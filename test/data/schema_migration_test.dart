import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Trial version 0.4.0 shipped schema 1. Opening such a database with this
/// version must keep every row and only widen the outbox's `op` check.
void main() {
  /// The schema-1 tables: today's DDL with the outbox check as it was.
  Future<List<String>> schemaOneDdl() async {
    final current = AppDatabase(NativeDatabase.memory());
    final rows = await current
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
          "AND name NOT LIKE 'sqlite_%' ORDER BY type DESC, name",
        )
        .get();
    await current.close();
    final ddl = [for (final r in rows) r.read<String>('sql')];
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
      expect(version.read<int>('user_version'), 2);
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
}
