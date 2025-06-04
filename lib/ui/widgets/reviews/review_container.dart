import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/reviews_stars.dart';
import 'package:tlobni/ui/screens/widgets/side_colored_border_container.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ReviewContainer extends StatelessWidget {
  const ReviewContainer(this.review, {super.key});

  final UserRatings review;

  @override
  Widget build(BuildContext context) {
    final reviewer = review.reviewer;
    if (reviewer == null) return SizedBox();
    return SideColoredBorderContainer(
      sideBorderColor: kColorSecondaryBeige,
      padding: EdgeInsets.all(15),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              spacing: 5,
              children: [
                ClipOval(child: UiUtils.getImage(reviewer.profile ?? '', height: 40, width: 40)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SmallText(reviewer.name ?? '', weight: FontWeight.bold),
                      IntrinsicHeight(
                        child: Row(
                          spacing: 10,
                          children: [
                            ReviewsStars(rating: review.ratings ?? 0, iconSize: 20, spacing: 0),
                            Expanded(child: SmallText(_reviewDateString(review.updatedAt), color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          SmallText(review.review ?? '', maxLines: 9),
        ],
      ),
    );
  }

  String _reviewDateString(String? updatedAt) {
    return UiUtils.dateToAgoString(updatedAt);
  }
}
