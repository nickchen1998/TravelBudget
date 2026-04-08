import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class IapPromptDialog {
  static const _keyLastShown = 'iap_prompt_last_shown';
  static const _keyDismissedAt = 'iap_prompt_dismissed_at';
  static const _keyAppOpenCount = 'iap_prompt_app_open_count';
  static const _keyAppOpenTriggered = 'iap_prompt_app_open_triggered';

  static const _cooldownDays = 7;
  static const _dismissCooldownDays = 14;
  static const _appOpenThreshold = 10;

  /// Call on every app foreground / home screen build.
  /// Checks two triggers:
  ///   1. Cloud trips >= 80% of limit
  ///   2. App opened N times (one-shot)
  /// Respects cooldown & dismiss windows.
  static Future<bool> showIfNeeded(
    BuildContext context, {
    required int cloudTripCount,
    required int cloudTripLimit,
    required bool adsRemoved,
  }) async {
    if (adsRemoved) return false;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check dismiss cooldown (user tapped "maybe later")
    final dismissedAt = prefs.getInt(_keyDismissedAt) ?? 0;
    if (dismissedAt > 0 &&
        now - dismissedAt < _dismissCooldownDays * 86400000) {
      return false;
    }

    // Check general cooldown
    final lastShown = prefs.getInt(_keyLastShown) ?? 0;
    if (lastShown > 0 && now - lastShown < _cooldownDays * 86400000) {
      return false;
    }

    // Trigger 1: cloud trips near limit (>= 80%)
    final nearLimit =
        cloudTripCount >= (cloudTripLimit * 0.8).round() && cloudTripCount > 0;

    // Trigger 2: app opened N times (one-shot)
    final appOpenTriggered = prefs.getBool(_keyAppOpenTriggered) ?? false;
    bool appOpenReady = false;
    if (!appOpenTriggered) {
      final count = (prefs.getInt(_keyAppOpenCount) ?? 0) + 1;
      await prefs.setInt(_keyAppOpenCount, count);
      if (count >= _appOpenThreshold) {
        appOpenReady = true;
        await prefs.setBool(_keyAppOpenTriggered, true);
      }
    }

    if (!nearLimit && !appOpenReady) return false;

    // Record show time
    await prefs.setInt(_keyLastShown, now);

    if (!context.mounted) return false;

    final purchaseService = PurchaseService();
    final dismissed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IapPromptSheet(purchaseService: purchaseService),
    );

    // User tapped "maybe later" or swiped down
    if (dismissed == true) {
      await prefs.setInt(_keyDismissedAt, now);
    }

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
            onPressed: () => Navigator.pop(context, true),
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
