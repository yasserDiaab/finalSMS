import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:geolocator/geolocator.dart';

class KidSOSService {
  static final KidSOSService _instance = KidSOSService._internal();
  factory KidSOSService() => _instance;
  KidSOSService._internal();

  // Get the current user ID from cache
  String? getUserId() {
    final userId = CacheHelper.getData(key: ApiKey.userId) ??
        CacheHelper.getData(key: "current_user_id") ??
        CacheHelper.getData(key: ApiKey.id) ??
        CacheHelper.getData(key: "userId") ??
        CacheHelper.getData(key: "UserId") ??
        CacheHelper.getData(key: "sub");

    if (userId == null || userId.toString().isEmpty) {
      log("WARNING: Could not get user ID from cache");
      return null;
    }

    return userId.toString();
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log("Location services are disabled");
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log("Location permissions are denied");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log("Location permissions are permanently denied");
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      log("Current location: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      log("Error getting current location: $e");
      return null;
    }
  }

  // Get supporters from trusted contacts
  Future<List<Map<String, dynamic>>> getTrustedSupporters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = getUserId();
      final String supportersKey = userId != null ? 'supporters_$userId' : 'supporters_default';
      
      final String? data = prefs.getString(supportersKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      log("Error getting trusted supporters: $e");
      return [];
    }
  }

  // Send SOS to all trusted supporters
  Future<bool> sendSOSToTrustedSupporters({
    String? customMessage,
    Position? location,
  }) async {
    try {
      log("🚨 KID SOS: Starting SOS alert to trusted supporters");

      // Get current location if not provided
      Position? currentLocation = location ?? await getCurrentLocation();
      
      // Get trusted supporters
      List<Map<String, dynamic>> supporters = await getTrustedSupporters();
      
      if (supporters.isEmpty) {
        log("🚨 KID SOS: No trusted supporters found");
        return false;
      }

      // Get kid information
      final kidName = CacheHelper.getData(key: ApiKey.name) ?? 'Unknown Kid';
      final kidEmail = CacheHelper.getData(key: ApiKey.email) ?? 'unknown@email.com';
      final kidId = getUserId() ?? 'unknown_id';

      // Create SOS message
      final sosMessage = customMessage ?? 'Emergency! I need help!';
      
      String locationText = 'Location not available';
      if (currentLocation != null) {
        locationText = 'Lat: ${currentLocation.latitude.toStringAsFixed(6)}, '
                      'Lng: ${currentLocation.longitude.toStringAsFixed(6)}';
      }

      // Create SOS notification data
      final sosData = {
        'type': 'KID_SOS',
        'kidId': kidId,
        'kidName': kidName,
        'kidEmail': kidEmail,
        'message': sosMessage,
        'location': locationText,
        'latitude': currentLocation?.latitude,
        'longitude': currentLocation?.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'urgency': 'HIGH',
      };

      // Send SOS to each supporter
      int successCount = 0;
      for (var supporter in supporters) {
        try {
          await sendSOSToSupporter(supporter, sosData);
          successCount++;
          log("🚨 KID SOS: Sent to ${supporter['name'] ?? 'Unknown'}");
        } catch (e) {
          log("🚨 KID SOS: Failed to send to ${supporter['name'] ?? 'Unknown'}: $e");
        }
      }

      log("🚨 KID SOS: Sent to $successCount out of ${supporters.length} supporters");
      
      // Save SOS history
      await saveSOSHistory(sosData, supporters.length, successCount);
      
      return successCount > 0;
    } catch (e) {
      log("🚨 KID SOS: Error sending SOS: $e");
      return false;
    }
  }

  // Send SOS to individual supporter
  Future<void> sendSOSToSupporter(Map<String, dynamic> supporter, Map<String, dynamic> sosData) async {
    try {
      final supporterId = supporter['id'] ?? supporter['supporterId'];
      if (supporterId == null) {
        log("🚨 KID SOS: Supporter ID not found for ${supporter['name']}");
        return;
      }

      // Store SOS notification for the supporter
      final prefs = await SharedPreferences.getInstance();
      final String notificationsKey = 'sos_notifications_$supporterId';
      
      // Load existing notifications
      List<Map<String, dynamic>> notifications = [];
      final String? existingData = prefs.getString(notificationsKey);
      if (existingData != null) {
        final List<dynamic> decoded = jsonDecode(existingData);
        notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Add new SOS notification
      final notification = {
        ...sosData,
        'supporterId': supporterId,
        'supporterName': supporter['name'] ?? 'Unknown',
        'read': false,
        'notificationId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      notifications.insert(0, notification); // Add to beginning

      // Keep only last 50 notifications
      if (notifications.length > 50) {
        notifications = notifications.take(50).toList();
      }

      // Save notifications
      final String encoded = jsonEncode(notifications);
      await prefs.setString(notificationsKey, encoded);

      log("🚨 KID SOS: Notification stored for supporter ${supporter['name']}");
    } catch (e) {
      log("🚨 KID SOS: Error sending to supporter: $e");
      rethrow;
    }
  }

  // Save SOS history for the kid
  Future<void> saveSOSHistory(Map<String, dynamic> sosData, int totalSupporters, int successCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = getUserId();
      final String historyKey = 'sos_history_$userId';
      
      // Load existing history
      List<Map<String, dynamic>> history = [];
      final String? existingData = prefs.getString(historyKey);
      if (existingData != null) {
        final List<dynamic> decoded = jsonDecode(existingData);
        history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Add new SOS record
      final record = {
        ...sosData,
        'totalSupporters': totalSupporters,
        'successCount': successCount,
        'historyId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      history.insert(0, record); // Add to beginning

      // Keep only last 20 SOS records
      if (history.length > 20) {
        history = history.take(20).toList();
      }

      // Save history
      final String encoded = jsonEncode(history);
      await prefs.setString(historyKey, encoded);

      log("🚨 KID SOS: History saved");
    } catch (e) {
      log("🚨 KID SOS: Error saving history: $e");
    }
  }

  // Get SOS history for the kid
  Future<List<Map<String, dynamic>>> getSOSHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = getUserId();
      final String historyKey = 'sos_history_$userId';
      
      final String? data = prefs.getString(historyKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      log("🚨 KID SOS: Error getting history: $e");
      return [];
    }
  }
}
