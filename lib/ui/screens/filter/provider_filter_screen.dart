import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/category/fetch_category_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/filter_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/theme/theme.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize with existing filter values if any
    if (widget.initialFilter != null) {
      city = widget.initialFilter?.city ?? "";
      areaId = widget.initialFilter?.areaId;
      area = widget.initialFilter?.area ?? "";
      _state = widget.initialFilter?.state ?? "";
      country = widget.initialFilter?.country ?? "";
      latitude = widget.initialFilter?.latitude;
      longitude = widget.initialFilter?.longitude;
      providerType = widget.initialFilter?.userType;
      // Reset gender to default (null) regardless of saved value
      _gender = null;

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
    }
  }

  @override
  void dispose() {
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
        title: 'Filter Providers'.translate(context),
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
              _providerTypes(),
              const SizedBox(height: 15),
              // Location Filter
              CustomText('locationLbl'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              _buildLocationWidget(context),
              const SizedBox(height: 15),

              // Category Filter
              CustomText('category'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 5),
              _buildCategoryWidget(context),
              const SizedBox(height: 15),

              // Gender Filter (only for Expert)
              if (providerType?.toLowerCase() == 'expert') ...[
                CustomText('Gender'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
                const SizedBox(height: 5),
                _buildGenderFilter(context),
                const SizedBox(height: 15),
              ],

              // Rating Filter
              CustomText('Rating Range'.translate(context), color: context.color.textDefaultColor, fontWeight: FontWeight.w600),
              const SizedBox(height: 10),
              _buildRatingFilter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerTypes() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider Type Filter (Service or Experience)
          CustomText(
            'Provider Type'.translate(context),
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _providerTypeButton("All".translate(context), null),
              SizedBox(width: 10),
              _providerTypeButton("Business".translate(context), "business"),
              SizedBox(width: 10),
              _providerTypeButton("Expert".translate(context), "expert"),
            ],
          ),
        ],
      );

  Widget _providerTypeButton(String text, String? value) => MaterialButton(
        onPressed: () => setState(() => providerType = value),
        color: providerType == value ? context.color.primary : null,
        textColor: providerType == value ? context.color.onPrimary : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(color: context.color.primary),
        ),
        child: Text(text.translate(context)),
      );

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

  Widget _buildGenderFilter(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.color.borderColor,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _gender,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: CustomText(
              "Choose one",
              color: context.color.textDefaultColor.withOpacity(0.5),
            ),
          ),
          items: ["Male", "Female"].map((String value) {
            return DropdownMenuItem<String>(
              value: value.toLowerCase(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: CustomText(
                  value,
                  color: context.color.textColorDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _gender = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRatingFilter() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
