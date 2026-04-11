import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';

class AdProvider extends ChangeNotifier {
  static const int freeCloudTripLimit = 3;
  static const int premiumCloudTripLimit = 20;

  final PurchaseService _purchaseService = PurchaseService();
  bool _adsRemoved = false;
  bool _loading = true;
  // Mirror of profiles.is_premium from Supabase. Used so the client limit
  // matches what the server trigger will enforce — especially important on
  // a fresh install of a user who previously purchased on another device
  // and hasn't restored purchases yet.
  bool _serverPremium = false;

  bool get adsRemoved => _adsRemoved;
  // Ads themselves stay tied to the local IAP receipt — we can't trust
  // a server flag to remove ads without a receipt.
  bool get showAds => !_adsRemoved && !_loading;
  bool get loading => _loading;
  // Trip limit uses either signal — if the server already says premium,
  // show 20 so the user's view agrees with what the server will allow.
  bool get _isPremium => _adsRemoved || _serverPremium;
  int get cloudTripLimit =>
      _isPremium ? premiumCloudTripLimit : freeCloudTripLimit;
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
    // Fire-and-forget — not critical for initial render.
    syncPremiumFromServer();
  }

  /// Fetches `profiles.is_premium` from Supabase and caches it. Call after
  /// login so the client limit matches what the server trigger enforces.
  /// No-op if not logged in. Swallows errors silently (offline-friendly).
  Future<void> syncPremiumFromServer() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (_serverPremium) {
        _serverPremium = false;
        notifyListeners();
      }
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('is_premium')
          .eq('id', user.id)
          .maybeSingle();
      final next = (row?['is_premium'] as bool?) ?? false;
      if (next != _serverPremium) {
        _serverPremium = next;
        notifyListeners();
      }
    } catch (_) {
      // Keep previous value on failure
    }
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
