import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/home/widgets/home_title_view_all.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.error,
    required this.isLoading,
    required this.shimmerEffect,
    required this.child,
    required this.isEmpty,
  });

  final String title;
  final VoidCallback onViewAll;
  final bool isLoading;
  final Widget shimmerEffect;
  final Widget child;
  final bool isEmpty;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (isEmpty && error == null && !isLoading) return SizedBox();
    return HomeTitleViewAll(
      title: title,
      onViewAll: onViewAll,
      child: isLoading
          ? shimmerEffect
          : error != null
              ? DescriptionText(error!)
              : isEmpty
                  ? SizedBox()
                  : child,
    );
  }
}
