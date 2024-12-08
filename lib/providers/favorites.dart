import 'package:flutter/material.dart';
import 'package:radiostations/services/storage.dart';

class Favorites extends ChangeNotifier {
  static const String _key = 'favorites';
  List<String> _stations;

  Favorites() : _stations = StorageService().getStringList('$_key/stations') ?? [];

  List<String> get stations => _stations;

  void add(String stationUuid) {
    if (!_stations.contains(stationUuid)) {
      _stations = [stationUuid, ..._stations];
      StorageService().setStringList('$_key/stations', _stations);
      notifyListeners();
    }
  }

  void remove(String stationUuid) {
    if (_stations.contains(stationUuid)) {
      _stations = List.from(_stations)..remove(stationUuid);
      StorageService().setStringList('$_key/stations', _stations);
      notifyListeners();
    }
  }

  bool contains(String stationId) => _stations.contains(stationId);
}
