import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/model/home/home_screen_section.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/favourites_repository.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:eClassify/ui/screens/widgets/promoted_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSectionsAdapter extends StatelessWidget {
  final HomeScreenSection section;

  const HomeSectionsAdapter({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    if (section.style == "style_1") {
      return section.sectionData!.isNotEmpty
          ? Column(
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                        arguments: {
                          "title": section.title,
                          "sectionId": section.sectionId,
                        });
                  },
                  // section: section,
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.5,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) => const SizedBox(
                    width: 14,
                  ),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return ItemCard(
                      item: item,
                      bigCard: true,
                    );
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_2") {
      return section.sectionData!.isNotEmpty
          ? Column(
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                        arguments: {
                          "title": section.title,
                          "sectionId": section.sectionId,
                        });
                  },
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.5,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) => const SizedBox(
                    width: 14,
                  ),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return ItemCard(
                      item: item,
                      width: 144,
                    );
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_3") {
      return section.sectionData!.isNotEmpty
          ? Column(
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                        arguments: {
                          "title": section.title,
                          "sectionId": section.sectionId,
                        });
                  },
                ),
                GridListAdapter(
                  type: ListUiType.Grid,
                  crossAxisCount: 2,
                  height: MediaQuery.of(context).size.height / 3.5,
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return ItemCard(
                      item: item,
                      width: 192,
                    );
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_4") {
      return section.sectionData!.isNotEmpty
          ? Column(
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(context, Routes.sectionWiseItemsScreen,
                        arguments: {
                          "title": section.title,
                          "sectionId": section.sectionId,
                        });
                  },
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.5,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) => const SizedBox(
                    width: 14,
                  ),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return ItemCard(
                      item: item,
                      width: 192,
                    );
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else {
      return Container();
    }
  }
}

class TitleHeader extends StatelessWidget {
  final String title;
  final Function() onTap;
  final bool? hideSeeAll;

  const TitleHeader({
    super.key,
    required this.title,
    required this.onTap,
    this.hideSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          top: 18, bottom: 12, start: sidePadding, end: sidePadding),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: CustomText(
                title,
                fontSize: context.font.large,
                fontWeight: FontWeight.w600,
                maxLines: 1,
              )),
          const Spacer(),
          if (!(hideSeeAll ?? false))
            GestureDetector(
                onTap: onTap,
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2.2),
                    child: CustomText(
                      "seeAll".translate(context),
                      fontSize: context.font.smaller + 1,
                    )))
        ],
      ),
    );
  }
}

class ItemCard extends StatefulWidget {
  final double? width;
  final bool? bigCard;
  final ItemModel? item;

  const ItemCard({
    super.key,
    required this.item,
    this.width,
    this.bigCard,
  });

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  double likeButtonSize = 32;
  double imageHeight = 147;
  // Use nullable bool to represent initial state

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
          "model": widget.item,
        });
      },
      child: Container(
        width: widget.width ?? 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: context.color.borderColor.darken(30),
            width: 1,
          ),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: UiUtils.getImage(
                        widget.item?.image ?? "",
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (widget.item?.isFeature ?? false)
                      const PositionedDirectional(
                          start: 10,
                          top: 5,
                          child: PromotedCard(type: PromoteCardType.icon)),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomText(
                              (widget.item?.price ?? 0.0).currencyFormat,
                              fontWeight: FontWeight.bold,
                              color: context.color.territoryColor,
                              fontSize: context.font.large,
                            ),
                            if (widget.item?.priceType != null)
                              Row(
                                children: [
                                  SizedBox(width: 4),
                                  CustomText(
                                    "/ ${_formatPriceType(widget.item?.priceType)}",
                                    fontSize: context.font.small,
                                    color: context.color.textLightColor,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        CustomText(
                          widget.item!.name!,
                          fontSize: context.font.large,
                          maxLines: 1,
                          firstUpperCaseWidget: true,
                        ),
                        if (widget.item?.address != "")
                          Row(
                            children: [
                              UiUtils.getSvg(
                                AppIcons.location,
                                width: widget.bigCard == true ? 10 : 8,
                                height: widget.bigCard == true ? 13 : 11,
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 3.0),
                                  child: CustomText(
                                    widget.item?.address ?? "",
                                    fontSize: (widget.bigCard == true)
                                        ? context.font.small
                                        : context.font.smaller,
                                    color: context.color.textDefaultColor
                                        .withOpacity(0.3),
                                    maxLines: 1,
                                  ),
                                ),
                              )
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            favButton(),
          ],
        ),
      ),
    );
  }

  Widget favButton() {
    bool isLike =
        context.read<FavoriteCubit>().isItemFavorite(widget.item!.id!);

    return BlocProvider(
        create: (context) => UpdateFavoriteCubit(FavoriteRepository()),
        child: BlocConsumer<FavoriteCubit, FavoriteState>(
            bloc: context.read<FavoriteCubit>(),
            listener: ((context, state) {
              if (state is FavoriteFetchSuccess) {
                isLike = context
                    .read<FavoriteCubit>()
                    .isItemFavorite(widget.item!.id!);
              }
            }),
            builder: (context, likeAndDislikeState) {
              return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
                  bloc: context.read<UpdateFavoriteCubit>(),
                  listener: ((context, state) {
                    if (state is UpdateFavoriteSuccess) {
                      if (state.wasProcess) {
                        context
                            .read<FavoriteCubit>()
                            .addFavoriteitem(state.item);
                      } else {
                        context
                            .read<FavoriteCubit>()
                            .removeFavoriteItem(state.item);
                      }
                    }
                  }),
                  builder: (context, state) {
                    return PositionedDirectional(
                      top: imageHeight - (likeButtonSize / 2) - 2,
                      end: 16,
                      child: InkWell(
                        onTap: () {
                          UiUtils.checkUser(
                              onNotGuest: () {
                                context
                                    .read<UpdateFavoriteCubit>()
                                    .setFavoriteItem(
                                      item: widget.item!,
                                      type: isLike ? 0 : 1,
                                    );
                              },
                              context: context);
                        },
                        child: Container(
                          width: likeButtonSize,
                          height: likeButtonSize,
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            shape: BoxShape.circle,
                            boxShadow:
                                context.watch<AppThemeCubit>().state.appTheme ==
                                        AppTheme.dark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.grey[300]!,
                                          offset: const Offset(0, 2),
                                          spreadRadius: 2,
                                          blurRadius: 4,
                                        ),
                                      ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.none,
                            child: state is UpdateFavoriteInProgress
                                ? Center(child: UiUtils.progress())
                                : UiUtils.getSvg(
                                    isLike ? AppIcons.like_fill : AppIcons.like,
                                    width: 22,
                                    height: 22,
                                    color: context.color.territoryColor,
                                  ),
                          ),
                        ),
                      ),
                    );
                  });
            }));
  }

  String _formatPriceType(String? priceType) {
    if (priceType == null) return "";

    switch (priceType) {
      case "session":
        return "session";
      case "consultation":
        return "consultation";
      case "hour":
        return "hour";
      case "class":
        return "class";
      case "fixed_fee":
        return "fixed fee";
      default:
        return priceType;
    }
  }
}
