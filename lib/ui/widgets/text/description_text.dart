import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/app_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class DescriptionText extends AppText {
  const DescriptionText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.color,
    super.weight,
    super.decoration,
    super.fontSize,
    super.height,
    super.fontStyle,
  });

  @override
  TextStyle? getTextStyle(BuildContext context) => context.textTheme.bodyMedium;
}
