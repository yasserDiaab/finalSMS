import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/kid_supporter_cubit.dart';
import 'package:pro/cubit/kid_supporter_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

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

  @override
  void initState() {
    super.initState();
    kidSupporterCubit = getIt<KidSupporterCubit>();
    loadSupporters();
    fetchSupportersFromApi();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchSupportersFromApi() async {
    try {
      await kidSupporterCubit.getKidSupporters();
    } catch (e) {
      log("Error fetching supporters: $e");
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

  String getSupportersKey() {
    final userId = getUserId();
    return userId != null ? 'supporters_$userId' : 'supporters_default';
  }

  Future<void> loadSupporters() async {
    final prefs = await SharedPreferences.getInstance();
    final String supportersKey = getSupportersKey();
    final String? data = prefs.getString(supportersKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        supporters = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      supporters = [
        {"name": "Mum", "image": null, "selected": false},
        {"name": "Dad", "image": null, "selected": false},
      ];
      await saveSupporters();
    }
  }

  Future<void> saveSupporters() async {
    final prefs = await SharedPreferences.getInstance();
    final String supportersKey = getSupportersKey();
    final String encoded = jsonEncode(supporters);
    await prefs.setString(supportersKey, encoded);
  }

  bool alreadyExists(String email) {
    return supporters.any((s) => s['email'] == email);
  }

  Future<void> addSupporterFromApi(String emailOrUsername) async {
    if (emailOrUsername.trim().isEmpty) return;
    final trimmedEmail = emailOrUsername.trim();
    if (alreadyExists(trimmedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Supporter already exists"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    kidSupporterCubit.addSupporterToKid(trimmedEmail);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KidSupporterCubit, KidSupporterState>(
      bloc: kidSupporterCubit,
      listener: (context, state) {
        if (state is KidSupporterAddSuccess) {
          final newSupporter = {
            'name': state.result.supporterName ?? _controller.text.trim(),
            'image': null,
            'selected': false,
            'id': state.result.supporterId ?? '',
            'email': _controller.text.trim(),
            'success': state.result.success
          };

          setState(() {
            supporters.add(newSupporter);
            showInput = false;
            _controller.clear();
          });

          saveSupporters();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.result.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is KidSupporterAddFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add supporter: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is KidSupporterGetSuccess) {
          setState(() {
            supporters = state.supporters.map((s) {
              return {
                'name': s['supporterName'] ??
                    s['name'] ??
                    s['fullName'] ??
                    'Unknown',
                'email': s['email'] ?? '',
                'id': s['supporterId'] ?? s['id'] ?? '',
                'image': null,
                'selected': false,
              };
            }).toList();
          });
          saveSupporters();
        } else if (state is KidSupporterGetFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch supporters: ${state.error}'),
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
                      return Container(
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.person,
                                        size: 40, color: Color(0xff193869)),
                                  ),
                            const SizedBox(height: 12),
                            Text(
                              contact["name"] ?? "Unknown",
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
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
}
