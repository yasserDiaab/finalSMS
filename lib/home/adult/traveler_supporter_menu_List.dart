import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:pro/repo/SupporterRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

import 'package:get_it/get_it.dart';

// Make sure SupporterRepository is registered in GetIt elsewhere in the code
// final getIt = GetIt.instance;
// getIt.registerLazySingleton<SupporterRepository>(() => SupporterRepository(api: getIt<DioConsumer>()));

class TravelersListWidget extends StatefulWidget {
  const TravelersListWidget({Key? key}) : super(key: key);

  @override
  State<TravelersListWidget> createState() => _TravelersListWidgetState();
}

class _TravelersListWidgetState extends State<TravelersListWidget> {
  List<Map<String, dynamic>> supporters = [];
  bool showInput = false;
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();
  late final SupporterRepository supporterRepo;

  @override
  void initState() {
    super.initState();
    supporterRepo = GetIt.instance<SupporterRepository>();
    loadSupporters();
  }

  // Get the current user ID from cache
  String? getUserId() {
    // Try to get user ID from different sources
    final userId = CacheHelper.getData(key: ApiKey.userId) ??
        CacheHelper.getData(key: "current_user_id") ??
        CacheHelper.getData(key: ApiKey.id) ??
        CacheHelper.getData(key: "userId") ??
        CacheHelper.getData(key: "UserId") ??
        CacheHelper.getData(key: "sub");

    if (userId == null || userId.toString().isEmpty) {
      log("WARNING: Could not get user ID from cache");
      return null;
    }

    return userId.toString();
  }

  // Get the storage key for the current user's supporters
  String getSupportersKey() {
    final userId = getUserId();
    return userId != null ? 'supporters_$userId' : 'supporters_default';
  }

  Future<void> loadSupporters() async {
    try {
      // 🌐 First try to load from API
      await loadSupportersFromApi();
    } catch (e) {
      log("Failed to load from API, falling back to local storage: $e");
      // If API fails, fallback to local storage
      try {
        await loadSupportersFromLocalStorage();
      } catch (localError) {
        setState(() {
          supporters = [];
        });
        log("Error loading supporters from local storage: $localError");
      }
    }
  }

  // 🌐 Load supporters from API
  Future<void> loadSupportersFromApi() async {
    try {
      log("Loading supporters from API...");

      final response = await supporterRepo.getSupportersList();

      if (response.success && response.supporters.isNotEmpty) {
        setState(() {
          supporters = response.supporters
              .map((supporter) => {
                    'name': supporter.name,
                    'image': supporter
                        .profilePicture, // Use profile picture from API
                    'selected': false,
                    'id': supporter.id,
                    'email': supporter.email,
                    'travelerId': supporter.travelerId ?? '',
                    'travelerName': supporter.travelerName ?? '',
                    'from_api': true, // Flag to indicate this came from API
                  })
              .toList();
        });

        log("✅ Loaded ${supporters.length} supporters from API");

        // Save to local storage for offline access
        await saveSupporters();
      } else {
        log("API returned empty or unsuccessful response, falling back to local storage");
        await loadSupportersFromLocalStorage();
      }
    } catch (e) {
      log("Error loading supporters from API: $e");
      rethrow; // Re-throw to trigger fallback
    }
  }

  // Load supporters from local storage (fallback)
  Future<void> loadSupportersFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String supportersKey = getSupportersKey();
    log("Loading supporters from local storage for key: $supportersKey");

    final String? data = prefs.getString(supportersKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        supporters = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
      log("Loaded ${supporters.length} supporters from local storage");
    } else {
      // Default supporters for new users
      supporters = [
        {'name': 'Mum', 'image': 'assets/images/man.jpeg', 'selected': false},
        {'name': 'Dad', 'image': 'assets/images/man.jpeg', 'selected': false},
        {'name': 'Sara', 'image': 'assets/images/man.jpeg', 'selected': false},
        {'name': 'Ali', 'image': 'assets/images/man.jpeg', 'selected': true},
      ];
      log("Created default supporters list for new user");
      await saveSupporters();
    }
  }

  Future<void> saveSupporters() async {
    final prefs = await SharedPreferences.getInstance();
    final String supportersKey = getSupportersKey();
    final String encoded = jsonEncode(supporters);
    await prefs.setString(supportersKey, encoded);
    log("Saved ${supporters.length} supporters with key: $supportersKey");
  }

  Future<void> addSupporterFromApi(String emailOrUsername) async {
    if (emailOrUsername.trim().isEmpty) return;

    try {
      log("Adding supporter via API: $emailOrUsername");

      // Call the API to add the supporter
      final response = await supporterRepo.addSupporter(emailOrUsername);

      // Use the supporter name from the response if available, otherwise use the email/username
      final displayName = response.supporterName ?? emailOrUsername.trim();

      final newSupporter = {
        'name': displayName,
        'image': null,
        'selected': false,
        'id': response.supporterId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'email': emailOrUsername.trim(),
        'success': response.success
      };

      setState(() {
        supporters.add(newSupporter);
        showInput = false;
        _controller.clear();
      });

      await saveSupporters();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Fallback to local storage if API fails
      /*
      // This code is for fallback to local storage if needed
      log("Adding supporter locally: $emailOrUsername");

      // Generate a random ID for the supporter
      final supporterId = DateTime.now().millisecondsSinceEpoch.toString();

      final newSupporter = {
        'name': emailOrUsername.trim(),
        'image': null,
        'selected': false,
        'id': supporterId,
        'email': emailOrUsername.trim(),
        'local': true // Flag to indicate this was added locally
      };
      */
    } catch (e) {
      if (mounted) {
        // Extract the error message from the exception
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ')[1];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add supporter: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        log("Error adding supporter: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Supporter's List",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.black, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (showInput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
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
                        onPressed: () => addSupporterFromApi(_controller.text),
                        child: const Text("Add"),
                      )
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  itemCount: supporters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == supporters.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.black,
                                  size: 12,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    showInput = !showInput;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }

                    final supporter = supporters[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 8),
                            supporter['image'] == null
                                ? const Icon(Icons.person, size: 24)
                                : ClipOval(
                                    child: Image.asset(
                                      supporter['image'],
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                supporter['name'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Icon(
                              Icons.location_on_outlined,
                              color: supporter['selected']
                                  ? Colors.green
                                  : Colors.black54,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
