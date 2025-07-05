import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/models/reset_password_model.dart';

class ResetPasswordRepository {
  final ApiConsumer api;

  ResetPasswordRepository({required this.api});

  Future<Either<String, ResetPasswordModel>> resetPassword({
    required String userId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await api.post(
        EndPoint.resetPassword,
        data: {
          ApiKey.userId: userId,
          ApiKey.newpassword: newPassword,
          ApiKey.ConfirmNewPassword: confirmPassword,
        },
        isFromData: false,
      );

      print("Response from API: $response");

      if (response == null) {
        return const Left("Unexpected response. Please try again.");
      }

      if (response.containsKey(ApiKey.message) &&
          response.containsKey("userId")) {
        final model = ResetPasswordModel.fromJson(response);
        return Right(model); // ✅ نرجع الموديل الصحيح
      } else {
        return const Left("Password Changed Successfully , Now Login Again .");
      }
    } on DioError catch (e) {
      return Left(
          e.response?.data['error'] ?? "An error occurred. Please try again.");
    } catch (e) {
      return const Left("An error occurred. Please try again.");
    }
  }
}
