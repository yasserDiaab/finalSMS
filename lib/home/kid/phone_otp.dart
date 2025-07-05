import 'package:flutter/material.dart';
import 'package:pro/home/kid/advanced_settings.dart';

import 'package:pro/widgets/controller_otp.dart';
import 'package:pro/widgets/text_field_otp.dart';

class PhoneOtp extends StatefulWidget {
  const PhoneOtp({super.key});

  @override
  State<PhoneOtp> createState() => _PhoneOtpState();
}

class _PhoneOtpState extends State<PhoneOtp> {
  final TextEditingController c1 = TextEditingController();
  final TextEditingController c2 = TextEditingController();
  final TextEditingController c3 = TextEditingController();
  final TextEditingController c4 = TextEditingController();

  void _updateState() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    c1.addListener(_updateState);
    c2.addListener(_updateState);
    c3.addListener(_updateState);
    c4.addListener(_updateState);
  }

  @override
  void dispose() {
    c1.removeListener(_updateState);
    c2.removeListener(_updateState);
    c3.removeListener(_updateState);
    c4.removeListener(_updateState);

    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00E1D4), Color(0xFF00B5A6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                "Enter Verification Code",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "We have sent a code to your phone number",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextFieldOTP(controller: c1, first: true, last: false),
                TextFieldOTP(controller: c2, first: false, last: false),
                TextFieldOTP(controller: c3, first: false, last: false),
                TextFieldOTP(controller: c4, first: false, last: true),
              ],
            ),
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return AdvancedSettings();
                  }));
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
            ),
            const SizedBox(height: 30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't you receive any code?",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11),
                ),
                SizedBox(width: 5),
                Text(
                  "Resend Code",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF00796B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
