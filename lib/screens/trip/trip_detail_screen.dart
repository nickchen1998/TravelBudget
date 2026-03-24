import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
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

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late Trip _trip;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses(_trip.id!);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l.details),
            Tab(text: l.stats),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpenseList(),
          AnalyticsScreen(trip: _trip),
        ],
      ),
      floatingActionButton: _tabController.index == 0
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
                          Text(AppLocalizations.of(context).noRecords,
                              style: const TextStyle(color: AppTheme.inkFaint)),
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
    final l = AppLocalizations.of(context);
    final remaining = _trip.budget - totalSpent;
    final isOver = remaining < 0;
    final symbol = getCurrencySymbol(_trip.baseCurrency);
    final amountStr = '$symbol${remaining.abs().toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOver
            ? AppTheme.stampRed.withValues(alpha: 0.08)
            : AppTheme.orangeSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
            size: 16,
            color: isOver ? AppTheme.stampRed : AppTheme.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isOver ? l.budgetOver(amountStr) : l.budgetRemaining(amountStr),
            style: TextStyle(
              fontSize: 13,
              color: isOver ? AppTheme.stampRed : AppTheme.inkLight,
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
