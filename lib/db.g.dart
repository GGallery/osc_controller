// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $FormValuesTable extends FormValues
    with TableInfo<$FormValuesTable, FormValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
    'field_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fieldId, value, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<FormValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('field_id')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FormValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FormValuesTable createAlias(String alias) {
    return $FormValuesTable(attachedDatabase, alias);
  }
}

class FormValue extends DataClass implements Insertable<FormValue> {
  final int id;
  final String fieldId;
  final String value;
  final DateTime createdAt;
  const FormValue({
    required this.id,
    required this.fieldId,
    required this.value,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['field_id'] = Variable<String>(fieldId);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FormValuesCompanion toCompanion(bool nullToAbsent) {
    return FormValuesCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      value: Value(value),
      createdAt: Value(createdAt),
    );
  }

  factory FormValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormValue(
      id: serializer.fromJson<int>(json['id']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fieldId': serializer.toJson<String>(fieldId),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FormValue copyWith({
    int? id,
    String? fieldId,
    String? value,
    DateTime? createdAt,
  }) => FormValue(
    id: id ?? this.id,
    fieldId: fieldId ?? this.fieldId,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
  );
  FormValue copyWithCompanion(FormValuesCompanion data) {
    return FormValue(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormValue(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fieldId, value, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormValue &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.value == this.value &&
          other.createdAt == this.createdAt);
}

class FormValuesCompanion extends UpdateCompanion<FormValue> {
  final Value<int> id;
  final Value<String> fieldId;
  final Value<String> value;
  final Value<DateTime> createdAt;
  const FormValuesCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FormValuesCompanion.insert({
    this.id = const Value.absent(),
    required String fieldId,
    required String value,
    this.createdAt = const Value.absent(),
  }) : fieldId = Value(fieldId),
       value = Value(value);
  static Insertable<FormValue> custom({
    Expression<int>? id,
    Expression<String>? fieldId,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FormValuesCompanion copyWith({
    Value<int>? id,
    Value<String>? fieldId,
    Value<String>? value,
    Value<DateTime>? createdAt,
  }) {
    return FormValuesCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormValuesCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$DbService extends GeneratedDatabase {
  _$DbService(QueryExecutor e) : super(e);
  $DbServiceManager get managers => $DbServiceManager(this);
  late final $FormValuesTable formValues = $FormValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [formValues];
}

typedef $$FormValuesTableCreateCompanionBuilder =
    FormValuesCompanion Function({
      Value<int> id,
      required String fieldId,
      required String value,
      Value<DateTime> createdAt,
    });
typedef $$FormValuesTableUpdateCompanionBuilder =
    FormValuesCompanion Function({
      Value<int> id,
      Value<String> fieldId,
      Value<String> value,
      Value<DateTime> createdAt,
    });

class $$FormValuesTableFilterComposer
    extends Composer<_$DbService, $FormValuesTable> {
  $$FormValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FormValuesTableOrderingComposer
    extends Composer<_$DbService, $FormValuesTable> {
  $$FormValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FormValuesTableAnnotationComposer
    extends Composer<_$DbService, $FormValuesTable> {
  $$FormValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FormValuesTableTableManager
    extends
        RootTableManager<
          _$DbService,
          $FormValuesTable,
          FormValue,
          $$FormValuesTableFilterComposer,
          $$FormValuesTableOrderingComposer,
          $$FormValuesTableAnnotationComposer,
          $$FormValuesTableCreateCompanionBuilder,
          $$FormValuesTableUpdateCompanionBuilder,
          (FormValue, BaseReferences<_$DbService, $FormValuesTable, FormValue>),
          FormValue,
          PrefetchHooks Function()
        > {
  $$FormValuesTableTableManager(_$DbService db, $FormValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fieldId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FormValuesCompanion(
                id: id,
                fieldId: fieldId,
                value: value,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fieldId,
                required String value,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FormValuesCompanion.insert(
                id: id,
                fieldId: fieldId,
                value: value,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FormValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$DbService,
      $FormValuesTable,
      FormValue,
      $$FormValuesTableFilterComposer,
      $$FormValuesTableOrderingComposer,
      $$FormValuesTableAnnotationComposer,
      $$FormValuesTableCreateCompanionBuilder,
      $$FormValuesTableUpdateCompanionBuilder,
      (FormValue, BaseReferences<_$DbService, $FormValuesTable, FormValue>),
      FormValue,
      PrefetchHooks Function()
    >;

class $DbServiceManager {
  final _$DbService _db;
  $DbServiceManager(this._db);
  $$FormValuesTableTableManager get formValues =>
      $$FormValuesTableTableManager(_db, _db.formValues);
}
