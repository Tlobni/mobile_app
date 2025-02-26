import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/login_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();

    // If needed, read from widget.email
    if (widget.email?.isNotEmpty ?? false) {
      emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle email login
  void onTapEmailLogin() {
    // Basic validation
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text.trim().isEmpty) {
        HelperUtils.showSnackBarMessage(context, 'Password cannot be empty');
        return;
      }
      context.read<LoginCubit>().loginEmailAndPassword(
          email: emailController.text.trim(),
          password: _passwordController.text.trim());
    }
  }

  /// Open Signup Screen
  void navigateToSignup() {
    Navigator.pushReplacementNamed(context, Routes.signup);
  }

  @override
  Widget build(BuildContext context) {
    // Hide phone references, only show email login
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
            body: BlocListener<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginInProgress) {
                  // show loader
                } else if (state is LoginSuccess) {
                  // hide loader
                  // navigate to home, or check if isProfileCompleted
                  if (state.isProfileCompleted) {
                    Navigator.pushReplacementNamed(context, Routes.main);
                  } else {
                    Navigator.pushNamed(context, Routes.completeProfile);
                  }
                } else if (state is LoginFailure) {
                  // hide loader
                  // show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage)),
                  );
                }
              },
              child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
                listener: (context, authState) async {
                  if (authState is AuthenticationInProcess) {
                    Widgets.showLoader(context);
                  }
                  if (authState is AuthenticationSuccess) {
                    Widgets.hideLoder(context);
                    if (authState.type == AuthenticationType.email) {
                      final user = authState.credential.user;
                      // If user email is verified -> proceed to login
                      if (user?.emailVerified ?? false) {
                      } else {
                        // Email not verified
                        HelperUtils.showSnackBarMessage(
                            context, "Please verify your email first.");
                      }
                    } else {
                      // Other providers not used in this simplified flow
                    }
                  } else if (authState is AuthenticationFail) {
                    Widgets.hideLoder(context);
                    HelperUtils.showSnackBarMessage(
                      context,
                      authState.error.toString(),
                      type: MessageType.error,
                    );
                  }
                },
                builder: (context, authState) {
                  return buildLoginForm(context);
                },
              ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Skip Button
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: FittedBox(
                  fit: BoxFit.none,
                  child: MaterialButton(
                    onPressed: () {
                      HiveUtils.setUserSkip();
                      HelperUtils.killPreviousPages(
                        context,
                        Routes.main,
                        {"from": "login", "isSkipped": true},
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: context.color.forthColor.withOpacity(0.102),
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
              const SizedBox(height: 66),

              /// Title
              CustomText(
                "welcomeback".translate(context),
                fontSize: context.font.extraLarge,
                color: context.color.textDefaultColor,
              ),
              const SizedBox(height: 8),

              /// Email Login Fields
              CustomText(
                'loginWithEmail'.translate(context),
                fontSize: context.font.large,
                color: context.color.textColorDark,
              ),
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
                  child: CustomText(
                    "${"forgotPassword".translate(context)}?",
                    color: context.color.textLightColor,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              /// Sign In Button
              UiUtils.buildButton(
                context,
                onPressed: onTapEmailLogin,
                buttonTitle: 'signIn'.translate(context),
                radius: 10,
                disabled: emailController.text.isEmpty ||
                    _passwordController.text.isEmpty,
                disabledColor: const Color.fromARGB(255, 104, 102, 106),
              ),
              const SizedBox(height: 20),

              /// Don't Have Account? -> SignUp
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText("dontHaveAcc".translate(context),
                      color: context.color.textColorDark.brighten(50)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: navigateToSignup,
                    child: CustomText(
                      "signUp".translate(context),
                      color: context.color.territoryColor,
                      showUnderline: true,
                    ),
                  )
                ],
              ),

              const Spacer(),

              /// Google & Apple buttons if needed
              if (Constant.googleAuthentication == "1" ||
                  (Constant.appleAuthentication == "1" && Platform.isIOS))
                googleAndAppleLogin(),

              /// Terms & Policy
            ],
          ),
        ),
      ),
    );
  }

  /// If you still want Google/Apple, keep this. Otherwise remove.
  Widget googleAndAppleLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        if (Constant.googleAuthentication == "1") ...[
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
          const SizedBox(height: 12),
        ],
        if (Constant.appleAuthentication == "1" && Platform.isIOS) ...[
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
          const SizedBox(height: 12),
        ],
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
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                  showUnderline: true,
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
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                  showUnderline: true,
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
