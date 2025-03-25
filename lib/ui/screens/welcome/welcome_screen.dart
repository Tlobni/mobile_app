import 'package:tlobni/app/routes.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),

            // Tlobni Logo
            Image.asset(
              'assets/images/tlobni-logo.png',
              height: 220,
              width: 300,
            ),

            // Welcome Text
            CustomText(
              "Welcome!",
              fontSize: context.font.extraLarge,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2137),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Tagline
            CustomText(
              "Tlobni connects you to the services you need with local providers you trust!",
              fontSize: context.font.normal,
              color: const Color(0xFF0F2137).withOpacity(0.7),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            // Sign In Button
            UiUtils.buildButton(
              context,
              onPressed: () => onTapSignIn(context),
              buttonTitle: 'Sign In',
              radius: 4,
              height: 50,
              buttonColor: const Color(0xFF0F2137),
              textColor: const Color(0xFFE6CBA8),
            ),

            const SizedBox(height: 10),
            UiUtils.buildButton(
              context,
              onPressed: () => navigateToSignup(context),
              buttonTitle: 'Create an Account',
              radius: 4,
              height: 50,
              buttonColor: const Color(0xFF0F2137),
              textColor: const Color(0xFFE6CBA8),
            ),

            const SizedBox(height: 10),
            // Skip for later
            TextButton(
              onPressed: () => skipForNow(context),
              child: CustomText(
                "Skip for later",
                color: const Color(0xFF0F2137).withOpacity(0.6),
                fontSize: context.font.small,
              ),
            ),
            const SizedBox(height: 20),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
