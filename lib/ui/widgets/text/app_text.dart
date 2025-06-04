import 'package:flutter/material.dart';

abstract class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.color,
    this.weight,
    this.decoration,
    this.fontSize,
    this.height,
    this.fontStyle,
  });

  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final Color? color;
  final FontWeight? weight;
  final TextDecoration? decoration;
  final FontStyle? fontStyle;
  final double? fontSize;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
      style: (getTextStyle(context) ?? TextStyle()).copyWith(
        color: color,
        fontWeight: weight,
        decoration: decoration,
        fontStyle: fontStyle ?? FontStyle.normal,
        fontSize: fontSize,
        height: height,
      ),
    );
  }

  TextStyle? getTextStyle(BuildContext context);
}
