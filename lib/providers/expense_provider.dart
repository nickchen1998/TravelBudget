import 'package:flutter/foundation.dart';
import '../constants/categories.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../repositories/expense_repository.dart';
import '../repositories/trip_repository.dart' show NetworkException;

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repo = ExpenseRepository();

  List<Expense> _expenses = [];
  int? _currentTripId;
  Trip? _currentTrip;

  List<Expense> get expenses => _expenses;
  int? get currentTripId => _currentTripId;
  Trip? get currentTrip => _currentTrip;

  double get totalSpent {
    return _expenses.fold(0.0, (sum, e) => sum + (e.convertedAmount ?? 0.0));
  }

  Map<ExpenseCategory, double> get totalsByCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + (e.convertedAmount ?? 0.0);
    }
    return map;
  }

  Map<DateTime, List<Expense>> get expensesByDate {
    final map = <DateTime, List<Expense>>{};
    for (final e in _expenses) {
      final dateKey = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(dateKey, () => []).add(e);
    }
    return map;
  }

  Map<DateTime, double> get dailyTotals {
    final map = <DateTime, double>{};
    for (final e in _expenses) {
      final dateKey = DateTime(e.date.year, e.date.month, e.date.day);
      map[dateKey] = (map[dateKey] ?? 0.0) + (e.convertedAmount ?? 0.0);
    }
    return map;
  }

  Future<void> loadExpenses(Trip trip) async {
    _currentTripId = trip.id;
    _currentTrip = trip;

    _expenses = await _repo.getExpenses(
      trip.id ?? 0,
      tripUuid: trip.uuid,
    );

    notifyListeners();
  }

  /// Returns null on success, an error key string on failure.
  Future<String?> addExpense(Expense expense) async {
    try {
      final saved = await _repo.addExpense(expense, tripUuid: _currentTrip?.uuid);
      _expenses.insert(0, saved);
      notifyListeners();
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  Future<String?> updateExpense(Expense expense) async {
    try {
      await _repo.updateExpense(expense, tripUuid: _currentTrip?.uuid);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  Future<String?> deleteExpense(int id) async {
    final expense = _expenses.where((e) => e.id == id).firstOrNull;
    if (expense == null) return null;
    try {
      await _repo.deleteExpense(
        id,
        expenseUuid: expense.uuid,
        tripUuid: _currentTrip?.uuid,
      );
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }
}
