import 'package:flutter/material.dart';

class TermsCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const TermsCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Expanded(
          child: Text(
            '''

By agreeing to the terms and conditions, you are entering into a legally binding contract with the service provider.

''',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
