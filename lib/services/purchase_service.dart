import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static const String removeAdsId = 'com.travelbudget.removeads';
  static const String _purchasedKey = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  VoidCallback? onPurchaseUpdated;

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => debugPrint('Purchase error: $error'),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<bool> isAdRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_purchasedKey) ?? false;
  }

  Future<void> _setAdRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purchasedKey, value);
  }

  Future<ProductDetails?> getProduct() async {
    final response = await _iap.queryProductDetails({removeAdsId});
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  Future<void> buyRemoveAds() async {
    final product = await getProduct();
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == removeAdsId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _setAdRemoved(true);
          onPurchaseUpdated?.call();
        }
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }
}
