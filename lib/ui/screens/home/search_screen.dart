import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/item/fetch_popular_items_cubit.dart';
import 'package:tlobni/data/cubits/item/search_item_cubit.dart';
import 'package:tlobni/data/cubits/user/search_providers_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/ui/screens/filter/item_listing_filter_screen.dart';
import 'package:tlobni/ui/screens/filter/provider_filter_screen.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/item_container.dart';
import 'package:tlobni/ui/screens/home/widgets/provider_home_screen_container.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/iterable.dart';
import 'package:tlobni/utils/extensions/lib/list.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/ui_utils.dart';

enum ListRowCountType {
  one,
  two;
}

class SearchScreen extends StatefulWidget {
  final ItemFilterModel? initialItemFilter;
  final SearchScreenType screenType;

  const SearchScreen({
    super.key,
    required this.screenType,
    this.initialItemFilter,
  });

  @override
  SearchScreenState createState() => SearchScreenState();

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
}

class SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<SearchScreen> {
  static TextEditingController searchController = TextEditingController();
  bool isFocused = false;
  String previousSearchQuery = "";
  final ScrollController scrollController = ScrollController();
  Timer? _searchDelay;
  late ItemFilterModel? filter = widget.initialItemFilter;
  List<CategoryModel> categoryList = [];

  Color get grayBorderColor => Color(0xffeeeeee);

  bool get isProviderSearch => widget.screenType == SearchScreenType.provider; //filter != null && filter!.userType != null;

  @override
  bool get wantKeepAlive => true;

