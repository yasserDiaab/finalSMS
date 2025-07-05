import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const SocialLoginButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          side: const BorderSide(
              style: BorderStyle.solid, color: Colors.grey, width: 0.8),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: TextStyle(
              color: Colors.grey[800], fontFamily: 'Poppins', fontSize: 13),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
