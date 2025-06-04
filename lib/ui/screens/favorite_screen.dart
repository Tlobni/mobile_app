import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/ui/screens/home/widgets/item_container.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/iterable.dart';
import 'package:tlobni/utils/extensions/lib/list.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, required this.showBack});

  final bool showBack;

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return FavoriteScreen(
          showBack: (settings.arguments as Map<String, dynamic>?)?['showBack'] ?? false,
        );
      },
    );
  }

  @override
  FavoriteScreenState createState() => FavoriteScreenState();
}

class FavoriteScreenState extends State<FavoriteScreen> {
  late final ScrollController _controller = ScrollController()
    ..addListener(
      () {
        if (_controller.offset >= _controller.position.maxScrollExtent) {
          if (context.read<FavoriteCubit>().hasMoreFavorite()) {
            setState(() {});
            context.read<FavoriteCubit>().getMoreFavorite();
          }
        }
      },
    );

  PostType _currentType = PostType.service;

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    getFavorite();
  }

  void getFavorite() async {
    context.read<FavoriteCubit>().getFavorite();
  }

/*  void hasMoreFavoriteScrollListener() {
    if (_controller.position.maxScrollExtent == _controller.offset) {
      if (context.read<FavoriteCubit>().hasMoreFavorite()) {
        context.read<FavoriteCubit>().getMoreFavorite();
      }
    }
  }*/

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return RefreshIndicator(
      onRefresh: () async {
        getFavorite();
      },
      color: context.color.territoryColor,
      child: Scaffold(
        appBar: UiUtils.buildAppBar(context, showBackButton: widget.showBack, title: "favorites".translate(context)),
        body: !HiveUtils.isUserAuthenticated()
            ? _buildLoginRequiredMessage()
            : BlocBuilder<FavoriteCubit, FavoriteState>(
                builder: (context, state) {
                  if (state is FavoriteFetchInProgress) {
                    return shimmerEffect();
                  } else if (state is FavoriteFetchSuccess) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                            children: PostType.values
                                .map(
                                  (e) => UnelevatedRegularButton(
                                    onPressed: () => setState(() => _currentType = e),
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IntrinsicWidth(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(20),
                                                child: HeadingText(
                                                  e.toString(),
                                                  fontSize: 18,
                                                  color: _currentType == e ? null : Colors.grey,
                                                  weight: _currentType == e ? FontWeight.w500 : null,
                                                ),
                                              ),
                                              Divider(
                                                height: 3,
                                                thickness: 3,
                                                color: _currentType == e ? kColorSecondaryBeige : Colors.transparent,
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                                .mapExpandedSpaceBetween(0)),
                        const Divider(height: 1, thickness: 0.5),
                        Expanded(
                          child: Builder(builder: (context) {
                            final items = state.favorite.where((e) => e.type == _currentType.name).toList();
                            if (items.isEmpty) {
                              return Center(
                                child: NoDataFound(
                                  onTap: getFavorite,
                                ),
                              );
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Builder(builder: (context) {
                                    final rowCount = (items.length / 2).ceil();
                                    final spacing = 10.0;
                                    return ListView.separated(
                                      separatorBuilder: (_, __) => SizedBox.square(dimension: spacing * 2),
                                      padding: EdgeInsets.all(spacing * 2),
                                      itemCount: rowCount,
                                      itemBuilder: (context, index) {
                                        final start = index * 2;
                                        final end = start + 1;
                                        final itemContainers = [
                                          items[start],
                                          items.getSafe(end),
                                        ].whereNotNull().map((e) => ItemContainer(item: e, small: true));
                                        return IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: itemContainers.length == 1
                                                ? [
                                                    (1, SizedBox()),
                                                    (2, itemContainers.first),
                                                    (1, SizedBox()),
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
                                if (state.isLoadingMore)
                                  UiUtils.progress(
                                    color: context.color.territoryColor,
                                  )
                              ],
                            );
                          }),
                        ),
                      ],
                    );
                  } else if (state is FavoriteFetchFailure) {
                    if (state.errorMessage is ApiException && (state.errorMessage as ApiException).errorMessage == "no-internet") {
                      return NoInternet(
                        onRetry: getFavorite,
                      );
                    }
                    return const SomethingWentWrong();
                  }
                  return Container();
                },
              ),
      ),
    );
  }

  // Widget to show when user is not logged in
  Widget _buildLoginRequiredMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: context.color.territoryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "loginIsRequiredForAccessingThisFeatures".translate(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "tapOnLoginToAuthorize".translate(context),
              style: TextStyle(
                color: context.color.textDefaultColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            UiUtils.buildButton(
              context,
              onPressed: () {
                Navigator.pushNamed(context, Routes.login);
              },
              buttonTitle: "loginNow".translate(context),
              height: 45,
              fontSize: 16,
              width: 200,
            ),
          ],
        ),
      ),
    );
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
              const ClipRRect(
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
}
