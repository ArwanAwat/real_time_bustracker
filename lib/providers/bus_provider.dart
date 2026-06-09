import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/bus.dart';
import '../models/bus_log.dart';

class BusProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<Bus> _buses = [];
  Map<String, int> _fleetStats = {};
  Map<String, double> _fleetAverages = {};
  String _filter = 'all';
  String _search = '';
  bool _loading = false;
  bool _autoRefresh = true;
  Timer? _timer;
  String? _lastAlert;

  List<Bus> get buses => _buses;
  Map<String, int> get fleetStats => _fleetStats;
  Map<String, double> get fleetAverages => _fleetAverages;
  String get filter => _filter;
  String get search => _search;
  bool get loading => _loading;
  bool get autoRefresh => _autoRefresh;
  String? get lastAlert => _lastAlert;

  BusProvider() {
    loadAll();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_autoRefresh) {
        await _db.simulateAllBuses();
        await loadAll(silent: true);
      }
    });
  }

  void toggleAutoRefresh() {
    _autoRefresh = !_autoRefresh;
    notifyListeners();
  }

  void setFilter(String f) {
    _filter = f;
    loadAll();
  }

  void setSearch(String s) {
    _search = s;
    loadAll();
  }

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    _buses = await _db.getAllBuses(
        statusFilter: _filter == 'all' ? null : _filter,
        search: _search.isEmpty ? null : _search);
    _fleetStats = await _db.getFleetStats();
    _fleetAverages = await _db.getFleetAverages();
    _loading = false;
    notifyListeners();
  }

  Future<void> addBus(Bus bus) async {
    await _db.insertBus(bus);
    await loadAll();
  }

  Future<void> updateBus(Bus bus) async {
    await _db.updateBus(bus);
    await loadAll(silent: true);
  }

  Future<void> deleteBus(int id) async {
    await _db.deleteBus(id);
    await loadAll();
  }

  Future<({Bus updated, String? statusChange})> refreshBus(int id) async {
    final result = await _db.simulateGpsUpdate(id);
    if (result.statusChange != null) {
      _lastAlert =
          'Bus updated to: ${result.statusChange!.replaceAll('_', ' ')}';
    }
    await loadAll(silent: true);
    return result;
  }

  Future<List<BusLog>> getLogsForBus(int busId) =>
      _db.getLogsForBus(busId);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}