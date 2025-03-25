import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SellerVerificationCompleteScreen extends StatefulWidget {
  const SellerVerificationCompleteScreen({
    super.key,
  });

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return SellerVerificationCompleteScreen();
      },
    );
  }

  @override
  _SellerVerificationCompleteScreenState createState() =>
      _SellerVerificationCompleteScreenState();
}

class _SellerVerificationCompleteScreenState
    extends State<SellerVerificationCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isBack = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // Adjust duration as needed
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1.5), // Off-screen initially
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(const Duration(seconds: 0), () {
      if (mounted)
        setState(() {
          Future.delayed(const Duration(seconds: 1), () {
            _slideController.forward();
          }); // Start slide animation
        });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleBackButtonPressed() {
    if (_slideController.isAnimating) {
      setState(() {
        isBack = false;
      });
      // Don't allow popping while the animation is playing
      return;
    } else {
      // Navigate back to the home screen
      _navigateBackToProfile();
      return;
    }
  }

  void _navigateBackToProfile() {
    if (mounted)
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context, 'refresh');
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isBack,
      onPopInvokedWithResult: (didPop, result) async {
        // Handle back button press
        _handleBackButtonPressed();
      },
      child: Scaffold(
        appBar: UiUtils.buildAppBar(context, onBackPress: () {
          _navigateBackToProfile();
        }, showBackButton: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset("assets/lottie/${Constant.successItemLottieFile}",
                  repeat: false),
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: CustomText(
                          'userVerificationCompleted'.translate(context),
                          fontSize: context.font.extraLarge,
                          fontWeight: FontWeight.w600,
                          color: context.color.territoryColor,
                          textAlign: TextAlign.center,
                        )),
                    SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: CustomText(
                        'sellerDocApproveLbl'.translate(context),
                        textAlign: TextAlign.center,
                        fontSize: context.font.larger,
                        color: context.color.textDefaultColor,
                      ),
                    ),
                    SizedBox(height: 60),
                    InkWell(
                      onTap: () {
                        _navigateBackToProfile();
                      },
                      child: Container(
                        height: 46,
                        alignment: AlignmentDirectional.center,
                        margin: EdgeInsets.symmetric(
                            horizontal: sidePadding, vertical: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: context.color.territoryColor),
                        child: CustomText("backToProfile".translate(context),
                            color: context.color.secondaryColor,
                            textAlign: TextAlign.center,
                            fontSize: context.font.larger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ), // Placeholder
        ),
      ),
    );
  }
}
