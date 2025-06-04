import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/secondary_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  static BlurredRouter route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const WelcomeScreen(),
    );
  }

  /// Handle sign in button tap
  void onTapSignIn(BuildContext context) {
    // Navigate to the login screen
    Navigator.pushNamed(context, Routes.login);
  }

  /// Open Signup Screen
  void navigateToSignup(BuildContext context) {
    Navigator.pushNamed(context, Routes.accountType);
  }

  /// Skip for now
  void skipForNow(BuildContext context) {
    HiveUtils.setUserSkip();
    HelperUtils.killPreviousPages(
      context,
      Routes.main,
      {"from": "welcome", "isSkipped": true},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is already authenticated, and if so, redirect to main screen
    if (HiveUtils.isUserAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HelperUtils.killPreviousPages(
          context,
          Routes.main,
          {"from": "welcome"},
        );
      });
      // Return a loading placeholder while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: buildWelcomeScreen(context),
    );
  }

  Widget buildWelcomeScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),

            // Tlobni Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/tlobni-logo.png',
                  height: 100,
                  width: 180,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Welcome Text
            HeadingText(
              "Welcome to Tlobni",
              textAlign: TextAlign.center,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 30),

            // Tagline
            DescriptionText(
              "Elite Providers. Premium Services\nUnforgettable Experiences\nBook Now",
              textAlign: TextAlign.center,
              color: kColorGrey,
            ),

            const SizedBox(height: 60),

            PrimaryButton.text(
              'Sign in',
              onPressed: () => onTapSignIn(context),
              weight: FontWeight.w600,
              padding: EdgeInsets.all(20),
            ),

            const SizedBox(height: 20),

            SecondaryButton.text(
              'Create an Account',
              onPressed: () => navigateToSignup(context),
              weight: FontWeight.w700,
              padding: EdgeInsets.all(20),
            ),

            // // Sign In Button
            // UiUtils.buildButton(
            //   context,
            //   onPressed: () => onTapSignIn(context),
            //   buttonTitle: 'Sign In',
            //   radius: 4,
            //   height: 50,
            //   buttonColor: const Color(0xFF0F2137),
            //   textColor: const Color(0xFFE6CBA8),
            // ),
            //
            // const SizedBox(height: 10),
            // UiUtils.buildButton(
            //   context,
            //   onPressed: () => navigateToSignup(context),
            //   buttonTitle: 'Create an Account',
            //   radius: 4,
            //   height: 50,
            //   buttonColor: const Color(0xFF0F2137),
            //   textColor: const Color(0xFFE6CBA8),
            // ),

            const SizedBox(height: 30),
            // Skip for later
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => skipForNow(context),
                  child: Text(
                    "Skip for later",
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
