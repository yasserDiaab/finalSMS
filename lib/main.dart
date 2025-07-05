import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/dio_consumer.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/login/logo_splash.dart';
import 'package:pro/repo/UserRepository.dart';
import 'package:pro/core/di/di.dart'; // Import the service locator setup
import 'package:pro/services/notification_service.dart';
import 'package:pro/services/app_timer_service.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:pro/cubit/startTrip/start_trip_cubit.dart';
import 'package:pro/cubit/updateLocation/updatelocation_cubit.dart';
import 'package:pro/cubit/end-trip/end_trip_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  setupServiceLocator(); // Initialize the service locator

  // Extract user info from token if available
  await _extractUserInfoFromTokenOnStartup();

  // Initialize notification service
  await getIt<NotificationService>().initialize();

  // Initialize app timer service
  try {
    await getIt<AppTimerService>().initialize();

    // Initialize tracking dependencies for timer service
    getIt<AppTimerService>().initializeTracking(
      startTripCubit: getIt<StartTripCubit>(),
      updateLocationCubit: getIt<UpdateLocationCubit>(),
      endTripCubit: getIt<EndTripCubit>(),
      signalRService: getIt<SignalRService>(),
    );

    // Initialize SignalR connection for traveler if user is logged in
    final token = CacheHelper.getData(key: ApiKey.token);
    if (token != null && token.toString().isNotEmpty) {
      try {
        await getIt<SignalRService>().startConnection();
        print("✅ SignalR connection initialized for traveler");
      } catch (e) {
        print("⚠️ SignalR connection failed: $e");
      }
    }

    print("✅ AppTimerService initialized successfully with tracking");
  } catch (e) {
    print("❌ Failed to initialize AppTimerService: $e");
  }

  // Initialize offline sync service (phones will be synced after login)
  try {
    getIt<OfflineSyncService>();
    print("✅ Offline sync service initialized");
  } catch (e) {
    print("⚠️ Offline sync service initialization failed: $e");
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              UserCubit(UserRepository(api: DioConsumer(dio: Dio()))),
        ),
        BlocProvider(
          create: (context) => getIt<SosCubit>()..initialize(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

// Extract user information from JWT token on app startup
Future<void> _extractUserInfoFromTokenOnStartup() async {
  try {
    final token = CacheHelper.getData(key: ApiKey.token);
    if (token == null || token.toString().isEmpty) {
      print("Debug - No token found on startup");
      return;
    }

    print("Debug - Extracting user info from token on startup");
    final decodedToken = JwtDecoder.decode(token.toString());
    print("Debug - Decoded token on startup: $decodedToken");

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
        print("Debug - User ID from token claim '$claim': $userIdFromToken");
        await CacheHelper.saveData(key: ApiKey.userId, value: userIdFromToken);
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
            "Debug - Found name in token claim '$claim' on startup: $extractedName");

        // Save to cache for future use
        await CacheHelper.saveData(
            key: "user_name_from_token", value: extractedName);
        await CacheHelper.saveData(key: ApiKey.name, value: extractedName);
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
            "Debug - Found email in token claim '$claim' on startup: $extractedEmail");

        // Save to cache for future use
        await CacheHelper.saveData(
            key: "user_email_from_token", value: extractedEmail);
        await CacheHelper.saveData(key: ApiKey.email, value: extractedEmail);
        break;
      }
    }

    // If we have name, use it; otherwise use email as display name
    if (extractedName != null && extractedName.isNotEmpty) {
      print("Debug - Using extracted name on startup: $extractedName");
    } else if (extractedEmail != null && extractedEmail.isNotEmpty) {
      print(
          "Debug - Using extracted email as name on startup: $extractedEmail");
      await CacheHelper.saveData(
          key: "user_name_from_token", value: extractedEmail);
      await CacheHelper.saveData(key: ApiKey.name, value: extractedEmail);
    }
  } catch (e) {
    print("Error extracting user info from token on startup: $e");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LogoSplash(),
    );
  }
}
