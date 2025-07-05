import 'package:flutter/material.dart';

class CustomPasswordField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final TextEditingController controller;
  CustomPasswordField(
      {required this.hintText,
      required this.icon,
      required this.isPasswordVisible,
      required this.onToggleVisibility,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Color(0xFF193869))),
        hintText: hintText,
        hintStyle: TextStyle(
            color: Colors.grey[400], fontFamily: 'Poppins', fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey)),
        contentPadding: EdgeInsets.symmetric(vertical: 1),
      ),
    );
  }
}
