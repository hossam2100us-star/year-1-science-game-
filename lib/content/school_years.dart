import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'catalog.dart';
import 'curriculum.dart';

/// One subject of a school year (`assets/content/years.json`, ADR-0021).
@immutable
class YearSubject {
  const YearSubject({required this.curriculum, required this.catalogAsset});
  final String curriculum;

  /// The subject's islands and units (`assets/content/...catalog.json`).
  final String catalogAsset;

  /// `science`, `maths` or `english`: how its lessons and pictures look.
  String get kind => subjectKindOf(curriculum);

  /// Where its progress is kept in the app's data.
  String get progressKey => progressKeyOf(curriculum);

  @override
  bool operator ==(Object other) =>
      other is YearSubject &&
      other.curriculum == curriculum &&
      other.catalogAsset == catalogAsset;

  @override
  int get hashCode => Object.hash(curriculum, catalogAsset);
}

@immutable
class SchoolYear {
  const SchoolYear({
    required this.id,
    required this.title,
    required this.arabic,
    required this.subjects,
  });
  final String id, title, arabic;
  final List<YearSubject> subjects;

  /// 1 for `y1`.
  int get number => int.parse(id.substring(1));

  /// "Year 1 • سنة أولى" on the child's screens.
  String get bilingual => '$title • $arabic';
}

/// The school years this app has, in order. A year appears in the app only
/// when it is listed here with at least one subject.
@immutable
class SchoolYears {
  const SchoolYears(this.years);
  final List<SchoolYear> years;

  /// Year 1 as `years.json` lists it; used until the file is read and if it
  /// cannot be (tests, a damaged install). A test keeps the two the same.
  static const builtIn = SchoolYears([
    SchoolYear(
      id: 'y1',
      title: 'Year 1',
      arabic: 'سنة أولى',
      subjects: [
        YearSubject(
          curriculum: currentCurriculum,
          catalogAsset: 'assets/content/catalog.json',
        ),
        YearSubject(
          curriculum: mathsCurriculum,
          catalogAsset: 'assets/content/maths_catalog.json',
        ),
        YearSubject(
          curriculum: englishCurriculum,
          catalogAsset: 'assets/content/english_catalog.json',
        ),
      ],
    ),
  ]);

  factory SchoolYears.fromJson(Map<String, dynamic> json) {
    final years = <SchoolYear>[];
    for (final raw in json['years'] as List) {
      final y = Map<String, dynamic>.from(raw as Map);
      final id = y['id'] as String;
      if (!schoolYearPattern.hasMatch(id)) {
        throw FormatException('Invalid school year ID', id);
      }
      final subjects = [
        for (final rawSubject in y['subjects'] as List)
          () {
            final s = Map<String, dynamic>.from(rawSubject as Map);
            final curriculum = s['curriculum'] as String;
            if (!curriculumPattern.hasMatch(curriculum) ||
                schoolYearOf(curriculum) != id) {
              throw FormatException('Invalid curriculum for $id', curriculum);
            }
            return YearSubject(
              curriculum: curriculum,
              catalogAsset: s['catalog'] as String,
            );
          }(),
      ];
      if (subjects.isEmpty) throw FormatException('No subjects in $id');
      if (subjects.map((s) => s.curriculum).toSet().length != subjects.length) {
        throw FormatException('A subject is listed twice in $id');
      }
      years.add(
        SchoolYear(
          id: id,
          title: y['title'] as String,
          arabic: y['ar'] as String,
          subjects: subjects,
        ),
      );
    }
    if (years.isEmpty) throw const FormatException('No school years');
    if (years.map((y) => y.id).toSet().length != years.length) {
      throw const FormatException('A school year is listed twice');
    }
    years.sort((a, b) => a.number.compareTo(b.number));
    return SchoolYears(years);
  }

  static Future<SchoolYears> load() async => SchoolYears.fromJson(
    jsonDecode(await rootBundle.loadString('assets/content/years.json'))
        as Map<String, dynamic>,
  );

  /// More than one year: the parent can choose, and the child can look back.
  bool get several => years.length > 1;

  SchoolYear? byId(String id) {
    for (final y in years) {
      if (y.id == id) return y;
    }
    return null;
  }

  /// The year a child plays: their own, or (when another device with a
  /// newer app set a year this one does not have) the highest earlier one,
  /// else the first.
  SchoolYear forChild(String yearId) {
    final exact = byId(yearId);
    if (exact != null) return exact;
    final number = schoolYearPattern.hasMatch(yearId)
        ? int.parse(yearId.substring(1))
        : 0;
    SchoolYear? best;
    for (final y in years) {
      if (y.number <= number) best = y;
    }
    return best ?? years.first;
  }

  /// The years before [year], for review (owner decision, 23 October 2026).
  List<SchoolYear> before(SchoolYear year) => [
    for (final y in years)
      if (y.number < year.number) y,
  ];
}

/// Replaced at start-up with `years.json` (see `main.dart`).
final schoolYearsProvider = Provider<SchoolYears>((ref) => SchoolYears.builtIn);

/// One subject's islands and units. Year 1 keeps the catalogs the app
/// already loads; later years read theirs from the asset named in
/// `years.json`.
final subjectCatalogProvider = FutureProvider.family<Catalog, YearSubject>((
  ref,
  subject,
) async {
  switch (subject.curriculum) {
    case currentCurriculum:
      return ref.watch(catalogProvider);
    case mathsCurriculum:
      return ref.watch(mathsCatalogProvider.future);
  }
  final catalog = Catalog.fromJson(
    jsonDecode(await rootBundle.loadString(subject.catalogAsset))
        as Map<String, dynamic>,
  );
  if (catalog.curriculum != subject.curriculum) {
    throw FormatException(
      '${subject.catalogAsset} is not ${subject.curriculum}',
    );
  }
  return catalog;
});
