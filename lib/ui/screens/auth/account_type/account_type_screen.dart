import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({Key? key}) : super(key: key);

  static BlurredRouter route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const AccountTypeScreen(),
    );
  }

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  // Available account types
  final List<String> _accountTypes = ['Client', 'Expert', 'Business'];

  // Selected account type (null by default, meaning no selection)
  String? _selectedAccountType;

  @override
  void initState() {
    super.initState();

    // Check if user is already authenticated and redirect to main screen if so
    if (HiveUtils.isUserAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HelperUtils.killPreviousPages(
          context,
          Routes.main,
          {"from": "account_type"},
        );
      });
    }
  }

  void _navigateToSignup() {
    // Only navigate if an account type is selected
    if (_selectedAccountType != null) {
      Navigator.pushNamed(
        context,
        Routes.signup,
        arguments: {
          'userType': _selectedAccountType == 'Client' ? 'Client' : 'Provider',
          'providerType':
              _selectedAccountType == 'Client' ? null : _selectedAccountType,
        },
      );
    }
  }

  /// Skip for now
  void _skipForNow() {
    HiveUtils.setUserSkip();
    HelperUtils.killPreviousPages(
      context,
      Routes.main,
      {"from": "accountType", "isSkipped": true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _skipForNow,
                child: CustomText(
                  "Skip for later",
                  color: const Color(0xFF0F2137).withOpacity(0.6),
                  fontSize: context.font.small,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tlobni Logo
            Center(
              child: Image.asset(
                'assets/images/tlobni-logo.png',
                height: 80,
                width: 100,
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Center(
              child: CustomText(
                "Account Type",
                fontSize: context.font.extraLarge,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F2137),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Center(
              child: CustomText(
                "Let us know more about you",
                fontSize: context.font.large,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // Account Type Options
            ...List.generate(_accountTypes.length, (index) {
              final accountType = _accountTypes[index];
              return _buildAccountTypeOption(accountType, index);
            }),

            const Spacer(),

            // Next Button - disabled when no selection
            Center(
              child: UiUtils.buildButton(
                context,
                onPressed: _navigateToSignup,
                buttonTitle: 'Next',
                radius: 8,
                height: 50,
                width: MediaQuery.of(context).size.width * 0.9,
                buttonColor: const Color(0xFF0F2137),
                disabled: false,
                disabledColor: const Color.fromARGB(255, 104, 102, 106),
                textColor: const Color(0xFFE6CBA8),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption(String accountType, int index) {
    bool isSelected = _selectedAccountType == accountType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = accountType;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: index == 0 ? 30 : 10),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE6CBA8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: CustomText(
                accountType,
                fontSize: context.font.large,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F2137),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F2137),
                    width: 2,
                  ),
                  color:
                      isSelected ? const Color(0xFF0F2137) : Colors.transparent,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.circle,
                          size: 12,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
