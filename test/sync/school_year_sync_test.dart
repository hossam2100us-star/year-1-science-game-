import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';

import 'device_harness.dart';
import 'fake_sync_server.dart';
import 'maths_sync_test.dart' show mathsDevice, resume;

/// School years and sync (ADR-0021): the child's year and the progress of a
/// later year reach the parent's other devices, and Year 1 children keep
/// syncing with a server from before school years.
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
  });
  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  test('a Year 1 child syncs with a server from before school years', () async {
    server.knowsSchoolYears = false;
    await phone.link(childId);
    expect(await phone.sync(), isNull);
    expect(await phone.syncStore.outbox.quarantined(), isEmpty);
    expect(server.children[childId]!.containsKey('schoolYear'), isFalse);
    await phone.app.saveProfile(
      phone.data.profile!.copyWith(palette: PaletteChoice.berry),
    );
    expect(await phone.sync(), isNull);
    expect(await phone.syncStore.outbox.quarantined(), isEmpty);
    expect(server.children[childId]!['palette'], 'berry');

    expect(await tablet.sync(), isNull);
    final profile = tablet.child(childId).profile!;
    expect(profile.name, 'Nour');
    expect(profile.schoolYear, 'y1');
  });

  test('the year a parent chooses reaches the other device', () async {
    await phone.link(childId);
    expect(await phone.sync(), isNull);
    expect(server.children[childId]!['schoolYear'], 'y1');

    await phone.app.saveProfile(phone.data.profile!.copyWith(schoolYear: 'y2'));
    expect(await phone.sync(), isNull);
    expect(server.children[childId]!['schoolYear'], 'y2');
    expect(await tablet.sync(), isNull);
    expect(tablet.child(childId).profile!.schoolYear, 'y2');

    // Back to Year 1: the change is sent although Year 1 is the default.
    await tablet.app.selectChild(childId);
    await tablet.app.saveProfile(
      tablet.data.profile!.copyWith(schoolYear: 'y1'),
    );
    expect(await tablet.sync(), isNull);
    expect(server.children[childId]!['schoolYear'], 'y1');
    expect(await phone.sync(), isNull);
    expect(phone.data.profile!.schoolYear, 'y1');
  });

  test('a later year keeps its own progress next to Year 1', () async {
    await phone.app.recordAttempt(attempt('y2-run'), subject: 'y2.science');
    await phone.app.saveJourney(
      'y2_unit_01',
      resume(2, 'y2_unit_01.step.003'),
      subject: 'y2.science',
    );
    await phone.link(childId);
    expect(await phone.sync(), isNull);
    expect(
      server.attempts.values
          .map((a) => (a['data'] as Map<String, dynamic>)['curriculum'])
          .toSet(),
      {'y1.science', 'y2.science'},
    );

    expect(await tablet.sync(), isNull);
    final child = tablet.child(childId);
    expect(child.attempts.single.attemptId, 'science-run');
    final later = child.progressForSubject('y2.science');
    expect(later.attempts.single.attemptId, 'y2-run');
    expect(later.journeys['y2_unit_01']!['index'], 2);
    expect(child.progressForSubject('maths').attempts, isEmpty);
  });
}
