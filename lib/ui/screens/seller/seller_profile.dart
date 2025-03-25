import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/add_user_review_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_item_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/review_dialog.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_hero_animation.dart';
import 'package:tlobni/utils/custom_silver_grid_delegate.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class SellerProfileScreen extends StatefulWidget {
  final User model;
  final double? rating;
  final int? total;

  const SellerProfileScreen({
    super.key,
    required this.model,
    this.rating,
    this.total,
  });

  @override
  SellerProfileScreenState createState() => SellerProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;

    print("SellerProfileScreen route called with arguments: $arguments");

    if (arguments == null || arguments['model'] == null) {
      print("Warning: Missing model in seller profile route arguments!");
    }

    return BlurredRouter(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => FetchSellerItemsCubit(),
                ),
                BlocProvider(
                  create: (context) => FetchSellerRatingsCubit(),
                ),
              ],
              child: SellerProfileScreen(
                model: arguments?['model'],
                rating: arguments?['rating'],
                total: arguments?['total'],
                // from: arguments?['from'],
              ),
            ));
  }
}

class SellerProfileScreenState extends State<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  //bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for changes in tab selection
    _tabController.addListener(() {
      print("Tab changed to index: ${_tabController.index}");
      setState(() {});
    });

    // Load data on initState
    Future.microtask(() {
      if (widget.model.id != null) {
        print("Initializing seller profile with ID: ${widget.model.id}");
        context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.model.id!);
        context
            .read<FetchSellerRatingsCubit>()
            .fetch(sellerId: widget.model.id!);
      } else {
        print("Error: widget.model.id is null in seller profile");
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMore() async {
    print("load more");

    if (context.read<FetchSellerItemsCubit>().hasMoreData()) {
      context
          .read<FetchSellerItemsCubit>()
          .fetchMore(sellerId: widget.model.id!);
    }
  }

  void _reviewLoadMore() async {
    if (context.read<FetchSellerRatingsCubit>().hasMoreData()) {
      context
          .read<FetchSellerRatingsCubit>()
          .fetchMore(sellerId: widget.model.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("_tabController.index***${_tabController.index}");
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        floatingActionButton: isBusinessOrExpertProfile()
            ? FloatingActionButton(
                onPressed: () {
                  print("FloatingActionButton pressed");
                  if (context.read<FetchSellerRatingsCubit>().state
                      is FetchSellerRatingsSuccess) {
                    final state = context.read<FetchSellerRatingsCubit>().state
                        as FetchSellerRatingsSuccess;
                    if (state.seller != null) {
                      _showReviewDialog(state.seller!);
                    } else {
                      print("Cannot show review dialog: seller is null");
                      HelperUtils.showSnackBarMessage(
                          context, "Cannot add review at this time",
                          messageDuration: 3);
                    }
                  } else {
                    // If the ratings state isn't loaded yet, use the widget.model
                    // to create a basic Seller object for the review dialog
                    print("Using widget.model for review dialog");
                    Seller seller = Seller(
                        id: widget.model.id,
                        name: widget.model.name,
                        profile: widget.model.profile);
                    _showReviewDialog(seller);
                  }
                },
                backgroundColor: context.color.territoryColor,
                child:
                    Icon(Icons.rate_review, color: context.color.buttonColor),
              )
            : null,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              leading: Material(
                clipBehavior: Clip.antiAlias,
                color: Colors.transparent,
                type: MaterialType.circle,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: RotatedBox(
                        quarterTurns:
                            Directionality.of(context) == ui.TextDirection.rtl
                                ? 2
                                : -4,
                        child: UiUtils.getSvg(AppIcons.arrowLeft,
                            fit: BoxFit.none,
                            color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                ),
              ),
              //automaticallyImplyLeading: false,
              pinned: true,

              expandedHeight: (widget.model.createdAt != null &&
                      widget.model.createdAt != '')
                  ? context.screenHeight / 2.3
                  : context.screenHeight / 2.9,
              backgroundColor: context.color.secondaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: widget.model.profile != null
                                  ? UiUtils.getImage(widget.model.profile!,
                                      fit: BoxFit.fill, width: 95, height: 95)
                                  : UiUtils.getSvg(AppIcons.defaultPersonLogo,
                                      color: context.color.territoryColor,
                                      fit: BoxFit.none,
                                      width: 95,
                                      height: 95),
                            ),
                          ),
                          if (widget.model.isVerified == 1)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -10,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: context.color.forthColor),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      UiUtils.getSvg(AppIcons.verifiedIcon,
                                          width: 14, height: 14),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      CustomText(
                                        "verifiedLbl".translate(context),
                                        color: context.color.secondaryColor,
                                        fontWeight: FontWeight.w500,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      CustomText(
                        widget.model.name!,
                        color: context.color.textDefaultColor,
                        fontWeight: FontWeight.w600,
                      ),
                      if (widget.model.createdAt != null &&
                          widget.model.createdAt != '') ...[
                        SizedBox(
                          height: 7,
                        ),
                        CustomText(
                          "${"memberSince".translate(context)}\t${UiUtils.monthYearDate(widget.model.createdAt!)}",
                          color: context.color.textDefaultColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                      if (widget.rating != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(Icons.star_rounded,
                                      size: 18,
                                      color: context
                                          .color.textDefaultColor), // Star icon
                                ),
                                TextSpan(
                                  text:
                                      '\t${widget.rating!.toStringAsFixed(2).toString()}',
                                  // Rating value
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.color.textDefaultColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '  |  ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.color.textDefaultColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${widget.total}\t${"ratings".translate(context)}',
                                  // Rating count text
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.color.textDefaultColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    border: Border(
                      top: BorderSide(
                          color: context.color.backgroundColor, width: 2.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: context.color.territoryColor,
                        labelColor: context.color.territoryColor,
                        labelStyle: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w500),
                        unselectedLabelColor:
                            context.color.textDefaultColor.withOpacity(0.7),
                        unselectedLabelStyle: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w500),
                        tabs: [
                          Tab(text: 'liveAds'.translate(context)),
                          Tab(text: 'ratings'.translate(context)),
                        ],
                      ),
                      Divider(
                        height: 0,
                        thickness: 2,
                        color: context.color.textDefaultColor.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: SafeArea(
            top: false,
            child: TabBarView(
              controller: _tabController,
              children: [
                liveAdsWidget(),
                ratingsListWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget liveAdsWidget() {
    return BlocBuilder<FetchSellerItemsCubit, FetchSellerItemsState>(
        builder: (context, state) {
      if (state is FetchSellerItemsInProgress) {
        return buildItemsShimmer(context);
      }

      if (state is FetchSellerItemsFail) {
        return Center(
          child: CustomText(state.error),
        );
      }
      if (state is FetchSellerItemsSuccess) {
        print("state loading more${state.isLoadingMore}");
        if (state.items.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchSellerItemsCubit>()
                    .fetch(sellerId: widget.model.id!);
              },
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "${state.total.toString()}\t${"itemsLive".translate(context)}",
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      _loadMore();
                    }
                    return true;
                  },
                  child: GridView.builder(
                    //primary: false,

                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 10),
                    shrinkWrap: true,
                    // Allow GridView to fit within the space
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                            crossAxisCount: 2,
                            height: MediaQuery.of(context).size.height / 3.5,
                            mainAxisSpacing: 7,
                            crossAxisSpacing: 10),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      ItemModel item = state.items[index];

                      return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.adDetailsScreen,
                              arguments: {
                                'model': item,
                              },
                            );
                          },
                          child: ItemCard(
                            item: item,
                          ));
                    },
                  ),
                ),
              ),
              if (state.isLoadingMore) Center(child: UiUtils.progress())
            ],
          ),
        );
      }
      return Container();
    });
  }

  Map<int, int> getRatingCounts(List<UserRatings> userRatings) {
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
    print("Building ratingsListWidget for seller ID: ${widget.model.id}");
    return BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(
      builder: (context, state) {
        if (state is FetchSellerRatingsInProgress) {
          print("Ratings fetch in progress");
          return Center(
            child: UiUtils.progress(),
          );
        }
        if (state is FetchSellerRatingsSuccess) {
          print("Ratings fetch success: found ${state.ratings.length} ratings");

          // If there are no ratings, show a centered message with review button
          if (state.ratings.isEmpty) {
            print("No ratings found");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 50,
                    color: context.color.textLightColor,
                  ),
                  SizedBox(height: 10),
                  CustomText(
                    "noRatingsAvailableYet".translate(context),
                    color: context.color.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                  if (HiveUtils.isUserAuthenticated())
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: ElevatedButton(
                        child: CustomText(
                          "Be the first to review",
                          color: context.color.buttonColor,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.color.territoryColor,
                          minimumSize: Size(200, 45),
                        ),
                        onPressed: () {
                          // Show review dialog when the seller is of type Business or Expert
                          if (state.seller != null) {
                            _showReviewDialog(state.seller!);
                          } else {
                            print("Cannot show review dialog: seller is null");
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          }

          // If there are ratings, show them with a review banner at the top
          return Column(
            children: [
              // Always show the review banner at the top
              if (state.seller != null)
                _buildReviewButtonSection(state.seller!),

              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      _reviewLoadMore();
                    }
                    return true;
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 20),
                    itemCount: state.ratings.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(state.ratings[index], index);
                    },
                  ),
                ),
              ),

              // Show progress indicator when loading more
              if (state is FetchSellerRatingsSuccess && state.isLoadingMore)
                Center(child: UiUtils.progress()),
            ],
          );
        }
        if (state is FetchSellerRatingsFail) {
          print("Ratings fetch failed: ${state.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 50,
                  color: context.color.textLightColor,
                ),
                SizedBox(height: 10),
                CustomText(
                  "Failed to load ratings",
                  color: context.color.textLightColor,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  child: CustomText(
                    "Try Again",
                    color: context.color.buttonColor,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.territoryColor,
                    minimumSize: Size(150, 45),
                  ),
                  onPressed: () {
                    print(
                        "Retrying ratings fetch for seller ID: ${widget.model.id}");
                    context
                        .read<FetchSellerRatingsCubit>()
                        .fetch(sellerId: widget.model.id!);
                  },
                ),
              ],
            ),
          );
        }

        print("Unhandled state in ratingsListWidget: ${state.runtimeType}");
        return SizedBox.shrink();
      },
    );
  }

