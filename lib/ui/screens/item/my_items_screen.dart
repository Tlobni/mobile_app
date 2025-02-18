import 'package:eClassify/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:eClassify/ui/screens/item/my_item_tab_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  int offset = 0, total = 0;
  int selectTab = 0;
  final PageController _pageController = PageController();
  List<Map> sections = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    sections = [
      {
        "title": "allAds".translate(context),
        "status": "",
      },
      {"title": "featured".translate(context), "status": "featured"},
      {
        "title": "live".translate(context),
        "status": "approved",
      },
      {
        "title": "deactivate".translate(context),
        "status": "inactive",
      },
      {
        "title": "underReview".translate(context),
        "status": "review",
      },
      {
        "title": "soldOut".translate(context),
        "status": "sold out",
      },
      {
        "title": "rejected".translate(context),
        "status": "rejected",
      },
    ];
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
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
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(18, 5, 18, 2),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  Map section = sections[index];
                  return customTab(
                    context,
                    isSelected: (selectTab == index),
                    onTap: () {
                      selectTab = index;
                      //itemScreenCurrentPage = index;
                      setState(() {});
                      _pageController.jumpToPage(index);
                    },
                    name: section['title'],
                    onDoubleTap: () {},
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    width: 8,
                  );
                },
                itemCount: sections.length,
              ),
            ),
          ],
        ),
        body: ScrollConfiguration(
          behavior: RemoveGlow(),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              //itemScreenCurrentPage = value;
              selectTab = value;
              setState(() {});
            },
            controller: _pageController,
            children: List.generate(sections.length, (index) {
              Map section = sections[index];

              ///Here we pass both but logic will be in the cubit
              return BlocProvider(
                create: (context) => FetchMyItemsCubit(),
                child: Builder(builder: (context) {
                  return MyItemTab(
                    //getActiveItems: section['active'],
                    getItemsWithStatus: section['status'],
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget customTab(
    BuildContext context, {
    required bool isSelected,
    required String name,
    required Function() onTap,
    required Function() onDoubleTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 110,
        ),
        height: 40,
        decoration: BoxDecoration(
            color: (isSelected
                ? (context.color.territoryColor)
                : Colors.transparent),
            border: Border.all(
              color: isSelected
                  ? context.color.territoryColor
                  : context.color.textLightColor,
            ),
            borderRadius: BorderRadius.circular(11)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomText(
              name,
              color: isSelected
                  ? context.color.buttonColor
                  : context.color.textColorDark,
              fontSize: context.font.large,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
