import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class IapPromptDialog {
  /// Returns true if the prompt was already shown for this trip.
  static Future<bool> _wasShown(int tripId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('iap_prompt_shown_trip_$tripId') ?? false;
  }

  static Future<void> _markShown(int tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iap_prompt_shown_trip_$tripId', true);
  }

  /// Shows the IAP prompt if the user hasn't purchased ad removal
  /// and hasn't seen the prompt for this trip yet.
  /// Returns true if prompt was shown, false if skipped.
  static Future<bool> showIfNeeded(BuildContext context, int tripId) async {
    final purchaseService = PurchaseService();
    final adRemoved = await purchaseService.isAdRemoved();
    if (adRemoved) return false;

    final alreadyShown = await _wasShown(tripId);
    if (alreadyShown) return false;

    await _markShown(tripId);

    if (!context.mounted) return false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IapPromptSheet(purchaseService: purchaseService),
    );
    return true;
  }
}

class _IapPromptSheet extends StatelessWidget {
  final PurchaseService purchaseService;

  const _IapPromptSheet({required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.parchment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.auto_awesome,
            color: AppTheme.orange,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l.removeAdsPromptTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.removeAdsPromptBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.inkLight,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                purchaseService.buyRemoveAds();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l.removeAds,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.maybeLater,
              style: const TextStyle(
                color: AppTheme.inkFaint,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
