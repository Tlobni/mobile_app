import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? timer;
  bool isVerified = false;

  @override
  void initState() {
    initFunction();
    super.initState();
  }

  void initFunction() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool? emailVerified = FirebaseAuth.instance.currentUser?.emailVerified;
      await FirebaseAuth.instance.currentUser?.reload();
      if (emailVerified == true) {
        Future.delayed(
          Duration.zero,
          () async {
            if (isVerified == false) {
              isVerified = true;
              setState(() {});

              await Future.delayed(const Duration(seconds: 2));

              Navigator.pushReplacementNamed(context, Routes.login);
              return;
            }
            // timer.cancel();
          },
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) async {
            if (state is AuthenticationSuccess) {}

            if (state is AuthenticationFail) {}
          },
          builder: (context, state) {
            if (state is AuthenticationInProcess) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is AuthenticationSuccess) {
              return Padding(
                padding: const EdgeInsets.all(18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(AppIcons.verificationMail),
                      const SizedBox(
                        height: 38,
                      ),
                      CustomText(
                        "youHaveGotEmail".translate(context),
                        fontSize: context.font.extraLarge,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      CustomText("clickLinkInYourEmail".translate(context)),
                      const SizedBox(
                        height: 58,
                      ),
                      MaterialButton(
                        onPressed: () {
                          if (!isVerified) {
                            openEmailAppToList();
                          }
                        },
                        elevation: 0,
                        minWidth: double.infinity,
                        height: 46,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: isVerified
                            ? context.color.territoryColor
                            : context.color.textLightColor,
                        child: CustomText(
                          isVerified
                              ? "verified".translate(context)
                              : "checkMail".translate(context),
                          color: context.color.buttonColor,
                          fontSize: context.font.large,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is AuthenticationFail) {
              return Center(
                child: CustomText(state.error.toString()),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }

  void openEmailAppToList() async {
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK]);

      intent.launch();
    } else if (Platform.isIOS) {
      await launchUrlString("message://");
    }
  }
}
