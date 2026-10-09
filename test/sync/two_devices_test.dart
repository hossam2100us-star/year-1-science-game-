import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/data/sync/sync_engine.dart';
import 'package:science_adventure/data/sync/sync_store.dart';

import 'device_harness.dart';
import 'fake_sync_server.dart';

const parent = '0192f0a0-0000-7000-8000-000000000001';

Future<Device> fakeDevice(FakeSyncServer server) => Device.open(
  client: (deviceId) => ApiClient(
    base: Uri.parse('https://school.example.test'),
    httpClient: MockClient(server.handle),
    tokens: MemoryTokens('R' * 43),
    deviceId: deviceId,
  ),
  signIn: (_) async => parent,
);

void main() {
  // Each device has its own in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeSyncServer server;

  group('two devices', () {
    sharedScenarios(() async {
      server = FakeSyncServer();
      return (await fakeDevice(server), await fakeDevice(server));
    });
  });

  group('one device', () {
    late Device phone;
    late String laila;

    setUp(() async {
      server = FakeSyncServer();
      phone = await fakeDevice(server);
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

    tearDown(() => phone.close());

    test('a child that is not linked never reaches the account', () async {
      await phone.app.addChild(const ChildProfile(name: 'Omar'));
      final omar = phone.data.activeChildId;
      await phone.link(laila);
      await phone.sync();
      expect(server.children.keys, [laila]);
      expect(server.attempts.values.map((a) => a['childId']).toSet(), {laila});
      expect(server.children.containsKey(omar), isFalse);
    });

    test('a removed child is deleted in the account', () async {
      await phone.link(laila);
      await phone.sync();
      await phone.app.addChild(const ChildProfile(name: 'Omar'));
      await phone.app.removeChild(laila);
      await phone.sync();
      expect(server.children[laila]?['deleted'], isTrue);
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
  });
}
