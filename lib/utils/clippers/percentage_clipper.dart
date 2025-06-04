import 'package:flutter/cupertino.dart';

class PercentageClipper extends CustomClipper<Path> {
  final double percentage;
  final bool fromTheEnd;

  PercentageClipper({
    required this.percentage,
    required this.fromTheEnd,
  });

  @override
  Path getClip(Size size) {
    final x = size.width;
    final y = size.height;
    if (fromTheEnd) {
      return Path()
        ..lineTo(x, 0)
        ..lineTo(x, y)
        ..lineTo(x * percentage, y)
        ..lineTo(x * percentage, 0)
        ..lineTo(x, 0)
        ..close();
    } else {
      return Path()
        ..lineTo(0, 0)
        ..lineTo(0, y)
        ..lineTo(x * percentage, y)
        ..lineTo(x * percentage, 0)
        ..lineTo(0, 0)
        ..close();
    }
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
