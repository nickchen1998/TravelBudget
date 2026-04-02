import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/categories.dart';
import '../constants/currencies.dart';
import '../l10n/app_localizations.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<ExpenseCategory, double> data;
  final String currencyCode;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(AppLocalizations.of(context).noRecords,
              style: const TextStyle(color: AppTheme.inkFaint)),
        ),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final symbol = getCurrencySymbol(currencyCode);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final percentage =
                    total > 0 ? (entry.value / total * 100) : 0;
                return PieChartSectionData(
                  color: entry.key.color,
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 75,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2.5,
              centerSpaceRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: data.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${entry.key.localizedName(context)} $symbol${formatAmount(entry.value)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkLight,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
