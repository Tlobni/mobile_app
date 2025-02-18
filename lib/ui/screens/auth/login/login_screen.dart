import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/login_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
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
import 'package:sms_autofill/sms_autofill.dart';

class LoginScreen extends StatefulWidget {
  final bool? isDeleteAccount;
  final bool? popToCurrent;
  final String? email;

  const LoginScreen(
      {super.key, this.isDeleteAccount, this.popToCurrent, this.email});

  @override
  State<LoginScreen> createState() => LoginScreenState();

  static BlurredRouter route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return BlurredRouter(
        builder: (_) => LoginScreen(
              isDeleteAccount: args?['isDeleteAccount'],
              popToCurrent: args?['popToCurrent'],
              email: args?['email'] as String?,
            ));
  }
}

class LoginScreenState extends State<LoginScreen> {
  late final TextEditingController emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController mobileController = TextEditingController(
      text: Constant.isDemoModeOn ? Constant.demoMobileNumber : '');
  bool isOtpSent = false;
  String? phone, otp, countryCode, countryName, flagEmoji;

  Timer? timer;
  late Size size;
  CountryService countryCodeService = CountryService();
  bool isLoginButtonDisabled = true;
  ValueNotifier<bool> isLoginWithMobile = ValueNotifier(true);
  bool sendMailClicked = false;
  final _formKey = GlobalKey<FormState>();

  bool isObscure = true;
  late PhoneLoginPayload phoneLoginPayload =
      PhoneLoginPayload(mobileController.text, countryCode!);
  bool isBack = false;
  String signature = "";

