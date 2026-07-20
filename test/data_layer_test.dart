// Teste pentru stratul de date local: scrieri, outbox, activitatea zilei,
// motorul de sincronizare și maparea modelelor.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/sync/sync_engine.dart';
import 'package:finedu_flutter/domain/models/transaction.dart';
import 'package:finedu_flutter/features/tracking/data/transaction_mapper.dart';
import 'package:finedu_flutter/features/tracking/data/transactions_repository.dart';

void main() {
  late AppDb db;
  late TransactionsRepository repo;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    repo = TransactionsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'addExpense writes the row, an outbox entry and daily activity "log"',
    () async {
      final tx = await repo.addExpense(
        amount: 12.5,
        category: 'mancare',
        merchant: 'Mega Image',
      );

      // Rândul există, cu valorile așteptate.
      final rows = await db.select(db.localTransactions).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, tx.id);
      expect(row.amount, 12.5);
      expect(row.category, 'mancare');
      expect(row.type, 'expense');
      expect(row.merchant, 'Mega Image');
      expect(row.deleted, isFalse);
      expect(row.pendingSync, isTrue);

      // În outbox a intrat operația de trimis mai târziu.
      final outbox = await db.select(db.outboxEntries).get();
      expect(outbox, hasLength(1));
      expect(outbox.single.opType, 'upsert_transaction');
      final payload = jsonDecode(outbox.single.payload) as Map<String, dynamic>;
      expect(payload['client_id'], tx.id);
      expect(payload['amount'], 12.5);

      // Activitatea zilei conține 'log'.
      final activity = await db.select(db.dailyActivityRows).get();
      expect(activity, hasLength(1));
      expect(activity.single.date, dayKey(tx.transactionDate));
      final kinds = (jsonDecode(activity.single.kinds) as List).cast<String>();
      expect(kinds, contains('log'));
    },
  );

  test('softDelete marks the row deleted and enqueues a delete op', () async {
    final tx = await repo.addExpense(amount: 30, category: 'transport');

    await repo.softDelete(tx.id);

    final row = (await db.select(db.localTransactions).get()).single;
    expect(row.deleted, isTrue);
    expect(row.pendingSync, isTrue);

    final outbox = await db.select(db.outboxEntries).get();
    // addExpense pune o operație, ștergerea o adaugă pe a doua.
    expect(outbox, hasLength(2));
    final deleteOp = outbox.last;
    expect(deleteOp.opType, 'delete_transaction');
    expect(jsonDecode(deleteOp.payload), {'id': tx.id});
  });

  test(
    'markNoSpendToday is idempotent (a single row after two calls)',
    () async {
      await repo.markNoSpendToday();
      await repo.markNoSpendToday();

      final days = await db.select(db.noSpendDays).get();
      expect(days, hasLength(1));
      expect(days.single.date, dayKey(DateTime.now()));

      // Doar primul apel pune operația și marchează ziua.
      final outbox = await db.select(db.outboxEntries).get();
      expect(outbox, hasLength(1));
      expect(outbox.single.opType, 'mark_no_spend');

      final activity = await db.select(db.dailyActivityRows).get();
      expect(activity, hasLength(1));
      final kinds = (jsonDecode(activity.single.kinds) as List).cast<String>();
      expect(kinds, contains('log'));
    },
  );

  test('SyncEngine with hasBackend=false: syncNow() is a safe no-op', () async {
    await repo.addExpense(amount: 5, category: 'altele');
    final before = await db.select(db.outboxEntries).get();
    expect(before, hasLength(1));

    final engine = SyncEngine(db: db, hasBackend: false);

    // Nu are voie să crape...
    await engine.syncNow();

    // ...și nu are voie să atingă outbox-ul.
    final after = await db.select(db.outboxEntries).get();
    expect(after, hasLength(1));
    expect(after.single.attempts, 0);
    expect(after.single.lastError, isNull);

    // Rândul rămâne în așteptare.
    final row = (await db.select(db.localTransactions).get()).single;
    expect(row.pendingSync, isTrue);

    engine.dispose();
  });

  test('domain <-> drift mapper round-trips every field', () async {
    final original = Transaction(
      id: 'a2e1c8a0-0000-4000-8000-1234567890ab',
      amount: 149.99,
      category: 'fond_urgenta',
      type: TransactionType.saving,
      merchant: null,
      note: 'primul depozit',
      transactionDate: DateTime(2026, 7, 6, 18, 30),
      source: TransactionSource.voice,
      createdAt: DateTime(2026, 7, 6, 18, 31),
      updatedAt: DateTime(2026, 7, 6, 18, 32),
      deleted: false,
      pendingSync: true,
    );

    // Model -> rând -> model dă exact ce a intrat.
    expect(original.toRow().toDomain(), original);

    // Și rezistă la un ciclu real de scriere și citire.
    await db.into(db.localTransactions).insert(original.toRow());
    final fromDb = (await db.select(db.localTransactions).get()).single
        .toDomain();
    expect(fromDb, original);
  });
}
