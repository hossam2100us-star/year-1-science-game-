import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/lesson.dart';
import '../../core/providers.dart';
import 'garden_adventure.dart';
import 'garden_model.dart';

List<GardenContent> aliveScenes(Lesson lesson) => [
  GardenContent(lesson.json['garden']),
  for (final json in lesson.json['aliveScenes'] ?? []) GardenContent(json),
];

class AliveAdventures extends ConsumerStatefulWidget {
  const AliveAdventures({super.key, required this.lesson});
  final Lesson lesson;
  @override
  ConsumerState<AliveAdventures> createState() => _AliveAdventuresState();
}

class _AliveAdventuresState extends ConsumerState<AliveAdventures> {
  List<GardenContent> get scenes => aliveScenes(widget.lesson);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(narrationProvider).speak(scenes.first.text('menu'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            tooltip: 'Listen again',
            onPressed: () => ref
                .read(narrationProvider)
                .speak(
                  '${scenes.first.text('menu')}. ${scenes.map((s) => '${s.text('title')}. ${s.text('difficulty')}').join('. ')}',
                ),
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final columns =
              box.maxWidth >= 1000 &&
                  MediaQuery.textScalerOf(context).scale(1) < 1.5
              ? 3
              : 1;
          final width = (box.maxWidth - 32 - 16 * (columns - 1)) / columns;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 20,
              children: [
                for (final scene in scenes)
                  SizedBox(
                    width: width,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('adventure-${scene.id}'),
                        onTap: () async {
                          await ref.read(narrationProvider).stop();
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GardenAdventure(content: scene),
                            ),
                          );
                          if (mounted)
                            ref
                                .read(narrationProvider)
                                .speak(scene.text('menu'));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 2,
                              child: Image.asset(
                                'assets/images/${scene.asset}',
                                fit: BoxFit.contain,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scene.text('title'),
                                    style: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 28,
                                    ),
                                  ),
                                  Text(
                                    scene.text('difficulty'),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox.shrink(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        scene.completed(
                                              data.journeys[scene.storageKey],
                                            )
                                            ? Icons.replay_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          scene.completed(
                                                data.journeys[scene.storageKey],
                                              )
                                              ? scene.text('replay')
                                              : scene.text('menu'),
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
