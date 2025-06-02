import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:social_media_buttons/social_media_buttons.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/add_user_review_cubit.dart';
import 'package:tlobni/data/cubits/category/fetch_all_categories_cubit.dart';
import 'package:tlobni/data/cubits/fetch_provider_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_item_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:tlobni/data/cubits/user_has_rated_user_cubit.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/home_category_in_container_bubble.dart';
import 'package:tlobni/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:tlobni/ui/screens/home/widgets/item_container.dart';
import 'package:tlobni/ui/screens/home/widgets/provider_home_screen_container.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/review_dialog.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/pagination/pagination_next_previous.dart';
import 'package:tlobni/ui/widgets/reviews/review_container.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_hero_animation.dart';
import 'package:tlobni/utils/custom_silver_grid_delegate.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/list.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum _SellerProfileScreenTab {
  listings,
  about,
  reviews;

  @override
  String toString() => switch (this) {
        _SellerProfileScreenTab.listings => 'Listings',
        _SellerProfileScreenTab.about => 'About',
        _SellerProfileScreenTab.reviews => 'Reviews',
      };
}

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

class SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late double? rating = widget.rating;

  _SellerProfileScreenTab _currentTab = _SellerProfileScreenTab.listings;

  //bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Check if user is a Client (not a business or expert)
    bool isClientProfile = widget.model.type?.toLowerCase() == "client";
    int tabCount = isClientProfile ? 2 : 3; // Only 2 tabs for client profiles

    _tabController = TabController(length: tabCount, vsync: this);

    // Listen for changes in tab selection
    _tabController.addListener(() {
      print("Tab changed to index: ${_tabController.index}");
      setState(() {});
    });

    context.read<FetchAllCategoriesCubit>().fetchCategories();

    _refreshUserHasRated();

    // Load data on initState
    Future.microtask(() {
      if (widget.model.id != null) {
        print("Initializing seller profile with ID: ${widget.model.id}");
        _onRefresh();
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
      context.read<FetchSellerItemsCubit>().fetchMore(sellerId: widget.model.id!);
    }
  }

  void _reviewLoadMore() async {
    if (context.read<FetchSellerRatingsCubit>().hasMoreData()) {
      context.read<FetchSellerRatingsCubit>().fetchMore(sellerId: widget.model.id!);
    }
  }

  Widget _providerSummary(FetchProviderSuccess state) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: kElevationToShadow[1],
        ),
        child: ProviderHomeScreenContainer(
          user: state.user,
          nameFontSize: 18,
          nameFontWeight: FontWeight.w500,
          goToProviderDetailsScreenOnPressed: false,
          withBorder: false,
          categoriesBuilder: (categories) => Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              ...[
                if (categories.length > 0) categories[0],
                if (categories.length > 1) categories[1],
              ].map((e) => HomeCategoryInContainerBubble(
                    e,
                    fontSize: 12,
                    color: Color(0xffe8edf2),
                    padding: EdgeInsets.all(5),
                  )),
              if (categories.length > 2) SmallText('+${categories.length - 2} more', color: Colors.grey, fontSize: 12),
            ],
          ),
        ),
      );

  Widget _tabsHeaders() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: kElevationToShadow[1]
          // ?.map((e) => e.copyWith(spreadRadius: e.spreadRadius / 2)).toList()
          ,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: _SellerProfileScreenTab.values
                .map((e) => UnelevatedRegularButton(
                      padding: EdgeInsets.all(20),
                      onPressed: () => setState(() => _currentTab = e),
                      color: _currentTab == e ? context.color.primary : Colors.white,
                      child: SmallText(
                        e.toString(),
                        color: _currentTab == e ? context.color.onPrimary : null,
                        fontSize: 14,
                      ),
                    ))
                .mapExpandedSpaceBetween(0),
          ),
        ),
      );

  Widget _tabContent() => Container(
        decoration: BoxDecoration(
          boxShadow: kElevationToShadow[1],
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(15),
        child: switch (_currentTab) {
          _SellerProfileScreenTab.listings => _listingsTabContent(),
          _SellerProfileScreenTab.about => _aboutTabContent(),
          _SellerProfileScreenTab.reviews => _reviewsTabContent(),
        },
      );

  Widget _listingsTabContent() => BlocBuilder<FetchSellerItemsCubit, FetchSellerItemsState>(builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: HeadingText('Services & Experiences', fontSize: 20)),
                if (state is FetchSellerItemsSuccess)
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xfff0f4f8),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: SmallText('${state.total} Listings', fontSize: 12),
                  )
              ],
            ),
            SizedBox(height: 20),
            Builder(builder: (context) {
              if (state is FetchSellerItemsInProgress)
                return Row(
                  children: [
                    CustomShimmer(height: 300),
                    CustomShimmer(height: 300),
                  ].mapExpandedSpaceBetween(10),
                );
              if (state is FetchSellerItemsFail) return Center(child: CustomText(state.error));
              if (state is! FetchSellerItemsSuccess) return Container();

              final allListings = [...state.items];

              if (allListings.isEmpty) {
                return Column(
                  children: [
                    Center(
                      child: NoDataFound(
                        mainMessage: 'No listings yet.',
                        subMessage: 'Stay tuned for more listings...',
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                );
              }

              final lists = allListings.groupEach(2);
              return Column(
                spacing: 10,
                children: [
                  for (var list in lists)
                    Row(
                      children: list.length == 1
                          ? [
                              (1, SizedBox()),
                              (2, _listing(list[0])),
                              (1, SizedBox()),
                            ].mapExpandedSpaceBetween(0)
                          : [
                              _listing(list[0]),
                              _listing(list[1]),
                            ].mapExpandedSpaceBetween(10),
                    ),
                  if (state.items.length < state.total) ...[
                    SizedBox(height: 10),
                    _itemsListingPaginationDetails(state),
                  ],
                  SizedBox(height: 10),
                ],
              );
            })
          ],
        );
      });

  Widget _itemsListingPaginationDetails(FetchSellerItemsSuccess state) => IntrinsicHeight(
        child: PaginationNextPrevious(
          currentPage: state.page,
          lastPage: state.lastPage,
          onButtonPressed: (newPage) => context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.model.id!, page: newPage),
        ),
      );

  Widget _listing(ItemModel item) => ItemContainer(
        item: item,
        small: true,
        showTypeTag: true,
      );

  Widget _aboutTabContent() {
    final state = context.read<FetchProviderCubit>().state;
    final user = state is FetchProviderSuccess ? state.user : null;
    if (user == null) return SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        if (user.bio != null) _aboutSection('About', DescriptionText(user.bio ?? '', color: Colors.grey.shade600)),
        if (user.categories != null && user.categories!.isNotEmpty)
          _aboutSection(
            'Specializations',
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: user.categories!.map((e) => HomeCategoryInContainerBubble(e, color: Color(0xffc8d8ea))).toList(),
            ),
          ),
        if (user.showPersonalDetails == 1)
          _aboutSection(
            'Contact Information',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                (Icons.language, user.website, true),
                (Icons.email_outlined, user.email, false),
                (Icons.phone_outlined, user.mobile, false),
                (Icons.location_pin, user.location, false),
              ].where((e) => e.$2 != null).map((e) {
                final (icon, text, canLaunch) = e;
                return GestureDetector(
                  onTap: () {
                    if (canLaunch) {
                      launchUrlString(text);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.grey.shade600),
                      SizedBox(width: 10),
                      Expanded(child: DescriptionText(text!, color: Colors.grey.shade600)),
                      if (canLaunch) Icon(Icons.open_in_new, color: context.color.primary),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Builder(builder: (context) {
          final socialMedia = <(Color, IconData, String)>[];
          if (user.instagram != null) socialMedia.add((Color(0xffc13584), SocialMediaIcons.instagram, user.instagram!));
          if (user.facebook != null) socialMedia.add((Color(0xff3b5998), SocialMediaIcons.facebook, user.facebook!));
          if (user.twitter != null) socialMedia.add((Color(0xff24a3f1), SocialMediaIcons.twitter, user.twitter!));
          if (user.tiktok != null) socialMedia.add((Color(0xff080808), Icons.tiktok, user.tiktok!));

          return _aboutSection(
              'Social Media',
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: socialMedia.map((e) {
                  final (color, icon, link) = e;
                  return RegularButton(
                    color: Colors.white,
                    shape: CircleBorder(),
                    onPressed: () {
                      launchUrlString(link);
                    },
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      icon,
                      size: 30,
                      color: color,
                    ),
                  );
                }).toList(),
              ));
        }),
        //todo portfolio
      ],
    );
  }

  Widget _aboutSection(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeadingText(title, fontSize: 20, weight: FontWeight.bold),
          SizedBox(height: 16),
          child,
        ],
      );

  Widget _reviewsTabContent() => BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: HeadingText('Ratings & Reviews', fontSize: 20)),
                if (state is FetchSellerRatingsSuccess)
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: kColorSecondaryBeige, size: 20),
                      DescriptionText((state.seller?.averageRating ?? 0).toStringAsFixed(1), fontSize: 16, weight: FontWeight.bold),
                      SizedBox(width: 3),
                      SmallText('(${state.total} reviews)', color: Colors.grey, fontSize: 12),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Builder(builder: (context) {
              if (state is FetchSellerRatingsInProgress)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    for (int i = 0; i < 3; i++) CustomShimmer(height: 100),
                  ],
                );
              if (state is FetchSellerRatingsFail) return Center(child: CustomText(state.error));
              if (state is! FetchSellerRatingsSuccess) return Container();
              return IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    ...state.ratings.map(ReviewContainer.new),
                    if (state.ratings.length < state.total) ...[
                      _reviewPaginationInformation(state),
                    ],
                    if (!isOwnProfile) _addReviewButton(),
                  ],
                ),
              );
            }),
          ],
        );
      });

  Widget _reviewPaginationInformation(FetchSellerRatingsSuccess state) => IntrinsicHeight(
        child: PaginationNextPrevious(
          currentPage: state.page,
          lastPage: state.lastPage,
          onButtonPressed: (newPage) => context.read<FetchSellerRatingsCubit>().fetch(sellerId: widget.model.id!, page: newPage),
        ),
      );

  Widget _addReviewButton() => BlocBuilder<UserHasRatedUserCubit, UserHasRatedUserState>(
        builder: (context, state) {
          if (state is! UserHasRatedUserSuccess || state.userHasRatedUser) return Container();
          return PrimaryButton.text(
            '+ Add Your Review',
            padding: EdgeInsets.all(16),
            fontSize: 16,
            onPressed: () {
              final user = context.read<FetchProviderCubit>().state is FetchProviderSuccess
                  ? (context.read<FetchProviderCubit>().state as FetchProviderSuccess).user
                  : null;
              if (user != null) {
                _showReviewDialog(Seller(
                  id: user.id,
                  name: user.name,
                  averageRating: user.averageRating,
                  profile: user.profile,
                  createdAt: user.createdAt,
                  email: user.email,
                  isVerified: user.isVerified,
                  mobile: user.mobile,
                ));
              }
            },
          );
        },
      );

  bool get isOwnProfile => widget.model.id.toString() == HiveUtils.getUserId();

  Widget _bottomBar(FetchProviderSuccess state) => PrimaryButton.text(
        'Whatsapp',
        onPressed: () => HelperUtils.launchWhatsapp(state.user.mobile),
        padding: EdgeInsets.all(20),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context, title: 'Provider Profile', showBackButton: true),
      body: BlocBuilder<FetchProviderCubit, FetchProviderState>(builder: (context, state) {
        if (state is FetchProviderInProgress) return Center(child: UiUtils.progress());
        if (state is FetchProviderFailure) return _error(state.errorMessage);
        if (state is! FetchProviderSuccess) return Container();
        return BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(builder: (context, fetchSellerState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 20,
                        children: [
                          _providerSummary(state),
                          _tabsHeaders(),
                          _tabContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (state.user.showPersonalDetails == 1)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _bottomBar(state),
                ),
            ],
          );
        });
      }),
    );

    // print("_tabController.index***${_tabController.index}");
    //
    // // Check if user is a Client (not a business or expert)
    // bool isClientProfile = widget.model.type?.toLowerCase() == "client";
    // int tabCount = isClientProfile ? 2 : 3; // Only 2 tabs for client profiles
    //
    // // Check if this is the current user's own profile
    // bool isOwnProfile = widget.model.id.toString() == HiveUtils.getUserId();
    // print("Is own profile: $isOwnProfile");
    // return DefaultTabController(
    //   length: tabCount, // Conditional number of tabs
    //   child: Scaffold(
    //     backgroundColor: context.color.backgroundColor,
    //     floatingActionButton: false ?? isBusinessOrExpertProfile() && !isOwnProfile
    //         ? FloatingActionButton(
    //             onPressed: () {
    //               print("FloatingActionButton pressed");
    //               if (context.read<FetchSellerRatingsCubit>().state is FetchSellerRatingsSuccess) {
    //                 final state = context.read<FetchSellerRatingsCubit>().state as FetchSellerRatingsSuccess;
    //                 if (state.seller != null) {
    //                   _showReviewDialog(state.seller!);
    //                 } else {
    //                   print("Cannot show review dialog: seller is null");
    //                   HelperUtils.showSnackBarMessage(context, "Cannot add review at this time", messageDuration: 3);
    //                 }
    //               } else {
    //                 // If the ratings state isn't loaded yet, use the widget.model
    //                 // to create a basic Seller object for the review dialog
    //                 print("Using widget.model for review dialog");
    //                 Seller seller = Seller(id: widget.model.id, name: widget.model.name, profile: widget.model.profile);
    //                 _showReviewDialog(seller);
    //               }
    //             },
    //             backgroundColor: context.color.territoryColor,
    //             child: Icon(Icons.rate_review, color: context.color.buttonColor),
    //           )
    //         : null,
    //     body: NestedScrollView(
    //       headerSliverBuilder: (context, innerBoxIsScrolled) => [
    //         SliverAppBar(
    //           leading: Material(
    //             clipBehavior: Clip.antiAlias,
    //             color: Colors.transparent,
    //             type: MaterialType.circle,
    //             child: InkWell(
    //               onTap: () {
    //                 Navigator.pop(context);
    //               },
    //               child: Padding(
    //                 padding: const EdgeInsets.all(18.0),
    //                 child: Directionality(
    //                   textDirection: Directionality.of(context),
    //                   child: RotatedBox(
    //                     quarterTurns: Directionality.of(context) == ui.TextDirection.rtl ? 2 : -4,
    //                     child: UiUtils.getSvg(AppIcons.arrowLeft, fit: BoxFit.none, color: context.color.textDefaultColor),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //           //automaticallyImplyLeading: false,
    //           pinned: true,
    //
    //           expandedHeight: (widget.model.createdAt != null && widget.model.createdAt != '')
    //               ? context.screenHeight / 2.3
    //               : context.screenHeight / 2.9,
    //           backgroundColor: context.color.secondaryColor,
    //           flexibleSpace: FlexibleSpaceBar(
    //             background: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    //               SizedBox(
    //                 height: 100,
    //               ),
    //               Stack(
    //                 clipBehavior: Clip.none,
    //                 children: [
    //                   CircleAvatar(
    //                     radius: 45,
    //                     child: ClipRRect(
    //                       borderRadius: BorderRadius.circular(45),
    //                       child: widget.model.profile != null
    //                           ? UiUtils.getImage(widget.model.profile!, fit: BoxFit.fill, width: 95, height: 95)
    //                           : UiUtils.getSvg(AppIcons.defaultPersonLogo,
    //                               color: context.color.territoryColor, fit: BoxFit.none, width: 95, height: 95),
    //                     ),
    //                   ),
    //                   if (widget.model.isVerified == 1)
    //                     Positioned(
    //                       left: 0,
    //                       right: 0,
    //                       bottom: -10,
    //                       child: DecoratedBox(
    //                         decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: context.color.forthColor),
    //                         child: Padding(
    //                           padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    //                           child: Row(
    //                             mainAxisAlignment: MainAxisAlignment.center,
    //                             mainAxisSize: MainAxisSize.min,
    //                             children: [
    //                               UiUtils.getSvg(AppIcons.verifiedIcon, width: 14, height: 14),
    //                               SizedBox(
    //                                 width: 4,
    //                               ),
    //                               CustomText(
    //                                 "verifiedLbl".translate(context),
    //                                 color: context.color.secondaryColor,
    //                                 fontWeight: FontWeight.w500,
    //                               )
    //                             ],
    //                           ),
    //                         ),
    //                       ),
    //                     ),
    //                 ],
    //               ),
    //               SizedBox(
    //                 height: 20,
    //               ),
    //               CustomText(
    //                 widget.model.name!,
    //                 color: context.color.textDefaultColor,
    //                 fontWeight: FontWeight.w600,
    //               ),
    //               SizedBox(height: 5),
    //               // Display category
    //               if (widget.model.categoriesIds != null && widget.model.categoriesIds!.isNotEmpty)
    //                 BlocBuilder<FetchAllCategoriesCubit, FetchAllCategoriesState>(
    //                   builder: (context, state) {
    //                     if (state is FetchAllCategoriesFailure) print(state.errorMessage);
    //                     if (state is! FetchAllCategoriesSuccess) return SizedBox();
    //                     final categoryIds = widget.model.categoriesIds?.toSet() ?? {};
    //                     final categories = state.categories.where((e) => categoryIds.contains(e.id)).toList();
    //                     if (categories.isEmpty) return SizedBox();
    //                     return CustomText(
    //                       // Show first category name or "Category"
    //                       UiUtils.categoriesListToString(categories),
    //                       color: context.color.textDefaultColor.withOpacity(0.7),
    //                       fontWeight: FontWeight.w400,
    //                     );
    //                   },
    //                 ),
    //
    //               if (widget.model.hasLocation) ...[
    //                 SizedBox(height: 5),
    //                 CustomText(
    //                   widget.model.location!,
    //                   color: context.color.textDefaultColor.withOpacity(0.7),
    //                   fontWeight: FontWeight.w400,
    //                 ),
    //               ],
    //
    //               // // Website link
    //               // if (widget.model.website != null && widget.model.website!.isNotEmpty)
    //               //   Padding(
    //               //     padding: const EdgeInsets.only(top: 5),
    //               //     child: GestureDetector(
    //               //       onTap: () {
    //               //         // Open website URL
    //               //         _launchURL(widget.model.website!);
    //               //       },
    //               //       child: Row(
    //               //         mainAxisSize: MainAxisSize.min,
    //               //         children: [
    //               //           Icon(
    //               //             Icons.link,
    //               //             size: 16,
    //               //             color: context.color.territoryColor,
    //               //           ),
    //               //           SizedBox(width: 4),
    //               //           CustomText(
    //               //             widget.model.website!,
    //               //             color: context.color.territoryColor,
    //               //             fontSize: context.font.small,
    //               //           ),
    //               //         ],
    //               //       ),
    //               //     ),
    //               //   ),
    //
    //               if (widget.rating != null)
    //                 Padding(
    //                   padding: const EdgeInsets.only(top: 8),
    //                   child: RichText(
    //                     text: TextSpan(
    //                       children: [
    //                         WidgetSpan(
    //                           child: Icon(Icons.star_rounded, size: 18, color: context.color.textDefaultColor), // Star icon
    //                         ),
    //                         TextSpan(
    //                           text: '\t${widget.rating!.toStringAsFixed(2).toString()}',
    //                           // Rating value
    //                           style: TextStyle(
    //                             fontSize: 16,
    //                             color: context.color.textDefaultColor,
    //                           ),
    //                         ),
    //                         TextSpan(
    //                           text: '  |  ',
    //                           style: TextStyle(
    //                             fontSize: 16,
    //                             color: context.color.textDefaultColor.withOpacity(0.3),
    //                           ),
    //                         ),
    //                         TextSpan(
    //                           text: '${widget.total}\t${"ratings".translate(context)}',
    //                           // Rating count text
    //                           style: TextStyle(
    //                             fontSize: 16,
    //                             color: context.color.textDefaultColor.withOpacity(0.3),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //             ]),
    //           ),
    //           bottom: PreferredSize(
    //             preferredSize: Size.fromHeight(60.0),
    //             child: Container(
    //               decoration: BoxDecoration(
    //                 color: context.color.secondaryColor,
    //                 border: Border(
    //                   top: BorderSide(color: context.color.backgroundColor, width: 2.5),
    //                 ),
    //               ),
    //               child: Column(
    //                 children: [
    //                   TabBar(
    //                     controller: _tabController,
    //                     indicatorColor: context.color.territoryColor,
    //                     labelColor: context.color.territoryColor,
    //                     labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
    //                     unselectedLabelColor: context.color.textDefaultColor.withOpacity(0.7),
    //                     unselectedLabelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
    //                     tabs: isClientProfile
    //                         ?
    //                         // For client profiles, only show Live Ads and Ratings tabs
    //                         [
    //                             Tab(text: 'liveAds'.translate(context)),
    //                             Tab(text: 'ratings'.translate(context)),
    //                           ]
    //                         :
    //                         // For business/expert profiles, show all three tabs
    //                         [
    //                             Tab(text: 'liveAds'.translate(context)),
    //                             Tab(text: 'About'.translate(context)),
    //                             Tab(text: 'ratings'.translate(context)),
    //                           ],
    //                   ),
    //                   Divider(
    //                     height: 0,
    //                     thickness: 2,
    //                     color: context.color.textDefaultColor.withOpacity(0.2),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ],
    //       body: SafeArea(
    //         top: false,
    //         child: TabBarView(
    //           controller: _tabController,
    //           children: isClientProfile
    //               ?
    //               // For client profiles, only show Live Ads and Ratings tabs
    //               [
    //                   liveAdsWidget(),
    //                   ratingsListWidget(),
    //                 ]
    //               :
    //               // For business/expert profiles, show all three tabs
    //               [
    //                   liveAdsWidget(),
    //                   aboutWidget(),
    //                   ratingsListWidget(),
    //                 ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget liveAdsWidget() {
    return BlocBuilder<FetchSellerItemsCubit, FetchSellerItemsState>(builder: (context, state) {
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
                context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.model.id!);
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
                    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                        crossAxisCount: 2, height: MediaQuery.of(context).size.height / 3, mainAxisSpacing: 7, crossAxisSpacing: 10),
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

            // Check if this is the current user's own profile
            bool isOwnProfile = widget.model.id.toString() == HiveUtils.getUserId();

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
                    "No ratings available yet".translate(context),
                    color: context.color.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                  if (HiveUtils.isUserAuthenticated() && !isOwnProfile)
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
              if (state.seller != null) _buildReviewButtonSection(state.seller!),

              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
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
              if (state is FetchSellerRatingsInProgress && state.isLoadingMore) Center(child: UiUtils.progress()),
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
                    print("Retrying ratings fetch for seller ID: ${widget.model.id}");
                    context.read<FetchSellerRatingsCubit>().fetch(sellerId: widget.model.id!);
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
  Widget _buildSellerSummary(Seller seller, int total, List<UserRatings> ratings) {
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
                            .copyWith(color: context.color.textDefaultColor, fontWeight: FontWeight.bold)),
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
          child: CustomText("$starCount", color: context.color.textDefaultColor, textAlign: TextAlign.center, fontWeight: FontWeight.w500),
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
              color: context.color.textDefaultColor.withOpacity(0.7), textAlign: TextAlign.center, fontWeight: FontWeight.w600),
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
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
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
                    child: SvgPicture.asset(
                      AppIcons.profile,
                      colorFilter: ColorFilter.mode(context.color.buttonColor, BlendMode.srcIn),
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
                                overflow: ratings.isExpanded! ? TextOverflow.visible : TextOverflow.ellipsis,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            if (isOverflowing)
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 3),
                                child: InkWell(
                                  onTap: () {
                                    context.read<FetchSellerRatingsCubit>().updateIsExpanded(index);
                                  },
                                  child: CustomText(
                                    ratings.isExpanded! ? "readLessLbl".translate(context) : "readMoreLbl".translate(context),
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
            reviewType: getProfileTypeName().toLowerCase() == "business" ? ReviewType.businessProfile : ReviewType.expertProfile,
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
        _onRefresh();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    return BlocBuilder<UserHasRatedUserCubit, UserHasRatedUserState>(builder: (context, state) {
      if (state is! UserHasRatedUserSuccess) {
        return Container();
      }
      if (state.userHasRatedUser) {
        return Container();
      }
      final bool isLoggedIn = HiveUtils.isUserAuthenticated();

      // Check if this is the current user's own profile
      bool isOwnProfile = seller.id.toString() == HiveUtils.getUserId();

      // Don't show review button for own profile
      if (isOwnProfile) {
        return Container(); // Return empty container
      }

      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.color.primaryColor,
          border: Border.all(color: context.color.territoryColor.withOpacity(0.3)),
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
    });
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

  // New About tab with bio, portfolio, social links
  Widget aboutWidget() {
    // Check if we have bio data to display
    bool hasBio = widget.model.bio != null && widget.model.bio!.isNotEmpty;

    // Check if phone is available and enabled
    bool hasPhone = widget.model.mobile != null && widget.model.mobile!.isNotEmpty && widget.model.showPersonalDetails == 1;

    // Check if this is the current user's own profile
    bool isOwnProfile = widget.model.id.toString() == HiveUtils.getUserId();
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section - always show if bio exists, even for own profile
          if (hasBio)
            _buildSectionCard(
              title: "Bio",
              child: CustomText(
                widget.model.bio ?? "",
                color: context.color.textDefaultColor,
              ),
            ),

          if (hasBio) SizedBox(height: 16),

          // Contact Buttons - only show if not viewing own profile
          if (!isOwnProfile && hasPhone)
            Row(
              children: [
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _launchURL("tel:${widget.model.mobile}");
                      },
                      icon: Icon(Icons.phone, color: context.color.textDefaultColor),
                      label: CustomText(
                        "Call",
                        color: context.color.textDefaultColor,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.color.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          if (!isOwnProfile && hasPhone) SizedBox(height: 24),

          // Social Media Links - show for all profiles including own
          _buildSocialMediaLinks(),
        ],
      ),
    );
  }

  // Section card widget with title
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.color.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomText(
              title,
              fontWeight: FontWeight.bold,
              fontSize: context.font.large,
            ),
          ),
          Divider(height: 0, thickness: 1, color: context.color.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // Social media links row
  Widget _buildSocialMediaLinks() {
    // List to hold only available social links
    List<Widget> socialButtons = [];

    // Only add buttons for links that exist
    if (widget.model.facebook != null && widget.model.facebook!.isNotEmpty) {
      socialButtons.add(_buildSocialButton(
        icon: Icons.facebook,
        url: widget.model.facebook,
        backgroundColor: Color(0xFF1877F2),
      ));
    }

    if (widget.model.twitter != null && widget.model.twitter!.isNotEmpty) {
      socialButtons.add(_buildSocialButton(
        // Use a custom X icon for Twitter
        icon: Icons.close, // X icon for Twitter
        isTwitter: true,
        url: widget.model.twitter,
        backgroundColor: Color(0xFF000000),
      ));
    }

    if (widget.model.instagram != null && widget.model.instagram!.isNotEmpty) {
      socialButtons.add(_buildSocialButton(
        // Use a proper Instagram icon
        icon: Icons.camera_alt,
        isInstagram: true,
        url: widget.model.instagram,
        backgroundColor: Color(0xFFE1306C),
      ));
    }

    if (widget.model.tiktok != null && widget.model.tiktok!.isNotEmpty) {
      socialButtons.add(_buildSocialButton(
        icon: Icons.music_note,
        url: widget.model.tiktok,
        backgroundColor: Color(0xFF000000),
      ));
    }

    // If no social links, return an empty container
    if (socialButtons.isEmpty) {
      return Container();
    }

    // Return row of social buttons
    return Center(
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: socialButtons,
      ),
    );
  }

  // Social media button
  Widget _buildSocialButton({
    IconData? icon,
    String? url,
    required Color backgroundColor,
    bool isTwitter = false,
    bool isInstagram = false,
  }) {
    return InkWell(
      onTap: () => _launchURL(url!),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isTwitter
              ?
              // Custom X logo for Twitter
              Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                  weight: 800, // Bold X for Twitter
                )
              : isInstagram
                  ?
                  // Custom Instagram logo
                  ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [
                            Color(0xFFFED373),
                            Color(0xFFFF930F),
                            Color(0xFFEF5E5E),
                            Color(0xFFD5267B),
                            Color(0xFF803CB6),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ).createShader(bounds);
                      },
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  :
                  // Regular icon
                  Icon(
                      icon ?? Icons.link,
                      color: Colors.white,
                      size: 24,
                    ),
        ),
      ),
    );
  }

  // Helper method to launch URLs
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
    }
  }

  void _refreshUserHasRated() {
    if (widget.model.id != null) context.read<UserHasRatedUserCubit>().userHasRatedUser(ratedUserId: widget.model.id!);
  }

  Widget _error(errorMessage) => RefreshIndicator(
        onRefresh: _onRefresh,
        child: SizedBox(
          height: double.infinity,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: context.screenHeight * 0.9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: DescriptionText(errorMessage.toString()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _onRefresh() async {
    if (widget.model.id != null) {
      context.read<FetchProviderCubit>().fetchProvider(widget.model.id!);
      context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.model.id!);
      context.read<FetchSellerRatingsCubit>().fetch(sellerId: widget.model.id!);
      context.read<UserHasRatedUserCubit>().userHasRatedUser(ratedUserId: widget.model.id!);
    }
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
