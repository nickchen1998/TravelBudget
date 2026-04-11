import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';

class AdProvider extends ChangeNotifier {
  static const int freeCloudTripLimit = 3;
  static const int premiumCloudTripLimit = 20;

  final PurchaseService _purchaseService = PurchaseService();
  bool _adsRemoved = false;
  bool _loading = true;

  bool get adsRemoved => _adsRemoved;
  bool get showAds => !_adsRemoved && !_loading;
  bool get loading => _loading;
  int get cloudTripLimit =>
      _adsRemoved ? premiumCloudTripLimit : freeCloudTripLimit;
  PurchaseService get purchaseService => _purchaseService;

  Future<void> initialize() async {
    await _purchaseService.initialize();
    _purchaseService.onPurchaseUpdated = _onPurchaseChanged;
    _adsRemoved = await _purchaseService.isAdRemoved();
    _loading = false;
    if (!_adsRemoved) {
      InterstitialAdManager.instance.preload();
    }
    notifyListeners();
  }

  void _onPurchaseChanged() async {
    _adsRemoved = await _purchaseService.isAdRemoved();
    if (_adsRemoved) {
      InterstitialAdManager.instance.dispose();
    } else {
      // Refund or purchase reverted — re-arm interstitials
      InterstitialAdManager.instance.preload();
    }
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    await _purchaseService.buyRemoveAds();
  }

  /// Returns true if at least one purchase was actually restored.
  Future<bool> restorePurchases() async {
    bool restored = false;
    final original = _purchaseService.onPurchaseUpdated;
    _purchaseService.onPurchaseUpdated = () {
      restored = true;
      _onPurchaseChanged();
    };
    await _purchaseService.restorePurchases();
    // Give StoreKit time to deliver restored transactions
    await Future.delayed(const Duration(seconds: 3));
    _purchaseService.onPurchaseUpdated = original;
    return restored;
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
