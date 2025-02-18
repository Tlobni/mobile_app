import 'dart:io';

import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static int? forceResendingToken;

  Future<Map<String, dynamic>> numberLoginWithApi(
      {String? phone,
      required String uid,
      required String type,
      String? fcmId,
      String? email,
      String? name,
      String? profile,
      String? countryCode}) async {
    Map<String, String> parameters = {
      if (phone != null) Api.mobile: phone,
      Api.firebaseId: uid,
      Api.type: type,
      Api.platformType: Platform.isAndroid ? "android" : "ios",
      if (fcmId != null) Api.fcmId: fcmId,
      if (email != null) Api.email: email,
      if (name != null) Api.name: name,
      if (countryCode != null) Api.countryCode: countryCode,
      //if (profile != null) Api.profile: profile
    };

    Map<String, dynamic> response = await Api.post(
      url: Api.loginApi,
      parameter: parameters, /* useAuthToken: false*/
    );

    return {"token": response['token'], "data": response['data']};
  }

  Future<dynamic> deleteUser() async {
    Map<String, dynamic> response = await Api.delete(
      url: Api.deleteUserApi,
    );

    return response;
  }

  void loginEmailUser() async {}

  Future<void> sendOTP(
      {required String phoneNumber,
      required Function(String verificationId) onCodeSent,
      Function(dynamic e)? onError}) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      timeout: Duration(
        seconds: Constant.otpTimeOutSecond,
      ),
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onError?.call(ApiException(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        forceResendingToken = resendToken;
        onCodeSent.call(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> verifyOTP({
    required String otpVerificationId,
    required String otp,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: otpVerificationId, smsCode: otp);
    UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return userCredential;
  }
}

class MultiAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> createUserWithEmail(
      {required String email, required String password}) async {
    try {
      UserCredential credentials =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credentials;
    } catch (e) {
      rethrow;
    }
  }
}
