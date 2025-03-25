import 'package:tlobni/app/routes.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_keys.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.none,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              Navigator.pushNamed(context, Routes.countriesScreen,
                  arguments: {"from": "home"});
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(10)),
              child: UiUtils.getSvg(
                AppIcons.location,
                fit: BoxFit.none,
                color: context.color.territoryColor,
              ),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          ValueListenableBuilder(
              valueListenable: Hive.box(HiveKeys.userDetailsBox).listenable(),
              builder: (context, value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "locationLbl".translate(context),
                      color: context.color.textColorDark,
                      fontSize: context.font.small,
                    ),
                    CustomText(
                      [
                        HiveUtils.getAreaName(),
                        HiveUtils.getCityName(),
                        HiveUtils.getStateName(),
                        HiveUtils.getCountryName()
                      ]
                              .where((element) =>
                                  element != null && element.isNotEmpty)
                              .join(", ")
                              .isEmpty
                          ? "------"
                          : [
                              HiveUtils.getAreaName(),
                              HiveUtils.getCityName(),
                              HiveUtils.getStateName(),
                              HiveUtils.getCountryName()
                            ]
                              .where((element) =>
                                  element != null && element.isNotEmpty)
                              .join(", "),
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      color: context.color.textColorDark,
                      fontSize: context.font.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }
}
