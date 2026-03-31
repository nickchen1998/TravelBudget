import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/categories.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/trip_provider.dart';
import '../../db/expense_dao.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with WidgetsBindingObserver {
  final ExpenseDao _dao = ExpenseDao();
  Map<String, double> _spentByCurrency = {};
  Map<ExpenseCategory, double> _allCategoryTotals = {};
  int _totalExpenseCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when trips change (e.g. coming back from trip detail)
    _loadStats();
  }

  Future<void> _loadStats() async {
    final trips = context.read<TripProvider>().trips;
    final currencyTotals = <String, double>{};
    final catTotals = <ExpenseCategory, double>{};
    int count = 0;

    for (final trip in trips) {
      if (trip.id == null) continue;
      final expenses = await _dao.getExpensesByTripId(trip.id!);
      count += expenses.length;
      for (final e in expenses) {
        final converted = e.convertedAmount ?? 0;
        final currency = trip.baseCurrency;
        currencyTotals[currency] = (currencyTotals[currency] ?? 0) + converted;
        catTotals[e.category] = (catTotals[e.category] ?? 0) + converted;
      }
    }

    if (mounted) {
      setState(() {
        _spentByCurrency = currencyTotals;
        _allCategoryTotals = catTotals;
        _totalExpenseCount = count;
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

    final l = AppLocalizations.of(context);

    Future<void> onRefresh() async {
      await context.read<TripProvider>().loadTrips();
      await _loadStats();
    }

    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
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
                    child: const Icon(
                      Icons.bar_chart,
                      size: 36,
                      color: AppTheme.orange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.noStatsTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.noStatsSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  icon: Icons.luggage,
                  value: '${trips.length}',
                  label: l.tripsCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniCard(
                  icon: Icons.receipt_long,
                  value: '$_totalExpenseCount',
                  label: l.expensesCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total spent by currency
          _sectionCard(
            title: l.totalSpending,
            child: Column(
              children: _spentByCurrency.entries.map((entry) {
                final symbol = getCurrencySymbol(entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.orangeSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$symbol${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Category breakdown
          if (_allCategoryTotals.isNotEmpty)
            _sectionCard(
              title: l.totalBreakdown,
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _allCategoryTotals.entries.map((entry) {
                          final total = _allCategoryTotals.values.fold(
                            0.0,
                            (a, b) => a + b,
                          );
                          final pct = total > 0
                              ? (entry.value / total * 100)
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
                  ...ExpenseCategory.values
                      .where((c) => _allCategoryTotals.containsKey(c))
                      .map((cat) {
                        final amount = _allCategoryTotals[cat]!;
                        final total = _allCategoryTotals.values.fold(
                          0.0,
                          (a, b) => a + b,
                        );
                        final pct = total > 0 ? amount / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.localizedName(context),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'NT\$${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.parchment
                                        .withValues(alpha: 0.4),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cat.color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Per-trip summary with progress bars
          _sectionCard(
            title: l.perTripSpending,
            child: Column(
              children: trips.where((t) => t.id != null).map((trip) {
                final spent = context.read<TripProvider>().getSpentForTrip(
                  trip.id!,
                );
                final symbol = getCurrencySymbol(trip.baseCurrency);
                final pct = trip.budget > 0
                    ? (spent / trip.budget).clamp(0.0, 1.0)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      if (trip.budget > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: AppTheme.parchment.withValues(
                              alpha: 0.4,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              spent > trip.budget
                                  ? AppTheme.stampRed
                                  : pct > 0.8
                                  ? AppTheme.amber
                                  : AppTheme.moss,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$symbol${spent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              '$symbol${trip.budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 5,
                            backgroundColor: AppTheme.infinitySoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$symbol${spent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            const Text(
                              '∞',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.infinity,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.inkFaint),
              ),
            ],
          ),
        ],
      ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 14),
                child,
              ],
            )
          : child,
    );
  }
}
