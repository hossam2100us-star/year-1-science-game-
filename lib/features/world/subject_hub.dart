import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/catalog.dart';
import '../../content/curriculum.dart';
import '../../content/school_years.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appProvider).profile;
    if (profile == null) return const SizedBox.shrink();
    final years = ref.watch(schoolYearsProvider);
    final year = years.forChild(profile.schoolYear);
    final earlier = years.before(year);
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
            const SizedBox(height: 8),
            Text(
              year.bilingual,
              key: const ValueKey('school-year'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            YearSubjects(year: year, onParentChanged: onParentChanged),
            if (earlier.isNotEmpty) ...[
              const SizedBox(height: 28),
              Center(
                child: OutlinedButton.icon(
                  key: const ValueKey('earlier-years'),
                  icon: const Icon(Icons.history_edu_rounded),
                  label: const Text('Earlier years • السنين اللي فاتت'),
                  onPressed: () async {
                    await ref.read(narrationProvider).stop();
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EarlierYears(
                          years: earlier,
                          onParentChanged: onParentChanged,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The subjects of one school year, as cards that open their islands.
class YearSubjects extends ConsumerWidget {
  const YearSubjects({
    super.key,
    required this.year,
    required this.onParentChanged,
  });
  final SchoolYear year;
  final ValueChanged<bool> onParentChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, box) {
      final cardWidth = box.maxWidth >= 700
          ? (box.maxWidth - 24) / 2
          : box.maxWidth;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (final subject in year.subjects)
            SizedBox(
              width: cardWidth,
              child: _SubjectEntry(
                subject: subject,
                onParentChanged: onParentChanged,
              ),
            ),
        ],
      );
    },
  );
}

class _SubjectEntry extends ConsumerWidget {
  const _SubjectEntry({required this.subject, required this.onParentChanged});
  final YearSubject subject;
  final ValueChanged<bool> onParentChanged;

  Future<void> _openWorld(
    BuildContext context,
    WidgetRef ref,
    Catalog catalogue,
  ) async {
    await ref.read(narrationProvider).stop();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (page) => WorldMap(
          // Year 1 Science is the app's own catalog.
          catalogue: subject.curriculum == currentCurriculum ? null : catalogue,
          onParentChanged: onParentChanged,
          onSubjects: () {
            ref.read(narrationProvider).stop();
            Navigator.of(page).pop();
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Catalog catalogue) {
    final science = subject.kind == 'science';
    return _SubjectCard(
      subject: subject.progressKey,
      title: catalogue.title,
      color: science ? const Color(0xFFE0F0E7) : const Color(0xFFE7EDF7),
      onTap: () => _openWorld(context, ref, catalogue),
      illustration: science
          ? Image.asset(
              'assets/images/islands-v2.webp',
              height: 230,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            )
          : const SizedBox(height: 230, width: 460, child: MathsIslandArt()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subject.curriculum == currentCurriculum) {
      return _card(context, ref, ref.watch(catalogProvider));
    }
    return ref
        .watch(subjectCatalogProvider(subject))
        .when(
          data: (catalogue) => _card(context, ref, catalogue),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(subjectCatalogProvider(subject)),
              child: Text(
                subject.kind == 'science'
                    ? 'Try opening Science again'
                    : 'Try opening Maths again',
              ),
            ),
          ),
        );
  }
}

/// The years before the child's own, to go back and review (owner
/// decision, 23 October 2026). Their progress is kept per year.
class EarlierYears extends ConsumerWidget {
  const EarlierYears({
    super.key,
    required this.years,
    required this.onParentChanged,
  });
  final List<SchoolYear> years;
  final ValueChanged<bool> onParentChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: const Color(0xFFFFF8EC),
    body: AdventurePage(
      maxWidth: 950,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                ref.read(narrationProvider).stop();
                Navigator.of(context).pop();
              },
            ),
          ),
          Text(
            'Earlier years • السنين اللي فاتت',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          for (final year in years.reversed) ...[
            const SizedBox(height: 28),
            Text(
              year.bilingual,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            YearSubjects(year: year, onParentChanged: onParentChanged),
          ],
        ],
      ),
    ),
  );
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
