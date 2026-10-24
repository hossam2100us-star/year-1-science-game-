import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/curriculum.dart';
import '../content/school_years.dart';
import '../core/providers.dart';
import '../core/widgets.dart';
import '../l10n/parent_strings.dart';
import 'parent_section.dart';
import 'unit_report.dart';

/// The child's school year, chosen by the parent (ADR-0021). With one year
/// in the app it is only shown; the choice appears when there are more.
class SchoolYearSetting extends ConsumerWidget {
  const SchoolYearSetting({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = parentStrings(arabic);
    final profile = ref.watch(appProvider).profile;
    if (profile == null) return const SizedBox.shrink();
    final years = ref.watch(schoolYearsProvider);
    final current = years.forChild(profile.schoolYear);
    String name(SchoolYear y) => arabic ? y.arabic : y.title;
    return Column(
      key: const ValueKey('school-year-setting'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.parentAreaSchoolYear),
        const SizedBox(height: 8),
        if (!years.several)
          Text(l.parentAreaSchoolYearOnlyOne(name(current)))
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final year in years.years)
                OutlinedButton.icon(
                  key: ValueKey('school-year-${year.id}'),
                  onPressed: () async {
                    if (year.id == profile.schoolYear) return;
                    try {
                      await ref
                          .read(appProvider.notifier)
                          .saveProfile(profile.copyWith(schoolYear: year.id));
                    } catch (error, stack) {
                      if (context.mounted) {
                        showSaveError(context, error, stack);
                      }
                    }
                  },
                  icon: Icon(
                    year.id == current.id
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                  ),
                  label: Text(name(year)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l.parentAreaSchoolYearNote),
        ],
      ],
    );
  }
}

/// The child's results, by school year (their own first, then the earlier
/// ones they can review) and subject.
class ResultsByYear extends ConsumerWidget {
  const ResultsByYear({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appProvider).profile;
    if (profile == null) return const SizedBox.shrink();
    final years = ref.watch(schoolYearsProvider);
    final current = years.forChild(profile.schoolYear);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final year in [current, ...years.before(current).reversed]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              arabic ? year.arabic : year.title,
              key: ValueKey('results-${year.id}'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          for (final subject in year.subjects)
            _SubjectResults(subject: subject, arabic: arabic),
        ],
      ],
    );
  }
}

/// How to use each subject of the child's year after Science (whose guide
/// the parent area shows first): Maths, English.
class SubjectGuides extends ConsumerWidget {
  const SubjectGuides({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = parentStrings(arabic);
    final profile = ref.watch(appProvider).profile;
    final year = ref
        .watch(schoolYearsProvider)
        .forChild(profile?.schoolYear ?? 'y1');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final subject in year.subjects)
          if (subject.curriculum != currentCurriculum)
            ref
                .watch(subjectCatalogProvider(subject))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(subjectCatalogProvider(subject)),
                    child: Text(
                      subject.curriculum == mathsCurriculum
                          ? l.parentAreaMathsGuideRetry
                          : l.parentAreaGuideRetry,
                    ),
                  ),
                  data: (catalogue) => ParentSection(
                    key: ValueKey('guide-${subject.curriculum}'),
                    title: arabic ? catalogue.arabic : catalogue.title,
                    children: [
                      for (final rule in catalogue.parentRules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(rule[arabic ? 'ar' : 'en'] as String),
                        ),
                    ],
                  ),
                ),
      ],
    );
  }
}

class _SubjectResults extends ConsumerWidget {
  const _SubjectResults({required this.subject, required this.arabic});
  final YearSubject subject;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = parentStrings(arabic);
    if (subject.curriculum == currentCurriculum) {
      return ParentSection(
        title: l.parentAreaUnitAssessment,
        children: [
          Text(l.parentAreaStarsRewardEffortAndCompletion),
          const SizedBox(height: 12),
          for (final level in ref.read(catalogProvider).levels)
            UnitReport(level: level, arabic: arabic),
        ],
      );
    }
    return ref
        .watch(subjectCatalogProvider(subject))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => OutlinedButton(
            onPressed: () => ref.invalidate(subjectCatalogProvider(subject)),
            child: Text(
              subject.curriculum == mathsCurriculum
                  ? l.parentAreaMathsResultsRetry
                  : l.parentAreaResultsRetry,
            ),
          ),
          data: (catalogue) => ParentSection(
            title: arabic ? catalogue.arabic : catalogue.title,
            children: [
              Text(l.parentAreaStarsRewardEffortAndCompletion),
              const SizedBox(height: 12),
              for (final level in catalogue.levels)
                UnitReport(
                  level: level,
                  arabic: arabic,
                  subject: catalogue.progressKey,
                ),
            ],
          ),
        );
  }
}
