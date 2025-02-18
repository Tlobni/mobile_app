// ignore_for_file: file_names

import 'package:eClassify/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  const CustomShimmer(
      {super.key, this.height, this.width, this.borderRadius, this.margin});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
      highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
      child: Container(
        width: width,
        margin: margin,
        height: height ?? 10,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.shimmerContentColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 10)),
      ),
    );
  }
}
