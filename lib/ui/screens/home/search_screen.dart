import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/item/fetch_popular_items_cubit.dart';
import 'package:tlobni/data/cubits/item/search_item_cubit.dart';
import 'package:tlobni/data/cubits/system/app_theme_cubit.dart';
import 'package:tlobni/data/cubits/user/search_providers_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/ui/screens/filter/item_listing_filter_screen.dart';
import 'package:tlobni/ui/screens/filter/provider_filter_screen.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_keys.dart';
import 'package:tlobni/utils/ui_utils.dart';

enum SearchScreenType { provider, itemListing }

class SearchScreen extends StatefulWidget {
  final ItemFilterModel? initialItemFilter;
  final SearchScreenType screenType;

  const SearchScreen({
    super.key,
    required this.screenType,
    this.initialItemFilter,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    // Extract the filter if it's passed in the arguments
    ItemFilterModel? itemFilter =
        arguments != null && arguments.containsKey('itemFilter') ? arguments['itemFilter'] as ItemFilterModel : null;

    SearchScreenType? screenType = arguments?['screenType'];

    assert(screenType != null);

    // Debug log to trace filter passing
    print("DEBUG ROUTE: Creating search route with filter: ${itemFilter?.toJson()}");

    return BlurredRouter(
      builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) {
                final cubit = SearchItemCubit();
                // Don't trigger search here, let initState handle it
                // This prevents double API calls
                print("DEBUG ROUTE: Created SearchItemCubit (search will be triggered in initState)");
                return cubit;
              },
            ),
            BlocProvider(
              create: (context) {
                final cubit = SearchProvidersCubit();
                // Don't trigger search here, let initState handle it
                // This prevents double API calls
                print("DEBUG ROUTE: Created SearchProvidersCubit (search will be triggered in initState)");
                return cubit;
              },
            ),
            BlocProvider(
              create: (context) => FetchPopularItemsCubit(),
            ),
          ],
          child: SearchScreen(
            initialItemFilter: itemFilter,
            screenType: screenType!,
          )),
    );
  }

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<SearchScreen> {
  @override
  bool get wantKeepAlive => true;
  bool isFocused = false;
  String previousSearchQuery = "";
  static TextEditingController searchController = TextEditingController();
  final ScrollController controller = ScrollController();
  final ScrollController popularController = ScrollController();
  final ScrollController providerController = ScrollController();
  Timer? _searchDelay;
  late ItemFilterModel? filter = widget.initialItemFilter;

  // To determine if we're showing providers or services
  bool get isProviderSearch => widget.screenType == SearchScreenType.provider; //filter != null && filter!.userType != null;

  //to store selected filter categories
  List<CategoryModel> categoryList = [];

  @override
  void initState() {
    super.initState();

    print("DEBUG: Search screen initialized with filter: ${filter?.toJson()}");

    context.read<FetchPopularItemsCubit>().fetchPopularItems();
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
    popularController.addListener(pagePopularScrollListen);
    providerController.addListener(pageProviderScrollListen);

    // If we have a filter, initiate a search immediately
    // if (filter != null) {
    // Prevent double initialization
    bool shouldInitiateSearch = true;

    print("DEBUG: Preparing to search with filter. Provider search: $isProviderSearch");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!shouldInitiateSearch) {
        print("DEBUG: Search already initiated, skipping duplicate search");
        return;
      }

      shouldInitiateSearch = false;

      if (isProviderSearch) {
        // Provider search
        print("DEBUG: Initiating provider search with filter: ${filter?.toJson()}");
        context.read<SearchProvidersCubit>().searchProviders(
              searchController.text,
              page: 1,
              filter: filter,
            );
      } else {
        // Service search
        print("DEBUG: Initiating service search with filter: ${filter?.toJson()}");
        context.read<SearchItemCubit>().searchItem(
              searchController.text,
              page: 1,
              filter: filter,
            );
      }
    });
    // }
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<SearchItemCubit>().hasMoreData()) {
        context.read<SearchItemCubit>().fetchMoreSearchData(searchController.text, Constant.itemFilter);
      }
    }
  }

  void pageProviderScrollListen() {
    if (providerController.isEndReached()) {
      if (context.read<SearchProvidersCubit>().hasMoreData()) {
        context.read<SearchProvidersCubit>().fetchMoreProviders(searchController.text, Constant.itemFilter);
      }
    }
  }

  void pagePopularScrollListen() {
    if (popularController.isEndReached()) {
      if (context.read<FetchPopularItemsCubit>().hasMoreData()) {
        context.read<FetchPopularItemsCubit>().fetchMyMoreItems();
      }
    }
  }

  //this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
    setState(() {});
  }

  //This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    if (previousSearchQuery != searchController.text) {
      if (isProviderSearch) {
        // Provider search
        context.read<SearchProvidersCubit>().searchProviders(
              searchController.text,
              page: 1,
              filter: filter,
            );
      } else {
        // Service search
        context.read<SearchItemCubit>().searchItem(
              searchController.text,
              page: 1,
              filter: filter,
            );
      }
      previousSearchQuery = searchController.text;
      setState(() {});
    }
  }

  void refreshData() {
    switch (widget.screenType) {
      case SearchScreenType.provider:
        context.read<SearchProvidersCubit>().searchProviders(
              searchController.text,
              page: 1,
              filter: filter,
            );
        break;
      case SearchScreenType.itemListing:
        context.read<SearchItemCubit>().searchItem(searchController.text, page: 1, filter: filter);
        break;
    }
  }

  PreferredSizeWidget appBarWidget() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: context.color.backgroundColor),
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: LayoutBuilder(builder: (context, c) {
            return SizedBox(
                width: c.maxWidth,
                child: FittedBox(
                  fit: BoxFit.none,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 270,
                            height: 50,
                            alignment: AlignmentDirectional.center,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark ? 0 : 1,
                                    color: context.color.borderColor.darken(30)),
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                color: context.color.secondaryColor),
                            child: buildSearchTextField()),
                        const SizedBox(
                          width: 14,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final filter = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => switch (widget.screenType) {
                                  SearchScreenType.provider => ProviderFilterScreen(initialFilter: this.filter),
                                  SearchScreenType.itemListing => ItemListingFilterScreen(initialFilter: this.filter),
                                },
                              ),
                            );
                            if (filter == null) return;
                            this.filter = filter;
                            refreshData();
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(width: 1, color: context.color.borderColor.darken(30)),
                              color: context.color.secondaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: UiUtils.getSvg(filter != null ? AppIcons.filterByIcon : AppIcons.filter,
                                  color: context.color.territoryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
          })),
      automaticallyImplyLeading: false,
      leading: Material(
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.circle,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
              padding: EdgeInsetsDirectional.only(start: 18.0, top: 12),
              child: Directionality(
                  textDirection: Directionality.of(context),
                  child: RotatedBox(
                    quarterTurns: Directionality.of(context) == TextDirection.rtl ? 2 : -4,
                    child: UiUtils.getSvg(AppIcons.arrowLeft, fit: BoxFit.none, color: context.color.textDefaultColor),
                  ))),
        ),
      ),
      elevation: context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark ? 0 : 6,
      shadowColor: context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark ? null : context.color.textDefaultColor.withOpacity(0.2),
      backgroundColor: context.color.backgroundColor,
    );
  }

  void getFilterValue(ItemFilterModel model) {
    filter = model;
    setState(() {});
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CustomShimmer(height: 90, width: 90),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth - 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomShimmer(
                        height: 10,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth / 1.2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: CustomShimmer(
                          width: c.maxWidth / 4,
                        ),
                      ),
                    ],
                  );
                }),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (isPop, result) {
        Constant.itemFilter = null;
      },
      child: Scaffold(
        appBar: appBarWidget(),
        body: RefreshIndicator(onRefresh: () async => refreshData(), child: bodyData()),
        backgroundColor: context.color.backgroundColor,
      ),
    );
  }

  Widget bodyData() {
    if (isProviderSearch) {
      // Provider search content
      return BlocConsumer<SearchProvidersCubit, SearchProvidersState>(
        listener: (context, searchState) {
          // Add any specific listener logic for SearchProvidersCubit state changes if needed
        },
        builder: (context, searchState) {
          bool hasSearchResults = searchState is SearchProvidersSuccess && searchState.searchedProviders.isNotEmpty;

          ScrollController activeController = hasSearchResults ? providerController : popularController;

          return SingleChildScrollView(
            padding: EdgeInsets.only(top: 10),
            physics: AlwaysScrollableScrollPhysics(),
            controller: activeController,
            child: providersItemsWidget(),
          );
        },
      );
    } else {
      // Service search content
      return BlocConsumer<SearchItemCubit, SearchItemState>(
        listener: (context, searchState) {
          // Add any specific listener logic for SearchItemCubit state changes if needed
        },
        builder: (context, searchState) {
          bool hasSearchResults = searchState is SearchItemSuccess && searchState.searchedItems.isNotEmpty;

          ScrollController activeController = hasSearchResults ? controller : popularController;

          return SingleChildScrollView(
            padding: EdgeInsets.only(top: 10),
            physics: AlwaysScrollableScrollPhysics(),
            controller: activeController,
            child: searchItemsWidget(),
          );
        },
      );
    }
  }

  void clearBoxData() async {
    var box = Hive.box(HiveKeys.historyBox);
    await box.clear();
    setState(() {});
  }

  Widget buildHistoryItemList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.historyBox).listenable(),
      builder: (context, Box box, _) {
        List<ItemModel> items = box.values.map((jsonString) {
          return ItemModel.fromJson(jsonDecode(jsonString));
        }).toList();

        if (items.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "recentSearches".translate(context),
                      color: context.color.textDefaultColor.withOpacity(0.3),
                    ),
                    InkWell(
                      child: CustomText(
                        "clear".translate(context),
                        color: context.color.territoryColor,
                      ),
                      onTap: () {
                        clearBoxData();
                      },
                    ),
                  ],
                ),
                ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(
                      color: context.color.borderColor.darken(30),
                      thickness: 1.2,
                    );
                  },
                  padding: EdgeInsets.only(top: 10),
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 22,
                          color: context.color.textDefaultColor,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "${items[index].name!}\tin\t",
                              style: TextStyle(color: context.color.textDefaultColor.withOpacity(0.3), overflow: TextOverflow.ellipsis),
                              children: <TextSpan>[
                                TextSpan(
                                  text: items[index].category!.name,
                                  style: TextStyle(
                                    color: context.color.textDefaultColor,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(
                  color: context.color.borderColor.darken(30),
                  thickness: 1.2,
                )
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  void insertNewItem(ItemModel model) {
    var box = Hive.box(HiveKeys.historyBox);

    // Check if the model.id is already present in the box
    bool exists = false;
    for (int i = 0; i < box.length; i++) {
      var item = jsonDecode(box.getAt(i));
      if (item['id'] == model.id) {
        exists = true;
        break;
      }
    }

    // If the id does not exist, add the new item
    if (!exists) {
      // Ensure the box length does not exceed 5
      if (box.length >= 5) {
        box.deleteAt(0);
      }

      box.add(jsonEncode(model.toJson()));
    }

    setState(() {});
  }

  // Widget to show provider search results
  Widget providersItemsWidget() {
    return BlocBuilder<SearchProvidersCubit, SearchProvidersState>(
      builder: (context, state) {
        if (state is SearchProvidersFetchProgress) {
          return shimmerEffect();
        }

        if (state is SearchProvidersFailure) {
          if (state.errorMessage == "no-internet") {
            return SingleChildScrollView(
              child: NoInternet(
                onRetry: () {
                  context.read<SearchProvidersCubit>().searchProviders(
                        searchController.text.toString(),
                        page: 1,
                        filter: filter,
                      );
                },
              ),
            );
          }

          return Center(child: const SomethingWentWrong());
        }

        if (state is SearchProvidersSuccess) {
          if (state.searchedProviders.isEmpty) {
            return SingleChildScrollView(child: NoDataFound(onTap: refreshData));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: sidePadding,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 3),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return Container(height: 8);
                  },
                  itemBuilder: (context, index) {
                    UserModel provider = state.searchedProviders[index];

                    return InkWell(
                      onTap: () {
                        // Create a User object from the UserModel provider
                        Navigator.pushNamed(
                          context,
                          Routes.sellerProfileScreen,
                          arguments: {
                            'model': User(
                              id: provider.id,
                              name: provider.name,
                              email: provider.email,
                              mobile: provider.mobile,
                              categoriesIds: provider.categoriesIds,
                              country: provider.country,
                              city: provider.city,
                              state: provider.state,
                              type: provider.type,
                              profile: provider.profile,
                              bio: provider.bio,
                              website: provider.website,
                              facebook: provider.facebook,
                              twitter: provider.twitter,
                              instagram: provider.instagram,
                              tiktok: provider.tiktok,
                              address: provider.address,
                              isVerified: provider.isVerified,
                              showPersonalDetails: provider.isPersonalDetailShow,
                              createdAt: provider.createdAt,
                              updatedAt: provider.updatedAt,
                            ),
                          },
                        );
                      },
                      child: ProviderCard(
                        provider: provider,
                      ),
                    );
                  },
                  itemCount: state.searchedProviders.length,
                ),
                if (state.isLoadingMore)
                  Center(
                    child: UiUtils.progress(
                      normalProgressColor: context.color.territoryColor,
                    ),
                  )
              ],
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget searchItemsWidget() {
    return RefreshIndicator(
      onRefresh: () async => refreshData(),
      child: BlocBuilder<SearchItemCubit, SearchItemState>(
        builder: (context, state) {
          if (state is SearchItemFetchProgress) {
            return shimmerEffect();
          }

          if (state is SearchItemFailure) {
            if (state.errorMessage is ApiException) {
              if (state.errorMessage == "no-internet") {
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: NoInternet(
                    onRetry: () {
                      context.read<SearchItemCubit>().searchItem(searchController.text.toString(), page: 1, filter: filter);
                    },
                  ),
                );
              }
            }

            return Center(child: const SomethingWentWrong());
          }

          if (state is SearchItemSuccess) {
            if (state.searchedItems.isEmpty) {
              return _noDataFound();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: sidePadding,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 3,
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 8,
                      );
                    },
                    itemBuilder: (context, index) {
                      ItemModel item = state.searchedItems[index];

                      return InkWell(
                        onTap: () {
                          insertNewItem(item);
                          Navigator.pushNamed(
                            context,
                            Routes.adDetailsScreen,
                            arguments: {
                              'model': item,
                            },
                          );
                        },
                        child: ItemHorizontalCard(
                          item: item,
                          showLikeButton: true,
                          additionalImageWidth: 8,
                        ),
                      );
                    },
                    itemCount: state.searchedItems.length,
                  ),
                  if (state.isLoadingMore)
                    Center(
                      child: UiUtils.progress(
                        normalProgressColor: context.color.territoryColor,
                      ),
                    )
                ],
              ),
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget popularItemsWidget() {
    return BlocBuilder<FetchPopularItemsCubit, FetchPopularItemsState>(
      builder: (context, state) {
        if (state is FetchPopularItemsInProgress) {
          return shimmerEffect();
        }

        if (state is FetchPopularItemsFailed) {
          if (state.error is ApiException) {
            if (state.error.error == "no-internet") {
              return SingleChildScrollView(
                child: NoInternet(
                  onRetry: () {
                    context.read<FetchPopularItemsCubit>().fetchPopularItems();
                  },
                ),
              );
            }
          }

          return const SingleChildScrollView(child: SomethingWentWrong());
        }

        if (state is FetchPopularItemsSuccess) {
          if (state.items.isEmpty) {
            return Container();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: sidePadding,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsetsDirectional.only(start: 5.0),
                    child: CustomText(
                      "popularAds".translate(context),
                      color: context.color.textDefaultColor.withOpacity(0.3),
                      fontSize: context.font.normal,
                    )),
                SizedBox(
                  height: 3,
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return Container(
                      height: 8,
                    );
                  },
                  itemBuilder: (context, index) {
                    ItemModel item = state.items[index];

                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.adDetailsScreen,
                          arguments: {
                            'model': item,
                          },
                        );
                      },
                      child: ItemHorizontalCard(
                        item: item,
                        showLikeButton: true,
                        additionalImageWidth: 8,
                      ),
                    );
                  },
                  itemCount: state.items.length,
                ),
                if (state.isLoadingMore)
                  Center(
                    child: UiUtils.progress(
                      normalProgressColor: context.color.territoryColor,
                    ),
                  )
              ],
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget setSearchIcon() {
    return Padding(padding: const EdgeInsets.all(8.0), child: UiUtils.getSvg(AppIcons.search, color: context.color.territoryColor));
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        // Use post-frame callback to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              isFocused = false;
            });
          }
        });
        FocusScope.of(context).unfocus(); //dismiss keyboard
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  Widget buildSearchTextField() {
    return TextFormField(
        autofocus: false,
        controller: searchController,
        decoration: InputDecoration(
          border: InputBorder.none,
          fillColor: Theme.of(context).colorScheme.secondaryColor,
          hintText: "searchHintLbl".translate(context),
          prefixIcon: setSearchIcon(),
          prefixIconConstraints: const BoxConstraints(minHeight: 5, minWidth: 5),
        ),
        enableSuggestions: true,
        onEditingComplete: () {
          // Use post-frame callback to prevent setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                isFocused = false;
              });
            }
          });
          FocusScope.of(context).unfocus();
        },
        onTap: () {
          // Use post-frame callback to prevent setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                isFocused = true;
              });
            }
          });
        });
  }

  @override
  void dispose() {
    searchController.dispose();
    controller.dispose();
    popularController.dispose();
    providerController.dispose();
    super.dispose();
  }

  Widget _noDataFound() => SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: NoDataFound(onTap: refreshData));
}

// Provider card widget to display provider search results
class ProviderCard extends StatelessWidget {
  final UserModel provider;

  const ProviderCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.color.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: provider.profile != null && provider.profile!.isNotEmpty
                ? UiUtils.getImage(
                    provider.profile!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 60,
                    width: 60,
                    color: context.color.territoryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: context.color.territoryColor,
                      size: 30,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Provider details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and type
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        provider.name ?? "Unknown",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.color.textColorDark,
                      ),
                    ),
                    if (provider.isVerified == 1)
                      Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Provider type
                CustomText(
                  provider.categoriesModels?.isEmpty ?? false
                      ? provider.type ?? ''
                      : UiUtils.categoriesListToString(provider.categoriesModels!),
                  fontSize: 14,
                  color: context.color.textDefaultColor.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                // Location
                if (provider.location != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: context.color.territoryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          provider.location.toString(),
                          fontSize: 12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: context.color.textDefaultColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.color.textDefaultColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
