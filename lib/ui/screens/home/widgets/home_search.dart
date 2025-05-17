import 'package:flutter/material.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  Widget buildSearchIcon(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(start: 16.0, end: 16),
        child: UiUtils.getSvg(AppIcons.search, color: context.color.territoryColor),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _searchButton(context, 'Browse Item Listings'.translate(context), SearchScreenType.itemListing),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _searchButton(context, 'Browse Providers'.translate(context), SearchScreenType.provider),
          ),
        ],
      ),
    );
  }

  Widget _searchButton(BuildContext context, String text, SearchScreenType destination) => MaterialButton(
        onPressed: () => Navigator.pushNamed(
          context,
          Routes.searchScreenRoute,
          arguments: {'autoFocus': true, 'screenType': destination},
        ),
        padding: EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.primary,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: buttonTextColor),
        ),
      );
}
