import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/auth/authentication_cubit.dart';
import 'package:tlobni/data/cubits/system/app_theme_cubit.dart';
import 'package:tlobni/data/repositories/auth_repository.dart';
import 'package:tlobni/data/repositories/category_repository.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/ui/screens/auth/sign_up/email_verification_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/login/lib/payloads.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class SignupScreen extends StatefulWidget {
  final String? emailId;
  final String? userType; // 'Provider' or 'Client'
  final String?
      providerType; // 'Expert' or 'Business' (only if userType is 'Provider')

  const SignupScreen({
    super.key,
    this.emailId,
    this.userType,
    this.providerType,
  });

  static BlurredRouter route(RouteSettings settings) {
    Map? args = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SignupScreen(
          emailId: args?['emailId'],
          userType: args?['userType'],
          providerType: args?['providerType'],
        );
      },
    );
  }

  @override
  CloudState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends CloudState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  // Existing email & password controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ----- New fields required by the specs ------
  // Common toggles
  String _userType = 'Provider'; // 'Provider' or 'Client' (default Provider)
  String _providerType = 'Expert'; // 'Expert' or 'Business' (default Expert)
  bool isObscure = true;
  bool _isLoading = false; // Loading state for signup process

  // Expert fields
  final TextEditingController _expertFullNameController =
      TextEditingController();
  String? _expertGender; // example: 'Male','Female'
  String? _expertCountry; // Store selected country name
  final TextEditingController _expertLocationController =
      TextEditingController();
  final TextEditingController _expertPhoneController = TextEditingController();

  // Business fields
  final TextEditingController _businessNameController = TextEditingController();
  String? _businessCountry; // Store selected country name
  final TextEditingController _businessLocationController =
      TextEditingController();
  final TextEditingController _businessPhoneController =
      TextEditingController();

  // Client fields
  final TextEditingController _clientFullNameController =
      TextEditingController();
  String? _clientGender;
  String? _clientCountry; // Store selected country name
  final TextEditingController _clientLocationController =
      TextEditingController();

  // Categories
  // Replace hardcoded categories with fetched categories
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  // We'll store the user's selected categories and subcategories
  List<int> _selectedCategoryIds = [];
  // Track which panels are expanded
  List<bool> _expandedPanels = [];

  // Add the _showCategoryError flag to the state class
  bool _showCategoryError = false;

  // Add these new methods to the class
  // Track expanded subcategories
  final Set<int> _expandedSubcategories = {};

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

  @override
  void initState() {
    super.initState();

    // Set initial user type and provider type based on selection from account type screen
    if (widget.userType != null) {
      _userType = widget.userType!;

      // Only set provider type if user type is 'Provider'
      if (_userType == 'Provider' && widget.providerType != null) {
        _providerType = widget.providerType!;
      } else if (_userType == 'Client') {
        // Clear provider type for Client users
        _providerType = '';
      }
    }

    // If an email is passed in, pre-populate:
    if (widget.emailId?.isNotEmpty ?? false) {
      _emailController.text = widget.emailId!;
    }

    // Fetch categories when the screen initializes
    _fetchCategories();
  }

  // Fetch categories from the repository
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final CategoryRepository categoryRepository = CategoryRepository();
      // Fetch only provider categories for sign up page
      final result = await categoryRepository.fetchCategories(
          page: 1, type: CategoryType.providers);

      log(result.toString());

      setState(() {
        // Only store categories with type 'providers'
        _categories = result.modelList
            .where((category) => category.type == CategoryType.providers)
            .toList();
        // Initialize expanded state for each category
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

  // Check if a category or subcategory is selected
  bool _isCategorySelected(int categoryId) {
    return _selectedCategoryIds.contains(categoryId);
  }

  // Toggle selection of a category or subcategory
  void _toggleCategorySelection(int categoryId) {
    setState(() {
      if (_isCategorySelected(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  void dispose() {
    // Dispose of new controllers
    _expertFullNameController.dispose();
    _expertLocationController.dispose();
    _expertPhoneController.dispose();
    _businessNameController.dispose();
    _businessLocationController.dispose();
    _businessPhoneController.dispose();
    _clientFullNameController.dispose();
    _clientLocationController.dispose();

    // Existing
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onTapSignup() async {
    setState(() {
      _showCategoryError = false; // Reset error state
    });

    if (_formKey.currentState?.validate() ?? false) {
      // Additional validation for required fields based on account type
      if (_userType == "Provider" && _selectedCategoryIds.isEmpty) {
        // Show error for categories field
        setState(() {
          _showCategoryError = true;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare categories as a string
        final String categoriesString = _userType == "Provider"
            ? _selectedCategoryIds.map((id) => id.toString()).join(',')
            : "";

        log('Categories as string: $categoriesString');

        // Get name based on user type
        String name = "";
        if (_userType == "Provider") {
          name = _providerType == "Expert"
              ? _expertFullNameController.text.trim()
              : _businessNameController.text.trim();
        } else {
          name = _clientFullNameController.text.trim();
        }

        // Collect all user data
        final userData = {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'type': _userType == "Provider"
              ? (_providerType == "Expert" ? "Expert" : "Business")
              : "Client",
          'userType': _userType,
          'providerType': _userType == "Provider" ? _providerType : null,
          'fullName': name, // Use name for all user types
          'name': name, // Add name parameter for API consistency
          'gender': _userType == "Provider" && _providerType == "Expert"
              ? _expertGender
              : _clientGender,
          'location': _userType == "Provider"
              ? (_providerType == "Expert"
                  ? _expertCountry ?? ""
                  : _businessCountry ?? "")
              : _clientCountry ?? "",
          'city': _userType == "Provider"
              ? (_providerType == "Expert"
                  ? _expertLocationController.text.trim()
                  : _businessLocationController.text.trim())
              : _clientLocationController.text.trim(),
          'categories': categoriesString,
          'phone': _userType == "Provider"
              ? (_providerType == "Expert"
                  ? _expertPhoneController.text.trim()
                  : _businessPhoneController.text.trim())
              : null,
          'platform_type': Platform.isAndroid ? "android" : "ios",
        };

        // Add debug log to show what is being sent to the API
        log('Signup request data: ${userData.toString()}');

        // Call signup API directly
        final response = await Api.post(
          url: Api.loginApi,
          parameter: userData,
        );

        if (response["status"] == true) {
          // Store token
          if (response.containsKey("token")) {
            HiveUtils.setJWT(response["token"]);
          }

          // Store user data
          final userData = response.containsKey("user")
              ? response["user"]
              : response["data"];

          // Determine the correct user type for storage
          String userTypeForStorage = _userType;
          if (_userType == "Provider") {
            userTypeForStorage = _providerType; // Either "Expert" or "Business"
          }

          log("Setting user type to: $userTypeForStorage");

          // Get name consistently based on user type
          String nameForStorage = name;

          HiveUtils.setUserData({
            'id': userData?["id"] != null
                ? int.parse(userData["id"].toString())
                : 0,
            'name': userData?["name"] ?? nameForStorage,
            'email': userData?["email"] ?? _emailController.text.trim(),
            'mobile': _userType == "Provider"
                ? (_providerType == "Expert"
                    ? _expertPhoneController.text.trim()
                    : _businessPhoneController.text.trim())
                : null,
            'profile': userData?["profile"] ?? "",
            'type':
                userTypeForStorage, // Use our explicit userTypeForStorage instead of roles
            'firebaseId': userData?["firebase_id"] ?? "",
            'fcmId': userData?["fcm_id"] ?? "",
            'notification': userData?["notification"] ?? 1,
            'address': userData?["address"] ?? "",
            'categories': categoriesString,
            'phone': _userType == "Provider"
                ? (_providerType == "Expert"
                    ? _expertPhoneController.text.trim()
                    : _businessPhoneController.text.trim())
                : null,
            'gender': _userType == "Provider" && _providerType == "Expert"
                ? _expertGender
                : _clientGender,
            'location': _userType == "Provider"
                ? (_providerType == "Expert"
                    ? _expertCountry ?? ""
                    : _businessCountry ?? "")
                : _clientCountry ?? "",
            'countryCode': "",
            'isProfileCompleted': true,
            'showPersonalDetails': 1,
            'autoApproveItem': true,
            'isVerified': true,
          });

          // Set user as authenticated
          HiveUtils.setUserIsAuthenticated(true);

          setState(() {
            _isLoading = false;
          });

          // Navigate based on user type
          final userRole = _userType;
          log('User type for navigation: $userRole');

          if (userRole == "Provider") {
            // Only Providers (Expert or Business) should see subscription packages
            log('Navigating Provider to main and subscription package');
            Navigator.pushReplacementNamed(
              context,
              Routes.main,
              arguments: {"from": "signup"},
            );

            Navigator.pushNamed(Constant.navigatorKey.currentContext!,
                Routes.subscriptionPackageListRoute);
          } else {
            // Client users should just go to the main screen
            log('Navigating Client to main screen only');
            Navigator.pushReplacementNamed(
              context,
              Routes.main,
              arguments: {"from": "signup"},
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response["message"] ?? "Registration failed")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        log('Signup error: $e');

        // Show a more user-friendly error message
        String errorMessage = 'Signup failed';

        // Extract the error message if it's an API error
        if (e.toString().contains('The selected type is invalid')) {
          errorMessage = 'Invalid account type selected. Please try again.';
        } else if (e.toString().contains('The email has already been taken')) {
          errorMessage =
              'This email is already registered. Please use another email or try logging in.';
        } else {
          // For other errors, just show the error message as is
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        bottomNavigationBar: termAndPolicyTxt(),
        body: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: context.color.backgroundColor,
          ),
          child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
            listener: (context, state) {
              if (state is AuthenticationSuccess) {
                if (state.type == AuthenticationType.email) {
                  // Set user as authenticated
                  HiveUtils.setUserIsAuthenticated(true);

                  // Get user role from Hive
                  final userDetails = HiveUtils.getUserDetails();
                  final userRole = userDetails.type ?? "Client";
                  if (userRole == "Provider" ||
                      userRole == "Expert" ||
                      userRole == "Business") {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.main,
                      arguments: {"from": "signup"},
                    );

                    Navigator.pushNamed(Constant.navigatorKey.currentContext!,
                        Routes.subscriptionPackageListRoute);
                  } else {
                    // Client users should just go to the main screen
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.main,
                      arguments: {"from": "signup"},
                    );
                  }
                }
              }

              if (state is AuthenticationFail) {
                HelperUtils.showSnackBarMessage(
                  context,
                  (state.error as FirebaseAuthException).message ?? "Error",
                );
              }
            },
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 18.0, right: 18, top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Skip" button
                        Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                Routes.main,
                                arguments: {
                                  "from": "login",
                                  "isSkipped": true,
                                },
                              );
                            },
                            child: CustomText(
                              "Skip for later",
                              color: const Color(0xFF0F2137).withOpacity(0.6),
                              fontSize: context.font.small,
                            ),
                          ),
                        ),

                        // Tlobni Logo
                        Center(
                          child: Image.asset(
                            'assets/images/tlobni-logo.png',
                            height: 80,
                            width: 100,
                          ),
                        ),

                        // Heading with account type
                        CustomText(
                          "Sign Up",
                          fontSize: context.font.extraLarge,
                        ),
                        const SizedBox(height: 8),

                        // Show what kind of account is being created
                        CustomText(
                          _userType == 'Client' ? "Client" : _providerType,
                          fontSize: context.font.large,
                          color: context.color.territoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 24),

                        // Conditionally show fields for Expert, Business, or Client
                        if (_userType == 'Provider' &&
                            _providerType == 'Expert')
                          _buildExpertFields(),
                        if (_userType == 'Provider' &&
                            _providerType == 'Business')
                          _buildBusinessFields(),
                        if (_userType == 'Client') _buildClientFields(),

                        const SizedBox(height: 20),

                        // ========== Existing Email & Password Fields ==========
                        CustomTextFormField(
                          controller: _emailController,
                          isReadOnly: false,
                          fillColor: context.color.secondaryColor,
                          validator: CustomTextFieldValidator.email,
                          hintText: "Email Address *".translate(context),
                          borderColor: context.color.borderColor.darken(50),
                        ),
                        const SizedBox(height: 14),
                        CustomTextFormField(
                          controller: _passwordController,
                          fillColor: context.color.secondaryColor,
                          obscureText: isObscure,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                isObscure = !isObscure;
                              });
                            },
                            icon: Icon(
                              isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color:
                                  context.color.textColorDark.withOpacity(0.3),
                            ),
                          ),
                          hintText: "Password *".translate(context),
                          validator: CustomTextFieldValidator.password,
                          borderColor: context.color.borderColor.darken(50),
                        ),
                        const SizedBox(height: 36),

                        // Sign up / Verify Email button
                        UiUtils.buildButton(
                          context,
                          onPressed: onTapSignup,
                          buttonTitle: "signUp".translate(context),
                          radius: 10,
                          disabled: _isLoading,
                          height: 46,
                          disabledColor:
                              const Color.fromARGB(255, 104, 102, 106),
                          textColor: const Color(0xFFE6CBA8),
                        ),
                        const SizedBox(height: 36),

                        // Already have account? -> Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              "alreadyHaveAcc".translate(context),
                              color: context.color.textColorDark.brighten(50),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  Routes.login,
                                );
                              },
                              child: CustomText(
                                "login".translate(context),
                                showUnderline: true,
                                color: context.color.territoryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Expert fields ---
  Widget _buildExpertFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        CustomTextFormField(
          controller: _expertFullNameController,
          fillColor: context.color.secondaryColor,
          hintText: "Full Name *",
          validator: CustomTextFieldValidator.nullCheck,
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Gender
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: _expertGender ?? "Gender *",
          readOnly: true,
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: ["Male", "Female"]
                    .map((gender) => ListTile(
                          title: Text(gender),
                          onTap: () {
                            setState(() => _expertGender = gender);
                            Navigator.pop(context);
                          },
                          selected: gender == _expertGender,
                        ))
                    .toList(),
              ),
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: _expertGender),
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Country Selection
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: _expertCountry ?? "Country *",
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
                'SA',
                'AE',
                'QA',
                'OM',
                'KW',
                'LB',
                'EG',
                'JO',
                'IQ',
              ],
              onSelect: (Country country) {
                setState(() => _expertCountry = country.name);
              },
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: _expertCountry),
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _expertLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "City/Area (optional)",
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Categories (multiple selection)
        _buildCategoryMultiSelect(),
        const SizedBox(height: 14),

        // Phone - required
        CustomTextFormField(
          controller: _expertPhoneController,
          fillColor: context.color.secondaryColor,
          hintText: "Phone *",
          validator: CustomTextFieldValidator.phoneNumber,
          keyboard: TextInputType.phone,
          borderColor: context.color.borderColor.darken(50),
        ),
      ],
    );
  }

  // --- Business fields ---
  Widget _buildBusinessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Name - renamed to Name for consistency
        CustomTextFormField(
          controller: _businessNameController,
          fillColor: context.color.secondaryColor,
          hintText: "Name *",
          validator: CustomTextFieldValidator.nullCheck,
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Country Selection
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: _businessCountry ?? "Country *",
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
                'SA',
                'AE',
                'QA',
                'OM',
                'KW',
                'LB',
                'EG',
                'JO',
                'IQ',
              ],
              onSelect: (Country country) {
                setState(() => _businessCountry = country.name);
              },
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: _businessCountry),
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _businessLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "City/Area (optional)",
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Categories
        _buildCategoryMultiSelect(),
        const SizedBox(height: 14),

        // Phone - required
        CustomTextFormField(
          controller: _businessPhoneController,
          fillColor: context.color.secondaryColor,
          hintText: "Phone *",
          validator: CustomTextFieldValidator.phoneNumber,
          keyboard: TextInputType.phone,
          borderColor: context.color.borderColor.darken(50),
        ),
      ],
    );
  }

  // --- Client fields ---
  Widget _buildClientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        CustomTextFormField(
          controller: _clientFullNameController,
          fillColor: context.color.secondaryColor,
          hintText: "Full Name *",
          validator: CustomTextFieldValidator.nullCheck,
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Gender
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: _clientGender ?? "Gender *",
          readOnly: true,
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: ["Male", "Female"]
                    .map((gender) => ListTile(
                          title: Text(gender),
                          onTap: () {
                            setState(() => _clientGender = gender);
                            Navigator.pop(context);
                          },
                          selected: gender == _clientGender,
                        ))
                    .toList(),
              ),
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: _clientGender),
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Country Selection
        CustomTextFormField(
          fillColor: context.color.secondaryColor,
          hintText: _clientCountry ?? "Country *",
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
                'SA',
                'AE',
                'QA',
                'OM',
                'KW',
                'LB',
                'EG',
                'JO',
                'IQ',
              ],
              onSelect: (Country country) {
                setState(() => _clientCountry = country.name);
              },
            );
          },
          suffix: const Icon(Icons.arrow_drop_down),
          validator: CustomTextFieldValidator.nullCheck,
          controller: TextEditingController(text: _clientCountry),
          borderColor: context.color.borderColor.darken(50),
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _clientLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "City/Area (optional)",
          borderColor: context.color.borderColor.darken(50),
        ),
      ],
    );
  }

  // --- Categories multi-select (common for Expert & Business) ---
  Widget _buildCategoryMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showCategorySelectionDialog(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(8),
              // border: Border.all(
              //   color: context.color.borderColor.darken(50),
              // ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryIds.isEmpty
                        ? "Choose Categories *"
                        : "${_selectedCategoryIds.length} categories selected",
                    style: TextStyle(
                      color: context.color.textColorDark.withOpacity(0.7),
                      fontSize: context.font.large,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: context.color.textColorDark.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        if (_selectedCategoryIds.isEmpty && _showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              "Field must not be empty",
              style: TextStyle(
                color: Colors.red,
                fontSize: context.font.small,
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
                                                                // Also select all nested subcategories
                                                                if (hasNestedSubcategories) {
                                                                  _selectAllNestedSubcategories(
                                                                      subcategory);
                                                                }
                                                              } else {
                                                                _selectedCategoryIds
                                                                    .remove(
                                                                        subcategory
                                                                            .id!);
                                                                // Also deselect all nested subcategories
                                                                if (hasNestedSubcategories) {
                                                                  _deselectAllNestedSubcategories(
                                                                      subcategory);
                                                                }
                                                              }
                                                            });
                                                          }
                                                        },
                                                      ),
                                                      trailing:
                                                          hasNestedSubcategories
                                                              ? Icon(
                                                                  _isSubcategoryExpanded(
                                                                          subcategory.id ??
                                                                              0)
                                                                      ? Icons
                                                                          .keyboard_arrow_up
                                                                      : Icons
                                                                          .keyboard_arrow_down,
                                                                  color: context
                                                                      .color
                                                                      .textColorDark,
                                                                )
                                                              : null,
                                                      onTap:
                                                          hasNestedSubcategories
                                                              ? () {
                                                                  setState(() {
                                                                    _toggleSubcategoryExpansion(
                                                                        subcategory.id ??
                                                                            0);
                                                                  });
                                                                }
                                                              : null,
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
                                                            .map(
                                                                (nestedSubcategory) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 40.0),
                                                            child: ListTile(
                                                              title: Text(
                                                                  nestedSubcategory
                                                                          .name ??
                                                                      "Unknown"),
                                                              leading: Checkbox(
                                                                value: _isCategorySelected(
                                                                    nestedSubcategory
                                                                            .id ??
                                                                        0),
                                                                onChanged:
                                                                    (bool?
                                                                        value) {
                                                                  if (nestedSubcategory
                                                                          .id !=
                                                                      null) {
                                                                    setState(
                                                                        () {
                                                                      if (value ==
                                                                          true) {
                                                                        if (!_selectedCategoryIds
                                                                            .contains(nestedSubcategory.id!)) {
                                                                          _selectedCategoryIds
                                                                              .add(nestedSubcategory.id!);
                                                                        }
                                                                      } else {
                                                                        _selectedCategoryIds
                                                                            .remove(nestedSubcategory.id!);
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

  // Load categories for the dialog
  Future<void> _loadCategoriesForDialog(
    StateSetter setState,
    List<CategoryModel> filteredCategories,
    List<bool> dialogExpandedPanels,
  ) async {
    try {
      final CategoryRepository categoryRepository = CategoryRepository();
      // Fetch only provider categories for the dialog
      final result = await categoryRepository.fetchCategories(
          page: 1, type: CategoryType.providers);

      setState(() {
        _categories = result.modelList;
        // Only add categories with type 'providers' to filteredCategories
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

  // --- Provided from the original code ---
  Widget mobileAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(
          "signupWithLbl".translate(context),
          color: context.color.textColorDark.brighten(50),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, Routes.signupMainScreen);
          },
          child: CustomText(
            "mobileNumberLbl".translate(context),
            showUnderline: true,
            color: context.color.territoryColor,
          ),
        ),
      ],
    );
  }

  Widget googleAndAppleAuth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        if (Constant.googleAuthentication == "1")
          UiUtils.buildButton(
            context,
            prefixWidget: Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: UiUtils.getSvg(AppIcons.googleIcon, width: 22, height: 22),
            ),
            showElevation: false,
            buttonColor: secondaryColor_,
            border:
                context.watch<AppThemeCubit>().state.appTheme != AppTheme.dark
                    ? BorderSide(
                        color: context.color.textDefaultColor.withOpacity(0.3))
                    : null,
            textColor: textDarkColor,
            onPressed: () {
              context.read<AuthenticationCubit>().setData(
                    payload: GoogleLoginPayload(),
                    type: AuthenticationType.google,
                  );
              context.read<AuthenticationCubit>().authenticate();
            },
            radius: 8,
            height: 46,
            buttonTitle: "continueWithGoogle".translate(context),
          ),
        if (Constant.appleAuthentication == "1" && Platform.isIOS) ...[
          const SizedBox(height: 12),
          UiUtils.buildButton(
            context,
            prefixWidget: Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: UiUtils.getSvg(AppIcons.appleIcon, width: 22, height: 22),
            ),
            showElevation: false,
            buttonColor: secondaryColor_,
            border:
                context.watch<AppThemeCubit>().state.appTheme != AppTheme.dark
                    ? BorderSide(
                        color: context.color.textDefaultColor.withOpacity(0.3))
                    : null,
            textColor: textDarkColor,
            onPressed: () {
              context.read<AuthenticationCubit>().setData(
                    payload: AppleLoginPayload(),
                    type: AuthenticationType.apple,
                  );
              context.read<AuthenticationCubit>().authenticate();
            },
            height: 46,
            radius: 8,
            buttonTitle: "continueWithApple".translate(context),
          ),
        ]
      ],
    );
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 15.0, start: 25.0, end: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "bySigningUpLoggingIn".translate(context),
            color: context.color.textLightColor.withOpacity(0.8),
            fontSize: context.font.small,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                child: CustomText(
                  "termsOfService".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "termsConditions".translate(context),
                    'param': Api.termsAndConditions
                  },
                ),
              ),
              const SizedBox(width: 5.0),
              CustomText(
                "andTxt".translate(context),
                color: context.color.textLightColor.withOpacity(0.8),
                fontSize: context.font.small,
              ),
              const SizedBox(width: 5.0),
              InkWell(
                child: CustomText(
                  "privacyPolicy".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "privacyPolicy".translate(context),
                    'param': Api.privacyPolicy
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
