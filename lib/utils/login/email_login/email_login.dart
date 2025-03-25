import 'package:tlobni/utils/login/lib/login_status.dart';
import 'package:tlobni/utils/login/lib/login_system.dart';
import 'package:tlobni/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailLogin extends LoginSystem {
  @override
  Future<UserCredential?> login() async {
    UserCredential? userCredential;
    if (payload is EmailLoginPayload) {
      var payloadData = (payload as EmailLoginPayload);

      if (payloadData.type == EmailLoginType.signup) {
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: payloadData.email,
          password: payloadData.password,
        );
        emit(MSuccess());
      } else {
        try {
          userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: payloadData.email,
            password: payloadData.password,
          );
        } on Exception catch (e) {
          emit(MFail(e));
        }
      }
    }
    return userCredential;
  }

  @override
  void onEvent(MLoginState state) {}
}
