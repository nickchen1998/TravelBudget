import 'package:flutter/foundation.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  final TripDao _tripDao = TripDao();
  final ExpenseDao _expenseDao = ExpenseDao();

  List<Trip> _trips = [];
  final Map<int, double> _tripSpending = {};

  List<Trip> get trips => _trips;

  double getSpentForTrip(int tripId) => _tripSpending[tripId] ?? 0.0;

  Future<void> loadTrips() async {
    _trips = await _tripDao.getAllTrips();
    for (final trip in _trips) {
      if (trip.id != null) {
        _tripSpending[trip.id!] = await _expenseDao.getTotalSpentByTrip(trip.id!);
      }
    }
    notifyListeners();
  }

  Future<Trip> addTrip(Trip trip) async {
    final id = await _tripDao.insertTrip(trip);
    final newTrip = trip.copyWith(id: id);
    _trips.insert(0, newTrip);
    _tripSpending[id] = 0.0;
    notifyListeners();
    return newTrip;
  }

  Future<void> updateTrip(Trip trip) async {
    await _tripDao.updateTrip(trip);
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(int id) async {
    await _tripDao.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    _tripSpending.remove(id);
    notifyListeners();
  }

  void updateSpending(int tripId, double total) {
    _tripSpending[tripId] = total;
    notifyListeners();
  }
}
