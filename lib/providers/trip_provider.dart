import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';

class TripProvider extends ChangeNotifier {
  final TripRepository _repo = TripRepository();

  List<Trip> _trips = [];
  final Map<int, double> _tripSpending = {};

  List<Trip> get trips => _trips;

  double getSpentForTrip(int tripId) => _tripSpending[tripId] ?? 0.0;

  Future<void> loadTrips() async {
    _trips = await _repo.getAllTrips();
    for (final trip in _trips) {
      if (trip.id != null) {
        _tripSpending[trip.id!] = await _repo.getTotalSpent(trip.id!);
      }
    }
    notifyListeners();
  }

  Future<Trip> addTrip(Trip trip) async {
    final newTrip = await _repo.addTrip(trip);
    _trips.insert(0, newTrip);
    _tripSpending[newTrip.id!] = 0.0;
    notifyListeners();
    return newTrip;
  }

  Future<void> updateTrip(Trip trip) async {
    await _repo.updateTrip(trip);
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(int id) async {
    await _repo.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    _tripSpending.remove(id);
    notifyListeners();
  }

  Future<void> deleteTripByUuid(String uuid) async {
    await _repo.deleteTripByUuid(uuid);
    _trips.removeWhere((t) => t.uuid == uuid);
    notifyListeners();
  }

  Future<void> leaveTrip(String tripUuid) async {
    await _repo.leaveTrip(tripUuid);
    _trips.removeWhere((t) => t.uuid == tripUuid);
    notifyListeners();
  }

  void updateSpending(int tripId, double total) {
    _tripSpending[tripId] = total;
    notifyListeners();
  }

  /// Called after account deletion: reset sync fields in DB, remove cloud-only trips from list.
  Future<void> onAccountDeleted() async {
    await _repo.clearCloudSyncFields();
    // Keep only trips that exist locally (have a SQLite id)
    _trips = _trips.where((t) => t.id != null).toList();
    notifyListeners();
  }
}
