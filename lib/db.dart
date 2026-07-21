import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'db.g.dart';

@DataClassName('FormValue')
class FormValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fieldId => text()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [FormValues])
class DbService extends _$DbService {
  DbService._internal() : super(_openConnection());
  static final DbService instance = DbService._internal();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => await m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) await m.createTable(formValues);
    },
    beforeOpen: (_) async => await customStatement('PRAGMA foreign_keys = ON;'),
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'app_data.sqlite'));
      return NativeDatabase(file);
    });
  }

  Future<void> clearForm() async => delete(formValues).go();

  Future<int> saveValue({required String fieldId, required String value}) {
    return into(
      formValues,
    ).insert(FormValuesCompanion(fieldId: Value(fieldId), value: Value(value)));
  }

  Future<List<FormValue>> loadForm() => select(formValues).get();

  Future<int> deleteValueByFieldId(String fieldId) {
    return (delete(
      formValues,
    )..where((tbl) => tbl.fieldId.equals(fieldId))).go();
  }

  Future<FormValue?> findValueByFieldId(String fieldId) {
    return (select(formValues)
          ..where((tbl) => tbl.fieldId.equals(fieldId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> updateValue({
    required String fieldId,
    required String newValue,
  }) async {
    final rowsUpdated =
        await (update(formValues)..where((tbl) => tbl.fieldId.equals(fieldId)))
            .write(FormValuesCompanion(value: Value(newValue)));

    return rowsUpdated > 0;
  }
}
