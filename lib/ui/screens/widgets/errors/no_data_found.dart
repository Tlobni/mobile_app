import 'package:flutter/material.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class NoDataFound extends StatelessWidget {
  final double? height;
  final String? mainMessage;
  final String? subMessage;
  final VoidCallback? onTap;

  const NoDataFound({
    super.key,
    this.onTap,
    this.height,
    this.mainMessage,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            // height: height ?? 200,
            child: UiUtils.getSvg(
              AppIcons.no_data_found,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          DescriptionText(
            mainMessage == null ? "nodatafound".translate(context) : mainMessage!,
            fontSize: context.font.extraLarge,
            color: context.color.territoryColor,
            textAlign: TextAlign.center,
            weight: FontWeight.w600,
          ),
          const SizedBox(
            height: 14,
          ),
          CustomText(
            subMessage == null ? "sorryLookingFor".translate(context) : subMessage!,
            fontSize: context.font.larger,
            textAlign: TextAlign.center,
          ),
          // CustomText(UiUtils.getTranslatedLabel(context, "nodatafound")),
          // TextButton(
          //     onPressed: onTap,
          //     style: ButtonStyle(
          //         overlayColor: MaterialStateItem.all(
          //             context.color.teritoryColor.withOpacity(0.2))),
          //     child: const CustomText("Retry").color(context.color.teritoryColor))
        ],
      ),
    );
  }
}
