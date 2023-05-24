import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/reuseablewidgets.dart';
import 'app_colors.dart';

class NotoNastaliqUrduRegular extends StatelessWidget {
  final String text;
  final TextDirection textDirection;

  const NotoNastaliqUrduRegular({
    Key? key,
    required this.text,
    required this.textDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: UC.uv.selectedTranslationFontSize,
        fontFamily: "NotoNastaliqUrdu-Regular",
      ),
      textAlign: TextAlign.justify,
      textDirection: textDirection,
    );
  }
}

class ScheherazadeNewBold extends StatelessWidget {
  final String arabic;
  final int number;

  const ScheherazadeNewBold({
    Key? key,
    required this.arabic,
    required this.number,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$arabic﴿${arabicNumeric(number)}﴾',
      style: TextStyle(
        fontSize: UC.uv.selectedArabicFontSize,
        fontFamily: "ScheherazadeNew-Bold",
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}

class RobotoRegular11 extends StatelessWidget {
  final String title;
  const RobotoRegular11({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.whiteWithOpacity,
      ),
    );
  }
}

class RobotoRegular14 extends StatelessWidget {
  final String title;
  const RobotoRegular14({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
    );
  }
}
class RobotoRegular16 extends StatelessWidget {
  final String title;
  const RobotoRegular16({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
    );
  }
}

class RobotoRegular18 extends StatelessWidget {
  final String title;
  const RobotoRegular18({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
    );
  }
}

class RobotoSemiBold22 extends StatelessWidget {
  final String title;
  const RobotoSemiBold22({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.green,
      ),
    );
  }
}

class RobotoSemiBold18 extends StatelessWidget {
  final String title;
  final bool isYesOrDone;
  const RobotoSemiBold18({
    Key? key,
    required this.title,
    required this.isYesOrDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isYesOrDone ? AppColors.white : AppColors.green,
      ),
    );
  }
}

class RobotoSemiBold14 extends StatelessWidget {
  final String title;
  const RobotoSemiBold14({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.whiteWithOpacity_2,
      ),
    );
  }
}

class RobotoSemiBold16 extends StatelessWidget {
  final String title;
  const RobotoSemiBold16({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }
}

class RobotoSemiBold13 extends StatelessWidget {
  final String title;
  const RobotoSemiBold13({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }
}
