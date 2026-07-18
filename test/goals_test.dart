import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/features/goals/data/goals_repository.dart';
import 'package:finedu_flutter/features/tracking/data/transactions_repository.dart';

void main() {
  late AppDb db;
  late GoalsRepository goals;
  late TransactionsRepository tx;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    goals = GoalsRepository(db);
    tx = TransactionsRepository(db);
  });

  tearDown(() => db.close());

  test('goal progress is derived from linked saving transactions', () async {
    final id = await goals.create(name: 'Căști', targetAmount: 300);

    var list = await goals.watchWithProgress().first;
    expect(list.single.saved, 0);

    await tx.addSaving(amount: 50, category: 'obiectiv', goalId: id);
    await tx.addSaving(amount: 25, category: 'obiectiv', goalId: id);
    // A saving WITHOUT a goal must not count toward it.
    await tx.addSaving(amount: 100, category: 'fond_urgenta');

    list = await goals.watchWithProgress().first;
    expect(list.single.saved, 75);
    expect(list.single.pct, closeTo(0.25, 0.001));
    expect(list.single.reached, isFalse);
  });

  test('deleting a saving contribution updates the derived progress', () async {
    final id = await goals.create(name: 'Vacanță', targetAmount: 100);
    final contribution =
        await tx.addSaving(amount: 100, category: 'obiectiv', goalId: id);

    var list = await goals.watchWithProgress().first;
    expect(list.single.reached, isTrue);

    await tx.softDelete(contribution.id);
    list = await goals.watchWithProgress().first;
    expect(list.single.saved, 0);
  });

  test('deleting a goal removes it; contributions stay as savings', () async {
    final id = await goals.create(name: 'X', targetAmount: 100);
    await tx.addSaving(amount: 40, category: 'obiectiv', goalId: id);
    await goals.delete(id);

    final list = await goals.watchWithProgress().first;
    expect(list, isEmpty);
    // The saving transaction itself survives (it is real money set aside).
    final recent = await tx.watchRecent(5).first;
    expect(recent.single.amount, 40);
  });
}
