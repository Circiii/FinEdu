import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/domain/engine/recurring_materializer.dart';
import 'package:finedu_flutter/features/recurring/data/recurring_repository.dart';
import 'package:finedu_flutter/features/tracking/data/transactions_repository.dart';

void main() {
  group('advanceDueDate', () {
    test('daily / weekly', () {
      expect(advanceDueDate('2026-07-07', 'daily'), '2026-07-08');
      expect(advanceDueDate('2026-07-07', 'weekly'), '2026-07-14');
    });

    test('monthly clamps to the last day of a short month', () {
      expect(advanceDueDate('2026-01-31', 'monthly'), '2026-02-28');
      expect(advanceDueDate('2028-01-31', 'monthly'), '2028-02-29'); // leap
      expect(advanceDueDate('2026-01-15', 'monthly'), '2026-02-15');
    });

    test('monthly rolls over the year', () {
      expect(advanceDueDate('2026-12-10', 'monthly'), '2027-01-10');
    });
  });

  group('collectDue', () {
    test('nothing due when next date is in the future', () {
      final r = collectDue(
          nextDueDate: '2026-08-01', frequency: 'monthly', today: '2026-07-07');
      expect(r.due, isEmpty);
      expect(r.nextDue, '2026-08-01');
    });

    test('recovers multiple missed monthly occurrences', () {
      final r = collectDue(
          nextDueDate: '2026-05-01', frequency: 'monthly', today: '2026-07-07');
      expect(r.due.map((d) => d.dateKey), ['2026-05-01', '2026-06-01', '2026-07-01']);
      expect(r.nextDue, '2026-08-01');
    });
  });

  group('materializeDue (integration)', () {
    late AppDb db;
    late RecurringRepository recurring;
    late TransactionsRepository tx;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      tx = TransactionsRepository(db);
      recurring = RecurringRepository(db, tx);
    });
    tearDown(() => db.close());

    test('emits one transaction per due occurrence and advances the date',
        () async {
      // A monthly subscription first due yesterday.
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final key =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await recurring.add(
        merchant: 'Netflix',
        amount: 55,
        category: 'distractie',
        type: 'expense',
        frequency: 'monthly',
        nextDueDate: key,
      );

      final emitted = await recurring.materializeDue();
      expect(emitted, 1);

      final recent = await tx.watchRecent(5).first;
      expect(recent.single.merchant, 'Netflix');
      expect(recent.single.amount, 55);

      // Running again is a no-op (date advanced past today).
      expect(await recurring.materializeDue(), 0);
    });
  });
}
