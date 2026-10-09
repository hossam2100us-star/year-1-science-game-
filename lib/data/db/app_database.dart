import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Local relational store (AUD-004, ADR-0005). One row per child, attempt,
/// objective, journey, usage day and subject record, so a save writes only
/// what changed. Sync metadata (`version`, `syncStatus`) and the outbox are
/// present from the start; they stay unused until a parent links an account.

@DataClassName('ChildRow')
class Children extends Table {
  /// UUIDv7.
  TextColumn get id => text()();

  /// The ID the child had in the Hive save (`local-child`, 32 hex, ...).
  TextColumn get legacyId => text().nullable()();

  /// False for the empty profile shown before onboarding finishes.
  BoolColumn get hasProfile => boolean()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get gender => text().withDefault(const Constant('boy'))();
  IntColumn get avatar => integer().withDefault(const Constant(0))();
  TextColumn get palette => text().withDefault(const Constant('automatic'))();
  BoolColumn get pendingPhoto => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (gender IN ('boy', 'girl'))",
    'CHECK (avatar BETWEEN 0 AND 2)',
    "CHECK (palette IN ('automatic', 'ocean', 'berry', 'forest'))",
  ];
}

/// Photos live in their own table so changing a name or a score never
/// rewrites the image bytes.
@DataClassName('ChildPhotoRow')
class ChildPhotos extends Table {
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();
  BlobColumn get bytes => blob()();

  @override
  Set<Column<Object>> get primaryKey => {childId};
}

@DataClassName('ChildSettingsRow')
class ChildSettings extends Table {
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();

  /// The settings object exactly as saved (values are validated by
  /// AppSettings when read).
  TextColumn get json => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {childId};
}

@DataClassName('AttemptRow')
class UnitAttempts extends Table {
  /// UUIDv7.
  TextColumn get id => text()();
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();

  /// Year and subject the unit belongs to, e.g. `y1.science` (AUD-023):
  /// unit IDs like `unit_01` only need to be unique inside a curriculum.
  TextColumn get curriculum => text()();

  /// The attempt ID the app uses for de-duplication (`{lesson}-{micros}`),
  /// kept exactly as saved; empty for very old attempts.
  TextColumn get clientAttemptId => text()();
  TextColumn get unitId => text()();
  IntColumn get contentVersion => integer()();
  BoolColumn get completed => boolean()();
  IntColumn get effortStars => integer()();

  /// ISO-8601 text exactly as saved (local time without offset).
  TextColumn get completedAt => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (effort_stars BETWEEN 0 AND 3)',
  ];
}

@DataClassName('ObjectiveRow')
class AttemptObjectives extends Table {
  TextColumn get attemptId =>
      text().references(UnitAttempts, #id, onDelete: KeyAction.cascade)();
  TextColumn get objectiveId => text()();
  TextColumn get outcome => text()();

  @override
  Set<Column<Object>> get primaryKey => {attemptId, objectiveId};

  @override
  List<String> get customConstraints => [
    "CHECK (outcome IN ('firstTry', 'afterHint', 'explained'))",
  ];
}

/// In-progress lesson state and other per-child progress records keyed by
/// their journey key (`unit_02`, `unit_01.garden`, `science.review`, ...).
@DataClassName('JourneyRow')
class Journeys extends Table {
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();
  TextColumn get curriculum => text()();
  TextColumn get journeyKey => text()();
  TextColumn get json => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {childId, curriculum, journeyKey};
}

@DataClassName('UsageRow')
class UsageDaily extends Table {
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();
  TextColumn get deviceId => text()();

  /// `YYYY-MM-DD` in the device's local calendar.
  TextColumn get day => text()();
  IntColumn get seconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => {childId, deviceId, day};

  @override
  List<String> get customConstraints => ['CHECK (seconds >= 0)'];
}

/// Records of subjects other than science, kept verbatim.
@DataClassName('SubjectRow')
class OtherSubjects extends Table {
  TextColumn get childId =>
      text().references(Children, #id, onDelete: KeyAction.cascade)();
  TextColumn get subject => text()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {childId, subject};
}

/// Anything that could not be read, kept verbatim for a rescue export and
/// never deleted without a parent's confirmation (AUD-006).
@DataClassName('QuarantineRow')
class QuarantinedRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `child` for a damaged child record; `hive:<key>` for raw Hive copies.
  TextColumn get source => text()();
  TextColumn get legacyId => text().nullable()();
  TextColumn get rawJson => text()();
  DateTimeColumn get foundAt => dateTime()();
}

@DataClassName('MetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Local changes waiting to be pushed (used only for children linked to a
/// parent account; written in the same transaction as the change itself).
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get mutationId => text().unique()();
  TextColumn get entity => text()();
  TextColumn get op => text()();
  TextColumn get entityId => text()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get tries => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => [
    "CHECK (op IN ('create', 'patch', 'delete'))",
    "CHECK (status IN ('pending', 'inflight', 'failed', 'quarantined'))",
  ];
}

@DriftDatabase(
  tables: [
    Children,
    ChildPhotos,
    ChildSettings,
    UnitAttempts,
    AttemptObjectives,
    Journeys,
    UsageDaily,
    OtherSubjects,
    QuarantinedRecords,
    AppMeta,
    Outbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> meta(String key) async => (await (select(
    appMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setMeta(String key, String value) => into(appMeta)
      .insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));

  Future<void> deleteMeta(String key) =>
      (delete(appMeta)..where((t) => t.key.equals(key))).go();
}
