import 'package:flutter/foundation.dart';

/// Where the parent-account server is, decided when the app is built:
///
///   flutter build apk --dart-define=API_BASE_URL=https://school.example.synology.me
///
/// No address means this build has no accounts at all (the app is the
/// offline game it always was). The web app is served by the same server, so
/// it uses its own origin unless an address is given. Only public settings
/// live here; there are no secrets in the app.
abstract final class ApiConfig {
  static const _baseUrl = String.fromEnvironment('API_BASE_URL');

  /// The "Web application" OAuth client ID for Sign in with Google (public).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Version of the consent text the account screens show (must match the
  /// server's CONSENT_VERSION).
  static const consentVersion = String.fromEnvironment(
    'CONSENT_VERSION',
    defaultValue: 'trial-2026-10',
  );

  static Uri? get baseUri {
    if (_baseUrl.isNotEmpty) return Uri.parse(_baseUrl);
    if (kIsWeb &&
        (Uri.base.scheme == 'https' || Uri.base.host == 'localhost')) {
      return Uri.parse(Uri.base.origin);
    }
    return null;
  }

  static bool get accountsAvailable => baseUri != null;
}
