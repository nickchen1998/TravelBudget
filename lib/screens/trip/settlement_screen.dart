import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/split_service.dart';

class SettlementScreen extends StatefulWidget {
  final Trip trip;

  const SettlementScreen({super.key, required this.trip});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _splitService = SplitService();
  final _supabase = Supabase.instance.client;

  List<Debt> _debts = [];
  List<Settlement> _settlements = [];
  Map<String, String> _memberNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tripUuid = widget.trip.uuid!;

      // Load members
      final members = await _splitService.getTripMembers(tripUuid);
      _memberNames = {};
      for (final m in members) {
        final uid = m['user_id'] as String;
        final profiles = m['profiles'];
        final name =
            profiles is Map ? profiles['display_name'] as String? : null;
        _memberNames[uid] = name ?? '?';
      }

      // Load all expenses with split data
      final expenses = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripUuid)
          .not('split_type', 'is', null);

      final allSplits = await _splitService.getAllSplitsForTrip(tripUuid);

      // Calculate debts
      final expenseMaps = (expenses as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _debts = _splitService.calculateDebts(expenseMaps, allSplits);

      // Load existing settlement records
      _settlements = await _splitService.getSettlements(tripUuid);
    } catch (e) {
      debugPrint('Failed to load settlement data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  bool _isDebtSettled(Debt debt) {
    return _settlements.any((s) =>
        s.fromUser == debt.fromUser &&
        s.toUser == debt.toUser &&
        s.isSettled);
  }

  Settlement? _getSettlement(Debt debt) {
    try {
      return _settlements.firstWhere((s) =>
          s.fromUser == debt.fromUser &&
          s.toUser == debt.toUser &&
          s.isSettled);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleSettle(Debt debt) async {
    final settled = _isDebtSettled(debt);

    try {
      if (settled) {
        final settlement = _getSettlement(debt);
        if (settlement?.id != null) {
          await _splitService.unmarkSettled(settlement!.id!);
        }
      } else {
        await _splitService.markSettled(
          widget.trip.uuid!,
          debt.fromUser,
          debt.toUser,
          debt.amount,
          widget.trip.baseCurrency,
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _debts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: AppTheme.moss),
                      const SizedBox(height: 16),
                      Text(l.settlementEmpty,
                          style: const TextStyle(
                              fontSize: 16, color: AppTheme.inkLight)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _debts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final debt = _debts[index];
                      final settled = _isDebtSettled(debt);
                      final fromName =
                          _memberNames[debt.fromUser] ?? '?';
                      final toName =
                          _memberNames[debt.toUser] ?? '?';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: settled
                              ? AppTheme.moss.withValues(alpha: 0.08)
                              : AppTheme.warmWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: settled
                                ? AppTheme.moss.withValues(alpha: 0.3)
                                : AppTheme.parchment,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // From user
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fromName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: settled
                                                ? AppTheme.inkFaint
                                                : AppTheme.ink,
                                            decoration: settled
                                                ? TextDecoration.lineThrough
                                                : null,
                                          )),
                                    ],
                                  ),
                                ),
                                // Arrow + amount
                                Column(
                                  children: [
                                    const Icon(Icons.arrow_forward,
                                        color: AppTheme.orange, size: 20),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${debt.amount.toStringAsFixed(0)} ${widget.trip.baseCurrency}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: settled
                                            ? AppTheme.inkFaint
                                            : AppTheme.orange,
                                        decoration: settled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                // To user
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(toName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: settled
                                                ? AppTheme.inkFaint
                                                : AppTheme.ink,
                                            decoration: settled
                                                ? TextDecoration.lineThrough
                                                : null,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _toggleSettle(debt),
                                icon: Icon(
                                  settled
                                      ? Icons.undo
                                      : Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                    settled ? l.undoSettle : l.markSettled),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      settled ? AppTheme.inkFaint : AppTheme.moss,
                                  side: BorderSide(
                                    color: settled
                                        ? AppTheme.inkFaint
                                        : AppTheme.moss,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
  }
}
