import 'package:flutter/material.dart';

class QuranIcons extends StatelessWidget {
  final String assetName;
  final double width;
  final double height;
  const QuranIcons({
    Key? key,
    required this.width,
    required this.height,
    required this.assetName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetName,
      width: width,
      height: height,
    );
  }
}
