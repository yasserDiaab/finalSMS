import 'package:flutter/material.dart';

class OverlappingImages extends StatelessWidget {
  final String photo1;
  final String photo2;

  const OverlappingImages(
      {super.key, required this.photo1, required this.photo2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Stack(
        children: [
          Image.asset(
            photo1,
            width: 200,
          ),
          Positioned(
            left: 120,
            top: 50,
            child: Image.asset(
              photo2,
              width: 200,
            ),
          )
        ],
      ),
    );
  }
}
