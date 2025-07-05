import 'package:pro/core/API/ApiKey.dart';

class SignUpModel {
  final String message;
  final String userId;

  SignUpModel({required this.message, required this.userId});
  factory SignUpModel.fromJson(Map<String, dynamic> jsonData) {
    return SignUpModel(
        message: jsonData[ApiKey.message], userId: jsonData['userId']);
  }
}
