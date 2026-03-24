import 'package:flutter/foundation.dart';
import '../constants/categories.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseDao _dao = ExpenseDao();

  List<Expense> _expenses = [];
  int? _currentTripId;

  List<Expense> get expenses => _expenses;
  int? get currentTripId => _currentTripId;

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

  Future<void> loadExpenses(int tripId) async {
    _currentTripId = tripId;
    _expenses = await _dao.getExpensesByTripId(tripId);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final id = await _dao.insertExpense(expense);
    _expenses.insert(0, expense.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dao.updateExpense(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _dao.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
