import 'dart:io';
import 'dart:developer';

import 'package:country_picker/country_picker.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/auth/auth_cubit.dart';
import 'package:tlobni/data/cubits/auth/authentication_cubit.dart';
import 'package:tlobni/data/cubits/slider_cubit.dart';
import 'package:tlobni/data/cubits/system/user_details.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/repositories/category_repository.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/screens/widgets/image_cropper.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/hive_keys.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;
  final AuthenticationType? type;
  final Map<String, dynamic>? extraData;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
    required this.type,
    this.extraData,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return BlurredRouter(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        type: arguments['type'],
        navigateToHome: arguments['navigateToHome'] as bool?,
        extraData: arguments['extraData'],
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Common controllers
  late final TextEditingController phoneController =
      TextEditingController(text: widget.extraData?['email']);
  late final TextEditingController nameController =
      TextEditingController(text: widget.extraData?['username']);
  late final TextEditingController emailController =
      TextEditingController(text: widget.extraData?['email']);
  final TextEditingController addressController = TextEditingController();

  // Additional controllers for different user types
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  dynamic size;
  dynamic city, _state, country;
  double? latitude, longitude;
  String? name, email, address, gender;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";
  String userType = "Client"; // Default type
  String providerType = "Expert"; // Default provider type

  // Categories related fields
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  List<int> _selectedCategoryIds = [];
  List<bool> _expandedPanels = [];
  String? _selectedCategories = "";

  // Track expanded subcategories
  final Set<int> _expandedSubcategories = {};

  @override
  void initState() {
    super.initState();

    // Determine user type
    userType = HiveUtils.getUserType();
    log("Initial user type from Hive: $userType");

    // If Provider, determine provider type (Expert or Business)
    if (userType == "Provider" ||
        userType == "Expert" ||
        userType == "Business") {
      providerType = userType == "Business" ? "Business" : "Expert";
    }

    log("User type: $userType, Provider type: $providerType");

    // Get Hive user data
    var userData = Hive.box(HiveKeys.userDetailsBox).toMap();
    log("Retrieved user data from Hive: $userData");

    // Get user details model
    var userDetails = HiveUtils.getUserDetails();

    // Get location data
    city = HiveUtils.getCityName();
    _state = HiveUtils.getStateName();
    country = HiveUtils.getCountryName();
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();

    // Set email from user details if it's empty
    if (emailController.text.isEmpty) {
      emailController.text = userDetails.email ?? "";
    }

    // Set name based on user type
    if (providerType == "Business") {
      // For business users, use name field for consistency
      if (businessNameController.text.isEmpty) {
        // Get name from userData
        String name = userDetails.name ?? "";
        businessNameController.text = name;
        log("Set business name to: $name");
      }
    } else {
      // For non-business users, use regular name field
      if (nameController.text.isEmpty) {
        nameController.text = userDetails.name ?? "";
      }
    }

    // Set country from user details if it's empty
    if (country == null || country.isEmpty) {
      country = userData['location'] ?? "";
    }

    // Set address from user details if it's empty
    if (addressController.text.isEmpty) {
      addressController.text = userDetails.address ?? "";
    }

    // Handle notification settings
    if (widget.from == "login") {
      isNotificationsEnabled = true;
    } else {
      isNotificationsEnabled =
          HiveUtils.getUserDetails().notification == 1 ? true : false;
    }

    // Handle personal details visibility
    if (widget.from == "login") {
      isPersonalDetailShow = true;
    } else {
      isPersonalDetailShow =
          HiveUtils.getUserDetails().isPersonalDetailShow == 1 ? true : false;
    }

    // Set phone with country code
    if (HiveUtils.getCountryCode() != null) {
      countryCode = (HiveUtils.getCountryCode() != null
          ? HiveUtils.getCountryCode()!
          : "");
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!.replaceFirst("+$countryCode", "")
          : "";
    } else {
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!
          : "";
    }

    // Set gender
    gender = userData['gender'];
    genderController.text = gender ?? "";

    // Load categories for Provider users
    if (userType == "Provider" ||
        userType == "Expert" ||
        userType == "Business") {
      _fetchCategories();

      // Get stored categories - handle both string and list formats
      var categoriesData = userData['categories'];
      if (categoriesData != null) {
        if (categoriesData is String) {
          // Handle string format (comma-separated)
          _selectedCategories = categoriesData;
          if (_selectedCategories!.isNotEmpty) {
            _selectedCategoryIds = _selectedCategories!
                .split(',')
                .map((id) => int.tryParse(id.trim()) ?? 0)
                .where((id) => id > 0)
                .toList();
          }
        } else if (categoriesData is List) {
          // Handle list format
          _selectedCategoryIds = [];
          for (var item in categoriesData) {
            int? id = item is int ? item : int.tryParse(item.toString());
            if (id != null && id > 0) {
              _selectedCategoryIds.add(id);
            }
          }
          // Convert to string format for consistency
          _selectedCategories = _selectedCategoryIds.isNotEmpty
              ? _selectedCategoryIds.map((id) => id.toString()).join(',')
              : "";
        }
        log("Loaded categories: $_selectedCategoryIds");
      } else {
        _selectedCategories = "";
        _selectedCategoryIds = [];
      }
    }

    // Log loaded field values for debugging
    log("Fields after init: email=${emailController.text}, name=${nameController.text}, business=${businessNameController.text}, country=$country, gender=$gender");
  }

  // Fetch categories from repository
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final CategoryRepository categoryRepository = CategoryRepository();
      final result = await categoryRepository.fetchCategories(
          page: 1, type: CategoryType.providers);

      setState(() {
        _categories = result.modelList
            .where((category) => category.type == CategoryType.providers)
            .toList();
        _expandedPanels = List.generate(_categories.length, (_) => false);
        _isLoadingCategories = false;
      });
    } catch (e) {
      log('Error fetching categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    // Get user type directly from Hive again to ensure it's current
    userType = HiveUtils.getUserType();
    log("Current user type in build method: $userType");

    // Debug check to ensure we actually have a user type
    if (userType.isEmpty) {
      log("WARNING: User type is empty, defaulting to Client for UI");
      userType = "Client"; // Fallback to ensure UI shows something
    }

    // Make sure providerType is also updated
    if (userType == "Provider" ||
        userType == "Expert" ||
        userType == "Business") {
      providerType = userType == "Business" ? "Business" : "Expert";
    }

    log("Building UI with userType: $userType, providerType: $providerType");

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: safeAreaCondition(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: widget.from == "login"
              ? null
              : UiUtils.buildAppBar(context, showBackButton: true),
          body: Stack(
            children: [
              ScrollConfiguration(
                behavior: RemoveGlow(),
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                          key: _formKey,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Align(
                                  alignment: AlignmentDirectional.center,
                                  child: buildProfilePicture(),
                                ),

                                // ALWAYS show the profile fields regardless of user type detection issues
                                providerType == "Business"
                                    ? _buildBusinessFields()
                                    : providerType == "Expert"
                                        ? _buildExpertFields()
                                        : _buildClientFields(),

                                // Common fields and buttons
                                SizedBox(height: 10),
                                CustomText("notification".translate(context)),
                                SizedBox(height: 10),
                                buildNotificationEnableDisableSwitch(context),
                                SizedBox(height: 10),
                                CustomText(
                                    "showContactInfo".translate(context)),
                                SizedBox(height: 10),
                                buildPersonalDetailEnableDisableSwitch(context),
                                SizedBox(height: 25),
                                UiUtils.buildButton(
                                  context,
                                  onPressed: () {
                                    if (widget.from == 'login') {
                                      validateData();
                                    } else {
                                      if (city != null && city != "") {
                                        HiveUtils.setCurrentLocation(
                                            city: city,
                                            state: _state,
                                            country: country,
                                            latitude: latitude,
                                            longitude: longitude);

                                        context
                                            .read<SliderCubit>()
                                            .fetchSlider(context);
                                      } else {
                                        HiveUtils.clearLocation();

                                        context
                                            .read<SliderCubit>()
                                            .fetchSlider(context);
                                      }
                                      validateData();
                                    }
                                  },
                                  height: 48,
                                  buttonTitle:
                                      "updateProfile".translate(context),
                                )
                              ])),
                    )),
              ),
              if (isLoading != null && isLoading!)
                Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
              if (widget.from == 'login')
                Positioned(
                  left: 10,
                  top: 10,
                  child: BackButton(),
                )
            ],
          ),
        ),
      ),
    );
  }

  // Client fields
  Widget _buildClientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        buildTextField(
          context,
          title: "fullName",
          controller: nameController,
          validator: CustomTextFieldValidator.nullCheck,
        ),

        // Email Address
        buildTextField(
          context,
          readOnly: HiveUtils.getUserDetails().type ==
                      AuthenticationType.email.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.google.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.apple.name
              ? true
              : false,
          title: "emailAddress",
          controller: emailController,
          validator: CustomTextFieldValidator.email,
        ),

        // Gender
        _buildGenderDropdown(
          context,
          value: gender,
          onChanged: (val) => setState(() => gender = val),
          label: "Gender",
        ),

        // Country Selection
        _buildCountrySelector(
          context,
          value: country,
          onChanged: (val) => setState(() => country = val),
          label: "Country",
        ),

        // Location/City
        buildAddressTextField(
          context,
          title: "addressLbl",
          controller: addressController,
        ),
      ],
    );
  }

  // Expert fields
  Widget _buildExpertFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        buildTextField(
          context,
          title: "fullName",
          controller: nameController,
          validator: CustomTextFieldValidator.nullCheck,
        ),

        // Email Address
        buildTextField(
          context,
          readOnly: HiveUtils.getUserDetails().type ==
                      AuthenticationType.email.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.google.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.apple.name
              ? true
              : false,
          title: "emailAddress",
          controller: emailController,
          validator: CustomTextFieldValidator.email,
        ),

        // Gender
        _buildGenderDropdown(
          context,
          value: gender,
          onChanged: (val) => setState(() => gender = val),
          label: "Gender",
        ),

        // Country Selection
        _buildCountrySelector(
          context,
          value: country,
          onChanged: (val) => setState(() => country = val),
          label: "Country",
        ),

        // Phone
        phoneWidget(),

        // Location/City
        buildAddressTextField(
          context,
          title: "addressLbl",
          controller: addressController,
        ),

        // Categories
        if (!_isLoadingCategories) _buildCategoryMultiSelect(),
      ],
    );
  }

  // Business fields
  Widget _buildBusinessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Name - renamed to Name for consistency
        buildTextField(
          context,
          title: "Name",
          controller: businessNameController,
          validator: CustomTextFieldValidator.nullCheck,
        ),

        // Email Address
        buildTextField(
          context,
          readOnly: HiveUtils.getUserDetails().type ==
                      AuthenticationType.email.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.google.name ||
                  HiveUtils.getUserDetails().type ==
                      AuthenticationType.apple.name
              ? true
              : false,
          title: "emailAddress",
          controller: emailController,
          validator: CustomTextFieldValidator.email,
        ),

        // Country Selection
        _buildCountrySelector(
          context,
          value: country,
          onChanged: (val) => setState(() => country = val),
          label: "Country",
        ),

        // Phone
        phoneWidget(),

        // Location/City
        buildAddressTextField(
          context,
          title: "addressLbl",
          controller: addressController,
        ),

        // Categories
        if (!_isLoadingCategories) _buildCategoryMultiSelect(),
      ],
    );
  }

  // Gender dropdown
  Widget _buildGenderDropdown(
    BuildContext context, {
    required String? value,
    required Function(String?) onChanged,
    required String label,
  }) {
    final items = <String>["Male", "Female"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        CustomText(label),
        SizedBox(height: 10),
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: value ?? label,
          readOnly: true,
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map((gender) => ListTile(
                          title: Text(gender),
                          onTap: () {
                            onChanged(gender);
                            Navigator.pop(context);
                          },
                          selected: gender == value,
                        ))
                    .toList(),
              ),
            );
          },
          controller: TextEditingController(text: value),
          suffix: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }

  // Country selector
  Widget _buildCountrySelector(
    BuildContext context, {
    required String? value,
    required Function(String?) onChanged,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        CustomText(label),
        SizedBox(height: 10),
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: value ?? label,
          readOnly: true,
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: false,
              countryListTheme: CountryListThemeData(
                borderRadius: BorderRadius.circular(11),
                searchTextStyle: TextStyle(
                  color: context.color.textColorDark,
                  fontSize: 16,
                ),
              ),
              countryFilter: [
                'SA', // Saudi Arabia
                'AE', // United Arab Emirates
                'QA', // Qatar
                'OM', // Oman
                'KW', // Kuwait
                'LB', // Lebanon
                'EG', // Egypt
                'JO', // Jordan
                'IQ', // Iraq
              ],
              onSelect: (Country country) {
                onChanged(country.name);
              },
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: value),
        ),
      ],
    );
  }

  // Categories multi-select
  Widget _buildCategoryMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const CustomText(
          "Categories",
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCategorySelectionDialog(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.color.borderColor.darken(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryIds.isEmpty
                        ? "Choose Categories"
                        : "${_selectedCategoryIds.length} categories selected",
                    style: TextStyle(
                      color: _selectedCategoryIds.isEmpty
                          ? context.color.textColorDark.withOpacity(0.5)
                          : context.color.textColorDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: context.color.textColorDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Show category selection dialog
  void _showCategorySelectionDialog() {
    // Search controller
    final TextEditingController searchController = TextEditingController();
    // Track filtered categories
    List<CategoryModel> filteredCategories = [];
    // Track expanded panels in the dialog
    List<bool> dialogExpandedPanels = [];
    // Track loading state
    bool isDialogLoading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          // Load categories when dialog opens
          if (isDialogLoading) {
            _loadCategoriesForDialog(
                    setState, filteredCategories, dialogExpandedPanels)
                .then((_) {
              setState(() {
                isDialogLoading = false;
              });
            });
          }

          // Filter function
          void filterCategories(String query) {
            if (query.isEmpty) {
              setState(() {
                // Only include categories with type 'providers'
                filteredCategories = _categories
                    .where(
                        (category) => category.type == CategoryType.providers)
                    .toList();
              });
              return;
            }

            query = query.toLowerCase();
            setState(() {
              // First check main categories, but only those with type 'providers'
              filteredCategories = _categories.where((category) {
                // Only include categories with type 'providers'
                if (category.type != CategoryType.providers) {
                  return false;
                }

                final matchesMainCategory =
                    category.name?.toLowerCase().contains(query) ?? false;

                // Check if any subcategory matches
                final hasMatchingSubcategory = category.children?.any(
                        (subcategory) =>
                            subcategory.name?.toLowerCase().contains(query) ??
                            false) ??
                    false;

                return matchesMainCategory || hasMatchingSubcategory;
              }).toList();

              // Auto-expand categories with matching subcategories
              for (int i = 0; i < filteredCategories.length; i++) {
                final category = filteredCategories[i];
                final originalIndex = _categories.indexOf(category);
                final hasSubcategories =
                    category.children != null && category.children!.isNotEmpty;

                final hasMatchingSubcategory = category.children?.any(
                        (subcategory) =>
                            subcategory.name?.toLowerCase().contains(query) ??
                            false) ??
                    false;

                if (hasMatchingSubcategory) {
                  dialogExpandedPanels[_categories.indexOf(category)] = true;
                }
              }
            });
          }

          return Dialog(
            insetPadding: EdgeInsets.zero, // Remove default padding
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // Header with title and close button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      border: Border(
                        bottom: BorderSide(
                          color: context.color.borderColor.darken(10),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            "Select Categories",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Update the main state with selected categories
                            this.setState(() {});
                            Navigator.of(context).pop();
                          },
                          child: const Text("Done"),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search categories or subcategories",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                      onChanged: filterCategories,
                    ),
                  ),

                  // Loading indicator or categories list
                  Expanded(
                    child: isDialogLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredCategories.isEmpty
                            ? const Center(
                                child: Text("No matching categories found"))
                            : ListView.builder(
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = filteredCategories[index];
                                  final originalIndex =
                                      _categories.indexOf(category);
                                  final hasSubcategories =
                                      category.children != null &&
                                          category.children!.isNotEmpty;

                                  return Column(
                                    children: [
                                      // Parent category
                                      Container(
                                        decoration: BoxDecoration(
                                          color: context.color.secondaryColor,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: context.color.borderColor
                                                  .darken(10),
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
                                            value: _isCategorySelected(
                                                category.id ?? 0),
                                            onChanged: (bool? value) {
                                              if (category.id != null) {
                                                setState(() {
                                                  if (value == true) {
                                                    if (!_selectedCategoryIds
                                                        .contains(
                                                            category.id!)) {
                                                      _selectedCategoryIds
                                                          .add(category.id!);
                                                    }

                                                    // Also select all subcategories
                                                    if (hasSubcategories) {
                                                      for (var subcategory
                                                          in category
                                                              .children!) {
                                                        if (subcategory.id !=
                                                                null &&
                                                            !_selectedCategoryIds
                                                                .contains(
                                                                    subcategory
                                                                        .id!)) {
                                                          _selectedCategoryIds
                                                              .add(subcategory
                                                                  .id!);
                                                        }
                                                      }
                                                    }
                                                  } else {
                                                    _selectedCategoryIds
                                                        .remove(category.id!);

                                                    // Also deselect all subcategories
                                                    if (hasSubcategories) {
                                                      for (var subcategory
                                                          in category
                                                              .children!) {
                                                        if (subcategory.id !=
                                                            null) {
                                                          _selectedCategoryIds
                                                              .remove(
                                                                  subcategory
                                                                      .id!);
                                                        }
                                                      }
                                                    }
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                          // Only show trailing arrow if there are subcategories
                                          trailing: hasSubcategories
                                              ? Icon(
                                                  dialogExpandedPanels[
                                                          originalIndex]
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  color: context
                                                      .color.textColorDark,
                                                )
                                              : null,
                                          // Make the entire row clickable to expand/collapse if it has subcategories
                                          onTap: hasSubcategories
                                              ? () {
                                                  setState(() {
                                                    dialogExpandedPanels[
                                                            originalIndex] =
                                                        !dialogExpandedPanels[
                                                            originalIndex];
                                                  });
                                                }
                                              : null,
                                        ),
                                      ),

                                      // Subcategories (if expanded and has subcategories)
                                      if (hasSubcategories &&
                                          dialogExpandedPanels[originalIndex])
                                        Container(
                                          color: context.color.secondaryColor
                                              .withOpacity(0.5),
                                          child: Column(
                                            children: category.children!
                                                .map((subcategory) {
                                              // Filter subcategories if search is active
                                              if (searchController
                                                  .text.isNotEmpty) {
                                                final query = searchController
                                                    .text
                                                    .toLowerCase();
                                                if (!(subcategory.name
                                                        ?.toLowerCase()
                                                        .contains(query) ??
                                                    false)) {
                                                  return Container(); // Skip non-matching subcategories
                                                }
                                              }

                                              final hasNestedSubcategories =
                                                  subcategory.children !=
                                                          null &&
                                                      subcategory
                                                          .children!.isNotEmpty;

                                              return Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 20.0),
                                                    child: ListTile(
                                                      title: Text(
                                                          subcategory.name ??
                                                              "Unknown"),
                                                      leading: Checkbox(
                                                        value:
                                                            _isCategorySelected(
                                                                subcategory
                                                                        .id ??
                                                                    0),
                                                        onChanged:
                                                            (bool? value) {
                                                          if (subcategory.id !=
                                                              null) {
                                                            setState(() {
                                                              if (value ==
                                                                  true) {
                                                                if (!_selectedCategoryIds
                                                                    .contains(
                                                                        subcategory
                                                                            .id!)) {
                                                                  _selectedCategoryIds.add(
                                                                      subcategory
                                                                          .id!);
                                                                }
                                                              } else {
                                                                _selectedCategoryIds
                                                                    .remove(
                                                                        subcategory
                                                                            .id!);
                                                              }
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  // Nested subcategories
                                                  if (hasNestedSubcategories &&
                                                      _isSubcategoryExpanded(
                                                          subcategory.id ?? 0))
                                                    Container(
                                                      color: context
                                                          .color.secondaryColor
                                                          .withOpacity(0.3),
                                                      child: Column(
                                                        children: subcategory
                                                            .children!
                                                            .map((subcategory) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 40.0),
                                                            child: ListTile(
                                                              title: Text(
                                                                  subcategory
                                                                          .name ??
                                                                      "Unknown"),
                                                              leading: Checkbox(
                                                                value: _isCategorySelected(
                                                                    subcategory
                                                                            .id ??
                                                                        0),
                                                                onChanged:
                                                                    (bool?
                                                                        value) {
                                                                  if (subcategory
                                                                          .id !=
                                                                      null) {
                                                                    setState(
                                                                        () {
                                                                      if (value ==
                                                                          true) {
                                                                        if (!_selectedCategoryIds
                                                                            .contains(subcategory.id!)) {
                                                                          _selectedCategoryIds
                                                                              .add(subcategory.id!);
                                                                        }
                                                                      } else {
                                                                        _selectedCategoryIds
                                                                            .remove(subcategory.id!);
                                                                      }
                                                                    });
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
                              ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Helper function to check if a category is selected
  bool _isCategorySelected(int categoryId) {
    return _selectedCategoryIds.contains(categoryId);
  }

  // Load categories for dialog
  Future<void> _loadCategoriesForDialog(
    StateSetter setState,
    List<CategoryModel> filteredCategories,
    List<bool> dialogExpandedPanels,
  ) async {
    try {
      final CategoryRepository categoryRepository = CategoryRepository();
      final result = await categoryRepository.fetchCategories(
          page: 1, type: CategoryType.providers);

      setState(() {
        _categories = result.modelList;
        filteredCategories.addAll(_categories
            .where((category) => category.type == CategoryType.providers)
            .toList());
        dialogExpandedPanels
            .addAll(List.generate(_categories.length, (_) => false));
        _expandedPanels = List.generate(_categories.length, (_) => false);
        _isLoadingCategories = false;
      });
    } catch (e) {
      log('Error fetching categories in dialog: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Widget phoneWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 10,
      ),
      CustomText(
        "phoneNumber".translate(context),
        color: context.color.textDefaultColor,
      ),
      SizedBox(
        height: 10,
      ),
      CustomTextFormField(
        controller: phoneController,
        validator: CustomTextFieldValidator.phoneNumber,
        keyboard: TextInputType.phone,
        isReadOnly:
            HiveUtils.getUserDetails().type == AuthenticationType.phone.name
                ? true
                : false,
        fillColor: context.color.secondaryColor,
        // borderColor: context.color.borderColor.darken(10),
        onChange: (value) {
          setState(() {});
        },
        isMobileRequired: false,
        fixedPrefix: SizedBox(
          width: 55,
          child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () {
                  if (HiveUtils.getUserDetails().type !=
                      AuthenticationType.phone.name) {
                    showCountryCode();
                  }
                },
                child: Container(
                    // color: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8),
                    child: Center(
                      child: CustomText(
                        formatCountryCode(countryCode!),
                        fontSize: context.font.large,
                        textAlign: TextAlign.center,
                      ),
                    )),
              )),
        ),
        hintText: "phoneNumber".translate(context),
      )
    ]);
  }

  String formatCountryCode(String countryCode) {
    if (!countryCode.startsWith('+')) {
      return '+$countryCode';
    }
    return countryCode;
  }

  Widget safeAreaCondition({required Widget child}) {
    if (widget.from == "login") {
      return SafeArea(child: child);
    }
    return child;
  }

  Widget buildNotificationEnableDisableSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: context.color.borderColor.darken(40),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: context.color.secondaryColor),
      height: 60,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomText(
              (isNotificationsEnabled
                      ? "enabled".translate(context)
                      : "disabled".translate(context))
                  .translate(context),
              fontSize: context.font.large,
              color: context.color.textDefaultColor,
            ),
          ),
          CupertinoSwitch(
            activeColor: context.color.territoryColor,
            value: isNotificationsEnabled,
            onChanged: (value) {
              isNotificationsEnabled = value;
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Widget buildPersonalDetailEnableDisableSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: context.color.borderColor.darken(40),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: context.color.secondaryColor),
      height: 60,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomText(
                (isPersonalDetailShow
                        ? "enabled".translate(context)
                        : "disabled".translate(context))
                    .translate(context),
                fontSize: context.font.large,
              )),
          CupertinoSwitch(
            activeColor: context.color.territoryColor,
            value: isPersonalDetailShow,
            onChanged: (value) {
              isPersonalDetailShow = value;
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Widget buildTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        SizedBox(
          height: 10,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          // formaters: [FilteringTextInputFormatter.deny(RegExp(","))],
          fillColor: context.color.secondaryColor,
        ),
      ],
    );
  }

  Widget buildAddressTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(title.translate(context)),
        SizedBox(
          height: 10,
        ),
        LocationAutocomplete(
          controller: controller,
          hintText: "enterLocation".translate(context),
          onSelected: (value) {
            // Do nothing here, since the controller is updated by the widget
          },
          onLocationSelected: (locationData) {
            // Use post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                city = locationData['city'];
                _state = locationData['state'];
                country = locationData['country'];

                print("Location updated to: ${controller.text}");
                print("City: $city, State: $_state, Country: $country");
              });
            });
          },
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(
        fileUserimg!,
        fit: BoxFit.cover,
      );
    } else {
      if (widget.from == "login") {
        if (HiveUtils.getUserDetails().profile != "" &&
            HiveUtils.getUserDetails().profile != null) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        if ((HiveUtils.getUserDetails().profile ?? "").isEmpty) {
          return UiUtils.getSvg(
            AppIcons.defaultPersonLogo,
            color: context.color.territoryColor,
            fit: BoxFit.none,
          );
        } else {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: context.color.territoryColor, width: 2)),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
                height: 37,
                width: 37,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    border: Border.all(
                        color: context.color.buttonColor, width: 1.5),
                    shape: BoxShape.circle,
                    color: context.color.territoryColor),
                child: SizedBox(
                    width: 15,
                    height: 15,
                    child: UiUtils.getSvg(AppIcons.edit))),
          ),
        )
      ],
    );
  }

  void showPicker() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10)),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: CustomText("gallery".translate(context)),
                    onTap: () {
                      _imgFromGallery(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: CustomText("camera".translate(context)),
                  onTap: () {
                    _imgFromGallery(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                if (fileUserimg != null && widget.from == 'login')
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: CustomText("lblremove".translate(context)),
                    onTap: () {
                      fileUserimg = null;

                      Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
              ],
            ),
          );
        });
  }

  void _imgFromGallery(ImageSource imageSource) async {
    CropImage.init(context);

    final pickedFile = await ImagePicker().pickImage(source: imageSource);

    if (pickedFile != null) {
      CroppedFile? croppedFile;
      croppedFile = await CropImage.crop(
        filePath: pickedFile.path,
      );
      if (croppedFile == null) {
        fileUserimg = null;
      } else {
        fileUserimg = File(croppedFile.path);
      }
    } else {
      fileUserimg = null;
    }
    setState(() {});
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
          CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (widget.from == 'login') {
        HiveUtils.setUserIsAuthenticated(true);
      }
      profileUpdateProcess();
    }
  }

  void profileUpdateProcess() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Debug output of current state before update
      log("BEFORE UPDATE - userType: $userType, providerType: $providerType");

      // Convert selected categories to string (comma-separated)
      final String categoriesString = _selectedCategoryIds.isEmpty
          ? ""
          : _selectedCategoryIds.map((id) => id.toString()).join(',');

      // Prepare update data
      Map<String, dynamic> additionalParams = {};

      // Store user type and provider type to ensure they're preserved
      // Use providerType for more specific type if it's a business or expert
      if (providerType == "Business") {
        additionalParams['type'] = "Business";
      } else if (providerType == "Expert") {
        additionalParams['type'] = "Expert";
      } else {
        additionalParams['type'] = userType;
      }

      log("Setting type in additionalParams: ${additionalParams['type']}");

      // Add type specific fields
      if (userType == "Provider" ||
          userType == "Expert" ||
          userType == "Business") {
        // Save categories as a string for consistency with the API
        additionalParams['categories'] = categoriesString;

        if (providerType == "Business") {
          // No need to store businessName separately anymore
        } else {
          additionalParams['gender'] = gender;
        }
      } else {
        // Client specific fields
        additionalParams['gender'] = gender;
      }

      // Add location data
      additionalParams['country'] = country;

      log('Updating profile with data: ${nameController.text}, business name: ${providerType == "Business" ? businessNameController.text.trim() : "N/A"}, categories: $categoriesString, userType: $userType');

      var response;

      // For all user types, use the appropriate name field but send it as "name"
      if (providerType == "Business") {
        response = await context.read<AuthCubit>().updateuserdata(context,
            name: businessNameController.text.trim(),
            email: emailController.text.trim(),
            fileUserimg: fileUserimg,
            address: addressController.text,
            mobile: phoneController.text,
            notification: isNotificationsEnabled == true ? "1" : "0",
            countryCode: countryCode,
            personalDetail: isPersonalDetailShow == true ? 1 : 0,
            country: country,
            categories: categoriesString);
      } else {
        // For non-business users, use the regular name field
        response = await context.read<AuthCubit>().updateuserdata(
              context,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              fileUserimg: fileUserimg,
              address: addressController.text,
              mobile: phoneController.text,
              notification: isNotificationsEnabled == true ? "1" : "0",
              countryCode: countryCode,
              personalDetail: isPersonalDetailShow == true ? 1 : 0,
              country: country,
              categories: categoriesString,
            );
      }

      // After successful update, also store the additional params that weren't handled by AuthCubit
      if (response["status"] == true) {
        // Get current user data
        var userData = HiveUtils.getUserDetails();
        Map<String, dynamic> updatedUserData = userData.toJson();

        log("BEFORE ADDITIONAL PARAMS - userData: $updatedUserData");

        // Update with additional parameters
        updatedUserData.addAll(additionalParams);

        log("AFTER ADDITIONAL PARAMS - userData: $updatedUserData");

        // Make sure proper name field is set based on user type
        if (providerType == "Business") {
          // For business users, ensure name is properly set
          if (updatedUserData['name'] == null ||
              updatedUserData['name'] == "") {
            updatedUserData['name'] = businessNameController.text.trim();
          }
        } else {
          // For regular users, ensure name is properly set
          if (updatedUserData['name'] == null ||
              updatedUserData['name'] == "") {
            updatedUserData['name'] = nameController.text.trim();
          }
        }

        // Make sure email isn't empty
        if (updatedUserData['email'] == null ||
            updatedUserData['email'] == "") {
          updatedUserData['email'] = emailController.text.trim();
        }

        // Make sure location/country isn't empty
        if (updatedUserData['location'] == null ||
            updatedUserData['location'] == "") {
          updatedUserData['location'] = country;
        }

        // Save back to Hive
        log('FINAL user data being saved to Hive: $updatedUserData');
        HiveUtils.setUserData(updatedUserData);
      }

      Future.delayed(
        Duration.zero,
        () {
          context
              .read<UserDetailsCubit>()
              .copy(UserModel.fromJson(response['data']));
        },
      );

      Future.delayed(
        Duration.zero,
        () {
          setState(() {
            isLoading = false;
          });
          HelperUtils.showSnackBarMessage(
            context,
            response['message'],
          );
          if (widget.from != "login") {
            Navigator.pop(context);
          }
        },
      );

      if (widget.from == "login" && widget.popToCurrent != true) {
        Future.delayed(
          Duration.zero,
          () {
            if (HiveUtils.getCityName() != null &&
                HiveUtils.getCityName() != "") {
              HelperUtils.killPreviousPages(
                  context, Routes.main, {"from": widget.from});
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.locationPermissionScreen, (route) => false);
            }
          },
        );
      } else if (widget.from == "login" && widget.popToCurrent == true) {
        Future.delayed(Duration.zero, () {
          Navigator.of(context)
            ..pop()
            ..pop();
        });
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        setState(() {
          isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString());
      });
    }
  }

  // Track expanded subcategories
  bool _isSubcategoryExpanded(int subcategoryId) {
    return _expandedSubcategories.contains(subcategoryId);
  }

  void _toggleSubcategoryExpansion(int subcategoryId) {
    setState(() {
      if (_isSubcategoryExpanded(subcategoryId)) {
        _expandedSubcategories.remove(subcategoryId);
      } else {
        _expandedSubcategories.add(subcategoryId);
      }
    });
  }

  void _selectAllNestedSubcategories(CategoryModel category) {
    if (category.children != null) {
      for (var subcategory in category.children!) {
        if (subcategory.id != null) {
          _selectedCategoryIds.add(subcategory.id!);
          _selectAllNestedSubcategories(subcategory);
        }
      }
    }
  }

  void _deselectAllNestedSubcategories(CategoryModel category) {
    if (category.children != null) {
      for (var subcategory in category.children!) {
        if (subcategory.id != null) {
          _selectedCategoryIds.remove(subcategory.id!);
          _deselectAllNestedSubcategories(subcategory);
        }
      }
    }
  }
}
