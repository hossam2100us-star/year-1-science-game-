import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/diagnostics/app_log.dart';
import '../db/app_database.dart';
import '../remote/api_client.dart';
import '../remote/api_config.dart';
import '../remote/api_errors.dart';

/// "This device only" (the default: no account, no network at all) or a
/// parent account that syncs linked children (ADR-0002).
enum AccountMode { deviceOnly, account }

@immutable
class AccountState {
  const AccountState({
    required this.available,
    this.mode = AccountMode.deviceOnly,
    this.user,
    this.restoring = false,
  });

  /// This build knows a server address (otherwise there is no account UI).
  final bool available;
  final AccountMode mode;

  /// The signed-in parent, or null (device-only, or signed out).
  final AccountUser? user;

  /// The saved session is being resumed in the background at start-up.
  final bool restoring;

  bool get signedIn => user != null;

  AccountState copyWith({
    AccountMode? mode,
    AccountUser? Function()? user,
    bool? restoring,
  }) => AccountState(
    available: available,
    mode: mode ?? this.mode,
    user: user == null ? this.user : user(),
    restoring: restoring ?? this.restoring,
  );
}

/// Small non-secret account facts kept with the app's data (the refresh
/// token itself lives in the Keystore, see [SecureRefreshTokenStore]).
abstract interface class AccountPrefs {
  Future<String?> get(String key);
  Future<void> set(String key, String? value);
}

class DatabaseAccountPrefs implements AccountPrefs {
  DatabaseAccountPrefs(this.db);
  final AppDatabase db;
  @override
  Future<String?> get(String key) => db.meta(key);
  @override
  Future<void> set(String key, String? value) =>
      value == null ? db.deleteMeta(key) : db.setMeta(key, value);
}

/// Web: the browser's cookie is the session; nothing else is stored.
class MemoryAccountPrefs implements AccountPrefs {
  final _values = <String, String>{};
  @override
  Future<String?> get(String key) async => _values[key];
  @override
  Future<void> set(String key, String? value) async =>
      value == null ? _values.remove(key) : _values[key] = value;
}

/// Everything the account layer needs from the app, provided at start-up.
@immutable
class AccountSetup {
  const AccountSetup({
    required this.prefs,
    required this.deviceId,
    required this.initialMode,
    this.initialUser,
    this.clientFactory,
    this.baseUri,
  });
  final AccountPrefs prefs;
  final String deviceId;
  final AccountMode initialMode;
  final AccountUser? initialUser;

  /// Tests replace the HTTP client; the app uses the real one.
  final ApiClient Function(Uri base, String deviceId)? clientFactory;

  /// Tests set the server address; the app takes it from the build.
  final Uri? baseUri;

  Uri? get server => baseUri ?? ApiConfig.baseUri;

  static const modeKey = 'account.mode';
  static const userKey = 'account.user';

  static Future<AccountSetup> load(AccountPrefs prefs, String deviceId) async {
    final mode = await prefs.get(modeKey) == 'account'
        ? AccountMode.account
        : AccountMode.deviceOnly;
    AccountUser? user;
    final saved = await prefs.get(userKey);
    if (saved != null) {
      try {
        user = AccountUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(saved) as Map),
        );
      } on Object {
        user = null;
      }
    }
    return AccountSetup(
      prefs: prefs,
      deviceId: deviceId,
      initialMode: mode,
      initialUser: user,
    );
  }
}

/// Overridden at start-up. The default is the app as it always was: device-only,
/// no server (tests and previews that do not care about accounts).
final accountSetupProvider = Provider<AccountSetup>(
  (ref) => AccountSetup(
    prefs: MemoryAccountPrefs(),
    deviceId: 'unset',
    initialMode: AccountMode.deviceOnly,
  ),
);

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

/// Owns the API client. In device-only mode there is no client object at
/// all, so no code path can make a network request.
class AccountController extends Notifier<AccountState> {
  ApiClient? _client;

  /// The client while a parent account is in use; null in device-only mode.
  ApiClient? get client => _client;

  AccountSetup get _setup => ref.read(accountSetupProvider);

  @override
  AccountState build() {
    final available = _setup.server != null;
    final mode = available ? _setup.initialMode : AccountMode.deviceOnly;
    if (mode == AccountMode.account) {
      _client = _newClient();
      // Resume in the background: the game never waits for the network.
      Future.microtask(_restore);
    }
    return AccountState(
      available: available,
      mode: mode,
      user: mode == AccountMode.account ? _setup.initialUser : null,
      restoring: mode == AccountMode.account,
    );
  }

  ApiClient _newClient() {
    final base = _setup.server!;
    final factory = _setup.clientFactory;
    if (factory != null) return factory(base, _setup.deviceId);
    return ApiClient(
      base: base,
      httpClient: http.Client(),
      tokens: kIsWeb ? CookieRefreshTokenStore() : SecureRefreshTokenStore(),
      deviceId: _setup.deviceId,
    );
  }

  Future<void> _restore() async {
    try {
      final user = await _client?.restore();
      await _remember(user);
    } on NetworkFailure {
      // Offline at start: keep the last known parent; sync retries later.
    } on Object catch (error, stack) {
      AppLog.error('account', 'Resuming the session failed', error, stack);
    } finally {
      state = state.copyWith(restoring: false);
    }
  }

  Future<void> _remember(AccountUser? user) async {
    state = state.copyWith(user: () => user);
    await _setup.prefs.set(
      AccountSetup.userKey,
      user == null
          ? null
          : jsonEncode({
              'id': user.id,
              'email': user.email,
              'emailVerified': user.emailVerified,
              'signInMethods': user.signInMethods,
            }),
    );
  }

  /// The parent chose a parent account (after the consent screen).
  Future<void> useAccount() async {
    if (!state.available) throw StateError('No server in this build');
    _client ??= _newClient();
    await _setup.prefs.set(AccountSetup.modeKey, 'account');
    state = state.copyWith(mode: AccountMode.account);
  }

  /// Back to "this device only": signs out, keeps every child on the device.
  Future<void> useDeviceOnly() async {
    if (state.signedIn) await signOut();
    _client = null;
    await _setup.prefs.set(AccountSetup.modeKey, null);
    state = state.copyWith(mode: AccountMode.deviceOnly, user: () => null);
  }

  ApiClient get _api {
    final client = _client;
    if (client == null) throw StateError('No parent account in use');
    return client;
  }

  Future<void> register(String email, String password) =>
      _api.register(email, password);

  Future<AccountUser> signIn(String email, String password) async {
    final user = await _api.login(email, password);
    await _remember(user);
    return user;
  }

  Future<AccountUser> signInWithGoogle(
    String idToken, {
    String? consentVersion,
  }) async {
    final user = await _api.loginWithGoogle(
      idToken,
      consentVersion: consentVersion,
    );
    await _remember(user);
    return user;
  }

  Future<void> resendVerification() async {
    final user = state.user;
    if (user != null) await _api.resendVerification(user.email);
  }

  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  /// Re-reads the parent (for example after confirming the email).
  Future<AccountUser?> refreshUser() async {
    try {
      final user = await _api.me();
      await _remember(user);
      return user;
    } on SignedOut {
      await _remember(null);
      return null;
    }
  }

  Future<void> signOut({bool everywhere = false}) async {
    await _client?.logout(all: everywhere);
    await _remember(null);
  }

  Future<DateTime> deleteAccount({
    String? password,
    String? googleIdToken,
  }) async {
    final when = await _api.deleteAccount(
      password: password,
      googleIdToken: googleIdToken,
    );
    await _remember(null);
    return when;
  }
}
