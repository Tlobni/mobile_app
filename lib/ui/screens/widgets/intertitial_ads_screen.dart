import 'dart:io';

import 'package:eClassify/utils/constant.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static final AdHelper _instance = AdHelper._internal();

  factory AdHelper() {
    return _instance;
  }

  AdHelper._internal();

  static InterstitialAd? _interstitialAd;

  static bool isAdLoaded = false;

  static void loadInterstitialAd() {
    if (Constant.isGoogleInterstitialAdsEnabled != "1") {
      return;
    }
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? Constant.interstitialAdIdAndroid //Android interstitial ad id
            : Constant.interstitialAdIdIOS, //iOS interstitial ad id
        request: AdRequest(
          nonPersonalizedAds: true,
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            isAdLoaded = true;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            isAdLoaded = false;
            _interstitialAd = null;
          },
        ));
  }

  static void showInterstitialAd() {
    if (Constant.isGoogleInterstitialAdsEnabled != "1") {
      return;
    }
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
