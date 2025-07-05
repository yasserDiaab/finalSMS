import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/core/errors/Exceptions.dart';
import 'package:pro/models/SignInModel.dart';
import 'package:pro/models/SignUpModel.dart';
import 'package:pro/models/UserModel.dart';

class UserRepository {
  final ApiConsumer api;

  UserRepository({required this.api});

  // ✅ Sign In
  Future<Either<String, SignInModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.post(
        EndPoint.signIn,
        data: {
          ApiKey.email: email,
          ApiKey.password: password,
        },
      );

      if (response == null || !response.containsKey(ApiKey.token)) {
        return const Left(
            "Unexpected error: 'token' key not found in response.");
      }

      final user = SignInModel.fromJson(response);
      final decodedToken = JwtDecoder.decode(user.token);

      print("Debug - Token: ${user.token}");
      print("Debug - Decoded Token: $decodedToken");
      print("Debug - User ID from token: ${decodedToken[ApiKey.id]}");
      print("Debug - User ID from model: ${user.userId}");

      // حفظ معرف المستخدم بعدة طرق للتأكد من وجوده
      CacheHelper.saveData(key: ApiKey.token, value: user.token);
      CacheHelper.saveData(key: ApiKey.id, value: decodedToken[ApiKey.id]);
      CacheHelper.saveData(key: ApiKey.userId, value: user.userId);
      CacheHelper.saveData(key: "userId", value: user.userId);
      CacheHelper.saveData(key: "UserId", value: user.userId);

      // Extract and save user name/email from token
      _extractAndSaveUserInfoFromToken(decodedToken);

      return Right(user);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in signIn: $e");
      return const Left(
          "An unexpected error occurred. Please try again later.");
    }
  }

  // Extract and save user information from JWT token
  void _extractAndSaveUserInfoFromToken(Map<String, dynamic> decodedToken) {
    try {
      print("Debug - Extracting user info from token: $decodedToken");

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
          print("Debug - Found name in token claim '$claim': $extractedName");

          // Save to cache for future use
          CacheHelper.saveData(
              key: "user_name_from_token", value: extractedName);
          CacheHelper.saveData(key: ApiKey.name, value: extractedName);
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
          print("Debug - Found email in token claim '$claim': $extractedEmail");

          // Save to cache for future use
          CacheHelper.saveData(
              key: "user_email_from_token", value: extractedEmail);
          CacheHelper.saveData(key: ApiKey.email, value: extractedEmail);
          break;
        }
      }

      // If we have name, use it; otherwise use email as display name
      if (extractedName != null && extractedName.isNotEmpty) {
        print("Debug - Using extracted name: $extractedName");
      } else if (extractedEmail != null && extractedEmail.isNotEmpty) {
        print("Debug - Using extracted email as name: $extractedEmail");
        CacheHelper.saveData(
            key: "user_name_from_token", value: extractedEmail);
        CacheHelper.saveData(key: ApiKey.name, value: extractedEmail);
      }
    } catch (e) {
      print("Error extracting user info from token: $e");
    }
  }

  // ✅ Sign Up
  Future<Either<String, SignUpModel>> signUp({
    required String name,
    required String email,
    required String password,
    required String userType,
    required String phoneNumber, // إضافة رقم الهاتف
  }) async {
    try {
      final response = await api.post(
        EndPoint.signUp,
        data: {
          ApiKey.name: name,
          ApiKey.email: email,
          ApiKey.password: password,
          ApiKey.userType: userType,
          'phoneNumber': phoneNumber, // إضافة رقم الهاتف للبيانات المرسلة
        },
      );

      if (response == null || !response.containsKey(ApiKey.message)) {
        return const Left(
            "Unexpected error: 'message' key not found in response.");
      }

      final signUpModel = SignUpModel.fromJson(response);

      print("Debug - SignUp Response: $response");

      if (response.containsKey("UserId")) {
        final userId = response["UserId"];
        print("Debug - SignUp UserId: $userId");

        // حفظ معرف المستخدم بعدة طرق للتأكد من وجوده
        CacheHelper.saveData(key: ApiKey.id, value: userId);
        CacheHelper.saveData(key: ApiKey.userId, value: userId);
        CacheHelper.saveData(key: "userId", value: userId);
        CacheHelper.saveData(key: "UserId", value: userId);
      }

      return Right(signUpModel);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in signUp: $e");
      return const Left(
          "An unexpected error occurred. Please try again later.");
    }
  }

  // ✅ Get User Profile
  Future<Either<String, UserModel>> getUserProfile() async {
    try {
      final userId = CacheHelper.getData(key: ApiKey.id);
      if (userId == null) {
        return const Left("User ID not found in cache.");
      }

      final response = await api.get(EndPoint.getUserDataEndPoint(userId));

      if (response == null || !response.containsKey("data")) {
        return const Left(
            "Unexpected error: 'data' key not found in response.");
      }

      return Right(UserModel.fromJson(response));
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in getUserProfile: $e");
      return const Left(
          "An unexpected error occurred. Please try again later.");
    }
  }

  // ✅ Forgot Password
  Future<Either<String, String>> forgotPassword({required String email}) async {
    try {
      final response = await api.post(
        EndPoint.forgotPassword,
        data: {ApiKey.email: email},
      );

      if (response == null || !response.containsKey(ApiKey.message)) {
        return const Left(
            "Unexpected error: 'message' key not found in response.");
      }

      return Right(response[ApiKey.message]);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in forgotPassword: $e");
      return const Left(
          "An unexpected error occurred. Please try again later.");
    }
  }

  // ✅ Send OTP
  Future<Either<String, String>> sendOtp({required String email}) async {
    try {
      final userId = CacheHelper.getData(key: ApiKey.id);
      if (userId == null) {
        return const Left("User ID not found. Please log in again.");
      }

      final response = await api.post(
        EndPoint.sendOtp,
        data: {'UserId': userId, 'email': email},
      );

      if (response == null || !response.containsKey(ApiKey.message)) {
        return const Left(
            "Unexpected error: 'message' key not found in response.");
      }

      return Right(response[ApiKey.message]);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in sendOtp: $e");
      return const Left("Failed to send OTP. Please try again.");
    }
  }

  // ✅ Verify OTP
  Future<Either<String, void>> verifyOtp(
      {required String otpCode, required String email}) async {
    try {
      final userId = CacheHelper.getData(key: ApiKey.id);
      if (userId == null) {
        return const Left("User ID not found. Please log in again.");
      }

      final response = await api.post(
        EndPoint.verifyOtp,
        data: {
          'UserId': userId,
          'code': otpCode,
          'email': email,
        },
      );

      if (response == null || !response.containsKey("success")) {
        return const Left("OTP verification failed. Please try again.");
      }

      return Right(null);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in verifyOtp: $e");
      return const Left("Invalid OTP code. Please try again.");
    }
  }

  // ✅ Resend OTP
  Future<Either<String, String>> resendOtp({required String email}) async {
    return sendOtp(email: email);
  }
}
