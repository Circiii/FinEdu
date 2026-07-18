import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/engine/score_engine.dart';
import '../../../domain/models/transaction.dart';
import '../../home/data/home_providers.dart';
import '../../learning/data/lessons_repository.dart';
import 'gamification_service.dart';

/// Scorul FinEdu live, asamblat din stream-urile existente, sursa unică
/// citită de Home (gauge) și Profil (factori).
final scoreProvider = Provider<AsyncValue<ScoreBreakdown>>((ref) {
  final profile = ref.watch(localProfileStreamProvider);
  final month = ref.watch(monthTransactionsProvider);
  final streak = ref.watch(streakViewProvider);
  final done = ref.watch(completedLessonsProvider);
  // Numărul de lecții nu depinde de limbă; 'ro' e doar cheia de cache.
  final units = ref.watch(unitsProvider('ro'));

  if (profile.isLoading ||
      month.isLoading ||
      streak.isLoading ||
      done.isLoading ||
      units.isLoading) {
    return const AsyncValue.loading();
  }

  final tx = month.valueOrNull ?? const [];
  final expenses =
      tx.where((t) => t.type == TransactionType.expense).toList();
  final savings = tx.where((t) => t.type == TransactionType.saving);
  final allLessons = (units.valueOrNull ?? const [])
      .fold<int>(0, (n, u) => n + u.lessons.length);

  return AsyncValue.data(computeScore(ScoreInputs(
    budget: (profile.valueOrNull?.monthlyBudget ?? 0).toDouble(),
    spentThisMonth: expenses.fold(0.0, (a, t) => a + t.amount),
    savedThisMonth: savings.fold(0.0, (a, t) => a + t.amount),
    streak: streak.valueOrNull?.current ?? 0,
    txThisMonth: tx.length,
    categoriesThisMonth: expenses.map((t) => t.category).toSet().length,
    lessonsDone: done.valueOrNull?.length ?? 0,
    lessonsTotal: allLessons,
  )));
});
