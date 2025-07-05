import 'dart:convert';
import 'dart:developer';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/models/AddSupporterModel.dart';
import 'package:pro/models/SupportersListModel.dart';

class SupporterRepository {
  final ApiConsumer api;

  SupporterRepository({required this.api});

  // ✅ Get the current user ID from cache or token
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
      "traveler_id",
      "travelerId",
      "supporter_id",
      "supporterId",
    ];

    for (var key in possibleKeys) {
      final value = CacheHelper.getData(key: key);
      if (value != null && value.toString().isNotEmpty) {
        log("Found user ID from cache key '$key': $value");
        return value.toString();
      }
    }

    // ❗ Try to extract from JWT token if not found in cache
    final token = CacheHelper.getData(key: ApiKey.token) ??
        CacheHelper.getData(key: "token") ??
        CacheHelper.getData(key: "access_token");

    if (token != null) {
      final userIdFromToken = _extractUserIdFromToken(token.toString());
      if (userIdFromToken != null) {
        log("Extracted user ID from token: $userIdFromToken");
        return userIdFromToken;
      }
    }

    log("WARNING: Could not get user ID from cache or token.");
    return null;
  }

  // ✅ Helper method to extract userId from JWT token
  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      final possibleClaims = [
        'sub',
        'user_id',
        'userId',
        'id',
        'nameid',
        'unique_name'
      ];
      for (var claim in possibleClaims) {
        if (claims.containsKey(claim)) return claims[claim].toString();
      }
    } catch (e) {
      log("Error decoding token: $e");
    }
    return null;
  }

  // ✅ Add a supporter
  Future<AddSupporterModel> addSupporter(String emailOrUsername) async {
    final travelerId = getUserId();
    if (travelerId == null || travelerId.toString().isEmpty) {
      throw Exception("User ID not found. Please log in again.");
    }

    final token = CacheHelper.getData(key: ApiKey.token);
    if (token == null || token.toString().isEmpty) {
      throw Exception("Authentication token not found. Please log in again.");
    }

    try {
      log("Adding supporter with email/username: $emailOrUsername by traveler ID: $travelerId");

      final response = await api.post(
        EndPoint.addSupporter,
        data: {
          "EmailOrUsername": emailOrUsername,
          "TravelerId": travelerId,
        },
      );

      log("Supporter API response: $response");
      return AddSupporterModel.fromJson(response);
    } catch (e) {
      log("Error adding supporter: $e");
      throw Exception("Failed to add supporter: $e");
    }
  }

  // ✅ Get supporters list
  Future<SupportersListModel> getSupportersList() async {
    final userId = getUserId();
    if (userId == null || userId.toString().isEmpty) {
      throw Exception("User ID not found. Please log in again.");
    }

    final token = CacheHelper.getData(key: ApiKey.token);
    if (token == null || token.toString().isEmpty) {
      throw Exception("Authentication token not found. Please log in again.");
    }

    try {
      log("Getting supporters list for user ID: $userId");

      final response = await api.get(
        EndPoint.getSupportersList,
      );

      log("Supporters list API response: $response");

      if (response is List) {
        return SupportersListModel(
          success: true,
          message: "Supporters list retrieved successfully",
          supporters: List<SupporterItem>.from(
              response.map((s) => SupporterItem.fromJson(s))),
        );
      } else if (response is Map<String, dynamic>) {
        return SupportersListModel.fromJson(response);
      }

      return SupportersListModel(
        success: false,
        message: "Invalid response format",
        supporters: [],
      );
    } catch (e) {
      log("Error getting supporters list: $e");
      throw Exception("Failed to get supporters list: $e");
    }
  }
}
