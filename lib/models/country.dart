class Country {
  final String _name;
  final String _code;
  final int _stationCount;

  Country({
    required String name,
    required String code,
    required int stationCount,
  })  : _name = name,
        _code = code,
        _stationCount = stationCount;

  String get name => _name;
  String get code => _code;
  int get stationCount => _stationCount;

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      code: (json['iso_3166_1'] as String).toLowerCase(),
      stationCount: json['stationcount'],
    );
  }
}
