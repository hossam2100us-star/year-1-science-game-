import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/data/remote/api_client.dart';

import 'device_harness.dart';
import 'fake_sync_server.dart';

Future<Device> mathsDevice(FakeSyncServer server) => Device.open(
  client: (deviceId) => ApiClient(
    base: Uri.parse('https://school.example.test'),
    httpClient: MockClient(server.handle),
    tokens: MemoryTokens('R' * 43),
    deviceId: deviceId,
  ),
  signIn: (_) async => '0192f0a0-0000-7000-8000-000000000001',
);

Map<String, dynamic> resume(int index, String stepId) => {
  'version': 1,
  'attemptId': 'maths-run',
  'index': index,
  'stepId': stepId,
  'responses': <String, dynamic>{},
  'current': <String, dynamic>{},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeSyncServer server;
  late Device phone, tablet;
  late String childId;

  setUp(() async {
    server = FakeSyncServer();
    phone = await mathsDevice(server);
    tablet = await mathsDevice(server);
    childId = phone.data.activeChildId;
    await phone.app.saveProfile(const ChildProfile(name: 'Nour'));
    await phone.app.recordAttempt(attempt('science-run'));
    await phone.app.recordAttempt(attempt('maths-run'), subject: 'maths');
    await phone.app.saveJourney(
      'math_unit_01',
      resume(1, 'math_unit_01.step.002'),
      subject: 'maths',
    );
  });
  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  test(
    'linking queues both curricula and Maths reaches the second device',
    () async {
      await phone.link(childId);
      expect(await phone.sync(), isNull);
      expect(
        server.attempts.values
            .map((a) => (a['data'] as Map<String, dynamic>)['curriculum'])
            .toSet(),
        {'y1.science', 'y1.maths'},
      );
      expect(await tablet.sync(), isNull);
      final child = tablet.child(childId);
      expect(child.attempts.single.attemptId, 'science-run');
      final maths = child.progressForSubject('maths');
      expect(maths.attempts.single.attemptId, 'maths-run');
      expect(maths.journeys['math_unit_01']!['index'], 1);
      expect(await tablet.syncStore.outbox.quarantined(), isEmpty);
    },
  );

  test(
    'Maths updates and concurrent resumes do not overwrite Science',
    () async {
      await phone.link(childId);
      await phone.sync();
      await tablet.sync();
      await tablet.app.selectChild(childId);
      await tablet.app.recordAttempt(attempt('maths-tablet'), subject: 'maths');
      await phone.app.saveJourney(
        'math_unit_01',
        resume(2, 'math_unit_01.step.003'),
        subject: 'maths',
      );
      await tablet.app.saveJourney(
        'math_unit_01',
        resume(3, 'math_unit_01.step.004'),
        subject: 'maths',
      );
      expect(await phone.sync(), isNull);
      expect(await tablet.sync(), isNull);
      expect(await phone.sync(), isNull);
      for (final device in [phone, tablet]) {
        final child = device.child(childId);
        expect(child.attempts.single.attemptId, 'science-run');
        expect(child.journeys, isEmpty);
        final maths = child.progressForSubject('maths');
        expect(maths.attempts.map((a) => a.attemptId).toSet(), {
          'maths-run',
          'maths-tablet',
        });
        expect(maths.journeys['math_unit_01']!['index'], 3);
        expect(await device.syncStore.outbox.quarantined(), isEmpty);
      }
    },
  );

  test(
    'a device-only Maths child is not sent through another child link',
    () async {
      await phone.app.addChild(const ChildProfile(name: 'Adam'));
      final localId = phone.data.activeChildId;
      await phone.app.recordAttempt(attempt('local-maths'), subject: 'maths');
      await phone.link(childId);
      expect(await phone.sync(), isNull);
      expect(server.children.containsKey(localId), isFalse);
      expect(
        server.attempts.values.any((a) => a['childId'] == localId),
        isFalse,
      );
      expect(
        phone
            .child(localId)
            .progressForSubject('maths')
            .attempts
            .single
            .attemptId,
        'local-maths',
      );
    },
  );
}
