import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/catalog.dart';
import '../../content/lesson.dart';
import '../../core/mascot.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../parent/parent_gate.dart';
import '../../parent/parent_area.dart';
import '../biology/lesson_player.dart';
import '../biology/sticker_album.dart';
import 'island_art.dart';
import 'todays_challenge.dart';

class WorldMap extends ConsumerStatefulWidget {
  const WorldMap({
    super.key,
    required this.onParentChanged,
    this.onSubjects,
    this.preview = false,
  });
  final bool preview;
  final ValueChanged<bool> onParentChanged;
  final VoidCallback? onSubjects;
  @override
  ConsumerState<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends ConsumerState<WorldMap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        ref
            .read(narrationProvider)
            .speak(
              'Welcome to our science islands. Tap Biology Island to explore.',
            );
    });
  }

  Future<void> _parents() async {
    await ref.read(narrationProvider).stop();
    if (!mounted || !await parentGate(context) || !mounted) return;
    widget.onParentChanged(true);
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ParentArea()));
    widget.onParentChanged(false);
  }

  void openIsland(int index) {
    ref.read(narrationProvider).stop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IslandScreen(index: index, preview: widget.preview),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider),
        profile = data.profile!,
        catalog = ref.watch(catalogProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFD4ECE9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (widget.onSubjects != null)
                      IconButton(
                        onPressed: widget.onSubjects,
                        tooltip: 'Subjects',
                        icon: const Icon(Icons.apps_rounded),
                      ),
                    ChildAvatar(profile: profile, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile.greeting,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _parents,
                      tooltip: 'Grown-ups',
                      icon: const Icon(Icons.lock_outline_rounded),
                      color: const Color(0xFF245B62),
                    ),
                  ],
                ),
              ),
              const TodaysChallenge(),
              LayoutBuilder(
                builder: (context, box) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(1) >= 1.5;
                  final columns = box.maxWidth >= (largeText ? 1000 : 620)
                      ? 2
                      : 1;
                  final cardWidth =
                      (box.maxWidth - 32 - (columns - 1) * 16) / columns;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < catalog.islands.length; i++)
                          SizedBox(
                            width: cardWidth,
                            child: Material(
                              color: const Color(0xFFFFFAEE),
                              borderRadius: BorderRadius.circular(24),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: ValueKey('island-$i'),
                                onTap: () => openIsland(i),
                                child: Column(
                                  children: [
                                    AspectRatio(
                                      // Match the painting region so the whole
                                      // island remains visible above its label.
                                      aspectRatio:
                                          2 *
                                          islandRegions[i].width /
                                          islandRegions[i].height,
                                      child: IslandIllustration(
                                        key: ValueKey('island-art-$i'),
                                        index: i,
                                      ),
                                    ),
                                    Padding(
                                      key: ValueKey('island-caption-$i'),
                                      padding: const EdgeInsets.all(14),
                                      child: _IslandLabel(
                                        island: catalog.islands[i],
                                        number: i + 1,
                                        unlocked:
                                            widget.preview ||
                                            catalog.islandUnlocked(i, data),
                                        completed: catalog.islands[i].levels
                                            .where(
                                              (l) => data.isAdventureComplete(
                                                l.id,
                                              ),
                                            )
                                            .length,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => openIsland(0),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Let us explore'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StickerAlbum(),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Sticker Album'),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(narrationProvider)
                          .speak('Tap an island. Start with Biology Island.'),
                      tooltip: 'Listen to the map',
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandLabel extends StatelessWidget {
  const _IslandLabel({
    required this.island,
    required this.number,
    required this.unlocked,
    required this.completed,
  });
  final IslandInfo island;
  final int number, completed;
  final bool unlocked;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(island.color),
          shape: BoxShape.circle,
        ),
        child: unlocked
            ? Text(
                '$number',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 25,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_rounded, color: Colors.white, size: 23),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              island.title,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 25,
                color: Color(0xFF234B4C),
              ),
            ),
            Text(
              unlocked
                  ? (completed > 0
                        ? '$completed / ${island.levels.length} adventures'
                        : 'Tap to explore')
                  : 'Not yet',
              style: const TextStyle(fontSize: 22, color: Color(0xFF3D6063)),
            ),
          ],
        ),
      ),
    ],
  );
}

void _comingSoon(BuildContext context, String name) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      content: StoryPanel(
        text: '$name is being prepared. Let us explore the garden for now.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to my island'),
        ),
      ],
    ),
  );
}

class IslandScreen extends ConsumerWidget {
  const IslandScreen({super.key, required this.index, this.preview = false});
  final bool preview;
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider),
        island = catalog.islands[index],
        data = ref.watch(appProvider);
    final color = Color(island.color),
        locked = !preview && !catalog.islandUnlocked(index, data);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'My map',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        island.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(narrationProvider)
                          .speak(
                            'Welcome to ${island.title}. Follow the adventure path.',
                          ),
                      tooltip: 'Listen',
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, box) => SizedBox(
                  height: (box.maxWidth * .34).clamp(210, 380),
                  width: double.infinity,
                  child: IslandIllustration(index: index),
                ),
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: color),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Finish the island before this one to begin. You can look around!',
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: Column(
                    children: [
                      for (var i = 0; i < island.levels.length; i++) ...[
                        if (i > 0)
                          Align(
                            alignment: Alignment(i.isEven ? -.45 : .45, 0),
                            child: SizedBox(
                              height: 25,
                              child: VerticalDivider(
                                color: color.withValues(alpha: .4),
                                thickness: 4,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment(i.isEven ? -.65 : .65, 0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: _LevelStop(
                              level: island.levels[i],
                              number: i + 1,
                              color: color,
                              available: LessonLibrary.availableIds.contains(
                                island.levels[i].id,
                              ),
                              unlocked:
                                  preview ||
                                  catalog.levelUnlocked(index, i, data),
                              complete: data.isAdventureComplete(
                                island.levels[i].id,
                              ),
                              onTap: () {
                                final level = island.levels[i];
                                if (!LessonLibrary.availableIds.contains(
                                  level.id,
                                )) {
                                  _comingSoon(context, level.title);
                                  return;
                                }
                                if (!preview &&
                                    !catalog.levelUnlocked(index, i, data)) {
                                  ref
                                      .read(narrationProvider)
                                      .speak(
                                        'Finish the adventure before this one first. You can do it!',
                                      );
                                  return;
                                }
                                ref.read(narrationProvider).stop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => LessonRoute(id: level.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelStop extends StatelessWidget {
  const _LevelStop({
    required this.level,
    required this.number,
    required this.color,
    required this.available,
    required this.unlocked,
    required this.complete,
    required this.onTap,
  });
  final LevelInfo level;
  final int number;
  final Color color;
  final bool available, unlocked, complete;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    child: InkWell(
      key: ValueKey('level-${level.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .13),
              ),
              child: Icon(
                complete
                    ? Icons.star_rounded
                    : !unlocked
                    ? Icons.lock_rounded
                    : level.quiz
                    ? Icons.emoji_events_rounded
                    : Icons.play_arrow_rounded,
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    !available
                        ? 'Coming soon'
                        : complete
                        ? 'Play again'
                        : unlocked
                        ? 'Let us explore'
                        : 'Not yet',
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$number',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 28,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
