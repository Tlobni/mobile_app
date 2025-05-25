import 'package:flutter/material.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  final bool? isDeleteAccount;
  final bool? popToCurrent;
  final String? email;

  const LoginScreen({
    Key? key,
    this.isDeleteAccount,
    this.popToCurrent,
    this.email,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static BlurredRouter route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => LoginScreen(
        isDeleteAccount: args?['isDeleteAccount'],
        popToCurrent: args?['popToCurrent'],
        email: args?['email'] as String?,
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  // Email/Password Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isObscure = true;
  bool isBack = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Check if user is already authenticated and redirect to main screen if so
    if (HiveUtils.isUserAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HelperUtils.killPreviousPages(
          context,
          Routes.main,
          {"from": "login"},
        );
      });
      return;
    }

    // If needed, read from widget.email
    if (widget.email?.isNotEmpty ?? false) {
      emailController.text = widget.email!;
      _updateButtonState();
    }

    // Add listeners to update button state when text changes
    emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final newState = emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    if (newState != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = newState;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);

    emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle email login
  void onTapEmailLogin() async {
    // Basic validation
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text.trim().isEmpty) {
        HelperUtils.showSnackBarMessage(context, 'Password cannot be empty');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Call backend API directly
        final response = await Api.post(
          url: Api.login,
          parameter: {'email': emailController.text.trim(), 'password': _passwordController.text.trim()},
        );

        // Store token
        HiveUtils.setJWT(response['token']);

        // Store user data
        HiveUtils.setUserData({
          'id': response['user']['id'],
          'name': response['user']['name'],
          'email': response['user']['email'],
          'mobile': response['user']['mobile'] ?? '',
          'profile': response['user']['profile'] ?? '',
          'type': response['user']['roles'][0]['name'],
          'firebaseId': response['user']['firebase_id'] ?? '',
          'fcmId': response['user']['fcm_id'] ?? '',
          'notification': response['user']['notification'] ?? 1,
          'address': response['user']['address'] ?? '',
          'categories': response['user']['categories'] ?? [],
          'phone': response['user']['phone'] ?? '',
          'bio': response['user']['bio'] ?? '',
          'gender': response['user']['gender'] ?? '',
          'location': response['user']['location'] ?? '',
          'countryCode': response['user']['country_code'] ?? '',
          'isProfileCompleted': response['user']['isProfileCompleted'] ?? true,
          'showPersonalDetails': response['user']['show_personal_details'] ?? 1,
          'autoApproveItem': true,
          'isVerified': true,
          'facebook': response['user']['facebook'],
          'twitter': response['user']['twitter'],
          'instagram': response['user']['instagram'],
          'tiktok': response['user']['tiktok'],
        });

        HiveUtils.setUserIsAuthenticated(true);

        // Navigate based on profile completion
        final isProfileCompleted = response['user']['isProfileCompleted'] ?? true;

        setState(() {
          _isLoading = false;
        });

        if (isProfileCompleted) {
          Navigator.pushReplacementNamed(context, Routes.main);
        } else {
          Navigator.pushNamed(context, Routes.completeProfile);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Handle specific error cases with more appropriate messages
        if (e.toString().contains('401') || e.toString().contains('invalid_credentials')) {
          // For 401 errors (unauthorized), show a clear message about invalid credentials
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid email or password. Please check your credentials.')),
          );
        } else if (e.toString().contains('deactivated')) {
          // If account is actually deactivated (rather than non-existent)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This account has been deactivated. Please contact support.')),
          );
        } else {
          // For other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString()}')),
          );
        }

        // No navigation needed here - we're already on the login screen
      }
    }
  }

  /// Open Signup Screen
  void navigateToSignup() {
    Navigator.pushReplacementNamed(context, Routes.accountType);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: context.color.backgroundColor,
            bottomNavigationBar: termAndPolicyTxt(),
            body: Stack(
              children: [
                buildLoginForm(context),
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: context.screenHeight - 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Skip Button
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: () {
                    HiveUtils.setUserSkip();
                    HelperUtils.killPreviousPages(
                      context,
                      Routes.main,
                      {"from": "login", "isSkipped": true},
                    );
                  },
                  child: Text(
                    "Skip for later",
                    style: context.textTheme.bodySmall,
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
              const SizedBox(height: 20),

              /// Title
              HeadingText("Sign In"),
              const SizedBox(height: 8),

              /// Email Login Fields
              DescriptionText('Enter your credentials to continue'),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// Email
                    CustomTextFormField(
                      controller: emailController,
                      fillColor: context.color.secondaryColor,
                      borderColor: context.color.borderColor.darken(30),
                      keyboard: TextInputType.emailAddress,
                      validator: CustomTextFieldValidator.email,
                      hintText: "emailAddress".translate(context),
                    ),
                    const SizedBox(height: 10),

                    /// Password
                    CustomTextFormField(
                      hintText: "password".translate(context),
                      controller: _passwordController,
                      validator: CustomTextFieldValidator.nullCheck,
                      obscureText: isObscure,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => isObscure = !isObscure);
                        },
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                          color: context.color.textColorDark.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.forgotPassword);
                  },
                  child: DescriptionText(
                    "${"forgotPassword".translate(context)}?",
                    color: context.color.textLightColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              /// Sign In Button
              PrimaryButton.text(
                'signIn'.translate(context),
                padding: EdgeInsets.all(20),
                onPressed: () {
                  if (!_isLoading) {
                    onTapEmailLogin();
                  }
                },
              ),
              const SizedBox(height: 20),

              /// Don't Have Account? -> SignUp
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DescriptionText("dontHaveAcc".translate(context)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: navigateToSignup,
                    child: DescriptionText(
                      "signUp".translate(context),
                      color: context.color.territoryColor,
                    ),
                  )
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 15.0, start: 25.0, end: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          SmallText(
            "bySigningUpLoggingIn".translate(context),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                child: SmallText(
                  "termsOfService".translate(context),
                  decoration: TextDecoration.underline,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {'title': "termsConditions".translate(context), 'param': Api.termsAndConditions},
                ),
              ),
              const SizedBox(width: 5.0),
              SmallText(
                "andTxt".translate(context),
              ),
              const SizedBox(width: 5.0),
              InkWell(
                child: SmallText(
                  "privacyPolicy".translate(context),
                  decoration: TextDecoration.underline,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {'title': "privacyPolicy".translate(context), 'param': Api.privacyPolicy},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget newUi() {
    return SizedBox();
  }
}
