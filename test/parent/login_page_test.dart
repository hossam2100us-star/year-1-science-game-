import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/data/account/account_controller.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/features/onboarding/profile_editor.dart';
import 'package:science_adventure/main.dart';
import 'package:science_adventure/parent/login_page.dart';
import 'package:science_adventure/parent/parent_gate.dart';

import '../setup_screen_test.dart' show SilentNarration, gateAnswer;
import '../sync/device_harness.dart' show MemoryTokens;
import '../sync/fake_sync_server.dart';

/// The login page (owner's decision, 16 October 2026): first each time the
/// app opens until a parent signs in; continuing without the Internet needs
/// nothing and sends nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  setUpAll(() async => catalog = await Catalog.load());

  late FakeSyncServer server;
  late AppDatabase db;
  late DriftProgressStore store;
  late MemoryAccountPrefs prefs;

  setUp(() {
    server = FakeSyncServer();
    prefs = MemoryAccountPrefs();
    ParentGatePolicy.reset();
  });
  tearDown(ParentGatePolicy.reset);

  const parent = AccountUser(
    id: '0192f0a0-0000-7000-8000-000000000001',
    email: 'parent@example.com',
    emailVerified: true,
    signInMethods: ['password'],
  );

  /// Opens the app of a build that knows the server.
  Future<void> open(
    WidgetTester tester, {
    bool chosen = false,
    AccountUser? signedIn,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = await DriftProgressStore.open(db);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(catalog),
          narrationProvider.overrideWith((ref) => SilentNarration()),
          accountSetupProvider.overrideWithValue(
            AccountSetup(
              prefs: prefs,
              deviceId: store.deviceId,
              initialMode: signedIn == null
                  ? AccountMode.deviceOnly
                  : AccountMode.account,
              initialUser: signedIn,
              initialChosen: chosen,
              baseUri: Uri.parse('https://school.example.test'),
              clientFactory: (uri, device) => ApiClient(
                base: uri,
                httpClient: MockClient(server.handle),
                tokens: MemoryTokens(),
                deviceId: device,
              ),
            ),
          ),
        ],
        // Like the app: Material texts in English and Arabic.
        child: const MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('en'), Locale('ar')],
          home: AdventureHome(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Lets database and HTTP work finish, then rebuilds.
  Future<void> settle(WidgetTester tester, [int rounds = 6]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> passGate(WidgetTester tester) async {
    expect(find.byType(ParentGateDialog), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(ParentGateDialog),
        matching: find.byType(TextField),
      ),
      gateAnswer(tester),
    );
    await tester.tap(find.text('كمّل • Continue'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Types the parent's email and password and presses "Sign in"; the
  /// first time, the parent agrees to what an account stores.
  Future<void> signIn(WidgetTester tester, {bool consent = true}) async {
    await tester.enterText(
      find.byKey(const ValueKey('account-email')),
      'parent@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-password')),
      'a long password here',
    );
    await tester.tap(find.byKey(const ValueKey('account-submit')));
    await tester.pump(const Duration(milliseconds: 400));
    if (consent) {
      expect(find.byType(ParentGateDialog), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(ValueKey('consent-$i')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('consent-continue')));
    }
    await settle(tester, 12);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  WidgetRef refOf(WidgetTester tester) =>
      tester.state<ConsumerState>(find.byType(AdventureHome)).ref;

  testWidgets('the login page opens first; offline needs no gate or network', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const ValueKey('account-email')), findsOneWidget);
    expect(find.byType(ProfileEditor), findsNothing);
    await tester.tap(find.byKey(const ValueKey('login-offline')));
    await settle(tester);
    expect(find.byType(ParentGateDialog), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(ProfileEditor), findsOneWidget);
    expect(await prefs.get(AccountSetup.choiceKey), 'device');
    expect(server.requests, isEmpty);
    await close(tester);
  });

  testWidgets('it comes back each time the app opens until a sign-in', (
    tester,
  ) async {
    // Continuing offline before is remembered, but the page still opens.
    await open(tester, chosen: true);
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-offline')));
    await settle(tester);
    expect(find.byType(ProfileEditor), findsOneWidget);
    await close(tester);
  });

  testWidgets('a saved session goes straight in and is never interrupted', (
    tester,
  ) async {
    // The session cannot be resumed (no saved token): the parent is signed
    // out in the background, and the game carries on.
    await open(tester, signedIn: parent);
    expect(find.byType(LoginPage), findsNothing);
    await settle(tester, 12);
    expect(refOf(tester).read(accountProvider).signedIn, isFalse);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(ProfileEditor), findsOneWidget);
    await close(tester);
  });

  testWidgets(
    "signing in brings the account's children and goes straight to them",
    (tester) async {
      final laila = Ids.uuidV7();
      server.seedChild(laila, 'Laila');
      await open(tester);
      expect(server.requests, isEmpty);
      await signIn(tester);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsNothing);
      // The child from the account is on this device, ready to play, and is
      // not offered again (it is already in the account).
      expect(find.byType(ProfileEditor), findsNothing);
      expect(find.text('Laila'), findsOneWidget);
      expect(find.byKey(const ValueKey('offer-save')), findsNothing);
      expect(store.linkedChildren, {laila});
      await close(tester);
    },
  );

  testWidgets('a sign-in that fails can continue offline, with no account', (
    tester,
  ) async {
    await open(tester);
    server.offline = true;
    await signIn(tester);
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-offline')));
    await settle(tester);
    expect(find.byType(ProfileEditor), findsOneWidget);
    final account = refOf(tester).read(accountProvider);
    expect(account.mode, AccountMode.deviceOnly);
    expect(refOf(tester).read(accountProvider.notifier).client, isNull);
    expect(await prefs.get(AccountSetup.modeKey), isNull);
    await close(tester);
  });

  testWidgets('a child created while signed in is offered to the account', (
    tester,
  ) async {
    await open(tester);
    await signIn(tester);
    expect(find.byType(ProfileEditor), findsOneWidget);

    // Onboarding saves the first child.
    await tester.runAsync(
      () =>
          refOf(tester)
              .read(appProvider.notifier)
              .saveProfile(const ChildProfile(name: 'Nour')),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('offer-save')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('offer-save')));
    await tester.pump(const Duration(milliseconds: 400));
    await passGate(tester);
    await settle(tester, 12);
    final nour = store.read().activeChildId;
    expect(store.linkedChildren, {nour});
    expect(server.children[nour]?['displayName'], 'Nour');
    await close(tester);
  });
}
