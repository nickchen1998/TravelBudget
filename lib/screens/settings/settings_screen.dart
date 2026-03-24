import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: '關於',
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.info_outline,
                title: '版本',
                trailing: const Text('1.0.0',
                    style: TextStyle(color: AppTheme.inkFaint)),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              _settingsTile(
                icon: Icons.person_outline,
                title: '開發者',
                trailing: const Text('扣握貝果-CodeWorldBagel',
                    style: TextStyle(color: AppTheme.inkFaint)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: '匯率',
          child: Column(
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://www.exchangerate-api.com'),
                  mode: LaunchMode.externalApplication,
                ),
                child: _settingsTile(
                  icon: Icons.currency_exchange,
                  title: '匯率來源',
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ExchangeRate API',
                          style: TextStyle(color: AppTheme.orange, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new, size: 14, color: AppTheme.orange),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.parchment),
              _settingsTile(
                icon: Icons.update,
                title: '更新頻率',
                trailing: const Text('每日一次',
                    style: TextStyle(color: AppTheme.inkFaint, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: '資料',
          child: _settingsTile(
            icon: Icons.storage_outlined,
            title: '儲存方式',
            subtitle: '所有資料儲存在裝置本機，不會上傳至雲端',
          ),
        ),
      ],
    );
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
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
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
                        fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: AppTheme.inkFaint)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
