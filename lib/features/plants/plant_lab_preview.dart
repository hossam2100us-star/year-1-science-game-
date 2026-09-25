import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/storage.dart';
import '../biology/lesson_player.dart';
import '../biology/session.dart';

/// A web review starts at the revised scene without replacing the child's journey.
class PlantLabPreview extends ConsumerStatefulWidget {
  const PlantLabPreview({super.key, this.initialStep = 0});
  final int initialStep;
  @override
  ConsumerState<PlantLabPreview> createState() => _PlantLabPreviewState();
}

class _PlantLabPreviewState extends ConsumerState<PlantLabPreview> {
  late final MemoryProgressStore store;
  bool seeded = false;
  @override
  void initState() {
    super.initState();
    final original = ref.read(appProvider);
    store = MemoryProgressStore(
      AppData(
        profile: original.profile ?? const ChildProfile(name: 'Seif'),
        settings: original.settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialStep > 0 && !seeded) {
      final library = ref.watch(lessonLibraryProvider);
      final loaded = library.asData?.value;
      if (loaded == null) {
        return Scaffold(
          body: Center(
            child: library.hasError
                ? FilledButton(
                    onPressed: () => ref.invalidate(lessonLibraryProvider),
                    child: const Text('Try opening again'),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      }
      final lesson = loaded.lessons['unit_02']!;
      final session = LessonSession.fresh(lesson)
        ..index = widget.initialStep.clamp(0, lesson.steps.length - 1);
      store.data = store.data.copyWith(journeys: {'unit_02': session.toJson()});
      seeded = true;
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              key: const ValueKey('plant-review-banner'),
              width: double.infinity,
              color: const Color(0xFFD9F2DF),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                widget.initialStep == 10
                    ? 'معاينة تجربة الضوء • ١١/٢١ • تقدمك الأساسي محفوظ'
                    : 'معاينة النبتة الجديدة • تقدمك الأساسي محفوظ',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: Color(0xFF174F39),
                ),
              ),
            ),
            Expanded(
              child: ProviderScope(
                overrides: [
                  storeProvider.overrideWithValue(store),
                  appProvider.overrideWith(AppController.new),
                ],
                child: const LessonRoute(id: 'unit_02'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
