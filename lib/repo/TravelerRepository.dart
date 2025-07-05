import 'dart:convert';
import 'dart:developer';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/models/AddTravelerModel.dart';
import 'package:pro/models/TravelersListModel.dart';

class TravelerRepository {
  final ApiConsumer api;

  TravelerRepository({required this.api});

  String? getUserId() {
    final possibleKeys = [
      ApiKey.userId,
      "current_user_id",
      ApiKey.id,
      "userId",
      "UserId",
      "sub",
      "user_id",
      "ID",
      "id",
      "userID",
      "USER_ID",
      "supporter_id",
      "supporterId",
      "traveler_id",
      "travelerId"
    ];

    for (var key in possibleKeys) {
      final value = CacheHelper.getData(key: key);
      if (value != null && value.toString().isNotEmpty) {
        log("Found user ID from cache key '$key': $value");
        return value.toString();
      }
    }

    log("WARNING: Could not get user ID from cache");
    return null;
  }

  Future<AddTravelerModel> addTraveler(String emailOrUsername) async {
    final supporterId = getUserId();
    if (supporterId == null || supporterId.isEmpty) {
      throw Exception("User ID not found. Please log in again.");
    }

    final token = CacheHelper.getData(key: ApiKey.token);
    if (token == null || token.toString().isEmpty) {
      throw Exception("Authentication token not found. Please log in again.");
    }

    try {
      log("Adding traveler with email/username: $emailOrUsername by supporter ID: $supporterId");

      final response = await api.post(
        EndPoint.addTraveler,
        data: {
          'EmailOrUsername': emailOrUsername,
          'SupporterId': supporterId,
        },
      );

      log("Traveler API response: $response");
      return AddTravelerModel.fromJson(response);
    } catch (e) {
      log("Error adding traveler: $e");
      throw Exception("Failed to add traveler: $e");
    }
  }

  Future<TravelersListModel> getTravelersList() async {
    final userId = getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception("User ID not found. Please log in again.");
    }

    final token = CacheHelper.getData(key: ApiKey.token);
    if (token == null || token.toString().isEmpty) {
      throw Exception("Authentication token not found. Please log in again.");
    }

    try {
      log("Getting travelers list for user ID: $userId");

      final response = await api.get(
        EndPoint.getTravelersList,
        queryParameters: {
          'userId': userId, // لإرضاء الـ backend لو طلب userId
          'id': userId, // لإرضاء الـ backend لو طلب id
        },
      );

      log("Travelers list API response: $response");

      return TravelersListModel.fromJson(response);
    } catch (e) {
      log("Error getting travelers list: $e");
      throw Exception("Failed to get travelers list: $e");
    }
  }
}
