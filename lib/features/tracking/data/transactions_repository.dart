import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/util/day_key.dart';
import 'transaction_mapper.dart';

export '../../../domain/util/day_key.dart' show dayKey;

/// Writes merg în drift local, un outbox pentru sync (debounced) și
/// marchează activitatea zilei, niciodată direct pe rețea.
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return TransactionsRepository(
    ref.watch(appDbProvider),
    onWrite: engine.scheduleSync,
  );
});

/// Sumele cele mai frecvente ale userului, reîmprospătate la fiecare tranzacție.
final frequentAmountsProvider = StreamProvider<List<int>>((ref) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchRecent(1).asyncMap((_) => repo.frequentAmounts());
});

const _uuid = Uuid();

/// Repository offline-first pentru logarea banilor. Writes sunt local + outbox;
/// [SyncEngine] golește outbox-ul când există sesiune; [onWrite] declanșează sync debounced.
class TransactionsRepository {
  TransactionsRepository(this._db, {this.onWrite});

  final AppDb _db;

  /// Apelat după fiecare mutație (declanșează un sync debounced).
  final void Function()? onWrite;

  // --- Reads -------------------------------------------------------------

  /// Urmărește ultimele [limit] tranzacții neșterse.
  Stream<List<Transaction>> watchRecent(int limit) {
    final query = _db.select(_db.localTransactions)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
      ..limit(limit);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Urmărește toate tranzacțiile neșterse din luna calendaristică a [month].
  Stream<List<Transaction>> watchMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final query = _db.select(_db.localTransactions)
      ..where((t) =>
          t.deleted.equals(false) &
          t.transactionDate.isBiggerOrEqualValue(start) &
          t.transactionDate.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Timestamp-urile `createdAt` ale ultimelor [limit] tranzacții, semnalul pentru
  /// ora preferată de notificare (nu `transactionDate`, ca să prindă CÂND a logat).
  Future<List<DateTime>> recentTimestamps(int limit) async {
    final rows = await (_db.select(_db.localTransactions)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map((r) => r.createdAt).toList();
  }

  /// Sumele întregi cele mai frecvente (chipuri de sumă rapidă): rotunjește
  /// la leu, numără aparițiile, întoarce primele [limit].
  Future<List<int>> frequentAmounts({int limit = 4}) async {
    final rows = await (_db.select(_db.localTransactions)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final counts = <int, int>{};
    for (final r in rows) {
      final rounded = r.amount.round();
      if (rounded <= 0) continue;
      counts[rounded] = (counts[rounded] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Ultimele [limit] cheltuieli ca (categorie, sumă, zi), date de antrenament
  /// pentru sugestia de categorie; `weekday` e ziua cheltuielii, nu ziua logării.
  Future<List<({String category, double amount, int weekday})>>
      recentExpenseFeatures({int limit = 120}) async {
    final rows = await (_db.select(_db.localTransactions)
          ..where((t) =>
              t.deleted.equals(false) &
              t.type.equals(TransactionType.expense.key))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .get();
    return [
      for (final r in rows)
        (
          category: r.category,
          amount: r.amount,
          weekday: r.transactionDate.weekday,
        ),
    ];
  }

  /// Urmărește zilele (day-key) cu activitate înregistrată, input pentru streak engine.
  Stream<Set<String>> watchActivityDays() {
    return _db
        .select(_db.dailyActivityRows)
        .watch()
        .map((rows) => rows.map((r) => r.date).toSet());
  }

  // --- Writes ------------------------------------------------------------

  /// Loghează o cheltuială (local + outbox + activitate 'log').
  Future<Transaction> addExpense({
    required double amount,
    required String category,
    String? merchant,
    String? note,
    DateTime? transactionDate,
    TransactionSource source = TransactionSource.manual,
  }) {
    return _add(
      type: TransactionType.expense,
      amount: amount,
      category: category,
      merchant: merchant,
      note: note,
      transactionDate: transactionDate,
      source: source,
    );
  }

  /// Loghează o economie (local + outbox + activitate 'log'). [goalId]
  /// atribuie opțional contribuția unui obiectiv.
  Future<Transaction> addSaving({
    required double amount,
    required String category,
    String? note,
    String? goalId,
    DateTime? transactionDate,
    TransactionSource source = TransactionSource.manual,
  }) {
    return _add(
      type: TransactionType.saving,
      amount: amount,
      category: category,
      note: note,
      goalId: goalId,
      transactionDate: transactionDate,
      source: source,
    );
  }

  Future<Transaction> _add({
    required TransactionType type,
    required double amount,
    required String category,
    String? merchant,
    String? note,
    String? goalId,
    DateTime? transactionDate,
    required TransactionSource source,
  }) async {
    final now = DateTime.now();
    final tx = Transaction(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      type: type,
      merchant: merchant,
      note: note,
      transactionDate: transactionDate ?? now,
      source: source,
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.localTransactions).insert(
            tx.toRow().copyWith(goalId: Value(goalId)),
          );
      await _enqueue(
          'upsert_transaction', _transactionPayload(tx, goalId: goalId));
      await _markActivity(dayKey(tx.transactionDate), 'log');
    });

    onWrite?.call();
    return tx;
  }

  /// Marchează azi ca zi fără cheltuieli. Idempotent (al doilea apel din
  /// aceeași zi nu face nimic) și înregistrează activitatea ca 'log'.
  Future<void> markNoSpendToday() async {
    final today = dayKey(DateTime.now());
    await _db.transaction(() async {
      final existing = await (_db.select(_db.noSpendDays)
            ..where((d) => d.date.equals(today)))
          .getSingleOrNull();
      if (existing != null) return; // idempotent

      await _db.into(_db.noSpendDays).insert(NoSpendDaysCompanion.insert(
            date: today,
          ));
      await _enqueue('mark_no_spend', {'date': today});
      await _markActivity(today, 'log');
    });
    onWrite?.call();
  }

  /// Șterge soft o tranzacție (setează `deleted`) și pune în coadă operația de delete.
  Future<void> softDelete(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.localTransactions)..where((t) => t.id.equals(id)))
          .write(LocalTransactionsCompanion(
        deleted: const Value(true),
        pendingSync: const Value(true),
        updatedAt: Value(now),
      ));
      await _enqueue('delete_transaction', {'id': id});
    });
    onWrite?.call();
  }

  // --- Internals ---------------------------------------------------------

  Future<void> _enqueue(String opType, Map<String, dynamic> payload) {
    return _db.into(_db.outboxEntries).insert(OutboxEntriesCompanion.insert(
          opType: opType,
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
        ));
  }

  /// Upsert pe rândul de activitate al zilei, adăugând [kind] în lista JSON
  /// `kinds` dacă lipsește.
  Future<void> _markActivity(String date, String kind) async {
    final row = await (_db.select(_db.dailyActivityRows)
          ..where((r) => r.date.equals(date)))
        .getSingleOrNull();

    final kinds = <String>{
      if (row != null) ...(jsonDecode(row.kinds) as List).cast<String>(),
      kind,
    }.toList();

    await _db.into(_db.dailyActivityRows).insertOnConflictUpdate(
          DailyActivityRowsCompanion.insert(
            date: date,
            kinds: jsonEncode(kinds),
          ),
        );
  }

  Map<String, dynamic> _transactionPayload(Transaction tx,
          {String? goalId}) =>
      {
        'client_id': tx.id,
        'amount': tx.amount,
        'category': tx.category,
        'type': tx.type.key,
        'merchant': tx.merchant,
        'note': tx.note,
        'goal_id': goalId,
        'transaction_date': tx.transactionDate.toUtc().toIso8601String(),
        'source': tx.source.key,
        'deleted': tx.deleted,
      };
}
