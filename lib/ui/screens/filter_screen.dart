// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';

import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/filter/provider_filter_screen.dart';
import 'package:tlobni/ui/screens/filter/service_filter_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/screens/main_activity.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/dynamic_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';

// String extension for capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// Custom category filter screen that works with our filter page
class FilterCategoryScreen extends StatefulWidget {
  final List<CategoryModel> categoryList;
  final CategoryType categoryType;

  const FilterCategoryScreen({
    Key? key,
    required this.categoryList,
    this.categoryType = CategoryType.serviceExperience,
  }) : super(key: key);

  @override
  State<FilterCategoryScreen> createState() => _FilterCategoryScreenState();
}

class _FilterCategoryScreenState extends State<FilterCategoryScreen>
    with TickerProviderStateMixin {
  final ScrollController _pageScrollController = ScrollController();
  List<CategoryModel> allCategories = [];
  List<CategoryModel> filteredCategories = [];
  List<bool> expandedPanels = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  Map<int, bool> expandedSubcategories = {};

  @override
  void initState() {
    super.initState();
    _pageScrollController.addListener(() {
      if (_pageScrollController.isEndReached()) {
        if (context.read<FetchCategoryCubit>().hasMoreData()) {
          context.read<FetchCategoryCubit>().fetchCategoriesMore();
        }
      }
    });

    // Fetch categories with the type specified by the widget
    context.read<FetchCategoryCubit>().fetchCategories(
          type: widget.categoryType,
        );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  bool isCategorySelected(int categoryId) {
    return widget.categoryList.any((cat) => cat.id == categoryId);
  }

  void toggleCategorySelection(CategoryModel category, bool selected) {
    setState(() {
      if (selected) {
        if (!widget.categoryList.any((cat) => cat.id == category.id)) {
          widget.categoryList.add(category);
        }

        // Also select children if any
        if (category.children != null && category.children!.isNotEmpty) {
          for (var child in category.children!) {
            if (!widget.categoryList.any((cat) => cat.id == child.id)) {
              widget.categoryList.add(child);
            }

            // Add nested children if any
            if (child.children != null && child.children!.isNotEmpty) {
              for (var nestedChild in child.children!) {
                if (!widget.categoryList
                    .any((cat) => cat.id == nestedChild.id)) {
                  widget.categoryList.add(nestedChild);
                }
              }
            }
          }
        }
      } else {
        widget.categoryList.removeWhere((cat) => cat.id == category.id);

        // Also remove children if any
        if (category.children != null && category.children!.isNotEmpty) {
          for (var child in category.children!) {
            widget.categoryList.removeWhere((cat) => cat.id == child.id);

            // Remove nested children if any
            if (child.children != null && child.children!.isNotEmpty) {
              for (var nestedChild in child.children!) {
                widget.categoryList
                    .removeWhere((cat) => cat.id == nestedChild.id);
              }
            }
          }
        }
      }
    });
  }

  void filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCategories = allCategories;
      } else {
        query = query.toLowerCase();
        filteredCategories = allCategories.where((category) {
          final matchesMainCategory =
              category.name?.toLowerCase().contains(query) ?? false;

          // Check if any subcategory matches
          final hasMatchingSubcategory = category.children?.any((subcategory) =>
                  subcategory.name?.toLowerCase().contains(query) ?? false) ??
              false;

          return matchesMainCategory || hasMatchingSubcategory;
        }).toList();

        // Auto-expand categories with matching subcategories
        for (int i = 0; i < filteredCategories.length; i++) {
          final category = filteredCategories[i];
          final originalIndex = allCategories.indexOf(category);
          if (originalIndex >= 0 && originalIndex < expandedPanels.length) {
            final hasMatchingSubcategory = category.children?.any(
                    (subcategory) =>
                        subcategory.name?.toLowerCase().contains(query) ??
                        false) ??
                false;

            if (hasMatchingSubcategory) {
              expandedPanels[originalIndex] = true;
            }
          }
        }
      }
    });
  }

  bool isSubcategoryExpanded(int subCategoryId) {
    return expandedSubcategories[subCategoryId] ?? false;
  }

  void toggleSubcategoryExpansion(int subCategoryId) {
    setState(() {
      expandedSubcategories[subCategoryId] =
          !(expandedSubcategories[subCategoryId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "categories".translate(context),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Done",
              style: TextStyle(
                color: context.color.territoryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search categories".translate(context),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: filterCategories,
            ),
          ),

          // Category list
          Expanded(
            child: BlocConsumer<FetchCategoryCubit, FetchCategoryState>(
              listener: (context, state) {
                if (state is FetchCategorySuccess) {
                  // Initialize data when categories are fetched
                  setState(() {
                    allCategories = state.categories
                        .where(
                            (category) => category.type == widget.categoryType)
                        .toList();

                    // If the search field has text, apply filter
                    if (searchController.text.isNotEmpty) {
                      filterCategories(searchController.text);
                    } else {
                      filteredCategories = allCategories;
                    }

                    // Initialize expansion state for all categories
                    expandedPanels = List.generate(
                      allCategories.length,
                      (index) => false,
                    );

                    isLoading = false;
                  });
                }
              },
              builder: (context, state) {
                if (state is FetchCategoryInProgress) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.territoryColor,
                    ),
                  );
                }

                if (state is FetchCategoryFailure) {
                  return Center(
                    child: Text(state.errorMessage),
                  );
                }

                if (state is FetchCategorySuccess) {
                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: CustomText("No Data Found".translate(context)),
                    );
                  }

                  return ListView.builder(
                    controller: _pageScrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    itemCount: filteredCategories.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredCategories.length) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.territoryColor,
                          ),
                        );
                      }

                      final category = filteredCategories[index];
                      final originalIndex = allCategories.indexOf(category);
                      final hasSubcategories = category.children != null &&
                          category.children!.isNotEmpty;

                      return Column(
                        children: [
                          // Parent category
                          Container(
                            decoration: BoxDecoration(
                              color: context.color.secondaryColor,
                              border: Border(
                                bottom: BorderSide(
                                  color: context.color.borderColor.darken(10),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                category.name ?? "Unknown",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              leading: Checkbox(
                                value: isCategorySelected(category.id ?? 0),
                                onChanged: (bool? value) {
                                  if (category.id != null && value != null) {
                                    toggleCategorySelection(category, value);
                                  }
                                },
                              ),
                              trailing: hasSubcategories
                                  ? Icon(
                                      expandedPanels[originalIndex]
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: context.color.textDefaultColor,
                                    )
                                  : null,
                              onTap: hasSubcategories
                                  ? () {
                                      setState(() {
                                        expandedPanels[originalIndex] =
                                            !expandedPanels[originalIndex];
                                      });
                                    }
                                  : null,
                            ),
                          ),

                          // Subcategories (if expanded and has subcategories)
                          if (hasSubcategories && expandedPanels[originalIndex])
                            Container(
                              color:
                                  context.color.secondaryColor.withOpacity(0.5),
                              child: Column(
                                children: category.children!.map((subcategory) {
                                  // Filter subcategories if search is active
                                  if (searchController.text.isNotEmpty) {
                                    final query =
                                        searchController.text.toLowerCase();
                                    if (!(subcategory.name
                                            ?.toLowerCase()
                                            .contains(query) ??
                                        false)) {
                                      return Container(); // Skip non-matching subcategories
                                    }
                                  }

                                  final hasNestedSubcategories =
                                      subcategory.children != null &&
                                          subcategory.children!.isNotEmpty;

                                  return Column(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 20.0),
                                        child: ListTile(
                                          title: Text(
                                              subcategory.name ?? "Unknown"),
                                          leading: Checkbox(
                                            value: isCategorySelected(
                                                subcategory.id ?? 0),
                                            onChanged: (bool? value) {
                                              if (subcategory.id != null &&
                                                  value != null) {
                                                toggleCategorySelection(
                                                    subcategory, value);
                                              }
                                            },
                                          ),
                                          trailing: hasNestedSubcategories
                                              ? Icon(
                                                  isSubcategoryExpanded(
                                                          subcategory.id ?? 0)
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  color: context
                                                      .color.textDefaultColor,
                                                )
                                              : null,
                                          onTap: hasNestedSubcategories
                                              ? () {
                                                  toggleSubcategoryExpansion(
                                                      subcategory.id ?? 0);
                                                }
                                              : null,
                                        ),
                                      ),

                                      // Nested subcategories
                                      if (hasNestedSubcategories &&
                                          isSubcategoryExpanded(
                                              subcategory.id ?? 0))
                                        Container(
                                          color: context.color.secondaryColor
                                              .withOpacity(0.3),
                                          child: Column(
                                            children: subcategory.children!
                                                .map((nestedSubcategory) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 40.0),
                                                child: ListTile(
                                                  title: Text(
                                                      nestedSubcategory.name ??
                                                          "Unknown"),
                                                  leading: Checkbox(
                                                    value: isCategorySelected(
                                                        nestedSubcategory.id ??
                                                            0),
                                                    onChanged: (bool? value) {
                                                      if (nestedSubcategory
                                                                  .id !=
                                                              null &&
                                                          value != null) {
                                                        toggleCategorySelection(
                                                            nestedSubcategory,
                                                            value);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterScreen extends StatefulWidget {
  final Function update;
  final String from;
  final List<String>? categoryIds;
  final List<CategoryModel>? categoryList;

  const FilterScreen({
    super.key,
    required this.update,
    required this.from,
    this.categoryIds,
    this.categoryList,
  });

  @override
  FilterScreenState createState() => FilterScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => BlocProvider(
        create: (context) => FetchCustomFieldsCubit(),
        child: FilterScreen(
          update: arguments?['update'],
          from: arguments?['from'],
          categoryIds: arguments?['categoryIds'] ?? [],
          categoryList: arguments?['categoryList'] ?? [],
        ),
      ),
    );
  }
}

class FilterScreenState extends State<FilterScreen> {
  List<String> selectedCategories = [];

  TextEditingController minController =
      TextEditingController(text: Constant.itemFilter?.minPrice);
  TextEditingController maxController =
      TextEditingController(text: Constant.itemFilter?.maxPrice);
  TextEditingController locationController = TextEditingController();

  // = 2; // 0: last_week   1: yesterday
  dynamic defaultCategoryID = currentVisitingCategoryId;
  dynamic defaultCategory = currentVisitingCategory;
  dynamic city = Constant.itemFilter?.city ?? "";
  dynamic area = Constant.itemFilter?.area ?? "";
  dynamic areaId = Constant.itemFilter?.areaId ?? null;
  dynamic radius = Constant.itemFilter?.radius ?? null;
  dynamic _state = Constant.itemFilter?.state ?? "";
  dynamic country = Constant.itemFilter?.country ?? "";
  dynamic latitude = Constant.itemFilter?.latitude ?? null;
  dynamic longitude = Constant.itemFilter?.longitude ?? null;
  List<CustomFieldBuilder> moreDetailDynamicFields = [];

  // New filter options
  String? _userType; // 'expert' or 'business'
  String? _gender; // 'male' or 'female' (for experts)
  String? _serviceType; // 'service' or 'experience'
  Map<String, bool> _specialTags = {
    "exclusive_women":
        Constant.itemFilter?.specialTags?["exclusive_women"] == "true" || false,
    "corporate_package":
        Constant.itemFilter?.specialTags?["corporate_package"] == "true" ||
            false
  };

  String postedOn =
      Constant.itemFilter?.postedSince ?? Constant.postedSince[0].value;

  late List<CategoryModel> categoryList = widget.categoryList ?? [];

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setCategories();
    setDefaultVal(isRefresh: false);
    //clearFieldData();
    getCustomFieldsData();

    // Initialize new filter values from existing filter if available
    if (Constant.itemFilter != null) {
      _userType = Constant.itemFilter?.userType;
      _gender = Constant.itemFilter?.gender;
      _serviceType = Constant.itemFilter?.serviceType;

      // Initialize special tags if they exist in the filter
      if (Constant.itemFilter?.specialTags != null) {
        _specialTags["exclusive_women"] =
            Constant.itemFilter?.specialTags?["exclusive_women"] == "true";
        _specialTags["corporate_package"] =
            Constant.itemFilter?.specialTags?["corporate_package"] == "true";
      }
    }
  }

  void setCategories() {
    log('${widget.categoryList} - ${widget.categoryIds}');
    if (widget.categoryIds != null && widget.categoryIds!.isNotEmpty) {
      selectedCategories.addAll(widget.categoryIds!);
    }
    if (widget.categoryList != null && widget.categoryList!.isNotEmpty) {
      selectedCategories
          .addAll(widget.categoryList!.map((e) => e.id.toString()).toList());
    }
  }

  void getCustomFieldsData() {
    if (Constant.itemFilter == null) {
      AbstractField.fieldsData.clear();
    }
    if (selectedCategories.isNotEmpty) {
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
            categoryIds: selectedCategories.join(','),
          );
    }
  }

  void setDefaultVal({bool isRefresh = true}) {
    if (isRefresh) {
      postedOn = Constant.postedSince[0].value;
      Constant.itemFilter = null;
      searchBody[Api.postedSince] = Constant.postedSince[0].value;

      selectedCategoryId = "0";
      city = "";
      areaId = null;
      radius = null;
      area = "";
      _state = "";
      country = "";
      latitude = null;
      longitude = null;
      selectedCategoryName = "";
      selectedCategory = defaultCategory;

      // Reset new filter options
      _userType = null;
      _gender = null;
      _serviceType = null;
      _specialTags = {"exclusive_women": false, "corporate_package": false};

      minController.clear();
      maxController.clear();
      locationController.clear();
      widget.categoryList?.clear();
      selectedCategories.clear();
      moreDetailDynamicFields.clear();
      AbstractField.fieldsData.clear();
      AbstractField.files.clear();
      checkFilterValSet();
      setCategories();
      getCustomFieldsData();
    } else {
      city = HiveUtils.getCityName() ?? "";
      areaId = HiveUtils.getAreaId() != null
          ? int.parse(HiveUtils.getAreaId().toString())
          : null;
      area = HiveUtils.getAreaName() ?? "";
      _state = HiveUtils.getStateName() ?? "";
      country = HiveUtils.getCountryName() ?? "";
      latitude = HiveUtils.getLatitude() ?? null;
      longitude = HiveUtils.getLongitude() ?? null;

      // Update location controller text if available
      if ([city, _state, country]
          .where((element) => element.isNotEmpty)
          .isNotEmpty) {
        locationController.text =
            [city, country].where((element) => element.isNotEmpty).join(", ");
      }
    }
  }

  bool checkFilterValSet() {
    if (postedOn != Constant.postedSince[0].value ||
        minController.text.trim().isNotEmpty ||
        maxController.text.trim().isNotEmpty ||
        selectedCategory != defaultCategory ||
        _userType != null ||
        _gender != null ||
        _serviceType != null ||
        _specialTags["exclusive_women"] == true ||
        _specialTags["corporate_package"] == true) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> convertToCustomFields(Map<dynamic, dynamic> fieldsData) {
    return fieldsData.map((key, value) {
      return MapEntry('custom_fields[$key]', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        checkFilterValSet();
        return;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8F7FB), // Light purple background
        appBar: UiUtils.buildAppBar(
          context,
          onBackPress: () {
            checkFilterValSet();
            Navigator.pop(context);
          },
          showBackButton: true,
          title: "filterTitle".translate(context),
          actions: [
            FittedBox(
              fit: BoxFit.none,
              child: UiUtils.buildButton(
                context,
                onPressed: () {
                  setDefaultVal(isRefresh: true);
                  setState(() {});
                },
                width: 100,
                height: 50,
                fontSize: context.font.normal,
                buttonColor: context.color.secondaryColor,
                showElevation: false,
                textColor: context.color.textColorDark,
                buttonTitle: "reset".translate(context),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Listing Type Filter (Service or Experience)
                CustomText('Listing Type'.translate(context),
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 5),
                _buildServiceTypeFilter(context),
                const SizedBox(height: 15),

                // Provider Type Filter (Expert or Business)
                CustomText('Provider Type'.translate(context),
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 5),
                _buildUserTypeFilter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build filter option buttons
  Widget _buildFilterOption(
    BuildContext context, {
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: context.color.borderColor,
            width: 1,
          ),
        ),
        child: CustomText(
          label,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  // Service Type filter (Service or Experience)
  Widget _buildServiceTypeFilter(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        _buildFilterOption(
          context,
          label: "Service",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceFilterScreen(
                  update: widget.update,
                  fromServiceType: 'service',
                ),
              ),
            );
          },
        ),
        _buildFilterOption(
          context,
          label: "Exclusive Experience",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceFilterScreen(
                  update: widget.update,
                  fromServiceType: 'experience',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // User Type filter (Expert or Business)
  Widget _buildUserTypeFilter(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        _buildFilterOption(
          context,
          label: "Expert",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderFilterScreen(
                  update: widget.update,
                  providerType: 'expert',
                ),
              ),
            );
          },
        ),
        _buildFilterOption(
          context,
          label: "Business",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderFilterScreen(
                  update: widget.update,
                  providerType: 'business',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PostedSinceItem {
  final String status;
  final String value;

  PostedSinceItem({
    required this.status,
    required this.value,
  });
}
