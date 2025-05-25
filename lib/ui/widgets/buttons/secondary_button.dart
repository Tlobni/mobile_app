import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class SecondaryButton extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    this.padding,
    required this.onPressed,
    required this.child,
  });

  SecondaryButton.text(
    String text, {
    TextStyle? textStyle,
    FontWeight? weight,
    required this.onPressed,
    this.padding,
  }) : child = Builder(
          builder: (context) => Text(
            text,
            style: (textStyle ?? context.textTheme.bodyLarge)?.copyWith(
              color: context.color.onSecondary,
              fontWeight: weight,
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    return RegularButton(
      color: context.buttonTheme.colorScheme?.secondary,
      textColor: context.color.onSecondary,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
