// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/category/fetch_category_cubit.dart';
import 'package:eClassify/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/item_filter_model.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:eClassify/ui/screens/main_activity.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/dynamic_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Custom category filter screen that works with our filter page
class FilterCategoryScreen extends StatefulWidget {
  final List<CategoryModel> categoryList;

  const FilterCategoryScreen({Key? key, required this.categoryList})
      : super(key: key);

  @override
  State<FilterCategoryScreen> createState() => _FilterCategoryScreenState();
}

class _FilterCategoryScreenState extends State<FilterCategoryScreen>
    with TickerProviderStateMixin {
  final ScrollController _pageScrollController = ScrollController();

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

    // Fetch categories with type service_experience (don't try to read state directly)
    context.read<FetchCategoryCubit>().fetchCategories(
          type: CategoryType.serviceExperience,
        );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "categories".translate(context),
      ),
      body: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
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
            // Filter out any provider categories, only show serviceExperience
            final categories = state.categories
                .where((category) =>
                    category.type == CategoryType.serviceExperience)
                .toList();

            if (categories.isEmpty) {
              return Center(
                child: CustomText("No Data Found".translate(context)),
              );
            }
            return ListView.builder(
              controller: _pageScrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              itemCount: categories.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.territoryColor,
                    ),
                  );
                }
                return InkWell(
                  onTap: () {
                    widget.categoryList.add(categories[index]);
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: UiUtils.getImage(categories[index].url ?? "",
                          fit: BoxFit.contain),
                    ),
                    title: CustomText(categories[index].name ?? ""),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
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
        selectedCategory != defaultCategory) {
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
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        appBar: UiUtils.buildAppBar(
          context,
          onBackPress: () {
            checkFilterValSet();
            Navigator.pop(context);
          },
          showBackButton: true,
          title: "filterTitle".translate(context),
          actions: [
            // if ((checkFilterValSet() == true)) ...[
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
            // ]
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: context.color.secondaryColor,
          elevation: 3,
          child: UiUtils.buildButton(context,
              outerPadding: const EdgeInsets.all(12),
              height: 50, onPressed: () {
            Map<String, dynamic> customFields =
                convertToCustomFields(AbstractField.fieldsData);

            Constant.itemFilter = ItemFilterModel(
                maxPrice: maxController.text,
                minPrice: minController.text,
                categoryId: selectedCategories.isNotEmpty
                    ? selectedCategories.last
                    : "",
                postedSince: postedOn,
                city: city,
                areaId: areaId,
                radius: radius,
                state: _state,
                country: country,
                latitude: latitude,
                longitude: longitude,
                customFields: customFields);

            widget.update(ItemFilterModel(
                maxPrice: maxController.text,
                minPrice: minController.text,
                categoryId: widget.from == "search"
                    ? selectedCategories.isNotEmpty
                        ? selectedCategories.last
                        : ""
                    : '',
                postedSince: postedOn,
                city: city,
                areaId: areaId,
                radius: radius,
                state: _state,
                country: country,
                longitude: longitude,
                latitude: latitude,
                area: area,
                customFields: customFields));

            Navigator.pop(context, true);
          }, buttonTitle: "applyFilter".translate(context), radius: 8),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(
              20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CustomText('locationLbl'.translate(context),
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 5),
                locationWidget(context),
                if (widget.categoryIds == null ||
                    widget.categoryIds!.isEmpty) ...[
                  const SizedBox(height: 15),
                  CustomText('category'.translate(context),
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 5),
                  categoryWidget(context),
                  const SizedBox(height: 5),
                ],
                const SizedBox(
                  height: 15,
                ),
                CustomText('budgetLbl'.translate(context),
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 15),
                budgetOption(),
                const SizedBox(height: 15),
                CustomText('postedSinceLbl'.translate(context),
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 5),
                postedSinceOption(context),
                const SizedBox(height: 15),
                customFields()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customFields() {
    return BlocConsumer<FetchCustomFieldsCubit, FetchCustomFieldState>(
      listener: (context, state) {
        if (state is FetchCustomFieldSuccess) {
          moreDetailDynamicFields = context
              .read<FetchCustomFieldsCubit>()
              .getFields()
              .where((field) =>
                  field.type != "fileinput" &&
                  field.type != "textbox" &&
                  field.type != "number")
              .map((field) {
            Map<String, dynamic> fieldData = field.toMap();

            // Prefill value from Constant.itemFilter!.customFields
            if (Constant.itemFilter != null &&
                Constant.itemFilter!.customFields != null) {
              String customFieldKey = 'custom_fields[${fieldData['id']}]';
              if (Constant.itemFilter!.customFields!
                  .containsKey(customFieldKey)) {
                fieldData['value'] =
                    Constant.itemFilter!.customFields![customFieldKey];
                fieldData['isEdit'] = true;
              }
            }

            CustomFieldBuilder customFieldBuilder =
                CustomFieldBuilder(fieldData);
            customFieldBuilder.stateUpdater(setState);
            customFieldBuilder.init();
            return customFieldBuilder;
          }).toList();
          setState(() {});
        }
      },
      builder: (context, state) {
        if (moreDetailDynamicFields.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: moreDetailDynamicFields.map((field) {
              field.stateUpdater(setState);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                child: field.build(context),
              );
            }).toList(),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }

  Widget locationWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: LocationAutocomplete(
        controller: locationController,
        hintText: "allCities".translate(context),
        onSelected: (String location) {
          // Basic handling when only the string is returned
        },
        onLocationSelected: (Map<String, String> locationData) {
          setState(() {
            city = locationData['city'] ?? "";
            _state = locationData['state'] ?? "";
            country = locationData['country'] ?? "";
            area = ""; // Reset area as it's not in the autocomplete data
            areaId = null; // Reset areaId
            radius = null; // Reset radius
            // We don't have lat/lng in the autocomplete data
            latitude = null;
            longitude = null;
          });
        },
      ),
    );
  }

  Widget categoryWidget(BuildContext context) {
    return InkWell(
      onTap: () {
        categoryList.clear();
        // Use MaterialPageRoute with BlocProvider to ensure the FetchCategoryCubit is available
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) {
                final cubit = FetchCategoryCubit();
                // No need to fetch here, the screen will do it properly now
                return cubit;
              },
              child: FilterCategoryScreen(
                categoryList: categoryList,
              ),
            ),
          ),
        )
            .then((value) {
          if (categoryList.isNotEmpty) {
            setState(() {});
            selectedCategories.clear();
            selectedCategories.addAll(
                categoryList.map<String>((e) => e.id.toString()).toList());
            getCustomFieldsData();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.color.borderColor.darken(30),
                width: 1,
              )),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14.0),
            child: Row(
              children: [
                categoryList.isNotEmpty
                    ? UiUtils.getImage(categoryList[0].url!,
                        height: 20, width: 20, fit: BoxFit.contain)
                    : UiUtils.getSvg(AppIcons.categoryIcon,
                        color: context.color.textDefaultColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 15.0),
                    child: categoryList.isNotEmpty
                        ? CustomText(
                            "${categoryList.map((e) => e.name).join(' - ')}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                        : CustomText("allInClassified".translate(context),
                            color: context.color.textDefaultColor
                                .withOpacity(0.3)),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 14.0),
                  child: UiUtils.getSvg(AppIcons.downArrow,
                      color: context.color.textDefaultColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget saveFilter() {
    //save prefs & validate fields & call API
    return IconButton(
        onPressed: () {
          Constant.itemFilter = ItemFilterModel(
            maxPrice: maxController.text,
            city: city,
            areaId: areaId,
            radius: radius,
            state: _state,
            country: country,
            longitude: longitude,
            latitude: latitude,
            minPrice: minController.text,
            categoryId:
                selectedCategories.isNotEmpty ? selectedCategories.last : "",
            postedSince: postedOn,
          );

          Navigator.pop(context, true);
        },
        icon: const Icon(Icons.check));
  }

  Widget budgetOption() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              minMaxTFF(
                "minLbl".translate(context),
              )
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              minMaxTFF("maxLbl".translate(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget minMaxTFF(String minMax) {
    return Container(
        /*  padding: EdgeInsetsDirectional.only(
            end: minMax == "minLbl".translate(context) ? 5 :),*/
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).colorScheme.secondaryColor),
        child: TextFormField(
            controller: (minMax == "minLbl".translate(context))
                ? minController
                : maxController,
            onChanged: ((value) {
              bool isEmpty = value.trim().isEmpty;
              if (minMax == "minLbl".translate(context)) {
                if (isEmpty && searchBody.containsKey(Api.minPrice)) {
                  searchBody.remove(Api.minPrice);
                } else {
                  searchBody[Api.minPrice] = value;
                }
              } else {
                if (isEmpty && searchBody.containsKey(Api.maxPrice)) {
                  searchBody.remove(Api.maxPrice);
                } else {
                  searchBody[Api.maxPrice] = value;
                }
              }
            }),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
                isDense: true,
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: context.color.territoryColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: context.color.borderColor.darken(30))),
                labelStyle: TextStyle(
                    color: context.color.textDefaultColor.withOpacity(0.3)),
                hintText: "00",
                label: CustomText(
                  minMax,
                ),
                prefixText: '${Constant.currencySymbol} ',
                prefixStyle: TextStyle(
                    color: Theme.of(context).colorScheme.territoryColor),
                fillColor: Theme.of(context).colorScheme.secondaryColor,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
            style:
                TextStyle(color: Theme.of(context).colorScheme.territoryColor),
            /* onSubmitted: () */
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]));
  }

  void postedSinceUpdate(String value) {
    setState(() {
      postedOn = value;
    });
  }

  Widget postedSinceOption(BuildContext context) {
    int index =
        Constant.postedSince.indexWhere((item) => item.value == postedOn);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.postedSinceFilterScreen,
            arguments: {
              "list": Constant.postedSince,
              "postedSince": postedOn,
              "update": postedSinceUpdate
            }).then((value) {});
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.color.borderColor.darken(30),
                width: 1,
              )),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14.0),
            child: Row(
              children: [
                UiUtils.getSvg(AppIcons.sinceIcon,
                    color: context.color.textDefaultColor),
                Padding(
                    padding: const EdgeInsetsDirectional.only(start: 15.0),
                    child: CustomText(Constant.postedSince[index].status,
                        color:
                            context.color.textDefaultColor.withOpacity(0.3))),
                Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 14.0),
                  child: UiUtils.getSvg(AppIcons.downArrow,
                      color: context.color.textDefaultColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onClickPosted(String val) {
    if (val == Constant.postedSince[0].value &&
        searchBody.containsKey(Api.postedSince)) {
      searchBody[Api.postedSince] = "";
    } else {
      searchBody[Api.postedSince] = val;
    }

    postedOn = val;
    setState(() {});
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
