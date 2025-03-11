import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/category/fetch_category_cubit.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/widgets/category.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_silver_grid_delegate.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryList extends StatefulWidget {
  final String? from;
  final CategoryType? categoryType;

  const CategoryList({super.key, this.from, this.categoryType});

  @override
  State<CategoryList> createState() => _CategoryListState();

  static Route route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => CategoryList(
        from: args?['from'],
        categoryType: args?['categoryType'],
      ),
    );
  }
}

class _CategoryListState extends State<CategoryList>
    with TickerProviderStateMixin {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    _pageScrollController.addListener(() {
      if (_pageScrollController.isEndReached()) {
        if (context.read<FetchCategoryCubit>().hasMoreData()) {
          context.read<FetchCategoryCubit>().fetchCategoriesMore();
        }
      }
    });

    if (context.read<FetchCategoryState>() is! FetchCategorySuccess ||
        (context.read<FetchCategoryState>() is FetchCategorySuccess &&
            (context.read<FetchCategoryState>() as FetchCategorySuccess)
                    .categoryType !=
                widget.categoryType)) {
      context
          .read<FetchCategoryCubit>()
          .fetchCategories(type: widget.categoryType);
    }

    super.initState();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
          title: "categoriesLbl".translate(context),
        ),
        body: BlocConsumer<FetchCategoryCubit, FetchCategoryState>(
          listener: ((context, state) {
            // if (state is FetchCategorySuccess) {}
          }),
          builder: (context, state) {
            if (state is FetchCategoryInProgress) {
              return UiUtils.progress();
            }
            if (state is FetchCategorySuccess) {
              // Filter categories to only show service_experience type
              final serviceCategories = state.categories
                  .where((category) =>
                      category.type == CategoryType.serviceExperience)
                  .toList();

              return Column(
                children: [
                  Expanded(
                      child: GridView.builder(
                    shrinkWrap: true,
                    controller: _pageScrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      crossAxisCount: 3,
                      height: MediaQuery.of(context).size.height * 0.18,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      CategoryModel category = serviceCategories[index];
                      return CategoryCard(
                        onTap: () {
                          if (widget.from == Routes.filterScreen) {
                            Navigator.pop(context, category);
                          } else {
                            if (category.children!.isEmpty) {
                              Constant.itemFilter = null;
                              HelperUtils.goToNextPage(
                                Routes.itemsList,
                                context,
                                false,
                                args: {
                                  'catID': category.id.toString(),
                                  'catName': category.name,
                                  "categoryIds": [category.id.toString()]
                                },
                              );
                            } else {
                              Navigator.pushNamed(
                                  context, Routes.subCategoryScreen,
                                  arguments: {
                                    "categoryList": category.children,
                                    "catName": category.name,
                                    "catId": category.id,
                                    "categoryIds": [category.id.toString()]
                                  }); //pass current index category id & name here
                            }
                          }
                        },
                        title: category.name!,
                        url: category.url!,
                      );
                    },
                    itemCount: serviceCategories.length,
                  )),
                  if (state.isLoadingMore) UiUtils.progress()
                ],
              );
            }

            return Container();
          },
        ),
      ),
    );
  }
}
