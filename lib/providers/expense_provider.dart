import 'package:flutter/foundation.dart';
import '../constants/categories.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../repositories/expense_repository.dart';

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

    if (trip.id != null) {
      _expenses = await _repo.getExpensesByTripId(trip.id!);
    }

    // For shared trips with no local expenses, pull from cloud
    if (_expenses.isEmpty && trip.uuid != null && trip.isShared) {
      _expenses =
          await _repo.getCloudExpensesForTrip(trip.uuid!, trip.id ?? 0);
    }

    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final saved = await _repo.addExpense(expense,
        tripUuid: _currentTrip?.uuid);
    _expenses.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense, tripUuid: _currentTrip?.uuid);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    final expense = _expenses.firstWhere((e) => e.id == id);
    await _repo.deleteExpense(id, expenseUuid: expense.uuid);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
