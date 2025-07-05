import 'package:flutter/material.dart';
import 'package:pro/home/adult/chat_list_supporter.dart';
import 'package:pro/home/adult/chat_list_traveler.dart';


class MessengerIcon extends StatelessWidget {
  final String userType;

  const MessengerIcon({
    super.key,
    this.userType = 'supporter',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.message, // Messenger Icon
        color: Color(0xff193869),
        size: 28,
      ),
      onPressed: () {
        // Navigate to appropriate page based on user type
        if (userType == 'supporter') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>  MessagesScreen(),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MessagesScreenn()
            ),
          );
        }
      },
    );
  }
}
