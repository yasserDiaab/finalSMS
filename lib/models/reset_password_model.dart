import 'package:pro/core/API/ApiKey.dart';

class ResetPasswordModel {
  final String message;

  ResetPasswordModel({required this.message});

  factory ResetPasswordModel.fromJson(Map<String, dynamic> jsonData) {
    return ResetPasswordModel(
      message: jsonData[ApiKey.message],
    );
  }
}
