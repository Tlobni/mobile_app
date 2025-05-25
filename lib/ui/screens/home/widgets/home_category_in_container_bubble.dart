import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';

class HomeCategoryInContainerBubble extends StatelessWidget {
  const HomeCategoryInContainerBubble(this.text, {super.key, this.fontSize, this.padding, this.color});

  final String text;
  final double? fontSize;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color ?? kColorSecondaryBeige),
        color: (color ?? kColorSecondaryBeige).withValues(alpha: 0.2),
      ),
      padding: padding ?? EdgeInsets.all(10),
      child: SmallText(
        text,
        fontSize: fontSize,
        weight: FontWeight.w500,
      ),
    );
  }
}
