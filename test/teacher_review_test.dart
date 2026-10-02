import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
  });
  test('Equivalent rock labels accept swapped legacy answers', () {
    final step = library.lessons['unit_08']!.steps.last;
    final answer = Map<String, dynamic>.from(step.answer!['value']);
    answer['coal_comes_from'] = 'rocks';
    answer['a_geologist_studies'] = 'rock';
    expect(matchesAnswer(step.answer!, answer), isTrue);
    answer['soil_is'] = 'rock';
    expect(matchesAnswer(step.answer!, answer), isFalse);
  });
  testWidgets('Feedback and check controls stay visible on small landscape', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 360);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final lesson = library.lessons['unit_02']!;
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {
          lesson.id: (LessonSession.fresh(lesson)..index = 4).toJson(),
        },
      ),
    );
    await helpers.mount(t, LessonPlayer(lesson: lesson), store, scale: 1.5);
    final check = find.text('Check my discovery');
    expect(t.getRect(check).bottom, lessThanOrEqualTo(360));
  });
}
