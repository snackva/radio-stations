import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  late final SharedPreferences _preferences;

  factory StorageService() => _instance;

  StorageService._internal();

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  List<String>? getStringList(String key) => _preferences.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) async => await _preferences.setStringList(key, value);

  double? getDouble(String key) => _preferences.getDouble(key);
  Future<bool> setDouble(String key, double value) async => await _preferences.setDouble(key, value);
}
