import 'package:flutter/material.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/home/adult/notifications_page.dart';
import 'package:pro/home/adult/traveler_notifications_page.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/services/notification_service.dart';

class NotificationIcon extends StatefulWidget {
  final String userType;

  const NotificationIcon({
    super.key,
    this.userType = 'supporter',
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final NotificationService _notificationService = getIt<NotificationService>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SosNotificationModel>>(
      valueListenable: _notificationService.notificationsNotifier,
      builder: (context, notifications, _) {
        // For travelers, never show notification count
        final displayNotifications = widget.userType == 'supporter'
            ? notifications
            : <SosNotificationModel>[];
        final hasNotifications = displayNotifications.isNotEmpty;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Color(0xff193869),
                size: 28,
              ),
              onPressed: () {
                // Navigate to appropriate notifications page based on user type
                if (widget.userType == 'supporter') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationsPage(hideHeader: true),
                    ),
                  );
                } else {
                  // For travelers, navigate to their specific notifications page
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const TravelerNotificationsPage(hideHeader: true),
                    ),
                  );
                }
              },
            ),
            if (hasNotifications)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${displayNotifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
