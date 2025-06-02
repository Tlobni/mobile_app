import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/home/widgets/home_category_in_container_bubble.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ProviderHomeScreenContainer extends StatelessWidget {
  const ProviderHomeScreenContainer({
    super.key,
    required this.user,
    this.onPressed,
    this.goToProviderDetailsScreenOnPressed = true,
    this.withBorder = true,
    this.padding,
    this.additionalDetails,
    this.categoriesBuilder,
    this.nameFontSize,
    this.nameFontWeight,
  });

  final User user;
  final double? nameFontSize;
  final FontWeight? nameFontWeight;
  final VoidCallback? onPressed;
  final bool goToProviderDetailsScreenOnPressed;
  final bool withBorder;
  final EdgeInsets? padding;
  final Widget? additionalDetails;
  final Widget Function(List<String> categoryNames)? categoriesBuilder;

  @override
  Widget build(BuildContext context) {
    return UnelevatedRegularButton(
      onPressed: onPressed ??
          (goToProviderDetailsScreenOnPressed
              ? () => Navigator.pushNamed(
                    context,
                    Routes.sellerProfileScreen,
                    arguments: {
                      "model": user,
                      "rating": user.averageRating ?? 0.0,
                      "total": user.totalReviews ?? 0,
                    },
                  )
              : null),
      color: Colors.white,
      disabledColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: withBorder ? BorderSide(color: context.color.secondary.withValues(alpha: 0.7), width: 2) : BorderSide.none,
      ),
      padding: padding ?? EdgeInsets.all(14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            IntrinsicWidth(
              child: Column(
                children: [
                  // if (user.profile != null)
                  Builder(builder: (context) {
                    double size = 90;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.color.secondary.withValues(alpha: 0.7), width: 4),
                      ),
                      height: size,
                      width: size,
                      child: ClipOval(child: UiUtils.getImage(user.profile ?? '', height: size)),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (user.isFeatured ?? false)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                      decoration: BoxDecoration(
                        color: context.color.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: context.color.onPrimary, size: 12),
                          const SizedBox(width: 3),
                          SmallText('Featured', color: context.color.onPrimary, fontSize: 10),
                        ],
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: DescriptionText(user.name ?? '', fontSize: nameFontSize ?? 15, maxLines: 1, weight: nameFontWeight)),
                      if ((user.isVerified ?? 0) == 1) ...[
                        const SizedBox(width: 5),
                        Icon(Icons.verified, size: 18, color: kColorSecondaryBeige),
                      ]
                    ],
                  ),
                  if (user.categories?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    categoriesBuilder?.call(user.categories ?? []) ??
                        Row(
                          children: [
                            HomeCategoryInContainerBubble(
                              '${user.categories?.first}${(user.categories?.length ?? 0) > 1 ? ' +${user.categories!.length - 1}' : ''}',
                              fontSize: 12,
                            ),
                          ],
                        ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: kColorSecondaryBeige, size: 20),
                      SizedBox(width: 5),
                      SmallText(
                        (user.averageRating ?? 0).toStringAsFixed(1),
                        fontSize: 14,
                        color: kColorSecondaryBeige.withValues(alpha: 1),
                      ),
                      SizedBox(width: 5),
                      SmallText('(${user.totalReviews ?? 0})', fontSize: 14),
                    ],
                  ),
                  if (user.hasLocation) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          size: 20,
                          color: context.color.primary,
                        ),
                        SizedBox(width: 5),
                        Text(user.location!, style: context.textTheme.bodySmall),
                      ],
                    ),
                  ],
                  if (additionalDetails != null) ...[
                    SizedBox(height: 10),
                    additionalDetails!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
