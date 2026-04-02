import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
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
        final l = AppLocalizations.of(context);
        final symbol = getCurrencySymbol(trip.baseCurrency);
        final avgDaily = trip.totalDays > 0
            ? provider.totalSpent / trip.totalDays
            : 0.0;

        final percentage = trip.budget > 0
            ? (provider.totalSpent / trip.budget).clamp(0.0, 1.0)
            : 0.0;
        final isOverBudget = provider.totalSpent > trip.budget && trip.budget > 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary row (2 columns: avg daily + expense count)
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: l.avgDaily,
                    value: '$symbol${avgDaily.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniStat(
                    label: l.expenseCount,
                    value: '${provider.expenses.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Budget progress — 效仿首頁 trip_card 樣式
            _sectionCard(
              title: l.budgetProgress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l.spent} $symbol${provider.totalSpent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isOverBudget ? AppTheme.stampRed : AppTheme.ink,
                        ),
                      ),
                      trip.budget > 0
                          ? Text(
                              '/ $symbol${trip.budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.inkFaint,
                                fontSize: 14,
                              ),
                            )
                          : const Text(
                              '/ ∞',
                              style: TextStyle(
                                color: AppTheme.infinity,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: trip.budget > 0
                        ? LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.parchment.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget
                                  ? AppTheme.stampRed
                                  : percentage > 0.8
                                      ? AppTheme.amber
                                      : AppTheme.moss,
                            ),
                          )
                        : const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 8,
                            backgroundColor: AppTheme.infinitySoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.infinity,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: l.spendingBreakdown,
              child: CategoryPieChart(
                data: provider.totalsByCategory,
                currencyCode: trip.baseCurrency,
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: l.dailySpending,
              child: _buildDailyChart(provider, symbol),
            ),
          ],
        );
      },
    );
  }

  Widget _miniStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.inkFaint)),
        ],
      ),
    );
  }

  Widget _buildDailyChart(ExpenseProvider provider, String symbol) {
    final dailyTotals = provider.dailyTotals;

    if (dailyTotals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Builder(builder: (context) {
            return Text(AppLocalizations.of(context).noRecords,
                style: const TextStyle(color: AppTheme.inkFaint));
          }),
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
              width: trip.totalDays > 10 ? 14 : 20,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ],
        ),
      );
      labels.add(DateFormat('MM/dd').format(date));
    }

    final rawMax = dailyTotals.values.isEmpty
        ? 100.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);
    // 計算 nice round maxY 和 interval
    final interval = _niceInterval(rawMax);
    final maxY = (rawMax / interval).ceil() * interval + interval * 0.1;

    // Make chart scrollable when trip is long
    final chartWidth = trip.totalDays > 7
        ? trip.totalDays * 50.0
        : null;

    final chart = SizedBox(
      height: 200,
      width: chartWidth,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: bars,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tooltipMargin: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '$symbol${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: chartWidth == null,
                reservedSize: 50,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == maxY) return const SizedBox.shrink();
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
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.parchment.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );

    if (chartWidth != null) {
      return SizedBox(
        height: 200,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        ),
      );
    }

    return chart;
  }

  /// 計算 Y 軸漂亮的固定區間（例如 1000, 2000, 5000, 10000...）
  double _niceInterval(double maxValue) {
    if (maxValue <= 0) return 100;
    final magnitude = maxValue / 4; // 大約 4-5 條格線
    final pow10 = _pow10(magnitude);
    final normalized = magnitude / pow10;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * pow10;
  }

  double _pow10(double value) {
    if (value <= 0) return 1;
    return math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  }
}
