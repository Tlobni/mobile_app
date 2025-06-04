import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSelected;
  final Function(Map<String, String>)? onLocationSelected;
  final String hintText;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final double? fontSize;
  final Color? borderColor;

  const LocationAutocomplete({
    Key? key,
    required this.controller,
    required this.onSelected,
    this.onLocationSelected,
    this.radius,
    this.padding,
    required this.hintText,
    this.fontSize = 14,
    this.borderColor,
  }) : super(key: key);

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // Updated list of cities with country and state information
  final List<Map<String, String>> _locations = [
    // Saudi Arabia
    {'city': 'Riyadh', 'state': 'Riyadh Province', 'country': 'Saudi Arabia'},
    {'city': 'Jeddah', 'state': 'Makkah Province', 'country': 'Saudi Arabia'},
    {'city': 'Mecca', 'state': 'Makkah Province', 'country': 'Saudi Arabia'},
    {'city': 'Medina', 'state': 'Medina Province', 'country': 'Saudi Arabia'},
    {'city': 'Dammam', 'state': 'Eastern Province', 'country': 'Saudi Arabia'},

    // UAE
    {'city': 'Dubai', 'state': 'Dubai', 'country': 'UAE'},
    {'city': 'Abu Dhabi', 'state': 'Abu Dhabi', 'country': 'UAE'},
    {'city': 'Sharjah', 'state': 'Sharjah', 'country': 'UAE'},
    {'city': 'Ajman', 'state': 'Ajman', 'country': 'UAE'},
    {'city': 'Ras Al Khaimah', 'state': 'Ras Al Khaimah', 'country': 'UAE'},

    // Qatar
    {'city': 'Doha', 'state': '', 'country': 'Qatar'},
    {'city': 'Al Wakrah', 'state': '', 'country': 'Qatar'},
    {'city': 'Al Khor', 'state': '', 'country': 'Qatar'},

    // Oman
    {'city': 'Muscat', 'state': 'Muscat Governorate', 'country': 'Oman'},
    {'city': 'Salalah', 'state': 'Dhofar Governorate', 'country': 'Oman'},
    {'city': 'Sohar', 'state': 'North Al Batinah Governorate', 'country': 'Oman'},

    // Kuwait
    {'city': 'Kuwait City', 'state': 'Al Asimah', 'country': 'Kuwait'},
    {'city': 'Hawalli', 'state': 'Hawalli Governorate', 'country': 'Kuwait'},

    // Lebanon
    {'city': 'Beirut', 'state': 'Beirut Governorate', 'country': 'Lebanon'},
    {'city': 'Tripoli', 'state': 'North Governorate', 'country': 'Lebanon'},
    {'city': 'Sidon', 'state': 'South Governorate', 'country': 'Lebanon'},
    {'city': 'Tyre', 'state': 'South Governorate', 'country': 'Lebanon'},
    {'city': 'Byblos', 'state': 'Mount Lebanon Governorate', 'country': 'Lebanon'},
    {'city': 'Baalbek', 'state': 'Baalbek-Hermel Governorate', 'country': 'Lebanon'},

    // Egypt
    {'city': 'Cairo', 'state': 'Cairo Governorate', 'country': 'Egypt'},
    {'city': 'Alexandria', 'state': 'Alexandria Governorate', 'country': 'Egypt'},
    {'city': 'Giza', 'state': 'Giza Governorate', 'country': 'Egypt'},
    {'city': 'Luxor', 'state': 'Luxor Governorate', 'country': 'Egypt'},

    // Jordan
    {'city': 'Amman', 'state': 'Amman Governorate', 'country': 'Jordan'},
    {'city': 'Zarqa', 'state': 'Zarqa Governorate', 'country': 'Jordan'},
    {'city': 'Irbid', 'state': 'Irbid Governorate', 'country': 'Jordan'},

    // Iraq
    {'city': 'Baghdad', 'state': 'Baghdad Governorate', 'country': 'Iraq'},
    {'city': 'Basra', 'state': 'Basra Governorate', 'country': 'Iraq'},
    {'city': 'Mosul', 'state': 'Nineveh Governorate', 'country': 'Iraq'},
    {'city': 'Erbil', 'state': 'Erbil Governorate', 'country': 'Iraq'},
  ];

  List<Map<String, String>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });

    // If the controller already has text (from edit mode),
    // try to find the location in our list and trigger onLocationSelected
    if (widget.controller.text.isNotEmpty && widget.onLocationSelected != null) {
      final String text = widget.controller.text.toLowerCase();

      // First try to find a matching location from our predefined list
      Map<String, String> matchedLocation = {};
      try {
        matchedLocation = _locations.firstWhere(
          (location) {
            final String cityCountry = "${location['city']}, ${location['country']}".toLowerCase();
            final String countryCity = "${location['country']}, ${location['city']}".toLowerCase();
            return cityCountry.contains(text) || countryCity.contains(text);
          },
          orElse: () => <String, String>{},
        );
      } catch (e) {
        print("Error finding location match: $e");
      }

      // If we found a match, trigger the callbacks with the full data
      if (matchedLocation.isNotEmpty) {
        widget.onLocationSelected!(matchedLocation);
      } else {
        // If no match in predefined locations, try to extract city/country from the text
        // Assuming format is "City, Country" or similar
        final parts = widget.controller.text.split(',');
        if (parts.length >= 2) {
          final city = parts[0].trim();
          final country = parts[1].trim();

          // Create a custom location object for the location that's not in our list
          final customLocation = {
            'city': city,
            'country': country,
            'state': '',
          };

          // Call the callback with our extracted data
          widget.onLocationSelected!(customLocation);
        }
      }
    }

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onLocationSelected?.call({});
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      _filteredLocations = _locations.toList();
    } else {
      _filteredLocations = _locations.where((location) {
        return '${location['city']}, ${location['country']}'.toLowerCase().contains(text.toLowerCase());
      }).toList();
    }

    if (_overlayEntry != null) {
      setState(() {});
      _updateOverlay();
    }
  }

  void _updateOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4.0,
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
              ),
              child: _filteredLocations.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(16),
                      child: DescriptionText(
                        "No locations found",
                        color: theme.hintColor,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        final displayText = "${location['city']}, ${location['country']}";

                        return ListTile(
                          title: DescriptionText(displayText),
                          onTap: () {
                            widget.controller.text = displayText;
                            widget.onSelected(displayText);

                            // Pass the full location data
                            if (widget.onLocationSelected != null) {
                              widget.onLocationSelected!(location);
                            }

                            _hideOverlay();
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = OutlineInputBorder(
      borderRadius: widget.radius ?? BorderRadius.zero,
      borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.withValues(alpha: 0.35)),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: context.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          prefixIcon: Container(
            margin: EdgeInsets.only(left: 10),
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.location_on_outlined,
              color: theme.iconTheme.color,
              size: 18,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 35, maxWidth: 35),
          contentPadding: widget.padding ?? EdgeInsets.only(right: 35),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          fillColor: theme.cardColor,
          filled: true,
        ),
      ),
    );
  }
}
