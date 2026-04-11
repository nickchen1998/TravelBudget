import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _bannerAdUnitId = 'ca-app-pub-3622409368808013/1217343003';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2435281174';

  static const String _interstitialAdUnitId =
      'ca-app-pub-3622409368808013/3044343226';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Use test ads during development, real ads in release mode.
  static String get bannerAdUnitId {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _bannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _interstitialAdUnitId;
    }
    return _testInterstitialAdUnitId;
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

/// Singleton manager for interstitial ads shown after trip creation.
///
/// Frequency rules:
///   - Skipped entirely when `adsRemoved == true`
///   - Attempted every Nth trip creation (default: every 2nd)
///   - Min interval between shows: 60 seconds (guards rapid-fire)
///   - If ad is not loaded when the attempt fires, silently skip and
///     kick off a preload so the next attempt can succeed
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  static const int _showEveryNCreates = 2;
  static const int _minIntervalSeconds = 60;

  InterstitialAd? _ad;
  bool _isLoading = false;
  int _createCount = 0;
  DateTime? _lastShownAt;

  /// Starts loading an interstitial ad if one isn't already loaded or loading.
  /// Safe to call multiple times — subsequent calls are no-ops.
  void preload() {
    if (_ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _ad = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Call after a trip is created successfully. Fire-and-forget.
  Future<void> maybeShowAfterTripCreate({required bool adsRemoved}) async {
    if (adsRemoved) return;

    _createCount += 1;
    if (_createCount % _showEveryNCreates != 0) {
      // Not this time — make sure one is warmed up for the next attempt
      preload();
      return;
    }

    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!).inSeconds <
            _minIntervalSeconds) {
      return;
    }

    final ad = _ad;
    if (ad == null) {
      // Not loaded in time — skip this round and preload for next
      preload();
      return;
    }

    _ad = null; // consumed
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        preload();
      },
    );
    _lastShownAt = DateTime.now();
    await ad.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
