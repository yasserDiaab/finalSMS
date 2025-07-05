import 'package:flutter/material.dart';

class HeaderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const HeaderButton(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  // fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: isSelected ? const Color(0xff193869) : Colors.grey)),
          // if (isSelected) Container(height: 2),
        ],
      ),
    );
  }
}
