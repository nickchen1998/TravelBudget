import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
import '../../services/exchange_rate_service.dart';

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
  late String _currency;
  late DateTime _date;
  bool _isConverting = false;

  final ExchangeRateService _rateService = ExchangeRateService();

  bool get isEditing => widget.expense != null;

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

    // Default date: today if within range, else first day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (e != null) {
      _date = DateTime(e.date.year, e.date.month, e.date.day);
    } else if (!today.isBefore(_tripDates.first) && !today.isAfter(_tripDates.last)) {
      _date = today;
    } else {
      _date = _tripDates.first;
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
        Navigator.pop(context, true);
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
