import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/filter/widgets/general_filter_screen.dart';
import 'package:tlobni/ui/screens/filter/widgets/general_type_selector.dart';
import 'package:tlobni/ui/screens/filter/widgets/rating_selector.dart';
import 'package:tlobni/ui/screens/filter_category_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ProviderFilterScreen extends StatefulWidget {
  const ProviderFilterScreen({
    Key? key,
    this.initialFilter,
  }) : super(key: key);

  final ItemFilterModel? initialFilter;

  @override
  State<ProviderFilterScreen> createState() => _ProviderFilterScreenState();
}

class _ProviderFilterScreenState extends State<ProviderFilterScreen> {
  TextEditingController locationController = TextEditingController();

  double _minRating = 0;
  double _maxRating = 5;

  String? _gender;
  List<CategoryModel> categoryList = [];
  String? providerType;

  String city = "";
  String area = "";
  int? areaId;
  String _state = "";
  String country = "";
  double? latitude;
  double? longitude;

  bool featuredOnly = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing filter values if any
    initializeFields(widget.initialFilter);
  }

  void initializeFields(ItemFilterModel? filter) {
    city = filter?.city ?? "";
    areaId = filter?.areaId;
    area = filter?.area ?? "";
    _state = filter?.state ?? "";
    country = filter?.country ?? "";
    latitude = filter?.latitude;
    longitude = filter?.longitude;
    providerType = filter?.userType;
    categoryList = filter?.categories ??
        (filter?.categoryId != null
            ? filter!.categoryId!.split(',').where((e) => e.isNotEmpty).map((id) => CategoryModel(id: int.parse(id))).toList()
            : []);
    // Initialize rating range
    // if (filter?.minRating != null) {
    _minRating = filter?.minRating ?? 0;
    // }
    // if (filter?.maxRating != null) {
    _maxRating = filter?.maxRating ?? 5;
    // }
    featuredOnly = filter?.featuredOnly ?? false;
    locationController.text = [city, country].where((element) => element.isNotEmpty).join(", ");
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GeneralFilterScreen(
      title: 'Filter Providers',
      onResetPressed: _resetFilter,
      onApplyPressed: _applyFilter,
      sections: [
        ('Provider Type', _providerType()),
        ('Categories', _buildCategoryWidget()),
        ('Location', _buildLocationWidget()),
        if (providerType == 'expert') ('Gender', _buildGenderFilter()),
        ('Rating', _buildRatingFilter()),
        _featuredProvidersOnly(),
      ],
    );
  }

  Widget _providerType() => GeneralTypeSelector(
        values: [
          null,
          'business',
          'expert',
        ],
        valueToString: (e) => switch (e) {
          null => 'All',
          'business' => 'Business',
          'expert' => 'Expert',
          _ => '',
        },
        selectedValue: providerType,
        onChanged: (value) => setState(() {
          if (value == providerType) return;
          providerType = value;
          _gender = null;
        }),
      );

  Widget _buildLocationWidget() {
    return Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.color.borderColor.darken(30),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            iconTheme: IconThemeData(
              color: context.color.textDefaultColor,
              size: 20,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: LocationAutocomplete(
              controller: locationController,
              hintText: "allCities".translate(context),
              onSelected: (String location) {
                // Basic handling when only the string is returned
              },
              onLocationSelected: (Map<String, String> locationData) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    city = locationData['city'] ?? "";
                    _state = locationData['state'] ?? "";
                    country = locationData['country'] ?? "";
                    area = "";
                    areaId = null;
                    latitude = null;
                    longitude = null;
                  });
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWidget() {
    return InkWell(
      onTap: () {
        // Don't clear the category list when opening the selection screen
        // This allows retaining the previously selected categories
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) {
                final cubit = FetchCategoryCubit();
                // No need to initialize here anymore, the FilterCategoryScreen will handle it
                return cubit;
              },
              child: FilterCategoryScreen(
                categoryList: categoryList,
                categoryType: CategoryType.providers,
              ),
            ),
          ),
        )
            .then((value) {
          // The category list will be updated inside the FilterCategoryScreen
          // We just need to refresh the UI to show the updated selections
          setState(() {
            // Debug log to show selected categories
            print("DEBUG: Selected categories for provider filter:");
            for (var category in categoryList) {
              print("DEBUG: Category ID: ${category.id}, Name: ${category.name}, Type: ${category.type}");
            }
          });
        });
      },
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
                  ? UiUtils.getImage(categoryList[0].url!, height: 20, width: 20, fit: BoxFit.contain)
                  : UiUtils.getSvg(AppIcons.categoryIcon, color: context.color.textDefaultColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 15.0),
                  child: categoryList.isNotEmpty
                      ? CustomText(
                          // Show the count of selected categories if more than one
                          categoryList.length > 1
                              ? "${categoryList[0].name} +${categoryList.length - 1}"
                              : "${categoryList.map((e) => e.name).join(' - ')}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                      : CustomText("Select Category".translate(context), color: context.color.textDefaultColor.withOpacity(0.3)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 14.0),
                child: UiUtils.getSvg(AppIcons.downArrow, color: context.color.textDefaultColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderFilter() {
    return GeneralTypeSelector(
      values: [null, 'Male', 'Female'],
      valueToString: (e) => e == null ? 'All' : e,
      selectedValue: _gender,
      onChanged: (val) => setState(() => _gender = val),
    );
  }

  Widget _buildRatingFilter() {
    return RatingSelector(
      minRating: _minRating,
      maxRating: _maxRating,
      onChanged: (values) {
        setState(() {
          _minRating = values.start;
          _maxRating = values.end;
        });
      },
    );
  }

  void _applyFilter() {
    print("DEBUG: Apply Filter button pressed in provider_filter_screen");
    ItemFilterModel filter = ItemFilterModel(
      categoryId: categoryList.isNotEmpty ? categoryList.map((cat) => cat.id.toString()).join(',') : "",
      city: city,
      areaId: areaId,
      state: _state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      area: area,
      userType: providerType?.toLowerCase(),
      gender: providerType?.toLowerCase() == 'expert' ? _gender : null,
      minRating: _minRating,
      maxRating: _maxRating,
      featuredOnly: featuredOnly,
      providerSortBy: widget.initialFilter?.providerSortBy,
    );

    // Debug the filter model before sending
    print("DEBUG: Creating filter for provider search:");
    print("DEBUG: Category IDs: ${filter.categoryId}");
    print("DEBUG: User Type: ${filter.userType}");
    print("DEBUG: Gender: ${filter.gender}");

    // Navigate only once to prevent double calls
    Navigator.pop(context, filter);
    // final arguments = {"itemFilter": filter, 'screenType': SearchScreenType.provider};
    // if (Navigator.of(context).canPop()) {
    //   print("DEBUG: Popping and pushing replacement for search screen");
    //   Navigator.of(context).pushReplacementNamed(Routes.searchScreenRoute, arguments: arguments);
    // } else {
    //   print("DEBUG: Pushing named route to search screen");
    //   Navigator.pushNamed(context, Routes.searchScreenRoute, arguments: arguments);
    // }
  }

  void _resetFilter() {
    initializeFields(ItemFilterModel.createEmpty());
    setState(() {});
  }

  Widget _divider() => Divider(height: 1.5, thickness: 0.5);

  Widget _featuredProvidersOnly() => Column(
        children: [
          _divider(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: DescriptionText('Featured Providers Only')),
              Switch(
                value: featuredOnly,
                onChanged: (val) => setState(() => featuredOnly = val ?? false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _divider(),
        ],
      );
}
