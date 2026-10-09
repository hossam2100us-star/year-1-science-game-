import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:science_adventure/data/account/account_controller.dart';
import 'package:science_adventure/data/remote/api_client.dart';

class MemoryTokens implements RefreshTokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

const userJson = {
  'id': '0192f0a0-0000-7000-8000-000000000001',
  'email': 'parent@example.com',
  'emailVerified': false,
  'signInMethods': ['password'],
  'createdAt': '2026-10-09T10:00:00.000Z',
};

http.Response ok(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> session(String access) => {
  'accessToken': access,
  'tokenType': 'Bearer',
  'expiresIn': 900,
  'refreshToken': 'R' * 43,
  'user': userJson,
};

void main() {
  late MemoryAccountPrefs prefs;
  late MemoryTokens tokens;
  late List<String> requests;
  late Future<http.Response> Function(http.Request) server;

  ProviderContainer container({
    AccountMode mode = AccountMode.deviceOnly,
    Uri? base,
    AccountUser? user,
  }) {
    final c = ProviderContainer(
      overrides: [
        accountSetupProvider.overrideWithValue(
          AccountSetup(
            prefs: prefs,
            deviceId: 'device-1',
            initialMode: mode,
            initialUser: user,
            baseUri: base ?? Uri.parse('https://school.example.test'),
            clientFactory: (uri, device) => ApiClient(
              base: uri,
              httpClient: MockClient((r) {
                requests.add('${r.method} ${r.url.path}');
                return server(r);
              }),
              tokens: tokens,
              deviceId: device,
            ),
          ),
        ),
      ],
    );
    // Like the app's widgets, keep listening so the provider stays active.
    c.listen(accountProvider, (_, _) {});
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    prefs = MemoryAccountPrefs();
    tokens = MemoryTokens();
    requests = [];
    server = (r) async => ok(<String, Object>{});
  });

  test('device-only mode has no API client and makes no request', () async {
    final c = container();
    final state = c.read(accountProvider);
    expect(state.available, isTrue);
    expect(state.mode, AccountMode.deviceOnly);
    expect(c.read(accountProvider.notifier).client, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(requests, isEmpty);
  });

  test(
    'choosing an account creates the client and remembers the choice',
    () async {
      final c = container();
      await c.read(accountProvider.notifier).useAccount();
      expect(c.read(accountProvider.notifier).client, isNotNull);
      expect(await prefs.get(AccountSetup.modeKey), 'account');
      expect(requests, isEmpty);
    },
  );

  test(
    'signing in remembers the parent and keeps the token in the secure store',
    () async {
      server = (r) async => ok(session('A'));
      final c = container();
      final account = c.read(accountProvider.notifier);
      await account.useAccount();
      await account.signIn('parent@example.com', 'a long password here');
      expect(c.read(accountProvider).user?.email, 'parent@example.com');
      expect(tokens.value, 'R' * 43);
      final saved = jsonDecode((await prefs.get(AccountSetup.userKey))!) as Map;
      expect(saved['email'], 'parent@example.com');
      expect(saved.containsKey('accessToken'), isFalse);
    },
  );

  test('resumes a saved session in the background at start-up', () async {
    tokens.value = 'R' * 43;
    server = (r) async => ok(session('A'));
    final c = container(mode: AccountMode.account);
    expect(c.read(accountProvider).restoring, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(requests, ['POST /api/v1/auth/refresh']);
    expect(c.read(accountProvider).restoring, isFalse);
    expect(c.read(accountProvider).user?.id, userJson['id']);
  });

  test('offline at start-up keeps the last known parent', () async {
    tokens.value = 'R' * 43;
    server = (r) async => throw http.ClientException('offline');
    final known = AccountUser.fromJson(userJson);
    final c = container(mode: AccountMode.account, user: known);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(accountProvider).user?.email, known.email);
    expect(c.read(accountProvider).restoring, isFalse);
  });

  test(
    'going back to this device only signs out and drops the client',
    () async {
      server = (r) async => r.url.path == '/api/v1/auth/logout'
          ? http.Response('', 204)
          : ok(session('A'));
      final c = container();
      final account = c.read(accountProvider.notifier);
      await account.useAccount();
      await account.signIn('parent@example.com', 'a long password here');
      await account.useDeviceOnly();
      expect(requests.last, 'POST /api/v1/auth/logout');
      expect(account.client, isNull);
      expect(c.read(accountProvider).mode, AccountMode.deviceOnly);
      expect(await prefs.get(AccountSetup.modeKey), isNull);
      expect(await prefs.get(AccountSetup.userKey), isNull);
      expect(tokens.value, isNull);
    },
  );

  test('the first-run choice is remembered across restarts', () async {
    final c = container();
    expect(c.read(accountProvider).chosen, isFalse);
    expect((await AccountSetup.load(prefs, 'device-1')).initialChosen, isFalse);
    await c.read(accountProvider.notifier).chooseDeviceOnly();
    expect(c.read(accountProvider).chosen, isTrue);
    expect(c.read(accountProvider).mode, AccountMode.deviceOnly);
    expect(requests, isEmpty);
    expect((await AccountSetup.load(prefs, 'device-1')).initialChosen, isTrue);
  });

  test('a build without a server address has no accounts', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(accountProvider).available, isFalse);
    await expectLater(
      c.read(accountProvider.notifier).useAccount(),
      throwsStateError,
    );
  });
}
