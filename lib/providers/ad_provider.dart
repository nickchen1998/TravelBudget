import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

class AdProvider extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  bool _adsRemoved = false;
  bool _loading = true;

  bool get adsRemoved => _adsRemoved;
  bool get showAds => !_adsRemoved && !_loading;
  bool get loading => _loading;
  PurchaseService get purchaseService => _purchaseService;

  Future<void> initialize() async {
    await _purchaseService.initialize();
    _purchaseService.onPurchaseUpdated = _onPurchaseChanged;
    _adsRemoved = await _purchaseService.isAdRemoved();
    _loading = false;
    notifyListeners();
  }

  void _onPurchaseChanged() async {
    _adsRemoved = await _purchaseService.isAdRemoved();
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    await _purchaseService.buyRemoveAds();
  }

  Future<void> restorePurchases() async {
    await _purchaseService.restorePurchases();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
