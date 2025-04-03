import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/category_home_card.dart';
import 'package:tlobni/ui/screens/main_activity.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryWidgetHome extends StatelessWidget {
  const CategoryWidgetHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
      builder: (context, state) {
        if (state is FetchCategorySuccess) {
          // Filter categories to only show service_experience type
          final serviceCategories = state.categories
              .where(
                  (category) => category.type == CategoryType.serviceExperience)
              .toList();

          if (serviceCategories.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sidePadding),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: context.font.large,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: context.screenWidth,
                    height: 103,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                      ),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        if (serviceCategories.length > 10 &&
                            index == serviceCategories.length) {
                          return moreCategory(context);
                        } else {
                          return CategoryHomeCard(
                            title: serviceCategories[index].name!,
                            url: serviceCategories[index].url!,
                            onTap: () {
                              if (serviceCategories[index].children != null &&
                                  serviceCategories[index]
                                      .children!
                                      .isNotEmpty) {
                                Navigator.pushNamed(
                                    context, Routes.subCategoryScreen,
                                    arguments: {
                                      "categoryList":
                                          serviceCategories[index].children,
                                      "catName": serviceCategories[index].name,
                                      "catId": serviceCategories[index].id,
                                      "categoryIds": [
                                        serviceCategories[index].id.toString()
                                      ]
                                    });
                              } else {
                                Navigator.pushNamed(context, Routes.itemsList,
                                    arguments: {
                                      'catID': serviceCategories[index]
                                          .id
                                          .toString(),
                                      'catName': serviceCategories[index].name,
                                      "categoryIds": [
                                        serviceCategories[index].id.toString()
                                      ]
                                    });
                              }
                            },
                          );
                        }
                      },
                      itemCount: serviceCategories.length > 10
                          ? serviceCategories.length + 1
                          : serviceCategories.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          width: 12,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(50.0),
              child: NoDataFound(
                onTap: () {},
              ),
            );
          }
        }
        return Container();
      },
    );
  }

  Widget moreCategory(BuildContext context) {
    // Get the current category type from the state
    CategoryType? currentType;
    if (context.read<FetchCategoryState>() is FetchCategorySuccess) {
      currentType = (context.read<FetchCategoryState>() as FetchCategorySuccess)
          .categoryType;
    }

    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, Routes.categories, arguments: {
            "from": Routes.home,
            "categoryType": CategoryType
                .serviceExperience, // Always pass service_experience type
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
                border: Border.all(
                    color: context.color.borderColor.darken(60), width: 1),
                color: context.color.secondaryColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: UiUtils.getSvg(AppIcons.more,
                      color: context.color.territoryColor),
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
}
