import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.minRating,
    required this.maxRating,
    required this.onChanged,
  });

  final double minRating;
  final double maxRating;
  final void Function(RangeValues values) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DescriptionText(
              "From ${minRating.toInt()} to ${maxRating.toInt()} Stars",
              weight: FontWeight.w500,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Display star icons to represent the range
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minimum rating stars
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < minRating.toInt() ? Icons.star : Icons.star_border,
                  color: index < minRating.toInt() ? Colors.amber : Colors.grey,
                  size: 16,
                );
              }),
            ),
            const DescriptionText("to"),
            // Maximum rating stars
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < maxRating.toInt() ? Icons.star : Icons.star_border,
                  color: index < maxRating.toInt() ? Colors.amber : Colors.grey,
                  size: 16,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RangeSlider(
          values: RangeValues(minRating, maxRating),
          min: 0,
          max: 5,
          divisions: 5,
          activeColor: context.color.primary,
          inactiveColor: Colors.grey.shade400,
          labels: RangeLabels(
            minRating.toInt().toString(),
            maxRating.toInt().toString(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
