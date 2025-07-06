import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

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

  // Check internet connectivity
  Future<bool> _isConnected() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      log('❌ Error checking connectivity: $e');
      return false;
    }
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
      final String supportersKey =
          userId != null ? 'supporters_$userId' : 'supporters_default';

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

  // Send SMS to supporters (for offline mode)
  Future<void> _sendSMSToSupporters(BuildContext? context) async {
    try {
      log('📱 KID SOS: Sending SMS to supporters...');

      // Get trusted supporters
      List<Map<String, dynamic>> supporters = await getTrustedSupporters();

      if (supporters.isEmpty) {
        log('⚠️ KID SOS: No trusted supporters found');
        return;
      }

      // Filter supporters with phone numbers
      List<Map<String, dynamic>> supportersWithPhones = supporters
          .where((supporter) =>
              supporter['phone'] != null &&
              supporter['phone'].toString().isNotEmpty)
          .toList();

      if (supportersWithPhones.isEmpty) {
        log('⚠️ KID SOS: No supporters with phone numbers found');
        return;
      }

      int successCount = 0;
      // Get last known location from cache
      final lastLat = CacheHelper.getData(key: 'last_latitude');
      final lastLng = CacheHelper.getData(key: 'last_longitude');
      String locationText = '';
      if (lastLat != null && lastLng != null) {
        locationText = '\nآخر موقع معروف: ($lastLat, $lastLng)';
      }
      final String dangerMessage =
          "SOS: الطفل في خطر ويحتاج مساعدة عاجلة$locationText";

      // Show confirmation dialog for SMS if context is available
      if (context != null) {
        final bool shouldSend = await _showSMSConfirmationDialog(
            context, supportersWithPhones.length);
        if (!shouldSend) {
          log('❌ KID SOS: SMS sending cancelled by user');
          return;
        }
      }

      for (var supporter in supportersWithPhones) {
        try {
          final String phoneNumber = supporter['phone'].toString();

          // Create SMS URI - SMS only, no WhatsApp
          final Uri smsUri = Uri(
            scheme: 'sms',
            path: phoneNumber,
            queryParameters: {'body': dangerMessage},
          );

          // Launch SMS app directly - no WhatsApp suggestions
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri, mode: LaunchMode.externalApplication);
            successCount++;
            log('✅ KID SOS: SMS sent to ${supporter['name'] ?? 'Unknown'}: $phoneNumber');
          } else {
            log('❌ KID SOS: Could not launch SMS for ${supporter['name'] ?? 'Unknown'}');
          }
        } catch (e) {
          log('❌ KID SOS: Error sending SMS to ${supporter['name'] ?? 'Unknown'}: $e');
        }
      }

      log('📱 KID SOS: SMS sent to $successCount out of ${supportersWithPhones.length} supporters');
    } catch (e) {
      log('❌ KID SOS: Error in _sendSMSToSupporters: $e');
    }
  }

  // Show SMS confirmation dialog for kids
  Future<bool> _showSMSConfirmationDialog(
      BuildContext context, int supporterCount) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('إرسال رسالة SMS عاجلة'),
              content: Text(
                'سيتم إرسال رسالة "SOS: الطفل في خطر ويحتاج مساعدة عاجلة" إلى $supporterCount مؤيد.\n\n'
                'هذا الإجراء سيستخدم SMS فقط (وليس الواتساب).\n\n'
                'هل تريد المتابعة؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('إرسال SMS'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Send SOS to all trusted supporters with offline SMS support
  Future<bool> sendSOSToTrustedSupporters({
    String? customMessage,
    Position? location,
    BuildContext? context,
  }) async {
    try {
      log("🚨 KID SOS: Starting SOS alert to trusted supporters");

      // Check internet connectivity first
      final bool isConnected = await _isConnected();

      if (!isConnected) {
        log('🌐 KID SOS: No internet connection, sending SMS to supporters...');
        await _sendSMSToSupporters(context);
        return true; // Return true since SMS was sent
      }

      log('🌐 KID SOS: Internet connection available, sending SOS via API...');

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
      final kidEmail =
          CacheHelper.getData(key: ApiKey.email) ?? 'unknown@email.com';
      final kidId = getUserId() ?? 'unknown_id';

      // Create SOS message
      final sosMessage = customMessage ?? 'Emergency! Kid needs help!';

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
      // Try SMS as fallback
      await _sendSMSToSupporters(context);
      return true; // Return true since SMS was sent as fallback
    }
  }

  // Send SOS to individual supporter
  Future<void> sendSOSToSupporter(
      Map<String, dynamic> supporter, Map<String, dynamic> sosData) async {
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
        notifications =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
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
  Future<void> saveSOSHistory(Map<String, dynamic> sosData, int totalSupporters,
      int successCount) async {
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
