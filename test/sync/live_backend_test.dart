@Tags(['live'])
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/data/remote/api_client.dart';

import 'device_harness.dart';

/// The same two-device scenarios against a real backend (`backend/`, with
/// REQUIRE_VERIFIED_EMAIL_FOR_SYNC=false and the memory mailer). Skipped
/// unless SYNC_LIVE_URL is set, for example:
///
///     $env:SYNC_LIVE_URL = 'http://localhost:3999'
///     flutter test test/sync/live_backend_test.dart
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final url = Platform.environment['SYNC_LIVE_URL'];
  if (url == null) {
    test('live backend', () {}, skip: 'SYNC_LIVE_URL is not set');
    return;
  }
  final base = Uri.parse(url);

  Future<Device> device(String email, String password) => Device.open(
    client: (deviceId) => ApiClient(
      base: base,
      httpClient: http.Client(),
      tokens: MemoryTokens(),
      deviceId: deviceId,
    ),
    signIn: (api) async => (await api.login(email, password)).id,
  );

  sharedScenarios(() async {
    final email = 'parent-${Ids.uuidV7()}@example.test';
    const password = 'a long trial password';
    final setup = ApiClient(
      base: base,
      httpClient: http.Client(),
      tokens: MemoryTokens(),
      deviceId: Ids.uuidV7(),
    );
    await setup.register(email, password);
    return (await device(email, password), await device(email, password));
  });
}
