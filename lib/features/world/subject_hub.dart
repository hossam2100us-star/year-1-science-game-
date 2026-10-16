import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/catalog.dart';
import '../../core/providers.dart';
import '../../core/mascot.dart';
import '../../core/widgets.dart';
import '../../parent/parent_gate.dart';
import '../../parent/parent_area.dart';
import 'world_map.dart';
import '../onboarding/child_chooser.dart';
import '../maths/maths_art.dart';

/// Only published subjects appear here; adding one must not unlock empty content.
class SubjectHub extends ConsumerWidget {
  const SubjectHub({super.key, required this.onParentChanged});
  final ValueChanged<bool> onParentChanged;

  Future<void> _openWorld(
    BuildContext context,
    WidgetRef ref, {
    Catalog? catalogue,
  }) async {
    await ref.read(narrationProvider).stop();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (page) => WorldMap(
          catalogue: catalogue,
          onParentChanged: onParentChanged,
          onSubjects: () {
            ref.read(narrationProvider).stop();
            Navigator.of(page).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appProvider).profile;
    if (profile == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: AdventurePage(
        maxWidth: 950,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChildAvatar(profile: profile, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: FittedTitle(
                    profile.greeting,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Switch child',
                  icon: const Icon(Icons.people_alt_rounded),
                  onPressed: () async {
                    await ref.read(narrationProvider).stop();
                    if (!context.mounted) return;
                    onParentChanged(true);
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (page) => ChildChooser(
                            onParentChanged: (_) {},
                            onSelected: () => Navigator.of(page).pop(),
                          ),
                        ),
                      );
                    } finally {
                      onParentChanged(false);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Grown-ups',
                  icon: const Icon(Icons.lock_outline_rounded),
                  onPressed: () async {
                    await ref.read(narrationProvider).stop();
                    if (!context.mounted ||
                        !await parentGate(
                          context,
                          gender: ref.read(appProvider).profile?.gender,
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    onParentChanged(true);
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ParentArea(),
                        ),
                      );
                    } finally {
                      onParentChanged(false);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Choose your adventure',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, box) {
                final cardWidth = box.maxWidth >= 700
                    ? (box.maxWidth - 24) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _SubjectCard(
                        subject: 'science',
                        title: 'Science',
                        color: const Color(0xFFE0F0E7),
                        onTap: () => _openWorld(context, ref),
                        illustration: Image.asset(
                          'assets/images/islands-v2.webp',
                          height: 230,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: ref
                          .watch(mathsCatalogProvider)
                          .when(
                            data: (catalogue) => _SubjectCard(
                              subject: catalogue.subject,
                              title: catalogue.title,
                              color: const Color(0xFFE7EDF7),
                              onTap: () => _openWorld(
                                context,
                                ref,
                                catalogue: catalogue,
                              ),
                              illustration: const SizedBox(
                                height: 230,
                                width: 460,
                                child: MathsIslandArt(),
                              ),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Center(
                              child: FilledButton(
                                onPressed: () =>
                                    ref.invalidate(mathsCatalogProvider),
                                child: const Text('Try opening Maths again'),
                              ),
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

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.title,
    required this.color,
    required this.illustration,
    required this.onTap,
  });
  final String subject, title;
  final Color color;
  final Widget illustration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          key: ValueKey('subject-$subject'),
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(aspectRatio: 2, child: illustration),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Icon(Icons.arrow_forward_rounded, size: 36),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
