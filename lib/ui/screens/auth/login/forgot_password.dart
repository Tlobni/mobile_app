import 'dart:developer';

import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static BlurredRouter route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const ForgotPasswordScreen(),
    );
  }

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: Form(
          key: _formKey,
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
                        )),
                  ),
                ),
                const SizedBox(
                  height: 66,
                ),
                CustomText(
                  "forgotPassword".translate(context),
                  fontSize: context.font.extraLarge,
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomText(
                  "forgotHeadingTxt".translate(context),
                  fontSize: context.font.large,
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomText(
                  "forgotSubHeadingTxt".translate(context),
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
                const SizedBox(
                  height: 24,
                ),
                CustomTextFormField(
                    controller: _emailController,
                    keyboard: TextInputType.emailAddress,
                    hintText: "emailAddress".translate(context),
                    validator: CustomTextFieldValidator.email),
                const SizedBox(
                  height: 25,
                ),
                ListenableBuilder(
                    listenable: _emailController,
                    builder: (context, child) {
                      log('build');
                      return UiUtils.buildButton(
                        context,
                        disabled: _emailController.text.isEmpty,
                        disabledColor: const Color.fromARGB(255, 104, 102, 106),
                        buttonTitle: "submitBtnLbl".translate(context),
                        radius: 8,
                        onPressed: () async {
                          FocusScope.of(context).unfocus(); //dismiss keyboard
                          Future.delayed(const Duration(seconds: 1))
                              .then((_) async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await _auth
                                    .sendPasswordResetEmail(
                                        email: _emailController.text)
                                    .then((value) {
                                  HelperUtils.showSnackBarMessage(context,
                                      "resetPasswordSuccess".translate(context),
                                      type: MessageType.success);
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      Routes.login, (route) => false);
                                });
                              } on FirebaseAuthException catch (e) {
                                if (e.code == 'user-not-found') {
                                  HelperUtils.showSnackBarMessage(context,
                                      "userNotFound".translate(context),
                                      type: MessageType.error);
                                } else {
                                  HelperUtils.showSnackBarMessage(
                                      context, e.toString(),
                                      type: MessageType.error);
                                }
                              }
                            }
                          });
                        },
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
