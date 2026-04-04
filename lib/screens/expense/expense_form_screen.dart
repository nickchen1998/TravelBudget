import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/categories.dart';
import '../../constants/payment_methods.dart';
import '../../l10n/app_localizations.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/split_service.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Trip trip;
  final Expense? expense;

  const ExpenseFormScreen({super.key, required this.trip, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late ExpenseCategory _category;
  PaymentMethod? _paymentMethod;
  late String _currency;
  late DateTime _date;
  bool _isConverting = false;

  // Split bill fields
  String? _paidBy;
  String _splitType = 'equal';
  List<Map<String, dynamic>> _members = [];
  Set<String> _selectedParticipants = {};
  final Map<String, TextEditingController> _customAmountControllers = {};
  bool _membersLoaded = false;

  final ExchangeRateService _rateService = ExchangeRateService();
  final SplitService _splitService = SplitService();

  bool get isEditing => widget.expense != null;
  bool get _isSplitEnabled => widget.trip.splitEnabled && widget.trip.uuid != null;

  late List<DateTime> _tripDates;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(e.amount == e.amount.roundToDouble() ? 0 : 2) : '',
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? ExpenseCategory.food;
    _currency = e?.currency ?? widget.trip.targetCurrency;

    // Build list of all dates in the trip range
    _tripDates = _buildTripDates();

    // Default date: editing → use expense date; new → last expense date → today → first day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (e != null) {
      _date = DateTime(e.date.year, e.date.month, e.date.day);
    } else {
      // 嘗試使用最近一筆消費的日期
      final provider = context.read<ExpenseProvider>();
      final lastDate = provider.lastExpenseDate;
      if (lastDate != null) {
        final ld = DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (!ld.isBefore(_tripDates.first) && !ld.isAfter(_tripDates.last)) {
          _date = ld;
        } else if (!today.isBefore(_tripDates.first) && !today.isAfter(_tripDates.last)) {
          _date = today;
        } else {
          _date = _tripDates.first;
        }
      } else if (!today.isBefore(_tripDates.first) && !today.isAfter(_tripDates.last)) {
        _date = today;
      } else {
        _date = _tripDates.first;
      }

      // 支付方式預設：記住上次選擇
      _paymentMethod = provider.lastPaymentMethod ?? PaymentMethod.cash;
    }

    // 編輯模式：使用既有的支付方式
    if (e != null) {
      _paymentMethod = e.paymentMethod;
    }

    // Split bill: load members
    if (_isSplitEnabled) {
      _loadMembers();
      if (e != null) {
        _paidBy = e.paidBy;
        _splitType = e.splitType ?? 'equal';
      }
    }
  }

  List<DateTime> _buildTripDates() {
    final start = DateTime(widget.trip.startDate.year, widget.trip.startDate.month, widget.trip.startDate.day);
    final end = DateTime(widget.trip.endDate.year, widget.trip.endDate.month, widget.trip.endDate.day);
    final dates = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      dates.add(d);
    }
    return dates;
  }

  Future<void> _loadMembers() async {
    try {
      final members =
          await _splitService.getTripMembers(widget.trip.uuid!);
      if (!mounted) return;

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      setState(() {
        _members = members;
        _membersLoaded = true;
        // Default paid by = current user
        _paidBy ??= currentUserId;
        // Default: all members selected
        _selectedParticipants =
            members.map((m) => m['user_id'] as String).toSet();
      });

      // If editing, load existing splits
      if (isEditing && widget.expense?.uuid != null) {
        final splits =
            await _splitService.getSplitsForExpense(widget.expense!.uuid!);
        if (splits.isNotEmpty && mounted) {
          setState(() {
            _selectedParticipants =
                splits.map((s) => s.userId).toSet();
            if (widget.expense?.splitType == 'custom') {
              for (final s in splits) {
                _customAmountControllers[s.userId] =
                    TextEditingController(text: s.amount.toStringAsFixed(0));
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load members: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l.editExpense : l.newExpense),
        actions: [
          TextButton(
            onPressed: _isConverting ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Selection
            Text(l.category, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon,
                          size: 18,
                          color: isSelected ? Colors.white : cat.color),
                      const SizedBox(width: 4),
                      Text(cat.localizedName(context)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: cat.color,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: l.itemName,
                hintText: l.itemNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.itemNameRequired : null,
            ),
            const SizedBox(height: 16),

            // Amount + Currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.amount,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.amountRequired;
                      if (double.tryParse(v) == null) return l.invalidAmount;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: l.currency,
                      border: const OutlineInputBorder(),
                    ),
                    items: {
                      widget.trip.baseCurrency,
                      widget.trip.targetCurrency,
                    }.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(code, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _currency = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Method
            Text(l.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((pm) {
                final isSelected = _paymentMethod == pm;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(pm.icon,
                          size: 16,
                          color: isSelected ? Colors.white : pm.color),
                      const SizedBox(width: 4),
                      Text(pm.localizedName(context)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: pm.color,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _paymentMethod = pm),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Split Bill Section
            if (_isSplitEnabled && _membersLoaded) ...[
              _buildSplitSection(l),
              const SizedBox(height: 16),
            ],

            // Date
            DropdownButtonFormField<DateTime>(
              initialValue: _date,
              decoration: InputDecoration(
                labelText: l.date,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              items: _tripDates.map((d) {
                final dayNum = d.difference(_tripDates.first).inDays + 1;
                return DropdownMenuItem(
                  value: d,
                  child: Text('Day $dayNum  ${DateFormat('MM/dd (E)', 'zh_TW').format(d)}'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _date = v);
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton.icon(
              onPressed: _isConverting ? null : _save,
              icon: _isConverting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(isEditing ? l.update : l.add),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMemberName(String userId) {
    final member = _members.firstWhere(
      (m) => m['user_id'] == userId,
      orElse: () => {'profiles': null},
    );
    final profiles = member['profiles'];
    if (profiles is Map) return profiles['display_name'] as String? ?? '?';
    return '?';
  }

  Widget _buildSplitSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.parchment),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 18, color: AppTheme.orange),
              const SizedBox(width: 6),
              Text(l.splitBill,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.ink)),
            ],
          ),
          const SizedBox(height: 12),

          // Paid by
          Text(l.paidBy,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.inkLight)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _members.map((m) {
              final uid = m['user_id'] as String;
              final name = _getMemberName(uid);
              final isSelected = _paidBy == uid;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: AppTheme.orange,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _paidBy = uid),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Split type
          Text(l.splitMethod,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.inkLight)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.splitEqual),
                selected: _splitType == 'equal',
                selectedColor: AppTheme.moss,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: _splitType == 'equal' ? Colors.white : AppTheme.ink,
                ),
                onSelected: (_) => setState(() => _splitType = 'equal'),
              ),
              ChoiceChip(
                label: Text(l.splitCustom),
                selected: _splitType == 'custom',
                selectedColor: AppTheme.moss,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: _splitType == 'custom' ? Colors.white : AppTheme.ink,
                ),
                onSelected: (_) => setState(() => _splitType = 'custom'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Participants
          Text(l.participants,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.inkLight)),
          const SizedBox(height: 6),
          ..._members.map((m) {
            final uid = m['user_id'] as String;
            final name = _getMemberName(uid);
            final isChecked = _selectedParticipants.contains(uid);
            return Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isChecked,
                    activeColor: AppTheme.orange,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedParticipants.add(uid);
                        } else {
                          _selectedParticipants.remove(uid);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
                if (_splitType == 'custom' && isChecked)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _customAmountControllers.putIfAbsent(
                          uid, () => TextEditingController()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        border: const OutlineInputBorder(),
                        hintText: widget.trip.baseCurrency,
                        hintStyle:
                            const TextStyle(fontSize: 12, color: AppTheme.inkFaint),
                      ),
                    ),
                  ),
              ],
            );
          }),

          // Equal split preview
          if (_splitType == 'equal' && _selectedParticipants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final amountText = _amountController.text;
              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) return const SizedBox.shrink();
              final perPerson = amount / _selectedParticipants.length;
              return Text(
                '${l.perPerson}: ${perPerson.toStringAsFixed(1)} $_currency',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.moss, fontWeight: FontWeight.w500),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConverting = true);

    try {
      final amount = double.parse(_amountController.text);
      double? convertedAmount;
      double? exchangeRate;

      if (_currency == widget.trip.baseCurrency) {
        convertedAmount = amount;
        exchangeRate = 1.0;
      } else {
        exchangeRate = await _rateService.getRate(
          _currency,
          widget.trip.baseCurrency,
        );
        convertedAmount = amount * exchangeRate;
      }

      final expense = Expense(
        id: widget.expense?.id,
        tripId: widget.trip.id!,
        title: _titleController.text.trim(),
        amount: amount,
        currency: _currency,
        convertedAmount: convertedAmount,
        exchangeRate: exchangeRate,
        category: _category,
        paymentMethod: _paymentMethod,
        paidBy: _isSplitEnabled ? _paidBy : null,
        splitType: _isSplitEnabled ? _splitType : null,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _date,
        createdAt: widget.expense?.createdAt,
      );

      if (!mounted) return;
      final provider = context.read<ExpenseProvider>();
      String? error;
      if (isEditing) {
        error = await provider.updateExpense(expense);
      } else {
        error = await provider.addExpense(expense);
      }

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).networkRequiredError)),
        );
      } else {
        // Save splits if split is enabled and expense was saved to cloud
        if (_isSplitEnabled && _selectedParticipants.isNotEmpty) {
          try {
            final savedExpense = provider.expenses.firstWhere(
              (e) => e.title == expense.title && e.date == expense.date,
            );
            if (savedExpense.uuid != null) {
              final splits = <SplitEntry>[];
              if (_splitType == 'equal') {
                final perPerson =
                    convertedAmount / _selectedParticipants.length;
                for (final uid in _selectedParticipants) {
                  splits.add(SplitEntry(
                    expenseId: savedExpense.uuid!,
                    userId: uid,
                    amount: double.parse(perPerson.toStringAsFixed(2)),
                  ));
                }
              } else {
                // Custom amounts
                for (final uid in _selectedParticipants) {
                  final ctrl = _customAmountControllers[uid];
                  final customAmount = double.tryParse(ctrl?.text ?? '') ?? 0;
                  if (customAmount > 0) {
                    splits.add(SplitEntry(
                      expenseId: savedExpense.uuid!,
                      userId: uid,
                      amount: customAmount,
                    ));
                  }
                }
              }
              await _splitService.saveSplits(savedExpense.uuid!, splits);
            }
          } catch (e) {
            debugPrint('Failed to save splits: $e');
          }
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).saveFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }
}
