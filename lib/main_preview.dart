// Review build only: `flutter build web -t lib/main_preview.dart`.
//
// Adds the `?preview=...` routes used to review single scenes in a browser.
// The production entry point (lib/main.dart) has none of these (AUD-014).
import 'package:flutter/material.dart';

import 'content/lesson.dart';
import 'features/biology/lesson_player.dart';
import 'features/plants/bean_experiment.dart';
import 'features/plants/plant_lab_preview.dart';
import 'features/science/science_review_menu.dart';
import 'main.dart';

Future<void> main() => launchScienceAdventure(
  app: ScienceAdventureApp(
    initialRoute: previewInitialRoute(Uri.base.queryParameters),
    routes: previewRoutes(Uri.base.queryParameters),
  ),
);

const _previewRoutes = {
  'garden-v2': '/garden-preview',
  'alive-three': '/garden-preview',
  'bean-v1': '/bean-preview',
  'plants-v2': '/plants-preview',
  'plants-v3': '/plants-review',
  'light-v1': '/light-review',
  'science-v1': '/science-review',
  'biology-v1': '/biology-review',
};

String previewInitialRoute(Map<String, String> query) =>
    _previewRoutes[query['preview']] ?? '/';

int _step(Map<String, String> query) =>
    (int.tryParse(query['step'] ?? '') ?? 1) - 1;

Map<String, WidgetBuilder> previewRoutes(Map<String, String> query) => {
  '/science-review': (_) => const ScienceReviewMenu(),
  '/biology-review': (_) => PlantLabPreview(
    lessonId: LessonLibrary.availableIds.contains(query['lesson'])
        ? query['lesson']!
        : 'unit_03',
    initialStep: _step(query),
  ),
  '/garden-preview': (_) => const LessonRoute(id: 'unit_01'),
  '/light-review': (_) => const PlantLabPreview(initialStep: 3),
  '/plants-review': (_) =>
      PlantLabPreview(initialStep: _step(query).clamp(0, 13)),
  '/plants-preview': (_) => const LessonRoute(id: 'unit_02'),
  '/bean-preview': (_) => const BeanPreview(),
};
