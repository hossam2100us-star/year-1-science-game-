import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/repositories.dart';
import 'package:science_adventure/domain/canonical_json.dart';

UnitAttempt evidence(String id, DecisionOutcome outcome) => UnitAttempt(
  unitId: 'unit_01',
  completedAt: DateTime(2026, 10, 11),
  objectives: {'counting': outcome},
  completed: true,
  effortStars: 3,
  attemptId: id,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'subjects sharing a unit ID retain independent evidence and resumes',
    () {
      final data =
          AppData(
            profile: const ChildProfile(name: 'Nour'),
            attempts: [evidence('science-run', DecisionOutcome.firstTry)],
            journeys: const {
              'unit_01': {'index': 7},
            },
            otherSubjects: const {
              'history': {'saved': true},
            },
          ).withSubjectProgress(
            'maths',
            attempts: [evidence('maths-run', DecisionOutcome.afterHint)],
            journeys: const {
              'unit_01': {'index': 2},
            },
          );
      final restored = AppData.fromJson(data.toJson());
      expect(restored.latest('unit_01')!.attemptId, 'science-run');
      expect(restored.journeys['unit_01']!['index'], 7);
      final maths = restored.progressForSubject('maths');
      expect(maths.latest('unit_01')!.attemptId, 'maths-run');
      expect(maths.journeys['unit_01']!['index'], 2);
      expect(maths.profile!.name, 'Nour');
      final reset = restored.resetProgress();
      expect(reset.attempts, isEmpty);
      expect(reset.progressForSubject('maths').attempts, isEmpty);
      expect(reset.otherSubjects['history'], {'saved': true});
    },
  );

  test(
    'concurrent saves and completion stay scoped to the selected subject',
    () async {
      final store = MemoryProgressStore(
        const AppData(profile: ChildProfile(name: 'Nour')),
      );
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final app = container.read(appProvider.notifier);
      await Future.wait([
        app.recordAttempt(evidence('science', DecisionOutcome.firstTry)),
        app.recordAttempt(
          evidence('maths', DecisionOutcome.afterHint),
          subject: 'maths',
        ),
        app.saveJourney('unit_01', {
          'version': 1,
          'attemptId': 'maths',
          'index': 0,
          'responses': <String, dynamic>{},
          'current': <String, dynamic>{},
        }, subject: 'maths'),
      ]);
      await app.completeJourney(
        evidence('maths', DecisionOutcome.afterHint),
        subject: 'maths',
      );
      expect(store.data.attempts.single.attemptId, 'science');
      final maths = store.data.progressForSubject('maths');
      expect(maths.attempts.single.attemptId, 'maths');
      expect(maths.journeys, isEmpty);
      await app.addChild(const ChildProfile(name: 'Adam'));
      expect(store.data.progressForSubject('maths').attempts, isEmpty);
      final nour = AppData.fromJson(store.data.savedChildren.values.single);
      expect(
        nour.progressForSubject('maths').attempts.single.attemptId,
        'maths',
      );
    },
  );

  group('SQLite persistence', () {
    late AppDatabase db;
    late DriftProgressStore store;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = await DriftProgressStore.open(db);
    });
    tearDown(() => db.close());

    test(
      'Maths uses existing curriculum rows and preserves Science row IDs',
      () async {
        final data =
            AppData(
              activeChildId: Ids.uuidV7(),
              profile: const ChildProfile(name: 'Nour'),
              attempts: [evidence('science', DecisionOutcome.firstTry)],
              journeys: const {
                'unit_01': {'version': 1, 'index': 7},
              },
              otherSubjects: const {
                'maths': {'custom': 'preserve'},
              },
            ).withSubjectProgress(
              'maths',
              attempts: [evidence('maths', DecisionOutcome.afterHint)],
              journeys: const {
                'unit_01': {'version': 1, 'index': 2},
              },
            );
        await store.write(data);
        final before = await db.select(db.unitAttempts).get();
        expect(before.map((a) => a.curriculum).toSet(), {
          'y1.science',
          'y1.maths',
        });
        final reopened = await DriftProgressStore.open(db);
        expect(
          canonicalJson(reopened.read().toJson()),
          canonicalJson(data.toJson()),
        );
        await reopened.write(
          reopened.read().withSubjectProgress(
            'maths',
            journeys: const {
              'unit_01': {'version': 1, 'index': 3},
            },
          ),
        );
        expect(
          (await db.select(db.unitAttempts).get()).map((a) => a.id),
          before.map((a) => a.id),
        );
        final journeys = await db.select(db.journeys).get();
        expect(
          journeys.firstWhere((j) => j.curriculum == 'y1.science').json,
          '{"version":1,"index":7}',
        );
        await reopened.write(reopened.read().resetProgress());
        expect(await db.select(db.unitAttempts).get(), isEmpty);
        expect(await db.select(db.journeys).get(), isEmpty);
      },
    );

    test(
      'an existing opaque Maths save is normalized without losing extras',
      () async {
        await store.write(
          AppData(
            activeChildId: Ids.uuidV7(),
            profile: const ChildProfile(name: 'Nour'),
          ),
        );
        final record = {
          'attempts': [
            evidence('old-maths', DecisionOutcome.afterHint).toJson(),
          ],
          'journeys': {
            'unit_01': {'version': 1, 'index': 2},
          },
          'custom': true,
        };
        await ProgressRepository(db)
            .putSubject(store.read().activeChildId, 'maths', record);
        final reopened = await DriftProgressStore.open(db);
        expect(reopened.read().otherSubjects['maths'], record);
        await reopened.write(reopened.read());
        expect(
          (await db.select(db.unitAttempts).get()).single.curriculum,
          'y1.maths',
        );
        final again = await DriftProgressStore.open(db);
        expect(again.read().otherSubjects['maths'], record);
      },
    );
  });
}
