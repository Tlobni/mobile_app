import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/ui/screens/widgets/side_colored_border_container.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class ItemPricingContainer extends StatelessWidget {
  const ItemPricingContainer({
    super.key,
    required this.price,
    required this.priceType,
    this.padding,
    this.priceFontSize,
    this.typeFontSize,
  });

  final double price;
  final String priceType;
  final EdgeInsets? padding;
  final double? priceFontSize;
  final double? typeFontSize;

  @override
  Widget build(BuildContext context) {
    return SideColoredBorderContainer(
      sideBorderColor: kColorSecondaryBeige,
      padding: padding,
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '\$${price}',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: priceFontSize),
          ),
          WidgetSpan(child: SizedBox(width: 2)),
          TextSpan(
            children: [
              TextSpan(text: '/'),
              WidgetSpan(child: SizedBox(width: 2)),
              TextSpan(text: priceType),
            ],
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: typeFontSize,
            ),
          ),
        ]),
      ),
    );
  }
}
