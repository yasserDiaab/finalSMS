import 'package:flutter/material.dart';
import 'header_button.dart';

class HeaderSection extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const HeaderSection({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 38),
          const Text(
            "Follow Safe",
            style: TextStyle(
              fontSize: 20,
              color: Color(0xff193869),
              // fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Welcome To",
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[800],
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            "Follow Safe Assistance",
            style: TextStyle(
                fontSize: 20, color: Colors.grey[800], fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HeaderButton(
                  label: "Login", isSelected: isLogin, onTap: onToggle),
              const SizedBox(width: 50),
              HeaderButton(
                  label: "Sign Up", isSelected: !isLogin, onTap: onToggle),
            ],
          ),
        ],
      ),
    );
  }
}
