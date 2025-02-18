import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/data/repositories/system_repository.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/network/network_availability.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchSystemSettingsState {}

class FetchSystemSettingsInitial extends FetchSystemSettingsState {}

class FetchSystemSettingsInProgress extends FetchSystemSettingsState {}

class FetchSystemSettingsSuccess extends FetchSystemSettingsState {
  final Map settings;

  FetchSystemSettingsSuccess({
    required this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'settings': settings,
    };
  }

  factory FetchSystemSettingsSuccess.fromMap(Map<String, dynamic> map) {
    return FetchSystemSettingsSuccess(
      settings: map['settings'] as Map,
    );
  }
}

class FetchSystemSettingsFailure extends FetchSystemSettingsState {
  final String errorMessage;

  FetchSystemSettingsFailure(this.errorMessage);
}

class FetchSystemSettingsCubit extends Cubit<FetchSystemSettingsState> {
  FetchSystemSettingsCubit() : super(FetchSystemSettingsInitial());
  final SystemRepository _systemRepository = SystemRepository();

  Future<void> fetchSettings({bool? forceRefresh}) async {
    try {
      if (forceRefresh != true) {
        if (state is FetchSystemSettingsSuccess) {
          await Future.delayed(
              const Duration(seconds: AppSettings.hiddenAPIProcessDelay));
        } else {
          emit(FetchSystemSettingsInProgress());
        }
      } else {
        emit(FetchSystemSettingsInProgress());
      }

      if (forceRefresh == true) {
        Map settings = await _systemRepository.fetchSystemSettings();
        Constant.currencySymbol =
            _getSetting(settings, SystemSetting.currencySymbol);
        Constant.currencyPositionIsLeft =
            _getSetting(settings, SystemSetting.currencySymbolPosition)
                    as String ==
                'left';
        Constant.maintenanceMode =
            _getSetting(settings, SystemSetting.maintenanceMode);
        Constant.isGoogleBannerAdsEnabled =
            _getSetting(settings, SystemSetting.bannerAdStatus) ?? "";
        Constant.isGoogleInterstitialAdsEnabled =
            _getSetting(settings, SystemSetting.interstitialAdStatus) ?? "";
        Constant.isGoogleNativeAdsEnabled =
            _getSetting(settings, SystemSetting.nativeAdStatus) ?? "";
        Constant.bannerAdIdAndroid =
            _getSetting(settings, SystemSetting.bannerAdAndroidAd) ?? "";
        Constant.bannerAdIdIOS =
            _getSetting(settings, SystemSetting.bannerAdiOSAd) ?? "";
        Constant.interstitialAdIdAndroid =
            _getSetting(settings, SystemSetting.interstitialAdAndroidAd) ?? "";
        Constant.interstitialAdIdIOS =
            _getSetting(settings, SystemSetting.interstitialAdiOSAd) ?? "";
        Constant.nativeAdIdAndroid =
            _getSetting(settings, SystemSetting.nativeAndroidAd) ?? "";
        Constant.nativeAdIdIOS =
            _getSetting(settings, SystemSetting.nativeAdiOSAd) ?? "";
        Constant.defaultLatitude =
            _getSetting(settings, SystemSetting.defaultLatitude) ?? "";
        Constant.defaultLongitude =
            _getSetting(settings, SystemSetting.defaultLongitude) ?? "";

        Constant.playstoreURLAndroid =
            _getSetting(settings, SystemSetting.playStoreLink) ?? "";
        Constant.appstoreURLios =
            _getSetting(settings, SystemSetting.appStoreLink) ?? "";
        Constant.iOSAppId =
            (_getSetting(settings, SystemSetting.appStoreLink) ?? "")
                .toString()
                .split('/')
                .last;

        Constant.mobileAuthentication =
            _getSetting(settings, SystemSetting.mobileAuthentication) ?? "0";
        Constant.googleAuthentication =
            _getSetting(settings, SystemSetting.googleAuthentication) ?? "0";
        Constant.appleAuthentication =
            _getSetting(settings, SystemSetting.appleAuthentication) ?? "0";
        Constant.emailAuthentication =
            _getSetting(settings, SystemSetting.emailAuthentication) ?? "0";

        emit(FetchSystemSettingsSuccess(settings: settings));
      } else {
        if (state is! FetchSystemSettingsSuccess) {
          Map settings = await _systemRepository.fetchSystemSettings();
          Constant.currencySymbol =
              _getSetting(settings, SystemSetting.currencySymbol);
          Constant.maintenanceMode =
              _getSetting(settings, SystemSetting.maintenanceMode);
          Constant.isGoogleBannerAdsEnabled =
              _getSetting(settings, SystemSetting.bannerAdStatus) ?? "";
          Constant.isGoogleInterstitialAdsEnabled =
              _getSetting(settings, SystemSetting.interstitialAdStatus) ?? "";
          Constant.isGoogleNativeAdsEnabled =
              _getSetting(settings, SystemSetting.nativeAdStatus) ?? "";
          Constant.bannerAdIdAndroid =
              _getSetting(settings, SystemSetting.bannerAdAndroidAd) ?? "";
          Constant.bannerAdIdIOS =
              _getSetting(settings, SystemSetting.bannerAdiOSAd) ?? "";
          Constant.interstitialAdIdAndroid =
              _getSetting(settings, SystemSetting.interstitialAdAndroidAd) ??
                  "";
          Constant.interstitialAdIdIOS =
              _getSetting(settings, SystemSetting.interstitialAdiOSAd) ?? "";
          Constant.nativeAdIdAndroid =
              _getSetting(settings, SystemSetting.nativeAndroidAd) ?? "";
          Constant.nativeAdIdIOS =
              _getSetting(settings, SystemSetting.nativeAdiOSAd) ?? "";
          Constant.defaultLatitude =
              _getSetting(settings, SystemSetting.defaultLatitude) ?? "";
          Constant.defaultLongitude =
              _getSetting(settings, SystemSetting.defaultLongitude) ?? "";

          Constant.playstoreURLAndroid =
              _getSetting(settings, SystemSetting.playStoreLink) ?? "";
          Constant.appstoreURLios =
              _getSetting(settings, SystemSetting.appStoreLink) ?? "";
          Constant.iOSAppId =
              (_getSetting(settings, SystemSetting.appStoreLink) ?? "")
                  .toString()
                  .split('/')
                  .last;
          Constant.mobileAuthentication =
              _getSetting(settings, SystemSetting.mobileAuthentication) ?? "0";
          Constant.googleAuthentication =
              _getSetting(settings, SystemSetting.googleAuthentication) ?? "0";
          Constant.appleAuthentication =
              _getSetting(settings, SystemSetting.appleAuthentication) ?? "0";
          Constant.emailAuthentication =
              _getSetting(settings, SystemSetting.emailAuthentication) ?? "0";

          emit(FetchSystemSettingsSuccess(settings: settings));
        } else {
          await CheckInternet.check(
            onInternet: () async {
              Map settings = await _systemRepository.fetchSystemSettings();

              Constant.currencySymbol =
                  _getSetting(settings, SystemSetting.currencySymbol);
              Constant.maintenanceMode =
                  _getSetting(settings, SystemSetting.maintenanceMode);

              Constant.currencySymbol =
                  _getSetting(settings, SystemSetting.currencySymbol);
              Constant.maintenanceMode =
                  _getSetting(settings, SystemSetting.maintenanceMode);

              Constant.isGoogleBannerAdsEnabled =
                  _getSetting(settings, SystemSetting.bannerAdStatus) ?? "";
              Constant.isGoogleInterstitialAdsEnabled =
                  _getSetting(settings, SystemSetting.interstitialAdStatus) ??
                      "";
              Constant.isGoogleNativeAdsEnabled =
                  _getSetting(settings, SystemSetting.nativeAdStatus) ?? "";
              Constant.bannerAdIdAndroid =
                  _getSetting(settings, SystemSetting.bannerAdAndroidAd) ?? "";
              Constant.bannerAdIdIOS =
                  _getSetting(settings, SystemSetting.bannerAdiOSAd) ?? "";
              Constant.interstitialAdIdAndroid = _getSetting(
                      settings, SystemSetting.interstitialAdAndroidAd) ??
                  "";
              Constant.interstitialAdIdIOS =
                  _getSetting(settings, SystemSetting.interstitialAdiOSAd) ??
                      "";
              Constant.nativeAdIdAndroid =
                  _getSetting(settings, SystemSetting.nativeAndroidAd) ?? "";
              Constant.nativeAdIdIOS =
                  _getSetting(settings, SystemSetting.nativeAdiOSAd) ?? "";

              Constant.playstoreURLAndroid =
                  _getSetting(settings, SystemSetting.playStoreLink) ?? "";
              Constant.appstoreURLios =
                  _getSetting(settings, SystemSetting.appStoreLink) ?? "";
              Constant.iOSAppId =
                  (_getSetting(settings, SystemSetting.appStoreLink) ?? "")
                      .toString()
                      .split('/')
                      .last;

              Constant.defaultLatitude =
                  _getSetting(settings, SystemSetting.defaultLatitude) ?? "";
              Constant.defaultLongitude =
                  _getSetting(settings, SystemSetting.defaultLongitude) ?? "";
              Constant.mobileAuthentication =
                  _getSetting(settings, SystemSetting.mobileAuthentication) ??
                      "0";
              Constant.googleAuthentication =
                  _getSetting(settings, SystemSetting.googleAuthentication) ??
                      "0";
              Constant.appleAuthentication =
                  _getSetting(settings, SystemSetting.appleAuthentication) ??
                      "0";
              Constant.emailAuthentication =
                  _getSetting(settings, SystemSetting.emailAuthentication) ??
                      "0";

              emit(FetchSystemSettingsSuccess(settings: settings));
            },
            onNoInternet: () {
              emit(FetchSystemSettingsSuccess(
                  settings: (state as FetchSystemSettingsSuccess).settings));
            },
          );
        }
      }
    } catch (e, st) {
      emit(FetchSystemSettingsFailure(st.toString()));
    }
  }

  dynamic getSetting(SystemSetting selected) {
    if (state is FetchSystemSettingsSuccess) {
      Map settings = (state as FetchSystemSettingsSuccess).settings['data'];
      if (selected == SystemSetting.subscription) {
        //check if we have subscribed to any package if true then return this data otherwise return empty list
        if (settings['subscription'] == true) {
          return settings['package']['user_purchased_package'] as List;
        } else {
          return [];
        }
      }

      if (selected == SystemSetting.language) {
        return settings['languages'];
      }

      if (selected == SystemSetting.demoMode) {
        if (settings.containsKey("demo_mode")) {
          return settings['demo_mode'];
        } else {
          return false;
        }
      }

      /// where selected is equals to type
      var selectedSettingData =
          (settings[Constant.systemSettingKeys[selected]]);

      return selectedSettingData;
    }
  }

  Map getRawSettings() {
    if (state is FetchSystemSettingsSuccess) {
      return (state as FetchSystemSettingsSuccess).settings['data'];
    }
    return {};
  }

  dynamic _getSetting(Map settings, SystemSetting selected) {
    var selectedSettingData =
        settings['data'][Constant.systemSettingKeys[selected]];

    return selectedSettingData;
  }
}
