import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/kid_supporter_cubit.dart';
import 'package:pro/cubit/kid_supporter_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:pro/models/supporter_phone_model.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({Key? key}) : super(key: key);

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> supporters = [];
  bool showInput = false;
  final TextEditingController _controller = TextEditingController();
  late final KidSupporterCubit kidSupporterCubit;
  final OfflineSyncService _offlineSyncService = getIt<OfflineSyncService>();

  @override
  void initState() {
    super.initState();
    kidSupporterCubit = getIt<KidSupporterCubit>();
    _syncAndLoadSupporters();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _syncAndLoadSupporters() async {
    try {
      log("🔄 Syncing kid supporters from API...");
      await _offlineSyncService.syncKidSupporterPhones(forceSync: true);
      log("✅ Kid supporters synced. Loading from local DB...");
      await loadSupporters();
    } catch (e) {
      log("❌ Error syncing and loading kid supporters: $e");
      await loadSupporters();
    }
  }

  String? getUserId() {
    final userId = CacheHelper.getData(key: ApiKey.userId) ??
        CacheHelper.getData(key: "current_user_id") ??
        CacheHelper.getData(key: ApiKey.id) ??
        CacheHelper.getData(key: "userId") ??
        CacheHelper.getData(key: "UserId") ??
        CacheHelper.getData(key: "sub");

    if (userId == null || userId.toString().isEmpty) {
      final token = CacheHelper.getData(key: ApiKey.token);
      if (token != null) {
        final extractedId = _extractUserIdFromToken(token.toString());
        if (extractedId != null) {
          log("Extracted user ID from token: $extractedId");
          return extractedId;
        }
      }

      log("WARNING: Could not get user ID from cache or token.");
      return null;
    }

    return userId.toString();
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      final possibleKeys = [
        'sub',
        'user_id',
        'userId',
        'id',
        'nameid',
        'unique_name'
      ];
      for (String key in possibleKeys) {
        if (claims.containsKey(key)) {
          return claims[key].toString();
        }
      }
    } catch (e) {
      log("Error decoding JWT token: $e");
    }
    return null;
  }

  Future<void> loadSupporters() async {
    try {
      final List<SupporterPhoneModel> localSupporters =
          await _offlineSyncService.getKidSupporterPhones();
      setState(() {
        supporters = localSupporters
            .map((s) => {
                  'name': s.supporterName,
                  'image': null,
                  'selected': false,
                  'id': s.supporterId,
                  'email': s.email ?? '',
                  'phone': s.phoneNumber,
                  'success': true,
                })
            .toList();
      });
      log('✅ Loaded ${supporters.length} supporters from local DB for Kid');
    } catch (e) {
      log('❌ Error loading supporters from local DB for Kid: $e');
      setState(() {
        supporters = [
          {"name": "Mum", "image": null, "selected": false, "phone": ""},
          {"name": "Dad", "image": null, "selected": false, "phone": ""},
        ];
      });
    }
  }

  bool alreadyExists(String emailOrPhone) {
    return supporters
        .any((s) => s['email'] == emailOrPhone || s['phone'] == emailOrPhone);
  }

  Future<void> addSupporterFromApi(String emailOrUsername) async {
    if (emailOrUsername.trim().isEmpty) return;
    final trimmedInput = emailOrUsername.trim();
    if (alreadyExists(trimmedInput)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Supporter already exists"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    kidSupporterCubit.addSupporterToKid(trimmedInput);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KidSupporterCubit, KidSupporterState>(
      bloc: kidSupporterCubit,
      listener: (context, state) async {
        if (state is KidSupporterAddSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.result.message),
              backgroundColor: Colors.green,
            ),
          );
          await _offlineSyncService.syncKidSupporterPhones(forceSync: true);
          await loadSupporters();
          setState(() {
            showInput = false;
            _controller.clear();
          });
        } else if (state is KidSupporterAddFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add supporter: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is KidSupporterGetSuccess) {
          await _offlineSyncService.syncKidSupporterPhones(forceSync: true);
          await loadSupporters();
        } else if (state is KidSupporterGetFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch supporters: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
          await loadSupporters();
        } else if (state is KidSupporterRemoveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Supporter removed successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          await _offlineSyncService.syncKidSupporterPhones(forceSync: true);
          await loadSupporters();
        } else if (state is KidSupporterRemoveFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove supporter: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3BE489), Color(0xFF00C2E0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            size: 14, color: Colors.black),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Trusted contacts",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showInput)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Enter email or username",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () =>
                              addSupporterFromApi(_controller.text),
                          child: const Text("Add"),
                        )
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: supporters.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index == supporters.length) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              showInput = !showInput;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5)
                              ],
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add,
                                    size: 50, color: Color(0xff193869)),
                                SizedBox(height: 8),
                                Text(
                                  "Add Supporter",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff193869)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final contact = supporters[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5)
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                contact["image"] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          contact["image"]!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xff193869)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.person,
                                            size: 40, color: Color(0xff193869)),
                                      ),
                                const SizedBox(height: 12),
                                Text(
                                  contact["name"] ?? "Unknown",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                if (contact["email"] != null)
                                  Text(
                                    contact["email"],
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                          if (contact['id'] != null && contact['id'].isNotEmpty)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeSupporter(contact['id']),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeSupporter(String supporterId) async {
    try {
      log("🗑️ Removing supporter with ID: $supporterId");
      await kidSupporterCubit.removeSupporterFromKid(supporterId);
    } catch (e) {
      log("❌ Error removing supporter: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing supporter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
