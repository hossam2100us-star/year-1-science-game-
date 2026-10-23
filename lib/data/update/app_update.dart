import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/diagnostics/app_log.dart';
import '../account/account_controller.dart';

/// This app's version as Android knows it (versionCode and versionName).
@immutable
class AppVersion {
  const AppVersion(this.code, this.name);
  final int code;
  final String name;
}

/// A newer APK on the family server's download page.
@immutable
class AvailableUpdate {
  const AvailableUpdate({
    required this.code,
    required this.name,
    required this.page,
  });
  final int code;
  final String name;

  /// The download page to open in the browser.
  final Uri page;
}

/// What the update check needs from Android (MainActivity's
/// `science_adventure/app` channel).
abstract interface class AppPlatform {
  Future<AppVersion?> version();
  Future<bool> openUrl(Uri url);
}

class AndroidAppPlatform implements AppPlatform {
  static const _channel = MethodChannel('science_adventure/app');

  @override
  Future<AppVersion?> version() async {
    final info = await _channel.invokeMapMethod<String, Object?>('version');
    final code = info?['code'];
    return code is int ? AppVersion(code, '${info?['name'] ?? ''}') : null;
  }

  @override
  Future<bool> openUrl(Uri url) async =>
      await _channel.invokeMethod<bool>('openUrl', {'url': '$url'}) ?? false;
}

/// Reads `<server>/download/version.json`, written with each release next to
/// the APK (docs/RELEASE.md):
///
///     {"versionCode": 9, "versionName": "0.6.1", "page": "/download/"}
///
/// It is the only request the app makes without a parent account (ADR-0020).
/// Nothing about the device or the children is sent, and any problem means
/// "no update": play never waits for it.
class UpdateChecker {
  UpdateChecker({
    required this.server,
    required this.platform,
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();

  final Uri server;
  final AppPlatform platform;
  final http.Client _client;
  final Duration timeout;

  Future<AvailableUpdate?> check() async {
    try {
      final current = await platform.version();
      if (current == null) return null;
      final response = await _client
          .get(server.resolve('/download/version.json'))
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map) return null;
      final code = json['versionCode'];
      final name = json['versionName'];
      if (code is! int || name is! String || code <= current.code) return null;
      final page = server.resolve(
        json['page'] is String ? json['page'] as String : '/download/',
      );
      // Only the family server's own page is ever opened.
      if (page.host != server.host || page.scheme != server.scheme) {
        return null;
      }
      return AvailableUpdate(code: code, name: name, page: page);
    } on Object catch (error) {
      // Offline is normal here, so only the kind of problem is noted.
      AppLog.info('update', 'No update information (${error.runtimeType})');
      return null;
    }
  }
}

@immutable
class UpdateState {
  const UpdateState({this.enabled = true, this.available, this.current});

  /// The parent's switch in the parent area (on unless turned off).
  final bool enabled;

  /// A newer version the parent has not dismissed.
  final AvailableUpdate? available;

  /// This app's version, shown in the parent area.
  final AppVersion? current;

  UpdateState copyWith({
    bool? enabled,
    AvailableUpdate? Function()? available,
    AppVersion? current,
  }) => UpdateState(
    enabled: enabled ?? this.enabled,
    available: available == null ? this.available : available(),
    current: current ?? this.current,
  );
}

/// Android's platform channel, or none (web, tests).
final appPlatformProvider = Provider<AppPlatform?>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? AndroidAppPlatform()
      : null,
);

/// Replaced in tests with a fake server.
final updateHttpClientProvider = Provider<http.Client?>((ref) => null);

final updateProvider = NotifierProvider<UpdateController, UpdateState>(
  UpdateController.new,
);

/// Looks for a newer APK once when the app opens (owner request, 21 October
/// 2026). The banner offers it to the parent; "Later" hides it until the
/// next version.
class UpdateController extends Notifier<UpdateState> {
  static const enabledKey = 'update.check';
  static const dismissedKey = 'update.dismissed';

  bool _started = false;

  AccountPrefs get _prefs => ref.read(accountSetupProvider).prefs;

  @override
  UpdateState build() => const UpdateState();

  /// Called once at start-up; does nothing without Android or a server.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _look();
  }

  Future<void> _look() async {
    final platform = ref.read(appPlatformProvider);
    final server = ref.read(accountSetupProvider).server;
    if (platform == null || server == null) return;
    final enabled = await _prefs.get(enabledKey) != 'off';
    final current = await _version(platform);
    state = state.copyWith(enabled: enabled, current: current);
    if (!enabled) return;
    final update = await UpdateChecker(
      server: server,
      platform: platform,
      client: ref.read(updateHttpClientProvider),
    ).check();
    if (update == null) return;
    if (await _prefs.get(dismissedKey) == '${update.code}') return;
    state = state.copyWith(available: () => update);
  }

  Future<AppVersion?> _version(AppPlatform platform) async {
    try {
      return await platform.version();
    } on Object catch (error, stack) {
      AppLog.warning('update', 'App version unknown', error, stack);
      return null;
    }
  }

  /// "Later": not again for this version.
  Future<void> dismiss() async {
    final update = state.available;
    if (update == null) return;
    state = state.copyWith(available: () => null);
    await _prefs.set(dismissedKey, '${update.code}');
  }

  /// Opens the download page in the browser (after the parent gate).
  Future<bool> openDownload() async {
    final update = state.available;
    final platform = ref.read(appPlatformProvider);
    if (update == null || platform == null) return false;
    try {
      return await platform.openUrl(update.page);
    } on Object catch (error, stack) {
      AppLog.warning(
        'update',
        'Could not open the download page',
        error,
        stack,
      );
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _prefs.set(enabledKey, enabled ? null : 'off');
    state = state.copyWith(
      enabled: enabled,
      available: enabled ? null : () => null,
    );
    if (enabled) await _look();
  }
}
