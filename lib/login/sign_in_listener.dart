import 'dart:developer'; // For logging
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/cubit/adult-type-cubit/adult_type_cubit.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/cubit/user_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/home/adult/mode_selector.dart';
import 'package:pro/home/adult/supporter.dart';
import 'package:pro/home/adult/traveler.dart';
import 'package:pro/home/kid/kid_mode.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:pro/main.dart' show _extractUserInfoFromTokenOnStartup;

// Make sure to import Kid_home

class SignInListener extends StatelessWidget {
  const SignInListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) async {
        if (state is SignInLoading) {
          _showLoading(context);
        } else {
          _hideLoading(context);

          if (state is SignInSuccess) {
            _showMessage(context, "Signed in successfully", Colors.green);

            log("Full UserModel Response: ${state.userModel}"); // Log full user model
            final userType =
                state.userModel.userType.toLowerCase(); // Get user type

            log("Extracted UserType: $userType"); // Log extracted user type

            // استدعاء دالة استخراج بيانات المستخدم من التوكن بعد تسجيل الدخول مباشرة
            await _extractUserInfoFromTokenOnLogin();

            // جلب أرقام الهواتف للمؤيدين بعد تسجيل الدخول
            await _syncSupporterPhonesAfterLogin();

            // Initialize SignalR connection for traveler
            if (userType == 'traveler') {
              // SignalR connection is already initialized in main.dart, no need to initialize again
              log("✅ SignalR connection already initialized in main.dart");
            }

            await Future.delayed(const Duration(seconds: 1));

            if (context.mounted) {
              if (userType == "kid") {
                log("Navigating to Kid_home");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SafetyScreen()),
                );
              } else {
                // Try to get user ID from different sources
                log("DEBUG: Full user model: ${state.userModel}");

                // First try to get user ID from model
                var userId = state.userModel.userId;
                log("DEBUG: User ID from model: $userId");

                // If user ID is empty, try to get it from token
                if (userId.isEmpty) {
                  // Get token from cache
                  final token = CacheHelper.getData(key: ApiKey.token);
                  log("DEBUG: Token from cache: $token");

                  if (token != null && token.toString().isNotEmpty) {
                    try {
                      // Decode token
                      final decodedToken = JwtDecoder.decode(token.toString());
                      log("DEBUG: Decoded token: $decodedToken");

                      // Try to get user ID from 'sub' claim
                      if (decodedToken.containsKey('sub')) {
                        userId = decodedToken['sub'];
                        log("DEBUG: Extracted user ID from token 'sub' claim: $userId");

                        // Save user ID to cache with multiple keys for redundancy
                        await CacheHelper.saveData(
                            key: ApiKey.id, value: userId);
                        await CacheHelper.saveData(
                            key: ApiKey.userId, value: userId);
                        await CacheHelper.saveData(
                            key: "userId", value: userId);
                        await CacheHelper.saveData(
                            key: "UserId", value: userId);
                        await CacheHelper.saveData(key: "sub", value: userId);
                        await CacheHelper.saveData(
                            key: "current_user_id", value: userId);

                        log("DEBUG: Saved user ID to cache with multiple keys");
                      }
                    } catch (e) {
                      log("ERROR: Failed to decode token: $e");
                    }
                  }
                }

                // If we still don't have a valid user ID, try to get it from cache
                if (userId.isEmpty) {
                  // Try different keys that might contain the user ID
                  final possibleKeys = [
                    ApiKey.id,
                    ApiKey.userId,
                    "userId",
                    "UserId",
                    "sub",
                    "current_user_id"
                  ];

                  for (var key in possibleKeys) {
                    final cachedId = CacheHelper.getData(key: key);
                    if (cachedId != null && cachedId.toString().isNotEmpty) {
                      userId = cachedId.toString();
                      log("DEBUG: Found user ID in cache with key $key: $userId");

                      // Save user ID to cache with multiple keys for redundancy
                      await CacheHelper.saveData(
                          key: "current_user_id", value: userId);

                      break;
                    }
                  }
                }

                // If we still don't have a valid user ID, redirect to ModeSelector
                if (userId.isEmpty) {
                  log("ERROR: Could not find valid user ID. Redirecting to ModeSelector");

                  // Navigate to ModeSelector since we can't identify the user
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => getIt<AdultTypeCubit>(),
                          child: const ModeSelector(),
                        ),
                      ),
                    );
                  }
                  return; // Exit early
                }

                // We have a valid user ID, save it to cache for future use
                log("DEBUG: Using user ID: $userId");
                await CacheHelper.saveData(
                    key: "current_user_id", value: userId);

                final userModeKey = "user_mode_$userId";

                // Log some debug information
                log("DEBUG: Checking cache state");

                // For debugging purposes only
                log("DEBUG: Checking if user mode exists");

                // Check if user has a specific mode preference
                final hasUserMode = CacheHelper.containsKey(key: userModeKey);
                final userModeValue = CacheHelper.getData(key: userModeKey);

                log("DEBUG: User ID: $userId");
                log("DEBUG: User mode key: $userModeKey");
                log("DEBUG: Has saved mode preference: $hasUserMode");
                log("DEBUG: User mode value: $userModeValue");

                if (!hasUserMode) {
                  // This user doesn't have a saved mode preference
                  log("No saved mode preference for this user");

                  log("First login, navigating to ModeSelector");

                  // Check if context is still valid after async operations
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => getIt<AdultTypeCubit>(),
                          child: const ModeSelector(),
                        ),
                      ),
                    );
                  }
                } else {
                  // User has a saved mode preference, get it from cache
                  final savedMode = CacheHelper.getData(key: userModeKey);
                  log("User has saved mode preference: $savedMode");

                  // Check if context is still valid after async operations
                  if (context.mounted) {
                    if (savedMode == "traveler") {
                      log("Navigating to Traveler page based on saved preference");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Traveler()),
                      );
                    } else if (savedMode == "supporter") {
                      log("Navigating to Supporter page based on saved preference");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Supporter()),
                      );
                    } else {
                      log("Invalid saved mode, navigating to ModeSelector");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => getIt<AdultTypeCubit>(),
                            child: const ModeSelector(),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
            }
          } else if (state is SignInFailure) {
            _showMessage(context, state.errMessage, Colors.red);
          }
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading(BuildContext context) {
    if (context.mounted &&
        Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showMessage(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Future<void> _extractUserInfoFromTokenOnLogin() async {
    try {
      final token = CacheHelper.getData(key: ApiKey.token);
      if (token == null || token.toString().isEmpty) {
        print("Debug - No token found on login");
        return;
      }

      print("Debug - Extracting user info from token on login");
      final decodedToken = JwtDecoder.decode(token.toString());
      print("Debug - Decoded token on login: $decodedToken");

      // Try to extract userId from various token claims
      final possibleIdClaims = [
        'userId',
        'UserId',
        'id',
        'Id',
        'sub',
      ];

      String? userIdFromToken;
      for (var claim in possibleIdClaims) {
        if (decodedToken.containsKey(claim) &&
            decodedToken[claim] != null &&
            decodedToken[claim].toString().isNotEmpty) {
          userIdFromToken = decodedToken[claim].toString();
          print(
              "Debug - User ID from token claim '[32m$claim': $userIdFromToken");
          await CacheHelper.saveData(
              key: ApiKey.userId, value: userIdFromToken);
          print("Debug - Saved userId to cache: $userIdFromToken");
          break;
        }
      }
      print("Debug - User ID from token: $userIdFromToken");

      // Try to extract name from various token claims
      final possibleNameClaims = [
        'name',
        'fullname',
        'given_name',
        'family_name',
        'preferred_username',
        'username',
        'unique_name',
        'display_name',
      ];

      String? extractedName;
      for (var claim in possibleNameClaims) {
        if (decodedToken.containsKey(claim) &&
            decodedToken[claim] != null &&
            decodedToken[claim].toString().isNotEmpty) {
          extractedName = decodedToken[claim].toString();
          print(
              "Debug - Found name in token claim '[32m$claim' on login: $extractedName");

          // Save to cache for future use
          await CacheHelper.saveData(
              key: "user_name_from_token", value: extractedName);
          await CacheHelper.saveData(key: ApiKey.name, value: extractedName);
          print("Debug - Saved userName to cache: $extractedName");
          break;
        }
      }

      // Try to extract email from various token claims
      final possibleEmailClaims = [
        'email',
        'email_address',
        'mail',
        'upn', // User Principal Name
      ];

      String? extractedEmail;
      for (var claim in possibleEmailClaims) {
        if (decodedToken.containsKey(claim) &&
            decodedToken[claim] != null &&
            decodedToken[claim].toString().isNotEmpty) {
          extractedEmail = decodedToken[claim].toString();
          print(
              "Debug - Found email in token claim '[32m$claim' on login: $extractedEmail");

          // Save to cache for future use
          await CacheHelper.saveData(
              key: "user_email_from_token", value: extractedEmail);
          await CacheHelper.saveData(key: ApiKey.email, value: extractedEmail);
          break;
        }
      }

      // If we have name, use it; otherwise use email as display name
      if (extractedName != null && extractedName.isNotEmpty) {
        print("Debug - Using extracted name on login: $extractedName");
      } else if (extractedEmail != null && extractedEmail.isNotEmpty) {
        print(
            "Debug - Using extracted email as name on login: $extractedEmail");
        await CacheHelper.saveData(
            key: "user_name_from_token", value: extractedEmail);
        await CacheHelper.saveData(key: ApiKey.name, value: extractedEmail);
      }
    } catch (e) {
      print("Error extracting user info from token on login: $e");
    }
  }

  // جلب أرقام الهواتف للمؤيدين بعد تسجيل الدخول
  static Future<void> _syncSupporterPhonesAfterLogin() async {
    try {
      print("🔄 Syncing supporter phones after login...");

      final offlineSyncService = getIt<OfflineSyncService>();
      final success =
          await offlineSyncService.syncSupporterPhones(forceSync: true);

      if (success) {
        print("✅ Supporter phones synced successfully after login");

        // طباعة محتويات قاعدة البيانات المحلية
        await _printLocalDatabaseContents();
      } else {
        print("⚠️ Failed to sync supporter phones after login");
      }
    } catch (e) {
      print("❌ Error syncing supporter phones after login: $e");
    }
  }

  // طباعة محتويات قاعدة البيانات المحلية
  static Future<void> _printLocalDatabaseContents() async {
    try {
      print("📊 ===== LOCAL DATABASE CONTENTS =====");

      final offlineSyncService = getIt<OfflineSyncService>();
      final phones = await offlineSyncService.getSupporterPhones();
      final stats = await offlineSyncService.getDatabaseStats();

      print("📱 Total phones in database: ${phones.length}");
      print("📊 Database stats: $stats");

      if (phones.isNotEmpty) {
        print("📋 Phone numbers list:");
        for (int i = 0; i < phones.length; i++) {
          final phone = phones[i];
          print("  ${i + 1}. ${phone.supporterName} - ${phone.phoneNumber}");
          if (phone.email != null && phone.email!.isNotEmpty) {
            print("     Email: ${phone.email}");
          }
          print("     Last Updated: ${phone.lastUpdated}");
          print("     Active: ${phone.isActive}");
          print("");
        }
      } else {
        print("❌ No phone numbers found in local database");
      }

      print("📊 ===== END LOCAL DATABASE CONTENTS =====");
    } catch (e) {
      print("❌ Error printing local database contents: $e");
    }
  }
}