  @override
  void initState() {
    super.initState();

    if (Constant.mobileAuthentication == "0") {
      isLoginWithMobile.value = false;
    }
    getSignature();
    context.read<AuthenticationCubit>().init();
    context.read<AuthenticationCubit>().listen((MLoginState state) {
      if (state is MOtpSendInProgress) {
        if (mounted) Widgets.showLoader(context);
      }

      if (state is MVerificationPending) {
        if (mounted) {
          Widgets.hideLoder(context);

          // Widgets.showLoader(context);

          isOtpSent = true;
          setState(() {});
          if (isLoginWithMobile.value) {
            HelperUtils.showSnackBarMessage(
                context, "optsentsuccessflly".translate(context));
          }
        }
      }

      if (state is MFail) {
        Widgets.hideLoder(context);
        // log('$isOtpSent - ${isLoginWithMobile.value}');
        // if (!isOtpSent && isLoginWithMobile.value) {
        //   Widgets.hideLoder(context);
        // }

        if (isOtpSent && (otp!.trim().isEmpty)) {
          HelperUtils.showSnackBarMessage(context,
              "${"weSentCodeOnNumber".translate(context)}\t${mobileController.text}",
              type: MessageType.error);
        } else {
          if (state.error is FirebaseAuthException) {
            final errorCode = (state.error as FirebaseAuthException).code;
            if (errorCode == 'invalid-credential') {
              HelperUtils.showSnackBarMessage(
                  context, 'You have entered an invalid username or password');
            } else {
              HelperUtils.showSnackBarMessage(context, 'Something went wrong');
            }
          } else {
            HelperUtils.showSnackBarMessage(context, 'Something went wrong');
          }
        }
      }
      if (state is MSuccess) {
        // Widgets.hideLoder(context);
      }
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

  Future<void> getSignature() async {
    signature = await SmsAutoFill().getAppSignature;
    SmsAutoFill().listenForCode;
    setState(() {});
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    if (timer != null) {
      timer!.cancel();
    }

    _passwordController.dispose();
    emailController.dispose();
    mobileController.dispose();
    isLoginWithMobile.dispose();
    super.dispose();
  }

  void _onTapContinue() {
    if (isLoginWithMobile.value) {
      // isOtpSent = true;
      phoneLoginPayload =
          PhoneLoginPayload(mobileController.text, countryCode!);

      context
          .read<AuthenticationCubit>()
          .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
      context.read<AuthenticationCubit>().verify();

      setState(() {});
    } else {
      sendMailClicked = true;
      setState(() {});
    }
  }

  Future<void> sendVerificationCode() async {
    if (widget.isDeleteAccount ?? false) {
      isOtpSent = true;

      context
          .read<AuthenticationCubit>()
          .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
      context.read<AuthenticationCubit>().verify();

      setState(() {});
    }
    final form = _formKey.currentState;

    if (form == null) return;
    form.save();
    //checkbox value should be 1 before Login/SignUp
    if (form.validate()) {
      if (widget.isDeleteAccount ?? false) {
      } else {
        _onTapContinue();
      }
    }
  }

  void setDemoOTP() {
    if (Constant.mobileAuthentication == "1") {
      if (mobileController.text == Constant.demoMobileNumber) {
        otp = Constant.demoModeOTP;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    setDemoOTP();

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
              if (widget.isDeleteAccount ?? false) {
                Navigator.pop(context);
              } else {
                if (isOtpSent) {
                  isLoginWithMobile.value = true;
                  setState(() {
                    isOtpSent = false;
                  });
                } else if (sendMailClicked) {
                  setState(() {
                    sendMailClicked = false;
                  });
                } else {
                  setState(() {
                    isBack = true;
                  });
                  return;
                }
              }
              setState(() {
                isBack = false;
              });
              return;
            },
            child: AnnotatedRegion(
              value: SystemUiOverlayStyle(
                statusBarColor: context.color.backgroundColor,
              ),
              child: Scaffold(
                backgroundColor: context.color.backgroundColor,
                bottomNavigationBar: !isOtpSent && !sendMailClicked
                    ? termAndPolicyTxt()
                    : SizedBox.shrink(),
                body: BlocListener<LoginCubit, LoginState>(
                  listener: (context, state) {
                    if (state is LoginSuccess) {
                      context
                          .read<UserDetailsCubit>()
                          .fill(HiveUtils.getUserDetails());
                      if (state.isProfileCompleted) {
                        HiveUtils.setUserIsAuthenticated(true);
                        if (HiveUtils.getCityName() != null &&
                            HiveUtils.getCityName() != "") {
                          HelperUtils.killPreviousPages(
                              context, Routes.main, {"from": "login"});
                        } else {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              Routes.locationPermissionScreen,
                              (route) => false);
                        }
                      } else {
                        Navigator.pushNamed(
                          context,
                          Routes.completeProfile,
                          arguments: {
                            "from": "login",
                            "popToCurrent": false,
                            "type": isLoginWithMobile.value
                                ? AuthenticationType.phone
                                : AuthenticationType.email,
                            "extraData": {
                              "email": state.credential.user?.email ??
                                  state.apiResponse['email'],
                              "username": state.apiResponse['name'],
                              "mobile": state.apiResponse['mobile'],
                              "countryCode": countryCode
                            }
                          },
                        );
                      }
                    }

                    if (state is LoginFailure) {
                      HelperUtils.showSnackBarMessage(
                          context, state.errorMessage.toString());
                    }
                  },
                  child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
                    listener: (context, state) {
                      if (state is AuthenticationSuccess) {
                        Widgets.hideLoder(context);

                        if (state.type == AuthenticationType.email) {
                          if (state.credential.user!.emailVerified) {
                            context.read<LoginCubit>().login(
                                phoneNumber: state.credential.user!.phoneNumber,
                                firebaseUserId: state.credential.user!.uid,
                                type: state.type.name,
                                credential: state.credential,
                                countryCode: null);
                          }
                        } else if (state.type == AuthenticationType.phone) {
                          context.read<LoginCubit>().login(
                              phoneNumber: (state.payload as PhoneLoginPayload)
                                  .phoneNumber,
                              firebaseUserId: state.credential.user!.uid,
                              type: state.type.name,
                              credential: state.credential,
                              countryCode:
                                  "+${(state.payload as PhoneLoginPayload).countryCode}");
                        } else {
                          context.read<LoginCubit>().login(
                              phoneNumber: state.credential.user!.phoneNumber,
                              firebaseUserId: state.credential.user!.uid,
                              type: state.type.name,
                              credential: state.credential,
                              countryCode: null);
                        }
                      }

                      if (state is AuthenticationFail) {
                        log('- ${state.error}');
                        Widgets.hideLoder(context);
                      }

                      if (state is AuthenticationInProcess) {
                        Widgets.showLoader(context);
                      }
                    },
                    builder: (context, state) {
                      return Builder(builder: (context) {
                        return SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: isOtpSent
                                ? verifyOTPWidget()
                                : buildLoginWidget(),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mobileLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'loginWithPhoneNumber'.translate(context),
          fontSize: context.font.large,
          color: context.color.textColorDark,
        ),
        const SizedBox(
          height: 24,
        ),
        CustomTextFormField(
            controller: mobileController,
            fillColor: context.color.secondaryColor,
            borderColor: context.color.borderColor.darken(30),
            keyboard: TextInputType.phone,
            validator: CustomTextFieldValidator.phoneNumber,
            fixedPrefix: SizedBox(
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
                      )),
                    ),
                  )),
            ),
            hintText: "mobileNumberLbl".translate(context)),
        const SizedBox(
          height: 25,
        ),
        ListenableBuilder(
            listenable: mobileController,
            builder: (context, child) {
              return UiUtils.buildButton(context,
                  onPressed: sendVerificationCode,
                  buttonTitle: 'continue'.translate(context),
                  radius: 10,
                  disabled: mobileController.text.isEmpty,
                  disabledColor: const Color.fromARGB(255, 104, 102, 106));
            }),
      ],
    );
  }

  Widget emailLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'loginWithEmail'.translate(context),
          fontSize: context.font.large,
          color: context.color.textColorDark,
        ),
        const SizedBox(
          height: 24,
        ),
        CustomTextFormField(
            controller: emailController,
            fillColor: context.color.secondaryColor,
            borderColor: context.color.borderColor.darken(30),
            keyboard: TextInputType.emailAddress,
            validator: CustomTextFieldValidator.email,
            hintText: "emailAddress".translate(context)),
        const SizedBox(
          height: 10,
        ),
        CustomTextFormField(
          hintText: "${"password".translate(context)}",
          controller: _passwordController,
          validator: CustomTextFieldValidator.nullCheck,
          obscureText: isObscure,
          suffix: IconButton(
            onPressed: () {
              isObscure = !isObscure;
              setState(() {});
            },
            icon: Icon(
              !isObscure ? Icons.visibility : Icons.visibility_off,
              color: context.color.textColorDark.withValues(alpha: 0.3),
            ),
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
        const SizedBox(
          height: 10,
        ),
        ListenableBuilder(
            listenable:
                Listenable.merge([emailController, _passwordController]),
            builder: (context, child) {
              return UiUtils.buildButton(context, onPressed: () {
                if (_passwordController.text.trim().isEmpty) {
                  HelperUtils.showSnackBarMessage(
                      context, 'Password cannot be empty');
                  return;
                }
                context.read<AuthenticationCubit>().setData(
                    payload: EmailLoginPayload(
                        email: emailController.text,
                        password: _passwordController.text,
                        type: EmailLoginType.login),
                    type: AuthenticationType.email);
                context.read<AuthenticationCubit>().authenticate();
              },
                  buttonTitle: 'signIn'.translate(context),
                  radius: 10,
                  disabled: emailController.text.isEmpty ||
                      _passwordController.text.isEmpty,
                  disabledColor: const Color.fromARGB(255, 104, 102, 106));
            }),
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
                      HiveUtils.setUserSkip();
                      HelperUtils.killPreviousPages(context, Routes.main,
                          {"from": "login", "isSkipped": true});
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: context.color.forthColor.withValues(alpha: 0.102),
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
                "welcomeback".translate(context),
                fontSize: context.font.extraLarge,
                color: context.color.textDefaultColor,
              ),
              const SizedBox(
                height: 8,
              ),
              if (Constant.mobileAuthentication == "1" ||
                  Constant.emailAuthentication == "1")
                ValueListenableBuilder(
                    valueListenable: isLoginWithMobile,
                    builder: (context, isMobileLogin, child) {
                      return isMobileLogin ? mobileLogin() : emailLogin();
                    }),
              const SizedBox(
                height: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (Constant.mobileAuthentication == "1" ||
                      Constant.emailAuthentication == "1")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText("dontHaveAcc".translate(context),
                            color: context.color.textColorDark.brighten(50)),
                        const SizedBox(
                          width: 12,
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, Routes.signupMainScreen);
                            },
                            child: CustomText(
                              "signUp".translate(context),
                              color: context.color.territoryColor,
                              showUnderline: true,
                            ))
                      ],
                    ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (Constant.googleAuthentication == "1" ||
                      Constant.appleAuthentication == "1")
                    googleAndAppleLogin(),
                  if (Constant.mobileAuthentication == "0" ||
                      Constant.emailAuthentication == "0") ...[
                    if ((Constant.googleAuthentication == "1") ||
                        (Constant.appleAuthentication == "1" &&
                            Platform.isIOS)) ...[
                      const SizedBox(
                        height: 65,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText("dontHaveAcc".translate(context),
                              color: context.color.textColorDark.brighten(50)),
                          const SizedBox(
                            width: 12,
                          ),
                          GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                    context, Routes.signupMainScreen);
                              },
                              child: CustomText(
                                "signUp".translate(context),
                                color: context.color.territoryColor,
                                showUnderline: true,
                              ))
                        ],
                      )
                    ],
                  ],
                ],
              ),
              /* const Spacer(),
              termAndPolicyTxt()*/
            ],
          ),
        ),
      ),
    );
  }

  Widget googleAndAppleLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (Constant.mobileAuthentication == "1" ||
            Constant.emailAuthentication == "1")
          if ((Constant.googleAuthentication == "1") ||
              (Constant.appleAuthentication == "1" && Platform.isIOS))
            CustomText("orSignInWith".translate(context),
                color: context.color.textDefaultColor),
        const SizedBox(
          height: 20,
        ),
        if (Constant.googleAuthentication == "1") ...[
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.googleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              buttonColor: secondaryColor_,
              border: context.watch<AppThemeCubit>().state.appTheme !=
                      AppTheme.dark
                  ? BorderSide(
                      color:
                          context.color.textDefaultColor.withValues(alpha: 0.5))
                  : null,
              textColor: textDarkColor, onPressed: () {
            context.read<AuthenticationCubit>().setData(
                payload: GoogleLoginPayload(), type: AuthenticationType.google);
            context.read<AuthenticationCubit>().authenticate();
          },
              radius: 8,
              height: 46,
              buttonTitle: "continueWithGoogle".translate(context)),
          const SizedBox(
            height: 12,
          ),
        ],
        if (Constant.appleAuthentication == "1" && Platform.isIOS) ...[
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.appleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              buttonColor: secondaryColor_,
              border: context.watch<AppThemeCubit>().state.appTheme !=
                      AppTheme.dark
                  ? BorderSide(
                      color:
                          context.color.textDefaultColor.withValues(alpha: 0.5))
                  : null,
              textColor: textDarkColor, onPressed: () {
            context.read<AuthenticationCubit>().setData(
                payload: AppleLoginPayload(), type: AuthenticationType.apple);
            context.read<AuthenticationCubit>().authenticate();
          },
              height: 46,
              radius: 8,
              buttonTitle: "continueWithApple".translate(context)),
          const SizedBox(
            height: 12,
          ),
        ],
        if (Constant.emailAuthentication == "1" &&
            Constant.mobileAuthentication == "1")
          ValueListenableBuilder(
              valueListenable: isLoginWithMobile,
              builder: (context, isMobileField, child) {
                return UiUtils.buildButton(context, onPressed: () {
                  isLoginWithMobile.value = !isLoginWithMobile.value;
                },
                    prefixWidget: Padding(
                        padding: EdgeInsetsDirectional.only(end: 10.0),
                        child: Icon(isMobileField ? Icons.email : Icons.phone)),
                    showElevation: false,
                    buttonColor: secondaryColor_,
                    textColor: textDarkColor,
                    border: context.watch<AppThemeCubit>().state.appTheme !=
                            AppTheme.dark
                        ? BorderSide(
                            color: context.color.textDefaultColor
                                .withValues(alpha: 0.5))
                        : null,
                    height: 46,
                    radius: 8,
                    buttonTitle: (isMobileField
                            ? 'continueWithEmail'
                            : 'continueWithMobile')
                        .translate(context));
              })
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
              color: context.color.textLightColor.withValues(alpha: 0.8),
              fontSize: context.font.small,
              textAlign: TextAlign.center),
          const SizedBox(
            height: 3,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
                child: CustomText("termsOfService".translate(context),
                    color: context.color.territoryColor,
                    fontSize: context.font.small,
                    showUnderline: true),
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
              color: context.color.textLightColor.withValues(alpha: 0.8),
              fontSize: context.font.small,
            ),
            const SizedBox(
              width: 5.0,
            ),
            InkWell(
                child: CustomText(
                  "privacyPolicy".translate(context),
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                  showUnderline: true,
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

  Future<bool> onBackPress() {
    if (widget.isDeleteAccount ?? false) {
      Navigator.pop(context);
    } else {
      if (isOtpSent == true) {
        setState(() {
          isOtpSent = false;
        });
      } else {
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
          CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        flagEmoji = value.flagEmoji;
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget otpInput() {
    return Center(
        child: PinFieldAutoFill(
            decoration: UnderlineDecoration(
              textStyle:
                  TextStyle(fontSize: 20, color: context.color.textColorDark),
              colorBuilder: FixedColorBuilder(context.color.territoryColor),
            ),
            currentCode: otp,
            codeLength: 6,
            onCodeChanged: (String? code) {
              otp = code;
            },
            onCodeSubmitted: (String code) {
              otp = code;
            }));
  }

  Widget verifyOTPWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: FittedBox(
              fit: BoxFit.none,
              child: MaterialButton(
                  onPressed: () {
                    HelperUtils.killPreviousPages(context, Routes.main,
                        {"from": "login", "isSkipped": true});
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: context.color.forthColor.withValues(alpha: 0.102),
                  elevation: 0,
                  height: 28,
                  minWidth: 64,
                  child: CustomText(
                    "skip".translate(context),
                    color: context.color.forthColor,
                  )),
            ),
          ),
          const SizedBox(
            height: 66,
          ),
          CustomText(
            "signInWithMob".translate(context),
            fontSize: context.font.extraLarge,
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              CustomText(
                "+${phoneLoginPayload.countryCode}\t${phoneLoginPayload.phoneNumber}",
                fontSize: context.font.large,
              ),
              const SizedBox(
                width: 5,
              ),
              InkWell(
                  child: CustomText(
                    "change".translate(context),
                    color: context.color.territoryColor,
                    fontSize: context.font.large,
                    showUnderline: true,
                  ),
                  onTap: () => Navigator.pushNamed(context, Routes.login)),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          otpInput(),
          const SizedBox(
            height: 8,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MaterialButton(
              onPressed: () {
                context.read<AuthenticationCubit>().setData(
                      payload: phoneLoginPayload,
                      type: AuthenticationType.phone,
                    );
                context.read<AuthenticationCubit>().verify();
              },
              child: CustomText("resendOTP".translate(context),
                  color: context.color.textColorDark.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(
            height: 19,
          ),
          UiUtils.buildButton(
            context,
            onPressed: () {
              if (otp!.trim().length < 6) {
                HelperUtils.showSnackBarMessage(
                    context, "pleaseEnterSixDigits".translate(context));
              } else {
                phoneLoginPayload.setOTP(otp!.trim());
                context.read<AuthenticationCubit>().authenticate();
              }
            },
            buttonTitle: "signIn".translate(context),
            radius: 8,
          ),
        ],
      ),
    );
  }

  Widget enterPasswordWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: FittedBox(
              fit: BoxFit.none,
              child: MaterialButton(
                onPressed: () {
                  HelperUtils.killPreviousPages(context, Routes.main,
                      {"from": "login", "isSkipped": true});
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: context.color.forthColor.withValues(alpha: 0.102),
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
            "signInWithEmail".translate(context),
            fontSize: context.font.extraLarge,
          ),
          const SizedBox(
            height: 8,
          ),
          const SizedBox(
            height: 19,
          ),
          UiUtils.buildButton(
            context,
            onPressed: () {
              if (_passwordController.text.trim().isEmpty) {
                HelperUtils.showSnackBarMessage(
                    context, 'Password cannot be empty');
                return;
              }
              context.read<AuthenticationCubit>().setData(
                  payload: EmailLoginPayload(
                      email: emailController.text,
                      password: _passwordController.text,
                      type: EmailLoginType.login),
                  type: AuthenticationType.email);
              context.read<AuthenticationCubit>().authenticate();
            },
            buttonTitle: "signIn".translate(context),
            radius: 8,
          ),
        ],
      ),
    );
  }
}
