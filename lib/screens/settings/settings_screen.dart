import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/trip_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentLocale = context.watch<LocaleProvider>().locale;
    final currentLocaleKey = currentLocale.countryCode != null
        ? '${currentLocale.languageCode}_${currentLocale.countryCode}'
        : currentLocale.languageCode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAccountSection(context, l),
        const SizedBox(height: 16),
        _sectionCard(
          title: l.about,
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.info_outline,
                title: l.version,
                trailing: const Text('1.2.0',
                    style: TextStyle(color: AppTheme.inkFaint)),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: '扣握貝果-CodeWorldBagel'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已複製'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: _settingsTile(
                  icon: Icons.person_outline,
                  title: l.developer,
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: const Text(
                      '扣握貝果-CodeWorldBagel',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: AppTheme.inkFaint, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: l.language,
          child: GestureDetector(
            onTap: () => _showLanguagePicker(context),
            child: _settingsTile(
              icon: Icons.language,
              title: l.language,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.localeNames[currentLocaleKey] ?? '',
                    style: const TextStyle(
                        color: AppTheme.inkFaint, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.inkFaint, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: l.exchangeRate,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://www.exchangerate-api.com'),
                  mode: LaunchMode.externalApplication,
                ),
                child: _settingsTile(
                  icon: Icons.currency_exchange,
                  title: l.rateSource,
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ExchangeRate API',
                          style:
                              TextStyle(color: AppTheme.orange, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new,
                          size: 14, color: AppTheme.orange),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              _settingsTile(
                icon: Icons.update,
                title: l.updateFrequency,
                trailing: Text(l.dailyOnce,
                    style: const TextStyle(
                        color: AppTheme.inkFaint, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: l.usageLimits,
          child: GestureDetector(
            onTap: () => _showUsageLimitsModal(context),
            child: _settingsTile(
              icon: Icons.data_usage,
              title: l.usageLimits,
              subtitle: l.usageLimitsDesc,
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.inkFaint, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPurchaseSection(context, l),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Account & Backup section ──────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context, AppLocalizations l) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return _sectionCard(
        title: l.account,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Text(l.signInDesc,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.inkFaint)),
            ),
            if (auth.isLoading)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              // Apple Sign-In (iOS only)
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                  child: MediaQuery.withNoTextScaling(
                    child: SignInWithAppleButton(
                      onPressed: () => _handleSignIn(context),
                      height: 50,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              // Google Sign-In
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: _GoogleSignInButton(
                  onPressed: () => _handleGoogleSignIn(context),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final name = auth.displayName?.isNotEmpty == true
        ? auth.displayName!
        : (auth.email?.split('@').first ?? '');

    return _sectionCard(
      title: l.account,
      child: Column(
        children: [
          // Profile row
          GestureDetector(
            onTap: () => _handleEditDisplayName(context),
            child: _settingsTile(
              icon: Icons.person,
              title: name,
              subtitle: l.signedInAs,
              trailing: const Icon(Icons.edit_outlined,
                  color: AppTheme.inkFaint, size: 18),
            ),
          ),
          const Divider(height: 1, color: AppTheme.parchment),
          // Linked accounts
          _buildLinkedAccountsSection(context, l, auth),
          const Divider(height: 1, color: AppTheme.parchment),
          // Sign out
          GestureDetector(
            onTap: () => _handleSignOut(context),
            child: _settingsTile(
              icon: Icons.logout,
              title: l.signOut,
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.inkFaint, size: 20),
            ),
          ),
          const Divider(height: 1, color: AppTheme.parchment),
          // Delete account
          GestureDetector(
            onTap: () => _handleDeleteAccount(context),
            child: _settingsTile(
              icon: Icons.delete_forever_outlined,
              title: l.deleteAccount,
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.inkFaint, size: 20),
              titleColor: AppTheme.stampRed,
            ),
          ),
        ],
      ),
    );
  }

  // ── Linked Accounts Section ───────────────────────────────────────────────

  Widget _buildLinkedAccountsSection(
      BuildContext context, AppLocalizations l, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Text(l.linkedAccounts,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkLight)),
        ),
        // Apple identity
        if (Platform.isIOS)
          _linkedProviderTile(
            context: context,
            icon: Icons.apple,
            providerName: 'Apple',
            isLinked: auth.hasAppleLinked,
            isLinking: auth.isLinking,
            onLink: () => _handleLinkApple(context),
          ),
        // Google identity
        _linkedProviderTile(
          context: context,
          icon: Icons.g_mobiledata,
          providerName: 'Google',
          isLinked: auth.hasGoogleLinked,
          isLinking: auth.isLinking,
          onLink: () => _handleLinkGoogle(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text(l.linkedAccountsDesc,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.inkFaint)),
        ),
      ],
    );
  }

  Widget _linkedProviderTile({
    required BuildContext context,
    required IconData icon,
    required String providerName,
    required bool isLinked,
    required bool isLinking,
    required VoidCallback onLink,
  }) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(providerName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.ink)),
          ),
          if (isLinked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.moss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l.linked,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.moss)),
            )
          else
            GestureDetector(
              onTap: isLinking ? null : onLink,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLinking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.link,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.orange)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Auth handlers ─────────────────────────────────────────────────────────

  Future<void> _handleEditDisplayName(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.displayName ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editNickname,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(hintText: l.nicknameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    try {
      await context.read<AuthProvider>().updateDisplayName(name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.nicknameSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.nicknameFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().signInWithApple();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.signInFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.signInFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleLinkGoogle(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().linkWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.linkSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.linkFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleLinkApple(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await context.read<AuthProvider>().linkWithApple();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.linkSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.linkFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<AuthProvider>().deleteAccount();
      if (context.mounted) {
        await context.read<TripProvider>().onAccountDeleted();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.deleteAccountFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOut,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.signOut,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        await context.read<TripProvider>().loadTrips();
      }
    }
  }

  // ── Purchase section ──────────────────────────────────────────────────────

  Widget _buildPurchaseSection(BuildContext context, AppLocalizations l) {
    final adProvider = context.watch<AdProvider>();

    if (adProvider.adsRemoved) {
      return _sectionCard(
        title: l.removeAds,
        child: _settingsTile(
          icon: Icons.check_circle_outline,
          title: l.adsAlreadyRemoved,
          trailing: const Icon(Icons.check, color: AppTheme.moss, size: 20),
        ),
      );
    }

    return _sectionCard(
      title: l.removeAds,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _buyRemoveAds(context),
            child: _settingsTile(
              icon: Icons.remove_circle_outline,
              title: l.removeAds,
              subtitle: l.removeAdsDesc,
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.inkFaint, size: 20),
            ),
          ),
          const Divider(height: 1, color: AppTheme.parchment),
          GestureDetector(
            onTap: () => _restorePurchase(context),
            child: _settingsTile(
              icon: Icons.restore,
              title: l.restorePurchase,
              subtitle: l.restorePurchaseDesc,
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.inkFaint, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              l.purchasePlatformNote,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.inkFaint,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyRemoveAds(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final platform = Platform.isIOS ? 'iOS' : 'Android';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.purchaseConfirmTitle,
            style: const TextStyle(color: AppTheme.ink)),
        content: Text(
          l.purchaseConfirmMessage.replaceAll('{platform}', platform),
          style: const TextStyle(color: AppTheme.inkLight, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppTheme.inkFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.purchaseConfirmButton,
                style: const TextStyle(color: AppTheme.orange)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AdProvider>().buyRemoveAds();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.purchaseFailed}: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchase(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      final restored = await context.read<AdProvider>().restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restored ? l.purchaseRestored : l.noPurchaseFound),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.purchaseFailed}: $e')),
        );
      }
    }
  }

  // ── Usage Limits Modal ───────────────────────────────────────────────────

  void _showUsageLimitsModal(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.warmWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.parchment,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(l.usageLimits,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                ),
                const SizedBox(height: 20),
                // ── 本地儲存 ──
                _limitSection(
                  icon: Icons.phone_iphone,
                  color: AppTheme.moss,
                  title: l.localStorage,
                  items: [
                    _limitRow(l.tripCount, l.unlimited),
                    _limitRow(l.splitBill, '❌'),
                    _limitRow(l.collaboration, '❌'),
                  ],
                ),
                const SizedBox(height: 14),
                // ── 免費雲端 ──
                _limitSection(
                  icon: Icons.cloud_outlined,
                  color: AppTheme.tagBlue,
                  title: l.freeCloud,
                  items: [
                    _limitRow(l.tripCount, '3'),
                    _limitRow(l.splitBill, '✅'),
                    _limitRow(l.collaboration, '✅'),
                    _limitRow(l.ads, l.adsYes),
                  ],
                ),
                const SizedBox(height: 14),
                // ── 付費雲端 ──
                _limitSection(
                  icon: Icons.workspace_premium_outlined,
                  color: AppTheme.orange,
                  title: l.premiumCloud,
                  isPremium: true,
                  items: [
                    _limitRow(l.tripCount, '20'),
                    _limitRow(l.splitBill, '✅'),
                    _limitRow(l.collaboration, '✅'),
                    _limitRow(l.ads, l.adsNo),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _limitSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> items,
    bool isPremium = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPremium
            ? AppTheme.orange.withValues(alpha: 0.05)
            : AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPremium
              ? AppTheme.orange.withValues(alpha: 0.3)
              : AppTheme.parchment.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isPremium ? AppTheme.orange : AppTheme.ink,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _limitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.inkLight)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink)),
        ],
      ),
    );
  }

  // ── Language picker ───────────────────────────────────────────────────────

  void _showLanguagePicker(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Language / 語言',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink)),
              ),
              ...AppLocalizations.supportedLocales.map((locale) {
                final key = locale.countryCode != null
                    ? '${locale.languageCode}_${locale.countryCode}'
                    : locale.languageCode;
                final name = AppLocalizations.localeNames[key] ?? key;
                final isSelected = localeProvider.locale.languageCode ==
                        locale.languageCode &&
                    localeProvider.locale.countryCode == locale.countryCode;

                return ListTile(
                  title: Text(name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected ? AppTheme.orange : AppTheme.ink,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppTheme.orange, size: 20)
                      : null,
                  onTap: () {
                    localeProvider.setLocale(locale);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
          ),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: titleColor ?? AppTheme.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppTheme.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkFaint)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}

// ── Google Sign-In Button (Material style matching Apple button) ──────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://developers.google.com/identity/images/g-logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).signInWithGoogle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
