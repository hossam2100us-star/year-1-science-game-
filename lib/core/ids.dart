import 'dart:math';

/// Identifier generation that behaves identically on the Dart VM and on the
/// web.
///
/// Only byte-sized values are drawn from the random source: on dart2js integer
/// shifts are 32-bit, so `1 << 32` evaluates to `0` and
/// `Random.secure().nextInt(1 << 32)` throws a `RangeError` (AUD-005).
final class Ids {
  Ids._();

  static final Random _secure = Random.secure();

  /// A time-ordered UUID version 7 (RFC 9562) in canonical lowercase form,
  /// e.g. `0192f1c4-5b7e-7a3c-9f10-2b6d8e4a1c55`.
  ///
  /// [now] and [random] exist for deterministic tests.
  static String uuidV7({DateTime? now, Random? random}) {
    final source = random ?? _secure;
    final millis = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    final bytes = List<int>.generate(16, (_) => source.nextInt(256));
    // 48-bit big-endian Unix timestamp in milliseconds. Division instead of
    // shifts keeps the arithmetic exact on the web (doubles hold 53 bits).
    var remaining = millis;
    for (var i = 5; i >= 0; i--) {
      bytes[i] = remaining % 256;
      remaining ~/= 256;
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f); // version 7
    bytes[8] = 0x80 | (bytes[8] & 0x3f); // RFC 4122/9562 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// Whether [value] is a canonical lowercase RFC 9562 UUID.
  static bool isUuid(String value) => _uuid.hasMatch(value);
}
