import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/category_home_card.dart';
import 'package:tlobni/ui/screens/home/widgets/home_section.dart';
import 'package:tlobni/ui/screens/home/widgets/home_shimmer_effect.dart';
import 'package:tlobni/ui/screens/main_activity.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/iterable.dart';
import 'package:tlobni/utils/ui_utils.dart';

class CategoryWidgetHome extends StatelessWidget {
  const CategoryWidgetHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
      builder: (context, state) => HomeSection(
        title: 'Browse Categories',
        onViewAll: () {},
        shimmerEffect: HomeShimmerEffect(
          height: 160,
          width: 160,
          itemCount: 5,
        ),
        isLoading: state is FetchCategoryInProgress,
        error: state is FetchCategoryFailure ? 'Failed to load categories: ${state.errorMessage}' : null,
        isEmpty: state is FetchCategorySuccess && state.categories.isEmpty,
        child: Builder(
          builder: (context) {
            if (state is FetchCategorySuccess) {
              // Filter categories to only show service_experience type
              final serviceCategories = state.categories.where((category) => category.type == CategoryType.serviceExperience).toList();
              return SizedBox(
                width: context.screenWidth,
                height: 160,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: sidePadding,
                  ),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    if (serviceCategories.length > 10 && index == serviceCategories.length) {
                      return moreCategory(context);
                    } else {
                      return CategoryHomeCard(
                        title: serviceCategories[index].name!,
                        url: serviceCategories[index].url!,
                        onTap: () => _onCategoryTapped(context, serviceCategories[index]),
                      );
                    }
                  },
                  itemCount: serviceCategories.length > 10 ? serviceCategories.length + 1 : serviceCategories.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      width: 12,
                    );
                  },
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget moreCategory(BuildContext context) {
    // Get the current category type from the state
    CategoryType? currentType;
    if (context.read<FetchCategoryState>() is FetchCategorySuccess) {
      currentType = (context.read<FetchCategoryState>() as FetchCategorySuccess).categoryType;
    }

    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, Routes.categories, arguments: {
            "from": Routes.home,
            "categoryType": CategoryType.serviceExperience, // Always pass service_experience type
          }).then(
            (dynamic value) {
              if (value != null) {
                selectedCategory = value;
                //setState(() {});
              }
            },
          );
        },
        child: Column(
          children: [
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.color.borderColor.darken(60), width: 1),
                color: context.color.secondaryColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: UiUtils.getSvg(AppIcons.more, color: context.color.territoryColor),
                ),
              ),
            ),
            Expanded(
                child: CustomText(
              "more".translate(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              color: context.color.textDefaultColor,
            ))
          ],
        ),
      ),
    );
  }

  void _onCategoryTapped(BuildContext context, CategoryModel serviceCategory) {
    final categories = [serviceCategory, ...?serviceCategory.children];
    Navigator.pushNamed(context, Routes.searchScreenRoute, arguments: {
      'autoFocus': true,
      'screenType': SearchScreenType.itemListing,
      'itemFilter': ItemFilterModel.createEmpty().copyWith(
        categoryId: categories.map((e) => e.id).whereNotNull().join(','),
        categories: categories,
      ),
    });

    // if (serviceCategory.children != null && serviceCategory.children!.isNotEmpty) {
    //   Navigator.pushNamed(context, Routes.subCategoryScreen, arguments: {
    //     "categoryList": serviceCategory.children,
    //     "catName": serviceCategory.name,
    //     "catId": serviceCategory.id,
    //     "categoryIds": [serviceCategory.id.toString()]
    //   });
    // } else {
    //   Navigator.pushNamed(context, Routes.itemsList, arguments: {
    //     'catID': serviceCategory.id.toString(),
    //     'catName': serviceCategory.name,
    //     "categoryIds": [serviceCategory.id.toString()]
    //   });
    // }
  }
}
