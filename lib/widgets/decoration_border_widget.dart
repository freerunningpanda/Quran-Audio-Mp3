import 'package:flutter/material.dart';

class DecorationBorderWidget extends StatelessWidget {
  final Widget child;
  final double? width;
  const DecorationBorderWidget({
    Key? key,
    required this.child,
    this.width
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 2,
            blurStyle: BlurStyle.normal,
            color: theme.shadowColor,
          ),
        ],
      ),
      width: width,

      child: child,
    );
  }
}
