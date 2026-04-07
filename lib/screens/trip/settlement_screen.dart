import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/currencies.dart';
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

      final members = await _splitService.getTripMembers(tripUuid);
      _memberNames = {};
      for (final m in members) {
        final uid = m['user_id'] as String;
        final profiles = m['profiles'];
        final name =
            profiles is Map ? profiles['display_name'] as String? : null;
        _memberNames[uid] = name ?? '?';
      }

      final expenses = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripUuid)
          .not('split_type', 'is', null);

      final allSplits = await _splitService.getAllSplitsForTrip(tripUuid);

      final expenseMaps = (expenses as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _debts = _splitService.calculateDebts(expenseMaps, allSplits);
    } catch (e) {
      debugPrint('Failed to load settlement data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// 取名字的第一個字當頭像
  String _initial(String name) {
    if (name.isEmpty || name == '?') return '?';
    return name.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final symbol = getCurrencySymbol(widget.trip.baseCurrency);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.moss.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.handshake_outlined,
                  size: 36, color: AppTheme.moss),
            ),
            const SizedBox(height: 16),
            Text(l.settlementEmpty,
                style: const TextStyle(
                    fontSize: 16, color: AppTheme.inkLight)),
          ],
        ),
      );
    }

    // 計算總欠款
    final totalOwed = _debts.fold<double>(0, (sum, d) => sum + d.amount);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 總覽卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warmWhite,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.parchment.withValues(alpha: 0.5)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  '$symbol${formatAmount(totalOwed)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_debts.length} ${l.settlement}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 債務列表
          ...List.generate(_debts.length, (index) {
            final debt = _debts[index];
            final fromName = _memberNames[debt.fromUser] ?? '?';
            final toName = _memberNames[debt.toUser] ?? '?';

            return Padding(
              padding: EdgeInsets.only(bottom: index < _debts.length - 1 ? 12 : 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.parchment.withValues(alpha: 0.5)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    // 付款人頭像
                    _avatar(fromName, AppTheme.stampRed),
                    const SizedBox(width: 10),
                    // 付款人名字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fromName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            '$symbol${formatAmount(debt.amount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 箭頭
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: AppTheme.orange, size: 16),
                    ),
                    // 收款人名字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(toName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 收款人頭像
                    _avatar(toName, AppTheme.moss),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _avatar(String name, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial(name),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
