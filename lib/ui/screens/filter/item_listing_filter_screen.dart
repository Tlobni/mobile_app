import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ItemListingFilterScreen extends StatefulWidget {
  const ItemListingFilterScreen({
    Key? key,
    this.initialFilter,
  }) : super(key: key);

  final ItemFilterModel? initialFilter;

  @override
  State<ItemListingFilterScreen> createState() => _ItemListingFilterScreenState();
}

class _ItemListingFilterScreenState extends State<ItemListingFilterScreen> {
  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String? listingType;

  double _rating = 0;
  double _minRating = 0;
  double _maxRating = 5;
  bool _exclusiveForWomen = false;
  bool _corporatePackage = false;
  List<CategoryModel> categoryList = [];

  String city = "";
  String area = "";
  int? areaId;
  String _state = "";
  String country = "";
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    // Initialize with existing filter values if any
    initializeFields(widget.initialFilter);
  }

  void initializeFields(ItemFilterModel? filter) {
    minController.text = filter?.minPrice ?? "";
    maxController.text = filter?.maxPrice ?? "";

    city = filter?.city ?? "";
    areaId = filter?.areaId;
    area = filter?.area ?? "";
    _state = filter?.state ?? "";
    country = filter?.country ?? "";
    latitude = filter?.latitude;
    longitude = filter?.longitude;
    listingType = filter?.serviceType;
    categoryList = filter?.categories ??
        (filter?.categoryId != null
            ? filter!.categoryId!.split(',').where((e) => e.isNotEmpty).map((id) => CategoryModel(id: int.parse(id))).toList()
            : []);

    // Initialize rating range
    if (filter?.minRating != null) {
      _minRating = filter!.minRating!;
    }
    if (filter?.maxRating != null) {
      _maxRating = filter!.maxRating!;
    }

    // Set location text
    locationController.text = [city, country].where((element) => element.isNotEmpty).join(", ");

    // Set special tags - debug the parsed values
    if (filter?.specialTags != null) {
      print("DEBUG: Loading special tags from existing filter: ${filter?.specialTags}");

      // Parse exclusive_women value
      String? exclusiveForWomenValue = filter?.specialTags?["exclusive_women"];
      print("DEBUG: Exclusive for women value from filter: $exclusiveForWomenValue");
      if (exclusiveForWomenValue != null) {
        _exclusiveForWomen = exclusiveForWomenValue.toLowerCase() == "true";
        print("DEBUG: _exclusiveForWomen set to: $_exclusiveForWomen");
      }

      // Parse corporate_package value
      String? corporatePackageValue = filter?.specialTags?["corporate_package"];
      print("DEBUG: Corporate package value from filter: $corporatePackageValue");
      if (corporatePackageValue != null) {
        _corporatePackage = corporatePackageValue.toLowerCase() == "true";
        print("DEBUG: _corporatePackage set to: $_corporatePackage");
      }
    }
  }

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GeneralFilterScreen(
      title: 'Filter Listings',
      onResetPressed: _resetFilter,
      onApplyPressed: _applyFilter,
      sections: [
        ('Categories'.translate(context), _buildCategoryWidget()),
        ('locationLbl'.translate(context), _buildLocationWidget()),
        ('Listing Type'.translate(context), _listingTypes()),
        ('Price Range', _buildPriceRangeWidget()),
        ('Special Filters', _buildSpecialFilters()),
        ('Rating'.translate(context), _buildRatingFilter()),
      ],
    );
  }

  Widget _listingTypes() => GeneralTypeSelector(
        values: [null, 'service', 'experience'],
        valueToString: (e) => switch (e) {
          null => 'All',
          'service' => 'Service',
          'experience' => 'Experience',
          _ => '',
        },
        onChanged: (value) => setState(() => listingType = value),
        selectedValue: listingType,
      );

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
                categoryType: CategoryType.serviceExperience,
              ),
            ),
          ),
        )
            .then((value) {
          // The category list will be updated inside the FilterCategoryScreen
          // We just need to refresh the UI to show the updated selections
          setState(() {
            // Debug log to show selected categories
            print("DEBUG: Selected categories for service filter:");
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

  Widget _buildPriceRangeWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        (1, _priceRangeTextField('Min Price (\$)', minController)),
        (0, DescriptionText('to')),
        (1, _priceRangeTextField('Max Price (\$)', maxController)),
      ].mapExpandedSpaceBetween(10),
    );
  }

  Widget _priceRangeTextField(String label, TextEditingController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DescriptionText(label),
          SizedBox(height: 10),
          Container(
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: context.color.secondaryColor,
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(20),
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.color.territoryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.color.borderColor.darken(30)),
                ),
                border: const OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: context.textTheme.bodyMedium,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      );

  Widget _buildSpecialFilters() => Column(
        children: [
          _buildSwitchOption("Exclusive for Women", _exclusiveForWomen, (value) => _exclusiveForWomen = value),
          _buildSwitchOption("Corporate Package", _corporatePackage, (value) => _corporatePackage = value),
        ],
      );

  Widget _buildSwitchOption(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          label,
          color: context.color.textColorDark,
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            // Log the value change for debugging
            print("DEBUG: ${label} switch changed from $value to $newValue");
            setState(() {
              onChanged(newValue);
            });
          },
          activeColor: context.color.territoryColor,
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    // Use RangeSlider instead of Slider for min-max rating selection
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
    print("DEBUG: Apply Filter button pressed in service_filter_screen");

    // Convert boolean values to string "true" or "false"
    Map<String, String> specialTags = {
      "exclusive_women": _exclusiveForWomen.toString(),
      "corporate_package": _corporatePackage.toString(),
    };

    print("DEBUG: Special tags values: ${specialTags.toString()}");
    print("DEBUG: exclusive_women value: ${specialTags['exclusive_women']}");
    print("DEBUG: corporate_package value: ${specialTags['corporate_package']}");

    ItemFilterModel filter = ItemFilterModel(
      maxPrice: maxController.text,
      minPrice: minController.text,
      categoryId: categoryList.isNotEmpty ? categoryList.map((cat) => cat.id.toString()).join(',') : "",
      city: city,
      areaId: areaId,
      state: _state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      area: area,
      serviceType: listingType,
      specialTags: specialTags,
      minRating: _minRating,
      maxRating: _maxRating,
      categories: categoryList,
      itemSortBy: widget.initialFilter?.itemSortBy,
    );

    // Debug the filter model before sending
    print("DEBUG: Creating filter for service search:");
    print("DEBUG: Category IDs: ${filter.categoryId}");
    print("DEBUG: Service Type: ${filter.serviceType}");

    Navigator.pop(context, filter);

    // // Navigate only once to prevent double calls
    // final arguments = {"itemFilter": filter};
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
}
