import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color Color1;
  final Color color2;
  final Color color3;

  LoginButton(
      {Key? key,
      required this.onPressed,
      required this.label,
      required this.Color1,
      required this.color2,
      required this.color3})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 330,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          side: BorderSide(color: color3, width: 1),
          backgroundColor: Color1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color2,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
