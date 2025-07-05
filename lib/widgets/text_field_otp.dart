import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldOTP extends StatelessWidget {
  const TextFieldOTP(
      {Key? key,
      required this.first,
      required this.last,
      required this.controller})
      : super(key: key);
  final bool first;
  final bool last;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        color: Colors.white,
        border: Border.all(
          width: 1.5,
          color: Colors.grey,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          if (value.isNotEmpty && last == false) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && first == false) {
            FocusScope.of(context).previousFocus();
          }
        },
        keyboardType: TextInputType.number,
        inputFormatters: [LengthLimitingTextInputFormatter(1)],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30),
        decoration: InputDecoration(
          border: InputBorder.none,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.width / 5,
            maxWidth: MediaQuery.of(context).size.width / 5,
          ),
        ),
      ),
    );
  }
}
