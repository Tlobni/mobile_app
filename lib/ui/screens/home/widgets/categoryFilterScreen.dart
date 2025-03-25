import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFilterScreen extends StatefulWidget {
  final List<CategoryModel> categoryList;

  const CategoryFilterScreen({super.key, required this.categoryList});

  @override
  State<CategoryFilterScreen> createState() => _CategoryFilterScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => CategoryFilterScreen(
        categoryList: args!["categoryList"],
      ),
    );
  }
}

class _CategoryFilterScreenState extends State<CategoryFilterScreen>
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

    // Fetch categories with type service_experience
    if (context.read<FetchCategoryState>() is! FetchCategorySuccess ||
        (context.read<FetchCategoryState>() is FetchCategorySuccess &&
            (context.read<FetchCategoryState>() as FetchCategorySuccess)
                    .categoryType !=
                CategoryType.serviceExperience)) {
      context.read<FetchCategoryCubit>().fetchCategories(
            type: CategoryType.serviceExperience,
          );
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
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        onBackPress: () {
          Navigator.of(context).pop();
        },
        title: "classifieds".translate(context),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: context.screenWidth,
          child: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
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

                return Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    color: context.color.secondaryColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            child: CustomText(
                              "allInClassified".translate(context),
                              color: context.color.textDefaultColor,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.bold,
                              fontSize: context.font.normal,
                            )),
                        const Divider(
                          thickness: 1.2,
                          height: 10,
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: serviceCategories.length,
                            padding: EdgeInsets.zero,
                            controller: _pageScrollController,
                            shrinkWrap: true,
                            separatorBuilder: (context, index) {
                              return const Divider(
                                thickness: 1.2,
                                height: 10,
                              );
                            },
                            itemBuilder: (context, index) {
                              CategoryModel category = serviceCategories[index];

                              return ListTile(
                                onTap: () {
                                  widget.categoryList.add(category);

                                  if (category.children?.isNotEmpty ?? false) {
                                    Navigator.pushNamed(
                                        context, Routes.subCategoryFilterScreen,
                                        arguments: {
                                          "model": category.children,
                                          "selection": widget.categoryList,
                                        });
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                leading: Container(
                                    width: 40,
                                    height: 40,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: context.color.territoryColor
                                            .withOpacity(0.1)),
                                    child: UiUtils.imageType(
                                      category.url!,
                                      color: context.color.territoryColor,
                                      fit: BoxFit.cover,
                                    )),
                                title: CustomText(
                                  category.name!,
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  color: context.color.textDefaultColor,
                                  fontSize: context.font.normal,
                                ),
                                trailing: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.color.borderColor
                                            .darken(10)),
                                    child: Icon(
                                      Icons.chevron_right_outlined,
                                      color: context.color.textDefaultColor,
                                    )),
                              );
                            },
                          ),
                        ),
                        if (state.isLoadingMore)
                          Center(child: UiUtils.progress())
                      ],
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }
}
