import 'package:pro/core/API/ApiKey.dart';

class UserModel {
  final String? email;
  final String? name;
  final String? userType;
  final String? password;

  UserModel({
    required this.email,
    this.name,
    this.userType,
    required this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> jsonData) {
    return UserModel(
        email: jsonData[ApiKey.email],
        name: jsonData[ApiKey.name],
        userType: jsonData["userType"],
        password: jsonData[ApiKey.password]);
  }
}
