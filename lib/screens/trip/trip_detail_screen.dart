import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/trip.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../widgets/expense_tile.dart';
import '../expense/expense_form_screen.dart';
import '../analytics/analytics_screen.dart';
import 'trip_form_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses(_trip.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () async {
              final tripProvider = context.read<TripProvider>();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripFormScreen(trip: _trip),
                ),
              );
              if (result == true && mounted) {
                final trips = tripProvider.trips;
                final updated = trips.firstWhere((t) => t.id == _trip.id);
                setState(() => _trip = updated);
              }
            },
          ),
        ],
      ),
      body: _currentTab == 0
          ? _buildExpenseList()
          : AnalyticsScreen(trip: _trip),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '明細',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '統計',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () => _addExpense(context),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TripProvider>().updateSpending(
                _trip.id!,
                provider.totalSpent,
              );
        });

        return Column(
          children: [
            // Budget Summary Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.parchment.withValues(alpha: 0.5)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  BudgetProgressBar(
                    budget: _trip.budget,
                    spent: provider.totalSpent,
                    currencyCode: _trip.baseCurrency,
                  ),
                  if (_trip.budget > 0 && _trip.totalDays > 0) ...[
                    const SizedBox(height: 8),
                    _buildDailyBudgetHint(provider.totalSpent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Expense List
            Expanded(
              child: provider.expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppTheme.orangeSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long,
                                size: 30, color: AppTheme.orange),
                          ),
                          const SizedBox(height: 14),
                          const Text('尚無消費紀錄',
                              style: TextStyle(color: AppTheme.inkFaint)),
                        ],
                      ),
                    )
                  : _buildGroupedList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyBudgetHint(double totalSpent) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
        _trip.endDate.year, _trip.endDate.month, _trip.endDate.day);
    final remainingDays = end.difference(today).inDays + 1;
    if (remainingDays <= 0) return const SizedBox.shrink();

    final remaining = _trip.budget - totalSpent;
    final dailyBudget = remaining > 0 ? remaining / remainingDays : 0.0;
    final symbol =
        _trip.baseCurrency == 'TWD' ? 'NT\$' : _trip.baseCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.orangeSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 16, color: AppTheme.orange),
          const SizedBox(width: 6),
          Text(
            '剩餘 $remainingDays 天，每日可花 $symbol${dailyBudget.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.inkLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(ExpenseProvider provider) {
    final grouped = provider.expensesByDate;
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final dateFormat = DateFormat('MM/dd (E)', 'zh_TW');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expenses = grouped[date]!;
        final dayNum = date
                .difference(DateTime(_trip.startDate.year,
                    _trip.startDate.month, _trip.startDate.day))
                .inDays +
            1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Day $dayNum',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      color: AppTheme.inkFaint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...expenses.map(
              (e) => ExpenseTile(
                expense: e,
                baseCurrency: _trip.baseCurrency,
                onTap: () => _editExpense(context, e),
                onDelete: () => provider.deleteExpense(e.id!),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addExpense(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(trip: _trip),
      ),
    );
  }

  void _editExpense(BuildContext context, Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(trip: _trip, expense: expense),
      ),
    );
  }
}
