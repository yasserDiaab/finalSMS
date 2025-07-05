import 'package:flutter/material.dart';
import 'package:pro/login/splash1.dart';
import 'package:pro/widgets/login_button.dart';

class LogoSplash extends StatelessWidget {
  const LogoSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 100,
          ),
          Image.asset(
            "assets/images/FOLLOWSAFE.jpg",
            height: 330,
            width: double.infinity,
          ),
          const SizedBox(
            height: 150,
          ),
          LoginButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Splash1();
                    },
                  ),
                );
              },
              label: 'Get Started',
              Color1: const Color(0xff193869),
              color2: Colors.white,
              color3: const Color(0xff193869))
        ],
      ),
    );
  }
}
