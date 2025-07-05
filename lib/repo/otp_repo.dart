import 'package:dartz/dartz.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/core/errors/Exceptions.dart';

class OtpRepository {
  final ApiConsumer api;

  OtpRepository({required this.api});

  Future<Either<String, void>> confirmEmailOtp({
    required String code,
    required String userId,
  }) async {
    try {
      final response = await api.post(EndPoint.confirmEmail,
          data: {
            "UserId": userId,
            "code": code,
          },
          isFromData: false);

      print("Response from API: $response");

      if (response == null) {
        return const Left("Unexpected response. Please try again.");
      }

      if (response.containsKey("message") &&
          response["message"]
              .toString()
              .toLowerCase()
              .contains("Email Confirmed Successfully")) {
        return const Right(unit);
      }

      if (response['statusCode'] == 400) {
        return const Left("Invalid OTP code. Please check and try again.");
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(e.errModel.description);
    } catch (e) {
      print("Error in confirmEmailOtp: $e");
      return const Left("An unexpected error occurred. Please try again.");
    }
  }
}
