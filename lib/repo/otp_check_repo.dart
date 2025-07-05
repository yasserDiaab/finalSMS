import 'package:dartz/dartz.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/errors/Exceptions.dart';

class OtpCheckRepository {
  final ApiConsumer api;

  OtpCheckRepository({required this.api});

  Future<Either<String, void>> checkOtp({
    required String code,
    required String userId,
  }) async {
    try {
      final response = await api.post(
        EndPoint.checkOtp,
        data: {
          ApiKey.userId: userId,
          ApiKey.code: code,
        },
        isFromData: false,
      );

      print("OTP Check Response: $response");

      if (response.containsKey(ApiKey.message) &&
          response[ApiKey.message].toString().contains("Valid OTP.")) {
        return const Right(unit);
      }

      return const Left("Invalid OTP. Please try again.");
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in checkOtp: $e");
      return const Left("An unexpected error occurred.");
    }
  }
}
