import 'package:flutter/material.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/widgets/chat_icon.dart';
import 'package:pro/widgets/notification_icon.dart';

class HeaderProfile extends StatelessWidget {
  final bool showNotifications;
  final String userType; // 'supporter' or 'traveler'

  const HeaderProfile({
    super.key,
    this.showNotifications = true,
    this.userType = 'traveler', // Default to traveler
  });

  @override
  Widget build(BuildContext context) {
    // Get user name from cache
    final userName = CacheHelper.getData(key: ApiKey.name) ??
        CacheHelper.getData(key: "fullname") ??
        "User";

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage("assets/images/man.jpeg"),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                SizedBox(width: 5),
                Text(
                  'Cairo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(flex: 2),
        if (showNotifications) ...[
          NotificationIcon(userType: userType),
          MessengerIcon(userType: userType),
        ] else
          const SizedBox.shrink(),
      ],
    );
  }
}
