import 'package:pro/core/API/ApiKey.dart';

class SignInModel {
  final String message;
  final String token;
  final String userId; // ✅ إضافة userId
  final String userType; // ✅ إضافة userType

  SignInModel({
    required this.message,
    required this.token,
    required this.userId,
    required this.userType, // ✅ إضافة userType
  });

  factory SignInModel.fromJson(Map<String, dynamic> jsonData) {
    return SignInModel(
      message:
          jsonData[ApiKey.message] ?? "No message available", // ✅ تجنب Null
      token: jsonData[ApiKey.token] ?? "", // ✅ قيمة افتراضية لتجنب Null
      userId: jsonData[ApiKey.id] ?? "", // ✅ إضافة userId مع قيمة افتراضية
      userType: jsonData['userType'] ?? "unknown", // ✅ إضافة userType
    );
  }
}
