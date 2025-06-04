import 'package:flutter/material.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';

class SkipForLaterButton extends StatelessWidget {
  const SkipForLaterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: TextButton(
        onPressed: () {
          HiveUtils.setUserSkip();
          HelperUtils.killPreviousPages(
            context,
            Routes.main,
            {"from": "login", "isSkipped": true},
          );
        },
        child: Text(
          "Skip for later",
          style: context.textTheme.bodySmall,
        ),
      ),
    );
  }
}
