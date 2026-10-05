import 'package:flutter/services.dart';

/// Child first-name rules (SEC-05), shared with the server DTO rules in the
/// future architecture: Unicode letters (Arabic or English), combining marks
/// such as Arabic diacritics, spaces, hyphens and apostrophes; at most 24
/// characters. The name is optional on the device, so empty is allowed here.
final class ChildName {
  ChildName._();

  static const maxLength = 24;
  static final RegExp _allowedCharacter = RegExp(
    r"[\p{L}\p{M} '’\-]",
    unicode: true,
  );
  static final RegExp _valid = RegExp(r"^[\p{L}\p{M} '’\-]*$", unicode: true);

  /// Blocks markup, digits, control characters and emoji while typing.
  static final List<TextInputFormatter> inputFormatters = [
    FilteringTextInputFormatter.allow(_allowedCharacter),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  static bool isValid(String name) =>
      name.length <= maxLength && _valid.hasMatch(name);
}
