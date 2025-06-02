// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:tlobni/data/cubits/item/manage_item_cubit.dart';
import 'package:tlobni/data/cubits/slider_cubit.dart';
import 'package:tlobni/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:tlobni/data/cubits/system/get_api_keys_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/notification_data.dart';
import 'package:tlobni/data/model/system_settings_model.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/screens/home/slider_widget.dart';
import 'package:tlobni/ui/screens/home/widgets/category_widget_home.dart';
import 'package:tlobni/ui/screens/home/widgets/home_list.dart';
import 'package:tlobni/ui/screens/home/widgets/home_shimmer_effect.dart';
import 'package:tlobni/ui/screens/home/widgets/home_shimmers.dart';
import 'package:tlobni/ui/screens/home/widgets/item_container.dart';
import 'package:tlobni/ui/screens/home/widgets/provider_home_screen_container.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
//import 'package:uni_links/uni_links.dart';

import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/notification/awsome_notification.dart';
import 'package:tlobni/utils/ui_utils.dart';

const double sidePadding = 10;

Future<void> notificationPermissionChecker() async {
  if (!(await Permission.notification.isGranted)) {
    await Permission.notification.request();
  }
}

void _goToItemListingSearch(BuildContext context) {
  _goToSearchPage(context, SearchScreenType.itemListing);
}

void _goToProviderSearch(BuildContext context) {
  _goToSearchPage(context, SearchScreenType.provider);
}

void _goToSearchPage(BuildContext context, SearchScreenType type) {
  Navigator.pushNamed(
    context,
    Routes.searchScreenRoute,
    arguments: {'autoFocus': true, 'screenType': type},
  );
}

class HomeScreen extends StatefulWidget {
  final String? from;

  const HomeScreen({super.key, this.from});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
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

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // Add these new properties
  final List<ItemModel> _experienceItems = [];

  bool _isLoadingExperiences = true;
  String? _experienceError;

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
  final List<User> _featuredUsers = [];

  bool _isLoadingFeaturedUsers = true;
  String? _featuredUsersError;

  //
  @override
  bool get wantKeepAlive => true;

