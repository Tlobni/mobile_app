import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:flutter/material.dart';

import 'package:tlobni/utils/extensions/extensions.dart';

enum PromoteCardType { text, icon }

class PromotedCard extends StatelessWidget {
  final PromoteCardType type;
  final Color? color;
  const PromotedCard({super.key, required this.type, this.color});

  @override
  Widget build(BuildContext context) {
    if (type == PromoteCardType.icon) {
      return Container(
        // width: 64,
        // height: 24,
        decoration: BoxDecoration(
            color: color ?? context.color.territoryColor,
            borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Center(
              child: CustomText(
            "featured".translate(context),
            color: context.color.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: context.font.smaller,
          )),
        ),
      );
    }

    return Container(
      width: 64,
      height: 24,
      decoration: BoxDecoration(
          color: context.color.territoryColor,
          borderRadius: BorderRadius.circular(4)),
      child: Center(
          child: CustomText(
        "featured".translate(context),
        color: context.color.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: context.font.smaller,
      )),
    );
  }
}
