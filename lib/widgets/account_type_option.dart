import 'package:flutter/material.dart';

class AccountTypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String imagePath;

  const AccountTypeOption(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          // color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? const Color(0xFF193869) : Colors.grey,
              width: 3),
          image:
              DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
