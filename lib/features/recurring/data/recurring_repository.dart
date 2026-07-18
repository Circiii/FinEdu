import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../domain/engine/recurring_materializer.dart';
import '../../../domain/models/transaction.dart';
import '../../tracking/data/transactions_repository.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(
    ref.watch(appDbProvider),
    ref.watch(transactionsRepositoryProvider),
  );
});

final recurringListProvider = StreamProvider<List<LocalRecurringData>>((ref) {
  return ref.watch(recurringRepositoryProvider).watchAll();
});

const _uuid = Uuid();

class RecurringRepository {
  RecurringRepository(this._db, this._transactions);

  final AppDb _db;
  final TransactionsRepository _transactions;

  Stream<List<LocalRecurringData>> watchAll() {
    return (_db.select(_db.localRecurring)
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
        .watch();
  }

  Future<void> add({
    required String merchant,
    required double amount,
    required String category,
    required String type,
    required String frequency,
    required String nextDueDate,
  }) {
    return _db.into(_db.localRecurring).insert(LocalRecurringCompanion.insert(
          id: _uuid.v4(),
          merchant: merchant,
          amount: amount,
          category: category,
          type: Value(type),
          frequency: Value(frequency),
          nextDueDate: nextDueDate,
          createdAt: DateTime.now(),
        ));
  }

  Future<void> setActive(String id, bool active) {
    return (_db.update(_db.localRecurring)..where((r) => r.id.equals(id)))
        .write(LocalRecurringCompanion(active: Value(active)));
  }

  Future<void> remove(String id) {
    return (_db.delete(_db.localRecurring)..where((r) => r.id.equals(id))).go();
  }

  /// Materializează aparițiile scadente ale recurentelor active în tranzacții
  /// reale (idempotent, avansează `nextDueDate`). Apelat la pornirea aplicației.
  Future<int> materializeDue() async {
    final today = dayKey(DateTime.now());
    final items = await (_db.select(_db.localRecurring)
          ..where((r) => r.active.equals(true)))
        .get();

    var emitted = 0;
    for (final item in items) {
      final result = collectDue(
        nextDueDate: item.nextDueDate,
        frequency: item.frequency,
        today: today,
      );
      if (result.due.isEmpty) continue;

      for (final occurrence in result.due) {
        final date = DateTime.parse(occurrence.dateKey);
        if (item.type == TransactionType.saving.key) {
          await _transactions.addSaving(
            amount: item.amount,
            category: item.category,
            transactionDate: date,
            source: TransactionSource.recurring,
          );
        } else {
          await _transactions.addExpense(
            amount: item.amount,
            category: item.category,
            merchant: item.merchant,
            transactionDate: date,
            source: TransactionSource.recurring,
          );
        }
        emitted++;
      }
      await (_db.update(_db.localRecurring)..where((r) => r.id.equals(item.id)))
          .write(LocalRecurringCompanion(nextDueDate: Value(result.nextDue)));
    }
    return emitted;
  }
}
