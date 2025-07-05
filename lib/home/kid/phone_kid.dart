import 'package:flutter/material.dart';
import 'package:pro/home/kid/phone_otp.dart';

import 'package:pro/widgets/login_button.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00E5FF), Color(0xFF00BFA5)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 50),
            const Center(
              child: Text(
                "Advanced Settings",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Enter your phone number to access advanced settings",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: Image.asset(
                "assets/images/phone-call (1) 1.png",
                height: 330,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter your phone number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter your phone number")),
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const PhoneOtp();
                  }));
                }
              },
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.of(context).size.width * 0.5, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF41DB8E), Color(0xFF025F68)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            LoginButton(
              onPressed: () {
                Navigator.pop(context);
              },
              label: 'Cancel',
              Color1: Colors.white,
              color2: Colors.black,
              color3: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
