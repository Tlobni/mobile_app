import 'dart:developer';
import 'dart:io';

import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType type;

  const NativeAdWidget({
    super.key,
    required this.type,
  });

  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    if (Constant.isGoogleNativeAdsEnabled != "1") {
      return;
    }
    log('loading');
    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid
          ? Constant.nativeAdIdAndroid //Android interstitial ad id
          : Constant.nativeAdIdIOS,
      factoryId: 'listTile',
      request: const AdManagerAdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
          // Required: Choose a template.
          templateType: widget.type,
          cornerRadius: 10.0),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          setState(() {
            _isAdLoaded = false;
            ad.dispose();
            print('Native ad failed to load: $error');
          });
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return Container(
        constraints: const BoxConstraints(
          minWidth: 320, // minimum recommended width
          minHeight: 320, // minimum recommended height
          maxWidth: 350,
          maxHeight: 350,
        ),
        margin: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 10),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return Container();
  }
}
