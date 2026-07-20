import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../domain/models/transaction.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(appDbProvider));
});

/// Obiective + progres live. Progresul e derivat (suma tranzacțiilor de
/// economisire neșterse legate de obiectiv); drift urmărește ambele tabele.
final goalsWithProgressProvider = StreamProvider<List<GoalProgress>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchWithProgress();
});

class GoalProgress {
  const GoalProgress(this.goal, this.saved);
  final LocalGoal goal;
  final double saved;

  double get pct =>
      goal.targetAmount <= 0 ? 0 : (saved / goal.targetAmount).clamp(0.0, 1.0);
  bool get reached => saved >= goal.targetAmount;
}

const _uuid = Uuid();

class GoalsRepository {
  GoalsRepository(this._db);

  final AppDb _db;

  Future<String> create({
    required String name,
    required double targetAmount,
    String emoji = '🎯',
    String? deadline,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.localGoals)
        .insert(
          LocalGoalsCompanion.insert(
            id: id,
            name: name,
            targetAmount: targetAmount,
            emoji: Value(emoji),
            deadline: Value(deadline),
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.localGoals)..where((g) => g.id.equals(id))).go();
  }

  Stream<List<GoalProgress>> watchWithProgress() {
    final saved = _db.localTransactions.amount.sum(
      filter:
          _db.localTransactions.deleted.equals(false) &
          _db.localTransactions.type.equals(TransactionType.saving.key),
    );
    final query =
        _db.select(_db.localGoals).join([
            leftOuterJoin(
              _db.localTransactions,
              _db.localTransactions.goalId.equalsExp(_db.localGoals.id),
            ),
          ])
          ..addColumns([saved])
          ..groupBy([_db.localGoals.id])
          ..orderBy([OrderingTerm.asc(_db.localGoals.createdAt)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          GoalProgress(row.readTable(_db.localGoals), row.read(saved) ?? 0),
      ],
    );
  }
}
