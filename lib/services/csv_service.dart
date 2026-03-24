import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../constants/categories.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class CsvService {
  final TripDao _tripDao = TripDao();
  final ExpenseDao _expenseDao = ExpenseDao();

  static const String _header =
      'trip,date,category,item,amount,currency,converted,base_currency,rate,note';

  Future<File> exportAll() async {
    final trips = await _tripDao.getAllTrips();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final buf = StringBuffer();
    buf.writeln(_header);

    for (final trip in trips) {
      if (trip.id == null) continue;
      final expenses = await _expenseDao.getExpensesByTripId(trip.id!);
      for (final e in expenses) {
        buf.writeln([
          _escape(trip.name),
          dateFormat.format(e.date),
          e.category.name,
          _escape(e.title),
          e.amount,
          e.currency,
          e.convertedAmount?.toStringAsFixed(2) ?? '',
          trip.baseCurrency,
          e.exchangeRate?.toString() ?? '',
          _escape(e.note ?? ''),
        ].join(','));
      }
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/旅算_匯出_$timestamp.csv');
    // Write with BOM for Excel to recognize UTF-8
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...buf.toString().codeUnits]);
    return file;
  }

  /// Step 1: Parse CSV and return a preview without writing to DB.
  Future<ImportPreview> previewImport(String csvContent) async {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return ImportPreview(tripSummaries: [], skipped: 0, error: '檔案為空');
    }

    final firstLine = lines.first;
    final isHeader = firstLine.contains('旅行名稱') || firstLine.contains('trip,');
    final dataLines = lines.length > 1 && isHeader
        ? lines.sublist(1)
        : lines;

    final tripExpenses = <String, List<CsvRow>>{};
    int skipped = 0;

    for (final line in dataLines) {
      final row = _parseCsvLine(line);
      if (row == null) {
        skipped++;
        continue;
      }
      tripExpenses.putIfAbsent(row.tripName, () => []).add(row);
    }

    if (tripExpenses.isEmpty) {
      return ImportPreview(tripSummaries: [], skipped: skipped, error: '無有效資料');
    }

    final existingTrips = await _tripDao.getAllTrips();
    final existingNames = existingTrips.map((t) => t.name).toSet();

    final summaries = tripExpenses.entries.map((entry) {
      return TripImportSummary(
        tripName: entry.key,
        expenseCount: entry.value.length,
        isNew: !existingNames.contains(entry.key),
      );
    }).toList();

    return ImportPreview(
      tripSummaries: summaries,
      skipped: skipped,
      parsedData: tripExpenses,
    );
  }

  /// Step 2: Execute the import using the parsed data from preview.
  Future<ImportResult> executeImport(Map<String, List<CsvRow>> tripExpenses) async {
    final existingTrips = await _tripDao.getAllTrips();
    final existingNames = existingTrips.map((t) => t.name).toSet();

    int tripsCreated = 0;
    int expensesImported = 0;

    for (final entry in tripExpenses.entries) {
      final tripName = entry.key;
      final rows = entry.value;

      int tripId;
      if (existingNames.contains(tripName)) {
        tripId = existingTrips.firstWhere((t) => t.name == tripName).id!;
      } else {
        final dates = rows.map((r) => r.date).toList()..sort();
        final trip = Trip(
          name: tripName,
          budget: 0,
          baseCurrency: rows.first.baseCurrency.isNotEmpty
              ? rows.first.baseCurrency
              : 'TWD',
          targetCurrency:
              rows.first.currency.isNotEmpty ? rows.first.currency : 'JPY',
          startDate: dates.first,
          endDate: dates.last,
        );
        tripId = await _tripDao.insertTrip(trip);
        tripsCreated++;
      }

      for (final row in rows) {
        final expense = Expense(
          tripId: tripId,
          title: row.title,
          amount: row.amount,
          currency: row.currency.isNotEmpty ? row.currency : 'JPY',
          convertedAmount: row.convertedAmount,
          exchangeRate: row.exchangeRate,
          category: row.category,
          note: row.note.isNotEmpty ? row.note : null,
          date: row.date,
        );
        await _expenseDao.insertExpense(expense);
        expensesImported++;
      }
    }

    return ImportResult(
      success: true,
      message: '匯入完成：$expensesImported 筆消費'
          '${tripsCreated > 0 ? '、新增 $tripsCreated 個旅行' : ''}'
    );
  }

  CsvRow? _parseCsvLine(String line) {
    try {
      final parts = _splitCsvLine(line);
      if (parts.length < 6) return null;

      final dateFormat = DateFormat('yyyy/MM/dd');
      return CsvRow(
        tripName: parts[0],
        date: dateFormat.parse(parts[1]),
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == parts[2],
          orElse: () => ExpenseCategory.values.firstWhere(
            (c) => c.displayName == parts[2],
            orElse: () => ExpenseCategory.food,
          ),
        ),
        title: parts[3],
        amount: double.parse(parts[4]),
        currency: parts[5],
        convertedAmount:
            parts.length > 6 && parts[6].isNotEmpty ? double.tryParse(parts[6]) : null,
        baseCurrency: parts.length > 7 ? parts[7] : '',
        exchangeRate:
            parts.length > 8 && parts[8].isNotEmpty ? double.tryParse(parts[8]) : null,
        note: parts.length > 9 ? parts[9] : '',
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class CsvRow {
  final String tripName;
  final DateTime date;
  final ExpenseCategory category;
  final String title;
  final double amount;
  final String currency;
  final double? convertedAmount;
  final String baseCurrency;
  final double? exchangeRate;
  final String note;

  CsvRow({
    required this.tripName,
    required this.date,
    required this.category,
    required this.title,
    required this.amount,
    required this.currency,
    this.convertedAmount,
    required this.baseCurrency,
    this.exchangeRate,
    required this.note,
  });
}

class ImportResult {
  final bool success;
  final String message;

  ImportResult({required this.success, required this.message});
}

class ImportPreview {
  final List<TripImportSummary> tripSummaries;
  final int skipped;
  final String? error;
  final Map<String, List<CsvRow>>? parsedData;

  int get totalExpenses =>
      tripSummaries.fold(0, (sum, s) => sum + s.expenseCount);
  int get newTrips => tripSummaries.where((s) => s.isNew).length;
  int get existingTrips => tripSummaries.where((s) => !s.isNew).length;

  ImportPreview({
    required this.tripSummaries,
    required this.skipped,
    this.error,
    this.parsedData,
  });
}

class TripImportSummary {
  final String tripName;
  final int expenseCount;
  final bool isNew;

  TripImportSummary({
    required this.tripName,
    required this.expenseCount,
    required this.isNew,
  });
}
