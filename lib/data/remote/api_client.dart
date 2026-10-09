import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_errors.dart';

/// The signed-in parent as the server describes them.
@immutable
class AccountUser {
  const AccountUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.signInMethods,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
    id: json['id'] as String,
    email: json['email'] as String,
    emailVerified: json['emailVerified'] as bool,
    signInMethods: [for (final m in json['signInMethods'] as List) m as String],
  );

  final String id;
  final String email;
  final bool emailVerified;
  final List<String> signInMethods;

  bool get hasPassword => signInMethods.contains('password');
}

@immutable
class PullPage {
  const PullPage(this.changes, this.cursor, this.hasMore);
  final List<Map<String, dynamic>> changes;
  final int cursor;
  final bool hasMore;
}

/// Where the long-lived refresh token is kept. Android: the Keystore-backed
/// secure storage. Web: nowhere the app can read (an HttpOnly cookie).
abstract interface class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureRefreshTokenStore implements RefreshTokenStore {
  SecureRefreshTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'sa.account.refresh';

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Web: the browser holds the refresh token as an HttpOnly cookie.
class CookieRefreshTokenStore implements RefreshTokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

/// Typed client for `api/openapi.yaml` (ADR-0014: written by hand, shapes
/// checked against the contract's example messages in tests).
///
/// The access token lives in memory only. Refreshing is single-flight, so
/// two requests that both find an expired token rotate the refresh token
/// once (a second rotation would look like token theft to the server).
class ApiClient {
  ApiClient({
    required this.base,
    required http.Client httpClient,
    required this._tokens,
    required this.deviceId,
    String? platform,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient,
       platform = platform ?? (kIsWeb ? 'web' : 'android');

  final Uri base;
  final String deviceId;
  final String platform;
  final Duration timeout;
  final http.Client _http;
  final RefreshTokenStore _tokens;

  String? _access;
  DateTime _accessExpires = DateTime.fromMillisecondsSinceEpoch(0);
  Future<AccountUser?>? _refreshing;

  bool get _cookieSession => platform == 'web';

  // ---- account ---------------------------------------------------------------

  Future<void> register(String email, String password) => _send(
    'POST',
    '/api/v1/auth/register',
    body: {
      'email': email,
      'password': password,
      'consentVersion': ApiConfig.consentVersion,
    },
  );

  Future<void> resendVerification(String email) =>
      _send('POST', '/api/v1/auth/resend-verification', body: {'email': email});

  Future<void> forgotPassword(String email) =>
      _send('POST', '/api/v1/auth/forgot-password', body: {'email': email});

  Future<AccountUser> login(String email, String password) async =>
      _startSession(
        (await _send(
          'POST',
          '/api/v1/auth/login',
          body: {
            'email': email,
            'password': password,
            'deviceId': deviceId,
            'platform': platform,
          },
        ))!,
      );

  /// [consentVersion] is needed only when the Google account is new here.
  Future<AccountUser> loginWithGoogle(
    String idToken, {
    String? consentVersion,
  }) async => _startSession(
    (await _send(
      'POST',
      '/api/v1/auth/google',
      body: {
        'idToken': idToken,
        'deviceId': deviceId,
        'platform': platform,
        'consentVersion': ?consentVersion,
      },
    ))!,
  );

  /// Resumes a saved session at app start. Null when there is none.
  Future<AccountUser?> restore() async {
    if (!_cookieSession && await _tokens.read() == null) return null;
    try {
      return await _refresh();
    } on SignedOut {
      return null;
    }
  }

  Future<AccountUser> me() async =>
      AccountUser.fromJson((await _authed('GET', '/api/v1/users/me'))!);

  Future<void> logout({bool all = false}) async {
    try {
      await _authed('POST', '/api/v1/auth/logout', body: {'all': all});
    } on SignedOut {
      // Already signed out on the server.
    } on NetworkFailure {
      // Offline: the device forgets the session anyway; it expires on the server.
    } finally {
      await _forget();
    }
  }

  Future<DateTime> deleteAccount({
    String? password,
    String? googleIdToken,
  }) async {
    final body = await _authed(
      'DELETE',
      '/api/v1/users/me',
      body: password != null
          ? {'password': password}
          : {'googleIdToken': googleIdToken},
    );
    await _forget();
    return DateTime.parse(body!['deletionScheduledAt'] as String);
  }

  // ---- sync ------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> push(
    List<Map<String, dynamic>> mutations,
  ) async {
    final body = await _authed(
      'POST',
      '/api/v1/sync/push',
      body: {
        'deviceId': deviceId,
        'platform': platform,
        'mutations': mutations,
      },
    );
    return [
      for (final r in body!['results'] as List)
        Map<String, dynamic>.from(r as Map),
    ];
  }

  Future<PullPage> pull(int since, {int limit = 200}) async {
    final body = await _authed(
      'GET',
      '/api/v1/sync/pull?since=$since&limit=$limit',
    );
    return PullPage(
      [
        for (final c in body!['changes'] as List)
          Map<String, dynamic>.from(c as Map),
      ],
      body['cursor'] as int,
      body['hasMore'] as bool,
    );
  }

  // ---- parent pages ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> children() async {
    final body = await _authed('GET', '/api/v1/children');
    return [
      for (final c in body!['items'] as List)
        Map<String, dynamic>.from(c as Map),
    ];
  }

