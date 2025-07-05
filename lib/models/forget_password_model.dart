import 'package:pro/core/API/ApiKey.dart';

class ForgetPasswordModel {
  final String message;
  final String userId;

  ForgetPasswordModel({required this.message, required this.userId});

  factory ForgetPasswordModel.fromJson(Map<String, dynamic> jsonData) {
    return ForgetPasswordModel(
      message: jsonData[ApiKey.message],
      userId: jsonData['userId'],
    );
  }
}
