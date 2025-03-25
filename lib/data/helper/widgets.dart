import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Widgets {
  static bool isLoadingShowing = false;
  static void showLoader(BuildContext context) async {
    if (isLoadingShowing) {
      return;
    }
    isLoadingShowing = true;
    showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (BuildContext context) {
          return AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.black.withOpacity(0),
            ),
            child: SafeArea(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  return;
                },
                child: Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
              ),
            ),
          );
        });
  }

  static void hideLoder(BuildContext context) {
    if (isLoadingShowing) {
      isLoadingShowing = false;
      Navigator.of(context).pop();
    }
  }

  static Center noDataFound(String errorMsg) {
    return Center(child: CustomText(errorMsg));
  }
}
