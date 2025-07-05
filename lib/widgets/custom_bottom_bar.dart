import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons; // قائمة الأيقونات

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.icons, // تمرير الأيقونات عند إنشاء العنصر
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10, // إضافة تأثير الظل
      child: SizedBox(
        height: 61,
        child: Container(
          height: 40, // تقليل حجم الـ BottomNavigationBar
          child: BottomNavigationBar(
            backgroundColor: const Color(0xffEBEEEF),
            type: BottomNavigationBarType.fixed,
            items: icons
                .map((icon) => _buildBottomNavigationBarItem(icon))
                .toList(),
            currentIndex: currentIndex,
            onTap: onTap,
            selectedItemColor: const Color(0xff193869),
            unselectedItemColor: const Color(0xff000000),
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(IconData icon) {
    final bool isSelected = icons.indexOf(icon) == currentIndex;
    return BottomNavigationBarItem(
      icon: Container(
        decoration: isSelected
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xff193869),
                    width: 2,
                  ),
                ),
              )
            : null,
        child: Icon(icon),
      ),
      label: '',
    );
  }
}
