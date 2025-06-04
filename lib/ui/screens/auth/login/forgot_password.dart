import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/skip_for_later.dart';
import 'package:tlobni/ui/widgets/miscellanious/logo.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

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
        appBar: UiUtils.buildAppBar(context, showBackButton: true, actions: [SkipForLaterButton()]),
        backgroundColor: context.color.backgroundColor,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Logo(),
                const SizedBox(
                  height: 60,
                ),
                HeadingText("forgotPassword".translate(context)),
                const SizedBox(
                  height: 20,
                ),
                DescriptionText("forgotHeadingTxt".translate(context) + '. ' + "forgotSubHeadingTxt".translate(context)),
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
                      return PrimaryButton.text(
                        "submitBtnLbl".translate(context),
                        padding: EdgeInsets.all(20),
                        onPressed: _emailController.text.isEmpty
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus(); //dismiss keyboard
                                Future.delayed(const Duration(seconds: 1)).then((_) async {
                                  if (_formKey.currentState!.validate()) {
                                    try {
                                      final response = await Api.post(
                                        url: Api.forgotPassword,
                                        parameter: {
                                          'email': _emailController.text,
                                        },
                                        options: Options(
                                          followRedirects: true,
                                          receiveDataWhenStatusError: true,
                                        ),
                                      );
                                      print(response);
                                    } catch (e) {
                                      // if (e.type != DioExceptionType.badResponse) return;
                                    }

                                    HelperUtils.showSnackBarMessage(context, "resetPasswordSuccess".translate(context),
                                        type: MessageType.success);
                                    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
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
