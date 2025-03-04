import 'dart:async';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
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
import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpMainScreen extends StatefulWidget {
  const SignUpMainScreen({super.key});

  @override
  State<SignUpMainScreen> createState() => LoginScreenState();

  static BlurredRouter route(RouteSettings routeSettings) {
    return BlurredRouter(builder: (_) => SignUpMainScreen());
  }
}

class LoginScreenState extends State<SignUpMainScreen> {
  final TextEditingController emailMobileTextController =
      TextEditingController();
  String? phone, countryCode, countryName, flagEmoji;

  Timer? timer;
  late Size size;
  CountryService countryCodeService = CountryService();
  bool isLoginButtonDisabled = true;
  bool isMobileNumberField = false;
  String numberOrEmail = "";
  final _formKey = GlobalKey<FormState>();

  late PhoneLoginPayload phoneLoginPayload =
      PhoneLoginPayload(emailMobileTextController.text, countryCode!);
  bool isBack = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthenticationCubit>().init();
    context.read<AuthenticationCubit>().listen((MLoginState state) {
      if (state is MOtpSendInProgress) {
        if (mounted) Widgets.showLoader(context);
      }

      if (state is MVerificationPending) {
        if (mounted) {
          Widgets.hideLoder(context);
          setState(() {});
        }
      }

      if (state is MFail) {
        if (state.error is FirebaseAuthException) {
          try {
            HelperUtils.showSnackBarMessage(context,
                (state.error as FirebaseAuthException).message!.toString());
          } catch (e) {}
        } else {
          HelperUtils.showSnackBarMessage(context, state.error.toString());
        }
      }
      if (state is MSuccess) {}
    });
    getSimCountry().then((value) {
      countryCode = value.phoneCode;

      flagEmoji = value.flagEmoji;
      setState(() {});
    });
  }

  /// it will return user's sim cards country code
  Future<Country> getSimCountry() async {
    List<Country> countryList = countryCodeService.getAll();
    String? simCountryCode;

    try {
      simCountryCode = await DeviceRegion.getSIMCountryCode();
    } catch (e) {}

    Country simCountry = countryList.firstWhere(
      (element) {
        if (Constant.isDemoModeOn) {
          return countryList.any(
            (element) => element.phoneCode == Constant.defaultCountryCode,
          );
        } else {
          return element.phoneCode == simCountryCode;
        }
      },
      orElse: () {
        return countryList
            .where(
              (element) => element.phoneCode == Constant.defaultCountryCode,
            )
            .first;
      },
    );

    if (Constant.isDemoModeOn) {
      simCountry = countryList
          .where((element) => element.phoneCode == Constant.demoCountryCode)
          .first;
    }

    return simCountry;
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }

    emailMobileTextController.dispose();

    super.dispose();
  }

  void _onTapContinue() {
    if (isMobileNumberField) {
      Navigator.pushNamed(context, Routes.mobileSignUp, arguments: {
        "mobile": emailMobileTextController.text.toString().trim(),
        "countryCode": countryCode
      });
    } else {
      Navigator.pushNamed(context, Routes.signup, arguments: {
        "emailId": emailMobileTextController.text.toString().trim()
      });
    }
  }

  Future<void> sendVerificationCode() async {
    final form = _formKey.currentState;

    if (form == null) return;
    form.save();
    //checkbox value should be 1 before Login/SignUp
    if (form.validate()) {
      _onTapContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: PopScope(
            canPop: isBack,
            onPopInvokedWithResult: (didPop, result) {
              setState(() {
                isBack = true;
              });
              return;
            },
            child: AnnotatedRegion(
              value: SystemUiOverlayStyle(
                statusBarColor: context.color.backgroundColor,
              ),
              child: Scaffold(
                backgroundColor: context.color.backgroundColor,
                bottomNavigationBar: termAndPolicyTxt(),
                body: Builder(builder: (context) {
                  return Form(
                    key: _formKey,
                    child: buildLoginWidget(),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mobileAndEmailSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "signUpToeClassify".translate(context),
          fontSize: context.font.large,
          color: context.color.textColorDark,
        ),
        const SizedBox(
          height: 24,
        ),
        CustomTextFormField(
            controller: emailMobileTextController,
            fillColor: context.color.secondaryColor,
            borderColor: context.color.borderColor.darken(30),
            onChange: (value) {
              bool isNumber = value.toString().contains(RegExp(r'^[0-9]+$'));

              isMobileNumberField =
                  Constant.mobileAuthentication == "1" ? isNumber : false;

              numberOrEmail = value;
              setState(() {});
            },
            keyboard: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? (isMobileNumberField
                    ? TextInputType.phone
                    : TextInputType.emailAddress)
                : (Constant.mobileAuthentication == "1")
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
            validator: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? (isMobileNumberField
                    ? CustomTextFieldValidator.phoneNumber
                    : CustomTextFieldValidator.email)
                : (Constant.mobileAuthentication == "1")
                    ? CustomTextFieldValidator.phoneNumber
                    : CustomTextFieldValidator.email,
            fixedPrefix: (isMobileNumberField)
                ? SizedBox(
                    width: 55,
                    child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GestureDetector(
                          onTap: () {
                            showCountryCode();
                          },
                          child: Container(
                              // color: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8),
                              child: Center(
                                  child: CustomText(
                                "+$countryCode",
                                fontSize: context.font.large,
                                textAlign: TextAlign.center,
                              ))),
                        )),
                  )
                : null,
            hintText: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? "emailOrPhone".translate(context)
                : (Constant.mobileAuthentication == "1")
                    ? "mobileNumberLbl".translate(context)
                    : "emailAddress".translate(context)),
        const SizedBox(
          height: 46,
        ),
        UiUtils.buildButton(context,
            onPressed: sendVerificationCode,
            buttonTitle: "continue".translate(context),
            radius: 10,
            disabled: numberOrEmail.isEmpty,
            disabledColor: const Color.fromARGB(255, 104, 102, 106)),
      ],
    );
  }

  Widget buildLoginWidget() {
    return SingleChildScrollView(
      child: SizedBox(
        height: context.screenHeight - 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: FittedBox(
                  fit: BoxFit.none,
                  child: MaterialButton(
                    onPressed: () {
                      //HiveUtils.setUserIsNotNew();
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
              const SizedBox(
                height: 66,
              ),
              CustomText(
                "welcome".translate(context),
                fontSize: context.font.extraLarge,
                color: context.color.textColorDark,
              ),
              const SizedBox(
                height: 8,
              ),
              if (Constant.mobileAuthentication == "1" ||
                  Constant.emailAuthentication == "1")
                mobileAndEmailSignUp(),
              const SizedBox(
                height: 68,
              ),
              if (Constant.googleAuthentication == "1" ||
                  Constant.appleAuthentication == "1")
                googleAndAppleSignUp(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    "alreadyHaveAcc".translate(context),
                    color: context.color.textColorDark.brighten(50),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
                    child: CustomText(
                      "login".translate(context),
                      showUnderline: true,
                      color: context.color.territoryColor,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget googleAndAppleSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Constant.googleAuthentication == "1")
              UiUtils.buildButton(context,
                  prefixWidget: Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.0),
                    child: UiUtils.getSvg(AppIcons.googleIcon,
                        width: 22, height: 22),
                  ),
                  showElevation: false,
                  buttonColor: secondaryColor_,
                  border: context.watch<AppThemeCubit>().state.appTheme !=
                          AppTheme.dark
                      ? BorderSide(
                          color:
                              context.color.textDefaultColor.withOpacity(0.3))
                      : null,
                  textColor: textDarkColor, onPressed: () {
                context.read<AuthenticationCubit>().setData(
                    payload: GoogleLoginPayload(),
                    type: AuthenticationType.google);
                context.read<AuthenticationCubit>().authenticate();
              },
                  radius: 8,
                  height: 46,
                  buttonTitle: "continueWithGoogle".translate(context)),
            const SizedBox(
              height: 12,
            ),
            if (Constant.appleAuthentication == "1" && Platform.isIOS)
              UiUtils.buildButton(context,
                  prefixWidget: Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.0),
                    child: UiUtils.getSvg(AppIcons.appleIcon,
                        width: 22, height: 22),
                  ),
                  showElevation: false,
                  buttonColor: secondaryColor_,
                  border: context.watch<AppThemeCubit>().state.appTheme !=
                          AppTheme.dark
                      ? BorderSide(
                          color:
                              context.color.textDefaultColor.withOpacity(0.3))
                      : null,
                  textColor: textDarkColor, onPressed: () {
                context.read<AuthenticationCubit>().setData(
                    payload: AppleLoginPayload(),
                    type: AuthenticationType.apple);
                context.read<AuthenticationCubit>().authenticate();
              },
                  height: 46,
                  radius: 8,
                  buttonTitle: "continueWithApple".translate(context)),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ],
    );
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 15.0, start: 25.0, end: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText("bySigningUpLoggingIn".translate(context),
              color: context.color.textLightColor.withOpacity(0.8),
              fontSize: context.font.small,
              textAlign: TextAlign.center),
          const SizedBox(
            height: 3,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
                child: CustomText(
                  "termsOfService".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                        context, Routes.profileSettings, arguments: {
                      'title': "termsConditions".translate(context),
                      'param': Api.termsAndConditions
                    })),
            const SizedBox(
              width: 5.0,
            ),
            CustomText(
              "andTxt".translate(context),
              color: context.color.textLightColor.withOpacity(0.8),
              fontSize: context.font.small,
            ),
            const SizedBox(
              width: 5.0,
            ),
            InkWell(
                child: CustomText(
                  "privacyPolicy".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                        context, Routes.profileSettings, arguments: {
                      'title': "privacyPolicy".translate(context),
                      'param': Api.privacyPolicy
                    })),
          ]),
        ],
      ),
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(11),
        searchTextStyle: TextStyle(
          color: context.color.textColorDark,
          fontSize: 16,
        ),
      ),
      onSelect: (Country value) {
        flagEmoji = value.flagEmoji;
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }
}
