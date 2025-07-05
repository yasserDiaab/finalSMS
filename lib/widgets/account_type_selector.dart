import 'package:flutter/material.dart';
import 'account_type_option.dart';

class AccountTypeSelector extends StatelessWidget {
  final bool isKidSelected;
  final ValueChanged<bool> onSelected;

  const AccountTypeSelector(
      {required this.isKidSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AccountTypeOption(
          label: "Kid",
          isSelected: isKidSelected,
          onTap: () => onSelected(true),
          imagePath: 'assets/images/kid.png',
        ),
        const SizedBox(width: 50),
        AccountTypeOption(
          label: "Adult",
          isSelected: !isKidSelected,
          onTap: () => onSelected(false),
          imagePath: 'assets/images/adult.png',
        ),
      ],
    );
  }
}
