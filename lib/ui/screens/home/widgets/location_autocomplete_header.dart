import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class LocationAutocompleteHeader extends StatefulWidget {
  const LocationAutocompleteHeader({Key? key}) : super(key: key);

  @override
  State<LocationAutocompleteHeader> createState() => _LocationAutocompleteHeaderState();
}

class _LocationAutocompleteHeaderState extends State<LocationAutocompleteHeader> {
  final TextEditingController _locationController = TextEditingController();
  bool _isExpanded = false;
  bool _preventAutoDismiss = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current location
    final cityName = HiveUtils.getCityName();
    final countryName = HiveUtils.getCountryName();
    if (cityName != null && cityName.isNotEmpty && countryName != null && countryName.isNotEmpty) {
      _locationController.text = "$cityName, $countryName";
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _refreshData(Map<String, String> location) {
    // Store location data using the proper HiveUtils method
    HiveUtils.setLocation(
      city: location['city'],
      state: location['state'],
      country: location['country'],
      area: location['state'], // Using state as area since that's what seems to be done elsewhere
    );

    // Update the controller text with the new location
    final cityName = location['city'];
    final countryName = location['country'];
    if (cityName != null && countryName != null) {
      _locationController.text = "$cityName, $countryName";
    }

    // Refresh data with new location
    context.read<FetchHomeScreenCubit>().fetch(
        city: HiveUtils.getCityName(), areaId: HiveUtils.getAreaId(), country: HiveUtils.getCountryName(), state: HiveUtils.getStateName());

    context.read<FetchHomeAllItemsCubit>().fetch(
        city: HiveUtils.getCityName(),
        areaId: HiveUtils.getAreaId(),
        radius: HiveUtils.getNearbyRadius(),
        longitude: HiveUtils.getLongitude(),
        latitude: HiveUtils.getLatitude(),
        country: HiveUtils.getCountryName(),
        state: HiveUtils.getStateName());
  }

  void _toggleExpanded(bool expanded) {
    // Only update if it's different to prevent unnecessary rebuilds
    if (_isExpanded != expanded) {
      setState(() {
        _isExpanded = expanded;
        if (expanded) {
          _preventAutoDismiss = true;
          // Reset the flag after a short delay to allow the widget to stabilize
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _preventAutoDismiss = false;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? MediaQuery.of(context).size.width * 0.7 : MediaQuery.of(context).size.width * 0.55,
      child: _isExpanded ? _buildAutocompleteInput() : _buildLocationDisplay(),
    );
  }

  Widget _buildLocationDisplay() {
    return FittedBox(
      fit: BoxFit.none,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _toggleExpanded(true),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: UiUtils.getSvg(
                AppIcons.location,
                fit: BoxFit.none,
                color: context.color.territoryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "locationLbl".translate(context),
                color: context.color.textColorDark,
                fontSize: context.font.smaller,
              ),
              CustomText(
                _locationController.text.isEmpty ? "------" : _locationController.text,
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                color: context.color.textColorDark,
                fontSize: context.font.smaller,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteInput() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _toggleExpanded(false),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back,
              color: context.color.territoryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.color.borderColor,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LocationAutocomplete(
                controller: _locationController,
                onSelected: (String value) {
                  // Only collapse if not in prevent mode
                  if (!_preventAutoDismiss) {
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (mounted) {
                        _toggleExpanded(false);
                      }
                    });
                  }
                },
                onLocationSelected: (Map<String, String> location) {
                  if (location.isEmpty) return;
                  _refreshData(location);
                  // Only collapse if not in prevent mode
                  if (!_preventAutoDismiss) {
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (mounted) {
                        _toggleExpanded(false);
                      }
                    });
                  }
                },
                hintText: "Search locations...",
              ),
            ),
          ),
        ),
      ],
    );
  }
}
