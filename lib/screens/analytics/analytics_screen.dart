import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/currencies.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../widgets/category_pie_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  final Trip trip;

  const AnalyticsScreen({super.key, required this.trip});

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final symbol = getCurrencySymbol(trip.baseCurrency);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: '預算進度',
              child: BudgetProgressBar(
                budget: trip.budget,
                spent: provider.totalSpent,
                currencyCode: trip.baseCurrency,
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: '消費結構',
              child: CategoryPieChart(
                data: provider.totalsByCategory,
                currencyCode: trip.baseCurrency,
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: '每日花費',
              child: _buildDailyChart(provider, symbol),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyChart(ExpenseProvider provider, String symbol) {
    final dailyTotals = provider.dailyTotals;

    if (dailyTotals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('尚無消費紀錄',
              style: TextStyle(color: AppTheme.inkFaint)),
        ),
      );
    }

    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    final startDate = DateTime(
        trip.startDate.year, trip.startDate.month, trip.startDate.day);

    for (int i = 0; i < trip.totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final total = dailyTotals[dateKey] ?? 0.0;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              color: AppTheme.orange,
              width: 20,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ],
        ),
      );
      labels.add(DateFormat('MM/dd').format(date));
    }

    final maxY = dailyTotals.values.isEmpty
        ? 100.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: bars,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.inkFaint),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[index],
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.inkFaint),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.parchment.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
