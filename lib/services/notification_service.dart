import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pro/home/adult/sos_location_map.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/models/TripNotificationModel.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // List to keep in-app notifications
  final List<SosNotificationModel> _notifications = [];

  // Notifier to update UI in real time
  final ValueNotifier<List<SosNotificationModel>> notificationsNotifier =
      ValueNotifier<List<SosNotificationModel>>([]);

  // Callback for trip start notifications
  Function(TripNotificationModel)? onTripStartReceived;

  bool _isDisposed = false;

  NotificationService._internal();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTap(NotificationResponse response) {
    log('Notification tapped: ${response.payload}');
    // تقدر هنا تفتح صفحة الخريطة أو صفحة الإشعارات
  }

  /// Show local push notification + add in-app
  Future<void> showSosNotification(SosNotificationModel notification) async {
    if (_isDisposed) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'sos_channel',
        'SOS Alerts',
        channelDescription: 'Notifications for SOS alerts from travelers',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        'SOS Alert from ${notification.travelerName} (${notification.userType ?? 'Unknown'})',
        notification.message,
        platformDetails,
        payload: 'SOS Alert Payload',
      );

      addInAppNotification(notification);

      log('SOS notification shown successfully.');
    } catch (e) {
      log('Error showing SOS notification: $e');
    }
  }

  /// Show custom dialog inside the app
void showSosDialog(BuildContext context, SosNotificationModel notification) {
  final timeAgo = _getTimeAgo(notification.timestamp);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'SOS Alert from ${notification.travelerName} (${notification.userType ?? 'Unknown'})',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Received: $timeAgo'),
            const SizedBox(height: 8),
            Text('Location: ${notification.latitude}, ${notification.longitude}'),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.map, color: Colors.blue),
            label: const Text('View on Map'),
            onPressed: () {
              Navigator.of(context).pop();
              
              // ✅ تأكد أننا نمرر notification نفسه الذي استقبلناه
              debugPrint('📍 Opening map with lat=${notification.latitude}, lng=${notification.longitude}');
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SosLocationMapScreen(notification: notification),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.close, color: Colors.grey),
            label: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}


  void _openMap(BuildContext context, SosNotificationModel notification) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosLocationMapScreen(notification: notification),
      ),
    );
  }

  /// Helpers

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void addInAppNotification(SosNotificationModel notification) {
    if (_isDisposed) return;
    _notifications.add(notification);
    notificationsNotifier.value = List.from(_notifications);
  }

  void clearNotification(SosNotificationModel notification) {
    if (_isDisposed) return;
    _notifications.removeWhere((n) =>
        n.travelerId == notification.travelerId &&
        n.timestamp == notification.timestamp);
    notificationsNotifier.value = List.from(_notifications);
  }

  void clearAllNotifications() {
    if (_isDisposed) return;
    _notifications.clear();
    notificationsNotifier.value = [];
    _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Handle trip start notification
  void handleTripStartNotification(TripNotificationModel trip) {
    if (_isDisposed) return;
    
    log('🔍 NotificationService received trip notification:');
    log('  - TripId: ${trip.tripId}');
    log('  - TravelerId: ${trip.travelerId}');
    log('  - TravelerName: ${trip.travelerName}');
    log('  - TravelerPhone: ${trip.travelerPhone}');
    log('  - StartTime: ${trip.startTime}');
    log('  - Status: ${trip.status}');
    log('  - Action: ${trip.action}');
    
    // Check if data is valid
    if (trip.travelerName.isEmpty) {
      log('⚠️ Warning: TravelerName is empty!');
    }
    if (trip.tripId.isEmpty) {
      log('⚠️ Warning: TripId is empty!');
    }
    if (trip.startTime.isEmpty) {
      log('⚠️ Warning: StartTime is empty!');
    }
    
    // Call the callback if it's set
    if (onTripStartReceived != null) {
      log('✅ Calling onTripStartReceived callback');
      onTripStartReceived!.call(trip);
    } else {
      log('⚠️ onTripStartReceived callback is null');
    }
    
    log('Trip start notification received for ${trip.travelerName}');
  }

  void dispose() {
    _isDisposed = true;
    notificationsNotifier.dispose();
  }

  int get unreadCount => _notifications.length;
}