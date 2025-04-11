// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:tlobni/data/cubits/item/manage_item_cubit.dart';
import 'package:tlobni/data/cubits/slider_cubit.dart';
import 'package:tlobni/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:tlobni/data/cubits/system/get_api_keys_cubit.dart';
import 'package:tlobni/data/cubits/fetch_notifications_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/home/home_screen_section.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/notification_data.dart';
import 'package:tlobni/data/model/system_settings_model.dart';
import 'package:tlobni/ui/screens/ad_banner_screen.dart';
import 'package:tlobni/ui/screens/home/slider_widget.dart';
import 'package:tlobni/ui/screens/home/widgets/category_widget_home.dart';
import 'package:tlobni/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:tlobni/ui/screens/home/widgets/home_search.dart';
import 'package:tlobni/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:tlobni/ui/screens/home/widgets/home_shimmers.dart';
import 'package:tlobni/ui/screens/home/widgets/location_widget.dart';
import 'package:tlobni/ui/screens/home/widgets/location_autocomplete_header.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/promoted_widget.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
//import 'package:uni_links/uni_links.dart';

import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/notification/awsome_notification.dart';
import 'package:tlobni/utils/notification/notification_service.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:tlobni/data/repositories/favourites_repository.dart';

const double sidePadding = 10;

class HomeScreen extends StatefulWidget {
  final String? from;

  const HomeScreen({super.key, this.from});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  //
  @override
  bool get wantKeepAlive => true;

  //
  List<ItemModel> itemLocalList = [];

  //
  bool isCategoryEmpty = false;

  // Notification related variables
  List<NotificationData> _notifications = [];
  bool _isNotificationLoading = false;
  Timer? _notificationRefreshTimer;

  // Stream subscription for item updates
  StreamSubscription? _itemUpdatesSubscription;

  //
  late final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Add these new properties
  final List<ItemModel> _experienceItems = [];
  bool _isLoadingExperiences = true;
  String? _experienceError;

  final List<ItemModel> _featuredItems = [];
  bool _isLoadingFeatured = true;
  String? _featuredError;

  // Add these properties for women exclusive and corporate package items
  final List<ItemModel> _womenExclusiveItems = [];
  bool _isLoadingWomenExclusive = true;
  String? _womenExclusiveError;

  final List<ItemModel> _corporatePackageItems = [];
  bool _isLoadingCorporatePackages = true;
  String? _corporatePackagesError;

  // Add properties for newest items
  final List<ItemModel> _newestItems = [];
  bool _isLoadingNewestItems = true;
  String? _newestItemsError;

  // Add these new properties for featured users
  final List<dynamic> _featuredUsers = [];
  bool _isLoadingFeaturedUsers = true;
  String? _featuredUsersError;