  PreferredSizeWidget appBarWidget() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: context.color.backgroundColor),
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
              padding: EdgeInsetsDirectional.only(start: 18.0, top: 12, bottom: 12),
              child: Directionality(
                  textDirection: Directionality.of(context),
                  child: RotatedBox(
                    quarterTurns: Directionality.of(context) == TextDirection.rtl ? 2 : -4,
                    child: UiUtils.getSvg(AppIcons.arrowLeft, fit: BoxFit.none, color: context.color.textDefaultColor),
                  ))),
        ),
      ),
      elevation: 0,
      backgroundColor: context.color.backgroundColor,
    );
  }

  Widget bodyData() => Column(
        children: [
          divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: buildSearchTextField(),
          ),
          divider(),
          Expanded(child: bodyListings()),
        ],
      );

  Widget bodyListings() {
    return Builder(builder: (context) {
      if (isProviderSearch) {
        return providersItemsWidget();
      } else {
        return searchItemsWidget();
      }
    });
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

  // To determine if we're showing providers or services
  //to store selected filter categories
  Widget buildSearchTextField() {
    final style = context.textTheme.bodyMedium;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: grayBorderColor),
    );
    final fillColor = Color(0xfff9f9f9);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextFormField(
              autofocus: false,
              controller: searchController,
              style: style,
              decoration: InputDecoration(
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                fillColor: fillColor,
                filled: true,
                hintText: isProviderSearch ? 'Search providers...' : 'Search listings...',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.search, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints: const BoxConstraints(),
                hintStyle: style?.copyWith(color: Color(0xffacacac)),
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
              },
            ),
          ),
          const SizedBox(width: 10),
          AspectRatio(
            aspectRatio: 1,
            child: UnelevatedRegularButton(
              onPressed: _goToFilter,
              color: fillColor,
              shape: RoundedRectangleBorder(borderRadius: border.borderRadius, side: border.borderSide),
              child: Icon(Icons.filter_list, size: 25),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget divider() => Divider(height: 1.5, color: grayBorderColor, thickness: 1);

  User _fromUserModel(UserModel provider) => User(
        id: provider.id,
        name: provider.name,
        email: provider.email,
        mobile: provider.mobile,
        categories: provider.categoriesModels?.map((e) => e.name).whereNotNull().toList(),
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
        averageRating: provider.averageRating,
        totalReviews: provider.totalReviews,
        isFeatured: provider.isFeatured,
      );

  @override
  void initState() {
    super.initState();

    print("DEBUG: Search screen initialized with filter: ${filter?.toJson()}");

    context.read<FetchPopularItemsCubit>().fetchPopularItems();
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    scrollController.addListener(pageScrollListen);

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
      refreshData();
    });
    // }
  }

  ///This will call api after some delay
  void itemSearch() {
    if (previousSearchQuery != searchController.text) {
      refreshData();
      previousSearchQuery = searchController.text;
      setState(() {});
    }
  }

  void pageScrollListen() {
    if (scrollController.isEndReached()) {
      switch (widget.screenType) {
        case SearchScreenType.provider:
          if (context.read<SearchProvidersCubit>().hasMoreData()) {
            context.read<SearchProvidersCubit>().fetchMoreProviders(searchController.text, Constant.itemFilter);
          }
          break;
        case SearchScreenType.itemListing:
          if (context.read<SearchItemCubit>().hasMoreData()) {
            context.read<SearchItemCubit>().fetchMoreSearchData(searchController.text, Constant.itemFilter);
          }
          break;
      }
    }
  }

  // Widget to show provider search results
  Widget providersItemsWidget() {
    return BlocBuilder<SearchProvidersCubit, SearchProvidersState>(
      builder: (context, state) {
        return _listBody(
          sortItems: SearchProviderSortBy.values
              .map((e) => (switch (e) {  SearchProviderSortBy.rating => 'Rating', SearchProviderSortBy.newest => 'Newest'}, e))
              .toList(),
          selectedItem: filter?.providerSortBy,
          onSortByPressed: (e) {
            filter =
                (filter ?? ItemFilterModel.createEmpty()).copyWith(providerSortBy: e, resetProviderSortBy: e == filter?.providerSortBy);
            refreshData();
            setState(() {});
          },
          isLoading: state is SearchProvidersFetchProgress,
          isError: state is SearchProvidersFailure,
          isInternetError: state is SearchProvidersFailure && state.errorMessage is ApiException && state.errorMessage == 'no-internet',
          isLoadingMore: state is SearchProvidersSuccess && state.isLoadingMore,
          totalResults: state is SearchProvidersSuccess ? state.total : 0,
          rowCountType: ListRowCountType.one,
          spacing: 10,
          items: state is SearchProvidersSuccess ? state.searchedProviders : [],
          itemBuilder: (item) {
            final user = _fromUserModel(item);
            return ProviderHomeScreenContainer(user: user);
          },
        );
      },
    );
  }

  void refreshData() {
    switch (widget.screenType) {
      case SearchScreenType.provider:
        context.read<SearchProvidersCubit>().searchProviders(searchController.text, page: 1, filter: filter);
        break;
      case SearchScreenType.itemListing:
        context.read<SearchItemCubit>().searchItem(searchController.text, page: 1, filter: filter);
        break;
    }
  }

  //This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  //this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
    setState(() {});
  }

  Widget searchItemsWidget() {
    return BlocBuilder<SearchItemCubit, SearchItemState>(builder: (context, state) {
      return _listBody(
        sortItems: SearchItemSortBy.values
            .map((e) => (
                  switch (e) {
                    SearchItemSortBy.newest => 'Newest',
                    SearchItemSortBy.priceLowToHigh => 'Price Low to High',
                    SearchItemSortBy.priceHighToLow => 'Price High to Low',
                    SearchItemSortBy.topRated => 'Top Rated',
                  },
                  e
                ))
            .toList(),
        selectedItem: filter?.itemSortBy,
        onSortByPressed: (e) {
          filter = (filter ?? ItemFilterModel.createEmpty()).copyWith(itemSortBy: e, resetItemSortBy: e == filter?.itemSortBy);
          refreshData();
          setState(() {});
        },
        isLoading: state is SearchItemProgress || state is SearchItemFetchProgress,
        isError: state is SearchItemFailure,
        isInternetError: state is SearchItemFailure && state.errorMessage is ApiException && state.errorMessage == 'no-internet',
        isLoadingMore: state is SearchItemSuccess && state.isLoadingMore,
        totalResults: state is SearchItemSuccess ? state.total : 0,
        rowCountType: ListRowCountType.two,
        spacing: 10,
        items: state is SearchItemSuccess ? state.searchedItems : [],
        itemBuilder: (item) => ItemContainer(small: true, item: item),
      );
    });
  }

  void _goToFilter() async {
    final filter = await Navigator.push(
      context,
      ModalBottomSheetRoute(
        constraints: BoxConstraints(
          minHeight: context.screenHeight * 0.85,
          maxHeight: context.screenHeight * 0.9,
        ),
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: context.screenHeight * 0.9,
          child: switch (widget.screenType) {
            SearchScreenType.provider => ProviderFilterScreen(initialFilter: this.filter),
            SearchScreenType.itemListing => ItemListingFilterScreen(initialFilter: this.filter),
          },
        ),
      ),
    );
    if (filter == null) return;
    this.filter = filter;
    refreshData();
  }

  Widget _listBody<SORT, ITEM>({
    required List<(String, SORT)> sortItems,
    required SORT? selectedItem,
    required void Function(SORT item) onSortByPressed,
    required bool isLoading,
    required bool isError,
    required bool isInternetError,
    required bool isLoadingMore,
    required int totalResults,
    required ListRowCountType rowCountType,
    required double spacing,
    required List<ITEM> items,
    required Widget Function(ITEM item) itemBuilder,
  }) =>
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15.0),
            child: _sortBy(sortItems, selectedItem, onSortByPressed),
          ),
          divider(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) return _shimmerEffect(rowCountType);

                if (isError) {
                  return SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Builder(builder: (context) {
                      if (isInternetError) {
                        return NoInternet(onRetry: refreshData);
                      }
                      return Center(child: const SomethingWentWrong());
                    }),
                  );
                }

                if (items.isEmpty) return _noDataFound();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: sidePadding,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 3),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: DescriptionText('${totalResults} results found'),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: Builder(builder: (context) {
                          final rowCount = rowCountType == ListRowCountType.one ? items.length : (items.length / 2).ceil();
                          return ListView.separated(
                            controller: scrollController,
                            separatorBuilder: (_, __) => SizedBox.square(dimension: spacing * 2),
                            padding: EdgeInsets.all(spacing),
                            itemCount: rowCount,
                            itemBuilder: (context, index) {
                              final start = rowCountType == ListRowCountType.one ? index : index * 2;
                              final end = start + 1;
                              final itemContainers = [
                                items[start],
                                if (rowCountType == ListRowCountType.two) items.getSafe(end),
                              ].whereNotNull().map(itemBuilder);
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: itemContainers.length == 1
                                      ? [
                                          if (rowCountType == ListRowCountType.two) (1, SizedBox()),
                                          (2, itemContainers.first),
                                          if (rowCountType == ListRowCountType.two) (1, SizedBox()),
                                        ].mapExpandedSpaceBetween(spacing / 2)
                                      : [
                                          (1, itemContainers.first),
                                          (1, itemContainers.last),
                                        ].mapExpandedSpaceBetween(spacing),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                      if (isLoadingMore)
                        Center(
                          child: UiUtils.progress(
                            color: context.color.territoryColor,
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _noDataFound() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: NoDataFound(onTap: refreshData),
            ),
          ),
        ],
      );

  ListView _shimmerEffect(ListRowCountType rowCountType) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return switch (rowCountType) {
          // TODO: Handle this case.
          ListRowCountType.one => Container(
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
                          const SizedBox(height: 10),
                          CustomShimmer(height: 10, width: c.maxWidth - 50),
                          const SizedBox(height: 10),
                          const CustomShimmer(height: 10),
                          const SizedBox(height: 10),
                          CustomShimmer(height: 10, width: c.maxWidth / 1.2),
                          const SizedBox(height: 10),
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
            ),
          ListRowCountType.two => Row(
              children: List.generate(2, (_) => CustomShimmer(height: 300)).mapExpandedSpaceBetween(10),
            ),
        };
      },
    );
  }

  Widget _sortBy<T>(
    List<(String, T)> sortByItems,
    T? selectedItem,
    void Function(T item) onSortByPressed,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DescriptionText('Sort by:'),
              SizedBox(width: 5),
              Expanded(
                child: IntrinsicHeight(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 10,
                      children: [
                        for (int index = 0; index < sortByItems.length; index++)
                          Builder(builder: (context) {
                            final (label, item) = sortByItems[index];
                            final isSelected = selectedItem == item;
                            return UnelevatedRegularButton(
                              onPressed: () => onSortByPressed(item),
                              color: isSelected ? context.color.primary : Colors.grey.shade100,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isSelected ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
                              ),
                              child: SmallText(
                                label,
                                color: isSelected ? context.color.onPrimary : Colors.grey.shade600,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      );
}

enum SearchScreenType { provider, itemListing }
