import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart' show TripRepository, NetworkException, TripLimitException;

class TripProvider extends ChangeNotifier {
  final TripRepository _repo = TripRepository();

  List<Trip> _trips = [];
  final Map<int, double> _tripSpending = {};
  bool _isOffline = false;

  List<Trip> get trips => _trips;
  bool get isOffline => _isOffline;

  double getSpentForTrip(int tripId) => _tripSpending[tripId] ?? 0.0;

  Future<void> loadTrips() async {
    try {
      _trips = await _repo.getAllTrips();
      _isOffline = false;
    } on NetworkException {
      _isOffline = true;
      _trips = await _repo.getAllTrips(); // falls back to cache
    } catch (_) {
      _trips = [];
    }
    for (final trip in _trips) {
      if (trip.id != null) {
        _tripSpending[trip.id!] = await _repo.getTotalSpent(trip.id!);
      }
    }
    notifyListeners();
  }

  /// Creates a local trip (always succeeds, no network required).
  Future<String?> addTrip(Trip trip) async {
    try {
      final newTrip = await _repo.addTrip(trip);
      _trips.insert(0, newTrip);
      _tripSpending[newTrip.id!] = 0.0;
      notifyListeners();
      return null;
    } catch (_) {
      return 'save_failed';
    }
  }

  /// Upload a local trip to Supabase. Returns null on success, error key on failure.
  Future<String?> uploadLocalTripToCloud(Trip trip) async {
    try {
      final promoted = await _repo.uploadLocalTripToCloud(trip);
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = promoted;
        notifyListeners();
      }
      return null;
    } on NetworkException {
      return 'network_required';
    } on TripLimitException {
      return 'trip_limit_exceeded';
    } catch (_) {
      return 'save_failed';
    }
  }

  /// 計算目前雲端旅行數量（owner 身份）
  int get cloudTripCount =>
      _trips.where((t) => t.uuid != null && (t.memberRole == null || t.memberRole == 'owner')).length;

  /// Returns null on success, an error key string on failure.
  Future<String?> updateTrip(Trip trip) async {
    try {
      await _repo.updateTrip(trip);
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
        notifyListeners();
      }
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  Future<String?> deleteTrip(int id) async {
    try {
      await _repo.deleteTrip(id);
      _trips.removeWhere((t) => t.id == id);
      _tripSpending.remove(id);
      notifyListeners();
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  Future<String?> deleteTripByUuid(String uuid) async {
    try {
      await _repo.deleteTripByUuid(uuid);
      _trips.removeWhere((t) => t.uuid == uuid);
      notifyListeners();
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  Future<String?> leaveTrip(String tripUuid) async {
    try {
      await _repo.leaveTrip(tripUuid);
      _trips.removeWhere((t) => t.uuid == tripUuid);
      notifyListeners();
      return null;
    } on NetworkException {
      return 'network_required';
    } catch (_) {
      return 'save_failed';
    }
  }

  void updateSpending(int tripId, double total) {
    _tripSpending[tripId] = total;
    notifyListeners();
  }

  Future<void> onAccountDeleted() async {
    await _repo.clearCloudSyncFields();
    _trips = _trips.where((t) => t.id != null).toList();
    notifyListeners();
  }
}
