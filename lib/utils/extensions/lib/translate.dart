import 'package:tlobni/app/app_localization.dart';
import 'package:flutter/cupertino.dart';

extension TranslateString on String {
  String translate(BuildContext context) {
    return (AppLocalization.of(context)!.getTranslatedValues(this) ?? this)
        .trim();
  }
}
