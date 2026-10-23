import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Trial version 0.4.0 shipped schema 1, 0.5.x and 0.6.x schema 2. Opening
/// such a database with this version must keep every row: schema 2 widened
/// the outbox's `op` check, schema 3 added the child's school year.
void main() {
  /// The schema-2 tables: today's DDL without the school year column.
  Future<List<String>> schemaTwoDdl() async {
    final current = AppDatabase(NativeDatabase.memory());
    final rows = await current
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
          "AND name NOT LIKE 'sqlite_%' ORDER BY type DESC, name",
        )
        .get();
    await current.close();
    final ddl = [for (final r in rows) r.read<String>('sql')];
    final children = ddl.indexWhere((s) => s.contains('TABLE "children"'));
    expect(children, isNot(-1));
    const column = ', "school_year" TEXT NOT NULL DEFAULT \'y1\'';
    expect(ddl[children], contains(column));
    return [...ddl]..[children] = ddl[children].replaceFirst(column, '');
  }

  /// The schema-1 tables: schema 2 with the outbox check as it was.
  Future<List<String>> schemaOneDdl() async {
    final ddl = await schemaTwoDdl();
    final outbox = ddl.indexWhere((s) => s.contains('"outbox"'));
    expect(outbox, isNot(-1));
    final old = ddl[outbox].replaceFirst(
      "op IN ('create', 'patch', 'put', 'delete')",
      "op IN ('create', 'patch', 'delete')",
    );
    expect(old, isNot(ddl[outbox]));
    return [...ddl]..[outbox] = old;
  }

  test(
    'upgrading from schema 1 keeps all rows and accepts put mutations',
    () async {
      final ddl = await schemaOneDdl();
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (sqlite.Database raw) {
            // Runs before drift reads user_version: only for this test DB.
            if (raw.userVersion != 0) return;
            for (final statement in ddl) {
              raw.execute(statement);
            }
            raw.execute(
              "INSERT INTO children (id, has_profile, display_name, sort_order, updated_at) "
              "VALUES ('c1', 1, 'Laila', 0, 0)",
            );
            raw.execute(
              "INSERT INTO outbox (mutation_id, entity, op, entity_id, payload_json, created_at) "
              "VALUES ('m1', 'child', 'patch', 'child:c1', '{}', 0)",
            );
            expect(
              () => raw.execute(
                "INSERT INTO outbox (mutation_id, entity, op, entity_id, payload_json, created_at) "
                "VALUES ('m0', 'journey', 'put', 'journey:c1', '{}', 0)",
              ),
              throwsA(isA<sqlite.SqliteException>()),
            );
            raw.userVersion = 1;
          },
        ),
      );
      addTearDown(db.close);

      final children = await db.select(db.children).get();
      expect(children.single.displayName, 'Laila');
      final outbox = await db.select(db.outbox).get();
      expect(outbox.single.mutationId, 'm1');
      await db
          .into(db.outbox)
          .insert(
            OutboxCompanion.insert(
              mutationId: 'm2',
              entity: 'journey',
              op: 'put',
              entityId: 'journey:c1:y1.science:unit_02',
              payloadJson: '{}',
              createdAt: DateTime.utc(2026, 10, 9),
            ),
          );
      expect(await db.select(db.outbox).get(), hasLength(2));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 3);
      expect(children.single.schoolYear, 'y1');
      final keys = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(keys.read<bool>('foreign_keys'), isTrue);
      await expectLater(
        db
            .into(db.outbox)
            .insert(
              OutboxCompanion.insert(
                mutationId: 'm3',
                entity: 'child',
                op: 'upsert',
                entityId: 'child:c1',
                payloadJson: '{}',
                createdAt: DateTime.utc(2026, 10, 9),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('upgrading from schema 2 keeps every child and puts them in Year 1', () async {
    final ddl = await schemaTwoDdl();
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite.Database raw) {
          if (raw.userVersion != 0) return;
          for (final statement in ddl) {
            raw.execute(statement);
          }
          raw.execute(
            "INSERT INTO children (id, has_profile, display_name, gender, avatar, palette, sort_order, version, sync_status, updated_at) "
            "VALUES ('c1', 1, 'Laila', 'girl', 2, 'berry', 0, 4, 'linked', 0), "
            "('c2', 1, 'Omar', 'boy', 1, 'ocean', 1, 0, 'local', 0)",
          );
          raw.execute(
            "INSERT INTO journeys (child_id, curriculum, journey_key, json, version, updated_at) "
            "VALUES ('c1', 'y1.maths', 'math_unit_01', '{}', 2, 0)",
          );
          raw.userVersion = 2;
        },
      ),
    );
    addTearDown(db.close);

    final children = await (db.select(
      db.children,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
    expect([for (final c in children) c.displayName], ['Laila', 'Omar']);
    expect([for (final c in children) c.schoolYear], ['y1', 'y1']);
    expect(children.first.palette, 'berry');
    expect(children.first.version, 4);
    expect(children.first.syncStatus, 'linked');
    final journey = (await db.select(db.journeys).get()).single;
    expect(journey.curriculum, 'y1.maths');
    expect(journey.version, 2);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 3);
  });
}
