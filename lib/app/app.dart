import 'package:eClassify/data/model/personalized/personalized_settings.dart';
import 'package:eClassify/firebase_options.dart';
import 'package:eClassify/main.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

PersonalizedInterestSettings personalizedInterestSettings =
    PersonalizedInterestSettings.empty();

void initApp() async {
  ///Note: this file's code is very necessary and sensitive if you change it, this might affect whole app , So change it carefully.
  ///This must be used do not remove this line
  WidgetsFlutterBinding.ensureInitialized();
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = false;
  }

  ///This is the widget to show uncaught runtime error in this custom widget so that user can know in that screen something is wrong instead of grey screen
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
      print(flutterErrorDetails.exceptionAsString());
      print(flutterErrorDetails.stack);
      return SomethingWentWrong(
        error: flutterErrorDetails,
      );
    };
  }

  if (Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }

  MobileAds.instance.initialize();

  await Hive.initFlutter();
  await Hive.openBox(HiveKeys.userDetailsBox);
  await Hive.openBox(HiveKeys.authBox);
  await Hive.openBox(HiveKeys.languageBox);
  await Hive.openBox(HiveKeys.themeBox);
  await Hive.openBox(HiveKeys.svgBox);
  await Hive.openBox(HiveKeys.jwtToken);
  await Hive.openBox(HiveKeys.historyBox);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) async {
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

      runApp(const EntryPoint());
    },
  );
}
