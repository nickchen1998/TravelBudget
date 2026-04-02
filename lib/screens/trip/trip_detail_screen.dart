import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/invite_code_widget.dart';
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

  // Members state (only used for cloud trips)
  List<Map<String, dynamic>>? _members;
  bool _membersLoading = false;

  bool get _isCloudTrip => _trip.uuid != null;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: _isCloudTrip ? 3 : 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses(_trip);
      if (_isCloudTrip) _loadMembers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (!_isCloudTrip) return;
    setState(() => _membersLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('trip_members')
          .select(
              'user_id, role, joined_at, profiles!trip_members_user_id_fkey(display_name)')
          .eq('trip_id', _trip.uuid!);
      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(response as List);
          _membersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _membersLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入成員失敗：$e')),
        );
      }
    }
  }

  Future<void> _removeMember(BuildContext context, String userId) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errorMsg = l.networkRequiredError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.removeMember,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l.removeMemberConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppTheme.inkLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.stampRed),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client
          .from('trip_members')
          .delete()
          .eq('trip_id', _trip.uuid!)
          .eq('user_id', userId);
      await _loadMembers();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final isOwner = _trip.memberRole == null || _trip.memberRole == 'owner';
    // Shared trips (user is editor/viewer) are read-only when offline
    final isOfflineReadOnly = !isOnline && _trip.memberRole != null;
    final canEdit = _trip.canEdit && !isOfflineReadOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        actions: [
          if (isOwner && auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_add_outlined, size: 22),
              tooltip: l.shareTrip,
              onPressed: () async {
                final tripProvider = context.read<TripProvider>();
                await showInviteCodeSheet(context, _trip);
                // Refresh trip after sharing (uuid may have been assigned)
                if (mounted) {
                  final trips = tripProvider.trips;
                  final updated = trips.where((t) => t.id == _trip.id).toList();
                  if (updated.isNotEmpty) setState(() => _trip = updated.first);
                }
              },
            ),
          if (canEdit)
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
            if (_isCloudTrip) Tab(text: l.members),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isOfflineReadOnly)
            Container(
              width: double.infinity,
              color: AppTheme.inkFaint.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 16,
                    color: AppTheme.inkLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).offlineReadOnly,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseList(),
                AnalyticsScreen(trip: _trip),
                if (_isCloudTrip) _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 && _trip.canEdit
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
            // Budget Summary Card — 效仿首頁 trip_card 簡潔樣式
            Builder(builder: (context) {
              final symbol = getCurrencySymbol(_trip.baseCurrency);
              final spent = provider.totalSpent;
              final percentage = _trip.budget > 0
                  ? (spent / _trip.budget).clamp(0.0, 1.0)
                  : 0.0;
              final isOverBudget = spent > _trip.budget && _trip.budget > 0;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.parchment.withValues(alpha: 0.5),
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context).spent} $symbol${formatAmount(spent)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isOverBudget ? AppTheme.stampRed : AppTheme.ink,
                          ),
                        ),
                        _trip.budget > 0
                            ? Text(
                                '/ $symbol${formatAmount(_trip.budget)}',
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
                      child: _trip.budget > 0
                          ? LinearProgressIndicator(
                              value: percentage,
                              minHeight: 7,
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
                              minHeight: 7,
                              backgroundColor: AppTheme.infinitySoft,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.infinity,
                              ),
                            ),
                    ),
                    if (_trip.budget > 0 && _trip.totalDays > 0) ...[
                      const SizedBox(height: 8),
                      _buildDailyBudgetHint(spent),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            // Expense List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<ExpenseProvider>().loadExpenses(_trip),
                child: provider.expenses.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
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
                                  child: const Icon(
                                    Icons.receipt_long,
                                    size: 30,
                                    color: AppTheme.orange,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  AppLocalizations.of(context).noRecords,
                                  style: const TextStyle(
                                    color: AppTheme.inkFaint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _buildGroupedList(provider),
              ),
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
    final amountStr = '$symbol${formatAmount(remaining.abs())}';

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
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final dateFormat = DateFormat('MM/dd (E)', 'zh_TW');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expenses = grouped[date]!;
        final dayNum =
            date
                .difference(
                  DateTime(
                    _trip.startDate.year,
                    _trip.startDate.month,
                    _trip.startDate.day,
                  ),
                )
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
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                onTap: _trip.canEdit ? () => _editExpense(context, e) : null,
                onDelete: _trip.canEdit
                    ? () => provider.deleteExpense(e.id!)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTab() {
    final l = AppLocalizations.of(context);
    final isOwner = _trip.memberRole == null || _trip.memberRole == 'owner';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (_membersLoading && _members == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final members = _members ?? [];

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: members.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Text(
                      l.noRecords,
                      style: const TextStyle(color: AppTheme.inkFaint),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                final profile = member['profiles'] as Map<String, dynamic>?;
                final displayName = profile?['display_name'] as String?;
                final role = member['role'] as String? ?? 'viewer';
                final userId = member['user_id'] as String?;
                final isSelf = userId == currentUserId;

                final roleLabel = role == 'owner'
                    ? l.roleOwner
                    : role == 'editor'
                    ? l.roleEditor
                    : l.roleViewer;

                final roleColor = role == 'owner'
                    ? AppTheme.orange
                    : role == 'editor'
                    ? AppTheme.moss
                    : AppTheme.inkFaint;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.orangeSoft,
                    child: Text(
                      (displayName?.isNotEmpty == true
                              ? displayName![0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    displayName?.isNotEmpty == true
                        ? displayName!
                        : '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  subtitle: null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      if (isOwner && !isSelf && userId != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeMember(context, userId),
                          child: const Icon(
                            Icons.person_remove_outlined,
                            size: 20,
                            color: AppTheme.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _addExpense(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(trip: _trip)),
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
