import 'package:flutter/material.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/home/adult/sos_location_map.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/widgets/header_profile.dart';

class NotificationsPage extends StatefulWidget {
  final bool hideHeader;

  const NotificationsPage({
    super.key,
    this.hideHeader = false,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = getIt<NotificationService>();
  String _userType = 'traveler'; // Default

  @override
  void initState() {
    super.initState();
    final adultType = CacheHelper.getData(key: 'adultType');
    if (adultType != null) {
      _userType = adultType.toString().toLowerCase() == 'supporter'
          ? 'supporter'
          : 'traveler';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            if (!widget.hideHeader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xff193869)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: HeaderProfile(
                        showNotifications: false,
                        userType: _userType,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xff193869)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Color(0xff193869), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff193869),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: ValueListenableBuilder<List<SosNotificationModel>>(
                valueListenable: _notificationService.notificationsNotifier,
                builder: (context, notifications, _) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'When you receive SOS alerts, they will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onDelete: () {
                          _notificationService.clearNotification(notification);
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Clear all button
            ValueListenableBuilder<List<SosNotificationModel>>(
              valueListenable: _notificationService.notificationsNotifier,
              builder: (context, notifications, _) {
                if (notifications.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _notificationService.clearAllNotifications();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff193869),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Clear All Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final SosNotificationModel notification;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SosLocationMapScreen(notification: notification),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'SOS Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Text(timeAgo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xff193869)),
                const SizedBox(width: 4),
                Text(
                  'From: ${notification.travelerName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff193869),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(notification.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openMap(context),
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('View on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff193869),
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}