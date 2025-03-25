import 'dart:convert';
import 'dart:io';

import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Basic email login with your backend
  Future<Map<String, dynamic>> loginWithApi({
    required String uid,
    required String type,
    String? fcmId,
    required String email, // Email is required
    String? name,
    String? profile,
  }) async {
    // We no longer handle phone here, removing phone and countryCode references.
    Map<String, String> parameters = {
      Api.firebaseId: uid,
      Api.type: type,
      Api.platformType: Platform.isAndroid ? "android" : "ios",
      if (fcmId != null) Api.fcmId: fcmId,
      Api.email: email,
      if (name != null) Api.name: name,
      // if (profile != null) Api.profile: profile
    };

    // POST to your login API
    Map<String, dynamic> response = await Api.post(
      url: Api.loginApi,
      parameter: parameters,
    );

    return {
      "token": response['token'],
      "data": response['data'],
    };
  }

  /// If you still want to delete a user, you can keep this
  Future<dynamic> deleteUser() async {
    Map<String, dynamic> response = await Api.delete(url: Api.deleteUserApi);
    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await Api.post(
      url: Api.login,
      parameter: {'email': email, 'password': password},
    );
    return {
      "token": response['token'],
      "user": response['user'],
    };
  }

  /// Email-based manual sign-in, if needed
  void loginEmailUser() async {
    // Empty because we're using Firebase + custom backend
  }

  /// Since we no longer do phone authentication, remove sendOTP and verifyOTP if not used
}

class MultiAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> createUserWithEmail({
    required String email,
    required String password,
    required String userType, // "Provider" or "Client"
    String? providerType, // "Expert" or "Business"
    String? fullName,
    String? gender,
    String? location,
    String? city,
    List<String>? categories,
    String? phone,
    bool? phonePublic,
  }) async {
    try {
      // 1️⃣ Firebase Authentication - Create User
      UserCredential credentials =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credentials.user!.uid;

      // 2️⃣ Prepare User Data for your "user-signup" API
      Map<String, dynamic> userData = {
        "email": email,
        "password": password,
        "type": "email",
        "platform_type": Platform.isAndroid ? "android" : "ios",
        "firebase_id": uid,
        "userType": userType,
      };

      if (userType == "Provider") {
        userData["providerType"] = providerType;
        userData["location"] = location;
        userData["city"] = city;
        userData["categories"] = categories?.join(",");
        userData["phone"] = phone;

        if (providerType == "Expert") {
          userData["fullName"] = fullName;
          userData["gender"] = gender;
        } 
      } else {
        userData["fullName"] = fullName;
        userData["gender"] = gender;
        userData["location"] = location;
        userData["city"] = city;
      }

      // 3️⃣ Send data to "user-signup" API
      Map<String, dynamic> response = await Api.post(
        url: Api.loginApi, // This is the correct endpoint for user signup
        parameter: userData,
      );

      // Handle the response based on the actual API response structure
      if (response["status"] == true) {
        return {
          "success": true,
          "data": response, // Pass the entire response
          "firebaseUser": credentials
        };
      } else {
        return {
          "success": false,
          "message": response["message"] ?? "Signup failed"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}
