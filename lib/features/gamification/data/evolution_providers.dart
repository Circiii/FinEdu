import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/engine/cashy_evolution.dart';
import '../../arcade/data/arcade_repository.dart';
import '../../arcade/data/dojo_repository.dart';
import '../../home/data/home_providers.dart';
import '../../learning/data/lessons_repository.dart';
import '../../wardrobe/data/wardrobe_repository.dart';
import 'gamification_service.dart';

/// Punctele de grijă de azi: compune stream-urile existente cu fallback (0/empty)
/// cât timp încarcă. Nu adaugă tabele noi, derivă din date deja colectate.
final carePointsProvider = Provider<int>((ref) {
  final activeDays = ref.watch(activityDaysProvider).valueOrNull?.length ?? 0;
  final lessonsDone =
      ref.watch(completedLessonsProvider).valueOrNull?.length ?? 0;
  final longestStreak = ref.watch(streakViewProvider).valueOrNull?.longest ?? 0;
  final dojoRounds = ref.watch(dojoStateProvider).valueOrNull?.rounds ?? 0;
  final dailySolved = ref.watch(dailySolvedCountProvider).valueOrNull ?? 0;
  final wardrobeOwned = ref.watch(ownedItemsProvider).valueOrNull?.length ?? 0;

  return carePoints(
    activeDays: activeDays,
    lessonsDone: lessonsDone,
    longestStreak: longestStreak,
    dojoRounds: dojoRounds,
    dailySolved: dailySolved,
    wardrobeOwned: wardrobeOwned,
  );
});
