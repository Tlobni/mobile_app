import 'package:eClassify/app/routes.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildSearchIcon() {
      return Padding(
          padding: EdgeInsetsDirectional.only(start: 16.0, end: 16),
          child: UiUtils.getSvg(AppIcons.search,
              color: context.color.territoryColor));
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: sidePadding, vertical: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.pushNamed(context, Routes.searchScreenRoute, arguments: {
            "autoFocus": true,
          });
        },
        child: AbsorbPointer(
          absorbing: true,
          child: Container(
              width: context.screenWidth,
              height: 56,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                  border: Border.all(
                      width: 1, color: context.color.borderColor.darken(30)),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: context.color.secondaryColor),
              child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    border: InputBorder.none, //OutlineInputBorder()
                    fillColor: Theme.of(context).colorScheme.secondaryColor,
                    hintText: "searchHintLbl".translate(context),
                    hintStyle: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.3)),
                    prefixIcon: buildSearchIcon(),
                    prefixIconConstraints:
                        const BoxConstraints(minHeight: 5, minWidth: 5),
                  ),
                  enableSuggestions: true,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                  onTap: () {
                    //change prefix icon color to primary
                  })),
        ),
      ),
    );
  }
}
