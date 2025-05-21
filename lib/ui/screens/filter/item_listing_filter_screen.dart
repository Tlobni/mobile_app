import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/filter_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
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
    if (widget.initialFilter != null) {
      minController.text = widget.initialFilter?.minPrice ?? "";
      maxController.text = widget.initialFilter?.maxPrice ?? "";

      city = widget.initialFilter?.city ?? "";
      areaId = widget.initialFilter?.areaId;
      area = widget.initialFilter?.area ?? "";
      _state = widget.initialFilter?.state ?? "";
      country = widget.initialFilter?.country ?? "";
      latitude = widget.initialFilter?.latitude;
      longitude = widget.initialFilter?.longitude;
      listingType = widget.initialFilter?.serviceType;
      categoryList = widget.initialFilter?.categories ??
          (widget.initialFilter?.categoryId != null
              ? widget.initialFilter!.categoryId!
                  .split(',')
                  .where((e) => e.isNotEmpty)
                  .map((id) => CategoryModel(id: int.parse(id)))
                  .toList()
              : []);

      // Initialize rating range
      if (widget.initialFilter?.minRating != null) {
        _minRating = widget.initialFilter!.minRating!;
      }
      if (widget.initialFilter?.maxRating != null) {
        _maxRating = widget.initialFilter!.maxRating!;
      }

      // Set location text
      if ([city, country].where((element) => element.isNotEmpty).isNotEmpty) {
        locationController.text = [city, country].where((element) => element.isNotEmpty).join(", ");
      }

      // Set special tags - debug the parsed values
      if (widget.initialFilter?.specialTags != null) {
        print("DEBUG: Loading special tags from existing filter: ${widget.initialFilter?.specialTags}");

        // Parse exclusive_women value
        String? exclusiveForWomenValue = widget.initialFilter?.specialTags?["exclusive_women"];
        print("DEBUG: Exclusive for women value from filter: $exclusiveForWomenValue");
        if (exclusiveForWomenValue != null) {
          _exclusiveForWomen = exclusiveForWomenValue.toLowerCase() == "true";
          print("DEBUG: _exclusiveForWomen set to: $_exclusiveForWomen");
        }

        // Parse corporate_package value
        String? corporatePackageValue = widget.initialFilter?.specialTags?["corporate_package"];
        print("DEBUG: Corporate package value from filter: $corporatePackageValue");
        if (corporatePackageValue != null) {
          _corporatePackage = corporatePackageValue.toLowerCase() == "true";
          print("DEBUG: _corporatePackage set to: $_corporatePackage");
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "Filter Item Listings".translate(context),
      ),
      bottomNavigationBar: Container(
        height: kToolbarHeight + 16,
        color: context.color.secondaryColor,
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.color.territoryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () {
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
          },
          child: Text("Apply Filter".translate(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _listingTypes(),
              const SizedBox(height: 15),
              // Category Filter
              CustomText('category'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              _buildCategoryWidget(context),
              const SizedBox(height: 15),

              // Location Filter
              CustomText('locationLbl'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              _buildLocationWidget(context),
              const SizedBox(height: 15),

              // Price Range Filter
              CustomText('budgetLbl'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              _buildPriceRangeWidget(),
              const SizedBox(height: 15),

              // Special Tags Filter
              CustomText('Special Tags'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              Column(
                children: [
                  _buildSwitchOption(
                    context,
                    label: "Exclusive for Women",
                    value: _exclusiveForWomen,
                    onChanged: (value) {
                      setState(() {
                        _exclusiveForWomen = value;
                      });
                    },
                  ),
                  _buildSwitchOption(
                    context,
                    label: "Corporate Package",
                    value: _corporatePackage,
                    onChanged: (value) {
                      setState(() {
                        _corporatePackage = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Rating Filter
              CustomText('Rating'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 10),
              _buildRatingFilter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listingTypes() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Listing Type Filter (Service or Experience)
          CustomText(
            'Listing Type'.translate(context),
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _listingTypeButton("All".translate(context), null),
              const SizedBox(width: 10),
              _listingTypeButton("Service".translate(context), "service"),
              const SizedBox(width: 10),
              _listingTypeButton("Experience".translate(context), "experience"),
            ],
          ),
        ],
      );

  Widget _listingTypeButton(String text, String? value) => MaterialButton(
        onPressed: () {
          setState(() {
            listingType = value;
          });
        },
        color: listingType == value ? context.color.primary : null,
        textColor: listingType == value ? context.color.onPrimary : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(color: context.color.primary),
        ),
        child: Text(text.translate(context)),
      );

  Widget _buildCategoryWidget(BuildContext context) {
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

  Widget _buildLocationWidget(BuildContext context) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Container(
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)), color: Theme.of(context).colorScheme.secondaryColor),
              child: TextFormField(
                  controller: minController,
                  decoration: InputDecoration(
                      isDense: true,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.color.territoryColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.color.borderColor.darken(30))),
                      labelStyle: TextStyle(color: context.color.textDefaultColor.withOpacity(0.3)),
                      hintText: "00",
                      label: CustomText(
                        "minLbl".translate(context),
                      ),
                      prefixText: '${Constant.currencySymbol} ',
                      prefixStyle: TextStyle(color: Theme.of(context).colorScheme.territoryColor),
                      fillColor: Theme.of(context).colorScheme.secondaryColor,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).colorScheme.territoryColor),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)), color: Theme.of(context).colorScheme.secondaryColor),
              child: TextFormField(
                  controller: maxController,
                  decoration: InputDecoration(
                      isDense: true,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.color.territoryColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.color.borderColor.darken(30))),
                      labelStyle: TextStyle(color: context.color.textDefaultColor.withOpacity(0.3)),
                      hintText: "00",
                      label: CustomText(
                        "maxLbl".translate(context),
                      ),
                      prefixText: '${Constant.currencySymbol} ',
                      prefixStyle: TextStyle(color: Theme.of(context).colorScheme.territoryColor),
                      fillColor: Theme.of(context).colorScheme.secondaryColor,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).colorScheme.territoryColor),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        ),
      ],
    );
  }

  Widget _buildSwitchOption(
    BuildContext context, {
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
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
              onChanged(newValue);
            },
            activeColor: context.color.territoryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    // Use RangeSlider instead of Slider for min-max rating selection
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "From ${_minRating.toInt()} to ${_maxRating.toInt()} Stars",
                color: context.color.textColorDark,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Display star icons to represent the range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minimum rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _minRating.toInt() ? Icons.star : Icons.star_border,
                    color: index < _minRating.toInt() ? Colors.amber : context.color.textDefaultColor.withOpacity(0.3),
                    size: 16,
                  );
                }),
              ),
              const CustomText("to"),
              // Maximum rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _maxRating.toInt() ? Icons.star : Icons.star_border,
                    color: index < _maxRating.toInt() ? Colors.amber : context.color.textDefaultColor.withOpacity(0.3),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RangeSlider(
            values: RangeValues(_minRating, _maxRating),
            min: 0,
            max: 5,
            divisions: 5,
            activeColor: context.color.territoryColor,
            inactiveColor: context.color.borderColor,
            labels: RangeLabels(
              _minRating.toInt().toString(),
              _maxRating.toInt().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _minRating = values.start;
                _maxRating = values.end;
              });
            },
          ),
        ],
      ),
    );
  }
}
