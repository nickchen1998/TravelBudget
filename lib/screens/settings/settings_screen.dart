import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/csv_service.dart';

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
        _sectionCard(
          title: l.about,
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.info_outline,
                title: l.version,
                trailing: const Text('1.0.0',
                    style: TextStyle(color: AppTheme.inkFaint)),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              _settingsTile(
                icon: Icons.person_outline,
                title: l.developer,
                trailing: const Text('扣握貝果-CodeWorldBagel',
                    style: TextStyle(color: AppTheme.inkFaint)),
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
          title: l.data,
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.storage_outlined,
                title: l.storageMethod,
                subtitle: l.storageDesc,
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              GestureDetector(
                onTap: () => _exportCsv(context),
                child: _settingsTile(
                  icon: Icons.file_download_outlined,
                  title: l.exportAll,
                  subtitle: l.exportDesc,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.inkFaint, size: 20),
                ),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              GestureDetector(
                onTap: () => _importCsv(context),
                child: _settingsTile(
                  icon: Icons.file_upload_outlined,
                  title: l.importData,
                  subtitle: l.importDesc,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.inkFaint, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                final isSelected =
                    localeProvider.locale.languageCode == locale.languageCode &&
                        localeProvider.locale.countryCode == locale.countryCode;

                return ListTile(
                  title: Text(name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected ? AppTheme.orange : AppTheme.ink,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.orange, size: 20)
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

  Future<void> _exportCsv(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      final csvService = CsvService();
      final file = await csvService.exportAll();
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.exportFailed}: $e')),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importCsv,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.pasteCsvContent,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.inkLight)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: l.pasteCsvHint,
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(l.cancel, style: const TextStyle(color: AppTheme.inkLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.next),
          ),
        ],
      ),
    );

    if (submitted != true || controller.text.trim().isEmpty) {
      controller.dispose();
      return;
    }

    final csvContent = controller.text;
    controller.dispose();

    if (!context.mounted) return;

    try {
      final csvService = CsvService();
      final preview = await csvService.previewImport(csvContent);

      if (preview.error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.parseFailed}：${preview.error}')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.confirmImport,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.importPreview(preview.totalExpenses),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...preview.tripSummaries.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          s.isNew
                              ? Icons.add_circle_outline
                              : Icons.folder_outlined,
                          size: 16,
                          color:
                              s.isNew ? AppTheme.orange : AppTheme.inkFaint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.tripName,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        Text(l.expenseUnit(s.expenseCount),
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.inkFaint)),
                        if (s.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.orangeSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(l.newLabel,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.orange)),
                          ),
                        ],
                      ],
                    ),
                  )),
              if (preview.skipped > 0) ...[
                const SizedBox(height: 8),
                Text(l.skippedLines(preview.skipped),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inkFaint)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel,
                  style: const TextStyle(color: AppTheme.inkLight)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.confirmImport),
            ),
          ],
        ),
      );

      if (confirmed != true || preview.parsedData == null) return;

      final result = await csvService.executeImport(preview.parsedData!);

      if (context.mounted) {
        context.read<TripProvider>().loadTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.importFailed}: $e')),
        );
      }
    }
  }

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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkFaint)),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
