// lib/data/local_db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_db.g.dart';

class NotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();

  TextColumn get kind => text().withDefault(const Constant('text'))();     // 'text' | 'audio' | 'template'
  TextColumn get skin => text().withDefault(const Constant('plain'))();    // 'plain' | 'yellow' | 'pink' | 'dotted' | 'grid'

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NotesTable])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(notesTable, notesTable.kind);
        await m.addColumn(notesTable, notesTable.skin);
      }
    },
  );

  Future<List<NotesTableData>> getAllNotes() =>
      (select(notesTable)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Stream<List<NotesTableData>> watchAllNotes() =>
      (select(notesTable)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<void> upsertNote(NotesTableData n) =>
      into(notesTable).insertOnConflictUpdate(n);

  Future<void> markDeleted(String id) =>
      (update(notesTable)..where((t) => t.id.equals(id)))
          .write(NotesTableCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ));

  Future<void> remove(String id) =>
      (delete(notesTable)..where((t) => t.id.equals(id))).go();

  Future<List<NotesTableData>> getDirty() =>
      (select(notesTable)..where((t) => t.isDirty.equals(true))).get();

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(notesTable).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'notes.db'));
    return NativeDatabase.createInBackground(file);
  });
}
