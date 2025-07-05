import 'package:dartz/dartz.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/models/forget_password_model.dart';

class ForgetRepo {
  final ApiConsumer api;
  ForgetRepo({required this.api});

  Future<Either<String, ForgetPasswordModel>> forgetPassword(
      {required String email}) async {
    try {
      final response = await api.post(
        EndPoint.forgotPassword,
        data: {ApiKey.email: email},
        isFromData: false,
      );
      print("Response from API: $response");

      if (response == null) {
        return const Left("Unexpected response. Please try again.");
      }

      // التأكد من وجود البيانات المطلوبة
      if (response.containsKey(ApiKey.message) &&
          response.containsKey("userId")) {
        final model = ForgetPasswordModel.fromJson(response);
        return Right(model); // ✅ نرجع الموديل الصحيح
      }

      // في حالة وجود خطأ معروف
      if (response.containsKey("statusCode") && response["statusCode"] == 400) {
        return const Left("Invalid email. Please check and try again.");
      }

      return const Left("An unexpected error occurred.");
    } catch (e) {
      print("Error in forgetPassword: $e");
      return const Left("An unexpected error occurred. Please try again.");
    }
  }
}
