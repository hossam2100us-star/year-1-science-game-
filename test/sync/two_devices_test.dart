import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/data/sync/sync_engine.dart';
import 'package:science_adventure/data/sync/sync_store.dart';

import 'fake_sync_server.dart';

class MemoryTokens implements RefreshTokenStore {
  String? value = 'R' * 43;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

UnitAttempt attempt(String id, {int day = 9}) => UnitAttempt(
  unitId: 'unit_02',
  completedAt: DateTime(2026, 10, day, 9, 30),
  objectives: const {'o.1': DecisionOutcome.firstTry},
  completed: true,
  effortStars: 2,
  attemptId: id,
);

const parent = '0192f0a0-0000-7000-8000-000000000001';

/// One install of the app: its own database, store, AppController and sync.
class Device {
  Device(this.server);
  final FakeSyncServer server;
  late final AppDatabase db;
  late final DriftProgressStore store;
  late final ProviderContainer container;
  late final SyncStore syncStore;
  late final SyncEngine engine;

  Future<Device> open() async {
    db = AppDatabase(NativeDatabase.memory());
    store = await DriftProgressStore.open(db);
    container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    container.listen(appProvider, (_, _) {});
    syncStore = SyncStore(db, deviceId: store.deviceId);
    engine = SyncEngine(
      store: syncStore,
      client: ApiClient(
        base: Uri.parse('https://school.example.test'),
        httpClient: MockClient(server.handle),
        tokens: MemoryTokens(),
        deviceId: store.deviceId,
      ),
      userId: parent,
      exclusive: app.exclusive,
      applyExternal: (apply) => app.applyExternal(apply, reload: store.reload),
    );
    return this;
  }

  AppController get app => container.read(appProvider.notifier);
  AppData get data => container.read(appProvider);

  Future<SyncFailure?> sync() => engine.run();

  Future<void> link(String childId) async {
    await app.applyExternal(() async {
      await syncStore.useAccount(parent);
      await syncStore.link(childId);
      return true;
    }, reload: store.reload);
  }

