import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/storage.dart';
import '../biology/lesson_player.dart';

/// A web review starts at the revised scene without replacing the child's journey.
class PlantLabPreview extends ConsumerStatefulWidget {
  const PlantLabPreview({super.key});
  @override
  ConsumerState<PlantLabPreview> createState() => _PlantLabPreviewState();
}

class _PlantLabPreviewState extends ConsumerState<PlantLabPreview> {
  late final MemoryProgressStore store;
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            key: const ValueKey('plant-review-banner'),
            width: double.infinity,
            color: const Color(0xFFD9F2DF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              'معاينة النبتة الجديدة • تقدمك الأساسي محفوظ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
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
