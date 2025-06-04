import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/delete_advertisment_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_my_promoted_items_cubit.dart';
import 'package:tlobni/data/cubits/utility/item_edit_global.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/advertisement_repository.dart';
import 'package:tlobni/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class MyAdvertisementScreen extends StatefulWidget {
  const MyAdvertisementScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return BlocProvider(
          create: (context) => FetchMyPromotedItemsCubit(),
          child: const MyAdvertisementScreen(),
        );
      },
    );
  }

  @override
  State<MyAdvertisementScreen> createState() => _MyAdvertisementScreenState();
}

class _MyAdvertisementScreenState extends State<MyAdvertisementScreen> {
  final ScrollController _pageScrollController = ScrollController();

  String? status(int status) => switch (status) {
        0 => "approved".translate(context),
        1 => "pending".translate(context),
        2 => "rejected".translate(context),
        _ => null,
      };

  @override
  void initState() {
    AdHelper.loadInterstitialAd();
    context.read<FetchMyPromotedItemsCubit>().fetchMyPromotedItems();

    _pageScrollController.addListener(_pageScroll);
    super.initState();
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchMyPromotedItemsCubit>().hasMoreData()) {
        context.read<FetchMyPromotedItemsCubit>().fetchMyPromotedItemsMore();
      }
    }
  }

  Color? statusColor(status) => switch (status) {
        0 => Colors.green,
        1 => Colors.purple,
        2 => Colors.red,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(context, showBackButton: true, title: "myFeaturedAds".translate(context)),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<FetchMyPromotedItemsCubit>().fetchMyPromotedItems();

          Future.delayed(
            Duration.zero,
            () {
              ;
            },
          );
        },
        color: context.color.territoryColor,
        child: BlocBuilder<FetchMyPromotedItemsCubit, FetchMyPromotedItemsState>(
          builder: (context, state) {
            if (state is FetchMyPromotedItemsInProgress) {
              return shimmerEffect();
            }
            if (state is FetchMyPromotedItemsFailure) {
              if (state.errorMessage is ApiException) {
                if (state.errorMessage.errorMessage == "no-internet") {
                  return NoInternet(
                    onRetry: () {
                      context.read<FetchMyPromotedItemsCubit>().fetchMyPromotedItems();
                    },
                  );
                }
              }

              return const SomethingWentWrong();
            }
            if (state is FetchMyPromotedItemsSuccess) {
              if (state.itemModel.isEmpty) {
                return NoDataFound(
                  onTap: () {
                    context.read<FetchMyPromotedItemsCubit>().fetchMyPromotedItems();
                    setState(() {});
                  },
                );
              }

              return buildWidget(state);
            }
            return Container();
          },
        ),
      ),
    );
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

  Widget buildWidget(FetchMyPromotedItemsSuccess state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _pageScrollController,
            itemCount: state.itemModel.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              ItemModel item = state.itemModel[index];

              item = context.watch<ItemEditCubit>().get(item);
              return BlocProvider(
                create: (context) => DeleteAdvertisementCubit(AdvertisementRepository()),
                child: InkWell(
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
                  ),
                ),
              );
            },
          ),
        ),
        if (state.isLoadingMore) UiUtils.progress()
      ],
    );
  }
}
