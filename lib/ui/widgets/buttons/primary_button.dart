import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final Color? color;
  final BorderSide border;
  final double? borderRadius;

  const PrimaryButton({
    super.key,
    this.padding,
    required this.onPressed,
    required this.child,
    this.color,
    this.border = BorderSide.none,
    this.borderRadius,
  });

  PrimaryButton.text(
    String text, {
    TextStyle? textStyle,
    FontWeight? weight,
    Color? textColor,
    double? fontSize,
    required this.onPressed,
    this.padding,
    this.color,
    this.border = BorderSide.none,
    this.borderRadius,
  }) : child = Builder(
          builder: (context) => Text(
            text,
            style: (textStyle ?? context.textTheme.bodyLarge)?.copyWith(
              color: textColor ?? context.color.onPrimary,
              fontWeight: weight,
              fontSize: fontSize,
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    return RegularButton(
      color: color ?? context.buttonTheme.colorScheme?.primary,
      textColor: context.color.onPrimary,
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 12), side: border),
      onPressed: onPressed,
      child: child,
    );
  }
}
