import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';

class HomeTitleViewAll extends StatelessWidget {
  const HomeTitleViewAll({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.child,
  });

  final String title;
  final VoidCallback? onViewAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            children: [
              Expanded(
                child: HeadingText(
                  title,
                  fontSize: 20,
                  weight: FontWeight.w700,
                ),
              ),
              if (onViewAll != null)
                UnelevatedRegularButton(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(10),
                  onPressed: onViewAll,
                  child: SmallText('View All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
