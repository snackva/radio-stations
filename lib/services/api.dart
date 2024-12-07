import 'dart:convert';

import 'package:radiostations/models/country.dart';
import 'package:http/http.dart' as http;
import 'package:radiostations/models/station.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  late final http.Client _client;
  final String _baseUrl = 'https://de1.api.radio-browser.info/json';

  factory ApiService() => _instance;

  ApiService._internal() {
    _client = http.Client();
  }

  Future<List<Country>?> countries({int limit = 10, int offset = 0}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/countries?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).map((country) => Country.fromJson(country)).toList();
    } else {
      return null;
    }
  }

  Future<List<Station>?> countryStations({required Country country, int limit = 10, int offset = 0}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/stations/bycountrycodeexact/${country.code}?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).map((station) => Station.fromJson(station)).toList();
    } else {
      return null;
    }
  }

  Future<Station?> station({required String uuid, int limit = 10, int offset = 0}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/stations/byuuid/$uuid'),
    );

    if (response.statusCode == 200) {
      final dynamic jsonStation = (jsonDecode(response.body) as List<dynamic>).firstOrNull;
      return jsonStation == null ? null : Station.fromJson(jsonStation);
    } else {
      return null;
    }
  }
}
