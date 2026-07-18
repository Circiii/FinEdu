// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    category,
    type,
    merchant,
    note,
    transactionDate,
    source,
    createdAt,
    updatedAt,
    deleted,
    pendingSync,
    goalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String id;
  final double amount;
  final String category;
  final String type;
  final String? merchant;
  final String? note;
  final DateTime transactionDate;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool pendingSync;

  /// Doar la saving: goalId-ul alimentat. Progresul e DERIVAT din aceste
  /// rânduri, nu ținut într-un contor separat.
  final String? goalId;
  const LocalTransaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    this.merchant,
    this.note,
    required this.transactionDate,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.pendingSync,
    this.goalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      category: Value(category),
      type: Value(type),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      transactionDate: Value(transactionDate),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      pendingSync: Value(pendingSync),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
    );
  }

  factory LocalTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      note: serializer.fromJson<String?>(json['note']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      goalId: serializer.fromJson<String?>(json['goalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'merchant': serializer.toJson<String?>(merchant),
      'note': serializer.toJson<String?>(note),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'goalId': serializer.toJson<String?>(goalId),
    };
  }

  LocalTransaction copyWith({
    String? id,
    double? amount,
    String? category,
    String? type,
    Value<String?> merchant = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? transactionDate,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    bool? pendingSync,
    Value<String?> goalId = const Value.absent(),
  }) => LocalTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    merchant: merchant.present ? merchant.value : this.merchant,
    note: note.present ? note.value : this.note,
    transactionDate: transactionDate ?? this.transactionDate,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    pendingSync: pendingSync ?? this.pendingSync,
    goalId: goalId.present ? goalId.value : this.goalId,
  );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      note: data.note.present ? data.note.value : this.note,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('goalId: $goalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    category,
    type,
    merchant,
    note,
    transactionDate,
    source,
    createdAt,
    updatedAt,
    deleted,
    pendingSync,
    goalId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.type == this.type &&
          other.merchant == this.merchant &&
          other.note == this.note &&
          other.transactionDate == this.transactionDate &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.pendingSync == this.pendingSync &&
          other.goalId == this.goalId);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> category;
  final Value<String> type;
  final Value<String?> merchant;
  final Value<String?> note;
  final Value<DateTime> transactionDate;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> pendingSync;
  final Value<String?> goalId;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.goalId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String id,
    required double amount,
    required String category,
    this.type = const Value.absent(),
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime transactionDate,
    this.source = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.goalId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amount = Value(amount),
       category = Value(category),
       transactionDate = Value(transactionDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalTransaction> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? merchant,
    Expression<String>? note,
    Expression<DateTime>? transactionDate,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? pendingSync,
    Expression<String>? goalId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (merchant != null) 'merchant': merchant,
      if (note != null) 'note': note,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (goalId != null) 'goal_id': goalId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith({
    Value<String>? id,
    Value<double>? amount,
    Value<String>? category,
    Value<String>? type,
    Value<String?>? merchant,
    Value<String?>? note,
    Value<DateTime>? transactionDate,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? pendingSync,
    Value<String?>? goalId,
    Value<int>? rowid,
  }) {
    return LocalTransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      pendingSync: pendingSync ?? this.pendingSync,
      goalId: goalId ?? this.goalId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('goalId: $goalId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoSpendDaysTable extends NoSpendDays
    with TableInfo<$NoSpendDaysTable, NoSpendDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoSpendDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'no_spend_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoSpendDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  NoSpendDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoSpendDay(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $NoSpendDaysTable createAlias(String alias) {
    return $NoSpendDaysTable(attachedDatabase, alias);
  }
}

class NoSpendDay extends DataClass implements Insertable<NoSpendDay> {
  final String date;
  const NoSpendDay({required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    return map;
  }

  NoSpendDaysCompanion toCompanion(bool nullToAbsent) {
    return NoSpendDaysCompanion(date: Value(date));
  }

  factory NoSpendDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoSpendDay(date: serializer.fromJson<String>(json['date']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'date': serializer.toJson<String>(date)};
  }

  NoSpendDay copyWith({String? date}) => NoSpendDay(date: date ?? this.date);
  NoSpendDay copyWithCompanion(NoSpendDaysCompanion data) {
    return NoSpendDay(date: data.date.present ? data.date.value : this.date);
  }

  @override
  String toString() {
    return (StringBuffer('NoSpendDay(')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => date.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoSpendDay && other.date == this.date);
}

class NoSpendDaysCompanion extends UpdateCompanion<NoSpendDay> {
  final Value<String> date;
  final Value<int> rowid;
  const NoSpendDaysCompanion({
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoSpendDaysCompanion.insert({
    required String date,
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<NoSpendDay> custom({
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoSpendDaysCompanion copyWith({Value<String>? date, Value<int>? rowid}) {
    return NoSpendDaysCompanion(
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoSpendDaysCompanion(')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyActivityRowsTable extends DailyActivityRows
    with TableInfo<$DailyActivityRowsTable, DailyActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActivityRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindsMeta = const VerificationMeta('kinds');
  @override
  late final GeneratedColumn<String> kinds = GeneratedColumn<String>(
    'kinds',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, kinds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActivityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kinds')) {
      context.handle(
        _kindsMeta,
        kinds.isAcceptableOrUnknown(data['kinds']!, _kindsMeta),
      );
    } else if (isInserting) {
      context.missing(_kindsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActivityRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      kinds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kinds'],
      )!,
    );
  }

  @override
  $DailyActivityRowsTable createAlias(String alias) {
    return $DailyActivityRowsTable(attachedDatabase, alias);
  }
}

class DailyActivityRow extends DataClass
    implements Insertable<DailyActivityRow> {
  final String date;
  final String kinds;
  const DailyActivityRow({required this.date, required this.kinds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['kinds'] = Variable<String>(kinds);
    return map;
  }

  DailyActivityRowsCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityRowsCompanion(date: Value(date), kinds: Value(kinds));
  }

  factory DailyActivityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActivityRow(
      date: serializer.fromJson<String>(json['date']),
      kinds: serializer.fromJson<String>(json['kinds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'kinds': serializer.toJson<String>(kinds),
    };
  }

  DailyActivityRow copyWith({String? date, String? kinds}) =>
      DailyActivityRow(date: date ?? this.date, kinds: kinds ?? this.kinds);
  DailyActivityRow copyWithCompanion(DailyActivityRowsCompanion data) {
    return DailyActivityRow(
      date: data.date.present ? data.date.value : this.date,
      kinds: data.kinds.present ? data.kinds.value : this.kinds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityRow(')
          ..write('date: $date, ')
          ..write('kinds: $kinds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, kinds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActivityRow &&
          other.date == this.date &&
          other.kinds == this.kinds);
}

class DailyActivityRowsCompanion extends UpdateCompanion<DailyActivityRow> {
  final Value<String> date;
  final Value<String> kinds;
  final Value<int> rowid;
  const DailyActivityRowsCompanion({
    this.date = const Value.absent(),
    this.kinds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActivityRowsCompanion.insert({
    required String date,
    required String kinds,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       kinds = Value(kinds);
  static Insertable<DailyActivityRow> custom({
    Expression<String>? date,
    Expression<String>? kinds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (kinds != null) 'kinds': kinds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActivityRowsCompanion copyWith({
    Value<String>? date,
    Value<String>? kinds,
    Value<int>? rowid,
  }) {
    return DailyActivityRowsCompanion(
      date: date ?? this.date,
      kinds: kinds ?? this.kinds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kinds.present) {
      map['kinds'] = Variable<String>(kinds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityRowsCompanion(')
          ..write('date: $date, ')
          ..write('kinds: $kinds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    opType,
    payload,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int id;
  final String opType;
  final String payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  const OutboxEntry({
    required this.id,
    required this.opType,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op_type'] = Variable<String>(opType);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      opType: Value(opType),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'opType': serializer.toJson<String>(opType),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEntry copyWith({
    int? id,
    String? opType,
    String? payload,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxEntry(
    id: id ?? this.id,
    opType: opType ?? this.opType,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, opType, payload, createdAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> id;
  final Value<String> opType;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String opType,
    required String payload,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : opType = Value(opType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? opType,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? opType,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashyNameMeta = const VerificationMeta(
    'cashyName',
  );
  @override
  late final GeneratedColumn<String> cashyName = GeneratedColumn<String>(
    'cashy_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Cashy'),
  );
  static const VerificationMeta _cashyColorMeta = const VerificationMeta(
    'cashyColor',
  );
  @override
  late final GeneratedColumn<String> cashyColor = GeneratedColumn<String>(
    'cashy_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sky'),
  );
  static const VerificationMeta _equippedBackgroundMeta =
      const VerificationMeta('equippedBackground');
  @override
  late final GeneratedColumn<String> equippedBackground =
      GeneratedColumn<String>(
        'equipped_background',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _equippedAccessoryMeta = const VerificationMeta(
    'equippedAccessory',
  );
  @override
  late final GeneratedColumn<String> equippedAccessory =
      GeneratedColumn<String>(
        'equipped_accessory',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ageBandMeta = const VerificationMeta(
    'ageBand',
  );
  @override
  late final GeneratedColumn<String> ageBand = GeneratedColumn<String>(
    'age_band',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackMeta = const VerificationMeta('track');
  @override
  late final GeneratedColumn<String> track = GeneratedColumn<String>(
    'track',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyBudgetMeta = const VerificationMeta(
    'monthlyBudget',
  );
  @override
  late final GeneratedColumn<double> monthlyBudget = GeneratedColumn<double>(
    'monthly_budget',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardedMeta = const VerificationMeta(
    'onboarded',
  );
  @override
  late final GeneratedColumn<bool> onboarded = GeneratedColumn<bool>(
    'onboarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notifChoiceMeta = const VerificationMeta(
    'notifChoice',
  );
  @override
  late final GeneratedColumn<String> notifChoice = GeneratedColumn<String>(
    'notif_choice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unset'),
  );
  static const VerificationMeta _parentEmailMeta = const VerificationMeta(
    'parentEmail',
  );
  @override
  late final GeneratedColumn<String> parentEmail = GeneratedColumn<String>(
    'parent_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentalStatusMeta = const VerificationMeta(
    'parentalStatus',
  );
  @override
  late final GeneratedColumn<String> parentalStatus = GeneratedColumn<String>(
    'parental_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_required'),
  );
  static const VerificationMeta _acornsMeta = const VerificationMeta('acorns');
  @override
  late final GeneratedColumn<int> acorns = GeneratedColumn<int>(
    'acorns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quizSeedMeta = const VerificationMeta(
    'quizSeed',
  );
  @override
  late final GeneratedColumn<String> quizSeed = GeneratedColumn<String>(
    'quiz_seed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personalizationOnMeta = const VerificationMeta(
    'personalizationOn',
  );
  @override
  late final GeneratedColumn<bool> personalizationOn = GeneratedColumn<bool>(
    'personalization_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("personalization_on" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashyName,
    cashyColor,
    equippedBackground,
    equippedAccessory,
    ageBand,
    track,
    monthlyBudget,
    onboarded,
    notifChoice,
    parentEmail,
    parentalStatus,
    acorns,
    xp,
    quizSeed,
    personalizationOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cashy_name')) {
      context.handle(
        _cashyNameMeta,
        cashyName.isAcceptableOrUnknown(data['cashy_name']!, _cashyNameMeta),
      );
    }
    if (data.containsKey('cashy_color')) {
      context.handle(
        _cashyColorMeta,
        cashyColor.isAcceptableOrUnknown(data['cashy_color']!, _cashyColorMeta),
      );
    }
    if (data.containsKey('equipped_background')) {
      context.handle(
        _equippedBackgroundMeta,
        equippedBackground.isAcceptableOrUnknown(
          data['equipped_background']!,
          _equippedBackgroundMeta,
        ),
      );
    }
    if (data.containsKey('equipped_accessory')) {
      context.handle(
        _equippedAccessoryMeta,
        equippedAccessory.isAcceptableOrUnknown(
          data['equipped_accessory']!,
          _equippedAccessoryMeta,
        ),
      );
    }
    if (data.containsKey('age_band')) {
      context.handle(
        _ageBandMeta,
        ageBand.isAcceptableOrUnknown(data['age_band']!, _ageBandMeta),
      );
    }
    if (data.containsKey('track')) {
      context.handle(
        _trackMeta,
        track.isAcceptableOrUnknown(data['track']!, _trackMeta),
      );
    }
    if (data.containsKey('monthly_budget')) {
      context.handle(
        _monthlyBudgetMeta,
        monthlyBudget.isAcceptableOrUnknown(
          data['monthly_budget']!,
          _monthlyBudgetMeta,
        ),
      );
    }
    if (data.containsKey('onboarded')) {
      context.handle(
        _onboardedMeta,
        onboarded.isAcceptableOrUnknown(data['onboarded']!, _onboardedMeta),
      );
    }
    if (data.containsKey('notif_choice')) {
      context.handle(
        _notifChoiceMeta,
        notifChoice.isAcceptableOrUnknown(
          data['notif_choice']!,
          _notifChoiceMeta,
        ),
      );
    }
    if (data.containsKey('parent_email')) {
      context.handle(
        _parentEmailMeta,
        parentEmail.isAcceptableOrUnknown(
          data['parent_email']!,
          _parentEmailMeta,
        ),
      );
    }
    if (data.containsKey('parental_status')) {
      context.handle(
        _parentalStatusMeta,
        parentalStatus.isAcceptableOrUnknown(
          data['parental_status']!,
          _parentalStatusMeta,
        ),
      );
    }
    if (data.containsKey('acorns')) {
      context.handle(
        _acornsMeta,
        acorns.isAcceptableOrUnknown(data['acorns']!, _acornsMeta),
      );
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('quiz_seed')) {
      context.handle(
        _quizSeedMeta,
        quizSeed.isAcceptableOrUnknown(data['quiz_seed']!, _quizSeedMeta),
      );
    }
    if (data.containsKey('personalization_on')) {
      context.handle(
        _personalizationOnMeta,
        personalizationOn.isAcceptableOrUnknown(
          data['personalization_on']!,
          _personalizationOnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cashyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashy_name'],
      )!,
      cashyColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashy_color'],
      )!,
      equippedBackground: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipped_background'],
      ),
      equippedAccessory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipped_accessory'],
      ),
      ageBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_band'],
      ),
      track: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track'],
      ),
      monthlyBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_budget'],
      ),
      onboarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarded'],
      )!,
      notifChoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notif_choice'],
      )!,
      parentEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_email'],
      ),
      parentalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parental_status'],
      )!,
      acorns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acorns'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      quizSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quiz_seed'],
      ),
      personalizationOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}personalization_on'],
      )!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final int id;
  final String cashyName;

  /// Una din: sky | mint | amber | violet (nuanțe din paleta clay).
  final String cashyColor;

  /// Itemul echipat per slot din garderobă (id din wardrobe.json).
  final String? equippedBackground;
  final String? equippedAccessory;

  /// Una din: 14_15 | 16_17 | 18_25 (nu se stochează niciodată anul exact de naștere).
  final String? ageBand;

  /// Track curriculum: A (14-18) | B (19+).
  final String? track;
  final double? monthlyBudget;
  final bool onboarded;

  /// Rezultat soft-ask: unset | accepted | later.
  final String notifChoice;
  final String? parentEmail;

  /// not_required | pending | confirmed.
  final String parentalStatus;

  /// Balanța locală de ghinde, până apare ledger-ul pe server.
  final int acorns;

  /// XP de învățare (300/nivel). Persistat, spre deosebire de contoarele
  /// efemere din prototipul web.
  final int xp;

  /// JSON cu răspunsurile la chestionarul de onboarding (seed Elo).
  final String? quizSeed;

  /// Personalizare inteligentă: opt-in explicit, DEFAULT OFF (AADC/GDPR, /// profilarea minorilor nu e niciodată default). Fără ea, totul cade pe
  /// regulile statice.
  final bool personalizationOn;
  const LocalProfile({
    required this.id,
    required this.cashyName,
    required this.cashyColor,
    this.equippedBackground,
    this.equippedAccessory,
    this.ageBand,
    this.track,
    this.monthlyBudget,
    required this.onboarded,
    required this.notifChoice,
    this.parentEmail,
    required this.parentalStatus,
    required this.acorns,
    required this.xp,
    this.quizSeed,
    required this.personalizationOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cashy_name'] = Variable<String>(cashyName);
    map['cashy_color'] = Variable<String>(cashyColor);
    if (!nullToAbsent || equippedBackground != null) {
      map['equipped_background'] = Variable<String>(equippedBackground);
    }
    if (!nullToAbsent || equippedAccessory != null) {
      map['equipped_accessory'] = Variable<String>(equippedAccessory);
    }
    if (!nullToAbsent || ageBand != null) {
      map['age_band'] = Variable<String>(ageBand);
    }
    if (!nullToAbsent || track != null) {
      map['track'] = Variable<String>(track);
    }
    if (!nullToAbsent || monthlyBudget != null) {
      map['monthly_budget'] = Variable<double>(monthlyBudget);
    }
    map['onboarded'] = Variable<bool>(onboarded);
    map['notif_choice'] = Variable<String>(notifChoice);
    if (!nullToAbsent || parentEmail != null) {
      map['parent_email'] = Variable<String>(parentEmail);
    }
    map['parental_status'] = Variable<String>(parentalStatus);
    map['acorns'] = Variable<int>(acorns);
    map['xp'] = Variable<int>(xp);
    if (!nullToAbsent || quizSeed != null) {
      map['quiz_seed'] = Variable<String>(quizSeed);
    }
    map['personalization_on'] = Variable<bool>(personalizationOn);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      id: Value(id),
      cashyName: Value(cashyName),
      cashyColor: Value(cashyColor),
      equippedBackground: equippedBackground == null && nullToAbsent
          ? const Value.absent()
          : Value(equippedBackground),
      equippedAccessory: equippedAccessory == null && nullToAbsent
          ? const Value.absent()
          : Value(equippedAccessory),
      ageBand: ageBand == null && nullToAbsent
          ? const Value.absent()
          : Value(ageBand),
      track: track == null && nullToAbsent
          ? const Value.absent()
          : Value(track),
      monthlyBudget: monthlyBudget == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyBudget),
      onboarded: Value(onboarded),
      notifChoice: Value(notifChoice),
      parentEmail: parentEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(parentEmail),
      parentalStatus: Value(parentalStatus),
      acorns: Value(acorns),
      xp: Value(xp),
      quizSeed: quizSeed == null && nullToAbsent
          ? const Value.absent()
          : Value(quizSeed),
      personalizationOn: Value(personalizationOn),
    );
  }

  factory LocalProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      id: serializer.fromJson<int>(json['id']),
      cashyName: serializer.fromJson<String>(json['cashyName']),
      cashyColor: serializer.fromJson<String>(json['cashyColor']),
      equippedBackground: serializer.fromJson<String?>(
        json['equippedBackground'],
      ),
      equippedAccessory: serializer.fromJson<String?>(
        json['equippedAccessory'],
      ),
      ageBand: serializer.fromJson<String?>(json['ageBand']),
      track: serializer.fromJson<String?>(json['track']),
      monthlyBudget: serializer.fromJson<double?>(json['monthlyBudget']),
      onboarded: serializer.fromJson<bool>(json['onboarded']),
      notifChoice: serializer.fromJson<String>(json['notifChoice']),
      parentEmail: serializer.fromJson<String?>(json['parentEmail']),
      parentalStatus: serializer.fromJson<String>(json['parentalStatus']),
      acorns: serializer.fromJson<int>(json['acorns']),
      xp: serializer.fromJson<int>(json['xp']),
      quizSeed: serializer.fromJson<String?>(json['quizSeed']),
      personalizationOn: serializer.fromJson<bool>(json['personalizationOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cashyName': serializer.toJson<String>(cashyName),
      'cashyColor': serializer.toJson<String>(cashyColor),
      'equippedBackground': serializer.toJson<String?>(equippedBackground),
      'equippedAccessory': serializer.toJson<String?>(equippedAccessory),
      'ageBand': serializer.toJson<String?>(ageBand),
      'track': serializer.toJson<String?>(track),
      'monthlyBudget': serializer.toJson<double?>(monthlyBudget),
      'onboarded': serializer.toJson<bool>(onboarded),
      'notifChoice': serializer.toJson<String>(notifChoice),
      'parentEmail': serializer.toJson<String?>(parentEmail),
      'parentalStatus': serializer.toJson<String>(parentalStatus),
      'acorns': serializer.toJson<int>(acorns),
      'xp': serializer.toJson<int>(xp),
      'quizSeed': serializer.toJson<String?>(quizSeed),
      'personalizationOn': serializer.toJson<bool>(personalizationOn),
    };
  }

  LocalProfile copyWith({
    int? id,
    String? cashyName,
    String? cashyColor,
    Value<String?> equippedBackground = const Value.absent(),
    Value<String?> equippedAccessory = const Value.absent(),
    Value<String?> ageBand = const Value.absent(),
    Value<String?> track = const Value.absent(),
    Value<double?> monthlyBudget = const Value.absent(),
    bool? onboarded,
    String? notifChoice,
    Value<String?> parentEmail = const Value.absent(),
    String? parentalStatus,
    int? acorns,
    int? xp,
    Value<String?> quizSeed = const Value.absent(),
    bool? personalizationOn,
  }) => LocalProfile(
    id: id ?? this.id,
    cashyName: cashyName ?? this.cashyName,
    cashyColor: cashyColor ?? this.cashyColor,
    equippedBackground: equippedBackground.present
        ? equippedBackground.value
        : this.equippedBackground,
    equippedAccessory: equippedAccessory.present
        ? equippedAccessory.value
        : this.equippedAccessory,
    ageBand: ageBand.present ? ageBand.value : this.ageBand,
    track: track.present ? track.value : this.track,
    monthlyBudget: monthlyBudget.present
        ? monthlyBudget.value
        : this.monthlyBudget,
    onboarded: onboarded ?? this.onboarded,
    notifChoice: notifChoice ?? this.notifChoice,
    parentEmail: parentEmail.present ? parentEmail.value : this.parentEmail,
    parentalStatus: parentalStatus ?? this.parentalStatus,
    acorns: acorns ?? this.acorns,
    xp: xp ?? this.xp,
    quizSeed: quizSeed.present ? quizSeed.value : this.quizSeed,
    personalizationOn: personalizationOn ?? this.personalizationOn,
  );
  LocalProfile copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfile(
      id: data.id.present ? data.id.value : this.id,
      cashyName: data.cashyName.present ? data.cashyName.value : this.cashyName,
      cashyColor: data.cashyColor.present
          ? data.cashyColor.value
          : this.cashyColor,
      equippedBackground: data.equippedBackground.present
          ? data.equippedBackground.value
          : this.equippedBackground,
      equippedAccessory: data.equippedAccessory.present
          ? data.equippedAccessory.value
          : this.equippedAccessory,
      ageBand: data.ageBand.present ? data.ageBand.value : this.ageBand,
      track: data.track.present ? data.track.value : this.track,
      monthlyBudget: data.monthlyBudget.present
          ? data.monthlyBudget.value
          : this.monthlyBudget,
      onboarded: data.onboarded.present ? data.onboarded.value : this.onboarded,
      notifChoice: data.notifChoice.present
          ? data.notifChoice.value
          : this.notifChoice,
      parentEmail: data.parentEmail.present
          ? data.parentEmail.value
          : this.parentEmail,
      parentalStatus: data.parentalStatus.present
          ? data.parentalStatus.value
          : this.parentalStatus,
      acorns: data.acorns.present ? data.acorns.value : this.acorns,
      xp: data.xp.present ? data.xp.value : this.xp,
      quizSeed: data.quizSeed.present ? data.quizSeed.value : this.quizSeed,
      personalizationOn: data.personalizationOn.present
          ? data.personalizationOn.value
          : this.personalizationOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('id: $id, ')
          ..write('cashyName: $cashyName, ')
          ..write('cashyColor: $cashyColor, ')
          ..write('equippedBackground: $equippedBackground, ')
          ..write('equippedAccessory: $equippedAccessory, ')
          ..write('ageBand: $ageBand, ')
          ..write('track: $track, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('onboarded: $onboarded, ')
          ..write('notifChoice: $notifChoice, ')
          ..write('parentEmail: $parentEmail, ')
          ..write('parentalStatus: $parentalStatus, ')
          ..write('acorns: $acorns, ')
          ..write('xp: $xp, ')
          ..write('quizSeed: $quizSeed, ')
          ..write('personalizationOn: $personalizationOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cashyName,
    cashyColor,
    equippedBackground,
    equippedAccessory,
    ageBand,
    track,
    monthlyBudget,
    onboarded,
    notifChoice,
    parentEmail,
    parentalStatus,
    acorns,
    xp,
    quizSeed,
    personalizationOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.id == this.id &&
          other.cashyName == this.cashyName &&
          other.cashyColor == this.cashyColor &&
          other.equippedBackground == this.equippedBackground &&
          other.equippedAccessory == this.equippedAccessory &&
          other.ageBand == this.ageBand &&
          other.track == this.track &&
          other.monthlyBudget == this.monthlyBudget &&
          other.onboarded == this.onboarded &&
          other.notifChoice == this.notifChoice &&
          other.parentEmail == this.parentEmail &&
          other.parentalStatus == this.parentalStatus &&
          other.acorns == this.acorns &&
          other.xp == this.xp &&
          other.quizSeed == this.quizSeed &&
          other.personalizationOn == this.personalizationOn);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<int> id;
  final Value<String> cashyName;
  final Value<String> cashyColor;
  final Value<String?> equippedBackground;
  final Value<String?> equippedAccessory;
  final Value<String?> ageBand;
  final Value<String?> track;
  final Value<double?> monthlyBudget;
  final Value<bool> onboarded;
  final Value<String> notifChoice;
  final Value<String?> parentEmail;
  final Value<String> parentalStatus;
  final Value<int> acorns;
  final Value<int> xp;
  final Value<String?> quizSeed;
  final Value<bool> personalizationOn;
  const LocalProfilesCompanion({
    this.id = const Value.absent(),
    this.cashyName = const Value.absent(),
    this.cashyColor = const Value.absent(),
    this.equippedBackground = const Value.absent(),
    this.equippedAccessory = const Value.absent(),
    this.ageBand = const Value.absent(),
    this.track = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.notifChoice = const Value.absent(),
    this.parentEmail = const Value.absent(),
    this.parentalStatus = const Value.absent(),
    this.acorns = const Value.absent(),
    this.xp = const Value.absent(),
    this.quizSeed = const Value.absent(),
    this.personalizationOn = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.cashyName = const Value.absent(),
    this.cashyColor = const Value.absent(),
    this.equippedBackground = const Value.absent(),
    this.equippedAccessory = const Value.absent(),
    this.ageBand = const Value.absent(),
    this.track = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.notifChoice = const Value.absent(),
    this.parentEmail = const Value.absent(),
    this.parentalStatus = const Value.absent(),
    this.acorns = const Value.absent(),
    this.xp = const Value.absent(),
    this.quizSeed = const Value.absent(),
    this.personalizationOn = const Value.absent(),
  });
  static Insertable<LocalProfile> custom({
    Expression<int>? id,
    Expression<String>? cashyName,
    Expression<String>? cashyColor,
    Expression<String>? equippedBackground,
    Expression<String>? equippedAccessory,
    Expression<String>? ageBand,
    Expression<String>? track,
    Expression<double>? monthlyBudget,
    Expression<bool>? onboarded,
    Expression<String>? notifChoice,
    Expression<String>? parentEmail,
    Expression<String>? parentalStatus,
    Expression<int>? acorns,
    Expression<int>? xp,
    Expression<String>? quizSeed,
    Expression<bool>? personalizationOn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashyName != null) 'cashy_name': cashyName,
      if (cashyColor != null) 'cashy_color': cashyColor,
      if (equippedBackground != null) 'equipped_background': equippedBackground,
      if (equippedAccessory != null) 'equipped_accessory': equippedAccessory,
      if (ageBand != null) 'age_band': ageBand,
      if (track != null) 'track': track,
      if (monthlyBudget != null) 'monthly_budget': monthlyBudget,
      if (onboarded != null) 'onboarded': onboarded,
      if (notifChoice != null) 'notif_choice': notifChoice,
      if (parentEmail != null) 'parent_email': parentEmail,
      if (parentalStatus != null) 'parental_status': parentalStatus,
      if (acorns != null) 'acorns': acorns,
      if (xp != null) 'xp': xp,
      if (quizSeed != null) 'quiz_seed': quizSeed,
      if (personalizationOn != null) 'personalization_on': personalizationOn,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? cashyName,
    Value<String>? cashyColor,
    Value<String?>? equippedBackground,
    Value<String?>? equippedAccessory,
    Value<String?>? ageBand,
    Value<String?>? track,
    Value<double?>? monthlyBudget,
    Value<bool>? onboarded,
    Value<String>? notifChoice,
    Value<String?>? parentEmail,
    Value<String>? parentalStatus,
    Value<int>? acorns,
    Value<int>? xp,
    Value<String?>? quizSeed,
    Value<bool>? personalizationOn,
  }) {
    return LocalProfilesCompanion(
      id: id ?? this.id,
      cashyName: cashyName ?? this.cashyName,
      cashyColor: cashyColor ?? this.cashyColor,
      equippedBackground: equippedBackground ?? this.equippedBackground,
      equippedAccessory: equippedAccessory ?? this.equippedAccessory,
      ageBand: ageBand ?? this.ageBand,
      track: track ?? this.track,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      onboarded: onboarded ?? this.onboarded,
      notifChoice: notifChoice ?? this.notifChoice,
      parentEmail: parentEmail ?? this.parentEmail,
      parentalStatus: parentalStatus ?? this.parentalStatus,
      acorns: acorns ?? this.acorns,
      xp: xp ?? this.xp,
      quizSeed: quizSeed ?? this.quizSeed,
      personalizationOn: personalizationOn ?? this.personalizationOn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cashyName.present) {
      map['cashy_name'] = Variable<String>(cashyName.value);
    }
    if (cashyColor.present) {
      map['cashy_color'] = Variable<String>(cashyColor.value);
    }
    if (equippedBackground.present) {
      map['equipped_background'] = Variable<String>(equippedBackground.value);
    }
    if (equippedAccessory.present) {
      map['equipped_accessory'] = Variable<String>(equippedAccessory.value);
    }
    if (ageBand.present) {
      map['age_band'] = Variable<String>(ageBand.value);
    }
    if (track.present) {
      map['track'] = Variable<String>(track.value);
    }
    if (monthlyBudget.present) {
      map['monthly_budget'] = Variable<double>(monthlyBudget.value);
    }
    if (onboarded.present) {
      map['onboarded'] = Variable<bool>(onboarded.value);
    }
    if (notifChoice.present) {
      map['notif_choice'] = Variable<String>(notifChoice.value);
    }
    if (parentEmail.present) {
      map['parent_email'] = Variable<String>(parentEmail.value);
    }
    if (parentalStatus.present) {
      map['parental_status'] = Variable<String>(parentalStatus.value);
    }
    if (acorns.present) {
      map['acorns'] = Variable<int>(acorns.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (quizSeed.present) {
      map['quiz_seed'] = Variable<String>(quizSeed.value);
    }
    if (personalizationOn.present) {
      map['personalization_on'] = Variable<bool>(personalizationOn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('id: $id, ')
          ..write('cashyName: $cashyName, ')
          ..write('cashyColor: $cashyColor, ')
          ..write('equippedBackground: $equippedBackground, ')
          ..write('equippedAccessory: $equippedAccessory, ')
          ..write('ageBand: $ageBand, ')
          ..write('track: $track, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('onboarded: $onboarded, ')
          ..write('notifChoice: $notifChoice, ')
          ..write('parentEmail: $parentEmail, ')
          ..write('parentalStatus: $parentalStatus, ')
          ..write('acorns: $acorns, ')
          ..write('xp: $xp, ')
          ..write('quizSeed: $quizSeed, ')
          ..write('personalizationOn: $personalizationOn')
          ..write(')'))
        .toString();
  }
}

class $StreakStatesTable extends StreakStates
    with TableInfo<$StreakStatesTable, StreakState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freezesMeta = const VerificationMeta(
    'freezes',
  );
  @override
  late final GeneratedColumn<int> freezes = GeneratedColumn<int>(
    'freezes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _frozenDaysMeta = const VerificationMeta(
    'frozenDays',
  );
  @override
  late final GeneratedColumn<String> frozenDays = GeneratedColumn<String>(
    'frozen_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _earnbackValueMeta = const VerificationMeta(
    'earnbackValue',
  );
  @override
  late final GeneratedColumn<int> earnbackValue = GeneratedColumn<int>(
    'earnback_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _earnbackUntilMeta = const VerificationMeta(
    'earnbackUntil',
  );
  @override
  late final GeneratedColumn<String> earnbackUntil = GeneratedColumn<String>(
    'earnback_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earnbackGapMeta = const VerificationMeta(
    'earnbackGap',
  );
  @override
  late final GeneratedColumn<String> earnbackGap = GeneratedColumn<String>(
    'earnback_gap',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _claimedMilestonesMeta = const VerificationMeta(
    'claimedMilestones',
  );
  @override
  late final GeneratedColumn<String> claimedMilestones =
      GeneratedColumn<String>(
        'claimed_milestones',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _lastEvaluatedMeta = const VerificationMeta(
    'lastEvaluated',
  );
  @override
  late final GeneratedColumn<String> lastEvaluated = GeneratedColumn<String>(
    'last_evaluated',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    freezes,
    frozenDays,
    earnbackValue,
    earnbackUntil,
    earnbackGap,
    claimedMilestones,
    lastEvaluated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreakState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('freezes')) {
      context.handle(
        _freezesMeta,
        freezes.isAcceptableOrUnknown(data['freezes']!, _freezesMeta),
      );
    }
    if (data.containsKey('frozen_days')) {
      context.handle(
        _frozenDaysMeta,
        frozenDays.isAcceptableOrUnknown(data['frozen_days']!, _frozenDaysMeta),
      );
    }
    if (data.containsKey('earnback_value')) {
      context.handle(
        _earnbackValueMeta,
        earnbackValue.isAcceptableOrUnknown(
          data['earnback_value']!,
          _earnbackValueMeta,
        ),
      );
    }
    if (data.containsKey('earnback_until')) {
      context.handle(
        _earnbackUntilMeta,
        earnbackUntil.isAcceptableOrUnknown(
          data['earnback_until']!,
          _earnbackUntilMeta,
        ),
      );
    }
    if (data.containsKey('earnback_gap')) {
      context.handle(
        _earnbackGapMeta,
        earnbackGap.isAcceptableOrUnknown(
          data['earnback_gap']!,
          _earnbackGapMeta,
        ),
      );
    }
    if (data.containsKey('claimed_milestones')) {
      context.handle(
        _claimedMilestonesMeta,
        claimedMilestones.isAcceptableOrUnknown(
          data['claimed_milestones']!,
          _claimedMilestonesMeta,
        ),
      );
    }
    if (data.containsKey('last_evaluated')) {
      context.handle(
        _lastEvaluatedMeta,
        lastEvaluated.isAcceptableOrUnknown(
          data['last_evaluated']!,
          _lastEvaluatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      freezes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freezes'],
      )!,
      frozenDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frozen_days'],
      )!,
      earnbackValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}earnback_value'],
      )!,
      earnbackUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earnback_until'],
      ),
      earnbackGap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earnback_gap'],
      )!,
      claimedMilestones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimed_milestones'],
      )!,
      lastEvaluated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_evaluated'],
      ),
    );
  }

  @override
  $StreakStatesTable createAlias(String alias) {
    return $StreakStatesTable(attachedDatabase, alias);
  }
}

class StreakState extends DataClass implements Insertable<StreakState> {
  final int id;
  final int freezes;
  final String frozenDays;
  final int earnbackValue;
  final String? earnbackUntil;
  final String earnbackGap;
  final String claimedMilestones;
  final String? lastEvaluated;
  const StreakState({
    required this.id,
    required this.freezes,
    required this.frozenDays,
    required this.earnbackValue,
    this.earnbackUntil,
    required this.earnbackGap,
    required this.claimedMilestones,
    this.lastEvaluated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['freezes'] = Variable<int>(freezes);
    map['frozen_days'] = Variable<String>(frozenDays);
    map['earnback_value'] = Variable<int>(earnbackValue);
    if (!nullToAbsent || earnbackUntil != null) {
      map['earnback_until'] = Variable<String>(earnbackUntil);
    }
    map['earnback_gap'] = Variable<String>(earnbackGap);
    map['claimed_milestones'] = Variable<String>(claimedMilestones);
    if (!nullToAbsent || lastEvaluated != null) {
      map['last_evaluated'] = Variable<String>(lastEvaluated);
    }
    return map;
  }

  StreakStatesCompanion toCompanion(bool nullToAbsent) {
    return StreakStatesCompanion(
      id: Value(id),
      freezes: Value(freezes),
      frozenDays: Value(frozenDays),
      earnbackValue: Value(earnbackValue),
      earnbackUntil: earnbackUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(earnbackUntil),
      earnbackGap: Value(earnbackGap),
      claimedMilestones: Value(claimedMilestones),
      lastEvaluated: lastEvaluated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEvaluated),
    );
  }

  factory StreakState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakState(
      id: serializer.fromJson<int>(json['id']),
      freezes: serializer.fromJson<int>(json['freezes']),
      frozenDays: serializer.fromJson<String>(json['frozenDays']),
      earnbackValue: serializer.fromJson<int>(json['earnbackValue']),
      earnbackUntil: serializer.fromJson<String?>(json['earnbackUntil']),
      earnbackGap: serializer.fromJson<String>(json['earnbackGap']),
      claimedMilestones: serializer.fromJson<String>(json['claimedMilestones']),
      lastEvaluated: serializer.fromJson<String?>(json['lastEvaluated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'freezes': serializer.toJson<int>(freezes),
      'frozenDays': serializer.toJson<String>(frozenDays),
      'earnbackValue': serializer.toJson<int>(earnbackValue),
      'earnbackUntil': serializer.toJson<String?>(earnbackUntil),
      'earnbackGap': serializer.toJson<String>(earnbackGap),
      'claimedMilestones': serializer.toJson<String>(claimedMilestones),
      'lastEvaluated': serializer.toJson<String?>(lastEvaluated),
    };
  }

  StreakState copyWith({
    int? id,
    int? freezes,
    String? frozenDays,
    int? earnbackValue,
    Value<String?> earnbackUntil = const Value.absent(),
    String? earnbackGap,
    String? claimedMilestones,
    Value<String?> lastEvaluated = const Value.absent(),
  }) => StreakState(
    id: id ?? this.id,
    freezes: freezes ?? this.freezes,
    frozenDays: frozenDays ?? this.frozenDays,
    earnbackValue: earnbackValue ?? this.earnbackValue,
    earnbackUntil: earnbackUntil.present
        ? earnbackUntil.value
        : this.earnbackUntil,
    earnbackGap: earnbackGap ?? this.earnbackGap,
    claimedMilestones: claimedMilestones ?? this.claimedMilestones,
    lastEvaluated: lastEvaluated.present
        ? lastEvaluated.value
        : this.lastEvaluated,
  );
  StreakState copyWithCompanion(StreakStatesCompanion data) {
    return StreakState(
      id: data.id.present ? data.id.value : this.id,
      freezes: data.freezes.present ? data.freezes.value : this.freezes,
      frozenDays: data.frozenDays.present
          ? data.frozenDays.value
          : this.frozenDays,
      earnbackValue: data.earnbackValue.present
          ? data.earnbackValue.value
          : this.earnbackValue,
      earnbackUntil: data.earnbackUntil.present
          ? data.earnbackUntil.value
          : this.earnbackUntil,
      earnbackGap: data.earnbackGap.present
          ? data.earnbackGap.value
          : this.earnbackGap,
      claimedMilestones: data.claimedMilestones.present
          ? data.claimedMilestones.value
          : this.claimedMilestones,
      lastEvaluated: data.lastEvaluated.present
          ? data.lastEvaluated.value
          : this.lastEvaluated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakState(')
          ..write('id: $id, ')
          ..write('freezes: $freezes, ')
          ..write('frozenDays: $frozenDays, ')
          ..write('earnbackValue: $earnbackValue, ')
          ..write('earnbackUntil: $earnbackUntil, ')
          ..write('earnbackGap: $earnbackGap, ')
          ..write('claimedMilestones: $claimedMilestones, ')
          ..write('lastEvaluated: $lastEvaluated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    freezes,
    frozenDays,
    earnbackValue,
    earnbackUntil,
    earnbackGap,
    claimedMilestones,
    lastEvaluated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakState &&
          other.id == this.id &&
          other.freezes == this.freezes &&
          other.frozenDays == this.frozenDays &&
          other.earnbackValue == this.earnbackValue &&
          other.earnbackUntil == this.earnbackUntil &&
          other.earnbackGap == this.earnbackGap &&
          other.claimedMilestones == this.claimedMilestones &&
          other.lastEvaluated == this.lastEvaluated);
}

class StreakStatesCompanion extends UpdateCompanion<StreakState> {
  final Value<int> id;
  final Value<int> freezes;
  final Value<String> frozenDays;
  final Value<int> earnbackValue;
  final Value<String?> earnbackUntil;
  final Value<String> earnbackGap;
  final Value<String> claimedMilestones;
  final Value<String?> lastEvaluated;
  const StreakStatesCompanion({
    this.id = const Value.absent(),
    this.freezes = const Value.absent(),
    this.frozenDays = const Value.absent(),
    this.earnbackValue = const Value.absent(),
    this.earnbackUntil = const Value.absent(),
    this.earnbackGap = const Value.absent(),
    this.claimedMilestones = const Value.absent(),
    this.lastEvaluated = const Value.absent(),
  });
  StreakStatesCompanion.insert({
    this.id = const Value.absent(),
    this.freezes = const Value.absent(),
    this.frozenDays = const Value.absent(),
    this.earnbackValue = const Value.absent(),
    this.earnbackUntil = const Value.absent(),
    this.earnbackGap = const Value.absent(),
    this.claimedMilestones = const Value.absent(),
    this.lastEvaluated = const Value.absent(),
  });
  static Insertable<StreakState> custom({
    Expression<int>? id,
    Expression<int>? freezes,
    Expression<String>? frozenDays,
    Expression<int>? earnbackValue,
    Expression<String>? earnbackUntil,
    Expression<String>? earnbackGap,
    Expression<String>? claimedMilestones,
    Expression<String>? lastEvaluated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (freezes != null) 'freezes': freezes,
      if (frozenDays != null) 'frozen_days': frozenDays,
      if (earnbackValue != null) 'earnback_value': earnbackValue,
      if (earnbackUntil != null) 'earnback_until': earnbackUntil,
      if (earnbackGap != null) 'earnback_gap': earnbackGap,
      if (claimedMilestones != null) 'claimed_milestones': claimedMilestones,
      if (lastEvaluated != null) 'last_evaluated': lastEvaluated,
    });
  }

  StreakStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? freezes,
    Value<String>? frozenDays,
    Value<int>? earnbackValue,
    Value<String?>? earnbackUntil,
    Value<String>? earnbackGap,
    Value<String>? claimedMilestones,
    Value<String?>? lastEvaluated,
  }) {
    return StreakStatesCompanion(
      id: id ?? this.id,
      freezes: freezes ?? this.freezes,
      frozenDays: frozenDays ?? this.frozenDays,
      earnbackValue: earnbackValue ?? this.earnbackValue,
      earnbackUntil: earnbackUntil ?? this.earnbackUntil,
      earnbackGap: earnbackGap ?? this.earnbackGap,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      lastEvaluated: lastEvaluated ?? this.lastEvaluated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (freezes.present) {
      map['freezes'] = Variable<int>(freezes.value);
    }
    if (frozenDays.present) {
      map['frozen_days'] = Variable<String>(frozenDays.value);
    }
    if (earnbackValue.present) {
      map['earnback_value'] = Variable<int>(earnbackValue.value);
    }
    if (earnbackUntil.present) {
      map['earnback_until'] = Variable<String>(earnbackUntil.value);
    }
    if (earnbackGap.present) {
      map['earnback_gap'] = Variable<String>(earnbackGap.value);
    }
    if (claimedMilestones.present) {
      map['claimed_milestones'] = Variable<String>(claimedMilestones.value);
    }
    if (lastEvaluated.present) {
      map['last_evaluated'] = Variable<String>(lastEvaluated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakStatesCompanion(')
          ..write('id: $id, ')
          ..write('freezes: $freezes, ')
          ..write('frozenDays: $frozenDays, ')
          ..write('earnbackValue: $earnbackValue, ')
          ..write('earnbackUntil: $earnbackUntil, ')
          ..write('earnbackGap: $earnbackGap, ')
          ..write('claimedMilestones: $claimedMilestones, ')
          ..write('lastEvaluated: $lastEvaluated')
          ..write(')'))
        .toString();
  }
}

class $AcornEntriesTable extends AcornEntries
    with TableInfo<$AcornEntriesTable, AcornEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcornEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, delta, reason, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'acorn_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcornEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcornEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcornEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AcornEntriesTable createAlias(String alias) {
    return $AcornEntriesTable(attachedDatabase, alias);
  }
}

class AcornEntry extends DataClass implements Insertable<AcornEntry> {
  final int id;
  final int delta;
  final String reason;
  final DateTime createdAt;
  const AcornEntry({
    required this.id,
    required this.delta,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['delta'] = Variable<int>(delta);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AcornEntriesCompanion toCompanion(bool nullToAbsent) {
    return AcornEntriesCompanion(
      id: Value(id),
      delta: Value(delta),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory AcornEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcornEntry(
      id: serializer.fromJson<int>(json['id']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AcornEntry copyWith({
    int? id,
    int? delta,
    String? reason,
    DateTime? createdAt,
  }) => AcornEntry(
    id: id ?? this.id,
    delta: delta ?? this.delta,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  AcornEntry copyWithCompanion(AcornEntriesCompanion data) {
    return AcornEntry(
      id: data.id.present ? data.id.value : this.id,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcornEntry(')
          ..write('id: $id, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, delta, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcornEntry &&
          other.id == this.id &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class AcornEntriesCompanion extends UpdateCompanion<AcornEntry> {
  final Value<int> id;
  final Value<int> delta;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  const AcornEntriesCompanion({
    this.id = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AcornEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int delta,
    required String reason,
    required DateTime createdAt,
  }) : delta = Value(delta),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<AcornEntry> custom({
    Expression<int>? id,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AcornEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? delta,
    Value<String>? reason,
    Value<DateTime>? createdAt,
  }) {
    return AcornEntriesCompanion(
      id: id ?? this.id,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcornEntriesCompanion(')
          ..write('id: $id, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuestClaimsTable extends QuestClaims
    with TableInfo<$QuestClaimsTable, QuestClaim> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimedAtMeta = const VerificationMeta(
    'claimedAt',
  );
  @override
  late final GeneratedColumn<DateTime> claimedAt = GeneratedColumn<DateTime>(
    'claimed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, slot, claimedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestClaim> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('claimed_at')) {
      context.handle(
        _claimedAtMeta,
        claimedAt.isAcceptableOrUnknown(data['claimed_at']!, _claimedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_claimedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, slot};
  @override
  QuestClaim map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestClaim(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      claimedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}claimed_at'],
      )!,
    );
  }

  @override
  $QuestClaimsTable createAlias(String alias) {
    return $QuestClaimsTable(attachedDatabase, alias);
  }
}

class QuestClaim extends DataClass implements Insertable<QuestClaim> {
  final String date;
  final int slot;
  final DateTime claimedAt;
  const QuestClaim({
    required this.date,
    required this.slot,
    required this.claimedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['slot'] = Variable<int>(slot);
    map['claimed_at'] = Variable<DateTime>(claimedAt);
    return map;
  }

  QuestClaimsCompanion toCompanion(bool nullToAbsent) {
    return QuestClaimsCompanion(
      date: Value(date),
      slot: Value(slot),
      claimedAt: Value(claimedAt),
    );
  }

  factory QuestClaim.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestClaim(
      date: serializer.fromJson<String>(json['date']),
      slot: serializer.fromJson<int>(json['slot']),
      claimedAt: serializer.fromJson<DateTime>(json['claimedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'slot': serializer.toJson<int>(slot),
      'claimedAt': serializer.toJson<DateTime>(claimedAt),
    };
  }

  QuestClaim copyWith({String? date, int? slot, DateTime? claimedAt}) =>
      QuestClaim(
        date: date ?? this.date,
        slot: slot ?? this.slot,
        claimedAt: claimedAt ?? this.claimedAt,
      );
  QuestClaim copyWithCompanion(QuestClaimsCompanion data) {
    return QuestClaim(
      date: data.date.present ? data.date.value : this.date,
      slot: data.slot.present ? data.slot.value : this.slot,
      claimedAt: data.claimedAt.present ? data.claimedAt.value : this.claimedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestClaim(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, slot, claimedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestClaim &&
          other.date == this.date &&
          other.slot == this.slot &&
          other.claimedAt == this.claimedAt);
}

class QuestClaimsCompanion extends UpdateCompanion<QuestClaim> {
  final Value<String> date;
  final Value<int> slot;
  final Value<DateTime> claimedAt;
  final Value<int> rowid;
  const QuestClaimsCompanion({
    this.date = const Value.absent(),
    this.slot = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestClaimsCompanion.insert({
    required String date,
    required int slot,
    required DateTime claimedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       slot = Value(slot),
       claimedAt = Value(claimedAt);
  static Insertable<QuestClaim> custom({
    Expression<String>? date,
    Expression<int>? slot,
    Expression<DateTime>? claimedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (slot != null) 'slot': slot,
      if (claimedAt != null) 'claimed_at': claimedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestClaimsCompanion copyWith({
    Value<String>? date,
    Value<int>? slot,
    Value<DateTime>? claimedAt,
    Value<int>? rowid,
  }) {
    return QuestClaimsCompanion(
      date: date ?? this.date,
      slot: slot ?? this.slot,
      claimedAt: claimedAt ?? this.claimedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (claimedAt.present) {
      map['claimed_at'] = Variable<DateTime>(claimedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestClaimsCompanion(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('claimedAt: $claimedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChestStatesTable extends ChestStates
    with TableInfo<$ChestStatesTable, ChestState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChestStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _earnedDateMeta = const VerificationMeta(
    'earnedDate',
  );
  @override
  late final GeneratedColumn<String> earnedDate = GeneratedColumn<String>(
    'earned_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedDateMeta = const VerificationMeta(
    'openedDate',
  );
  @override
  late final GeneratedColumn<String> openedDate = GeneratedColumn<String>(
    'opened_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, earnedDate, openedDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chest_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChestState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('earned_date')) {
      context.handle(
        _earnedDateMeta,
        earnedDate.isAcceptableOrUnknown(data['earned_date']!, _earnedDateMeta),
      );
    }
    if (data.containsKey('opened_date')) {
      context.handle(
        _openedDateMeta,
        openedDate.isAcceptableOrUnknown(data['opened_date']!, _openedDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChestState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChestState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      earnedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_date'],
      ),
      openedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_date'],
      ),
    );
  }

  @override
  $ChestStatesTable createAlias(String alias) {
    return $ChestStatesTable(attachedDatabase, alias);
  }
}

class ChestState extends DataClass implements Insertable<ChestState> {
  final int id;
  final String? earnedDate;
  final String? openedDate;
  const ChestState({required this.id, this.earnedDate, this.openedDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || earnedDate != null) {
      map['earned_date'] = Variable<String>(earnedDate);
    }
    if (!nullToAbsent || openedDate != null) {
      map['opened_date'] = Variable<String>(openedDate);
    }
    return map;
  }

  ChestStatesCompanion toCompanion(bool nullToAbsent) {
    return ChestStatesCompanion(
      id: Value(id),
      earnedDate: earnedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(earnedDate),
      openedDate: openedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(openedDate),
    );
  }

  factory ChestState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChestState(
      id: serializer.fromJson<int>(json['id']),
      earnedDate: serializer.fromJson<String?>(json['earnedDate']),
      openedDate: serializer.fromJson<String?>(json['openedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'earnedDate': serializer.toJson<String?>(earnedDate),
      'openedDate': serializer.toJson<String?>(openedDate),
    };
  }

  ChestState copyWith({
    int? id,
    Value<String?> earnedDate = const Value.absent(),
    Value<String?> openedDate = const Value.absent(),
  }) => ChestState(
    id: id ?? this.id,
    earnedDate: earnedDate.present ? earnedDate.value : this.earnedDate,
    openedDate: openedDate.present ? openedDate.value : this.openedDate,
  );
  ChestState copyWithCompanion(ChestStatesCompanion data) {
    return ChestState(
      id: data.id.present ? data.id.value : this.id,
      earnedDate: data.earnedDate.present
          ? data.earnedDate.value
          : this.earnedDate,
      openedDate: data.openedDate.present
          ? data.openedDate.value
          : this.openedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChestState(')
          ..write('id: $id, ')
          ..write('earnedDate: $earnedDate, ')
          ..write('openedDate: $openedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, earnedDate, openedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChestState &&
          other.id == this.id &&
          other.earnedDate == this.earnedDate &&
          other.openedDate == this.openedDate);
}

class ChestStatesCompanion extends UpdateCompanion<ChestState> {
  final Value<int> id;
  final Value<String?> earnedDate;
  final Value<String?> openedDate;
  const ChestStatesCompanion({
    this.id = const Value.absent(),
    this.earnedDate = const Value.absent(),
    this.openedDate = const Value.absent(),
  });
  ChestStatesCompanion.insert({
    this.id = const Value.absent(),
    this.earnedDate = const Value.absent(),
    this.openedDate = const Value.absent(),
  });
  static Insertable<ChestState> custom({
    Expression<int>? id,
    Expression<String>? earnedDate,
    Expression<String>? openedDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (earnedDate != null) 'earned_date': earnedDate,
      if (openedDate != null) 'opened_date': openedDate,
    });
  }

  ChestStatesCompanion copyWith({
    Value<int>? id,
    Value<String?>? earnedDate,
    Value<String?>? openedDate,
  }) {
    return ChestStatesCompanion(
      id: id ?? this.id,
      earnedDate: earnedDate ?? this.earnedDate,
      openedDate: openedDate ?? this.openedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (earnedDate.present) {
      map['earned_date'] = Variable<String>(earnedDate.value);
    }
    if (openedDate.present) {
      map['opened_date'] = Variable<String>(openedDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChestStatesCompanion(')
          ..write('id: $id, ')
          ..write('earnedDate: $earnedDate, ')
          ..write('openedDate: $openedDate')
          ..write(')'))
        .toString();
  }
}

class $LocalGoalsTable extends LocalGoals
    with TableInfo<$LocalGoalsTable, LocalGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🎯'),
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<String> deadline = GeneratedColumn<String>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmount,
    emoji,
    deadline,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deadline'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalGoalsTable createAlias(String alias) {
    return $LocalGoalsTable(attachedDatabase, alias);
  }
}

class LocalGoal extends DataClass implements Insertable<LocalGoal> {
  final String id;
  final String name;
  final double targetAmount;
  final String emoji;
  final String? deadline;
  final DateTime createdAt;
  const LocalGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.emoji,
    this.deadline,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<double>(targetAmount);
    map['emoji'] = Variable<String>(emoji);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<String>(deadline);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalGoalsCompanion toCompanion(bool nullToAbsent) {
    return LocalGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
      emoji: Value(emoji),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      createdAt: Value(createdAt),
    );
  }

  factory LocalGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGoal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      emoji: serializer.fromJson<String>(json['emoji']),
      deadline: serializer.fromJson<String?>(json['deadline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'emoji': serializer.toJson<String>(emoji),
      'deadline': serializer.toJson<String?>(deadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    String? emoji,
    Value<String?> deadline = const Value.absent(),
    DateTime? createdAt,
  }) => LocalGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    emoji: emoji ?? this.emoji,
    deadline: deadline.present ? deadline.value : this.deadline,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalGoal copyWithCompanion(LocalGoalsCompanion data) {
    return LocalGoal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGoal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('emoji: $emoji, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, targetAmount, emoji, deadline, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGoal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount &&
          other.emoji == this.emoji &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt);
}

class LocalGoalsCompanion extends UpdateCompanion<LocalGoal> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> targetAmount;
  final Value<String> emoji;
  final Value<String?> deadline;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.emoji = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGoalsCompanion.insert({
    required String id,
    required String name,
    required double targetAmount,
    this.emoji = const Value.absent(),
    this.deadline = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetAmount = Value(targetAmount),
       createdAt = Value(createdAt);
  static Insertable<LocalGoal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? targetAmount,
    Expression<String>? emoji,
    Expression<String>? deadline,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (emoji != null) 'emoji': emoji,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? targetAmount,
    Value<String>? emoji,
    Value<String?>? deadline,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      emoji: emoji ?? this.emoji,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<String>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('emoji: $emoji, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRecurringTable extends LocalRecurring
    with TableInfo<$LocalRecurringTable, LocalRecurringData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecurringTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<String> nextDueDate = GeneratedColumn<String>(
    'next_due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    merchant,
    amount,
    category,
    type,
    frequency,
    nextDueDate,
    active,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recurring';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecurringData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextDueDateMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRecurringData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecurringData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due_date'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalRecurringTable createAlias(String alias) {
    return $LocalRecurringTable(attachedDatabase, alias);
  }
}

class LocalRecurringData extends DataClass
    implements Insertable<LocalRecurringData> {
  final String id;
  final String merchant;
  final double amount;
  final String category;
  final String type;
  final String frequency;
  final String nextDueDate;
  final bool active;
  final DateTime createdAt;
  const LocalRecurringData({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.nextDueDate,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['merchant'] = Variable<String>(merchant);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    map['frequency'] = Variable<String>(frequency);
    map['next_due_date'] = Variable<String>(nextDueDate);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalRecurringCompanion toCompanion(bool nullToAbsent) {
    return LocalRecurringCompanion(
      id: Value(id),
      merchant: Value(merchant),
      amount: Value(amount),
      category: Value(category),
      type: Value(type),
      frequency: Value(frequency),
      nextDueDate: Value(nextDueDate),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory LocalRecurringData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecurringData(
      id: serializer.fromJson<String>(json['id']),
      merchant: serializer.fromJson<String>(json['merchant']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      frequency: serializer.fromJson<String>(json['frequency']),
      nextDueDate: serializer.fromJson<String>(json['nextDueDate']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'merchant': serializer.toJson<String>(merchant),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'frequency': serializer.toJson<String>(frequency),
      'nextDueDate': serializer.toJson<String>(nextDueDate),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalRecurringData copyWith({
    String? id,
    String? merchant,
    double? amount,
    String? category,
    String? type,
    String? frequency,
    String? nextDueDate,
    bool? active,
    DateTime? createdAt,
  }) => LocalRecurringData(
    id: id ?? this.id,
    merchant: merchant ?? this.merchant,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    frequency: frequency ?? this.frequency,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalRecurringData copyWithCompanion(LocalRecurringCompanion data) {
    return LocalRecurringData(
      id: data.id.present ? data.id.value : this.id,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringData(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('frequency: $frequency, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    merchant,
    amount,
    category,
    type,
    frequency,
    nextDueDate,
    active,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecurringData &&
          other.id == this.id &&
          other.merchant == this.merchant &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.type == this.type &&
          other.frequency == this.frequency &&
          other.nextDueDate == this.nextDueDate &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class LocalRecurringCompanion extends UpdateCompanion<LocalRecurringData> {
  final Value<String> id;
  final Value<String> merchant;
  final Value<double> amount;
  final Value<String> category;
  final Value<String> type;
  final Value<String> frequency;
  final Value<String> nextDueDate;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalRecurringCompanion({
    this.id = const Value.absent(),
    this.merchant = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecurringCompanion.insert({
    required String id,
    required String merchant,
    required double amount,
    required String category,
    this.type = const Value.absent(),
    this.frequency = const Value.absent(),
    required String nextDueDate,
    this.active = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       merchant = Value(merchant),
       amount = Value(amount),
       category = Value(category),
       nextDueDate = Value(nextDueDate),
       createdAt = Value(createdAt);
  static Insertable<LocalRecurringData> custom({
    Expression<String>? id,
    Expression<String>? merchant,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? frequency,
    Expression<String>? nextDueDate,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchant != null) 'merchant': merchant,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (frequency != null) 'frequency': frequency,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecurringCompanion copyWith({
    Value<String>? id,
    Value<String>? merchant,
    Value<double>? amount,
    Value<String>? category,
    Value<String>? type,
    Value<String>? frequency,
    Value<String>? nextDueDate,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalRecurringCompanion(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<String>(nextDueDate.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringCompanion(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('frequency: $frequency, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressRowsTable extends LessonProgressRows
    with TableInfo<$LessonProgressRowsTable, LessonProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lessonId, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressRow(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $LessonProgressRowsTable createAlias(String alias) {
    return $LessonProgressRowsTable(attachedDatabase, alias);
  }
}

class LessonProgressRow extends DataClass
    implements Insertable<LessonProgressRow> {
  final String lessonId;
  final DateTime completedAt;
  const LessonProgressRow({required this.lessonId, required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  LessonProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressRowsCompanion(
      lessonId: Value(lessonId),
      completedAt: Value(completedAt),
    );
  }

  factory LessonProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressRow(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  LessonProgressRow copyWith({String? lessonId, DateTime? completedAt}) =>
      LessonProgressRow(
        lessonId: lessonId ?? this.lessonId,
        completedAt: completedAt ?? this.completedAt,
      );
  LessonProgressRow copyWithCompanion(LessonProgressRowsCompanion data) {
    return LessonProgressRow(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRow(')
          ..write('lessonId: $lessonId, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressRow &&
          other.lessonId == this.lessonId &&
          other.completedAt == this.completedAt);
}

class LessonProgressRowsCompanion extends UpdateCompanion<LessonProgressRow> {
  final Value<String> lessonId;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const LessonProgressRowsCompanion({
    this.lessonId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressRowsCompanion.insert({
    required String lessonId,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       completedAt = Value(completedAt);
  static Insertable<LessonProgressRow> custom({
    Expression<String>? lessonId,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressRowsCompanion copyWith({
    Value<String>? lessonId,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return LessonProgressRowsCompanion(
      lessonId: lessonId ?? this.lessonId,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRowsCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewCardsTable extends ReviewCards
    with TableInfo<$ReviewCardsTable, ReviewCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nextDueMeta = const VerificationMeta(
    'nextDue',
  );
  @override
  late final GeneratedColumn<String> nextDue = GeneratedColumn<String>(
    'next_due',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<String> lastReview = GeneratedColumn<String>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    lessonId,
    box,
    nextDue,
    lapses,
    stability,
    difficulty,
    lastReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    }
    if (data.containsKey('next_due')) {
      context.handle(
        _nextDueMeta,
        nextDue.isAcceptableOrUnknown(data['next_due']!, _nextDueMeta),
      );
    } else if (isInserting) {
      context.missing(_nextDueMeta);
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  ReviewCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewCard(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      nextDue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_review'],
      ),
    );
  }

  @override
  $ReviewCardsTable createAlias(String alias) {
    return $ReviewCardsTable(attachedDatabase, alias);
  }
}

class ReviewCard extends DataClass implements Insertable<ReviewCard> {
  final String cardId;
  final String lessonId;
  final int box;
  final String nextDue;
  final int lapses;

  /// NULL = card moștenit, neatins încă de FSRS. `lastReview` e day-key `yyyy-MM-dd`.
  final double? stability;
  final double? difficulty;
  final String? lastReview;
  const ReviewCard({
    required this.cardId,
    required this.lessonId,
    required this.box,
    required this.nextDue,
    required this.lapses,
    this.stability,
    this.difficulty,
    this.lastReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['box'] = Variable<int>(box);
    map['next_due'] = Variable<String>(nextDue);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<String>(lastReview);
    }
    return map;
  }

  ReviewCardsCompanion toCompanion(bool nullToAbsent) {
    return ReviewCardsCompanion(
      cardId: Value(cardId),
      lessonId: Value(lessonId),
      box: Value(box),
      nextDue: Value(nextDue),
      lapses: Value(lapses),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
    );
  }

  factory ReviewCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewCard(
      cardId: serializer.fromJson<String>(json['cardId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      box: serializer.fromJson<int>(json['box']),
      nextDue: serializer.fromJson<String>(json['nextDue']),
      lapses: serializer.fromJson<int>(json['lapses']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      lastReview: serializer.fromJson<String?>(json['lastReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'lessonId': serializer.toJson<String>(lessonId),
      'box': serializer.toJson<int>(box),
      'nextDue': serializer.toJson<String>(nextDue),
      'lapses': serializer.toJson<int>(lapses),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'lastReview': serializer.toJson<String?>(lastReview),
    };
  }

  ReviewCard copyWith({
    String? cardId,
    String? lessonId,
    int? box,
    String? nextDue,
    int? lapses,
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    Value<String?> lastReview = const Value.absent(),
  }) => ReviewCard(
    cardId: cardId ?? this.cardId,
    lessonId: lessonId ?? this.lessonId,
    box: box ?? this.box,
    nextDue: nextDue ?? this.nextDue,
    lapses: lapses ?? this.lapses,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
  );
  ReviewCard copyWithCompanion(ReviewCardsCompanion data) {
    return ReviewCard(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      box: data.box.present ? data.box.value : this.box,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCard(')
          ..write('cardId: $cardId, ')
          ..write('lessonId: $lessonId, ')
          ..write('box: $box, ')
          ..write('nextDue: $nextDue, ')
          ..write('lapses: $lapses, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('lastReview: $lastReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    lessonId,
    box,
    nextDue,
    lapses,
    stability,
    difficulty,
    lastReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewCard &&
          other.cardId == this.cardId &&
          other.lessonId == this.lessonId &&
          other.box == this.box &&
          other.nextDue == this.nextDue &&
          other.lapses == this.lapses &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.lastReview == this.lastReview);
}

class ReviewCardsCompanion extends UpdateCompanion<ReviewCard> {
  final Value<String> cardId;
  final Value<String> lessonId;
  final Value<int> box;
  final Value<String> nextDue;
  final Value<int> lapses;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<String?> lastReview;
  final Value<int> rowid;
  const ReviewCardsCompanion({
    this.cardId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.box = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.lapses = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewCardsCompanion.insert({
    required String cardId,
    required String lessonId,
    this.box = const Value.absent(),
    required String nextDue,
    this.lapses = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       lessonId = Value(lessonId),
       nextDue = Value(nextDue);
  static Insertable<ReviewCard> custom({
    Expression<String>? cardId,
    Expression<String>? lessonId,
    Expression<int>? box,
    Expression<String>? nextDue,
    Expression<int>? lapses,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<String>? lastReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (box != null) 'box': box,
      if (nextDue != null) 'next_due': nextDue,
      if (lapses != null) 'lapses': lapses,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (lastReview != null) 'last_review': lastReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewCardsCompanion copyWith({
    Value<String>? cardId,
    Value<String>? lessonId,
    Value<int>? box,
    Value<String>? nextDue,
    Value<int>? lapses,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<String?>? lastReview,
    Value<int>? rowid,
  }) {
    return ReviewCardsCompanion(
      cardId: cardId ?? this.cardId,
      lessonId: lessonId ?? this.lessonId,
      box: box ?? this.box,
      nextDue: nextDue ?? this.nextDue,
      lapses: lapses ?? this.lapses,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      lastReview: lastReview ?? this.lastReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<String>(nextDue.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<String>(lastReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('lessonId: $lessonId, ')
          ..write('box: $box, ')
          ..write('nextDue: $nextDue, ')
          ..write('lapses: $lapses, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('lastReview: $lastReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArcadeRoundsTable extends ArcadeRounds
    with TableInfo<$ArcadeRoundsTable, ArcadeRound> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArcadeRoundsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metaMeta = const VerificationMeta('meta');
  @override
  late final GeneratedColumn<String> meta = GeneratedColumn<String>(
    'meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, game, date, score, meta];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arcade_rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArcadeRound> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game')) {
      context.handle(
        _gameMeta,
        game.isAcceptableOrUnknown(data['game']!, _gameMeta),
      );
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('meta')) {
      context.handle(
        _metaMeta,
        meta.isAcceptableOrUnknown(data['meta']!, _metaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArcadeRound map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArcadeRound(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      game: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      )!,
    );
  }

  @override
  $ArcadeRoundsTable createAlias(String alias) {
    return $ArcadeRoundsTable(attachedDatabase, alias);
  }
}

class ArcadeRound extends DataClass implements Insertable<ArcadeRound> {
  final int id;
  final String game;
  final String date;
  final int score;
  final String meta;
  const ArcadeRound({
    required this.id,
    required this.game,
    required this.date,
    required this.score,
    required this.meta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game'] = Variable<String>(game);
    map['date'] = Variable<String>(date);
    map['score'] = Variable<int>(score);
    map['meta'] = Variable<String>(meta);
    return map;
  }

  ArcadeRoundsCompanion toCompanion(bool nullToAbsent) {
    return ArcadeRoundsCompanion(
      id: Value(id),
      game: Value(game),
      date: Value(date),
      score: Value(score),
      meta: Value(meta),
    );
  }

  factory ArcadeRound.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArcadeRound(
      id: serializer.fromJson<int>(json['id']),
      game: serializer.fromJson<String>(json['game']),
      date: serializer.fromJson<String>(json['date']),
      score: serializer.fromJson<int>(json['score']),
      meta: serializer.fromJson<String>(json['meta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'game': serializer.toJson<String>(game),
      'date': serializer.toJson<String>(date),
      'score': serializer.toJson<int>(score),
      'meta': serializer.toJson<String>(meta),
    };
  }

  ArcadeRound copyWith({
    int? id,
    String? game,
    String? date,
    int? score,
    String? meta,
  }) => ArcadeRound(
    id: id ?? this.id,
    game: game ?? this.game,
    date: date ?? this.date,
    score: score ?? this.score,
    meta: meta ?? this.meta,
  );
  ArcadeRound copyWithCompanion(ArcadeRoundsCompanion data) {
    return ArcadeRound(
      id: data.id.present ? data.id.value : this.id,
      game: data.game.present ? data.game.value : this.game,
      date: data.date.present ? data.date.value : this.date,
      score: data.score.present ? data.score.value : this.score,
      meta: data.meta.present ? data.meta.value : this.meta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArcadeRound(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('date: $date, ')
          ..write('score: $score, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, game, date, score, meta);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArcadeRound &&
          other.id == this.id &&
          other.game == this.game &&
          other.date == this.date &&
          other.score == this.score &&
          other.meta == this.meta);
}

class ArcadeRoundsCompanion extends UpdateCompanion<ArcadeRound> {
  final Value<int> id;
  final Value<String> game;
  final Value<String> date;
  final Value<int> score;
  final Value<String> meta;
  const ArcadeRoundsCompanion({
    this.id = const Value.absent(),
    this.game = const Value.absent(),
    this.date = const Value.absent(),
    this.score = const Value.absent(),
    this.meta = const Value.absent(),
  });
  ArcadeRoundsCompanion.insert({
    this.id = const Value.absent(),
    required String game,
    required String date,
    required int score,
    this.meta = const Value.absent(),
  }) : game = Value(game),
       date = Value(date),
       score = Value(score);
  static Insertable<ArcadeRound> custom({
    Expression<int>? id,
    Expression<String>? game,
    Expression<String>? date,
    Expression<int>? score,
    Expression<String>? meta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (game != null) 'game': game,
      if (date != null) 'date': date,
      if (score != null) 'score': score,
      if (meta != null) 'meta': meta,
    });
  }

  ArcadeRoundsCompanion copyWith({
    Value<int>? id,
    Value<String>? game,
    Value<String>? date,
    Value<int>? score,
    Value<String>? meta,
  }) {
    return ArcadeRoundsCompanion(
      id: id ?? this.id,
      game: game ?? this.game,
      date: date ?? this.date,
      score: score ?? this.score,
      meta: meta ?? this.meta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (game.present) {
      map['game'] = Variable<String>(game.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArcadeRoundsCompanion(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('date: $date, ')
          ..write('score: $score, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }
}

class $DojoStatesTable extends DojoStates
    with TableInfo<$DojoStatesTable, DojoState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DojoStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, rating, rounds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dojo_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<DojoState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('rounds')) {
      context.handle(
        _roundsMeta,
        rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DojoState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DojoState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      rounds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds'],
      )!,
    );
  }

  @override
  $DojoStatesTable createAlias(String alias) {
    return $DojoStatesTable(attachedDatabase, alias);
  }
}

class DojoState extends DataClass implements Insertable<DojoState> {
  final int id;
  final int rating;
  final int rounds;
  const DojoState({
    required this.id,
    required this.rating,
    required this.rounds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rating'] = Variable<int>(rating);
    map['rounds'] = Variable<int>(rounds);
    return map;
  }

  DojoStatesCompanion toCompanion(bool nullToAbsent) {
    return DojoStatesCompanion(
      id: Value(id),
      rating: Value(rating),
      rounds: Value(rounds),
    );
  }

  factory DojoState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DojoState(
      id: serializer.fromJson<int>(json['id']),
      rating: serializer.fromJson<int>(json['rating']),
      rounds: serializer.fromJson<int>(json['rounds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rating': serializer.toJson<int>(rating),
      'rounds': serializer.toJson<int>(rounds),
    };
  }

  DojoState copyWith({int? id, int? rating, int? rounds}) => DojoState(
    id: id ?? this.id,
    rating: rating ?? this.rating,
    rounds: rounds ?? this.rounds,
  );
  DojoState copyWithCompanion(DojoStatesCompanion data) {
    return DojoState(
      id: data.id.present ? data.id.value : this.id,
      rating: data.rating.present ? data.rating.value : this.rating,
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DojoState(')
          ..write('id: $id, ')
          ..write('rating: $rating, ')
          ..write('rounds: $rounds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rating, rounds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DojoState &&
          other.id == this.id &&
          other.rating == this.rating &&
          other.rounds == this.rounds);
}

class DojoStatesCompanion extends UpdateCompanion<DojoState> {
  final Value<int> id;
  final Value<int> rating;
  final Value<int> rounds;
  const DojoStatesCompanion({
    this.id = const Value.absent(),
    this.rating = const Value.absent(),
    this.rounds = const Value.absent(),
  });
  DojoStatesCompanion.insert({
    this.id = const Value.absent(),
    this.rating = const Value.absent(),
    this.rounds = const Value.absent(),
  });
  static Insertable<DojoState> custom({
    Expression<int>? id,
    Expression<int>? rating,
    Expression<int>? rounds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rating != null) 'rating': rating,
      if (rounds != null) 'rounds': rounds,
    });
  }

  DojoStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? rating,
    Value<int>? rounds,
  }) {
    return DojoStatesCompanion(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      rounds: rounds ?? this.rounds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DojoStatesCompanion(')
          ..write('id: $id, ')
          ..write('rating: $rating, ')
          ..write('rounds: $rounds')
          ..write(')'))
        .toString();
  }
}

class $DojoItemStatsTable extends DojoItemStats
    with TableInfo<$DojoItemStatsTable, DojoItemStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DojoItemStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playsMeta = const VerificationMeta('plays');
  @override
  late final GeneratedColumn<int> plays = GeneratedColumn<int>(
    'plays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeenRoundMeta = const VerificationMeta(
    'lastSeenRound',
  );
  @override
  late final GeneratedColumn<int> lastSeenRound = GeneratedColumn<int>(
    'last_seen_round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    rating,
    plays,
    correct,
    lastSeenRound,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dojo_item_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DojoItemStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('plays')) {
      context.handle(
        _playsMeta,
        plays.isAcceptableOrUnknown(data['plays']!, _playsMeta),
      );
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    }
    if (data.containsKey('last_seen_round')) {
      context.handle(
        _lastSeenRoundMeta,
        lastSeenRound.isAcceptableOrUnknown(
          data['last_seen_round']!,
          _lastSeenRoundMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  DojoItemStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DojoItemStat(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      plays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plays'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      lastSeenRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_round'],
      )!,
    );
  }

  @override
  $DojoItemStatsTable createAlias(String alias) {
    return $DojoItemStatsTable(attachedDatabase, alias);
  }
}

class DojoItemStat extends DataClass implements Insertable<DojoItemStat> {
  final String itemId;
  final int rating;
  final int plays;
  final int correct;
  final int lastSeenRound;
  const DojoItemStat({
    required this.itemId,
    required this.rating,
    required this.plays,
    required this.correct,
    required this.lastSeenRound,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['rating'] = Variable<int>(rating);
    map['plays'] = Variable<int>(plays);
    map['correct'] = Variable<int>(correct);
    map['last_seen_round'] = Variable<int>(lastSeenRound);
    return map;
  }

  DojoItemStatsCompanion toCompanion(bool nullToAbsent) {
    return DojoItemStatsCompanion(
      itemId: Value(itemId),
      rating: Value(rating),
      plays: Value(plays),
      correct: Value(correct),
      lastSeenRound: Value(lastSeenRound),
    );
  }

  factory DojoItemStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DojoItemStat(
      itemId: serializer.fromJson<String>(json['itemId']),
      rating: serializer.fromJson<int>(json['rating']),
      plays: serializer.fromJson<int>(json['plays']),
      correct: serializer.fromJson<int>(json['correct']),
      lastSeenRound: serializer.fromJson<int>(json['lastSeenRound']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'rating': serializer.toJson<int>(rating),
      'plays': serializer.toJson<int>(plays),
      'correct': serializer.toJson<int>(correct),
      'lastSeenRound': serializer.toJson<int>(lastSeenRound),
    };
  }

  DojoItemStat copyWith({
    String? itemId,
    int? rating,
    int? plays,
    int? correct,
    int? lastSeenRound,
  }) => DojoItemStat(
    itemId: itemId ?? this.itemId,
    rating: rating ?? this.rating,
    plays: plays ?? this.plays,
    correct: correct ?? this.correct,
    lastSeenRound: lastSeenRound ?? this.lastSeenRound,
  );
  DojoItemStat copyWithCompanion(DojoItemStatsCompanion data) {
    return DojoItemStat(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      rating: data.rating.present ? data.rating.value : this.rating,
      plays: data.plays.present ? data.plays.value : this.plays,
      correct: data.correct.present ? data.correct.value : this.correct,
      lastSeenRound: data.lastSeenRound.present
          ? data.lastSeenRound.value
          : this.lastSeenRound,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DojoItemStat(')
          ..write('itemId: $itemId, ')
          ..write('rating: $rating, ')
          ..write('plays: $plays, ')
          ..write('correct: $correct, ')
          ..write('lastSeenRound: $lastSeenRound')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, rating, plays, correct, lastSeenRound);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DojoItemStat &&
          other.itemId == this.itemId &&
          other.rating == this.rating &&
          other.plays == this.plays &&
          other.correct == this.correct &&
          other.lastSeenRound == this.lastSeenRound);
}

class DojoItemStatsCompanion extends UpdateCompanion<DojoItemStat> {
  final Value<String> itemId;
  final Value<int> rating;
  final Value<int> plays;
  final Value<int> correct;
  final Value<int> lastSeenRound;
  final Value<int> rowid;
  const DojoItemStatsCompanion({
    this.itemId = const Value.absent(),
    this.rating = const Value.absent(),
    this.plays = const Value.absent(),
    this.correct = const Value.absent(),
    this.lastSeenRound = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DojoItemStatsCompanion.insert({
    required String itemId,
    required int rating,
    this.plays = const Value.absent(),
    this.correct = const Value.absent(),
    this.lastSeenRound = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       rating = Value(rating);
  static Insertable<DojoItemStat> custom({
    Expression<String>? itemId,
    Expression<int>? rating,
    Expression<int>? plays,
    Expression<int>? correct,
    Expression<int>? lastSeenRound,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (rating != null) 'rating': rating,
      if (plays != null) 'plays': plays,
      if (correct != null) 'correct': correct,
      if (lastSeenRound != null) 'last_seen_round': lastSeenRound,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DojoItemStatsCompanion copyWith({
    Value<String>? itemId,
    Value<int>? rating,
    Value<int>? plays,
    Value<int>? correct,
    Value<int>? lastSeenRound,
    Value<int>? rowid,
  }) {
    return DojoItemStatsCompanion(
      itemId: itemId ?? this.itemId,
      rating: rating ?? this.rating,
      plays: plays ?? this.plays,
      correct: correct ?? this.correct,
      lastSeenRound: lastSeenRound ?? this.lastSeenRound,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (plays.present) {
      map['plays'] = Variable<int>(plays.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (lastSeenRound.present) {
      map['last_seen_round'] = Variable<int>(lastSeenRound.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DojoItemStatsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('rating: $rating, ')
          ..write('plays: $plays, ')
          ..write('correct: $correct, ')
          ..write('lastSeenRound: $lastSeenRound, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardrobeItemsTable extends WardrobeItems
    with TableInfo<$WardrobeItemsTable, WardrobeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acquiredAtMeta = const VerificationMeta(
    'acquiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> acquiredAt = GeneratedColumn<DateTime>(
    'acquired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, acquiredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wardrobe_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WardrobeItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
        _acquiredAtMeta,
        acquiredAt.isAcceptableOrUnknown(data['acquired_at']!, _acquiredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  WardrobeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeItem(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      acquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acquired_at'],
      )!,
    );
  }

  @override
  $WardrobeItemsTable createAlias(String alias) {
    return $WardrobeItemsTable(attachedDatabase, alias);
  }
}

class WardrobeItem extends DataClass implements Insertable<WardrobeItem> {
  final String itemId;
  final DateTime acquiredAt;
  const WardrobeItem({required this.itemId, required this.acquiredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['acquired_at'] = Variable<DateTime>(acquiredAt);
    return map;
  }

  WardrobeItemsCompanion toCompanion(bool nullToAbsent) {
    return WardrobeItemsCompanion(
      itemId: Value(itemId),
      acquiredAt: Value(acquiredAt),
    );
  }

  factory WardrobeItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeItem(
      itemId: serializer.fromJson<String>(json['itemId']),
      acquiredAt: serializer.fromJson<DateTime>(json['acquiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'acquiredAt': serializer.toJson<DateTime>(acquiredAt),
    };
  }

  WardrobeItem copyWith({String? itemId, DateTime? acquiredAt}) => WardrobeItem(
    itemId: itemId ?? this.itemId,
    acquiredAt: acquiredAt ?? this.acquiredAt,
  );
  WardrobeItem copyWithCompanion(WardrobeItemsCompanion data) {
    return WardrobeItem(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      acquiredAt: data.acquiredAt.present
          ? data.acquiredAt.value
          : this.acquiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeItem(')
          ..write('itemId: $itemId, ')
          ..write('acquiredAt: $acquiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, acquiredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeItem &&
          other.itemId == this.itemId &&
          other.acquiredAt == this.acquiredAt);
}

class WardrobeItemsCompanion extends UpdateCompanion<WardrobeItem> {
  final Value<String> itemId;
  final Value<DateTime> acquiredAt;
  final Value<int> rowid;
  const WardrobeItemsCompanion({
    this.itemId = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardrobeItemsCompanion.insert({
    required String itemId,
    required DateTime acquiredAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       acquiredAt = Value(acquiredAt);
  static Insertable<WardrobeItem> custom({
    Expression<String>? itemId,
    Expression<DateTime>? acquiredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardrobeItemsCompanion copyWith({
    Value<String>? itemId,
    Value<DateTime>? acquiredAt,
    Value<int>? rowid,
  }) {
    return WardrobeItemsCompanion(
      itemId: itemId ?? this.itemId,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<DateTime>(acquiredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeItemsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsightEventsTable extends InsightEvents
    with TableInfo<$InsightEventsTable, InsightEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsightEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _insightIdMeta = const VerificationMeta(
    'insightId',
  );
  @override
  late final GeneratedColumn<String> insightId = GeneratedColumn<String>(
    'insight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleKeyMeta = const VerificationMeta(
    'ruleKey',
  );
  @override
  late final GeneratedColumn<String> ruleKey = GeneratedColumn<String>(
    'rule_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventMeta = const VerificationMeta('event');
  @override
  late final GeneratedColumn<String> event = GeneratedColumn<String>(
    'event',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _armMeta = const VerificationMeta('arm');
  @override
  late final GeneratedColumn<int> arm = GeneratedColumn<int>(
    'arm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _propensityMeta = const VerificationMeta(
    'propensity',
  );
  @override
  late final GeneratedColumn<double> propensity = GeneratedColumn<double>(
    'propensity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    insightId,
    ruleKey,
    kind,
    event,
    createdAt,
    arm,
    propensity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insight_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<InsightEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('insight_id')) {
      context.handle(
        _insightIdMeta,
        insightId.isAcceptableOrUnknown(data['insight_id']!, _insightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_insightIdMeta);
    }
    if (data.containsKey('rule_key')) {
      context.handle(
        _ruleKeyMeta,
        ruleKey.isAcceptableOrUnknown(data['rule_key']!, _ruleKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('event')) {
      context.handle(
        _eventMeta,
        event.isAcceptableOrUnknown(data['event']!, _eventMeta),
      );
    } else if (isInserting) {
      context.missing(_eventMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('arm')) {
      context.handle(
        _armMeta,
        arm.isAcceptableOrUnknown(data['arm']!, _armMeta),
      );
    }
    if (data.containsKey('propensity')) {
      context.handle(
        _propensityMeta,
        propensity.isAcceptableOrUnknown(data['propensity']!, _propensityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InsightEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsightEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      insightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_id'],
      )!,
      ruleKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      event: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      arm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arm'],
      ),
      propensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}propensity'],
      ),
    );
  }

  @override
  $InsightEventsTable createAlias(String alias) {
    return $InsightEventsTable(attachedDatabase, alias);
  }
}

class InsightEvent extends DataClass implements Insertable<InsightEvent> {
  final int id;
  final String insightId;
  final String ruleKey;
  final String kind;
  final String event;
  final DateTime createdAt;

  /// Brațul de bandit ales pentru varianta afișată și propensity-ul asociat.
  /// Rămân NULL când personalizarea e oprită, istoricul vechi nu se atinge.
  final int? arm;
  final double? propensity;
  const InsightEvent({
    required this.id,
    required this.insightId,
    required this.ruleKey,
    required this.kind,
    required this.event,
    required this.createdAt,
    this.arm,
    this.propensity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['insight_id'] = Variable<String>(insightId);
    map['rule_key'] = Variable<String>(ruleKey);
    map['kind'] = Variable<String>(kind);
    map['event'] = Variable<String>(event);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || arm != null) {
      map['arm'] = Variable<int>(arm);
    }
    if (!nullToAbsent || propensity != null) {
      map['propensity'] = Variable<double>(propensity);
    }
    return map;
  }

  InsightEventsCompanion toCompanion(bool nullToAbsent) {
    return InsightEventsCompanion(
      id: Value(id),
      insightId: Value(insightId),
      ruleKey: Value(ruleKey),
      kind: Value(kind),
      event: Value(event),
      createdAt: Value(createdAt),
      arm: arm == null && nullToAbsent ? const Value.absent() : Value(arm),
      propensity: propensity == null && nullToAbsent
          ? const Value.absent()
          : Value(propensity),
    );
  }

  factory InsightEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsightEvent(
      id: serializer.fromJson<int>(json['id']),
      insightId: serializer.fromJson<String>(json['insightId']),
      ruleKey: serializer.fromJson<String>(json['ruleKey']),
      kind: serializer.fromJson<String>(json['kind']),
      event: serializer.fromJson<String>(json['event']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      arm: serializer.fromJson<int?>(json['arm']),
      propensity: serializer.fromJson<double?>(json['propensity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'insightId': serializer.toJson<String>(insightId),
      'ruleKey': serializer.toJson<String>(ruleKey),
      'kind': serializer.toJson<String>(kind),
      'event': serializer.toJson<String>(event),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'arm': serializer.toJson<int?>(arm),
      'propensity': serializer.toJson<double?>(propensity),
    };
  }

  InsightEvent copyWith({
    int? id,
    String? insightId,
    String? ruleKey,
    String? kind,
    String? event,
    DateTime? createdAt,
    Value<int?> arm = const Value.absent(),
    Value<double?> propensity = const Value.absent(),
  }) => InsightEvent(
    id: id ?? this.id,
    insightId: insightId ?? this.insightId,
    ruleKey: ruleKey ?? this.ruleKey,
    kind: kind ?? this.kind,
    event: event ?? this.event,
    createdAt: createdAt ?? this.createdAt,
    arm: arm.present ? arm.value : this.arm,
    propensity: propensity.present ? propensity.value : this.propensity,
  );
  InsightEvent copyWithCompanion(InsightEventsCompanion data) {
    return InsightEvent(
      id: data.id.present ? data.id.value : this.id,
      insightId: data.insightId.present ? data.insightId.value : this.insightId,
      ruleKey: data.ruleKey.present ? data.ruleKey.value : this.ruleKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      event: data.event.present ? data.event.value : this.event,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      arm: data.arm.present ? data.arm.value : this.arm,
      propensity: data.propensity.present
          ? data.propensity.value
          : this.propensity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InsightEvent(')
          ..write('id: $id, ')
          ..write('insightId: $insightId, ')
          ..write('ruleKey: $ruleKey, ')
          ..write('kind: $kind, ')
          ..write('event: $event, ')
          ..write('createdAt: $createdAt, ')
          ..write('arm: $arm, ')
          ..write('propensity: $propensity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    insightId,
    ruleKey,
    kind,
    event,
    createdAt,
    arm,
    propensity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsightEvent &&
          other.id == this.id &&
          other.insightId == this.insightId &&
          other.ruleKey == this.ruleKey &&
          other.kind == this.kind &&
          other.event == this.event &&
          other.createdAt == this.createdAt &&
          other.arm == this.arm &&
          other.propensity == this.propensity);
}

class InsightEventsCompanion extends UpdateCompanion<InsightEvent> {
  final Value<int> id;
  final Value<String> insightId;
  final Value<String> ruleKey;
  final Value<String> kind;
  final Value<String> event;
  final Value<DateTime> createdAt;
  final Value<int?> arm;
  final Value<double?> propensity;
  const InsightEventsCompanion({
    this.id = const Value.absent(),
    this.insightId = const Value.absent(),
    this.ruleKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.event = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.arm = const Value.absent(),
    this.propensity = const Value.absent(),
  });
  InsightEventsCompanion.insert({
    this.id = const Value.absent(),
    required String insightId,
    required String ruleKey,
    required String kind,
    required String event,
    required DateTime createdAt,
    this.arm = const Value.absent(),
    this.propensity = const Value.absent(),
  }) : insightId = Value(insightId),
       ruleKey = Value(ruleKey),
       kind = Value(kind),
       event = Value(event),
       createdAt = Value(createdAt);
  static Insertable<InsightEvent> custom({
    Expression<int>? id,
    Expression<String>? insightId,
    Expression<String>? ruleKey,
    Expression<String>? kind,
    Expression<String>? event,
    Expression<DateTime>? createdAt,
    Expression<int>? arm,
    Expression<double>? propensity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (insightId != null) 'insight_id': insightId,
      if (ruleKey != null) 'rule_key': ruleKey,
      if (kind != null) 'kind': kind,
      if (event != null) 'event': event,
      if (createdAt != null) 'created_at': createdAt,
      if (arm != null) 'arm': arm,
      if (propensity != null) 'propensity': propensity,
    });
  }

  InsightEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? insightId,
    Value<String>? ruleKey,
    Value<String>? kind,
    Value<String>? event,
    Value<DateTime>? createdAt,
    Value<int?>? arm,
    Value<double?>? propensity,
  }) {
    return InsightEventsCompanion(
      id: id ?? this.id,
      insightId: insightId ?? this.insightId,
      ruleKey: ruleKey ?? this.ruleKey,
      kind: kind ?? this.kind,
      event: event ?? this.event,
      createdAt: createdAt ?? this.createdAt,
      arm: arm ?? this.arm,
      propensity: propensity ?? this.propensity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (insightId.present) {
      map['insight_id'] = Variable<String>(insightId.value);
    }
    if (ruleKey.present) {
      map['rule_key'] = Variable<String>(ruleKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (event.present) {
      map['event'] = Variable<String>(event.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (arm.present) {
      map['arm'] = Variable<int>(arm.value);
    }
    if (propensity.present) {
      map['propensity'] = Variable<double>(propensity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsightEventsCompanion(')
          ..write('id: $id, ')
          ..write('insightId: $insightId, ')
          ..write('ruleKey: $ruleKey, ')
          ..write('kind: $kind, ')
          ..write('event: $event, ')
          ..write('createdAt: $createdAt, ')
          ..write('arm: $arm, ')
          ..write('propensity: $propensity')
          ..write(')'))
        .toString();
  }
}

class $ExpeditionRowsTable extends ExpeditionRows
    with TableInfo<$ExpeditionRowsTable, ExpeditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpeditionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departedAtMeta = const VerificationMeta(
    'departedAt',
  );
  @override
  late final GeneratedColumn<DateTime> departedAt = GeneratedColumn<DateTime>(
    'departed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rewardMeta = const VerificationMeta('reward');
  @override
  late final GeneratedColumn<int> reward = GeneratedColumn<int>(
    'reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, departedAt, collectedAt, reward];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expedition_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpeditionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('departed_at')) {
      context.handle(
        _departedAtMeta,
        departedAt.isAcceptableOrUnknown(data['departed_at']!, _departedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_departedAtMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    }
    if (data.containsKey('reward')) {
      context.handle(
        _rewardMeta,
        reward.isAcceptableOrUnknown(data['reward']!, _rewardMeta),
      );
    } else if (isInserting) {
      context.missing(_rewardMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  ExpeditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpeditionRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      departedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}departed_at'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      ),
      reward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward'],
      )!,
    );
  }

  @override
  $ExpeditionRowsTable createAlias(String alias) {
    return $ExpeditionRowsTable(attachedDatabase, alias);
  }
}

class ExpeditionRow extends DataClass implements Insertable<ExpeditionRow> {
  final String day;
  final DateTime departedAt;
  final DateTime? collectedAt;
  final int reward;
  const ExpeditionRow({
    required this.day,
    required this.departedAt,
    this.collectedAt,
    required this.reward,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['departed_at'] = Variable<DateTime>(departedAt);
    if (!nullToAbsent || collectedAt != null) {
      map['collected_at'] = Variable<DateTime>(collectedAt);
    }
    map['reward'] = Variable<int>(reward);
    return map;
  }

  ExpeditionRowsCompanion toCompanion(bool nullToAbsent) {
    return ExpeditionRowsCompanion(
      day: Value(day),
      departedAt: Value(departedAt),
      collectedAt: collectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(collectedAt),
      reward: Value(reward),
    );
  }

  factory ExpeditionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpeditionRow(
      day: serializer.fromJson<String>(json['day']),
      departedAt: serializer.fromJson<DateTime>(json['departedAt']),
      collectedAt: serializer.fromJson<DateTime?>(json['collectedAt']),
      reward: serializer.fromJson<int>(json['reward']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'departedAt': serializer.toJson<DateTime>(departedAt),
      'collectedAt': serializer.toJson<DateTime?>(collectedAt),
      'reward': serializer.toJson<int>(reward),
    };
  }

  ExpeditionRow copyWith({
    String? day,
    DateTime? departedAt,
    Value<DateTime?> collectedAt = const Value.absent(),
    int? reward,
  }) => ExpeditionRow(
    day: day ?? this.day,
    departedAt: departedAt ?? this.departedAt,
    collectedAt: collectedAt.present ? collectedAt.value : this.collectedAt,
    reward: reward ?? this.reward,
  );
  ExpeditionRow copyWithCompanion(ExpeditionRowsCompanion data) {
    return ExpeditionRow(
      day: data.day.present ? data.day.value : this.day,
      departedAt: data.departedAt.present
          ? data.departedAt.value
          : this.departedAt,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      reward: data.reward.present ? data.reward.value : this.reward,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpeditionRow(')
          ..write('day: $day, ')
          ..write('departedAt: $departedAt, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('reward: $reward')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, departedAt, collectedAt, reward);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpeditionRow &&
          other.day == this.day &&
          other.departedAt == this.departedAt &&
          other.collectedAt == this.collectedAt &&
          other.reward == this.reward);
}

class ExpeditionRowsCompanion extends UpdateCompanion<ExpeditionRow> {
  final Value<String> day;
  final Value<DateTime> departedAt;
  final Value<DateTime?> collectedAt;
  final Value<int> reward;
  final Value<int> rowid;
  const ExpeditionRowsCompanion({
    this.day = const Value.absent(),
    this.departedAt = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.reward = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpeditionRowsCompanion.insert({
    required String day,
    required DateTime departedAt,
    this.collectedAt = const Value.absent(),
    required int reward,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       departedAt = Value(departedAt),
       reward = Value(reward);
  static Insertable<ExpeditionRow> custom({
    Expression<String>? day,
    Expression<DateTime>? departedAt,
    Expression<DateTime>? collectedAt,
    Expression<int>? reward,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (departedAt != null) 'departed_at': departedAt,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (reward != null) 'reward': reward,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpeditionRowsCompanion copyWith({
    Value<String>? day,
    Value<DateTime>? departedAt,
    Value<DateTime?>? collectedAt,
    Value<int>? reward,
    Value<int>? rowid,
  }) {
    return ExpeditionRowsCompanion(
      day: day ?? this.day,
      departedAt: departedAt ?? this.departedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      reward: reward ?? this.reward,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (departedAt.present) {
      map['departed_at'] = Variable<DateTime>(departedAt.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (reward.present) {
      map['reward'] = Variable<int>(reward.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpeditionRowsCompanion(')
          ..write('day: $day, ')
          ..write('departedAt: $departedAt, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('reward: $reward, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifeSimRunsTable extends LifeSimRuns
    with TableInfo<$LifeSimRunsTable, LifeSimRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeSimRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seed,
    roleId,
    goalId,
    mode,
    contentVersion,
    day,
    stateJson,
    startedAt,
    completedAt,
    resultJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_sim_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifeSimRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifeSimRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeSimRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
    );
  }

  @override
  $LifeSimRunsTable createAlias(String alias) {
    return $LifeSimRunsTable(attachedDatabase, alias);
  }
}

class LifeSimRun extends DataClass implements Insertable<LifeSimRun> {
  final String id;
  final int seed;
  final String roleId;
  final String goalId;
  final String mode;
  final String contentVersion;
  final int day;
  final String stateJson;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? resultJson;
  const LifeSimRun({
    required this.id,
    required this.seed,
    required this.roleId,
    required this.goalId,
    required this.mode,
    required this.contentVersion,
    required this.day,
    required this.stateJson,
    required this.startedAt,
    this.completedAt,
    this.resultJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seed'] = Variable<int>(seed);
    map['role_id'] = Variable<String>(roleId);
    map['goal_id'] = Variable<String>(goalId);
    map['mode'] = Variable<String>(mode);
    map['content_version'] = Variable<String>(contentVersion);
    map['day'] = Variable<int>(day);
    map['state_json'] = Variable<String>(stateJson);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    return map;
  }

  LifeSimRunsCompanion toCompanion(bool nullToAbsent) {
    return LifeSimRunsCompanion(
      id: Value(id),
      seed: Value(seed),
      roleId: Value(roleId),
      goalId: Value(goalId),
      mode: Value(mode),
      contentVersion: Value(contentVersion),
      day: Value(day),
      stateJson: Value(stateJson),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
    );
  }

  factory LifeSimRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeSimRun(
      id: serializer.fromJson<String>(json['id']),
      seed: serializer.fromJson<int>(json['seed']),
      roleId: serializer.fromJson<String>(json['roleId']),
      goalId: serializer.fromJson<String>(json['goalId']),
      mode: serializer.fromJson<String>(json['mode']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      day: serializer.fromJson<int>(json['day']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seed': serializer.toJson<int>(seed),
      'roleId': serializer.toJson<String>(roleId),
      'goalId': serializer.toJson<String>(goalId),
      'mode': serializer.toJson<String>(mode),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'day': serializer.toJson<int>(day),
      'stateJson': serializer.toJson<String>(stateJson),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'resultJson': serializer.toJson<String?>(resultJson),
    };
  }

  LifeSimRun copyWith({
    String? id,
    int? seed,
    String? roleId,
    String? goalId,
    String? mode,
    String? contentVersion,
    int? day,
    String? stateJson,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> resultJson = const Value.absent(),
  }) => LifeSimRun(
    id: id ?? this.id,
    seed: seed ?? this.seed,
    roleId: roleId ?? this.roleId,
    goalId: goalId ?? this.goalId,
    mode: mode ?? this.mode,
    contentVersion: contentVersion ?? this.contentVersion,
    day: day ?? this.day,
    stateJson: stateJson ?? this.stateJson,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
  );
  LifeSimRun copyWithCompanion(LifeSimRunsCompanion data) {
    return LifeSimRun(
      id: data.id.present ? data.id.value : this.id,
      seed: data.seed.present ? data.seed.value : this.seed,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      mode: data.mode.present ? data.mode.value : this.mode,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      day: data.day.present ? data.day.value : this.day,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeSimRun(')
          ..write('id: $id, ')
          ..write('seed: $seed, ')
          ..write('roleId: $roleId, ')
          ..write('goalId: $goalId, ')
          ..write('mode: $mode, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('day: $day, ')
          ..write('stateJson: $stateJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('resultJson: $resultJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seed,
    roleId,
    goalId,
    mode,
    contentVersion,
    day,
    stateJson,
    startedAt,
    completedAt,
    resultJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeSimRun &&
          other.id == this.id &&
          other.seed == this.seed &&
          other.roleId == this.roleId &&
          other.goalId == this.goalId &&
          other.mode == this.mode &&
          other.contentVersion == this.contentVersion &&
          other.day == this.day &&
          other.stateJson == this.stateJson &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.resultJson == this.resultJson);
}

class LifeSimRunsCompanion extends UpdateCompanion<LifeSimRun> {
  final Value<String> id;
  final Value<int> seed;
  final Value<String> roleId;
  final Value<String> goalId;
  final Value<String> mode;
  final Value<String> contentVersion;
  final Value<int> day;
  final Value<String> stateJson;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> resultJson;
  final Value<int> rowid;
  const LifeSimRunsCompanion({
    this.id = const Value.absent(),
    this.seed = const Value.absent(),
    this.roleId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.mode = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.day = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifeSimRunsCompanion.insert({
    required String id,
    required int seed,
    required String roleId,
    required String goalId,
    required String mode,
    required String contentVersion,
    this.day = const Value.absent(),
    required String stateJson,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seed = Value(seed),
       roleId = Value(roleId),
       goalId = Value(goalId),
       mode = Value(mode),
       contentVersion = Value(contentVersion),
       stateJson = Value(stateJson),
       startedAt = Value(startedAt);
  static Insertable<LifeSimRun> custom({
    Expression<String>? id,
    Expression<int>? seed,
    Expression<String>? roleId,
    Expression<String>? goalId,
    Expression<String>? mode,
    Expression<String>? contentVersion,
    Expression<int>? day,
    Expression<String>? stateJson,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? resultJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seed != null) 'seed': seed,
      if (roleId != null) 'role_id': roleId,
      if (goalId != null) 'goal_id': goalId,
      if (mode != null) 'mode': mode,
      if (contentVersion != null) 'content_version': contentVersion,
      if (day != null) 'day': day,
      if (stateJson != null) 'state_json': stateJson,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (resultJson != null) 'result_json': resultJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifeSimRunsCompanion copyWith({
    Value<String>? id,
    Value<int>? seed,
    Value<String>? roleId,
    Value<String>? goalId,
    Value<String>? mode,
    Value<String>? contentVersion,
    Value<int>? day,
    Value<String>? stateJson,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? resultJson,
    Value<int>? rowid,
  }) {
    return LifeSimRunsCompanion(
      id: id ?? this.id,
      seed: seed ?? this.seed,
      roleId: roleId ?? this.roleId,
      goalId: goalId ?? this.goalId,
      mode: mode ?? this.mode,
      contentVersion: contentVersion ?? this.contentVersion,
      day: day ?? this.day,
      stateJson: stateJson ?? this.stateJson,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      resultJson: resultJson ?? this.resultJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeSimRunsCompanion(')
          ..write('id: $id, ')
          ..write('seed: $seed, ')
          ..write('roleId: $roleId, ')
          ..write('goalId: $goalId, ')
          ..write('mode: $mode, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('day: $day, ')
          ..write('stateJson: $stateJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('resultJson: $resultJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifeSimDecisionsTable extends LifeSimDecisions
    with TableInfo<$LifeSimDecisionsTable, LifeSimDecision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeSimDecisionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choiceIdxMeta = const VerificationMeta(
    'choiceIdx',
  );
  @override
  late final GeneratedColumn<int> choiceIdx = GeneratedColumn<int>(
    'choice_idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    day,
    eventId,
    choiceIdx,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_sim_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifeSimDecision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('choice_idx')) {
      context.handle(
        _choiceIdxMeta,
        choiceIdx.isAcceptableOrUnknown(data['choice_idx']!, _choiceIdxMeta),
      );
    } else if (isInserting) {
      context.missing(_choiceIdxMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifeSimDecision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeSimDecision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      choiceIdx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}choice_idx'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LifeSimDecisionsTable createAlias(String alias) {
    return $LifeSimDecisionsTable(attachedDatabase, alias);
  }
}

class LifeSimDecision extends DataClass implements Insertable<LifeSimDecision> {
  final int id;
  final String runId;
  final int day;
  final String eventId;
  final int choiceIdx;
  final DateTime createdAt;
  const LifeSimDecision({
    required this.id,
    required this.runId,
    required this.day,
    required this.eventId,
    required this.choiceIdx,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<String>(runId);
    map['day'] = Variable<int>(day);
    map['event_id'] = Variable<String>(eventId);
    map['choice_idx'] = Variable<int>(choiceIdx);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LifeSimDecisionsCompanion toCompanion(bool nullToAbsent) {
    return LifeSimDecisionsCompanion(
      id: Value(id),
      runId: Value(runId),
      day: Value(day),
      eventId: Value(eventId),
      choiceIdx: Value(choiceIdx),
      createdAt: Value(createdAt),
    );
  }

  factory LifeSimDecision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeSimDecision(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      day: serializer.fromJson<int>(json['day']),
      eventId: serializer.fromJson<String>(json['eventId']),
      choiceIdx: serializer.fromJson<int>(json['choiceIdx']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<String>(runId),
      'day': serializer.toJson<int>(day),
      'eventId': serializer.toJson<String>(eventId),
      'choiceIdx': serializer.toJson<int>(choiceIdx),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LifeSimDecision copyWith({
    int? id,
    String? runId,
    int? day,
    String? eventId,
    int? choiceIdx,
    DateTime? createdAt,
  }) => LifeSimDecision(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    day: day ?? this.day,
    eventId: eventId ?? this.eventId,
    choiceIdx: choiceIdx ?? this.choiceIdx,
    createdAt: createdAt ?? this.createdAt,
  );
  LifeSimDecision copyWithCompanion(LifeSimDecisionsCompanion data) {
    return LifeSimDecision(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      day: data.day.present ? data.day.value : this.day,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      choiceIdx: data.choiceIdx.present ? data.choiceIdx.value : this.choiceIdx,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeSimDecision(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('day: $day, ')
          ..write('eventId: $eventId, ')
          ..write('choiceIdx: $choiceIdx, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, runId, day, eventId, choiceIdx, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeSimDecision &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.day == this.day &&
          other.eventId == this.eventId &&
          other.choiceIdx == this.choiceIdx &&
          other.createdAt == this.createdAt);
}

class LifeSimDecisionsCompanion extends UpdateCompanion<LifeSimDecision> {
  final Value<int> id;
  final Value<String> runId;
  final Value<int> day;
  final Value<String> eventId;
  final Value<int> choiceIdx;
  final Value<DateTime> createdAt;
  const LifeSimDecisionsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.day = const Value.absent(),
    this.eventId = const Value.absent(),
    this.choiceIdx = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LifeSimDecisionsCompanion.insert({
    this.id = const Value.absent(),
    required String runId,
    required int day,
    required String eventId,
    required int choiceIdx,
    required DateTime createdAt,
  }) : runId = Value(runId),
       day = Value(day),
       eventId = Value(eventId),
       choiceIdx = Value(choiceIdx),
       createdAt = Value(createdAt);
  static Insertable<LifeSimDecision> custom({
    Expression<int>? id,
    Expression<String>? runId,
    Expression<int>? day,
    Expression<String>? eventId,
    Expression<int>? choiceIdx,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (day != null) 'day': day,
      if (eventId != null) 'event_id': eventId,
      if (choiceIdx != null) 'choice_idx': choiceIdx,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LifeSimDecisionsCompanion copyWith({
    Value<int>? id,
    Value<String>? runId,
    Value<int>? day,
    Value<String>? eventId,
    Value<int>? choiceIdx,
    Value<DateTime>? createdAt,
  }) {
    return LifeSimDecisionsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      day: day ?? this.day,
      eventId: eventId ?? this.eventId,
      choiceIdx: choiceIdx ?? this.choiceIdx,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (choiceIdx.present) {
      map['choice_idx'] = Variable<int>(choiceIdx.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeSimDecisionsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('day: $day, ')
          ..write('eventId: $eventId, ')
          ..write('choiceIdx: $choiceIdx, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $NoSpendDaysTable noSpendDays = $NoSpendDaysTable(this);
  late final $DailyActivityRowsTable dailyActivityRows =
      $DailyActivityRowsTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $StreakStatesTable streakStates = $StreakStatesTable(this);
  late final $AcornEntriesTable acornEntries = $AcornEntriesTable(this);
  late final $QuestClaimsTable questClaims = $QuestClaimsTable(this);
  late final $ChestStatesTable chestStates = $ChestStatesTable(this);
  late final $LocalGoalsTable localGoals = $LocalGoalsTable(this);
  late final $LocalRecurringTable localRecurring = $LocalRecurringTable(this);
  late final $LessonProgressRowsTable lessonProgressRows =
      $LessonProgressRowsTable(this);
  late final $ReviewCardsTable reviewCards = $ReviewCardsTable(this);
  late final $ArcadeRoundsTable arcadeRounds = $ArcadeRoundsTable(this);
  late final $DojoStatesTable dojoStates = $DojoStatesTable(this);
  late final $DojoItemStatsTable dojoItemStats = $DojoItemStatsTable(this);
  late final $WardrobeItemsTable wardrobeItems = $WardrobeItemsTable(this);
  late final $InsightEventsTable insightEvents = $InsightEventsTable(this);
  late final $ExpeditionRowsTable expeditionRows = $ExpeditionRowsTable(this);
  late final $LifeSimRunsTable lifeSimRuns = $LifeSimRunsTable(this);
  late final $LifeSimDecisionsTable lifeSimDecisions = $LifeSimDecisionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTransactions,
    noSpendDays,
    dailyActivityRows,
    outboxEntries,
    localProfiles,
    streakStates,
    acornEntries,
    questClaims,
    chestStates,
    localGoals,
    localRecurring,
    lessonProgressRows,
    reviewCards,
    arcadeRounds,
    dojoStates,
    dojoItemStats,
    wardrobeItems,
    insightEvents,
    expeditionRows,
    lifeSimRuns,
    lifeSimDecisions,
  ];
}

typedef $$LocalTransactionsTableCreateCompanionBuilder =
    LocalTransactionsCompanion Function({
      required String id,
      required double amount,
      required String category,
      Value<String> type,
      Value<String?> merchant,
      Value<String?> note,
      required DateTime transactionDate,
      Value<String> source,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> deleted,
      Value<bool> pendingSync,
      Value<String?> goalId,
      Value<int> rowid,
    });
typedef $$LocalTransactionsTableUpdateCompanionBuilder =
    LocalTransactionsCompanion Function({
      Value<String> id,
      Value<double> amount,
      Value<String> category,
      Value<String> type,
      Value<String?> merchant,
      Value<String?> note,
      Value<DateTime> transactionDate,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> pendingSync,
      Value<String?> goalId,
      Value<int> rowid,
    });

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$AppDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$AppDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$AppDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);
}

class $$LocalTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LocalTransactionsTable,
          LocalTransaction,
          $$LocalTransactionsTableFilterComposer,
          $$LocalTransactionsTableOrderingComposer,
          $$LocalTransactionsTableAnnotationComposer,
          $$LocalTransactionsTableCreateCompanionBuilder,
          $$LocalTransactionsTableUpdateCompanionBuilder,
          (
            LocalTransaction,
            BaseReferences<_$AppDb, $LocalTransactionsTable, LocalTransaction>,
          ),
          LocalTransaction,
          PrefetchHooks Function()
        > {
  $$LocalTransactionsTableTableManager(
    _$AppDb db,
    $LocalTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion(
                id: id,
                amount: amount,
                category: category,
                type: type,
                merchant: merchant,
                note: note,
                transactionDate: transactionDate,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                pendingSync: pendingSync,
                goalId: goalId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double amount,
                required String category,
                Value<String> type = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime transactionDate,
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion.insert(
                id: id,
                amount: amount,
                category: category,
                type: type,
                merchant: merchant,
                note: note,
                transactionDate: transactionDate,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                pendingSync: pendingSync,
                goalId: goalId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LocalTransactionsTable,
      LocalTransaction,
      $$LocalTransactionsTableFilterComposer,
      $$LocalTransactionsTableOrderingComposer,
      $$LocalTransactionsTableAnnotationComposer,
      $$LocalTransactionsTableCreateCompanionBuilder,
      $$LocalTransactionsTableUpdateCompanionBuilder,
      (
        LocalTransaction,
        BaseReferences<_$AppDb, $LocalTransactionsTable, LocalTransaction>,
      ),
      LocalTransaction,
      PrefetchHooks Function()
    >;
typedef $$NoSpendDaysTableCreateCompanionBuilder =
    NoSpendDaysCompanion Function({required String date, Value<int> rowid});
typedef $$NoSpendDaysTableUpdateCompanionBuilder =
    NoSpendDaysCompanion Function({Value<String> date, Value<int> rowid});

class $$NoSpendDaysTableFilterComposer
    extends Composer<_$AppDb, $NoSpendDaysTable> {
  $$NoSpendDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoSpendDaysTableOrderingComposer
    extends Composer<_$AppDb, $NoSpendDaysTable> {
  $$NoSpendDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoSpendDaysTableAnnotationComposer
    extends Composer<_$AppDb, $NoSpendDaysTable> {
  $$NoSpendDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$NoSpendDaysTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $NoSpendDaysTable,
          NoSpendDay,
          $$NoSpendDaysTableFilterComposer,
          $$NoSpendDaysTableOrderingComposer,
          $$NoSpendDaysTableAnnotationComposer,
          $$NoSpendDaysTableCreateCompanionBuilder,
          $$NoSpendDaysTableUpdateCompanionBuilder,
          (NoSpendDay, BaseReferences<_$AppDb, $NoSpendDaysTable, NoSpendDay>),
          NoSpendDay,
          PrefetchHooks Function()
        > {
  $$NoSpendDaysTableTableManager(_$AppDb db, $NoSpendDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoSpendDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoSpendDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoSpendDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoSpendDaysCompanion(date: date, rowid: rowid),
          createCompanionCallback:
              ({
                required String date,
                Value<int> rowid = const Value.absent(),
              }) => NoSpendDaysCompanion.insert(date: date, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoSpendDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $NoSpendDaysTable,
      NoSpendDay,
      $$NoSpendDaysTableFilterComposer,
      $$NoSpendDaysTableOrderingComposer,
      $$NoSpendDaysTableAnnotationComposer,
      $$NoSpendDaysTableCreateCompanionBuilder,
      $$NoSpendDaysTableUpdateCompanionBuilder,
      (NoSpendDay, BaseReferences<_$AppDb, $NoSpendDaysTable, NoSpendDay>),
      NoSpendDay,
      PrefetchHooks Function()
    >;
typedef $$DailyActivityRowsTableCreateCompanionBuilder =
    DailyActivityRowsCompanion Function({
      required String date,
      required String kinds,
      Value<int> rowid,
    });
typedef $$DailyActivityRowsTableUpdateCompanionBuilder =
    DailyActivityRowsCompanion Function({
      Value<String> date,
      Value<String> kinds,
      Value<int> rowid,
    });

class $$DailyActivityRowsTableFilterComposer
    extends Composer<_$AppDb, $DailyActivityRowsTable> {
  $$DailyActivityRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kinds => $composableBuilder(
    column: $table.kinds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyActivityRowsTableOrderingComposer
    extends Composer<_$AppDb, $DailyActivityRowsTable> {
  $$DailyActivityRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kinds => $composableBuilder(
    column: $table.kinds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActivityRowsTableAnnotationComposer
    extends Composer<_$AppDb, $DailyActivityRowsTable> {
  $$DailyActivityRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kinds =>
      $composableBuilder(column: $table.kinds, builder: (column) => column);
}

class $$DailyActivityRowsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DailyActivityRowsTable,
          DailyActivityRow,
          $$DailyActivityRowsTableFilterComposer,
          $$DailyActivityRowsTableOrderingComposer,
          $$DailyActivityRowsTableAnnotationComposer,
          $$DailyActivityRowsTableCreateCompanionBuilder,
          $$DailyActivityRowsTableUpdateCompanionBuilder,
          (
            DailyActivityRow,
            BaseReferences<_$AppDb, $DailyActivityRowsTable, DailyActivityRow>,
          ),
          DailyActivityRow,
          PrefetchHooks Function()
        > {
  $$DailyActivityRowsTableTableManager(
    _$AppDb db,
    $DailyActivityRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActivityRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActivityRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActivityRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> kinds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityRowsCompanion(
                date: date,
                kinds: kinds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String kinds,
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityRowsCompanion.insert(
                date: date,
                kinds: kinds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActivityRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DailyActivityRowsTable,
      DailyActivityRow,
      $$DailyActivityRowsTableFilterComposer,
      $$DailyActivityRowsTableOrderingComposer,
      $$DailyActivityRowsTableAnnotationComposer,
      $$DailyActivityRowsTableCreateCompanionBuilder,
      $$DailyActivityRowsTableUpdateCompanionBuilder,
      (
        DailyActivityRow,
        BaseReferences<_$AppDb, $DailyActivityRowsTable, DailyActivityRow>,
      ),
      DailyActivityRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      required String opType,
      required String payload,
      required DateTime createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      Value<String> opType,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
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

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDb, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDb db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                opType: opType,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String opType,
                required String payload,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                id: id,
                opType: opType,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (OutboxEntry, BaseReferences<_$AppDb, $OutboxEntriesTable, OutboxEntry>),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<int> id,
      Value<String> cashyName,
      Value<String> cashyColor,
      Value<String?> equippedBackground,
      Value<String?> equippedAccessory,
      Value<String?> ageBand,
      Value<String?> track,
      Value<double?> monthlyBudget,
      Value<bool> onboarded,
      Value<String> notifChoice,
      Value<String?> parentEmail,
      Value<String> parentalStatus,
      Value<int> acorns,
      Value<int> xp,
      Value<String?> quizSeed,
      Value<bool> personalizationOn,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<int> id,
      Value<String> cashyName,
      Value<String> cashyColor,
      Value<String?> equippedBackground,
      Value<String?> equippedAccessory,
      Value<String?> ageBand,
      Value<String?> track,
      Value<double?> monthlyBudget,
      Value<bool> onboarded,
      Value<String> notifChoice,
      Value<String?> parentEmail,
      Value<String> parentalStatus,
      Value<int> acorns,
      Value<int> xp,
      Value<String?> quizSeed,
      Value<bool> personalizationOn,
    });

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDb, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
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

  ColumnFilters<String> get cashyName => $composableBuilder(
    column: $table.cashyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashyColor => $composableBuilder(
    column: $table.cashyColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equippedBackground => $composableBuilder(
    column: $table.equippedBackground,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equippedAccessory => $composableBuilder(
    column: $table.equippedAccessory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get track => $composableBuilder(
    column: $table.track,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboarded => $composableBuilder(
    column: $table.onboarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notifChoice => $composableBuilder(
    column: $table.notifChoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentEmail => $composableBuilder(
    column: $table.parentEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentalStatus => $composableBuilder(
    column: $table.parentalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acorns => $composableBuilder(
    column: $table.acorns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quizSeed => $composableBuilder(
    column: $table.quizSeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get personalizationOn => $composableBuilder(
    column: $table.personalizationOn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDb, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get cashyName => $composableBuilder(
    column: $table.cashyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashyColor => $composableBuilder(
    column: $table.cashyColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equippedBackground => $composableBuilder(
    column: $table.equippedBackground,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equippedAccessory => $composableBuilder(
    column: $table.equippedAccessory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get track => $composableBuilder(
    column: $table.track,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboarded => $composableBuilder(
    column: $table.onboarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notifChoice => $composableBuilder(
    column: $table.notifChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentEmail => $composableBuilder(
    column: $table.parentEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentalStatus => $composableBuilder(
    column: $table.parentalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acorns => $composableBuilder(
    column: $table.acorns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quizSeed => $composableBuilder(
    column: $table.quizSeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get personalizationOn => $composableBuilder(
    column: $table.personalizationOn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDb, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cashyName =>
      $composableBuilder(column: $table.cashyName, builder: (column) => column);

  GeneratedColumn<String> get cashyColor => $composableBuilder(
    column: $table.cashyColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equippedBackground => $composableBuilder(
    column: $table.equippedBackground,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equippedAccessory => $composableBuilder(
    column: $table.equippedAccessory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ageBand =>
      $composableBuilder(column: $table.ageBand, builder: (column) => column);

  GeneratedColumn<String> get track =>
      $composableBuilder(column: $table.track, builder: (column) => column);

  GeneratedColumn<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboarded =>
      $composableBuilder(column: $table.onboarded, builder: (column) => column);

  GeneratedColumn<String> get notifChoice => $composableBuilder(
    column: $table.notifChoice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentEmail => $composableBuilder(
    column: $table.parentEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentalStatus => $composableBuilder(
    column: $table.parentalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get acorns =>
      $composableBuilder(column: $table.acorns, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<String> get quizSeed =>
      $composableBuilder(column: $table.quizSeed, builder: (column) => column);

  GeneratedColumn<bool> get personalizationOn => $composableBuilder(
    column: $table.personalizationOn,
    builder: (column) => column,
  );
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LocalProfilesTable,
          LocalProfile,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (
            LocalProfile,
            BaseReferences<_$AppDb, $LocalProfilesTable, LocalProfile>,
          ),
          LocalProfile,
          PrefetchHooks Function()
        > {
  $$LocalProfilesTableTableManager(_$AppDb db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cashyName = const Value.absent(),
                Value<String> cashyColor = const Value.absent(),
                Value<String?> equippedBackground = const Value.absent(),
                Value<String?> equippedAccessory = const Value.absent(),
                Value<String?> ageBand = const Value.absent(),
                Value<String?> track = const Value.absent(),
                Value<double?> monthlyBudget = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<String> notifChoice = const Value.absent(),
                Value<String?> parentEmail = const Value.absent(),
                Value<String> parentalStatus = const Value.absent(),
                Value<int> acorns = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<String?> quizSeed = const Value.absent(),
                Value<bool> personalizationOn = const Value.absent(),
              }) => LocalProfilesCompanion(
                id: id,
                cashyName: cashyName,
                cashyColor: cashyColor,
                equippedBackground: equippedBackground,
                equippedAccessory: equippedAccessory,
                ageBand: ageBand,
                track: track,
                monthlyBudget: monthlyBudget,
                onboarded: onboarded,
                notifChoice: notifChoice,
                parentEmail: parentEmail,
                parentalStatus: parentalStatus,
                acorns: acorns,
                xp: xp,
                quizSeed: quizSeed,
                personalizationOn: personalizationOn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cashyName = const Value.absent(),
                Value<String> cashyColor = const Value.absent(),
                Value<String?> equippedBackground = const Value.absent(),
                Value<String?> equippedAccessory = const Value.absent(),
                Value<String?> ageBand = const Value.absent(),
                Value<String?> track = const Value.absent(),
                Value<double?> monthlyBudget = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<String> notifChoice = const Value.absent(),
                Value<String?> parentEmail = const Value.absent(),
                Value<String> parentalStatus = const Value.absent(),
                Value<int> acorns = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<String?> quizSeed = const Value.absent(),
                Value<bool> personalizationOn = const Value.absent(),
              }) => LocalProfilesCompanion.insert(
                id: id,
                cashyName: cashyName,
                cashyColor: cashyColor,
                equippedBackground: equippedBackground,
                equippedAccessory: equippedAccessory,
                ageBand: ageBand,
                track: track,
                monthlyBudget: monthlyBudget,
                onboarded: onboarded,
                notifChoice: notifChoice,
                parentEmail: parentEmail,
                parentalStatus: parentalStatus,
                acorns: acorns,
                xp: xp,
                quizSeed: quizSeed,
                personalizationOn: personalizationOn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LocalProfilesTable,
      LocalProfile,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (
        LocalProfile,
        BaseReferences<_$AppDb, $LocalProfilesTable, LocalProfile>,
      ),
      LocalProfile,
      PrefetchHooks Function()
    >;
typedef $$StreakStatesTableCreateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int> freezes,
      Value<String> frozenDays,
      Value<int> earnbackValue,
      Value<String?> earnbackUntil,
      Value<String> earnbackGap,
      Value<String> claimedMilestones,
      Value<String?> lastEvaluated,
    });
typedef $$StreakStatesTableUpdateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int> freezes,
      Value<String> frozenDays,
      Value<int> earnbackValue,
      Value<String?> earnbackUntil,
      Value<String> earnbackGap,
      Value<String> claimedMilestones,
      Value<String?> lastEvaluated,
    });

class $$StreakStatesTableFilterComposer
    extends Composer<_$AppDb, $StreakStatesTable> {
  $$StreakStatesTableFilterComposer({
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

  ColumnFilters<int> get freezes => $composableBuilder(
    column: $table.freezes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frozenDays => $composableBuilder(
    column: $table.frozenDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earnbackValue => $composableBuilder(
    column: $table.earnbackValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnbackUntil => $composableBuilder(
    column: $table.earnbackUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnbackGap => $composableBuilder(
    column: $table.earnbackGap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimedMilestones => $composableBuilder(
    column: $table.claimedMilestones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastEvaluated => $composableBuilder(
    column: $table.lastEvaluated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreakStatesTableOrderingComposer
    extends Composer<_$AppDb, $StreakStatesTable> {
  $$StreakStatesTableOrderingComposer({
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

  ColumnOrderings<int> get freezes => $composableBuilder(
    column: $table.freezes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frozenDays => $composableBuilder(
    column: $table.frozenDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earnbackValue => $composableBuilder(
    column: $table.earnbackValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnbackUntil => $composableBuilder(
    column: $table.earnbackUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnbackGap => $composableBuilder(
    column: $table.earnbackGap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimedMilestones => $composableBuilder(
    column: $table.claimedMilestones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastEvaluated => $composableBuilder(
    column: $table.lastEvaluated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreakStatesTableAnnotationComposer
    extends Composer<_$AppDb, $StreakStatesTable> {
  $$StreakStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get freezes =>
      $composableBuilder(column: $table.freezes, builder: (column) => column);

  GeneratedColumn<String> get frozenDays => $composableBuilder(
    column: $table.frozenDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get earnbackValue => $composableBuilder(
    column: $table.earnbackValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnbackUntil => $composableBuilder(
    column: $table.earnbackUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnbackGap => $composableBuilder(
    column: $table.earnbackGap,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimedMilestones => $composableBuilder(
    column: $table.claimedMilestones,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastEvaluated => $composableBuilder(
    column: $table.lastEvaluated,
    builder: (column) => column,
  );
}

class $$StreakStatesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $StreakStatesTable,
          StreakState,
          $$StreakStatesTableFilterComposer,
          $$StreakStatesTableOrderingComposer,
          $$StreakStatesTableAnnotationComposer,
          $$StreakStatesTableCreateCompanionBuilder,
          $$StreakStatesTableUpdateCompanionBuilder,
          (
            StreakState,
            BaseReferences<_$AppDb, $StreakStatesTable, StreakState>,
          ),
          StreakState,
          PrefetchHooks Function()
        > {
  $$StreakStatesTableTableManager(_$AppDb db, $StreakStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> freezes = const Value.absent(),
                Value<String> frozenDays = const Value.absent(),
                Value<int> earnbackValue = const Value.absent(),
                Value<String?> earnbackUntil = const Value.absent(),
                Value<String> earnbackGap = const Value.absent(),
                Value<String> claimedMilestones = const Value.absent(),
                Value<String?> lastEvaluated = const Value.absent(),
              }) => StreakStatesCompanion(
                id: id,
                freezes: freezes,
                frozenDays: frozenDays,
                earnbackValue: earnbackValue,
                earnbackUntil: earnbackUntil,
                earnbackGap: earnbackGap,
                claimedMilestones: claimedMilestones,
                lastEvaluated: lastEvaluated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> freezes = const Value.absent(),
                Value<String> frozenDays = const Value.absent(),
                Value<int> earnbackValue = const Value.absent(),
                Value<String?> earnbackUntil = const Value.absent(),
                Value<String> earnbackGap = const Value.absent(),
                Value<String> claimedMilestones = const Value.absent(),
                Value<String?> lastEvaluated = const Value.absent(),
              }) => StreakStatesCompanion.insert(
                id: id,
                freezes: freezes,
                frozenDays: frozenDays,
                earnbackValue: earnbackValue,
                earnbackUntil: earnbackUntil,
                earnbackGap: earnbackGap,
                claimedMilestones: claimedMilestones,
                lastEvaluated: lastEvaluated,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $StreakStatesTable,
      StreakState,
      $$StreakStatesTableFilterComposer,
      $$StreakStatesTableOrderingComposer,
      $$StreakStatesTableAnnotationComposer,
      $$StreakStatesTableCreateCompanionBuilder,
      $$StreakStatesTableUpdateCompanionBuilder,
      (StreakState, BaseReferences<_$AppDb, $StreakStatesTable, StreakState>),
      StreakState,
      PrefetchHooks Function()
    >;
typedef $$AcornEntriesTableCreateCompanionBuilder =
    AcornEntriesCompanion Function({
      Value<int> id,
      required int delta,
      required String reason,
      required DateTime createdAt,
    });
typedef $$AcornEntriesTableUpdateCompanionBuilder =
    AcornEntriesCompanion Function({
      Value<int> id,
      Value<int> delta,
      Value<String> reason,
      Value<DateTime> createdAt,
    });

class $$AcornEntriesTableFilterComposer
    extends Composer<_$AppDb, $AcornEntriesTable> {
  $$AcornEntriesTableFilterComposer({
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

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AcornEntriesTableOrderingComposer
    extends Composer<_$AppDb, $AcornEntriesTable> {
  $$AcornEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AcornEntriesTableAnnotationComposer
    extends Composer<_$AppDb, $AcornEntriesTable> {
  $$AcornEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AcornEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AcornEntriesTable,
          AcornEntry,
          $$AcornEntriesTableFilterComposer,
          $$AcornEntriesTableOrderingComposer,
          $$AcornEntriesTableAnnotationComposer,
          $$AcornEntriesTableCreateCompanionBuilder,
          $$AcornEntriesTableUpdateCompanionBuilder,
          (AcornEntry, BaseReferences<_$AppDb, $AcornEntriesTable, AcornEntry>),
          AcornEntry,
          PrefetchHooks Function()
        > {
  $$AcornEntriesTableTableManager(_$AppDb db, $AcornEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcornEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcornEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcornEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AcornEntriesCompanion(
                id: id,
                delta: delta,
                reason: reason,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int delta,
                required String reason,
                required DateTime createdAt,
              }) => AcornEntriesCompanion.insert(
                id: id,
                delta: delta,
                reason: reason,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AcornEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AcornEntriesTable,
      AcornEntry,
      $$AcornEntriesTableFilterComposer,
      $$AcornEntriesTableOrderingComposer,
      $$AcornEntriesTableAnnotationComposer,
      $$AcornEntriesTableCreateCompanionBuilder,
      $$AcornEntriesTableUpdateCompanionBuilder,
      (AcornEntry, BaseReferences<_$AppDb, $AcornEntriesTable, AcornEntry>),
      AcornEntry,
      PrefetchHooks Function()
    >;
typedef $$QuestClaimsTableCreateCompanionBuilder =
    QuestClaimsCompanion Function({
      required String date,
      required int slot,
      required DateTime claimedAt,
      Value<int> rowid,
    });
typedef $$QuestClaimsTableUpdateCompanionBuilder =
    QuestClaimsCompanion Function({
      Value<String> date,
      Value<int> slot,
      Value<DateTime> claimedAt,
      Value<int> rowid,
    });

class $$QuestClaimsTableFilterComposer
    extends Composer<_$AppDb, $QuestClaimsTable> {
  $$QuestClaimsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestClaimsTableOrderingComposer
    extends Composer<_$AppDb, $QuestClaimsTable> {
  $$QuestClaimsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestClaimsTableAnnotationComposer
    extends Composer<_$AppDb, $QuestClaimsTable> {
  $$QuestClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<DateTime> get claimedAt =>
      $composableBuilder(column: $table.claimedAt, builder: (column) => column);
}

class $$QuestClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $QuestClaimsTable,
          QuestClaim,
          $$QuestClaimsTableFilterComposer,
          $$QuestClaimsTableOrderingComposer,
          $$QuestClaimsTableAnnotationComposer,
          $$QuestClaimsTableCreateCompanionBuilder,
          $$QuestClaimsTableUpdateCompanionBuilder,
          (QuestClaim, BaseReferences<_$AppDb, $QuestClaimsTable, QuestClaim>),
          QuestClaim,
          PrefetchHooks Function()
        > {
  $$QuestClaimsTableTableManager(_$AppDb db, $QuestClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<DateTime> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestClaimsCompanion(
                date: date,
                slot: slot,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int slot,
                required DateTime claimedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestClaimsCompanion.insert(
                date: date,
                slot: slot,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $QuestClaimsTable,
      QuestClaim,
      $$QuestClaimsTableFilterComposer,
      $$QuestClaimsTableOrderingComposer,
      $$QuestClaimsTableAnnotationComposer,
      $$QuestClaimsTableCreateCompanionBuilder,
      $$QuestClaimsTableUpdateCompanionBuilder,
      (QuestClaim, BaseReferences<_$AppDb, $QuestClaimsTable, QuestClaim>),
      QuestClaim,
      PrefetchHooks Function()
    >;
typedef $$ChestStatesTableCreateCompanionBuilder =
    ChestStatesCompanion Function({
      Value<int> id,
      Value<String?> earnedDate,
      Value<String?> openedDate,
    });
typedef $$ChestStatesTableUpdateCompanionBuilder =
    ChestStatesCompanion Function({
      Value<int> id,
      Value<String?> earnedDate,
      Value<String?> openedDate,
    });

class $$ChestStatesTableFilterComposer
    extends Composer<_$AppDb, $ChestStatesTable> {
  $$ChestStatesTableFilterComposer({
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

  ColumnFilters<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedDate => $composableBuilder(
    column: $table.openedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChestStatesTableOrderingComposer
    extends Composer<_$AppDb, $ChestStatesTable> {
  $$ChestStatesTableOrderingComposer({
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

  ColumnOrderings<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedDate => $composableBuilder(
    column: $table.openedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChestStatesTableAnnotationComposer
    extends Composer<_$AppDb, $ChestStatesTable> {
  $$ChestStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openedDate => $composableBuilder(
    column: $table.openedDate,
    builder: (column) => column,
  );
}

class $$ChestStatesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ChestStatesTable,
          ChestState,
          $$ChestStatesTableFilterComposer,
          $$ChestStatesTableOrderingComposer,
          $$ChestStatesTableAnnotationComposer,
          $$ChestStatesTableCreateCompanionBuilder,
          $$ChestStatesTableUpdateCompanionBuilder,
          (ChestState, BaseReferences<_$AppDb, $ChestStatesTable, ChestState>),
          ChestState,
          PrefetchHooks Function()
        > {
  $$ChestStatesTableTableManager(_$AppDb db, $ChestStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChestStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChestStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChestStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> earnedDate = const Value.absent(),
                Value<String?> openedDate = const Value.absent(),
              }) => ChestStatesCompanion(
                id: id,
                earnedDate: earnedDate,
                openedDate: openedDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> earnedDate = const Value.absent(),
                Value<String?> openedDate = const Value.absent(),
              }) => ChestStatesCompanion.insert(
                id: id,
                earnedDate: earnedDate,
                openedDate: openedDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChestStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ChestStatesTable,
      ChestState,
      $$ChestStatesTableFilterComposer,
      $$ChestStatesTableOrderingComposer,
      $$ChestStatesTableAnnotationComposer,
      $$ChestStatesTableCreateCompanionBuilder,
      $$ChestStatesTableUpdateCompanionBuilder,
      (ChestState, BaseReferences<_$AppDb, $ChestStatesTable, ChestState>),
      ChestState,
      PrefetchHooks Function()
    >;
typedef $$LocalGoalsTableCreateCompanionBuilder =
    LocalGoalsCompanion Function({
      required String id,
      required String name,
      required double targetAmount,
      Value<String> emoji,
      Value<String?> deadline,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalGoalsTableUpdateCompanionBuilder =
    LocalGoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> targetAmount,
      Value<String> emoji,
      Value<String?> deadline,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalGoalsTableFilterComposer
    extends Composer<_$AppDb, $LocalGoalsTable> {
  $$LocalGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalGoalsTableOrderingComposer
    extends Composer<_$AppDb, $LocalGoalsTable> {
  $$LocalGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalGoalsTableAnnotationComposer
    extends Composer<_$AppDb, $LocalGoalsTable> {
  $$LocalGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LocalGoalsTable,
          LocalGoal,
          $$LocalGoalsTableFilterComposer,
          $$LocalGoalsTableOrderingComposer,
          $$LocalGoalsTableAnnotationComposer,
          $$LocalGoalsTableCreateCompanionBuilder,
          $$LocalGoalsTableUpdateCompanionBuilder,
          (LocalGoal, BaseReferences<_$AppDb, $LocalGoalsTable, LocalGoal>),
          LocalGoal,
          PrefetchHooks Function()
        > {
  $$LocalGoalsTableTableManager(_$AppDb db, $LocalGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> targetAmount = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String?> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGoalsCompanion(
                id: id,
                name: name,
                targetAmount: targetAmount,
                emoji: emoji,
                deadline: deadline,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double targetAmount,
                Value<String> emoji = const Value.absent(),
                Value<String?> deadline = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalGoalsCompanion.insert(
                id: id,
                name: name,
                targetAmount: targetAmount,
                emoji: emoji,
                deadline: deadline,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LocalGoalsTable,
      LocalGoal,
      $$LocalGoalsTableFilterComposer,
      $$LocalGoalsTableOrderingComposer,
      $$LocalGoalsTableAnnotationComposer,
      $$LocalGoalsTableCreateCompanionBuilder,
      $$LocalGoalsTableUpdateCompanionBuilder,
      (LocalGoal, BaseReferences<_$AppDb, $LocalGoalsTable, LocalGoal>),
      LocalGoal,
      PrefetchHooks Function()
    >;
typedef $$LocalRecurringTableCreateCompanionBuilder =
    LocalRecurringCompanion Function({
      required String id,
      required String merchant,
      required double amount,
      required String category,
      Value<String> type,
      Value<String> frequency,
      required String nextDueDate,
      Value<bool> active,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalRecurringTableUpdateCompanionBuilder =
    LocalRecurringCompanion Function({
      Value<String> id,
      Value<String> merchant,
      Value<double> amount,
      Value<String> category,
      Value<String> type,
      Value<String> frequency,
      Value<String> nextDueDate,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalRecurringTableFilterComposer
    extends Composer<_$AppDb, $LocalRecurringTable> {
  $$LocalRecurringTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecurringTableOrderingComposer
    extends Composer<_$AppDb, $LocalRecurringTable> {
  $$LocalRecurringTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecurringTableAnnotationComposer
    extends Composer<_$AppDb, $LocalRecurringTable> {
  $$LocalRecurringTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalRecurringTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LocalRecurringTable,
          LocalRecurringData,
          $$LocalRecurringTableFilterComposer,
          $$LocalRecurringTableOrderingComposer,
          $$LocalRecurringTableAnnotationComposer,
          $$LocalRecurringTableCreateCompanionBuilder,
          $$LocalRecurringTableUpdateCompanionBuilder,
          (
            LocalRecurringData,
            BaseReferences<_$AppDb, $LocalRecurringTable, LocalRecurringData>,
          ),
          LocalRecurringData,
          PrefetchHooks Function()
        > {
  $$LocalRecurringTableTableManager(_$AppDb db, $LocalRecurringTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecurringTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRecurringTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRecurringTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> nextDueDate = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringCompanion(
                id: id,
                merchant: merchant,
                amount: amount,
                category: category,
                type: type,
                frequency: frequency,
                nextDueDate: nextDueDate,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String merchant,
                required double amount,
                required String category,
                Value<String> type = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                required String nextDueDate,
                Value<bool> active = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringCompanion.insert(
                id: id,
                merchant: merchant,
                amount: amount,
                category: category,
                type: type,
                frequency: frequency,
                nextDueDate: nextDueDate,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecurringTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LocalRecurringTable,
      LocalRecurringData,
      $$LocalRecurringTableFilterComposer,
      $$LocalRecurringTableOrderingComposer,
      $$LocalRecurringTableAnnotationComposer,
      $$LocalRecurringTableCreateCompanionBuilder,
      $$LocalRecurringTableUpdateCompanionBuilder,
      (
        LocalRecurringData,
        BaseReferences<_$AppDb, $LocalRecurringTable, LocalRecurringData>,
      ),
      LocalRecurringData,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressRowsTableCreateCompanionBuilder =
    LessonProgressRowsCompanion Function({
      required String lessonId,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$LessonProgressRowsTableUpdateCompanionBuilder =
    LessonProgressRowsCompanion Function({
      Value<String> lessonId,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$LessonProgressRowsTableFilterComposer
    extends Composer<_$AppDb, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressRowsTableOrderingComposer
    extends Composer<_$AppDb, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressRowsTableAnnotationComposer
    extends Composer<_$AppDb, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$LessonProgressRowsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LessonProgressRowsTable,
          LessonProgressRow,
          $$LessonProgressRowsTableFilterComposer,
          $$LessonProgressRowsTableOrderingComposer,
          $$LessonProgressRowsTableAnnotationComposer,
          $$LessonProgressRowsTableCreateCompanionBuilder,
          $$LessonProgressRowsTableUpdateCompanionBuilder,
          (
            LessonProgressRow,
            BaseReferences<
              _$AppDb,
              $LessonProgressRowsTable,
              LessonProgressRow
            >,
          ),
          LessonProgressRow,
          PrefetchHooks Function()
        > {
  $$LessonProgressRowsTableTableManager(
    _$AppDb db,
    $LessonProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressRowsCompanion(
                lessonId: lessonId,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressRowsCompanion.insert(
                lessonId: lessonId,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LessonProgressRowsTable,
      LessonProgressRow,
      $$LessonProgressRowsTableFilterComposer,
      $$LessonProgressRowsTableOrderingComposer,
      $$LessonProgressRowsTableAnnotationComposer,
      $$LessonProgressRowsTableCreateCompanionBuilder,
      $$LessonProgressRowsTableUpdateCompanionBuilder,
      (
        LessonProgressRow,
        BaseReferences<_$AppDb, $LessonProgressRowsTable, LessonProgressRow>,
      ),
      LessonProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewCardsTableCreateCompanionBuilder =
    ReviewCardsCompanion Function({
      required String cardId,
      required String lessonId,
      Value<int> box,
      required String nextDue,
      Value<int> lapses,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<String?> lastReview,
      Value<int> rowid,
    });
typedef $$ReviewCardsTableUpdateCompanionBuilder =
    ReviewCardsCompanion Function({
      Value<String> cardId,
      Value<String> lessonId,
      Value<int> box,
      Value<String> nextDue,
      Value<int> lapses,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<String?> lastReview,
      Value<int> rowid,
    });

class $$ReviewCardsTableFilterComposer
    extends Composer<_$AppDb, $ReviewCardsTable> {
  $$ReviewCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewCardsTableOrderingComposer
    extends Composer<_$AppDb, $ReviewCardsTable> {
  $$ReviewCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewCardsTableAnnotationComposer
    extends Composer<_$AppDb, $ReviewCardsTable> {
  $$ReviewCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<String> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );
}

class $$ReviewCardsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ReviewCardsTable,
          ReviewCard,
          $$ReviewCardsTableFilterComposer,
          $$ReviewCardsTableOrderingComposer,
          $$ReviewCardsTableAnnotationComposer,
          $$ReviewCardsTableCreateCompanionBuilder,
          $$ReviewCardsTableUpdateCompanionBuilder,
          (ReviewCard, BaseReferences<_$AppDb, $ReviewCardsTable, ReviewCard>),
          ReviewCard,
          PrefetchHooks Function()
        > {
  $$ReviewCardsTableTableManager(_$AppDb db, $ReviewCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<String> nextDue = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<String?> lastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion(
                cardId: cardId,
                lessonId: lessonId,
                box: box,
                nextDue: nextDue,
                lapses: lapses,
                stability: stability,
                difficulty: difficulty,
                lastReview: lastReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cardId,
                required String lessonId,
                Value<int> box = const Value.absent(),
                required String nextDue,
                Value<int> lapses = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<String?> lastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion.insert(
                cardId: cardId,
                lessonId: lessonId,
                box: box,
                nextDue: nextDue,
                lapses: lapses,
                stability: stability,
                difficulty: difficulty,
                lastReview: lastReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ReviewCardsTable,
      ReviewCard,
      $$ReviewCardsTableFilterComposer,
      $$ReviewCardsTableOrderingComposer,
      $$ReviewCardsTableAnnotationComposer,
      $$ReviewCardsTableCreateCompanionBuilder,
      $$ReviewCardsTableUpdateCompanionBuilder,
      (ReviewCard, BaseReferences<_$AppDb, $ReviewCardsTable, ReviewCard>),
      ReviewCard,
      PrefetchHooks Function()
    >;
typedef $$ArcadeRoundsTableCreateCompanionBuilder =
    ArcadeRoundsCompanion Function({
      Value<int> id,
      required String game,
      required String date,
      required int score,
      Value<String> meta,
    });
typedef $$ArcadeRoundsTableUpdateCompanionBuilder =
    ArcadeRoundsCompanion Function({
      Value<int> id,
      Value<String> game,
      Value<String> date,
      Value<int> score,
      Value<String> meta,
    });

class $$ArcadeRoundsTableFilterComposer
    extends Composer<_$AppDb, $ArcadeRoundsTable> {
  $$ArcadeRoundsTableFilterComposer({
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

  ColumnFilters<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArcadeRoundsTableOrderingComposer
    extends Composer<_$AppDb, $ArcadeRoundsTable> {
  $$ArcadeRoundsTableOrderingComposer({
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

  ColumnOrderings<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArcadeRoundsTableAnnotationComposer
    extends Composer<_$AppDb, $ArcadeRoundsTable> {
  $$ArcadeRoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);
}

class $$ArcadeRoundsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ArcadeRoundsTable,
          ArcadeRound,
          $$ArcadeRoundsTableFilterComposer,
          $$ArcadeRoundsTableOrderingComposer,
          $$ArcadeRoundsTableAnnotationComposer,
          $$ArcadeRoundsTableCreateCompanionBuilder,
          $$ArcadeRoundsTableUpdateCompanionBuilder,
          (
            ArcadeRound,
            BaseReferences<_$AppDb, $ArcadeRoundsTable, ArcadeRound>,
          ),
          ArcadeRound,
          PrefetchHooks Function()
        > {
  $$ArcadeRoundsTableTableManager(_$AppDb db, $ArcadeRoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArcadeRoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArcadeRoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArcadeRoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> game = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> meta = const Value.absent(),
              }) => ArcadeRoundsCompanion(
                id: id,
                game: game,
                date: date,
                score: score,
                meta: meta,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String game,
                required String date,
                required int score,
                Value<String> meta = const Value.absent(),
              }) => ArcadeRoundsCompanion.insert(
                id: id,
                game: game,
                date: date,
                score: score,
                meta: meta,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArcadeRoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ArcadeRoundsTable,
      ArcadeRound,
      $$ArcadeRoundsTableFilterComposer,
      $$ArcadeRoundsTableOrderingComposer,
      $$ArcadeRoundsTableAnnotationComposer,
      $$ArcadeRoundsTableCreateCompanionBuilder,
      $$ArcadeRoundsTableUpdateCompanionBuilder,
      (ArcadeRound, BaseReferences<_$AppDb, $ArcadeRoundsTable, ArcadeRound>),
      ArcadeRound,
      PrefetchHooks Function()
    >;
typedef $$DojoStatesTableCreateCompanionBuilder =
    DojoStatesCompanion Function({
      Value<int> id,
      Value<int> rating,
      Value<int> rounds,
    });
typedef $$DojoStatesTableUpdateCompanionBuilder =
    DojoStatesCompanion Function({
      Value<int> id,
      Value<int> rating,
      Value<int> rounds,
    });

class $$DojoStatesTableFilterComposer
    extends Composer<_$AppDb, $DojoStatesTable> {
  $$DojoStatesTableFilterComposer({
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

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DojoStatesTableOrderingComposer
    extends Composer<_$AppDb, $DojoStatesTable> {
  $$DojoStatesTableOrderingComposer({
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

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DojoStatesTableAnnotationComposer
    extends Composer<_$AppDb, $DojoStatesTable> {
  $$DojoStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => column);
}

class $$DojoStatesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DojoStatesTable,
          DojoState,
          $$DojoStatesTableFilterComposer,
          $$DojoStatesTableOrderingComposer,
          $$DojoStatesTableAnnotationComposer,
          $$DojoStatesTableCreateCompanionBuilder,
          $$DojoStatesTableUpdateCompanionBuilder,
          (DojoState, BaseReferences<_$AppDb, $DojoStatesTable, DojoState>),
          DojoState,
          PrefetchHooks Function()
        > {
  $$DojoStatesTableTableManager(_$AppDb db, $DojoStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DojoStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DojoStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DojoStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> rounds = const Value.absent(),
              }) => DojoStatesCompanion(id: id, rating: rating, rounds: rounds),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> rounds = const Value.absent(),
              }) => DojoStatesCompanion.insert(
                id: id,
                rating: rating,
                rounds: rounds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DojoStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DojoStatesTable,
      DojoState,
      $$DojoStatesTableFilterComposer,
      $$DojoStatesTableOrderingComposer,
      $$DojoStatesTableAnnotationComposer,
      $$DojoStatesTableCreateCompanionBuilder,
      $$DojoStatesTableUpdateCompanionBuilder,
      (DojoState, BaseReferences<_$AppDb, $DojoStatesTable, DojoState>),
      DojoState,
      PrefetchHooks Function()
    >;
typedef $$DojoItemStatsTableCreateCompanionBuilder =
    DojoItemStatsCompanion Function({
      required String itemId,
      required int rating,
      Value<int> plays,
      Value<int> correct,
      Value<int> lastSeenRound,
      Value<int> rowid,
    });
typedef $$DojoItemStatsTableUpdateCompanionBuilder =
    DojoItemStatsCompanion Function({
      Value<String> itemId,
      Value<int> rating,
      Value<int> plays,
      Value<int> correct,
      Value<int> lastSeenRound,
      Value<int> rowid,
    });

class $$DojoItemStatsTableFilterComposer
    extends Composer<_$AppDb, $DojoItemStatsTable> {
  $$DojoItemStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenRound => $composableBuilder(
    column: $table.lastSeenRound,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DojoItemStatsTableOrderingComposer
    extends Composer<_$AppDb, $DojoItemStatsTable> {
  $$DojoItemStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenRound => $composableBuilder(
    column: $table.lastSeenRound,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DojoItemStatsTableAnnotationComposer
    extends Composer<_$AppDb, $DojoItemStatsTable> {
  $$DojoItemStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get plays =>
      $composableBuilder(column: $table.plays, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get lastSeenRound => $composableBuilder(
    column: $table.lastSeenRound,
    builder: (column) => column,
  );
}

class $$DojoItemStatsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DojoItemStatsTable,
          DojoItemStat,
          $$DojoItemStatsTableFilterComposer,
          $$DojoItemStatsTableOrderingComposer,
          $$DojoItemStatsTableAnnotationComposer,
          $$DojoItemStatsTableCreateCompanionBuilder,
          $$DojoItemStatsTableUpdateCompanionBuilder,
          (
            DojoItemStat,
            BaseReferences<_$AppDb, $DojoItemStatsTable, DojoItemStat>,
          ),
          DojoItemStat,
          PrefetchHooks Function()
        > {
  $$DojoItemStatsTableTableManager(_$AppDb db, $DojoItemStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DojoItemStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DojoItemStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DojoItemStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> plays = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> lastSeenRound = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DojoItemStatsCompanion(
                itemId: itemId,
                rating: rating,
                plays: plays,
                correct: correct,
                lastSeenRound: lastSeenRound,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required int rating,
                Value<int> plays = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> lastSeenRound = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DojoItemStatsCompanion.insert(
                itemId: itemId,
                rating: rating,
                plays: plays,
                correct: correct,
                lastSeenRound: lastSeenRound,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DojoItemStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DojoItemStatsTable,
      DojoItemStat,
      $$DojoItemStatsTableFilterComposer,
      $$DojoItemStatsTableOrderingComposer,
      $$DojoItemStatsTableAnnotationComposer,
      $$DojoItemStatsTableCreateCompanionBuilder,
      $$DojoItemStatsTableUpdateCompanionBuilder,
      (
        DojoItemStat,
        BaseReferences<_$AppDb, $DojoItemStatsTable, DojoItemStat>,
      ),
      DojoItemStat,
      PrefetchHooks Function()
    >;
typedef $$WardrobeItemsTableCreateCompanionBuilder =
    WardrobeItemsCompanion Function({
      required String itemId,
      required DateTime acquiredAt,
      Value<int> rowid,
    });
typedef $$WardrobeItemsTableUpdateCompanionBuilder =
    WardrobeItemsCompanion Function({
      Value<String> itemId,
      Value<DateTime> acquiredAt,
      Value<int> rowid,
    });

class $$WardrobeItemsTableFilterComposer
    extends Composer<_$AppDb, $WardrobeItemsTable> {
  $$WardrobeItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardrobeItemsTableOrderingComposer
    extends Composer<_$AppDb, $WardrobeItemsTable> {
  $$WardrobeItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardrobeItemsTableAnnotationComposer
    extends Composer<_$AppDb, $WardrobeItemsTable> {
  $$WardrobeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => column,
  );
}

class $$WardrobeItemsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WardrobeItemsTable,
          WardrobeItem,
          $$WardrobeItemsTableFilterComposer,
          $$WardrobeItemsTableOrderingComposer,
          $$WardrobeItemsTableAnnotationComposer,
          $$WardrobeItemsTableCreateCompanionBuilder,
          $$WardrobeItemsTableUpdateCompanionBuilder,
          (
            WardrobeItem,
            BaseReferences<_$AppDb, $WardrobeItemsTable, WardrobeItem>,
          ),
          WardrobeItem,
          PrefetchHooks Function()
        > {
  $$WardrobeItemsTableTableManager(_$AppDb db, $WardrobeItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<DateTime> acquiredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardrobeItemsCompanion(
                itemId: itemId,
                acquiredAt: acquiredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required DateTime acquiredAt,
                Value<int> rowid = const Value.absent(),
              }) => WardrobeItemsCompanion.insert(
                itemId: itemId,
                acquiredAt: acquiredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardrobeItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WardrobeItemsTable,
      WardrobeItem,
      $$WardrobeItemsTableFilterComposer,
      $$WardrobeItemsTableOrderingComposer,
      $$WardrobeItemsTableAnnotationComposer,
      $$WardrobeItemsTableCreateCompanionBuilder,
      $$WardrobeItemsTableUpdateCompanionBuilder,
      (
        WardrobeItem,
        BaseReferences<_$AppDb, $WardrobeItemsTable, WardrobeItem>,
      ),
      WardrobeItem,
      PrefetchHooks Function()
    >;
typedef $$InsightEventsTableCreateCompanionBuilder =
    InsightEventsCompanion Function({
      Value<int> id,
      required String insightId,
      required String ruleKey,
      required String kind,
      required String event,
      required DateTime createdAt,
      Value<int?> arm,
      Value<double?> propensity,
    });
typedef $$InsightEventsTableUpdateCompanionBuilder =
    InsightEventsCompanion Function({
      Value<int> id,
      Value<String> insightId,
      Value<String> ruleKey,
      Value<String> kind,
      Value<String> event,
      Value<DateTime> createdAt,
      Value<int?> arm,
      Value<double?> propensity,
    });

class $$InsightEventsTableFilterComposer
    extends Composer<_$AppDb, $InsightEventsTable> {
  $$InsightEventsTableFilterComposer({
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

  ColumnFilters<String> get insightId => $composableBuilder(
    column: $table.insightId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleKey => $composableBuilder(
    column: $table.ruleKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get arm => $composableBuilder(
    column: $table.arm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get propensity => $composableBuilder(
    column: $table.propensity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InsightEventsTableOrderingComposer
    extends Composer<_$AppDb, $InsightEventsTable> {
  $$InsightEventsTableOrderingComposer({
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

  ColumnOrderings<String> get insightId => $composableBuilder(
    column: $table.insightId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleKey => $composableBuilder(
    column: $table.ruleKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get arm => $composableBuilder(
    column: $table.arm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get propensity => $composableBuilder(
    column: $table.propensity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InsightEventsTableAnnotationComposer
    extends Composer<_$AppDb, $InsightEventsTable> {
  $$InsightEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get insightId =>
      $composableBuilder(column: $table.insightId, builder: (column) => column);

  GeneratedColumn<String> get ruleKey =>
      $composableBuilder(column: $table.ruleKey, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get event =>
      $composableBuilder(column: $table.event, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get arm =>
      $composableBuilder(column: $table.arm, builder: (column) => column);

  GeneratedColumn<double> get propensity => $composableBuilder(
    column: $table.propensity,
    builder: (column) => column,
  );
}

class $$InsightEventsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $InsightEventsTable,
          InsightEvent,
          $$InsightEventsTableFilterComposer,
          $$InsightEventsTableOrderingComposer,
          $$InsightEventsTableAnnotationComposer,
          $$InsightEventsTableCreateCompanionBuilder,
          $$InsightEventsTableUpdateCompanionBuilder,
          (
            InsightEvent,
            BaseReferences<_$AppDb, $InsightEventsTable, InsightEvent>,
          ),
          InsightEvent,
          PrefetchHooks Function()
        > {
  $$InsightEventsTableTableManager(_$AppDb db, $InsightEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsightEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsightEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsightEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> insightId = const Value.absent(),
                Value<String> ruleKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> event = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> arm = const Value.absent(),
                Value<double?> propensity = const Value.absent(),
              }) => InsightEventsCompanion(
                id: id,
                insightId: insightId,
                ruleKey: ruleKey,
                kind: kind,
                event: event,
                createdAt: createdAt,
                arm: arm,
                propensity: propensity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String insightId,
                required String ruleKey,
                required String kind,
                required String event,
                required DateTime createdAt,
                Value<int?> arm = const Value.absent(),
                Value<double?> propensity = const Value.absent(),
              }) => InsightEventsCompanion.insert(
                id: id,
                insightId: insightId,
                ruleKey: ruleKey,
                kind: kind,
                event: event,
                createdAt: createdAt,
                arm: arm,
                propensity: propensity,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InsightEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $InsightEventsTable,
      InsightEvent,
      $$InsightEventsTableFilterComposer,
      $$InsightEventsTableOrderingComposer,
      $$InsightEventsTableAnnotationComposer,
      $$InsightEventsTableCreateCompanionBuilder,
      $$InsightEventsTableUpdateCompanionBuilder,
      (
        InsightEvent,
        BaseReferences<_$AppDb, $InsightEventsTable, InsightEvent>,
      ),
      InsightEvent,
      PrefetchHooks Function()
    >;
typedef $$ExpeditionRowsTableCreateCompanionBuilder =
    ExpeditionRowsCompanion Function({
      required String day,
      required DateTime departedAt,
      Value<DateTime?> collectedAt,
      required int reward,
      Value<int> rowid,
    });
typedef $$ExpeditionRowsTableUpdateCompanionBuilder =
    ExpeditionRowsCompanion Function({
      Value<String> day,
      Value<DateTime> departedAt,
      Value<DateTime?> collectedAt,
      Value<int> reward,
      Value<int> rowid,
    });

class $$ExpeditionRowsTableFilterComposer
    extends Composer<_$AppDb, $ExpeditionRowsTable> {
  $$ExpeditionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reward => $composableBuilder(
    column: $table.reward,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpeditionRowsTableOrderingComposer
    extends Composer<_$AppDb, $ExpeditionRowsTable> {
  $$ExpeditionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reward => $composableBuilder(
    column: $table.reward,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpeditionRowsTableAnnotationComposer
    extends Composer<_$AppDb, $ExpeditionRowsTable> {
  $$ExpeditionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reward =>
      $composableBuilder(column: $table.reward, builder: (column) => column);
}

class $$ExpeditionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ExpeditionRowsTable,
          ExpeditionRow,
          $$ExpeditionRowsTableFilterComposer,
          $$ExpeditionRowsTableOrderingComposer,
          $$ExpeditionRowsTableAnnotationComposer,
          $$ExpeditionRowsTableCreateCompanionBuilder,
          $$ExpeditionRowsTableUpdateCompanionBuilder,
          (
            ExpeditionRow,
            BaseReferences<_$AppDb, $ExpeditionRowsTable, ExpeditionRow>,
          ),
          ExpeditionRow,
          PrefetchHooks Function()
        > {
  $$ExpeditionRowsTableTableManager(_$AppDb db, $ExpeditionRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpeditionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpeditionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpeditionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<DateTime> departedAt = const Value.absent(),
                Value<DateTime?> collectedAt = const Value.absent(),
                Value<int> reward = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpeditionRowsCompanion(
                day: day,
                departedAt: departedAt,
                collectedAt: collectedAt,
                reward: reward,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required DateTime departedAt,
                Value<DateTime?> collectedAt = const Value.absent(),
                required int reward,
                Value<int> rowid = const Value.absent(),
              }) => ExpeditionRowsCompanion.insert(
                day: day,
                departedAt: departedAt,
                collectedAt: collectedAt,
                reward: reward,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpeditionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ExpeditionRowsTable,
      ExpeditionRow,
      $$ExpeditionRowsTableFilterComposer,
      $$ExpeditionRowsTableOrderingComposer,
      $$ExpeditionRowsTableAnnotationComposer,
      $$ExpeditionRowsTableCreateCompanionBuilder,
      $$ExpeditionRowsTableUpdateCompanionBuilder,
      (
        ExpeditionRow,
        BaseReferences<_$AppDb, $ExpeditionRowsTable, ExpeditionRow>,
      ),
      ExpeditionRow,
      PrefetchHooks Function()
    >;
typedef $$LifeSimRunsTableCreateCompanionBuilder =
    LifeSimRunsCompanion Function({
      required String id,
      required int seed,
      required String roleId,
      required String goalId,
      required String mode,
      required String contentVersion,
      Value<int> day,
      required String stateJson,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<String?> resultJson,
      Value<int> rowid,
    });
typedef $$LifeSimRunsTableUpdateCompanionBuilder =
    LifeSimRunsCompanion Function({
      Value<String> id,
      Value<int> seed,
      Value<String> roleId,
      Value<String> goalId,
      Value<String> mode,
      Value<String> contentVersion,
      Value<int> day,
      Value<String> stateJson,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> resultJson,
      Value<int> rowid,
    });

class $$LifeSimRunsTableFilterComposer
    extends Composer<_$AppDb, $LifeSimRunsTable> {
  $$LifeSimRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LifeSimRunsTableOrderingComposer
    extends Composer<_$AppDb, $LifeSimRunsTable> {
  $$LifeSimRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LifeSimRunsTableAnnotationComposer
    extends Composer<_$AppDb, $LifeSimRunsTable> {
  $$LifeSimRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );
}

class $$LifeSimRunsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LifeSimRunsTable,
          LifeSimRun,
          $$LifeSimRunsTableFilterComposer,
          $$LifeSimRunsTableOrderingComposer,
          $$LifeSimRunsTableAnnotationComposer,
          $$LifeSimRunsTableCreateCompanionBuilder,
          $$LifeSimRunsTableUpdateCompanionBuilder,
          (LifeSimRun, BaseReferences<_$AppDb, $LifeSimRunsTable, LifeSimRun>),
          LifeSimRun,
          PrefetchHooks Function()
        > {
  $$LifeSimRunsTableTableManager(_$AppDb db, $LifeSimRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeSimRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeSimRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeSimRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifeSimRunsCompanion(
                id: id,
                seed: seed,
                roleId: roleId,
                goalId: goalId,
                mode: mode,
                contentVersion: contentVersion,
                day: day,
                stateJson: stateJson,
                startedAt: startedAt,
                completedAt: completedAt,
                resultJson: resultJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int seed,
                required String roleId,
                required String goalId,
                required String mode,
                required String contentVersion,
                Value<int> day = const Value.absent(),
                required String stateJson,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifeSimRunsCompanion.insert(
                id: id,
                seed: seed,
                roleId: roleId,
                goalId: goalId,
                mode: mode,
                contentVersion: contentVersion,
                day: day,
                stateJson: stateJson,
                startedAt: startedAt,
                completedAt: completedAt,
                resultJson: resultJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LifeSimRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LifeSimRunsTable,
      LifeSimRun,
      $$LifeSimRunsTableFilterComposer,
      $$LifeSimRunsTableOrderingComposer,
      $$LifeSimRunsTableAnnotationComposer,
      $$LifeSimRunsTableCreateCompanionBuilder,
      $$LifeSimRunsTableUpdateCompanionBuilder,
      (LifeSimRun, BaseReferences<_$AppDb, $LifeSimRunsTable, LifeSimRun>),
      LifeSimRun,
      PrefetchHooks Function()
    >;
typedef $$LifeSimDecisionsTableCreateCompanionBuilder =
    LifeSimDecisionsCompanion Function({
      Value<int> id,
      required String runId,
      required int day,
      required String eventId,
      required int choiceIdx,
      required DateTime createdAt,
    });
typedef $$LifeSimDecisionsTableUpdateCompanionBuilder =
    LifeSimDecisionsCompanion Function({
      Value<int> id,
      Value<String> runId,
      Value<int> day,
      Value<String> eventId,
      Value<int> choiceIdx,
      Value<DateTime> createdAt,
    });

class $$LifeSimDecisionsTableFilterComposer
    extends Composer<_$AppDb, $LifeSimDecisionsTable> {
  $$LifeSimDecisionsTableFilterComposer({
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

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get choiceIdx => $composableBuilder(
    column: $table.choiceIdx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LifeSimDecisionsTableOrderingComposer
    extends Composer<_$AppDb, $LifeSimDecisionsTable> {
  $$LifeSimDecisionsTableOrderingComposer({
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

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get choiceIdx => $composableBuilder(
    column: $table.choiceIdx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LifeSimDecisionsTableAnnotationComposer
    extends Composer<_$AppDb, $LifeSimDecisionsTable> {
  $$LifeSimDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get choiceIdx =>
      $composableBuilder(column: $table.choiceIdx, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LifeSimDecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $LifeSimDecisionsTable,
          LifeSimDecision,
          $$LifeSimDecisionsTableFilterComposer,
          $$LifeSimDecisionsTableOrderingComposer,
          $$LifeSimDecisionsTableAnnotationComposer,
          $$LifeSimDecisionsTableCreateCompanionBuilder,
          $$LifeSimDecisionsTableUpdateCompanionBuilder,
          (
            LifeSimDecision,
            BaseReferences<_$AppDb, $LifeSimDecisionsTable, LifeSimDecision>,
          ),
          LifeSimDecision,
          PrefetchHooks Function()
        > {
  $$LifeSimDecisionsTableTableManager(_$AppDb db, $LifeSimDecisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeSimDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeSimDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeSimDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> choiceIdx = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LifeSimDecisionsCompanion(
                id: id,
                runId: runId,
                day: day,
                eventId: eventId,
                choiceIdx: choiceIdx,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String runId,
                required int day,
                required String eventId,
                required int choiceIdx,
                required DateTime createdAt,
              }) => LifeSimDecisionsCompanion.insert(
                id: id,
                runId: runId,
                day: day,
                eventId: eventId,
                choiceIdx: choiceIdx,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LifeSimDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $LifeSimDecisionsTable,
      LifeSimDecision,
      $$LifeSimDecisionsTableFilterComposer,
      $$LifeSimDecisionsTableOrderingComposer,
      $$LifeSimDecisionsTableAnnotationComposer,
      $$LifeSimDecisionsTableCreateCompanionBuilder,
      $$LifeSimDecisionsTableUpdateCompanionBuilder,
      (
        LifeSimDecision,
        BaseReferences<_$AppDb, $LifeSimDecisionsTable, LifeSimDecision>,
      ),
      LifeSimDecision,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$NoSpendDaysTableTableManager get noSpendDays =>
      $$NoSpendDaysTableTableManager(_db, _db.noSpendDays);
  $$DailyActivityRowsTableTableManager get dailyActivityRows =>
      $$DailyActivityRowsTableTableManager(_db, _db.dailyActivityRows);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$StreakStatesTableTableManager get streakStates =>
      $$StreakStatesTableTableManager(_db, _db.streakStates);
  $$AcornEntriesTableTableManager get acornEntries =>
      $$AcornEntriesTableTableManager(_db, _db.acornEntries);
  $$QuestClaimsTableTableManager get questClaims =>
      $$QuestClaimsTableTableManager(_db, _db.questClaims);
  $$ChestStatesTableTableManager get chestStates =>
      $$ChestStatesTableTableManager(_db, _db.chestStates);
  $$LocalGoalsTableTableManager get localGoals =>
      $$LocalGoalsTableTableManager(_db, _db.localGoals);
  $$LocalRecurringTableTableManager get localRecurring =>
      $$LocalRecurringTableTableManager(_db, _db.localRecurring);
  $$LessonProgressRowsTableTableManager get lessonProgressRows =>
      $$LessonProgressRowsTableTableManager(_db, _db.lessonProgressRows);
  $$ReviewCardsTableTableManager get reviewCards =>
      $$ReviewCardsTableTableManager(_db, _db.reviewCards);
  $$ArcadeRoundsTableTableManager get arcadeRounds =>
      $$ArcadeRoundsTableTableManager(_db, _db.arcadeRounds);
  $$DojoStatesTableTableManager get dojoStates =>
      $$DojoStatesTableTableManager(_db, _db.dojoStates);
  $$DojoItemStatsTableTableManager get dojoItemStats =>
      $$DojoItemStatsTableTableManager(_db, _db.dojoItemStats);
  $$WardrobeItemsTableTableManager get wardrobeItems =>
      $$WardrobeItemsTableTableManager(_db, _db.wardrobeItems);
  $$InsightEventsTableTableManager get insightEvents =>
      $$InsightEventsTableTableManager(_db, _db.insightEvents);
  $$ExpeditionRowsTableTableManager get expeditionRows =>
      $$ExpeditionRowsTableTableManager(_db, _db.expeditionRows);
  $$LifeSimRunsTableTableManager get lifeSimRuns =>
      $$LifeSimRunsTableTableManager(_db, _db.lifeSimRuns);
  $$LifeSimDecisionsTableTableManager get lifeSimDecisions =>
      $$LifeSimDecisionsTableTableManager(_db, _db.lifeSimDecisions);
}
