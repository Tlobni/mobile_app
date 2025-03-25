import 'dart:developer';

import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class HiveUtils {
  ///private constructor
  HiveUtils._();

  static String getJWT() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.jwtToken);
  }

  static void dontShowChooseLocationDialog() {
    Hive.box(HiveKeys.userDetailsBox).put("showChooseLocationDialoge", false);
  }

  static bool isShowChooseLocationDialog() {
    var value = Hive.box(HiveKeys.userDetailsBox).get(
      "showChooseLocationDialoge",
    );

    if (value == null) {
      return true;
    }
    return false;
  }

  static String? getUserId() {
    return Hive.box(HiveKeys.userDetailsBox).get("id").toString();
  }

  static AppTheme getCurrentTheme() {
    var current = Hive.box(HiveKeys.themeBox).get(HiveKeys.currentTheme);

    if (current == null) {
      return AppTheme.light;
    }
    if (current == "light") {
      return AppTheme.light;
    }
    if (current == "dark") {
      return AppTheme.dark;
    }
    return AppTheme.light;
  }

  static String? getCountryCode() {
    return Hive.box(HiveKeys.userDetailsBox).get("country_code");
    //return Hive.box(HiveKeys.userDetailsBox).toMap()['countryCode'];
  }

  static void setProfileNotCompleted() async {
    await Hive.box(HiveKeys.userDetailsBox)
        .put(HiveKeys.isProfileCompleted, false);
  }

  static dynamic setCurrentTheme(AppTheme theme) {
    String newTheme;
    if (theme == AppTheme.light) {
      newTheme = "light";
    } else {
      newTheme = "dark";
    }
    Hive.box(HiveKeys.themeBox).put(HiveKeys.currentTheme, newTheme);
  }

  static void setUserData(Map data) async {
    await Hive.box(HiveKeys.userDetailsBox).putAll(data);
  }

  static void setNearbyRadius(int radius) async {
    await Hive.box(HiveKeys.userDetailsBox).put(HiveKeys.nearbyRadius, radius);
  }

  static dynamic getNearbyRadius() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.nearbyRadius);
  }

  static dynamic getCityName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.city);
  }

  static dynamic getAreaName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.area);
  }

  static dynamic getAreaId() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.areaId);
  }

  static dynamic getStateName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.stateKey);
  }

  static dynamic getCountryName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.countryKey);
  }

  static dynamic getCurrentCityName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.currentLocationCity);
  }

  static dynamic getCurrentAreaName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.currentLocationArea);
  }

  static dynamic getCurrentStateName() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.currentLocationState);
  }

  static dynamic getCurrentCountryName() {
    return Hive.box(HiveKeys.userDetailsBox)
        .get(HiveKeys.currentLocationCountry);
  }

  static dynamic getCurrentLatitude() {
    return Hive.box(HiveKeys.userDetailsBox)
        .get(HiveKeys.currentLocationLatitude);
  }

  static dynamic getCurrentLongitude() {
    return Hive.box(HiveKeys.userDetailsBox)
        .get(HiveKeys.currentLocationLongitude);
  }

  static dynamic getLatitude() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.latitudeKey);
  }

  static dynamic getLongitude() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.longitudeKey);
  }

  static void setJWT(String token) async {
    await Hive.box(HiveKeys.userDetailsBox).put(HiveKeys.jwtToken, token);
  }

  static UserModel getUserDetails() {
    return UserModel.fromJson(
        Map.from(Hive.box(HiveKeys.userDetailsBox).toMap()));
  }

  static void setUserIsAuthenticated(bool value) {
    Hive.box(HiveKeys.authBox).put(HiveKeys.isAuthenticated, value);
  }

