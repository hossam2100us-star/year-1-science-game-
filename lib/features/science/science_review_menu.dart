import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../plants/plant_lab_preview.dart';
import 'science_picture.dart';

/// Review-only entry points do not unlock or overwrite the child's journey.
class ScienceReviewMenu extends ConsumerWidget {
  const ScienceReviewMenu({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const previews = {
      'unit_04': ('خصائص المواد', 'Maker’s workshop', 'spoon'),
      'unit_05': ('القوى والحركة', 'Movement playground', 'sailboat'),
      'unit_06': ('الصوت', 'Band room', 'drum'),
      'unit_07': ('الكهرباء والمغناطيس', 'Safe science workshop', 'magnet'),
      'unit_08': ('كوكب الأرض', 'Water world', 'earth'),
      'unit_09': ('الأرض في الفضاء', 'Space explorers', 'astronaut'),
    };
    void open(String id) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlantLabPreview(lessonId: id)),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'باقي مغامرات العلوم',
          textDirection: TextDirection.rtl,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                const Text(
                  'اختار الوحدة اللي تحب تجربها. دي معاينة منفصلة، وتقدم الطفل الأساسي محفوظ.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final e in previews.entries)
                      SizedBox(
                        width: 330,
                        child: Card(
                          color: const Color(0xFFFFFCF3),
                          child: InkWell(
                            key: ValueKey('review-${e.key}'),
                            onTap: () => open(e.key),
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  SciencePicture(e.value.$3, height: 150),
                                  Text(
                                    e.value.$1,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    e.value.$2,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  ref
                                      .watch(lessonLibraryProvider)
                                      .when(
                                        data: (b) => Text(
                                          '${b.lessons[e.key]!.steps.length} نشاط',
                                          textDirection: TextDirection.rtl,
                                        ),
                                        loading: () => const SizedBox(),
                                        error: (_, _) => const SizedBox(),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final e in {
                      'quiz_02': 'تحدي المواد',
                      'quiz_03': 'تحدي الفيزياء',
                      'quiz_04': 'تحدي الأرض والفضاء',
                    }.entries)
                      FilledButton.tonal(
                        onPressed: () => open(e.key),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            e.value,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
