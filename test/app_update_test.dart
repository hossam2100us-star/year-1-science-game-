import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/account/account_controller.dart';
import 'package:science_adventure/data/update/app_update.dart';
import 'package:science_adventure/parent/parent_gate.dart';
import 'package:science_adventure/parent/update_banner.dart';
import 'package:science_adventure/parent/update_settings.dart';

import 'setup_screen_test.dart' show SilentNarration, gateAnswer;

/// The Android side of the update check, without Android.
class FakePlatform implements AppPlatform {
  FakePlatform([this.current = const AppVersion(8, '0.6.0')]);
  final AppVersion? current;
  final opened = <Uri>[];

  @override
  Future<AppVersion?> version() async => current;

  @override
  Future<bool> openUrl(Uri url) async {
    opened.add(url);
    return true;
  }
}

final server = Uri.parse('https://family.example');

/// A family server whose version.json says [body] (or answers [status]).
MockClient familyServer(
  Object? body, {
  int status = 200,
  List<Uri>? requests,
}) => MockClient((request) async {
  requests?.add(request.url);
  return http.Response(
    body is String ? body : jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
});

const newer = {'versionCode': 9, 'versionName': '0.6.1', 'page': '/download/'};

void main() {
  group('UpdateChecker', () {
    Future<AvailableUpdate?> check(
      http.Client client, {
      AppPlatform? platform,
    }) => UpdateChecker(
      server: server,
      platform: platform ?? FakePlatform(),
      client: client,
    ).check();

    test('reads version.json on the family server and offers a newer '
        'versionCode', () async {
      final requests = <Uri>[];
      final update = await check(familyServer(newer, requests: requests));
      expect(requests, [
        Uri.parse('https://family.example/download/version.json'),
      ]);
      expect(update?.code, 9);
      expect(update?.name, '0.6.1');
      expect(update?.page, Uri.parse('https://family.example/download/'));
    });

    test('sends nothing about the device or the children', () async {
      late http.BaseRequest sent;
      await check(
        MockClient((request) async {
          sent = request;
          return http.Response(jsonEncode(newer), 200);
        }),
      );
      expect(sent.method, 'GET');
      expect(sent.url.query, isEmpty);
      expect(
        sent.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(
        sent.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('cookie')),
      );
    });

    test('the same or an older version is not an update', () async {
      expect(await check(familyServer({...newer, 'versionCode': 8})), isNull);
      expect(await check(familyServer({...newer, 'versionCode': 7})), isNull);
    });

    test('a missing page means the download page', () async {
      final update = await check(
        familyServer({'versionCode': 9, 'versionName': '0.6.1'}),
      );
      expect(update?.page, Uri.parse('https://family.example/download/'));
    });

    test('never opens a page on another site', () async {
      expect(
        await check(
          familyServer({...newer, 'page': 'https://other.example/x'}),
        ),
        isNull,
      );
      expect(
        await check(familyServer({...newer, 'page': 'http://family.example/'})),
        isNull,
      );
      expect(
        await check(familyServer({...newer, 'page': '//other.example/'})),
        isNull,
      );
    });

    test(
      'a missing file, a broken file or no network is simply no update',
      () async {
        expect(await check(familyServer('Not found', status: 404)), isNull);
        expect(await check(familyServer('{"versionCode": ')), isNull);
        expect(await check(familyServer('[]')), isNull);
        expect(
          await check(familyServer({'versionCode': '9', 'versionName': 'x'})),
          isNull,
        );
        expect(
          await check(
            MockClient((_) async => throw const SocketException('offline')),
          ),
          isNull,
        );
      },
    );

    test('a server that never answers does not hold anything up', () async {
      final update = UpdateChecker(
        server: server,
        platform: FakePlatform(),
        client: MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 50),
      ).check();
      expect(await update, isNull);
    });

    test('an unknown app version asks nothing', () async {
      final requests = <Uri>[];
      expect(
        await check(
          familyServer(newer, requests: requests),
          platform: FakePlatform(null),
        ),
        isNull,
      );
      expect(requests, isEmpty);
    });
  });

  group('UpdateController', () {
    late MemoryAccountPrefs prefs;
    late FakePlatform platform;
    late List<Uri> requests;

    setUp(() {
      prefs = MemoryAccountPrefs();
      platform = FakePlatform();
      requests = [];
    });

    ProviderContainer container({
      Object? body = newer,
      Uri? baseUri,
      bool android = true,
    }) {
      final c = ProviderContainer(
        overrides: [
          accountSetupProvider.overrideWithValue(
            AccountSetup(
              prefs: prefs,
              deviceId: 'device',
              initialMode: AccountMode.deviceOnly,
              baseUri: baseUri ?? server,
            ),
          ),
          appPlatformProvider.overrideWithValue(android ? platform : null),
          updateHttpClientProvider.overrideWithValue(
            familyServer(body, requests: requests),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('looks once at start-up, in device-only mode too', () async {
      final c = container();
      final controller = c.read(updateProvider.notifier);
      await controller.start();
      await controller.start();
      expect(requests, hasLength(1));
      expect(c.read(updateProvider).available?.name, '0.6.1');
      expect(c.read(updateProvider).current?.name, '0.6.0');
      expect(c.read(updateProvider).enabled, isTrue);
    });

    test('no Android, no request (web and tests)', () async {
      final c = container(android: false);
      await c.read(updateProvider.notifier).start();
      expect(requests, isEmpty);
      expect(c.read(updateProvider).available, isNull);
    });

    test('turned off by the parent: no request at all', () async {
      await prefs.set(UpdateController.enabledKey, 'off');
      final c = container();
      await c.read(updateProvider.notifier).start();
      expect(requests, isEmpty);
      expect(c.read(updateProvider).enabled, isFalse);
      expect(c.read(updateProvider).current?.name, '0.6.0');
    });

    test(
      'turning it off hides the banner, turning it on looks again',
      () async {
        final c = container();
        final controller = c.read(updateProvider.notifier);
        await controller.start();
        await controller.setEnabled(false);
        expect(c.read(updateProvider).available, isNull);
        expect(await prefs.get(UpdateController.enabledKey), 'off');

        await controller.setEnabled(true);
        expect(await prefs.get(UpdateController.enabledKey), isNull);
        expect(requests, hasLength(2));
        expect(c.read(updateProvider).available?.code, 9);
      },
    );

    test('"Later" hides this version for good, but not the next one', () async {
      final c = container();
      await c.read(updateProvider.notifier).start();
      await c.read(updateProvider.notifier).dismiss();
      expect(c.read(updateProvider).available, isNull);
      expect(await prefs.get(UpdateController.dismissedKey), '9');

      final again = container();
      await again.read(updateProvider.notifier).start();
      expect(again.read(updateProvider).available, isNull);

      final next = container(body: {...newer, 'versionCode': 10});
      await next.read(updateProvider.notifier).start();
      expect(next.read(updateProvider).available?.code, 10);
    });

    test('opens the download page in the browser', () async {
      final c = container();
      await c.read(updateProvider.notifier).start();
      expect(await c.read(updateProvider.notifier).openDownload(), isTrue);
      expect(platform.opened, [Uri.parse('https://family.example/download/')]);
    });
  });

  group('banner and settings', () {
    late MemoryAccountPrefs prefs;
    late FakePlatform platform;

    setUp(() {
      ParentGatePolicy.reset();
      prefs = MemoryAccountPrefs();
      platform = FakePlatform();
    });
    tearDown(ParentGatePolicy.reset);

    Future<ProviderContainer> mount(WidgetTester tester, Widget child) async {
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(
            MemoryProgressStore(const AppData(profile: ChildProfile())),
          ),
          narrationProvider.overrideWith((ref) => SilentNarration()),
          accountSetupProvider.overrideWithValue(
            AccountSetup(
              prefs: prefs,
              deviceId: 'device',
              initialMode: AccountMode.deviceOnly,
              baseUri: server,
            ),
          ),
          appPlatformProvider.overrideWithValue(platform),
          updateHttpClientProvider.overrideWithValue(familyServer(newer)),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(body: ListView(children: [child])),
          ),
        ),
      );
      return c;
    }

    testWidgets('nothing shows until a newer version is found', (tester) async {
      final c = await mount(tester, const UpdateBanner());
      expect(find.byKey(const ValueKey('update-banner')), findsNothing);
      await tester.runAsync(c.read(updateProvider.notifier).start);
      await tester.pump();
      expect(find.byKey(const ValueKey('update-banner')), findsOneWidget);
      expect(find.textContaining('0.6.1'), findsOneWidget);
    });

    testWidgets('Later hides the banner and remembers it', (tester) async {
      final c = await mount(tester, const UpdateBanner());
      await tester.runAsync(c.read(updateProvider.notifier).start);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('update-later')));
      await tester.pump();
      expect(find.byKey(const ValueKey('update-banner')), findsNothing);
      expect(await prefs.get(UpdateController.dismissedKey), '9');
    });

    testWidgets('Update asks the parent gate before opening the browser', (
      tester,
    ) async {
      final c = await mount(tester, const UpdateBanner());
      await tester.runAsync(c.read(updateProvider.notifier).start);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('update-now')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ParentGateDialog), findsOneWidget);
      expect(platform.opened, isEmpty, reason: 'a child cannot pass on');

      await tester.tap(find.text('رجوع • Back'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(platform.opened, isEmpty);

      await tester.tap(find.byKey(const ValueKey('update-now')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), gateAnswer(tester));
      await tester.tap(find.text('كمّل • Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(platform.opened, [Uri.parse('https://family.example/download/')]);
    });

    testWidgets('the parent area switch turns the check off and shows the '
        'version', (tester) async {
      final c = await mount(tester, const UpdateSettings(arabic: false));
      await tester.runAsync(c.read(updateProvider.notifier).start);
      await tester.pump();
      expect(find.text('This version: 0.6.0'), findsOneWidget);
      final toggle = find.byKey(const ValueKey('update-check-switch'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.runAsync(() async {});
      expect(await prefs.get(UpdateController.enabledKey), 'off');
      expect(c.read(updateProvider).available, isNull);
    });

    testWidgets('no switch without Android', (tester) async {
      final c = ProviderContainer(
        overrides: [appPlatformProvider.overrideWithValue(null)],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(body: UpdateSettings(arabic: true)),
          ),
        ),
      );
      expect(find.byType(SwitchListTile), findsNothing);
    });
  });
}
