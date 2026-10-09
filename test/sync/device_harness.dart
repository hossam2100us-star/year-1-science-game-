import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/data/sync/sync_engine.dart';
import 'package:science_adventure/data/sync/sync_store.dart';

class MemoryTokens implements RefreshTokenStore {
  MemoryTokens([this.value]);
  String? value;
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

/// One install of the app: its own database, store, AppController and sync.
class Device {
  Device._();
  late final AppDatabase db;
  late final DriftProgressStore store;
  late final ProviderContainer container;
  late final SyncStore syncStore;
  late final SyncEngine engine;
  late final String userId;

  /// [signIn] returns the parent's user ID (after signing in, if needed).
  static Future<Device> open({
    required ApiClient Function(String deviceId) client,
    required Future<String> Function(ApiClient client) signIn,
  }) async {
    final d = Device._();
    d.db = AppDatabase(NativeDatabase.memory());
    d.store = await DriftProgressStore.open(d.db);
    d.container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(d.store)],
    );
    d.container.listen(appProvider, (_, _) {});
    d.syncStore = SyncStore(d.db, deviceId: d.store.deviceId);
    final api = client(d.store.deviceId);
    d.userId = await signIn(api);
    d.engine = SyncEngine(
      store: d.syncStore,
      client: api,
      userId: d.userId,
      exclusive: d.app.exclusive,
      applyExternal: (apply) =>
          d.app.applyExternal(apply, reload: d.store.reload),
    );
    return d;
  }

  AppController get app => container.read(appProvider.notifier);
  AppData get data => container.read(appProvider);

  Future<SyncFailure?> sync() => engine.run();

  Future<void> link(String childId) async {
    await app.applyExternal(() async {
      await syncStore.useAccount(userId);
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

/// Two-device scenarios that only look at what the devices show, so they
/// run against the in-memory server and against the real backend alike.
/// [devices] opens a phone and a tablet signed in to the same new parent.
void sharedScenarios(Future<(Device, Device)> Function() devices) {
  late Device phone, tablet;
  late String laila;

  setUp(() async {
    (phone, tablet) = await devices();
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
      expect(await phone.syncStore.outbox.quarantined(), isEmpty);

      expect(await tablet.sync(), isNull);
      final there = tablet.child(laila);
      expect(there.profile?.name, 'Laila');
      expect(there.profile?.gender, ChildGender.girl);
      expect(there.profile?.photo, isNull);
      expect(there.attempts.single.attemptId, 'unit_02-1');
      expect(there.attempts.single.objectives, {
        'o.1': DecisionOutcome.firstTry,
      });
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
    expect(await tablet.sync(), isNull);
    expect(await phone.sync(), isNull);
    expect(await tablet.sync(), isNull);
    for (final device in [phone, tablet]) {
      final child = device.child(laila);
      expect(child.attempts.map((a) => a.attemptId).toSet(), {
        'unit_02-1',
        'unit_02-2',
      });
      // 5 + 1 minutes on the phone, 10 on the tablet.
      expect(child.dailySeconds, {'2026-10-09': 960});
      expect(await device.syncStore.outbox.quarantined(), isEmpty);
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
      expect(await phone.sync(), isNull);
      expect(await tablet.sync(), isNull);
      expect(await phone.sync(), isNull);
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
    expect(await phone.sync(), isNull);
    expect(await tablet.sync(), isNull);
    expect(await phone.sync(), isNull);
    for (final device in [phone, tablet]) {
      expect(device.child(laila).settings.music, isFalse);
      expect(device.child(laila).settings.breakMinutes, 20);
      expect(await device.syncStore.outbox.quarantined(), isEmpty);
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
    expect(await phone.sync(), isNull);
    expect(await tablet.sync(), isNull);
    expect(await phone.sync(), isNull);
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
    expect(await phone.sync(), isNull);
    expect(await tablet.sync(), isNull);
    expect(tablet.data.childRecords.containsKey(laila), isFalse);
    final issue = (await tablet.syncStore.issues()).single;
    expect(issue.kind, 'childRemoved');
    expect(issue.childName, 'Laila');
  });
}
