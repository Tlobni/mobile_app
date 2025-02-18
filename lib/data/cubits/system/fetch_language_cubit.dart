// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';

import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchLanguageState {}

class FetchLanguageInitial extends FetchLanguageState {}

class FetchLanguageInProgress extends FetchLanguageState {}

class FetchLanguageSuccess extends FetchLanguageState {
  final String code;
  final String? countryCode;
  final String name;
  final String engName;
  final String image;
  final Map data;
  final bool rtl;

  FetchLanguageSuccess({
    required this.code,
    required this.countryCode,
    required this.name,
    required this.engName,
    required this.data,
    required this.image,
    required this.rtl,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'country_code': countryCode,
      'name': name,
      'name_in_english': engName,
      'image': image,
      'file_name': data,
      'rtl': rtl,
    };
  }

  factory FetchLanguageSuccess.fromMap(Map<String, dynamic> map) {
    return FetchLanguageSuccess(
      code: map['code'] as String,
      countryCode: map['country_code'] as String?,
      name: map['name'] as String,
      engName: map['name_in_english'] as String,
      image: map['image'] as String,
      data: map['file_name'] as Map,
      rtl: map['rtl'] as bool,
    );
  }
}

class FetchLanguageFailure extends FetchLanguageState {
  final String errorMessage;

  FetchLanguageFailure(this.errorMessage);
}

class FetchLanguageCubit extends Cubit<FetchLanguageState> {
  FetchLanguageCubit() : super(FetchLanguageInitial());

  Future<void> getLanguage(String languageCode) async {
    try {
      emit(FetchLanguageInProgress());

      Map<String, dynamic> response = await Api.get(
        url: Api.getLanguageApi,
        queryParameters: {Api.languageCode: languageCode},
      );

      Constant.currentLocale =
          Constant.countryLocaleMap[response['data']['country_code']] ??
              'en_US';
      emit(FetchLanguageSuccess(
          code: response['data']['code'],
          countryCode: response['data']['country_code'],
          rtl: response['data']['rtl'],
          image: response['data']['image'],
          engName: response['data']['name_in_english'],
          data: response['data']['file_name'],
          name: response['data']['name']));
    } catch (e) {
      log(e.toString(), name: 'ERROR');
      emit(FetchLanguageFailure(e.toString()));
    }
  }
}
