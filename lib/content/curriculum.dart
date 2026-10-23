/// Curriculum namespace for progress records (AUD-023).
///
/// Unit and quiz IDs (`unit_01`, `quiz_04`) are unique only inside one
/// curriculum. Stored attempts and journeys carry this ID, so adding a
/// second school year or subject later cannot collide with Year 1 science.
const currentCurriculum = 'y1.science';

/// Maths uses the same progress tables with a separate curriculum namespace.
const mathsCurriculum = 'y1.maths';

/// A curriculum ID is `<school year>.<subject kind>`, e.g. `y2.maths`
/// (ADR-0021). The kind decides how lessons look; the ID decides where the
/// progress is kept.
final curriculumPattern = RegExp(r'^y[0-9]{1,2}\.(science|maths)$');

/// A school year ID, e.g. `y1`.
final schoolYearPattern = RegExp(r'^y[0-9]{1,2}$');

/// The subject kind of a curriculum or progress key (`science`, `maths`).
String subjectKindOf(String curriculumOrKey) =>
    curriculumOrKey.substring(curriculumOrKey.indexOf('.') + 1);

/// The school year of a curriculum or progress key (`y1` for the keys Year 1
/// always had).
String schoolYearOf(String curriculumOrKey) {
  final dot = curriculumOrKey.indexOf('.');
  return dot < 0 ? 'y1' : curriculumOrKey.substring(0, dot);
}

/// The key a curriculum's progress is kept under in the app's records.
/// Year 1 keeps the keys it always had (`science` in the main fields,
/// `maths` among the other subjects), so saved progress never moves; every
/// later curriculum uses its own ID.
String progressKeyOf(String curriculum) => switch (curriculum) {
  currentCurriculum => 'science',
  mathsCurriculum => 'maths',
  _ => curriculum,
};

/// The curriculum a progress key belongs to; null for other saved records.
String? curriculumOfKey(String key) => switch (key) {
  'science' => currentCurriculum,
  'maths' => mathsCurriculum,
  _ => curriculumPattern.hasMatch(key) ? key : null,
};
