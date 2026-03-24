import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/categories.dart';
import '../../constants/currencies.dart';
import '../../providers/trip_provider.dart';
import '../../providers/expense_provider.dart';
import '../../db/expense_dao.dart';
import '../../models/trip.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final ExpenseDao _dao = ExpenseDao();
  Map<ExpenseCategory, double> _allCategoryTotals = {};
  double _allTimeSpent = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final trips = context.read<TripProvider>().trips;
    double total = 0;
    final catTotals = <ExpenseCategory, double>{};

    for (final trip in trips) {
      if (trip.id == null) continue;
      final expenses = await _dao.getExpensesByTripId(trip.id!);
      for (final e in expenses) {
        final converted = e.convertedAmount ?? 0;
        total += converted;
        catTotals[e.category] = (catTotals[e.category] ?? 0) + converted;
      }
    }

    if (mounted) {
      setState(() {
        _allTimeSpent = total;
        _allCategoryTotals = catTotals;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>().trips;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.orangeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart, size: 36, color: AppTheme.orange),
            ),
            const SizedBox(height: 20),
            const Text('尚無統計資料',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.ink)),
            const SizedBox(height: 6),
            const Text('新增旅行並記帳後，統計會顯示在這裡',
                style: TextStyle(fontSize: 14, color: AppTheme.inkFaint)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total spent across all trips
        _sectionCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: AppTheme.orange, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('所有旅行總花費',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkFaint)),
                  const SizedBox(height: 2),
                  Text(
                    'NT\$${_allTimeSpent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.parchment.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${trips.length} 趟旅行',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.inkLight, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category breakdown across all trips
        if (_allCategoryTotals.isNotEmpty)
          _sectionCard(
            title: '總消費結構',
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _allCategoryTotals.entries.map((entry) {
                        final pct = _allTimeSpent > 0
                            ? (entry.value / _allTimeSpent * 100)
                            : 0;
                        return PieChartSectionData(
                          color: entry.key.color,
                          value: entry.value,
                          title: '${pct.toStringAsFixed(0)}%',
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
                  children: _allCategoryTotals.entries.map((entry) {
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
                          '${entry.key.displayName} NT\$${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.inkLight),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Per-trip summary
        _sectionCard(
          title: '各旅行花費',
          child: Column(
            children: trips.map((trip) {
              final spent = context.read<TripProvider>().getSpentForTrip(trip.id!);
              final symbol = getCurrencySymbol(trip.baseCurrency);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(trip.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: AppTheme.ink)),
                    ),
                    Text(
                      '$symbol${spent.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppTheme.ink),
                    ),
                    if (trip.budget > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '/ $symbol${trip.budget.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.inkFaint),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: title != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                const SizedBox(height: 14),
                child,
              ],
            )
          : child,
    );
  }
}
