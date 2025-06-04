import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';

class HomeShimmerEffect extends StatelessWidget {
  const HomeShimmerEffect({
    super.key,
    this.width,
    this.height,
    this.itemCount,
    this.padding,
  });

  final double? width;
  final double? height;
  final int? itemCount;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final itemCount = this.itemCount ?? 3;
    final width = this.width ?? context.screenWidth * 0.85;
    final height = this.height ?? 400;
    final padding = this.padding ?? EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05);
    return IntrinsicHeight(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: List.generate(
            itemCount,
            (index) => CustomShimmer(
              width: width,
              height: height,
              borderRadius: 10,
            ),
          ).spaceBetween(18).toList(),
        ),
      ),
    );
  }
}
