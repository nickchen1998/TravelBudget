import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../constants/app_theme.dart';
import '../../providers/ad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/ad_service.dart';
import '../../services/image_storage_service.dart';
import 'trip_detail_screen.dart';

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
  bool _splitEnabled = false;
  bool _isSaving = false;

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
    _splitEnabled = trip?.splitEnabled ?? false;
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
            if (isEditing) ...[
              Row(
                children: [
                  Expanded(child: _ReadOnlyField(label: l.startDate, value: DateFormat('yyyy/MM/dd').format(_startDate))),
                  const SizedBox(width: 12),
                  Expanded(child: _ReadOnlyField(label: l.endDate, value: DateFormat('yyyy/MM/dd').format(_endDate))),
                ],
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 16),

            // Currency Selection
            if (isEditing) ...[
              Row(
                children: [
                  Expanded(child: _ReadOnlyField(label: l.baseCurrency, value: _baseCurrency)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: Colors.grey),
                  ),
                  Expanded(child: _ReadOnlyField(label: l.targetCurrency, value: _targetCurrency)),
                ],
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 16),

            // Budget
            if (isEditing) ...[
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
                    if (value == null || value.isEmpty) return l.budgetRequired;
                    if (double.tryParse(value) == null) return l.invalidNumber;
                    return null;
                  },
                ),
              ],
            ] else ...[
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
            ],
            const SizedBox(height: 8),

            // Split Bill Toggle
            SwitchListTile(
              title: Text(l.splitEnabled),
              subtitle: Text(l.splitEnabledDesc,
                  style: const TextStyle(fontSize: 12)),
              value: _splitEnabled,
              onChanged: (v) => _onSplitToggle(v, l),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
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

  void _onSplitToggle(bool value, AppLocalizations l) {
    // Turning off: always allow
    if (!value) {
      setState(() => _splitEnabled = false);
      return;
    }

    // Turning on: if already a cloud trip, just enable
    if (widget.trip?.uuid != null) {
      setState(() => _splitEnabled = true);
      return;
    }

    // Turning on a local/new trip: check login & confirm cloud upload
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.splitRequiresCloud)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.splitCloudConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.splitCloudConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _splitEnabled = true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.orange,
            ),
            child: Text(l.confirm),
          ),
        ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final budget = _noBudget ? 0.0 : double.parse(_budgetController.text);

    // 若有選新圖片，先壓縮為 WebP 並持久化到 App 文件目錄
    String? persistedImagePath = _coverImagePath;
    if (_imageChanged && _coverImagePath != null) {
      persistedImagePath =
          await ImageStorageService.persistLocalCover(_coverImagePath!);
      _coverImagePath = persistedImagePath;
    }

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
      coverImageUrl: _imageChanged ? null : widget.trip?.coverImageUrl,
      splitEnabled: _splitEnabled,
      createdAt: widget.trip?.createdAt,
    );

    try {
      final provider = context.read<TripProvider>();
      String? error;
      if (isEditing) {
        error = await provider.updateTrip(trip);
      } else {
        error = await provider.addTrip(trip);
      }
      if (!mounted) return;
      if (error != null && isEditing) {
        // Edit on cloud trip failed (network)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).networkRequiredError),
        ));
        return;
      }

      // If split enabled on a local trip, upload to cloud
      if (_splitEnabled && trip.uuid == null) {
        final savedTrip = provider.trips.firstWhere(
          (t) => t.name == trip.name && t.uuid == null,
          orElse: () => trip,
        );
        if (savedTrip.id != null) {
          final uploadError =
              await provider.uploadLocalTripToCloud(savedTrip);
          if (uploadError != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).networkRequiredError),
            ));
          }
        }
      }

      if (!mounted) return;

      if (!isEditing) {
        // New trip: navigate directly into the trip detail
        final createdTrip = provider.trips.first;
        final adsRemoved = context.read<AdProvider>().adsRemoved;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: createdTrip),
          ),
        );
        // Fire-and-forget interstitial on top of the new screen
        InterstitialAdManager.instance
            .maybeShowAfterTripCreate(adsRemoved: adsRemoved);
      } else {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: Colors.grey.shade100,
        filled: true,
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
