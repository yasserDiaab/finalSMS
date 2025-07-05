import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/repo/TravelerRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:get_it/get_it.dart';
import 'package:pro/models/TravelersListModel.dart';

class SupportersListWidget extends StatefulWidget {
  const SupportersListWidget({Key? key}) : super(key: key);

  @override
  State<SupportersListWidget> createState() => _SupportersListWidgetState();
}

class _SupportersListWidgetState extends State<SupportersListWidget> {
  List<Map<String, dynamic>> travelers = [];
  bool showInput = false;
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();
  late final TravelerRepository travelerRepo;

  @override
  void initState() {
    super.initState();
    travelerRepo = GetIt.instance<TravelerRepository>();
    loadTravelers();
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

  // Get the storage key for the current user's travelers
  String getTravelersKey() {
    final userId = getUserId();
    return userId != null ? 'travelers_$userId' : 'travelers_default';
  }

  Future<void> loadTravelers() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get travelers from API
      final travelersResponse = await travelerRepo.getTravelersList();

      if (travelersResponse.success) {
        // Convert TravelerItem objects to Map format for consistency with existing code
        final List<Map<String, dynamic>> travelersList =
            travelersResponse.travelers
                .map((traveler) => {
                      'id': traveler.id,
                      'name': traveler.name,
                      'email': traveler.email,
                      'image': traveler.profilePicture,
                      'selected': false,
                      'supporterId': traveler.supporterId,
                      'supporterName': traveler.supporterName,
                    })
                .toList();

        final List<Map<String, dynamic>> kidsList = travelersResponse.kids
            .map((kid) => {
                  'id': kid.id,
                  'name': kid.name,
                  'email': kid.email,
                  'image': kid.profilePicture,
                  'selected': false,
                  'supporterId': kid.supporterId,
                  'supporterName': kid.supporterName,
                })
            .toList();

        setState(() {
          travelers = [...travelersList, ...kidsList]; // دمج الاتنين معًا
          isLoading = false;
        });

        log("Loaded ${travelers.length} travelers from API");

        // Save to local storage as backup
        await saveTravelers();
      } else {
        log("Failed to load travelers from API: ${travelersResponse.message}");
        // Fallback to local storage if API fails
        await loadTravelersFromLocalStorage();
      }
    } catch (e) {
      log("Error loading travelers from API: $e");
      // Fallback to local storage if API fails
      await loadTravelersFromLocalStorage();
    }
  }

  Future<void> loadTravelersFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String travelersKey = getTravelersKey();
      log("Loading travelers from local storage for key: $travelersKey");

      final String? data = prefs.getString(travelersKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        setState(() {
          travelers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          isLoading = false;
        });
        log("Loaded ${travelers.length} travelers from local storage");
      } else {
        setState(() {
          // Default travelers for new users
          travelers = [
            {
              'name': 'John',
              'image': 'assets/images/man.jpeg',
              'selected': false
            },
            {
              'name': 'Emma',
              'image': 'assets/images/man.jpeg',
              'selected': false
            },
            {
              'name': 'Mike',
              'image': 'assets/images/man.jpeg',
              'selected': false
            },
            {
              'name': 'Lisa',
              'image': 'assets/images/man.jpeg',
              'selected': true
            },
          ];
          isLoading = false;
        });
        log("Created default travelers list for new user");
        await saveTravelers();
      }
    } catch (e) {
      setState(() {
        travelers = [];
        isLoading = false;
      });
      log("Error loading travelers from local storage: $e");
    }
  }

  Future<void> saveTravelers() async {
    final prefs = await SharedPreferences.getInstance();
    final String travelersKey = getTravelersKey();
    final String encoded = jsonEncode(travelers);
    await prefs.setString(travelersKey, encoded);
    log("Saved ${travelers.length} travelers with key: $travelersKey");
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
          "Traveler's List",
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
                        onPressed: () => addTravelerFromApi(_controller.text),
                        child: const Text("Add"),
                      )
                    ],
                  ),
                ),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemCount: travelers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == travelers.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
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

                          final traveler = travelers[index];
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
                                  traveler['image'] == null
                                      ? const Icon(Icons.person, size: 24)
                                      : ClipOval(
                                          child: Image.asset(
                                            traveler['image'],
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      traveler['name'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: traveler['selected']
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

  Future<void> addTravelerFromApi(String emailOrUsername) async {
    if (emailOrUsername.trim().isEmpty) return;

    try {
      log("Adding traveler via API: $emailOrUsername");

      // Call the API to add the traveler
      final response = await travelerRepo.addTraveler(emailOrUsername);

      // Use the traveler name from the response if available, otherwise use the email/username
      final displayName = response.travelerName ?? emailOrUsername.trim();

      final newTraveler = {
        'name': displayName,
        'image': null,
        'selected': false,
        'id': response.travelerId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'email': emailOrUsername.trim(),
        'success': response.success,
        'supporterId': response.supporterId,
        'supporterName': response.supporterName
      };

      setState(() {
        travelers.add(newTraveler);
        showInput = false;
        _controller.clear();
      });

      await saveTravelers();

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
    } catch (e) {
      if (mounted) {
        // Extract the error message from the exception
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ')[1];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add traveler: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        log("Error adding traveler: $e");
      }
    }
  }
}
