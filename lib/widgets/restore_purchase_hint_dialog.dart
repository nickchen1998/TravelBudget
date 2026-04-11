import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/ad_provider.dart';

/// Shown when the server says this account is premium but the local device
/// has no IAP receipt — typically a new device after login, before Restore
/// Purchase has been tapped. Guides the user straight to restore so they
/// stop seeing ads they already paid to remove.
class RestorePurchaseHintDialog {
  static const _keyLastShown = 'restore_hint_last_shown';
  static const _cooldownDays = 7;

  /// Call when `adProvider.needsRestoreHint` becomes true. Respects a 7-day
  /// cooldown so a user who dismisses isn't nagged on every launch.
  static Future<void> showIfNeeded(BuildContext context) async {
    final adProvider = context.read<AdProvider>();
    if (!adProvider.needsRestoreHint) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastShown = prefs.getInt(_keyLastShown) ?? 0;
    if (lastShown > 0 && now - lastShown < _cooldownDays * 86400000) {
      return;
    }
    await prefs.setInt(_keyLastShown, now);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => const _RestoreHintSheet(),
    );
  }
}

class _RestoreHintSheet extends StatelessWidget {
  const _RestoreHintSheet();

  Future<void> _handleRestore(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final adProvider = context.read<AdProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final restored = await adProvider.restorePurchases();
      messenger.showSnackBar(
        SnackBar(
          content: Text(restored ? l.purchaseRestored : l.noPurchaseFound),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l.purchaseFailed}: $e')),
      );
    }
  }

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
            Icons.workspace_premium_outlined,
            color: AppTheme.orange,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l.restoreHintTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.restoreHintBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.inkLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleRestore(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l.restorePurchase,
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
