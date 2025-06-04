import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/utils/clippers/percentage_clipper.dart';

class ReviewsStars extends StatelessWidget {
  const ReviewsStars({
    super.key,
    required this.rating,
    required this.iconSize,
    required this.spacing,
  }) : assert(rating >= 0 && rating <= 5);

  final double rating;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _starRow(Icons.star_outline_rounded),
        _starRow(Icons.star_rounded, untilRating: true),
      ],
    );
  }

  Widget _starRow(IconData icon, {bool untilRating = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: spacing,
        children: [
          for (int i = 0; i < (untilRating ? rating.ceil() : 5); i++)
            Builder(builder: (context) {
              final child = Padding(
                padding: EdgeInsets.zero,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: kColorSecondaryBeige,
                  weight: 0.01,
                  opticalSize: iconSize,
                ),
              );
              if (!(untilRating && i == rating.floor())) return child;
              return ClipPath(
                clipper: PercentageClipper(percentage: rating - rating.floor(), fromTheEnd: false),
                child: child,
              );
            }),
        ],
      );
}
