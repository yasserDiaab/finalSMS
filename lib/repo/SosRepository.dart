import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/core/errors/Exceptions.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/repo/SupporterRepository.dart';
import 'package:pro/services/signalr_service.dart';

class SosRepository {
  final ApiConsumer api;
  final SignalRService signalRService;

  static const String sosEndpoint =
      'https://followsafe.runasp.net/notifications/traveler-sos';

  SosRepository({required this.api, required this.signalRService});

  // استخراج userId من الكاش أو من الـ JWT
  String? getUserId() {
    final userId = CacheHelper.getData(key: ApiKey.userId) ??
        CacheHelper.getData(key: "current_user_id") ??
        CacheHelper.getData(key: ApiKey.id) ??
        CacheHelper.getData(key: "userId") ??
        CacheHelper.getData(key: "UserId") ??
        CacheHelper.getData(key: "sub");

    if (userId != null && userId.toString().isNotEmpty) {
      return userId.toString();
    }

    // محاولة استخراجه من الـ token
    final token = CacheHelper.getData(key: ApiKey.token);
    if (token != null) {
      return _extractUserIdFromToken(token.toString());
    }

    log("WARNING: Could not get user ID from cache or token");
    return null;
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
      for (var key in possibleKeys) {
        if (claims.containsKey(key)) {
          return claims[key].toString();
        }
      }
    } catch (e) {
      log("Error decoding JWT token: $e");
    }
    return null;
  }

  // استخراج اسم المستخدم من الكاش أو من الـ JWT
  String? getUserName() {
    final possibleKeys = [
      "user_name_from_token",
      "user_email_from_token",
      ApiKey.name,
      "fullname",
      "name",
      "username",
      "displayName",
      "firstName",
      "lastName",
      "user_name",
      "userName",
      "display_name",
      "full_name",
      ApiKey.email,
      "email"
    ];

    for (var key in possibleKeys) {
      final value = CacheHelper.getData(key: key);
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    // محاولة من التوكن
    return _extractUserInfoFromToken() ?? "Anonymous Traveler";
  }

  String? _extractUserInfoFromToken() {
    try {
      final token = CacheHelper.getData(key: ApiKey.token);
      if (token == null || token.toString().isEmpty) return null;

      final decodedToken = JwtDecoder.decode(token.toString());

      final possibleNameClaims = [
        'name',
        'fullname',
        'given_name',
        'family_name',
        'preferred_username',
        'username',
        'unique_name',
        'display_name'
      ];

      for (var claim in possibleNameClaims) {
        if (decodedToken.containsKey(claim) &&
            decodedToken[claim] != null &&
            decodedToken[claim].toString().isNotEmpty) {
          return decodedToken[claim].toString();
        }
      }

      final possibleEmailClaims = ['email', 'email_address', 'mail', 'upn'];
      for (var claim in possibleEmailClaims) {
        if (decodedToken.containsKey(claim) &&
            decodedToken[claim] != null &&
            decodedToken[claim].toString().isNotEmpty) {
          return decodedToken[claim].toString();
        }
      }
    } catch (e) {
      log("ERROR extracting user info from token: $e");
    }
    return null;
  }

  // الاتصال بـ SignalR
  Future<void> connectToSignalR() async {
    try {
      // Check if already connected
      if (signalRService.isConnected) {
        log("✅ SignalR already connected, skipping connection");
        return;
      }

      log("🔗 Connecting to SignalR...");
      await signalRService.startConnection();
      log("✅ SignalR connected successfully");
    } catch (e) {
      log("Error connecting to SignalR: $e");
      throw Exception("Failed to connect to notification service: $e");
    }
  }

  // إرسال إشعار SOS
  Future<Either<String, SosResponse>> sendSosNotification({
    required double latitude,
    required double longitude,
    String message = "SOS! I need help!",
  }) async {
    try {
      final userId = getUserId();
      if (userId == null) return const Left("User ID not found.");

      final userName = getUserName();

      if (!signalRService.isConnected) {
        await connectToSignalR();
      }

      // جلب قائمة الداعمين
      List<String> supporterIds = [];
      try {
        final supporterRepository = getIt<SupporterRepository>();
        final supportersList = await supporterRepository.getSupportersList();
        if (supportersList.success) {
          supporterIds = supportersList.supporters.map((s) => s.id).toList();
        }
      } catch (e) {
        log("Could not fetch supporters: $e");
      }

      // قراءة نوع المستخدم من الكاش (Traveler أو Kid)
      final userType = CacheHelper.getData(key: 'userType') ?? 'Traveler';

      // تجهيز البيانات
      final sosData = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'message': message,
        'travelerId': userId,
        'travelerName': userName,
        'timestamp': DateTime.now().toIso8601String(),
        'sendToSupportersOnly': true,
        'supporterIds': supporterIds,
        'userType': userType,
      };

      log("Sending SOS: $sosData");

      // إرسال الـ request (الـ token سيتم إرساله تلقائياً عبر ApiInterceptor)
      final response = await api.post(sosEndpoint, data: sosData);

      return Right(SosResponse.fromJson(response is Map<String, dynamic>
          ? response
          : {'success': true, 'message': 'SOS notification sent'}));
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      return Left("Failed to send SOS notification: $e");
    }
  }

  // فصل الاتصال بـ SignalR
  Future<void> disconnectFromSignalR() async {
    await signalRService.stopConnection();
  }

  // تنظيف الموارد
  void dispose() {
    signalRService.dispose();
  }
}
