import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/promoted_widget.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

Map<String, FetchMyItemsCubit> myAdsCubitReference = {};

class MyItemTab extends StatefulWidget {
  //final bool? getActiveItems;
  final String? getItemsWithStatus;

  const MyItemTab({super.key, this.getItemsWithStatus});

  @override
  CloudState<MyItemTab> createState() => _MyItemTabState();
}

class _MyItemTabState extends CloudState<MyItemTab> {
  late final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    if (HiveUtils.isUserAuthenticated()) {
      context.read<FetchMyItemsCubit>().fetchMyItems(
            getItemsWithStatus: widget.getItemsWithStatus,
          );
      _pageScrollController.addListener(_pageScroll);
      setReferenceOfCubit();
    }

    super.initState();
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchMyItemsCubit>().hasMoreData()) {
        context
            .read<FetchMyItemsCubit>()
            .fetchMyMoreItems(getItemsWithStatus: widget.getItemsWithStatus);
      }
    }
  }

  void setReferenceOfCubit() {
    myAdsCubitReference[widget.getItemsWithStatus!] =
        context.read<FetchMyItemsCubit>();
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

  Widget showStatus(ItemModel model) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      //margin: EdgeInsetsDirectional.only(end: 4, start: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _getStatusColor(model.status),
      ),
      child: CustomText(
        _getStatusCustomText(model.status)!,
        fontSize: context.font.small,
        color: _getStatusTextColor(model.status),
      ),
    );
  }

  String? _getStatusCustomText(String? status) {
    switch (status) {
      case "review":
        return "underReview".translate(context);
      case "active":
        return "active".translate(context);
      case "approved":
        return "approved".translate(context);
      case "inactive":
        return "deactivate".translate(context);
      case "sold out":
        return "soldOut".translate(context);
      case "rejected":
        return "rejected".translate(context);
      case "expired":
        return "expired".translate(context);
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "review":
        return pendingButtonColor.withValues(alpha: 0.1);
      case "active" || "approved":
        return activateButtonColor.withValues(alpha: 0.1);
      case "inactive":
        return deactivateButtonColor.withValues(alpha: 0.1);
      case "sold out":
        return soldOutButtonColor.withValues(alpha: 0.1);
      case "rejected":
        return deactivateButtonColor.withValues(alpha: 0.1);
      case "expired":
        return deactivateButtonColor.withValues(alpha: 0.1);
      default:
        return context.color.territoryColor.withValues(alpha: 0.1);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case "review":
        return pendingButtonColor;
      case "active" || "approved":
        return activateButtonColor;
      case "inactive":
        return deactivateButtonColor;
      case "sold out":
        return soldOutButtonColor;
      case "rejected":
        return deactivateButtonColor;
      case "expired":
        return deactivateButtonColor;
      default:
        return context.color.territoryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FetchMyItemsCubit>().fetchMyItems(
              getItemsWithStatus: widget.getItemsWithStatus,
            );

        setReferenceOfCubit();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<FetchMyItemsCubit, FetchMyItemsState>(
        builder: (context, state) {
          if (state is FetchMyItemsInProgress) {
            return shimmerEffect();
          }

          if (state is FetchMyItemsFailed) {
            if (state.error is ApiException) {
              if (state.error.error == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<FetchMyItemsCubit>().fetchMyItems(
                        getItemsWithStatus: widget.getItemsWithStatus);
                  },
                );
              }
            }

            return const SomethingWentWrong();
          }

          if (state is FetchMyItemsSuccess) {
            if (state.items.isEmpty) {
              return NoDataFound(
                mainMessage: "noAdsFound".translate(context),
                subMessage: "noAdsAvailable".translate(context),
                onTap: () {
                  context.read<FetchMyItemsCubit>().fetchMyItems(
                      getItemsWithStatus: widget.getItemsWithStatus);
                },
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    controller: _pageScrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 8,
                    ),
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 8,
                      );
                    },
                    itemBuilder: (context, index) {
                      ItemModel item = state.items[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.adDetailsScreen,
                              arguments: {
                                "model": item,
                              }).then((value) {
                            if (value == "refresh") {
                              context.read<FetchMyItemsCubit>().fetchMyItems(
                                    getItemsWithStatus:
                                        widget.getItemsWithStatus,
                                  );

                              setReferenceOfCubit();
                            }
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: 130,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: item.status == "inactive"
                                    ? context.color.deactivateColor.brighten(70)
                                    : context.color.secondaryColor,
                                border: Border.all(
                                    color: context.color.borderColor.darken(30),
                                    width: 1)),
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: SizedBox(
                                        width: 116,
                                        height: double.infinity,
                                        child: UiUtils.getImage(
                                            item.image ?? "",
                                            height: double.infinity,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    if (item.isFeature ?? false)
                                      const PositionedDirectional(
                                          start: 5,
                                          top: 5,
                                          child: PromotedCard(
                                              type: PromoteCardType.icon))
                                  ],
                                ),
                                Expanded(
                                  flex: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 15),
                                    child: Column(
                                      //mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomText(
                                              (item.price ?? 0.0)
                                                  .currencyFormat,
                                              color:
                                                  context.color.territoryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            Spacer(),
                                            showStatus(item)
                                          ],
                                        ),
                                        //SizedBox(height: 7,),
                                        CustomText(
                                          item.name ?? "",
                                          maxLines: 2,
                                          firstUpperCaseWidget: true,
                                        ),
                                        //SizedBox(height: 12,),
                                        Row(
                                          //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              flex: 1,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(AppIcons.eye,
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter: ColorFilter.mode(
                                                          context.color
                                                              .textDefaultColor,
                                                          BlendMode.srcIn)),
                                                  const SizedBox(
                                                    width: 4,
                                                  ),
                                                  CustomText(
                                                    "${"views".translate(context)}:${item.views}",
                                                    fontSize:
                                                        context.font.small,
                                                    color: context
                                                        .color.textColorDark
                                                        .withValues(alpha: 0.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Flexible(
                                              flex: 1,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                      AppIcons.heart,
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter: ColorFilter.mode(
                                                          context.color
                                                              .textDefaultColor,
                                                          BlendMode.srcIn)),
                                                  const SizedBox(
                                                    width: 4,
                                                  ),
                                                  CustomText(
                                                    "${"like".translate(context)}:${item.totalLikes.toString()}",
                                                    fontSize:
                                                        context.font.small,
                                                    color: context
                                                        .color.textColorDark
                                                        .withValues(alpha: 0.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: state.items.length,
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress()
              ],
            );
          }
          return Container();
        },
      ),
    );
  }
}
