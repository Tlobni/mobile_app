// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:eClassify/utils/hive_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class LanguageState {}

class LanguageInitial extends LanguageState {}

class LanguageLoader extends LanguageState {
  final dynamic language;

  LanguageLoader(this.language);
}

class LanguageLoadFail extends LanguageState {
  final dynamic error;
  LanguageLoadFail({required this.error});
}

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageInitial());

  void loadCurrentLanguage() {
    var language =
        Hive.box(HiveKeys.languageBox).get(HiveKeys.currentLanguageKey);
    if (language != null) {
      emit(LanguageLoader(language));
    } else {
      emit(LanguageLoadFail(error: "error"));
    }
  }

  void changeLanguages(dynamic map) {
    emit(LanguageLoader(map));
  }

  dynamic currentLanguageCode() {
    return Hive.box(HiveKeys.languageBox)
        .get(HiveKeys.currentLanguageKey)['code'];
  }

  dynamic currentCountryCode() {
    return Hive.box(HiveKeys.languageBox)
        .get(HiveKeys.currentLanguageKey)['country_code'];
  }
}
