import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:science_adventure/content/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Bundled map contains all nine units and four quizzes with unique IDs',
    () async {
      final catalog = await Catalog.load();
      expect(catalog.islands.length, 4);
      final levels = catalog.levels.toList();
      expect(levels.map((l) => l.id).toSet().length, 13);
      expect(levels.where((l) => !l.quiz).length, 9);
      expect(levels.where((l) => l.quiz).length, 4);
      expect(catalog.parentRules.every((r) => r['sourcePage'] == 2), isTrue);
    },
  );
  test(
    'Local celebration animation loads and lasts less than 1.5 seconds',
    () async {
      final animation = await AssetLottie('assets/animations/celebrate.json')
          .load();
      expect(animation.duration.inMilliseconds, lessThan(1500));
    },
  );
}
