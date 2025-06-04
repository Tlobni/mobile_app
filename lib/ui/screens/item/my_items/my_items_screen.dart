import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:tlobni/ui/screens/item/my_items/my_item_tab_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

enum ItemsScreenTab {
  allListings,
  featured,
  live,
  underReview,
  rejected;

  String get status => switch (this) {
        allListings => '',
        featured => 'featured',
        live => 'approved',
        underReview => 'underReview',
        rejected => 'rejected',
      };

  String title(BuildContext context) => switch (this) {
        allListings => 'allAds'.translate(context),
        featured => 'featured'.translate(context),
        live => 'live'.translate(context),
        underReview => 'underReview'.translate(context),
        rejected => 'rejected'.translate(context),
      };
}

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => MyItemState();

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const ItemsScreen(),
    );
  }
}

class MyItemState extends State<ItemsScreen> with TickerProviderStateMixin {
  ItemsScreenTab _currentTab = ItemsScreenTab.allListings;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: UiUtils.buildAppBar(
          context,
          title: "myAds".translate(context),
          // bottomHeight: 49,
          bottomHeight: 49,

          bottom: [
            SizedBox(
              width: context.screenWidth,
              height: 45,
              child: Builder(builder: (context) {
                final values = ItemsScreenTab.values;
                return ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 5, 18, 2),
                  scrollDirection: Axis.horizontal,
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final value = values[index];
                    return customTab(
                      context,
                      isSelected: (_currentTab == value),
                      onTap: () {
                        if (context.read<FetchMyItemsCubit>().state is FetchMyItemsInProgress) return;
                        setState(() => _currentTab = value);
                        _refreshDataForTab();
                      },
                      name: value.title(context),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        body: MyItemTab(getItemsWithStatus: _currentTab.status),
      ),
    );
  }

  Widget customTab(
    BuildContext context, {
    required bool isSelected,
    required String name,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 110,
        ),
        height: 40,
        decoration: BoxDecoration(
            color: (isSelected ? (context.color.territoryColor) : Colors.transparent),
            border: Border.all(
              color: isSelected ? context.color.territoryColor : context.color.textLightColor,
            ),
            borderRadius: BorderRadius.circular(11)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HeadingText(
              name,
              color: isSelected ? context.color.onPrimary : null,
              fontSize: context.font.large,
            ),
          ),
        ),
      ),
    );
  }

  void _refreshDataForTab() {
    context.read<FetchMyItemsCubit>().fetchMyItems(getItemsWithStatus: _currentTab.status);
  }
}
