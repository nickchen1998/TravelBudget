import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';

class TripFormScreen extends StatefulWidget {
  final Trip? trip;

  const TripFormScreen({super.key, this.trip});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late String _baseCurrency;
  late String _targetCurrency;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _coverImagePath;
  bool _imageChanged = false;
  bool _noBudget = false;

  bool get isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _nameController = TextEditingController(text: trip?.name ?? '');
    _budgetController = TextEditingController(
      text: trip != null && trip.budget > 0
          ? trip.budget.toStringAsFixed(0)
          : '',
    );
    _baseCurrency = trip?.baseCurrency ?? 'TWD';
    _targetCurrency = trip?.targetCurrency ?? 'JPY';
    _startDate = trip?.startDate ?? DateTime.now();
    _endDate = trip?.endDate ?? DateTime.now().add(const Duration(days: 4));
    _coverImagePath = trip?.coverImagePath;
    _noBudget = trip != null && trip.budget == 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l.editTrip : l.newTrip),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                  image: _coverImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_coverImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: _coverImagePath == null
                      ? const LinearGradient(
                          colors: [Color(0xFFF2A06A), Color(0xFFE8763A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: _coverImagePath == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.white70),
                            const SizedBox(height: 8),
                            Text(l.addCoverImage,
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Trip Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.tripName,
                hintText: l.tripNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flight),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l.tripNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: l.startDate,
                    date: _startDate,
                    onChanged: (date) {
                      setState(() {
                        _startDate = date;
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: l.endDate,
                    date: _endDate,
                    firstDate: _startDate,
                    onChanged: (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Currency Selection
            Row(
              children: [
                Expanded(
                  child: _CurrencyDropdown(
                    label: l.baseCurrency,
                    value: _baseCurrency,
                    onChanged: (v) => setState(() => _baseCurrency = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: _CurrencyDropdown(
                    label: l.targetCurrency,
                    value: _targetCurrency,
                    onChanged: (v) => setState(() => _targetCurrency = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget
            SwitchListTile(
              title: Text(l.noBudgetLimit),
              value: _noBudget,
              onChanged: (v) => setState(() => _noBudget = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_noBudget) ...[
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.budgetAmount,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  suffixText: _baseCurrency,
                ),
                validator: (value) {
                  if (_noBudget) return null;
                  if (value == null || value.isEmpty) {
                    return l.budgetRequired;
                  }
                  if (double.tryParse(value) == null) {
                    return l.invalidNumber;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? l.saveChanges : l.createTrip),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() {
        _coverImagePath = image.path;
        _imageChanged = true;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final budget = _noBudget ? 0.0 : double.parse(_budgetController.text);

    final trip = Trip(
      id: widget.trip?.id,
      uuid: widget.trip?.uuid,
      ownerId: widget.trip?.ownerId,
      memberRole: widget.trip?.memberRole,
      isDirty: widget.trip?.isDirty ?? false,
      syncedAt: widget.trip?.syncedAt,
      name: _nameController.text.trim(),
      budget: budget,
      baseCurrency: _baseCurrency,
      targetCurrency: _targetCurrency,
      startDate: _startDate,
      endDate: _endDate,
      coverImagePath: _coverImagePath,
      // Clear old URL when user picked a new local image so cloud re-uploads
      coverImageUrl: _imageChanged ? null : widget.trip?.coverImageUrl,
      createdAt: widget.trip?.createdAt,
    );

    final provider = context.read<TripProvider>();
    if (isEditing) {
      provider.updateTrip(trip);
    } else {
      provider.addTrip(trip);
    }
    Navigator.pop(context, true);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat('yyyy/MM/dd').format(date)),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: supportedCurrencies.map((c) {
        return DropdownMenuItem(
          value: c.code,
          child: Text('${c.code} ${c.symbol}', style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
