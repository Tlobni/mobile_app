import 'package:tlobni/data/helper/custom_exception.dart';
import 'package:tlobni/data/model/company.dart';
import 'package:tlobni/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyFetchProgress extends CompanyState {}

class CompanyFetchSuccess extends CompanyState {
  Company companyData;

  CompanyFetchSuccess(this.companyData);
}

class CompanyFetchFailure extends CompanyState {
  final String errmsg;

  CompanyFetchFailure(this.errmsg);
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit() : super(CompanyInitial());

  void fetchCompany(BuildContext context) {
    emit(CompanyFetchProgress());
    fetchCompanyFromDb(context)
        .then((value) => emit(CompanyFetchSuccess(value)))
        .catchError((e) => emit(CompanyFetchFailure(e.toString())));
  }

  Future<Company> fetchCompanyFromDb(BuildContext context) async {
    try {
      Company companyData = Company();

      Map<String, String> body = {};

      var response =
          await Api.get(url: Api.getSystemSettingsApi, queryParameters: body);

      if (!response[Api.error]) {
        var data = response['data'];

        companyData = Company(
            companyEmail: data['company_email'],
            companyName: data['company_name'],
            companyTel1: data['company_tel1'],
            companyTel2: data['company_tel2']);
      } else {
        throw CustomException(response[Api.message]);
      }

      return companyData;
    } catch (e) {
      rethrow;
    }
  }
}
