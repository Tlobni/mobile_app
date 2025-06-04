import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/home/widgets/home_category_in_container_bubble.dart';
import 'package:tlobni/ui/screens/widgets/item_pricing_container.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/iterable.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ItemContainer extends StatelessWidget {
  const ItemContainer({
    super.key,
    required this.item,
    required this.small,
    this.onPressed,
    this.showTypeTag = false,
  });

  final ItemModel item;
  final VoidCallback? onPressed;
  final bool small;
  final bool showTypeTag;

  @override
  Widget build(BuildContext context) {
    final user = item.user;
    final price = item.price;
    final priceType = item.priceType;
    final name = item.name;
    final location = item.location;
    final categoryName = item.category?.name;

    final tags = [
      if (item.expirationDate != null) _daysLeftUntilExpiryString(item.expirationDate),
      // ...[
      if (item.isWomenExclusive) 'Women only',
      if (item.isCorporatePackage) 'Corporate',
      // ],
    ].whereNotNull();

    return RegularButton(
      onPressed: onPressed ??
          () {
            Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {"model": item});
          },
      color: context.color.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        //image
                        _image(),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              //provider details
                              if (user != null) _providerDetails(user),
                              SizedBox(height: small ? 6 : 12),

                              //name
                              if (name != null) _name(name),

                              SizedBox(height: small ? 10 : 20),

                              // pricing
                              if (price != null && priceType != null) _pricing(price, priceType),

                              SizedBox(height: small ? 10 : 15),

                              //location
                              if (location != null) _location(location),
                              SizedBox(height: small ? 5 : 20),
                              if (categoryName != null) _category(categoryName),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (small) ...[
            if (item.isFeature ?? false)
              Positioned(
                top: 10,
                left: showTypeTag ? null : 10,
                right: showTypeTag ? 10 : null,
                child: _smallFeaturedTagContainer(),
              ),
            if (showTypeTag)
              Positioned(
                top: 10,
                left: 10,
                child: _typeTagContainer(),
              )
          ] else
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: tags.map(_tagContainer).spaceBetween(10).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _tagContainer(String tag) => Builder(builder: (context) {
        return Container(
          padding: EdgeInsets.all(small ? 7 : 10),
          decoration: BoxDecoration(
            border: Border.all(color: context.color.onPrimary),
            borderRadius: BorderRadius.circular(8),
            color: context.color.primary,
          ),
          child: Text(
            tag,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.color.onPrimary,
              fontSize: small ? 11 : 13,
            ),
          ),
        );
      });

  Widget _image() => UiUtils.getImage(
        item.image ?? "",
        height: small ? 130 : 200,
        fit: BoxFit.cover,
      );

  Widget _providerDetails(User user) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            double size = small ? 20 : 30;
            return Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kColorSecondaryBeige, width: 2),
              ),
              child: ClipOval(
                child: UiUtils.getImage(
                  user.profile ?? '',
                  height: size,
                ),
              ),
            );
          }),
          SizedBox(width: small ? 7 : 10),
          Expanded(
            child: SmallText(
              user.name ?? '',
              weight: FontWeight.w500,
              fontSize: small ? 11 : null,
              maxLines: 1,
            ),
          )
        ],
      );

  Widget _name(String name) => DescriptionText(
        name.trim(),
        maxLines: 2,
        weight: FontWeight.w500,
        fontSize: small ? 15 : null,
      );

  Widget _pricing(double price, String priceType) => ItemPricingContainer(
        price: price,
        priceType: priceType,
        priceFontSize: small ? 14 : null,
        typeFontSize: small ? 12 : null,
        padding: small ? EdgeInsets.all(8) : null,
      );

  Widget _location(String location) => Builder(builder: (context) {
        return Row(
          children: [
            Icon(
              Icons.location_pin,
              size: small ? 10 : 13,
              color: Colors.grey.shade700,
            ),
            SizedBox(width: 2),
            Expanded(
              child: Text(
                location,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontSize: small ? 10 : null,
                ),
              ),
            ),
          ],
        );
      });

  Widget _category(String categoryName) => Row(
        children: [
          Flexible(
            child: HomeCategoryInContainerBubble(
              categoryName,
              fontSize: small ? 10 : null,
              color: small ? Color(0xffc6d2e1) : null,
              padding: small ? EdgeInsets.all(5) : null,
            ),
          ),
        ],
      );

  String? _daysLeftUntilExpiryString(DateTime? expirationDate) {
    if (expirationDate == null) return null;
    final diff = expirationDate.difference(DateTime.now()).abs();
    return '${max(0, diff.inDays)} Days Left';
  }

  Widget _smallFeaturedTagContainer() => Builder(builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: context.color.secondary,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.white, size: 10),
              SizedBox(width: 4),
              SmallText(
                'Featured',
                color: context.color.onSecondary,
                weight: FontWeight.w500,
                fontSize: 10,
              ),
            ],
          ),
        );
      });

  Widget _typeTagContainer() => _tagContainer(switch (item.type) {
        'service' => 'Service',
        'experience' => 'Experience',
        _ => '',
      });
}
