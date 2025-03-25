import 'package:tlobni/utils/login/lib/login_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:tlobni/utils/login/lib/login_system.dart';

class AppleLogin extends LoginSystem {
  OAuthCredential? credential;
  OAuthProvider? oAuthProvider;

  @override
  void init() async {}

  Future<UserCredential?> login() async {
    try {
      emit(MProgress());

      final AuthorizationCredentialAppleID appleIdCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      oAuthProvider = OAuthProvider('apple.com');
      if (oAuthProvider != null) {
        credential = oAuthProvider!.credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );

        final UserCredential userCredential =
            await firebaseAuth.signInWithCredential(credential!);

        if (userCredential.additionalUserInfo!.isNewUser) {
          final String givenName = appleIdCredential.givenName ?? "";
          final String familyName = appleIdCredential.familyName ?? "";

          await userCredential.user!
              .updateDisplayName("$givenName $familyName");
          await userCredential.user!.reload();
        }

        emit(MSuccess());

        return userCredential;
      }
      return null;
    } catch (e) {
      print("apple error catch***${e.toString()}");
      emit(MFail(e));
      throw e;
    }
  }

  @override
  void onEvent(MLoginState state) {
    print("Login state is $state");
  }
}
