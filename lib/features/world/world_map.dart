import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/mascot.dart';
import 'island_art.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../parent/parent_gate.dart';
import '../../parent/parent_area.dart';
import '../../content/catalog.dart';

class WorldMap extends ConsumerWidget {
  const WorldMap({super.key, required this.onParentChanged});
  final ValueChanged<bool> onParentChanged;
  Future<void> _parents(BuildContext context, WidgetRef ref) async {
    await ref.read(narrationProvider).stop();
    if (!context.mounted || !await parentGate(context) || !context.mounted)
      return;
    onParentChanged(true);
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ParentArea()));
    onParentChanged(false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final profile = data.profile!;
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      body: AdventurePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChildAvatar(profile: profile),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        profile.greeting,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _parents(context, ref),
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: const Text('Grown-ups • الأهل'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, box) {
                final story = StoryPanel(
                  text:
                      '${profile.greeting} I am ${profile.guideName}, your science friend. Welcome to our four islands! Tap an island to look around.',
                );
                return box.maxWidth > 650
                    ? Row(
                        children: [
                          ScientistOwl(
                            gender: profile.gender,
                            size: 155,
                            mood: OwlMood.happy,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: story),
                        ],
                      )
                    : Column(
                        children: [
                          ScientistOwl(gender: profile.gender, size: 130),
                          story,
                        ],
                      );
              },
            ),
            const SizedBox(height: 26),
            Text(
              'Our discovery map',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your adventures are being built. Today, meet your guide and explore the map.',
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, box) {
                final columns =
                    box.maxWidth > 1050 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.4
                    ? 4
                    : box.maxWidth > 750
                    ? 2
                    : 1;
                final width = (box.maxWidth - 24 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    for (var i = 0; i < catalog.islands.length; i++)
                      SizedBox(
                        width: width,
                        child: _IslandCard(
                          island: catalog.islands[i],
                          index: i,
                          unlocked: catalog.islandUnlocked(i, data),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => IslandScreen(index: i),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _comingSoon(context, 'Sticker Album'),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Sticker Album'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _comingSoon(context, 'Science Skills'),
                  icon: const Icon(Icons.bar_chart_rounded),
                  label: const Text('Science Skills'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _comingSoon(BuildContext context, String name) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      content: StoryPanel(
        text:
            '$name is coming in a later adventure. We can look around the map for now.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to my map'),
        ),
      ],
    ),
  );
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.island,
    required this.index,
    required this.unlocked,
    required this.onTap,
  });
  final IslandInfo island;
  final int index;
  final bool unlocked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = Color(island.color);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 145,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: IslandArt(index, color)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        unlocked ? Icons.explore_rounded : Icons.lock_rounded,
                        color: color,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        '0${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 28,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                island.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? 'Start here • Map preview'
                    : 'Later on our journey • Preview',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < island.levels.length; i++)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        island.levels[i].quiz
                            ? Icons.star_outline_rounded
                            : Icons.circle_outlined,
                        size: 24,
                        color: color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IslandScreen extends ConsumerWidget {
  const IslandScreen({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final island = catalog.islands[index];
    final data = ref.watch(appProvider);
    return Scaffold(
      body: AdventurePage(
        maxWidth: 900,
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
            const SizedBox(height: 20),
            StoryPanel(
              text:
                  'Welcome to ${island.title}. ${island.levels.map((l) => l.title).join('. ')}. These games are coming soon.',
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < island.levels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      scrollable: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!MediaQuery.disableAnimationsOf(context))
                            Lottie.asset(
                              'assets/animations/celebrate.json',
                              width: 100,
                              height: 80,
                              repeat: false,
                            ),
                          ScientistOwl(
                            gender: data.profile!.gender,
                            mood: OwlMood.thinking,
                            size: 110,
                          ),
                          StoryPanel(
                            text:
                                '${island.levels[i].title}. This adventure is being built. You can play it in a future update.',
                          ),
                        ],
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Keep looking'),
                        ),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        island.levels[i].quiz
                            ? Icons.star_outline_rounded
                            : catalog.levelUnlocked(index, i, data)
                            ? Icons.explore_rounded
                            : Icons.lock_outline_rounded,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${i + 1}. ${island.levels[i].title}\nComing soon',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Listen',
                        onPressed: () => ref
                            .read(narrationProvider)
                            .speak(island.levels[i].title),
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
