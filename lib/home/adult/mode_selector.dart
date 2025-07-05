import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:pro/home/adult/supporter.dart';
import 'package:pro/home/adult/traveler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/adult-type-cubit/adult_type_cubit.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

import 'package:pro/widgets/header_profile.dart';
import 'package:pro/widgets/login_button.dart';

class ModeSelector extends StatefulWidget {
  const ModeSelector({super.key});

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector> {
  final List<String> items = [
    'default mode',
    'traveler',
    'supporter',
  ];
  String? selectedValue;

  // Navigate based on selected mode
  Future<void> navigateToPage() async {
    if (selectedValue == 'traveler') {
      // Save user preference using UserCubit
      await context.read<UserCubit>().saveDefaultMode('traveler');

      // Also save directly to cache with user-specific key for redundancy
      // Try to get user ID from different sources
      var userId = CacheHelper.getData(key: "current_user_id");

      // If not found, try other keys
      if (userId == null || userId.toString().isEmpty) {
        final possibleKeys = [
          ApiKey.id,
          ApiKey.userId,
          "userId",
          "UserId",
          "sub"
        ];

        for (var key in possibleKeys) {
          final cachedId = CacheHelper.getData(key: key);
          if (cachedId != null && cachedId.toString().isNotEmpty) {
            userId = cachedId;
            log("Found user ID in cache with key $key: $userId");
            break;
          }
        }
      }

      if (userId != null && userId.toString().isNotEmpty) {
        final userModeKey = "user_mode_$userId";
        await CacheHelper.saveData(key: userModeKey, value: 'traveler');
        log("Saved user mode preference: traveler for user: $userId");

        // Also save to default_mode for backward compatibility
        await CacheHelper.saveDefaultMode('traveler');
      } else {
        log("WARNING: Could not get user ID from cache");

        // Save to default_mode as fallback
        await CacheHelper.saveDefaultMode('traveler');
      }

      // Navigate to Traveler page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Traveler()),
        );
      }
    } else if (selectedValue == 'supporter') {
      // Save user preference using UserCubit
      await context.read<UserCubit>().saveDefaultMode('supporter');

      // Also save directly to cache with user-specific key for redundancy
      // Try to get user ID from different sources
      var userId = CacheHelper.getData(key: "current_user_id");

      // If not found, try other keys
      if (userId == null || userId.toString().isEmpty) {
        final possibleKeys = [
          ApiKey.id,
          ApiKey.userId,
          "userId",
          "UserId",
          "sub"
        ];

        for (var key in possibleKeys) {
          final cachedId = CacheHelper.getData(key: key);
          if (cachedId != null && cachedId.toString().isNotEmpty) {
            userId = cachedId;
            log("Found user ID in cache with key $key: $userId");
            break;
          }
        }
      }

      if (userId != null && userId.toString().isNotEmpty) {
        final userModeKey = "user_mode_$userId";
        await CacheHelper.saveData(key: userModeKey, value: 'supporter');
        log("Saved user mode preference: supporter for user: $userId");

        // Also save to default_mode for backward compatibility
        await CacheHelper.saveDefaultMode('supporter');
      } else {
        log("WARNING: Could not get user ID from cache");

        // Save to default_mode as fallback
        await CacheHelper.saveDefaultMode('supporter');
      }

      // Navigate to Supporter page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Supporter()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mode first!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdultTypeCubit, AdultTypeState>(
      listener: (context, state) {
        if (state is AdultTypeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User mode saved successfully: ${state.message}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AdultTypeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving user mode: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const HeaderProfile(),
            const SizedBox(
              height: 50,
            ),
            const Padding(
              padding: EdgeInsets.only(right: 60),
              child: Text(
                "Please choose your default mode",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Container(
              width: 330,
              height: 45,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xff193869)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xff193869))),
                  iconStyleData:
                      const IconStyleData(iconEnabledColor: Color(0xffF9F9F9)),
                  isExpanded: true,
                  hint: const Text(
                    'Default Mode',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xffF9F9F9),
                    ),
                  ),
                  items: items
                      .map((String item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Color(0xffF9F9F9)),
                            ),
                          ))
                      .toList(),
                  value: selectedValue,
                  onChanged: (String? value) async {
                    setState(() {
                      selectedValue = value;
                    });

                    // Save user preference
                    if (value == 'traveler' || value == 'supporter') {
                      // Show loading message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saving your preference...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Save the selected mode using UserCubit
                      if (mounted) {
                        await context.read<UserCubit>().saveDefaultMode(value!);
                        log("DEBUG: Saved user mode preference: $value");
                      }

                      // Also save directly to cache with user-specific key for redundancy
                      // Try to get user ID from different sources
                      var userId = CacheHelper.getData(key: "current_user_id");

                      // If not found, try other keys
                      if (userId == null || userId.toString().isEmpty) {
                        final possibleKeys = [
                          ApiKey.id,
                          ApiKey.userId,
                          "userId",
                          "UserId",
                          "sub"
                        ];

                        for (var key in possibleKeys) {
                          final cachedId = CacheHelper.getData(key: key);
                          if (cachedId != null &&
                              cachedId.toString().isNotEmpty) {
                            userId = cachedId;
                            log("Found user ID in cache with key $key: $userId");
                            break;
                          }
                        }
                      }

                      if (userId != null && userId.toString().isNotEmpty) {
                        final userModeKey = "user_mode_$userId";
                        await CacheHelper.saveData(
                            key: userModeKey, value: value);
                        log("DEBUG: Saved user mode preference: $value for user: $userId");

                        // Also save to default_mode for backward compatibility
                        await CacheHelper.saveDefaultMode(value!);
                      } else {
                        log("WARNING: Could not get user ID from cache");

                        // Save to default_mode as fallback
                        await CacheHelper.saveDefaultMode(value!);
                      }

                      // Send data to server with user type
                      // Check if context is still valid
                      if (mounted) {
                        context
                            .read<AdultTypeCubit>()
                            .changeAdultType("sub", value);
                      }
                    }
                  },
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    width: 140,
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 480),
            // Link "Next" button to navigation function
            LoginButton(
              onPressed: navigateToPage, // Call the navigation function
              label: 'Next',
              Color1: const Color(0xff193869),
              color2: const Color(0xffF9F9F9),
              color3: const Color(0xff193869),
            ),
          ],
        ),
      ),
    );
  }
}

// Traveler page

// Supporter page