/*  static setUserIsNotAuthenticated() async {
    await Hive.box(HiveKeys.authBox).put(HiveKeys.isAuthenticated, false);
  }*/

  static Future<void> setUserIsNotNew() {
    return Hive.box(HiveKeys.authBox).put(HiveKeys.isUserFirstTime, false);
  }

  static Future<void> setUserSkip() {
    return Hive.box(HiveKeys.authBox).put(HiveKeys.isUserSkip, true);
  }

  static bool isLocationFilled() {
    var city = Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.city);
    var state = Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.stateKey);
    var country = Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.countryKey);

    if (city == null && state == null && country == null) {
      return false;
    } else {
      return true;
    }
  }

  static void setLocation(
      {String? city,
      String? state,
      String? country,
      String? area,
      int? areaId,
      double? latitude,
      double? longitude,
      double? radius}) async {
    if (Constant.isDemoModeOn) {
      await Hive.box(HiveKeys.userDetailsBox).putAll({
        HiveKeys.city: "Bhuj",
        HiveKeys.stateKey: "Gujarat",
        HiveKeys.countryKey: "India",
        HiveKeys.areaId: null,
        HiveKeys.area: null,
        HiveKeys.latitudeKey: 23.2533,
        HiveKeys.longitudeKey: 69.6693,
      });
    } else {
      await Hive.box(HiveKeys.userDetailsBox).putAll({
        HiveKeys.city: city ?? null,
        HiveKeys.stateKey: state ?? null,
        HiveKeys.countryKey: country ?? null,
        HiveKeys.areaId: areaId ?? null,
        HiveKeys.area: area ?? null,
        HiveKeys.latitudeKey: latitude ?? null,
        HiveKeys.longitudeKey: longitude ?? null,
        HiveKeys.nearbyRadius: radius ?? null,
      });
    }
  }

  static void setCurrentLocation(
      {required String city,
      required String state,
      required String country,
      latitude,
      longitude,
      String? area}) async {
    if (Constant.isDemoModeOn) {
      await Hive.box(HiveKeys.userDetailsBox).putAll({
        HiveKeys.currentLocationCity: "Bhuj",
        HiveKeys.currentLocationState: "Gujarat",
        HiveKeys.currentLocationCountry: "India",
        HiveKeys.currentLocationArea: null,
        HiveKeys.currentLocationLatitude: 23.2533,
        HiveKeys.currentLocationLongitude: 69.6693
      });
    } else {
      await Hive.box(HiveKeys.userDetailsBox).putAll({
        HiveKeys.currentLocationCity: city,
        HiveKeys.currentLocationState: state,
        HiveKeys.currentLocationCountry: country,
        HiveKeys.currentLocationLatitude: latitude,
        HiveKeys.currentLocationLongitude: longitude,
        HiveKeys.currentLocationArea: area
      });
    }
  }

  static void clearLocation() async {
    await Hive.box(HiveKeys.userDetailsBox).putAll({
      HiveKeys.city: null,
      HiveKeys.stateKey: null,
      HiveKeys.countryKey: null,
    });
  }

  static Future<bool> storeLanguage(
    dynamic data,
  ) async {
    Hive.box(HiveKeys.languageBox).put(HiveKeys.currentLanguageKey, data);
    return true;
  }

  static dynamic getLanguage() {
    return Hive.box(HiveKeys.languageBox).get(HiveKeys.currentLanguageKey);
  }

  @visibleForTesting
  static Future<void> setUserIsNew() {
    //Only testing purpose // not in production
    Hive.box(HiveKeys.authBox).put(HiveKeys.isAuthenticated, false);
    return Hive.box(HiveKeys.authBox).put(HiveKeys.isUserFirstTime, true);
  }

  static bool isUserAuthenticated() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isAuthenticated) ?? false;
  }

  static bool isUserFirstTime() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isUserFirstTime) ?? true;
  }

  static bool isUserSkip() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isUserSkip) ?? false;
  }

  static void logoutUser(context,
      {required VoidCallback onLogout, bool? isRedirect}) async {
    await Hive.box(HiveKeys.userDetailsBox).clear();
    HiveUtils.setUserIsAuthenticated(false);

    //GuestChecker.set(isGuest: true);
    onLogout.call();

    Future.delayed(
      Duration.zero,
      () {
        if (isRedirect ?? true) {
          HelperUtils.killPreviousPages(context, Routes.login, {});
        }
      },
    );
  }

  static String getUserType() {
    if (!isUserAuthenticated()) {
      log("getUserType: User not authenticated, returning Client as default");
      return "Client"; // Default to Client for non-authenticated users
    }

    String? type = Hive.box(HiveKeys.userDetailsBox).get("type");

    if (type == null || type.isEmpty) {
      log("getUserType: No user type found in Hive, defaulting to Client");
      return "Client"; // Default if no type is set
    }

    // Convert legacy types to standardized format if needed
    // if (type == "Provider") {
    //   // Check if we need to be more specific about the provider type
    //   String? businessName =
    //       Hive.box(HiveKeys.userDetailsBox).get("businessName");
    //   if (businessName != null && businessName.isNotEmpty) {
    //     log("getUserType: Provider with business name detected, returning Business type");
    //     return "Business";
    //   }
    // }

    log("getUserType: Returning user type: $type");
    return type;
  }

  static bool isProvider() {
    return getUserType() == "Provider";
  }

  static void clear() async {
    await Hive.box(HiveKeys.userDetailsBox).clear();
    await Hive.box(HiveKeys.historyBox).clear();
    HiveUtils.setUserIsAuthenticated(false);
    //GuestChecker.set(isGuest: true);
  }

  static void setFcmToken(String token) async {
    await Hive.box(HiveKeys.userDetailsBox).put('fcm_token', token);
  }

  static String? getFcmToken() {
    return Hive.box(HiveKeys.userDetailsBox).get('fcm_token');
  }

  static String getJwtToken() {
    return getJWT();
  }
}
