import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const CustomTextField(
      {required this.hintText,
      required this.icon,
      required this.controller,
      this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              width: 1,
              color: Color(0xFF193869),
            )),
        hintText: hintText,
        hintStyle: TextStyle(
            color: Colors.grey[400], fontFamily: 'Poppins', fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 1),
      ),
    );
  }
}
