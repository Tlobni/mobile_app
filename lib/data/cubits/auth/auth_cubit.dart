import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthProgress extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  bool isAuthenticated = false;

  Authenticated(this.isAuthenticated);
}

class AuthFailure extends AuthState {
  final String errorMessage;

  AuthFailure(this.errorMessage);
}

class AuthCubit extends Cubit<AuthState> {
  //late String name, email, profile, address;
  AuthCubit() : super(AuthInitial()) {
    // checkIsAuthenticated();
  }

  void checkIsAuthenticated() {
    if (HiveUtils.isUserAuthenticated()) {
      //setUserData();
      emit(Authenticated(true));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<Map<String, dynamic>> updateuserdata(BuildContext context,
      {String? name,
      String? email,
      File? fileUserimg,
      String? fcmToken,
      String? notification,
      String? mobile,
      String? countryCode,
      String? country,
      String? city,
      String? state,
      String? categories,
      String? bio,
      String? facebook,
      String? twitter,
      String? instagram,
      String? tiktok,
      int? personalDetail}) async {
    Map<String, dynamic> parameters = {
      Api.name: name ?? '',
      Api.email: email ?? '',
      Api.fcmId: fcmToken ?? '',
      Api.notification: notification,
      Api.mobile: mobile,
      Api.city: city,
      Api.country: country,
      Api.state: state,
      Api.countryCode: countryCode,
      Api.personalDetail: personalDetail,
      Api.country: country ?? '',
      'categories': categories ?? '',
      'bio': bio ?? '',
      'facebook': facebook ?? '',
      'twitter': twitter ?? '',
      'instagram': instagram ?? '',
      'tiktok': tiktok ?? '',
    };
    if (fileUserimg != null) {
      parameters['profile'] = await MultipartFile.fromFile(fileUserimg.path);
    }

    try {
      var response = await Api.post(url: Api.updateProfileApi, parameter: parameters);
      if (!response[Api.error]) {
        HiveUtils.setUserData(response['data']);
        //checkIsAuthenticated();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  void signOut(BuildContext context) async {
    if ((state as Authenticated).isAuthenticated) {
      HiveUtils.logoutUser(context, onLogout: () {});
      emit(Unauthenticated());
    }
  }
}
