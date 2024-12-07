class Station {
  final String _uuid;
  final String _name;
  final String _streamUrl;
  final String? _iconUrl;
  final List<String> _tags;

  Station({
    required String uuid,
    required String name,
    required String streamUrl,
    required String? iconUrl,
    required List<String> tags,
  })  : _uuid = uuid,
        _name = name,
        _streamUrl = streamUrl,
        _iconUrl = iconUrl,
        _tags = tags;

  String get uuid => _uuid;
  String get name => _name;
  String get streamUrl => _streamUrl;
  String? get iconUrl => _iconUrl;
  List<String> get tags => _tags;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      uuid: json['stationuuid'],
      name: (json['name'] as String).trim(),
      streamUrl: json['url'],
      iconUrl: (json['favicon'] as String).isEmpty ? null : json['favicon'],
      tags: (json['tags'] as String).isEmpty ? [] : (json['tags'] as String).split(','),
    );
  }
}
