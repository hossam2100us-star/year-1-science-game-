import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/curriculum.dart';
import 'package:science_adventure/content/school_years.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/world/subject_hub.dart';
import 'package:science_adventure/parent/parent_area.dart';

import 'setup_screen_test.dart' as helpers;

/// Year 1 as the app has it, and a Year 2 with the same two subjects.
final twoYears = SchoolYears([
  SchoolYears.builtIn.years.single,
  const SchoolYear(
    id: 'y2',
    title: 'Year 2',
    arabic: 'سنة تانية',
    subjects: [
      YearSubject(
        curriculum: 'y2.science',
        catalogAsset: 'assets/content/y2/science_catalog.json',
      ),
      YearSubject(
        curriculum: 'y2.maths',
        catalogAsset: 'assets/content/y2/maths_catalog.json',
      ),
    ],
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the list of school years', () {
    test(
      'years.json lists Year 1 exactly as the app has it built in',
      () async {
        final years = await SchoolYears.load();
        expect(years.years, hasLength(SchoolYears.builtIn.years.length));
        for (var i = 0; i < years.years.length; i++) {
          final file = years.years[i], builtIn = SchoolYears.builtIn.years[i];
          expect(file.id, builtIn.id);
          expect(file.title, builtIn.title);
          expect(file.arabic, builtIn.arabic);
          expect(file.subjects, builtIn.subjects);
        }
        expect(years.years.single.bilingual, 'Year 1 • سنة أولى');
      },
    );

    test('every listed catalog exists and belongs to its curriculum', () async {
      for (final year in (await SchoolYears.load()).years) {
        for (final subject in year.subjects) {
          final catalog = Catalog.fromJson(
            jsonDecode(await rootBundle.loadString(subject.catalogAsset))
                as Map<String, dynamic>,
          );
          expect(catalog.curriculum, subject.curriculum);
          expect(catalog.subject, subject.kind);
          expect(catalog.levels, isNotEmpty);
        }
      }
    });

    test('a broken list is refused, not half read', () {
      Map<String, dynamic> list(List<Map<String, dynamic>> years) => {
        'years': years,
      };
      Map<String, dynamic> year(String id, List<String> curricula) => {
        'id': id,
        'title': id,
        'ar': id,
        'subjects': [
          for (final c in curricula) {'curriculum': c, 'catalog': '$c.json'},
        ],
      };
      for (final bad in [
        list([]),
        list([
          year('Y1', ['y1.science']),
        ]),
        list([
          year('y2', ['y1.science']),
        ]),
        list([
          year('y1', ['y1.music']),
        ]),
        list([year('y1', [])]),
        list([
          year('y1', ['y1.science', 'y1.science']),
        ]),
        list([
          year('y1', ['y1.science']),
          year('y1', ['y1.maths']),
        ]),
      ]) {
        expect(
          () => SchoolYears.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
      final sorted = SchoolYears.fromJson(
        list([
          year('y3', ['y3.maths']),
          year('y1', ['y1.science']),
        ]),
      );
      expect([for (final y in sorted.years) y.id], ['y1', 'y3']);
    });

    test('a child plays their own year, or the nearest one this app has', () {
      final years = SchoolYears.fromJson({
        'years': [
          for (final id in ['y1', 'y3'])
            {
              'id': id,
              'title': id,
              'ar': id,
              'subjects': [
                {'curriculum': '$id.science', 'catalog': 'x.json'},
              ],
            },
        ],
      });
      expect(years.forChild('y1').id, 'y1');
      expect(years.forChild('y3').id, 'y3');
      expect(years.forChild('y2').id, 'y1');
      expect(years.forChild('y6').id, 'y3');
      expect(years.forChild('nonsense').id, 'y1');
      expect(years.before(years.forChild('y3')).map((y) => y.id), ['y1']);
      expect(years.before(years.forChild('y1')), isEmpty);
      expect(years.several, isTrue);
      expect(SchoolYears.builtIn.several, isFalse);
    });

    test('Year 1 keeps the progress keys it always had', () {
      expect(progressKeyOf('y1.science'), 'science');
      expect(progressKeyOf('y1.maths'), 'maths');
      expect(progressKeyOf('y2.science'), 'y2.science');
      expect(curriculumOfKey('science'), 'y1.science');
      expect(curriculumOfKey('maths'), 'y1.maths');
      expect(curriculumOfKey('y2.maths'), 'y2.maths');
      expect(curriculumOfKey('math'), isNull);
      expect(curriculumOfKey('y2.music'), isNull);
      expect(subjectKindOf('y2.maths'), 'maths');
      expect(subjectKindOf('science'), 'science');
      expect(schoolYearOf('y2.maths'), 'y2');
      expect(schoolYearOf('maths'), 'y1');
    });
  });

  group('the child\'s year', () {
    test('children saved before school years are in Year 1', () {
      const old = {'name': 'Nour', 'gender': 'girl', 'avatar': 1};
      expect(ChildProfile.fromJson(old).schoolYear, 'y1');
      expect(
        ChildProfile.fromJson({...old, 'schoolYear': 'grade two'}).schoolYear,
        'y1',
      );
      final y2 = ChildProfile.fromJson({...old, 'schoolYear': 'y2'});
      expect(y2.schoolYear, 'y2');
      expect(ChildProfile.fromJson(y2.toJson()).schoolYear, 'y2');
      final recoloured = y2.copyWith(palette: PaletteChoice.forest);
      expect(recoloured.schoolYear, 'y2');
      expect(recoloured.name, 'Nour');
      expect(recoloured.avatar, 1);
    });

    test('resetting progress clears every year and subject', () {
      final data = AppData(
        profile: const ChildProfile(name: 'Nour', schoolYear: 'y2'),
        attempts: [helpersAttempt('science')],
        otherSubjects: {
          'maths': {
            'attempts': [helpersAttempt('maths').toJson()],
          },
          'y2.science': {
            'attempts': [helpersAttempt('y2').toJson()],
          },
          'garden-notes': {'kept': true},
        },
      );
      final reset = data.resetProgress();
      expect(reset.attempts, isEmpty);
      expect(reset.otherSubjects.keys, ['garden-notes']);
      expect(reset.profile!.schoolYear, 'y2');
    });
  });

  group('screens', () {
    late Catalog science;
    setUpAll(() async {
      science = await Catalog.load();
      helpers.testCatalog = science;
    });

    Catalog laterYear(String curriculum) {
      final kind = subjectKindOf(curriculum);
      return Catalog.fromJson({
        'subject': kind,
        'curriculum': curriculum,
        'title': kind == 'science' ? 'Science' : 'Maths',
        'ar': kind == 'science' ? 'العلوم' : 'الرياضيات',
        'islands': [
          {
            'title': 'Island',
            'ar': 'جزيرة',
            'color': 'FF3E9B5A',
            'levels': [
              {'id': '${curriculum}_unit_01', 'title': 'Unit', 'ar': 'وحدة'},
            ],
          },
        ],
        'parentRules': <Map<String, dynamic>>[],
      });
    }

    Future<MemoryProgressStore> mount(
      WidgetTester tester,
      Widget child, {
      required SchoolYears years,
      String schoolYear = 'y1',
    }) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryProgressStore(
        AppData(
          profile: ChildProfile(name: 'Nour', schoolYear: schoolYear),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            catalogProvider.overrideWithValue(science),
            narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
            schoolYearsProvider.overrideWithValue(years),
            subjectCatalogProvider.overrideWith((ref, subject) async {
              if (subject.curriculum == currentCurriculum) return science;
              if (subject.curriculum == mathsCurriculum) {
                return Catalog.loadMaths();
              }
              return laterYear(subject.curriculum);
            }),
          ],
          child: MaterialApp(
            theme: adventureTheme(store.data.profile),
            home: child,
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump();
      return store;
    }

    testWidgets('with Year 1 only, the hub names the year and nothing else '
        'changes', (tester) async {
      await mount(
        tester,
        SubjectHub(onParentChanged: (_) {}),
        years: SchoolYears.builtIn,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('school-year'))).data,
        'Year 1 • سنة أولى',
      );
      expect(find.byKey(const ValueKey('subject-science')), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-maths')), findsOneWidget);
      expect(find.byKey(const ValueKey('earlier-years')), findsNothing);
    });

    testWidgets('a Year 2 child plays Year 2 and can go back to Year 1', (
      tester,
    ) async {
      await mount(
        tester,
        SubjectHub(onParentChanged: (_) {}),
        years: twoYears,
        schoolYear: 'y2',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('school-year'))).data,
        'Year 2 • سنة تانية',
      );
      expect(find.byKey(const ValueKey('subject-y2.science')), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-y2.maths')), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-science')), findsNothing);

      await helpers.tapVisible(
        tester,
        find.byKey(const ValueKey('earlier-years')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byType(EarlierYears), findsOneWidget);
      expect(find.text('Year 1 • سنة أولى'), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-science')), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-maths')), findsOneWidget);
    });

    testWidgets('with Year 1 only, the parent sees the year without a choice', (
      tester,
    ) async {
      await mount(tester, const ParentArea(), years: SchoolYears.builtIn);
      await helpers.tapVisible(tester, find.text('الإعدادات'));
      expect(find.byKey(const ValueKey('school-year-setting')), findsOneWidget);
      expect(
        find.text('سنة أولى. السنين الدراسية التانية هتظهر هنا لما تتضاف.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('school-year-y1')), findsNothing);
    });

    testWidgets('choosing Year 2 moves the child and keeps Year 1 results', (
      tester,
    ) async {
      final store = await mount(tester, const ParentArea(), years: twoYears);
      await helpers.tapVisible(tester, find.text('الإعدادات'));
      await helpers.tapVisible(
        tester,
        find.byKey(const ValueKey('school-year-y2')),
      );
      expect(store.data.profile!.schoolYear, 'y2');
      expect(store.data.profile!.name, 'Nour');

      await helpers.tapVisible(tester, find.text('النتائج'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.byKey(const ValueKey('results-y2')), findsOneWidget);
      expect(find.byKey(const ValueKey('results-y1')), findsOneWidget);
      final y2 = tester.getTopLeft(find.byKey(const ValueKey('results-y2')));
      final y1 = tester.getTopLeft(find.byKey(const ValueKey('results-y1')));
      expect(y2.dy, lessThan(y1.dy), reason: 'the child\'s own year first');
    });
  });
}

UnitAttempt helpersAttempt(String id) => UnitAttempt(
  unitId: 'unit_02',
  completedAt: DateTime(2026, 10, 23),
  objectives: const {'o.1': DecisionOutcome.firstTry},
  completed: true,
  effortStars: 3,
  attemptId: id,
);