// Rating summary widget (similar to the top section of your image)
  Widget _buildSellerSummary(
      Seller seller, int total, List<UserRatings> ratings) {
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
                    Text(seller.averageRating!.toStringAsFixed(2).toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color: context.color.textDefaultColor,
                                fontWeight: FontWeight.bold)),
                    CustomRatingBar(
                      rating: seller.averageRating!,
                      itemSize: 25.0,
                      activeColor: Colors.amber,
                      inactiveColor: context.color.backgroundColor.darken(10),
                      allowHalfRating: true,
                    ),
                    SizedBox(height: 3),
                    CustomText(
                      "${total.toString()}\t${"ratings".translate(context)}",
                      fontSize: context.font.large,
                    )
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

            // Write a Review Button - Always show it
            _buildReviewButtonSection(seller),
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
          width: 10.0,
          child: CustomText("$starCount",
              color: context.color.textDefaultColor,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500),
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
          width: 10.0,
          child: CustomText(ratingCount.toString(),
              color: context.color.textDefaultColor.withOpacity(0.7),
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w600),
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

  Widget _buildReviewCard(UserRatings ratings, int index) {
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
                      if (ratings.createdAt != null)
                        CustomText(
                          dateTime(
                            ratings.createdAt!,
                          ),
                          fontSize: context.font.small,
                          color: context.color.textDefaultColor
                            ..withOpacity(0.3),
                        )
                    ],
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
                      CustomText(
                        ratings.ratings!.toString(),
                        color: context.color.textDefaultColor,
                      )
                    ],
                  ),
                  SizedBox(height: 5),
                  SizedBox(
                    width: context.screenWidth * 0.63,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final span = TextSpan(
                          text: "${ratings.review!}\t",
                          style: TextStyle(
                            color: context.color.textDefaultColor,
                          ),
                        );
                        final tp = TextPainter(
                          text: span,
                          maxLines: 2,
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
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            if (isOverflowing)
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 3),
                                child: InkWell(
                                  onTap: () {
                                    context
                                        .read<FetchSellerRatingsCubit>()
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show the review dialog
  void _showReviewDialog(Seller seller) {
    print("_showReviewDialog called with seller: ${seller.id}");

    // Check if user is authenticated
    if (!HiveUtils.isUserAuthenticated()) {
      print("User not authenticated, showing login dialog");
      // Show login required dialog
      _showLoginRequiredDialog();
      return;
    }

    print("User authenticated, showing review dialog");
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BlocProvider(
          create: (context) => AddUserReviewCubit(),
          child: ReviewDialog(
            targetId: seller.id!,
            reviewType: getProfileTypeName().toLowerCase() == "business"
                ? ReviewType.businessProfile
                : ReviewType.expertProfile,
            name: seller.name ?? "",
            image: seller.profile,
          ),
        );
      },
    ).then((value) {
      print("Review dialog closed with value: $value");
      if (value == true) {
        // Refresh the reviews after submitting a new one
        print("Refreshing reviews after submission");
        context
            .read<FetchSellerRatingsCubit>()
            .fetch(sellerId: widget.model.id!);
      }
    });
  }

  // Show login required dialog
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              "Login Required",
              style: TextStyle(
                fontSize: context.font.larger,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 60,
                color: context.color.territoryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "You need to be logged in to write a review",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.color.textDefaultColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: context.color.textColorDark,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.color.territoryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.login);
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: context.color.buttonColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Check if seller is an expert or business profile
  bool isBusinessOrExpertProfile() {
    // First try to use user_type if available
    if (widget.model.type != null) {
      String type = widget.model.type!.toLowerCase();
      return type == "expert" || type == "business" || type == "provider";
    }

    // Fallback: if verified, consider it as a professional account
    return widget.model.isVerified == 1;
  }

  // Get profile type name for display
  String getProfileTypeName() {
    if (widget.model.type != null) {
      String type = widget.model.type!.toLowerCase();
      if (type == "expert") return "Expert";
      if (type == "business") return "Business";
      if (type == "provider") return "Provider";
    }

    return widget.model.isVerified == 1 ? "Verified Professional" : "Profile";
  }

  // Get profile type icon
  IconData getProfileTypeIcon() {
    if (widget.model.type != null) {
      String type = widget.model.type!.toLowerCase();
      if (type == "expert") return Icons.verified_user;
      if (type == "business") return Icons.business_center;
      if (type == "provider") return Icons.account_circle;
    }

    return widget.model.isVerified == 1 ? Icons.verified_user : Icons.person;
  }

  // Separate method for the review button section
  Widget _buildReviewButtonSection(Seller seller) {
    final bool isLoggedIn = HiveUtils.isUserAuthenticated();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.color.primaryColor,
        border:
            Border.all(color: context.color.territoryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                getProfileTypeIcon(),
                color: context.color.territoryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              CustomText(
                getProfileTypeName() + " Profile",
                fontSize: context.font.large,
                fontWeight: FontWeight.bold,
                color: context.color.territoryColor,
              ),
            ],
          ),
          SizedBox(height: 8),
          CustomText(
            "Share your experience with ${seller.name}",
            color: context.color.textDefaultColor,
          ),
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CustomText(
                "Login required to write a review",
                color: context.color.textLightColor,
                fontSize: context.font.small,
              ),
            ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _showReviewDialog(seller);
            },
            icon: Icon(Icons.rate_review, color: context.color.buttonColor),
            label: CustomText(
              isLoggedIn ? "Write a Review" : "Login to Review",
              color: context.color.buttonColor,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.color.territoryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size(double.infinity, 45),
            ),
          ),
        ],
      ),
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
