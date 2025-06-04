import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/app_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class HeadingText extends AppText {
  const HeadingText(
    super.text, {
    super.key,
    super.textAlign,
    super.maxLines,
    super.color,
    super.weight,
    super.fontSize,
    super.fontStyle,
    super.height,
  });

  @override
  TextStyle? getTextStyle(BuildContext context) => context.textTheme.titleMedium?.copyWith();
}