  Future<Map<String, dynamic>> reportSummary(String childId) async =>
      (await _authed('GET', '/api/v1/children/$childId/reports/summary'))!;

  Future<Map<String, dynamic>> settings(String childId) async =>
      (await _authed('GET', '/api/v1/children/$childId/settings'))!;

  Future<Map<String, dynamic>> putSettings(
    String childId,
    Map<String, dynamic> settings,
    int baseVersion,
  ) async => (await _authed(
    'PUT',
    '/api/v1/children/$childId/settings',
    body: {...settings, 'baseVersion': baseVersion},
  ))!;

  // ---- plumbing ------------------------------------------------------------------

  Future<AccountUser> _startSession(Map<String, dynamic> body) async {
    _access = body['accessToken'] as String;
    _accessExpires = DateTime.now().add(
      Duration(seconds: (body['expiresIn'] as int) - 30),
    );
    final refresh = body['refreshToken'] as String?;
    if (refresh != null) await _tokens.write(refresh);
    return AccountUser.fromJson(Map<String, dynamic>.from(body['user'] as Map));
  }

  Future<void> _forget() async {
    _access = null;
    _accessExpires = DateTime.fromMillisecondsSinceEpoch(0);
    await _tokens.clear();
  }

  Future<AccountUser> _refresh() {
    final running = _refreshing;
    if (running != null) return running.then((u) => u!);
    final task = _doRefresh();
    _refreshing = task;
    return task.whenComplete(() => _refreshing = null).then((u) => u!);
  }

  Future<AccountUser?> _doRefresh() async {
    final stored = _cookieSession ? null : await _tokens.read();
    if (!_cookieSession && stored == null) throw SignedOut();
    for (var attempt = 0; ; attempt++) {
      try {
        return await _startSession(
          (await _send(
            'POST',
            '/api/v1/auth/refresh',
            body: stored == null
                ? <String, dynamic>{}
                : {'refreshToken': stored},
            headers: _cookieSession
                ? const {'X-CSRF-Protection': '1'}
                : const {},
          ))!,
        );
      } on ApiProblem catch (p) {
        // Another tab renewed the shared cookie a moment ago: use the new one.
        if (p.code == 'refresh_superseded' && _cookieSession && attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }
        if (p.status == 401 || p.status == 403 || p.status == 409) {
          await _forget();
          throw SignedOut();
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> _authed(
    String method,
    String path, {
    Object? body,
  }) async {
    if (_access == null || DateTime.now().isAfter(_accessExpires)) {
      await _refresh();
    }
    try {
      return await _send(method, path, body: body, bearer: _access);
    } on ApiProblem catch (p) {
      if (p.status != 401) rethrow;
      // Expired or revoked in between: renew once and try again.
      await _refresh();
      return _send(method, path, body: body, bearer: _access);
    }
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Object? body,
    String? bearer,
    Map<String, String> headers = const {},
  }) async {
    final request = http.Request(method, base.resolve(path))
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        'Authorization': ?(bearer == null ? null : 'Bearer $bearer'),
        ...headers,
      });
    if (body != null) request.body = jsonEncode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      ).timeout(timeout);
    } on Exception catch (error) {
      throw NetworkFailure(error.runtimeType.toString());
    }
    final json = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    final retry = int.tryParse(response.headers['retry-after'] ?? '');
    throw ApiProblem(
      response.statusCode,
      json?['code'] as String? ?? 'http_${response.statusCode}',
      detail: json?['detail'] as String?,
      retryAfter: retry == null ? null : Duration(seconds: retry),
      body: json,
    );
  }

  /// JSON object, or null for an empty or non-JSON body (e.g. a proxy's
  /// HTML error page).
  static Map<String, dynamic>? _decode(String text) {
    if (text.isEmpty) return null;
    try {
      final value = jsonDecode(text);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on FormatException {
      return null;
    }
  }
}
