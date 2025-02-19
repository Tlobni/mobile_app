import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/data/cubits/fetch_my_reviews_cubit.dart';
import 'package:eClassify/data/cubits/my_item_review_report_cubit.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/data/model/my_review_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_hero_animation.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class MyReviewScreen extends StatefulWidget {
  const MyReviewScreen({
    super.key,
  });

  @override
  MyReviewScreenState createState() => MyReviewScreenState();

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(builder: (_) => MyReviewScreen());
  }
}

class MyReviewScreenState extends State<MyReviewScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController reviewController;
  //bool isExpanded = false;
  final TextEditingController _reportController = TextEditingController();

  @override
  void initState() {
    reviewController = ScrollController()..addListener(_reviewLoadMore);
    context.read<FetchMyRatingsCubit>().fetch();
    super.initState();
  }

  @override
  void dispose() {
    reviewController.removeListener(_reviewLoadMore);
    reviewController.dispose();

    super.dispose();
  }

  void _reviewLoadMore() async {
    if (reviewController.isEndReached()) {
      if (context.read<FetchMyRatingsCubit>().hasMoreData()) {
        context.read<FetchMyRatingsCubit>().fetchMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context,
          showBackButton: true, title: "myReview".translate(context)),
      backgroundColor: context.color.backgroundColor,
      body: ratingsListWidget(),
    );
  }

  Map<int, int> getRatingCounts(List<MyReviewModel> userRatings) {
    // Initialize the counters for each rating
    Map<int, int> ratingCounts = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    // Iterate through the user ratings list and count each rating
    if (userRatings.isNotEmpty) {
      for (var rating in userRatings) {
        int ratingValue = (rating.ratings ?? 0.0).toInt();

        // If the rating is between 1 and 5, increment the corresponding counter
        if (ratingCounts.containsKey(ratingValue)) {
          ratingCounts[ratingValue] = ratingCounts[ratingValue]! + 1;
        }
      }
    }

    return ratingCounts;
  }

  Widget buildRatingsShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
            border: Border.all(width: 1.5, color: context.color.borderColor),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            CustomShimmer(
              height: 120,
              width: 100,
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomShimmer(
                  width: 100,
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 150,
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 120,
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 80,
                  height: 10,
                  borderRadius: 7,
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget ratingsListWidget() {
    return BlocBuilder<FetchMyRatingsCubit, FetchMyRatingsState>(
        builder: (context, state) {
      if (state is FetchMyRatingsInProgress) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: 10,
          itemBuilder: (context, index) {
            return buildRatingsShimmer(context);
          },
        );
      }

      if (state is FetchMyRatingsFail) {
        return Center(
          child: CustomText(state.error),
        );
      }
      if (state is FetchMyRatingsSuccess) {
        if (state.ratings.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context.read<FetchMyRatingsCubit>().fetch();
              },
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average Rating & Breakdown Section

              _buildMySummary(state.averageRating!, state.total, state.ratings),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  controller: reviewController,
                  itemCount: state.ratings.length,
                  itemBuilder: (context, index) {
                    MyReviewModel ratings = state.ratings[index];

                    return _buildReviewCard(ratings, index);
                  },
                ),
              ),
              if (state.isLoadingMore) UiUtils.progress()
            ],
          ),
        );
      }
      return Container();
    });
  }

  // Rating summary widget (similar to the top section of your image)
  Widget _buildMySummary(
      double averageRating, int total, List<MyReviewModel> ratings) {
    Map<int, int> ratingCounts = getRatingCounts(ratings);
    return Card(
      color: context.color.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average Rating and Total Ratings
            Row(
              children: [
                Column(
                  children: [
                    Text(averageRating.toStringAsFixed(2).toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color: context.color.textDefaultColor,
                                fontWeight: FontWeight.bold)),
                    CustomRatingBar(
                      rating: averageRating,
                      itemSize: 25.0,
                      activeColor: Colors.amber,
                      inactiveColor: context.color.backgroundColor.darken(10),
                      allowHalfRating: true,
                    ),
                    SizedBox(height: 3),
                    CustomText(
                      "${total.toString()}\t${"ratings".translate(context)}",
                      fontSize: context.font.large,
                    ),
                  ],
                ),
                SizedBox(width: 20),
                // Star rating breakdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRatingBar(5, ratingCounts[5]!.toInt(), total),
                      _buildRatingBar(4, ratingCounts[4]!.toInt(), total),
                      _buildRatingBar(3, ratingCounts[3]!.toInt(), total),
                      _buildRatingBar(2, ratingCounts[2]!.toInt(), total),
                      _buildRatingBar(1, ratingCounts[1]!.toInt(), total),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rating bar with percentage
  Widget _buildRatingBar(int starCount, int ratingCount, int total) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          child: CustomText(
            "$starCount",
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          width: 2,
        ),
        Icon(
          Icons.star_rounded,
          size: 15,
          color: context.color.textDefaultColor,
        ),
        SizedBox(width: 5),
        Expanded(
          child: LinearProgressIndicator(
            value: ratingCount / total,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.darken(20)),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 10,
          child: CustomText(
            ratingCount.toString(),
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
            color: context.color.textDefaultColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String dateTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate).toLocal();

    // Get the current date
    DateTime now = DateTime.now();

    // Create formatters for date and time
    DateFormat dateFormat = DateFormat('MMM d, yyyy');
    DateFormat timeFormat = DateFormat('h:mm a');

    // Check if the given date is today
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      // Return just the time if the date is today
      String formattedTime = timeFormat.format(dateTime);
      return formattedTime; // Example output: 10:16 AM
    } else {
      // Return the full date if the date is not today
      String formattedDate = dateFormat.format(dateTime);

      return formattedDate;
    }
  }

  // Individual review card widget
  Widget _buildReviewCard(MyReviewModel ratings, int index) {
    return Card(
      color: context.color.secondaryColor,
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ratings.buyer!.profile == "" || ratings.buyer!.profile == null
                ? CircleAvatar(
                    backgroundColor: context.color.territoryColor,
                    child: SvgPicture.asset(
                      AppIcons.profile,
                      colorFilter: ColorFilter.mode(
                          context.color.buttonColor, BlendMode.srcIn),
                    ),
                  )
                : CustomImageHeroAnimation(
                    type: CImageType.Network,
                    image: ratings.buyer!.profile,
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        ratings.buyer!.profile!,
                      ),
                    ),
                  ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        ratings.buyer!.name!,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      if (ratings.reportStatus == null)
                        InkWell(
                          child: UiUtils.getSvg(AppIcons.reportReviewIcon,
                              height: 20,
                              width: 20,
                              color: context.color.textDefaultColor),
                          onTap: () {
                            reportAlertDialog(ratings.id!);
                          },
                        )
                    ],
                  ),
                  itemDetails(ratings, index),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void reportAlertDialog(int sellerReviewId) async {
    await showDialog(
      context: context,
      barrierDismissible: true,

      // Set to false if you don't want the dialog to close by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(child: CustomText("reportReview".translate(context))),
          content: BlocListener<AddMyItemReviewReportCubit,
              AddMyItemReviewReportState>(
            listener: (context, state) {
              if (state is AddMyItemReviewReportInSuccess) {
                Widgets.hideLoder(context);
                Navigator.pop(context);
                context.read<FetchMyRatingsCubit>().updateReportReason(
                    sellerReviewId, _reportController.text.trim().toString());
                HelperUtils.showSnackBarMessage(context, state.responseMessage);
                _reportController.clear();
              }
              if (state is AddMyItemReviewReportFailure) {
                Widgets.hideLoder(context);
                Navigator.pop(context);
                HelperUtils.showSnackBarMessage(
                    context, state.error.toString());
              }
              if (state is AddMyItemReviewReportInProgress) {
                Widgets.showLoader(context);
              }
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        onChanged: (value) {
                          setStater(() {});
                          setState(() {});
                        },
                        controller: _reportController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide:
                                BorderSide(color: context.color.territoryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(
                              color:
                                  context.color.textLightColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          UiUtils.buildButton(context, onPressed: () {
                            _reportController.clear();
                            Navigator.of(context).pop();
                          },
                              buttonTitle: "cancelBtnLbl".translate(context),
                              radius: 8,
                              fontSize: 12,
                              width: context.screenWidth / 4,
                              textColor: context.color.textDefaultColor,
                              buttonColor: context.color.backgroundColor,
                              showElevation: false,
                              height: 39),
                          UiUtils.buildButton(context, showElevation: false,
                              onPressed: () {
                            context
                                .read<AddMyItemReviewReportCubit>()
                                .addMyItemReviewReport(
                                    sellerReviewId: sellerReviewId,
                                    reportReason: _reportController.text
                                        .trim()
                                        .toString());
                          },
                              fontSize: 12,
                              disabled: _reportController.text
                                  .trim()
                                  .toString()
                                  .isEmpty,
                              disabledColor: context.color.deactivateColor,
                              buttonTitle: "submitBtnLbl".translate(context),
                              radius: 8,
                              width: context.screenWidth / 4,
                              textColor: context.color.secondaryColor,
                              buttonColor: context.color.territoryColor,
                              height: 39),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget itemDetails(MyReviewModel ratings, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 5),
              CustomText(
                ratings.item!.name!,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  CustomRatingBar(
                    rating: ratings.ratings!,
                    itemSize: 20.0,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.grey.shade300,
                    allowHalfRating: true,
                  ),
                  SizedBox(width: 5),
                  CustomText(ratings.ratings!.toString())
                ],
              ),
              SizedBox(height: 5),
              //CustomText(ratings.review!).color(context.color.textDefaultColor),
              SizedBox(
                width: context.screenWidth * 0.63,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Measure the rendered text
                    final span = TextSpan(
                      text: "${ratings.review!}\t",
                      style: TextStyle(
                        color: context.color.textDefaultColor,
                      ),
                    );
                    final tp = TextPainter(
                      text: span,
                      maxLines: 2,
                      // Maximum number of lines before overflow
                      textDirection: ui.TextDirection.ltr,
                    );
                    tp.layout(maxWidth: constraints.maxWidth);

                    final isOverflowing = tp.didExceedMaxLines;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                            child: CustomText(
                          "${ratings.review!}\t",
                          maxLines: ratings.isExpanded! ? null : 2,
                          softWrap: true,
                          overflow: ratings.isExpanded!
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        )),
                        if (isOverflowing) // Conditionally show the button
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 3),
                            child: GestureDetector(
                              onTap: () {
                                context
                                    .read<FetchMyRatingsCubit>()
                                    .updateIsExpanded(index);
                              },
                              child: CustomText(
                                ratings.isExpanded!
                                    ? "readLessLbl".translate(context)
                                    : "readMoreLbl".translate(context),
                                color: context.color.territoryColor,
                                fontWeight: FontWeight.w400,
                                fontSize: context.font.small,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (ratings.createdAt != null) ...[
                SizedBox(height: 5),
                CustomText(
                  dateTime(ratings.createdAt!),
                  fontSize: context.font.small,
                  color: context.color.textDefaultColor.withOpacity(0.3),
                ),
              ],
              if (ratings.reportReason != null) ...[
                SizedBox(height: 5),
                Divider(),
                CustomText(
                  "${"reportReason".translate(context)}: ${ratings.reportReason}",
                  fontSize: context.font.small,
                  color: context.color.textDefaultColor.withOpacity(0.3),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: UiUtils.imageType(ratings.item!.image!,
                fit: BoxFit.cover, height: 70, width: 70),
          ),
        ),
      ],
    );
  }

  Widget buildItemsShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: ListView(
        children: [
          Row(
            children: [
              CustomShimmer(
                height: MediaQuery.of(context).size.height / 3.5,
                width: context.screenWidth / 2.3,
              ),
              SizedBox(
                width: 10,
              ),
              CustomShimmer(
                height: MediaQuery.of(context).size.height / 3.5,
                width: context.screenWidth / 2.3,
              ),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: [
              CustomShimmer(
                height: MediaQuery.of(context).size.height / 3.5,
                width: context.screenWidth / 2.3,
              ),
              SizedBox(
                width: 10,
              ),
              CustomShimmer(
                height: MediaQuery.of(context).size.height / 3.5,
                width: context.screenWidth / 2.3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomRatingBar extends StatelessWidget {
  final double rating; // The rating value (e.g., 4.5)

  final double itemSize; // Size of each star icon
  final Color activeColor; // Color for filled stars
  final Color inactiveColor; // Color for unfilled stars
  final bool allowHalfRating; // Whether to allow half-star ratings

  const CustomRatingBar({
    Key? key,
    required this.rating,
    this.itemSize = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        // Determine whether to display a full star, half star, or empty star
        IconData icon;
        if (index < rating.floor()) {
          icon = Icons.star_rounded; // Full star
        } else if (allowHalfRating && index < rating) {
          icon = Icons.star_half_rounded; // Half star
        } else {
          icon = Icons.star_rounded; // Empty star
        }

        return Icon(
          icon,
          color: index < rating ? activeColor : inactiveColor,
          size: itemSize,
        );
      }),
    );
  }
}