  @override
  void initState() {
    super.initState();
    initializeSettings();
    addPageScrollListener();
    notificationPermissionChecker();
    LocalAwesomeNotification().init(context);
    ///////////////////////////////////////
    NotificationService.init(context);
    context.read<SliderCubit>().fetchSlider(
          context,
        );
    context.read<FetchCategoryCubit>().fetchCategories(
          type: CategoryType.serviceExperience,
        );
    context.read<FetchHomeScreenCubit>().fetch(
        city: HiveUtils.getCityName(),
        areaId: HiveUtils.getAreaId(),
        country: HiveUtils.getCountryName(),
        state: HiveUtils.getStateName());
    context.read<FetchHomeAllItemsCubit>().fetch(
        city: HiveUtils.getCityName(),
        areaId: HiveUtils.getAreaId(),
        radius: HiveUtils.getNearbyRadius(),
        longitude: HiveUtils.getLongitude(),
        latitude: HiveUtils.getLatitude(),
        country: HiveUtils.getCountryName(),
        state: HiveUtils.getStateName());

    // Fetch items for each specialized section
    _fetchExperienceItems();
    _fetchFeaturedUsers();
    _fetchWomenExclusiveItems();
    _fetchCorporatePackageItems();
    _fetchNewestItems();

    context.read<FavoriteCubit>().getFavorite();
    //fetchApiKeys();
    context.read<GetBuyerChatListCubit>().fetch();
    context.read<BlockedUsersListCubit>().blockedUsersList();

    // Start loading notifications
    _fetchNotifications();

    // Set up a refresh timer for notifications (every 2 minutes)
    _notificationRefreshTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _fetchNotifications();
      }
    });

    // Listen for item update events
    _itemUpdatesSubscription =
        ItemEvents().itemEditedStream.stream.listen((updatedItem) {
      print("Home screen received item update: ${updatedItem.id}");
      if (mounted) {
        context.read<FetchHomeAllItemsCubit>().updateItem(updatedItem);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchHomeAllItemsCubit>().hasMoreData()) {
          context.read<FetchHomeAllItemsCubit>().fetchMore(
                city: HiveUtils.getCityName(),
                areaId: HiveUtils.getAreaId(),
                radius: HiveUtils.getNearbyRadius(),
                longitude: HiveUtils.getLongitude(),
                latitude: HiveUtils.getLatitude(),
                country: HiveUtils.getCountryName(),
                stateName: HiveUtils.getStateName(),
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _itemUpdatesSubscription?.cancel();
    super.dispose();
  }

  void initializeSettings() {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment("force-disable-demo-mode",
        defaultValue: false)) {
      Constant.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
    }
  }

  void addPageScrollListener() {
    //homeScreenController.addListener(pageScrollListener);
  }

  void fetchApiKeys() {
    context.read<GetApiKeysCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leadingWidth: double.maxFinite,
          leading: Padding(
              padding: EdgeInsetsDirectional.only(
                  start: sidePadding, end: sidePadding),
              child: const LocationAutocompleteHeader()),
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          actions: [
            // Add notification icon with badge
            Padding(
              padding: EdgeInsetsDirectional.only(end: 15.0),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: context.color.textDefaultColor,
                    ),
                    onPressed: () {
                      UiUtils.checkUser(
                        onNotGuest: () {
                          Navigator.pushNamed(context, Routes.notificationPage);
                        },
                        context: context,
                      );
                    },
                  ),
                  // Notification badge - Only show if there are unread notifications
                  if (HiveUtils.isUserAuthenticated() &&
                      _hasUnreadNotifications())
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: context.color.territoryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _getNotificationCount() > 9
                              ? '9+'
                              : _getNotificationCount().toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.color.primaryColor,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            // Fetch all data
            context.read<SliderCubit>().fetchSlider(context);
            context.read<FetchCategoryCubit>().fetchCategories(
                  type: CategoryType.serviceExperience,
                );
            context.read<FetchHomeScreenCubit>().fetch(
                city: HiveUtils.getCityName(),
                areaId: HiveUtils.getAreaId(),
                country: HiveUtils.getCountryName(),
                state: HiveUtils.getStateName());
            context.read<FetchHomeAllItemsCubit>().fetch(
                city: HiveUtils.getCityName(),
                areaId: HiveUtils.getAreaId(),
                radius: HiveUtils.getNearbyRadius(),
                longitude: HiveUtils.getLongitude(),
                latitude: HiveUtils.getLatitude(),
                country: HiveUtils.getCountryName(),
                state: HiveUtils.getStateName());

            // Refresh all specialized sections
            _fetchExperienceItems();
            _fetchFeaturedUsers();
            _fetchWomenExclusiveItems();
            _fetchCorporatePackageItems();
            _fetchNewestItems();

            // Also refresh the favorites
            context.read<FavoriteCubit>().getFavorite();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                const HomeSearchField(),

                // Exclusive Experiences Section
                _buildSectionHeader(context, "Exclusive Experiences"),
                _buildExclusiveExperiences(context),

                // Categories
                const CategoryWidgetHome(),

                // Newest Listings Section
                _buildSectionHeader(context, "Newest Listings"),
                _buildNewestListings(context),

                // Featured Experts & Businesses
                _buildSectionHeader(context, "Featured Experts & Businesses"),
                _buildFeaturedExperts(context),

                // Women-Exclusive Services
                _buildSectionHeader(context, "Women-Exclusive Services"),
                _buildWomenExclusiveServices(context),

                // Corporate & Business Packages
                _buildSectionHeader(context, "Corporate & Business Packages"),
                _buildCorporatePackages(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          top: 18, bottom: 12, start: sidePadding, end: sidePadding),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              )),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Navigate to the correct "see all" screen based on the section title
              if (title == "Exclusive Experiences") {
                Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                    arguments: {
                      "title": "Exclusive Experiences",
                      "sectionId": 1,
                      "endpoint": Api.getExperienceItemsApi,
                      "filter": {"post_type": "experience"},
                    });
              } else if (title == "Featured Experts & Businesses") {
                // Use the dedicated featured users screen instead of the section items screen
                Navigator.pushNamed(context, Routes.featuredUsersScreen,
                    arguments: {
                      "title": "Featured Experts & Businesses",
                    });
              } else if (title == "Women-Exclusive Services") {
                Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                    arguments: {
                      "title": "Women-Exclusive Services",
                      "sectionId": 3,
                      "endpoint": Api.getExclusiveWomenItemsApi,
                      "filter": {"special_tag": "exclusive_women"},
                    });
              } else if (title == "Corporate & Business Packages") {
                Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                    arguments: {
                      "title": "Corporate & Business Packages",
                      "sectionId": 4,
                      "endpoint": Api.getCorporatePackageItemsApi,
                      "filter": {"special_tag": "corporate_package"},
                    });
              } else if (title == "Newest Listings") {
                Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                    arguments: {
                      "title": "Newest Listings",
                      "sectionId": 5,
                      "endpoint": Api.getNewestItemsApi,
                      "filter": {"sort_by": "new-to-old"},
                    });
              } else {
                // Default behavior for other sections
                Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                    arguments: {
                      "title": title,
                      "sectionId": 6,
                      "filter": {"sort_by": "new-to-old"},
                    });
              }
            },
            child: Text(
              "See All",
              style: TextStyle(
                fontSize: context.font.small,
                fontWeight: FontWeight.w600,
                color: context.color.textLightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewestListings(BuildContext context) {
    if (_isLoadingNewestItems) {
      return SizedBox(
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return CustomShimmer(
              width: 170,
              height: 210,
              borderRadius: 10,
            );
          },
        ),
      );
    }

    if (_newestItemsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("Failed to load newest items: $_newestItemsError"),
      );
    }

    if (_newestItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("No newest items found"),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        itemCount: _newestItems.length > 3 ? 3 : _newestItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _newestItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                "model": item,
              });
            },
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor.darken(50)),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: UiUtils.getImage(
                          item.image ?? "",
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\$ ${item.price?.toStringAsFixed(2) ?? '0.00'}",
                              style: TextStyle(
                                fontSize: context.font.large,
                                fontWeight: FontWeight.w700,
                                color: context.color.territoryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name ?? "",
                              style: TextStyle(
                                fontSize: context.font.small * 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: context.color.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.address ?? "",
                                    style: TextStyle(
                                      fontSize: context.font.small,
                                      color: context.color.textLightColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.isFeature ?? false)
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.color.territoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Featured",
                          style: TextStyle(
                            fontSize: context.font.small * 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    end: 8,
                    bottom: 50,
                    child: BlocBuilder<FavoriteCubit, FavoriteState>(
                      builder: (context, state) {
                        bool isLike = context
                            .read<FavoriteCubit>()
                            .isItemFavorite(item.id!);
                        return GestureDetector(
                          onTap: () {
                            UiUtils.checkUser(
                              context: context,
                              onNotGuest: () {
                                context
                                    .read<UpdateFavoriteCubit>()
                                    .setFavoriteItem(
                                      item: item,
                                      type: isLike ? 0 : 1,
                                    );
                              },
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.color.secondaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isLike ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: context.color.territoryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedExperts(BuildContext context) {
    if (_isLoadingFeaturedUsers) {
      return SizedBox(
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return CustomShimmer(
              width: 170,
              height: 210,
              borderRadius: 10,
            );
          },
        ),
      );
    }

    if (_featuredUsersError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("Failed to load featured experts: $_featuredUsersError"),
      );
    }

    if (_featuredUsers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("No featured experts or businesses found"),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        itemCount: _featuredUsers.length > 3 ? 3 : _featuredUsers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final user = _featuredUsers[index];
          // Get categories as a formatted string
          String categoryName = "Category";
          if (user['categories'] != null) {
            try {
              List<String> categories =
                  user['categories'].toString().split(',');
              if (categories.isNotEmpty) {
                categoryName = categories.first;
              }
            } catch (e) {
              // Use default if there's an error parsing
            }
          }

          return GestureDetector(
            onTap: () {
              // Navigate to user profile or listings
              if (user['id'] != null) {
                // Create a User object from the featured user data
                User userModel = User(
                  id: user['id'],
                  name: user['name'],
                  profile: user['profile'],
                  type: user['type'],
                  bio: user['bio'],
                  email: user['email'],
                  mobile: user['mobile'],
                  address: user['address'] ?? user['location'],
                  isVerified: user['is_verified'],
                  createdAt: user['created_at'],
                  facebook: user['facebook'],
                  twitter: user['twitter'],
                  instagram: user['instagram'],
                  tiktok: user['tiktok'],
                  showPersonalDetails: user['show_personal_details'],
                );

                // Navigate to seller profile with proper model
                Navigator.pushNamed(
                  context,
                  Routes.sellerProfileScreen,
                  arguments: {
                    "model": userModel,
                    "rating": 0.0, // Default rating
                    "total": 0, // Default total reviews
                  },
                );
              }
            },
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor.darken(50)),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Image
                      user['profile'] != null &&
                              user['profile'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                              child: UiUtils.getImage(
                                user['profile'] ?? "",
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.color.territoryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: context.color.territoryColor,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Name
                            Text(
                              user['name'] ?? "Name",
                              style: TextStyle(
                                fontSize: context.font.large * 0.9,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Category
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: context.font.small * 1.1,
                                fontWeight: FontWeight.w500,
                                color: context.color.territoryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: context.color.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user['location'] ?? user['address'] ?? "",
                                    style: TextStyle(
                                      fontSize: context.font.small,
                                      color: context.color.textLightColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Featured badge
                  PositionedDirectional(
                    start: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.color.territoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Featured",
                        style: TextStyle(
                          fontSize: context.font.small * 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWomenExclusiveServices(BuildContext context) {
    if (_isLoadingWomenExclusive) {
      return SizedBox(
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return CustomShimmer(
              width: 170,
              height: 210,
              borderRadius: 10,
            );
          },
        ),
      );
    }

    if (_womenExclusiveError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text(
            "Failed to load women-exclusive services: $_womenExclusiveError"),
      );
    }

    if (_womenExclusiveItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("No women-exclusive services found"),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        itemCount:
            _womenExclusiveItems.length > 3 ? 3 : _womenExclusiveItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _womenExclusiveItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                "model": item,
              });
            },
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor.darken(50)),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: UiUtils.getImage(
                          item.image ?? "",
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\$ ${item.price?.toStringAsFixed(2) ?? '0.00'}",
                              style: TextStyle(
                                fontSize: context.font.large,
                                fontWeight: FontWeight.w700,
                                color: context.color.territoryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name ?? "",
                              style: TextStyle(
                                fontSize: context.font.small * 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: context.color.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.address ?? "",
                                    style: TextStyle(
                                      fontSize: context.font.small,
                                      color: context.color.textLightColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.isFeature ?? false)
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.color.territoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Featured",
                          style: TextStyle(
                            fontSize: context.font.small * 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    end: 8,
                    bottom: 45,
                    child: BlocProvider(
                      create: (context) =>
                          UpdateFavoriteCubit(FavoriteRepository()),
                      child: BlocBuilder<FavoriteCubit, FavoriteState>(
                        builder: (context, state) {
                          bool isLike = context
                              .read<FavoriteCubit>()
                              .isItemFavorite(item.id!);
                          return GestureDetector(
                            onTap: () {
                              UiUtils.checkUser(
                                context: context,
                                onNotGuest: () {
                                  context
                                      .read<UpdateFavoriteCubit>()
                                      .setFavoriteItem(
                                        item: item,
                                        type: isLike ? 0 : 1,
                                      );
                                },
                              );
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: context.color.secondaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isLike
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: context.color.territoryColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCorporatePackages(BuildContext context) {
    if (_isLoadingCorporatePackages) {
      return SizedBox(
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return CustomShimmer(
              width: 170,
              height: 210,
              borderRadius: 10,
            );
          },
        ),
      );
    }

    if (_corporatePackagesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child:
            Text("Failed to load corporate packages: $_corporatePackagesError"),
      );
    }

    if (_corporatePackageItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("No corporate packages found"),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        itemCount: _corporatePackageItems.length > 3
            ? 3
            : _corporatePackageItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _corporatePackageItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                "model": item,
              });
            },
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor.darken(50)),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: UiUtils.getImage(
                          item.image ?? "",
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\$ ${item.price?.toStringAsFixed(2) ?? '0.00'}",
                              style: TextStyle(
                                fontSize: context.font.large,
                                fontWeight: FontWeight.w700,
                                color: context.color.territoryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name ?? "",
                              style: TextStyle(
                                fontSize: context.font.small * 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: context.color.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.address ?? "",
                                    style: TextStyle(
                                      fontSize: context.font.small,
                                      color: context.color.textLightColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.isFeature ?? false)
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.color.territoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Featured",
                          style: TextStyle(
                            fontSize: context.font.small * 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    end: 8,
                    bottom: 45,
                    child: BlocProvider(
                      create: (context) =>
                          UpdateFavoriteCubit(FavoriteRepository()),
                      child: BlocBuilder<FavoriteCubit, FavoriteState>(
                        builder: (context, state) {
                          bool isLike = context
                              .read<FavoriteCubit>()
                              .isItemFavorite(item.id!);
                          return GestureDetector(
                            onTap: () {
                              UiUtils.checkUser(
                                context: context,
                                onNotGuest: () {
                                  context
                                      .read<UpdateFavoriteCubit>()
                                      .setFavoriteItem(
                                        item: item,
                                        type: isLike ? 0 : 1,
                                      );
                                },
                              );
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: context.color.secondaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isLike
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: context.color.territoryColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget sliderWidget() {
    return BlocConsumer<SliderCubit, SliderState>(
      listener: (context, state) {
        if (state is SliderFetchSuccess) {
          setState(() {});
        }
      },
      builder: (context, state) {
        log('State is  $state');
        if (state is SliderFetchInProgress) {
          return const SliderShimmer();
        }
        if (state is SliderFetchFailure) {
          return Container();
        }
        if (state is SliderFetchSuccess) {
          if (state.sliderlist.isNotEmpty) {
            return const SliderWidget();
          }
        }
        return Container();
      },
    );
  }

  // Fetch notifications
  void _fetchNotifications() {
    if (_isNotificationLoading || !HiveUtils.isUserAuthenticated()) return;

    setState(() {
      _isNotificationLoading = true;
    });

    // Use the API to fetch notifications with proper parameters
    Api.get(
      url: Api.getNotificationListApi,
      queryParameters: {
        "page": 1
      }, // Add page parameter to ensure proper API call
    ).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        // Check if data exists and is a list
        if (response['data'] is List) {
          List list = response['data'];
          _notifications =
              list.map((model) => NotificationData.fromJson(model)).toList();
          log('Fetched ${_notifications.length} notifications');
        } else if (response['data']['data'] != null &&
            response['data']['data'] is List) {
          // Some APIs use a nested data structure
          List list = response['data']['data'];
          _notifications =
              list.map((model) => NotificationData.fromJson(model)).toList();
          log('Fetched ${_notifications.length} notifications from nested data');
        } else {
          log('Notification data format unexpected: ${response['data']}');
          _notifications = [];
        }
      } else {
        log('No notifications found or error in response');
        _notifications = [];
      }

      if (mounted) {
        setState(() {
          _isNotificationLoading = false;
        });
      }
    }).catchError((error) {
      log('Error fetching notifications: $error');
      if (mounted) {
        setState(() {
          _isNotificationLoading = false;
          _notifications = []; // Clear on error
        });
      }
    });
  }

  // Check if there are unread notifications
  bool _hasUnreadNotifications() {
    if (!HiveUtils.isUserAuthenticated()) return false;

    // A provider should see notifications for their packages and posts
    final isProvider = HiveUtils.getUserType() == "Expert" ||
        HiveUtils.getUserType() == "Business";

    if (isProvider) {
      // Check for provider-specific notifications
      return _notifications.any((notification) =>
          notification.isProviderNotification() && !notification.isRead);
    }

    return false;
  }

  // Get count of unread notifications
  int _getNotificationCount() {
    if (!HiveUtils.isUserAuthenticated()) return 0;

    // A provider should see notifications for their packages and posts
    final isProvider = HiveUtils.getUserType() == "Expert" ||
        HiveUtils.getUserType() == "Business";

    if (isProvider) {
      // Count provider-specific notifications
      return _notifications
          .where((notification) =>
              notification.isProviderNotification() && !notification.isRead)
          .length;
    }

    return 0;
  }

  // Fetch items with post_type as experience
  void _fetchExperienceItems() {
    setState(() {
      _isLoadingExperiences = true;
      _experienceError = null;
    });

    Map<String, dynamic> parameters = {
      "page": 1,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null)
        'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getExperienceItemsApi, queryParameters: parameters)
        .then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        }

        if (mounted) {
          setState(() {
            _experienceItems.clear();
            _experienceItems.addAll(items);
            _isLoadingExperiences = false;
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingExperiences = false;
          _experienceError = error.toString();
        });
      }
    });
  }

  // Fetch featured users
  void _fetchFeaturedUsers() {
    setState(() {
      _isLoadingFeaturedUsers = true;
      _featuredUsersError = null;
    });

    Map<String, dynamic> parameters = {
      "page": 1,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null)
        'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.featuredUsersApi, queryParameters: parameters)
        .then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<dynamic> users = [];

        // Parse the featured users data
        if (response['data']['data'] is List) {
          users = response['data']['data'];
        }

        if (mounted) {
          setState(() {
            _featuredUsers.clear();
            _featuredUsers.addAll(users);
            _isLoadingFeaturedUsers = false;
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingFeaturedUsers = false;
          _featuredUsersError = error.toString();
        });
      }
    });
  }

  // Add new method for fetching women exclusive items
  void _fetchWomenExclusiveItems() {
    setState(() {
      _isLoadingWomenExclusive = true;
      _womenExclusiveError = null;
    });

    Map<String, dynamic> parameters = {
      "page": 1,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null)
        'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getExclusiveWomenItemsApi, queryParameters: parameters)
        .then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        }

        if (mounted) {
          setState(() {
            _womenExclusiveItems.clear();
            _womenExclusiveItems.addAll(items);
            _isLoadingWomenExclusive = false;
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingWomenExclusive = false;
          _womenExclusiveError = error.toString();
        });
      }
    });
  }

  // Add new method for fetching corporate package items
  void _fetchCorporatePackageItems() {
    setState(() {
      _isLoadingCorporatePackages = true;
      _corporatePackagesError = null;
    });

    Map<String, dynamic> parameters = {
      "page": 1,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null)
        'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getCorporatePackageItemsApi, queryParameters: parameters)
        .then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        }

        if (mounted) {
          setState(() {
            _corporatePackageItems.clear();
            _corporatePackageItems.addAll(items);
            _isLoadingCorporatePackages = false;
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingCorporatePackages = false;
          _corporatePackagesError = error.toString();
        });
      }
    });
  }

  // Add a new method to build exclusive experiences section
  Widget _buildExclusiveExperiences(BuildContext context) {
    if (_isLoadingExperiences) {
      return SizedBox(
        height: 200,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return CustomShimmer(
              width: 300,
              height: 200,
              borderRadius: 10,
            );
          },
        ),
      );
    }

    if (_experienceError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: Text("Failed to load experiences: $_experienceError"),
      );
    }

    if (_experienceItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: sidePadding),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.color.secondaryColor.withOpacity(0.5),
          border: Border.all(color: context.color.borderColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: context.color.territoryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              "No Exclusive Experiences Available",
              style: TextStyle(
                fontSize: context.font.large,
                fontWeight: FontWeight.w600,
                color: context.color.textColorDark,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Check back soon for unique experiences",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 236, // Increased height to fix overflow
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        itemCount: _experienceItems.length > 3 ? 3 : _experienceItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final experience = _experienceItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                "model": experience,
              });
            },
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.color.secondaryColor,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: UiUtils.getImage(
                          experience.image ?? "",
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\$${experience.price?.toStringAsFixed(2) ?? '0.00'}",
                              style: TextStyle(
                                fontSize: context.font.large,
                                fontWeight: FontWeight.w700,
                                color: context.color.territoryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              experience.name ?? "",
                              style: TextStyle(
                                fontSize: context.font.small * 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (experience.expirationDate != null)
                              Text(
                                "Available until: ${experience.expirationDate?.toString().split(' ')[0] ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: context.font.small,
                                  color: context.color.textLightColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Experience badge
                  PositionedDirectional(
                    start: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.color.territoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Experience",
                        style: TextStyle(
                          fontSize: context.font.small * 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Like button
                  PositionedDirectional(
                    end: 8,
                    top: 8,
                    child: BlocBuilder<FavoriteCubit, FavoriteState>(
                      builder: (context, state) {
                        bool isLike = context
                            .read<FavoriteCubit>()
                            .isItemFavorite(experience.id!);
                        return GestureDetector(
                          onTap: () {
                            UiUtils.checkUser(
                              context: context,
                              onNotGuest: () {
                                context
                                    .read<UpdateFavoriteCubit>()
                                    .setFavoriteItem(
                                      item: experience,
                                      type: isLike ? 0 : 1,
                                    );
                              },
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.color.secondaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isLike ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: context.color.territoryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Fetch newest items
  void _fetchNewestItems() {
    setState(() {
      _isLoadingNewestItems = true;
      _newestItemsError = null;
    });

    Map<String, dynamic> parameters = {
      "page": 1,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null)
        'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getNewestItemsApi, queryParameters: parameters)
        .then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List)
              .map((e) => ItemModel.fromJson(e))
              .toList();
        }

        if (mounted) {
          setState(() {
            _newestItems.clear();
            _newestItems.addAll(items);
            _isLoadingNewestItems = false;
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingNewestItems = false;
          _newestItemsError = error.toString();
        });
      }
    });
  }
}

class AllItemsWidget extends StatelessWidget {
  const AllItemsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllItemsCubit, FetchHomeAllItemsState>(
      builder: (context, state) {
        if (state is FetchHomeAllItemsSuccess) {
          if (state.items.isNotEmpty) {
            final int crossAxisCount = 2;
            final int items = state.items.length;
            final int total = (items ~/ crossAxisCount) +
                (items % crossAxisCount != 0 ? 1 : 0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridListAdapter(
                    type: ListUiType.List,
                    crossAxisCount: 2,
                    builder: (context, int index, bool isGrid) {
                      int itemIndex = index * crossAxisCount;
                      return SizedBox(
                        height: MediaQuery.sizeOf(context).height / 3.5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < crossAxisCount; ++i) ...[
                              Expanded(
                                  child: itemIndex + 1 <= items
                                      ? ItemCard(item: state.items[itemIndex++])
                                      : SizedBox.shrink()),
                              if (i != crossAxisCount - 1)
                                SizedBox(
                                  width: 15,
                                )
                            ]
                          ],
                        ),
                      );
                    },
                    listSeparator: (context, index) {
                      if (index == 0 ||
                          index % Constant.nativeAdsAfterItemNumber != 0) {
                        return SizedBox(
                          height: 15,
                        );
                      } else {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 5,
                            ),
                            AdBannerWidget(),
                            SizedBox(
                              height: 5,
                            ),
                          ],
                        );
                      }
                    },
                    total: total),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          } else {
            return SizedBox.shrink();
          }
        }
        if (state is FetchHomeAllItemsFail) {
          if (state.error is ApiException) {
            if (state.error.error == "no-internet") {
              return Center(child: NoInternet());
            }
          }

          return const SomethingWentWrong();
        }
        return SizedBox.shrink();
      },
    );
  }
}

Future<void> notificationPermissionChecker() async {
  if (!(await Permission.notification.isGranted)) {
    await Permission.notification.request();
  }
}
