import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../games/science_art.dart';
import '../maths/maths_visual.dart';

class StickerAlbum extends ConsumerWidget {
  const StickerAlbum({super.key, this.subject = 'science'});
  final String subject;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider).progressForSubject(subject);
    return Scaffold(
      body: AdventurePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('My map'),
              ),
            ),
            const SizedBox(height: 16),
            StoryPanel(
              text: subject == 'science'
                  ? 'My science words! Finish a unit to earn its stickers. Tap an earned sticker to listen.'
                  : 'My maths words! Finish a unit to earn its stickers. Tap an earned sticker to listen.',
            ),
            const SizedBox(height: 16),
            ref
                .watch(lessonLibraryProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const Text(
                    'The word album could not open. Please try again.',
                  ),
                  data: (library) {
                    final words = <String, Map<String, dynamic>>{};
                    final earned = <String>{};
                    for (final lesson in library.lessons.values.where(
                      (lesson) => lesson.subject == subject,
                    )) {
                      for (final sticker in lesson.stickers) {
                        words[sticker['id']] = sticker;
                        if (data.isComplete(lesson.id)) {
                          earned.add(sticker['id']);
                        }
                      }
                    }
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final entry in words.entries)
                          SizedBox(
                            width: 210,
                            child: OutlinedButton(
                              onPressed: () {
                                if (!earned.contains(entry.key)) {
                                  ref
                                      .read(narrationProvider)
                                      .speak(
                                        'Not yet. Finish the unit to earn this sticker.',
                                      );
                                  return;
                                }
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    scrollable: true,
                                    content: StoryPanel(
                                      text:
                                          '${entry.value['word']}. ${entry.value['meaning']}',
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Back to my words'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  if (earned.contains(entry.key))
                                    if (subject == 'science')
                                      SciencePicture(art: entry.key)
                                    // Each Maths word has its own picture
                                    // (teacher review 5: all showed one icon).
                                    else if (entry.value['picture']
                                        case final Map<String, dynamic> picture)
                                      MathsVisual(
                                        data: {...picture, 'height': 64},
                                      )
                                    else
                                      const Icon(
                                        Icons.calculate_rounded,
                                        size: 64,
                                      )
                                  else
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 64,
                                    ),
                                  Text(
                                    earned.contains(entry.key)
                                        ? entry.value['word']
                                        : 'Not yet',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
