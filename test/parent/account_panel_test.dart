import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/data/account/account_controller.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/parent/parent_area.dart';

import '../setup_screen_test.dart' show SilentNarration;
import '../sync/fake_sync_server.dart';

class MemoryTokens implements RefreshTokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  setUpAll(() async => catalog = await Catalog.load());

  late FakeSyncServer server;
  late AppDatabase db;
  late DriftProgressStore store;

  Future<void> mount(WidgetTester tester, {bool withServer = true}) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = await DriftProgressStore.open(db);
      await store.write(
        AppData(
          activeChildId: store.read().activeChildId,
          profile: const ChildProfile(name: 'Laila', gender: ChildGender.girl),
          settings: const AppSettings(arabic: false),
        ),
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(catalog),
          narrationProvider.overrideWith((ref) => SilentNarration()),
          accountSetupProvider.overrideWithValue(
            AccountSetup(
              prefs: MemoryAccountPrefs(),
              deviceId: store.deviceId,
              initialMode: AccountMode.deviceOnly,
              baseUri: withServer
                  ? Uri.parse('https://school.example.test')
                  : null,
              clientFactory: (uri, device) => ApiClient(
                base: uri,
                httpClient: MockClient(server.handle),
                tokens: MemoryTokens(),
                deviceId: device,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ParentArea()),
      ),
    );
    await tester.pump();
  }

  /// Lets database and HTTP work finish, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  setUp(() => server = FakeSyncServer());

  testWidgets('a build without a server has no account tab', (tester) async {
    await mount(tester, withServer: false);
    expect(find.text('Parent account'), findsNothing);
    await unmount(tester);
  });

  testWidgets('device-only by default; an account needs every consent point', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Parent account'));
    await tester.pump();
    expect(find.text('This device only'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('account-start')));
    await tester.pumpAndSettle();
    final go = find.byKey(const ValueKey('consent-continue'));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(ValueKey('consent-$i')));
      await tester.pump();
    }
    expect(tester.widget<FilledButton>(go).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('consent-2')));
    await tester.pump();
    await tester.tap(go);
    await tester.pumpAndSettle();
    await settle(tester);
    expect(find.byKey(const ValueKey('account-email')), findsOneWidget);
    expect(server.requests, isEmpty, reason: 'no request before sign-in');
    await unmount(tester);
  });

  testWidgets('after sign-in a child is saved in the account and synced', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Parent account'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('consent-$i')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('consent-continue')));
    await tester.pumpAndSettle();
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('account-email')),
      'parent@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-password')),
      'a long password here',
    );
    await tester.tap(find.byKey(const ValueKey('account-submit')));
    await settle(tester);
    expect(find.text('Signed in as parent@example.com'), findsOneWidget);

    final child = store.read().activeChildId;
    await tester.tap(find.byKey(ValueKey('account-link-$child')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-confirm')));
    await settle(tester);
    await settle(tester);
    expect(find.text('Saved in the account'), findsOneWidget);
    expect(server.children.keys, [child]);
    expect(server.children[child]?['displayName'], 'Laila');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('sync-status'))).data,
      'Everything is saved in the account.',
    );
    await unmount(tester);
  });
}