  AppData child(String id) => data.activeChildId == id
      ? data
      : AppData.fromJson(data.savedChildren[id]!);

  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}

void main() {
  // Each device has its own in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeSyncServer server;
  late Device phone, tablet;
  late String laila;

  setUp(() async {
    server = FakeSyncServer();
    phone = await Device(server).open();
    tablet = await Device(server).open();
    laila = phone.data.activeChildId;
    await phone.app.saveProfile(
      const ChildProfile(name: 'Laila', gender: ChildGender.girl),
    );
    await phone.app.recordAttempt(attempt('unit_02-1'));
    await phone.app.usageFor(
      laila,
      DateTime(2026, 10, 9, 9),
      DateTime(2026, 10, 9, 9, 5),
    );
  });

  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  test(
    'a child linked on the phone arrives on the tablet with progress',
    () async {
      await phone.link(laila);
      expect(await phone.sync(), isNull);
      expect(await phone.syncStore.outbox.waitingCount(), 0);

      expect(await tablet.sync(), isNull);
      final there = tablet.child(laila);
      expect(there.profile?.name, 'Laila');
      expect(there.profile?.gender, ChildGender.girl);
      expect(there.profile?.photo, isNull);
      expect(there.attempts.single.attemptId, 'unit_02-1');
      expect(there.dailySeconds, {'2026-10-09': 300});
      expect(tablet.store.linkedChildren, contains(laila));
    },
  );

  test('progress from both devices adds up on both', () async {
    await phone.link(laila);
    await phone.sync();
    await tablet.sync();
    await tablet.app.selectChild(laila);
    await tablet.app.recordAttempt(attempt('unit_02-2', day: 10));
    await tablet.app.usageFor(
      laila,
      DateTime(2026, 10, 9, 18),
      DateTime(2026, 10, 9, 18, 10),
    );
    await phone.app.usageFor(
      laila,
      DateTime(2026, 10, 9, 19),
      DateTime(2026, 10, 9, 19, 1),
    );
    await tablet.sync();
    await phone.sync();
    await tablet.sync();
    for (final device in [phone, tablet]) {
      final child = device.child(laila);
      expect(child.attempts.map((a) => a.attemptId).toSet(), {
        'unit_02-1',
        'unit_02-2',
      });
      // 5 + 1 minutes on the phone, 10 on the tablet.
      expect(child.dailySeconds, {'2026-10-09': 960});
    }
  });

  test(
    'a name changed on both devices keeps the first and tells the parent',
    () async {
      await phone.link(laila);
      await phone.sync();
      await tablet.sync();
      await tablet.app.selectChild(laila);
      await phone.app.saveProfile(
        const ChildProfile(name: 'Lulu', gender: ChildGender.girl, avatar: 1),
      );
      await tablet.app.saveProfile(
        const ChildProfile(name: 'Lola', gender: ChildGender.girl, avatar: 2),
      );
      await phone.sync();
      await tablet.sync();
      await phone.sync();
      for (final device in [phone, tablet]) {
        expect(device.child(laila).profile?.name, 'Lulu');
        // Avatar is a low-value field: the later change wins everywhere.
        expect(device.child(laila).profile?.avatar, 2);
      }
      final issues = await tablet.syncStore.issues();
      expect(issues.single.field, 'displayName');
      expect(issues.single.mine, 'Lola');
      expect(issues.single.theirs, 'Lulu');
      expect(await phone.syncStore.issues(), isEmpty);
    },
  );

  test('different settings changed on each device are both kept', () async {
    await phone.link(laila);
    await phone.sync();
    await tablet.sync();
    await tablet.app.selectChild(laila);
    await phone.app.settings(phone.data.settings.copyWith(music: false));
    await tablet.app.settings(tablet.data.settings.copyWith(breakMinutes: 20));
    await phone.sync();
    await tablet.sync();
    await phone.sync();
    for (final device in [phone, tablet]) {
      expect(device.child(laila).settings.music, isFalse);
      expect(device.child(laila).settings.breakMinutes, 20);
    }
  });

  test('records of the same journey from both devices are merged', () async {
    await phone.link(laila);
    await phone.sync();
    await tablet.sync();
    await tablet.app.selectChild(laila);
    await phone.app.saveJourney('discovery.animals', {
      'version': 1,
      'results': {'cat': 'firstTry'},
    });
    await tablet.app.saveJourney('discovery.animals', {
      'version': 1,
      'results': {'dog': 'afterHint'},
    });
    await phone.sync();
    await tablet.sync();
    await phone.sync();
    for (final device in [phone, tablet]) {
      expect(device.child(laila).journeys['discovery.animals']?['results'], {
        'cat': 'firstTry',
        'dog': 'afterHint',
      });
    }
  });

  test('a child removed on one device is removed on the other', () async {
    await phone.link(laila);
    await phone.sync();
    await tablet.sync();
    await phone.app.addChild(const ChildProfile(name: 'Omar'));
    await phone.app.removeChild(laila);
    await phone.sync();
    await tablet.sync();
    expect(tablet.data.childRecords.containsKey(laila), isFalse);
    final issue = (await tablet.syncStore.issues()).single;
    expect(issue.kind, 'childRemoved');
    expect(issue.childName, 'Laila');
    expect(server.children[laila]?['deleted'], isTrue);
  });

  test('a child that is not linked never reaches the account', () async {
    await phone.app.addChild(const ChildProfile(name: 'Omar'));
    final omar = phone.data.activeChildId;
    await phone.link(laila);
    await phone.sync();
    expect(server.children.keys, [laila]);
    expect(server.attempts.values.map((a) => a['childId']).toSet(), {laila});
    expect(server.children.containsKey(omar), isFalse);
  });

  test('offline: nothing is lost and nothing is sent twice', () async {
    await phone.link(laila);
    server.offline = true;
    expect(await phone.sync(), SyncFailure.offline);
    expect(await phone.syncStore.outbox.waitingCount(), greaterThan(0));
    server.offline = false;
    server.loseNextAnswer = true;
    expect(await phone.sync(), SyncFailure.offline);
    expect(await phone.sync(), isNull);
    expect(await phone.syncStore.outbox.waitingCount(), 0);
    expect(server.attempts, hasLength(1));
    expect(server.children[laila]?['version'], 1);
  });

  test('an unconfirmed email stops sync and keeps every change', () async {
    server.emailVerified = false;
    await phone.link(laila);
    expect(await phone.sync(), SyncFailure.emailNotVerified);
    expect(await phone.syncStore.outbox.waitingCount(), 4);
    expect(server.children, isEmpty);
  });

  test(
    'signing in to another account keeps children on the device only',
    () async {
      await phone.link(laila);
      await phone.sync();
      final other = SyncStore(phone.db, deviceId: phone.store.deviceId);
      expect(await other.useAccount(Ids.uuidV7()), isTrue);
      await phone.store.reload();
      expect(phone.store.linkedChildren, isEmpty);
      expect(phone.child(laila).attempts, hasLength(1));
      expect(await other.outbox.waitingCount(), 0);
    },
  );
}
