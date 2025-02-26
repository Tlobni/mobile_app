import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/repositories/auth_repository.dart';
import 'package:eClassify/ui/screens/auth/sign_up/email_verification_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupScreen extends StatefulWidget {
  final String? emailId;

  const SignupScreen({super.key, this.emailId});

  static BlurredRouter route(RouteSettings settings) {
    Map? args = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SignupScreen(
            // emailId: args!['emailId'],
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

  // Expert fields
  final TextEditingController _expertFullNameController =
      TextEditingController();
  String? _expertGender; // example: 'Male','Female','Other'
  final TextEditingController _expertLocationController =
      TextEditingController();
  final TextEditingController _expertPhoneController = TextEditingController();

  // Business fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessLocationController =
      TextEditingController();
  final TextEditingController _businessPhoneController =
      TextEditingController();

  // Client fields
  final TextEditingController _clientFullNameController =
      TextEditingController();
  String? _clientGender;
  final TextEditingController _clientLocationController =
      TextEditingController();

  // Categories used by Providers (Expert/Business)
  final List<String> _allCategories = ["IT", "Finance", "Health", "Education"];
  // We'll store the user's selected categories in one list for providers:
  List<String> _providerSelectedCategories = [];

  @override
  void initState() {
    super.initState();
    // If an email is passed in, pre-populate:
    // _emailController.text = widget.emailId ?? "";
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
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final MultiAuthRepository _multiAuthRepository = MultiAuthRepository();
        final response = await _multiAuthRepository.createUserWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          userType: _userType,
          providerType: _providerType,
          fullName: _userType == "Provider" && _providerType == "Expert"
              ? _expertFullNameController.text.trim()
              : _clientFullNameController.text.trim(),
          gender: _userType == "Provider" && _providerType == "Expert"
              ? _expertGender
              : _clientGender,
          location: _userType == "Provider"
              ? (_providerType == "Expert"
                  ? _expertLocationController.text.trim()
                  : _businessLocationController.text.trim())
              : _clientLocationController.text.trim(),
          businessName: _providerType == "Business"
              ? _businessNameController.text.trim()
              : null,
          categories: _providerSelectedCategories,
          phone: _providerType == "Expert"
              ? _expertPhoneController.text.trim()
              : _businessPhoneController.text.trim(),
        );

        // Check if signup was successful
        if (response["success"] == true) {
          // Get the user credential from the response
          final UserCredential userCredential = response["firebaseUser"];
          final User firebaseUser = userCredential.user!;

          // Send Email Verification
          await firebaseUser.sendEmailVerification();

          // Emit success in the cubit to keep it consistent
          final payload = EmailLoginPayload(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            type: EmailLoginType.signup,
          );

          context.read<AuthenticationCubit>().setSignUpSuccess(
                userCredential,
                payload,
              );

          // Navigate to EmailVerificationScreen or wait for the bloc listener to do so
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => EmailVerificationScreen(
          //       email: _emailController.text,
          //       password: _passwordController.text,
          //     ),
          //   ),
          // );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response["message"])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
                  // Send verification email
                  FirebaseAuth.instance.currentUser?.sendEmailVerification();

                  Navigator.push<dynamic>(context, BlurredRouter(
                    builder: (context) {
                      return EmailVerificationScreen(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                    },
                  ));
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
                          child: FittedBox(
                            fit: BoxFit.none,
                            child: MaterialButton(
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              color:
                                  context.color.forthColor.withOpacity(0.102),
                              elevation: 0,
                              height: 28,
                              minWidth: 64,
                              child: CustomText(
                                "skip".translate(context),
                                color: context.color.forthColor,
                              ),
                            ),
                          ),
                        ),
                        // Heading
                        CustomText(
                          "welcome".translate(context),
                          fontSize: context.font.extraLarge,
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          "signUpToeClassify".translate(context),
                          fontSize: context.font.large,
                          color: context.color.textColorDark.brighten(50),
                        ),
                        const SizedBox(height: 24),

                        // ============== NEW UI: Provider / Client selection ==============
                        _buildUserTypeSelector(),

                        // ========== If Provider -> Show Expert or Business fields =========
                        if (_userType == 'Provider')
                          _buildProviderTypeSelector(),
                        const SizedBox(height: 16),

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
                          hintText: "emailAddress".translate(context),
                          borderColor: context.color.borderColor.darken(10),
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
                          hintText: "password".translate(context),
                          validator: CustomTextFieldValidator.password,
                          borderColor: context.color.borderColor.darken(10),
                        ),
                        const SizedBox(height: 36),

                        // Sign up / Verify Email button
                        UiUtils.buildButton(
                          context,
                          onPressed: onTapSignup,
                          buttonTitle: "verifyEmailAddress".translate(context),
                          radius: 10,
                          disabled: false,
                          height: 46,
                          disabledColor:
                              const Color.fromARGB(255, 104, 102, 106),
                        ),
                        const SizedBox(height: 36),

                        // Social or phone login if enabled
                        // // if (Constant.mobileAuthentication == "1") mobileAuth(),
                        // if (Constant.googleAuthentication == "1" ||
                        //     Constant.appleAuthentication == "1")
                        //   googleAndAppleAuth(),
                        // const SizedBox(height: 24),

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

  // --- Provider / Client selection ---
  Widget _buildUserTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor.darken(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'Provider'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _userType == 'Provider'
                      ? context.color.territoryColor
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(7)),
                ),
                child: Text(
                  'Provider',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _userType == 'Provider'
                        ? Colors.white
                        : context.color.textColorDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'Client'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _userType == 'Client'
                      ? context.color.territoryColor
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(7)),
                ),
                child: Text(
                  'Client',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _userType == 'Client'
                        ? Colors.white
                        : context.color.textColorDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Expert / Business selection ---
  Widget _buildProviderTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor.darken(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildProviderTypeOption('Expert'),
          const SizedBox(width: 8),
          _buildProviderTypeOption('Business'),
        ],
      ),
    );
  }

  Widget _buildProviderTypeOption(String type) {
    final isSelected = _providerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _providerType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? context.color.territoryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.color.textColorDark,
              fontWeight: FontWeight.w500,
            ),
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
          hintText: "Full Name",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Full Name is required";
          //   }
          //   return null;
          // },
        ),
        const SizedBox(height: 14),

        // Gender
        _buildGenderDropdown(
          context,
          value: _expertGender,
          onChanged: (val) => setState(() => _expertGender = val),
          label: "Gender",
          requiredMsg: "Please select gender",
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _expertLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "Location",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Location is required";
          //   }
          //   return null;
          // },
        ),
        const SizedBox(height: 14),

        // Categories (multiple selection)
        _buildCategoryMultiSelect(),
        const SizedBox(height: 14),

        // Phone - required
        CustomTextFormField(
          controller: _expertPhoneController,
          fillColor: context.color.secondaryColor,
          hintText: "Phone",
        ),
      ],
    );
  }

  // --- Business fields ---
  Widget _buildBusinessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Name
        CustomTextFormField(
          controller: _businessNameController,
          fillColor: context.color.secondaryColor,
          hintText: "Business Name",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Business name is required";
          //   }
          //   return null;
          // },
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _businessLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "Location",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Location is required";
          //   }
          //   return null;
          // },
        ),
        const SizedBox(height: 14),

        // Categories
        _buildCategoryMultiSelect(),
        const SizedBox(height: 14),

        // Phone - optional
        CustomTextFormField(
          controller: _businessPhoneController,
          fillColor: context.color.secondaryColor,
          hintText: "Phone (optional)",
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
          hintText: "Full Name",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Full Name is required";
          //   }
          //   return null;
          // },
        ),
        const SizedBox(height: 14),

        // Gender
        _buildGenderDropdown(
          context,
          value: _clientGender,
          onChanged: (val) => setState(() => _clientGender = val),
          label: "Gender",
          requiredMsg: "Please select gender",
        ),
        const SizedBox(height: 14),

        // Location
        CustomTextFormField(
          controller: _clientLocationController,
          fillColor: context.color.secondaryColor,
          hintText: "Location",
          // validator: (val) {
          //   if ((val ?? '').trim().isEmpty) {
          //     return "Location is required";
          //   }
          //   return null;
          // },
        ),
      ],
    );
  }

  // --- Updated gender dropdown to match other fields ---
  Widget _buildGenderDropdown(
    BuildContext context, {
    required String? value,
    required Function(String?) onChanged,
    required String label,
    String? requiredMsg,
  }) {
    final items = <String>["Male", "Female", "Other"];
    return CustomTextFormField(
      fillColor: context.color.secondaryColor,
      hintText: label,
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
    );
  }

  // --- Categories multi-select (common for Expert & Business) ---
  Widget _buildCategoryMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText(
          "Categories (pick at least one)",
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: _allCategories.map((cat) {
            final isSelected = _providerSelectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _providerSelectedCategories.add(cat);
                  } else {
                    _providerSelectedCategories.remove(cat);
                  }
                });
              },
            );
          }).toList(),
        ),
        // If none selected, show an inline message
        if (_providerSelectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "* Required field. Please select at least one category.",
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
      ],
    );
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
