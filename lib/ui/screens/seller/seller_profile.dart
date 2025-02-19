import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/seller/fetch_seller_item_cubit.dart';
import 'package:eClassify/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/seller_ratings_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_hero_animation.dart';
import 'package:eClassify/utils/custom_silver_grid_delegate.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
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
    _tabController = TabController(length: 2, vsync: this);

    // Listen for changes in tab selection
    _tabController.addListener(() {
      print("addListener**");
      setState(() {});
    });

    context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.model.id!);
    context.read<FetchSellerRatingsCubit>().fetch(sellerId: widget.model.id!);
    super.initState();
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
    return BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(
        builder: (context, state) {
      if (state is FetchSellerRatingsInProgress) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: 10,
          itemBuilder: (context, index) {
            return buildRatingsShimmer(context);
          },
        );
      }

      if (state is FetchSellerRatingsFail) {
        return Center(
          child: CustomText(state.error),
        );
      }
      if (state is FetchSellerRatingsSuccess) {
        if (state.ratings.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchSellerRatingsCubit>()
                    .fetch(sellerId: widget.model.id!);
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
              if (state.seller != null)
                _buildSellerSummary(state.seller!, state.total, state.ratings),

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
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: state.ratings.length,
                    itemBuilder: (context, index) {
                      UserRatings ratings = state.ratings[index];

                      return _buildReviewCard(ratings, index);
                    },
                  ),
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
                          color: context.color.textDefaultColor..withOpacity(0.3),
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

/*// Individual review card widget
  Widget _buildReviewCard(UserRatings ratings) {
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (ratings.createdAt != null)
                        CustomText(
                          dateTime(ratings.createdAt!),
                        ).size(context.font.small).color(
                            context.color.textDefaultColor.withOpacity(0.3)),
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
                      CustomText(ratings.ratings!.toString())
                          .color(context.color.textDefaultColor)
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
                                maxLines: isExpanded ? null : 2,
                                softWrap: true,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ).color(context.color.textDefaultColor),
                            ),
                            if (isOverflowing) // Conditionally show the button
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 3),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isExpanded =
                                          !isExpanded; // Toggle the expanded state
                                    });
                                  },
                                  child: CustomText(
                                    isExpanded
                                        ? "readLessLbl".translate(context)
                                        : "readMoreLbl".translate(context),
                                  )
                                      .color(context.color.territoryColor)
                                      .bold(weight: FontWeight.w400)
                                      .size(context.font.small),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }*/

/*int getSpecificRatingCount(List<UserRatings> userRatings, int specificRating) {
  // Initialize the count for the specific rating
  int specificRatingCount = 0;

  // Iterate through the user ratings list and count the specific rating
  if (userRatings.isNotEmpty) {
    for (var rating in userRatings) {
      int ratingValue = rating.ratings ?? 0;

      // Check if the rating matches the specific rating
      if (ratingValue == specificRating) {
        specificRatingCount++;
      }
    }
  }

  return specificRatingCount;
}*/

/*  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: CustomScrollView(
          controller: controller,
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          slivers: <Widget>[
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
                      SizedBox(
                          height: 95,
                          width: 95,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: widget.model.profile != null
                                  ? UiUtils.getImage(widget.model.profile!,
                                      fit: BoxFit.fill)
                                  : UiUtils.getSvg(
                                      AppIcons.defaultPersonLogo,
                                      color: context.color.territoryColor,
                                      fit: BoxFit.none,
                                    ))),
                      SizedBox(
                        height: 7,
                      ),
                      CustomText(widget.model.name!)
                          .bold()
                          .color(context.color.textDefaultColor),
                      if (widget.model.createdAt != null &&
                          widget.model.createdAt != '') ...[
                        SizedBox(
                          height: 7,
                        ),
                        CustomText("${"memberSince".translate(context)}\t${UiUtils.monthYearDate(widget.model.createdAt!)}")
                            .bold(weight: FontWeight.w400)
                            .color(context.color.textDefaultColor),
                      ]
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(60.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: context.color.backgroundColor, width: 2.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        TabBar(
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
                          color:
                              context.color.textDefaultColor.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                )),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  liveAdsWidget(),
                  Container(),
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("${state.total.toString()}\t${"itemsLive".translate(context)}")
                  .bold(weight: FontWeight.w600)
                  .size(context.font.large),
              Expanded(
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: 10),
                  shrinkWrap: true,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                          crossAxisCount: 2,
                          height: MediaQuery.of(context).size.height /
                              3.5,
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
              if (state.isLoadingMore) UiUtils.progress()
            ],
          ),
        );
      }
      return Container();
    });
  }*/

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
