import 'package:flutter/material.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/widgets/header_profile.dart';

class TravelerNotificationsPage extends StatefulWidget {
  final bool hideHeader;

  const TravelerNotificationsPage({
    super.key,
    this.hideHeader = false,
  });

  @override
  State<TravelerNotificationsPage> createState() =>
      _TravelerNotificationsPageState();
}

class _TravelerNotificationsPageState extends State<TravelerNotificationsPage> {
  String _userType = 'traveler';

  @override
  void initState() {
    super.initState();
    // Determine user type from cache
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

            // Notifications list (always empty for traveler)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You will receive notifications here when available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}