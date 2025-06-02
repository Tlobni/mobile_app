import 'package:flutter/material.dart';
import 'package:non_uniform_border/non_uniform_border.dart';

class SideColoredBorderContainer extends StatelessWidget {
  const SideColoredBorderContainer({
    super.key,
    required this.sideBorderColor,
    this.padding,
    required this.child,
  });

  final Color sideBorderColor;
  final EdgeInsets? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: ShapeDecoration(
          shape: NonUniformBorder(
            leftWidth: 3,
            topWidth: 0,
            bottomWidth: 0,
            rightWidth: 0,
            color: sideBorderColor,
            borderRadius: BorderRadius.circular(5),
          ),
          color: Colors.grey.shade100.withValues(alpha: 0.8),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}
