// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';
import 'dart:io';

import 'package:tlobni/data/cubits/auth/authentication_cubit.dart';
import 'package:tlobni/data/repositories/auth_repository.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginInProgress extends LoginState {}

class LoginSuccess extends LoginState {
  final bool isProfileCompleted;
  final UserCredential credential;
  final Map<String, dynamic> apiResponse;

  LoginSuccess({
    required this.isProfileCompleted,
    required this.credential,
    required this.apiResponse,
  });
}

class LoginFailure extends LoginState {
  final dynamic errorMessage;

  LoginFailure(this.errorMessage);
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  final AuthRepository _authRepository = AuthRepository();

  Future<String?> getDeviceToken() async {
    String? token;
    if (Platform.isIOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    return token;
  }

  // login_cubit.dart
  void loginEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      emit(LoginInProgress());
      // 1. Firebase Authentication
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      // 2. Backend Sanctum Login
      final response =
          await _authRepository.login(email.trim(), password.trim());

      HiveUtils.setJWT(response['token']!);
      log('response: ${response['user']['roles']}');
      log('response: ${response['user']['roles'].first}');

      // Store token
      HiveUtils.setUserData({
        'id': response['user']['id'],
        'name': response['user']['name'],
        'email': response['user']['email'],
        'mobile': response['mobile'],
        'profile': response['profile'],
        'type': response['user']['roles'][0]['name'],
        'firebaseId': response['firebase_id'],
        'fcmId': response['fcm_id'],
        'notification': response['notification'],
        'address': response['address'],
        'categories': response['categories'],
        'phone': response['phone'],
        'gender': response['gender'],
        'location': response['location'],
        'countryCode': response['country_code'],
        'isProfileCompleted': response['isProfileCompleted'] ?? false,
        'showPersonalDetails': response['show_personal_details'],
        'autoApproveItem': true,
        'isVerified': true,
      });

      HiveUtils.setUserIsAuthenticated(true);

      log('STORED TOKEN: ${HiveUtils.getJWT()}');

      emit(LoginSuccess(
        isProfileCompleted: true,
        credential: credential,
        apiResponse: response,
      ));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
