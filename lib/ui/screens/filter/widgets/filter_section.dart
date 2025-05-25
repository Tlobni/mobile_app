import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeadingText(title, fontSize: 20, weight: FontWeight.w500),
        SizedBox(height: 20),
        child,
      ],
    );
  }
}
