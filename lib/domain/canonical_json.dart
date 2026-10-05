import 'dart:convert';

/// JSON with object keys sorted at every level, so two values with the same
/// content compare equal regardless of insertion order. Used for round-trip
/// checks and migration checksums.
String canonicalJson(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) => switch (value) {
  final Map<dynamic, dynamic> map => {
    for (final key in map.keys.map((k) => '$k').toList()..sort())
      key: _canonical(map[key]),
  },
  final Iterable<dynamic> list => [for (final v in list) _canonical(v)],
  _ => value,
};
