import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _bannerAdUnitId = 'ca-app-pub-3622409368808013/1217343003';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2435281174';

  /// Use test ads during development, real ads in release mode.
  static String get bannerAdUnitId {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _bannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({required VoidCallback onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }
}