  void addPageScrollListener() {
    //homeScreenController.addListener(pageScrollListener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leadingWidth: double.maxFinite,
          bottom: PreferredSize(preferredSize: Size(double.infinity, 1), child: Divider(height: 1, thickness: 1)),
          leading: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40, child: Image.asset('assets/images/tlobni-logo.png')),
            ],
          ),

          // leading:
          //     Padding(padding: EdgeInsetsDirectional.only(start: sidePadding, end: sidePadding), child: const LocationAutocompleteHeader()),
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          actions: [
            // Add notification icon with badge
            Padding(
              padding: EdgeInsetsDirectional.only(end: 15.0),
              child: _notificationsAppbarAction(),
            ),
          ],
        ),
        backgroundColor: context.color.primaryColor,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _searchField(),

                const SizedBox(height: 20),

                // Exclusive Experiences Section
                _buildExclusiveExperiences(),

                const SizedBox(height: 10),

                // Categories
                const CategoryWidgetHome(),

                const SizedBox(height: 25),

                _buildFeaturedProviders(),

                const SizedBox(height: 30),
                // Newest Listings Section
                _buildNewestListings(),

                const SizedBox(height: 30),
                // Women-Exclusive Services
                _buildWomenExclusiveServices(),

                const SizedBox(height: 30),
                // Corporate & Business Packages
                _buildCorporatePackages(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _itemUpdatesSubscription?.cancel();
    super.dispose();
  }

  Widget favouriteButton(BuildContext context, ItemModel model) {
    bool isAddedByMe = (model.user?.id != null ? model.user!.id.toString() : model.userId) == HiveUtils.getUserId();
    if (!isAddedByMe) {
      return BlocBuilder<FavoriteCubit, FavoriteState>(
        bloc: context.read<FavoriteCubit>(),
        builder: (context, favState) {
          bool isLike = context.select((FavoriteCubit cubit) => cubit.isItemFavorite(model.id!));

          return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
            bloc: context.read<UpdateFavoriteCubit>(),
            listener: (context, state) {
              if (state is UpdateFavoriteSuccess) {
                if (state.wasProcess) {
                  context.read<FavoriteCubit>().addFavoriteitem(state.item);
                } else {
                  context.read<FavoriteCubit>().removeFavoriteItem(state.item);
                }
              }
            },
            builder: (context, state) {
              return setTopRowItem(
                  alignment: AlignmentDirectional.topEnd,
                  marginVal: 10,
                  backgroundColor: context.color.backgroundColor,
                  cornerRadius: 30,
                  childWidget: InkWell(
                    onTap: () {
                      UiUtils.checkUser(
                          onNotGuest: () {
                            context.read<UpdateFavoriteCubit>().setFavoriteItem(
                                  item: model,
                                  type: isLike ? 0 : 1,
                                );
                          },
                          context: context);
                    },
                    child: UiUtils.getSvg(isLike ? AppIcons.like_fill : AppIcons.like,
                        color: context.color.territoryColor, width: 22, height: 22),
                  ));
            },
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  void fetchApiKeys() {
    context.read<GetApiKeysCubit>().fetch();
  }

  void initializeSettings() {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment("force-disable-demo-mode", defaultValue: false)) {
      Constant.isDemoModeOn = settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    initializeSettings();
    addPageScrollListener();
    notificationPermissionChecker();
    LocalAwesomeNotification().init(context);
    ///////////////////////////////////////
    context.read<SliderCubit>().fetchSlider(
          context,
        );
    context.read<FetchCategoryCubit>().fetchCategories(
          type: CategoryType.serviceExperience,
        );
    context.read<FetchHomeScreenCubit>().fetch(
        city: HiveUtils.getCityName(), areaId: HiveUtils.getAreaId(), country: HiveUtils.getCountryName(), state: HiveUtils.getStateName());
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
    _notificationRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _fetchNotifications();
      }
    });

    // Listen for item update events
    _itemUpdatesSubscription = ItemEvents().itemEditedStream.stream.listen((updatedItem) {
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

  Widget setTopRowItem(
      {required AlignmentDirectional alignment,
      required double marginVal,
      required double cornerRadius,
      required Color backgroundColor,
      required Widget childWidget}) {
    return Align(
        alignment: alignment,
        child: Container(
            margin: EdgeInsets.all(marginVal),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(cornerRadius), color: backgroundColor),
            child: childWidget)
        //TODO: swap icons according to liked and non-liked -- favorite_border_rounded and favorite_rounded
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

  Widget _buildCorporatePackages() {
    return HomeList(
      title: 'Corporate Packages',
      isLoading: _isLoadingCorporatePackages,
      error: _corporatePackagesError == null ? null : 'Failed to load corporate packages: $_corporatePackagesError',
      shimmerEffect: HomeShimmerEffect(),
      onViewAll: () => _goToItemListingSearch(context),
      children: _corporatePackageItems.map(_itemContainer).toList(),
    );
  }

  Widget _itemContainer(ItemModel item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemContainer(small: false, item: item),
          ],
        ),
      );

  // Add a new method to build exclusive experiences section
  Widget _buildExclusiveExperiences() {
    final items = _experienceItems;

    return HomeList(
      title: 'Exclusive Experiences',
      isLoading: _isLoadingExperiences,
      error: _experienceError == null ? null : 'Failed to load experiences: $_experienceError',
      shimmerEffect: HomeShimmerEffect(
        itemCount: 3,
        width: context.screenWidth * 0.85,
        height: 400,
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
      ),
      onViewAll: () => _goToItemListingSearch(context),
      children: items.map(_itemContainer).toList(),
    );
  }

  Widget _buildFeaturedProviders() {
    return Container(
      color: kColorSecondaryBeige.withValues(alpha: 0.2),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: HomeList(
        title: 'Featured Providers',
        onViewAll: () => _goToProviderSearch(context),
        error: _featuredUsersError == null ? null : 'Failed to load featured users: $_featuredUsersError',
        isLoading: _isLoadingFeaturedUsers,
        shimmerEffect: HomeShimmerEffect(height: 100),
        children: _featuredUsers.map((user) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
            child: ProviderHomeScreenContainer(user: user),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewestListings() {
    return HomeList(
      title: 'Newest Services',
      isLoading: _isLoadingNewestItems,
      error: _newestItemsError == null ? null : 'Failed to load newest items: $_newestItemsError',
      shimmerEffect: HomeShimmerEffect(),
      onViewAll: () => _goToItemListingSearch(context),
      children: _newestItems.map(_itemContainer).toList(),
    );
  }

  Widget _buildWomenExclusiveServices() {
    return HomeList(
      title: 'Women-Exclusive Services',
      isLoading: _isLoadingWomenExclusive,
      error: _womenExclusiveError == null ? null : 'Failed to load women-exclusive services: $_womenExclusiveError',
      shimmerEffect: HomeShimmerEffect(),
      onViewAll: () => _goToItemListingSearch(context),
      children: _womenExclusiveItems.map(_itemContainer).toList(),
    );
  }

  // Add new method for fetching corporate package items
  void _fetchCorporatePackageItems() {
    setState(() {
      _isLoadingCorporatePackages = true;
      _corporatePackagesError = null;
    });

    Map<String, dynamic> parameters = {
      'limit': 5,
      "offset": 0,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getCorporatePackageItemsApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List).map((e) => ItemModel.fromJson(e)).toList();
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

  // Fetch items with post_type as experience
  void _fetchExperienceItems() {
    setState(() {
      _isLoadingExperiences = true;
      _experienceError = null;
    });

    Map<String, dynamic> parameters = {
      "limit": 5,
      'offset': 0,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getExperienceItemsApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List).map((e) => ItemModel.fromJson(e)).toList();
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
      "limit": 5,
      'offset': 0,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.featuredUsersApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<dynamic> users = [];

        // Parse the featured users data
        if (response['data']['data'] is List) {
          users = response['data']['data'];
        }

        if (mounted) {
          setState(() {
            _featuredUsers.clear();
            _featuredUsers.addAll(users.map((e) => User.fromJson(e)));
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

  // Fetch newest items
  void _fetchNewestItems() {
    setState(() {
      _isLoadingNewestItems = true;
      _newestItemsError = null;
    });

    Map<String, dynamic> parameters = {
      "limit": 5,
      'offset': 0,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getNewestItemsApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List).map((e) => ItemModel.fromJson(e)).toList();
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

  // Fetch notifications
  void _fetchNotifications() {
    if (_isNotificationLoading || !HiveUtils.isUserAuthenticated()) return;

    setState(() {
      _isNotificationLoading = true;
    });

    // Use the API to fetch notifications with proper parameters
    Api.get(
      url: Api.getNotificationListApi,
      queryParameters: {"page": 1}, // Add page parameter to ensure proper API call
    ).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        // Check if data exists and is a list
        if (response['data'] is List) {
          List list = response['data'];
          _notifications = list.map((model) => NotificationData.fromJson(model)).toList();
          log('Fetched ${_notifications.length} notifications');
        } else if (response['data']['data'] != null && response['data']['data'] is List) {
          // Some APIs use a nested data structure
          List list = response['data']['data'];
          _notifications = list.map((model) => NotificationData.fromJson(model)).toList();
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

  // Add new method for fetching women exclusive items
  void _fetchWomenExclusiveItems() {
    setState(() {
      _isLoadingWomenExclusive = true;
      _womenExclusiveError = null;
    });

    Map<String, dynamic> parameters = {
      'limit': 5,
      "offset": 0,
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    Api.get(url: Api.getExclusiveWomenItemsApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List).map((e) => ItemModel.fromJson(e)).toList();
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

  // Get count of unread notifications
  int _getNotificationCount() {
    if (!HiveUtils.isUserAuthenticated()) return 0;

    // A provider should see notifications for their packages and posts
    final isProvider = HiveUtils.getUserType() == "Expert" || HiveUtils.getUserType() == "Business";

    if (isProvider) {
      // Count provider-specific notifications
      return _notifications.where((notification) => notification.isProviderNotification() && !notification.isRead).length;
    }

    return 0;
  }

  // Check if there are unread notifications
  bool _hasUnreadNotifications() {
    if (!HiveUtils.isUserAuthenticated()) return false;

    // A provider should see notifications for their packages and posts
    final isProvider = HiveUtils.getUserType() == "Expert" || HiveUtils.getUserType() == "Business";

    if (isProvider) {
      // Check for provider-specific notifications
      return _notifications.any((notification) => notification.isProviderNotification() && !notification.isRead);
    }

    return false;
  }

  Widget _notificationsAppbarAction() => Stack(
        children: [
          MaterialButton(
            minWidth: 0,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.all(15),
            shape: CircleBorder(),
            onPressed: () {
              UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.notificationPage);
                },
                context: context,
              );
            },
            child: Icon(
              Icons.notifications_outlined,
              color: context.color.textDefaultColor,
            ),
          ),
          // Notification badge - Only show if there are unread notifications
          if (HiveUtils.isUserAuthenticated() && _hasUnreadNotifications())
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
                  _getNotificationCount() > 9 ? '9+' : _getNotificationCount().toString(),
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
      );

  Future<void> _onRefresh() async {
    // Fetch all data
    context.read<SliderCubit>().fetchSlider(context);
    context.read<FetchCategoryCubit>().fetchCategories(
          type: CategoryType.serviceExperience,
        );
    context.read<FetchHomeScreenCubit>().fetch(
        city: HiveUtils.getCityName(), areaId: HiveUtils.getAreaId(), country: HiveUtils.getCountryName(), state: HiveUtils.getStateName());
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
  }

  Widget _searchField() => Container(
        margin: EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => _goToItemListingSearch(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(120),
              color: Colors.white,
              boxShadow: kElevationToShadow[1]?.map((e) => e.copyWith(offset: Offset.zero)).toList(),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Row(
              children: [
                Icon(Icons.search, size: 25, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(child: SmallText('Search for Services & Experiences', color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
}
