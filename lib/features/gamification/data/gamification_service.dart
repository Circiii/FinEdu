import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../domain/engine/quest_engine.dart';
import '../../../domain/engine/streak_rules.dart';
import '../../../domain/models/transaction.dart';
import '../../tracking/data/transactions_repository.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Streak-ul live: se reevaluează (idempotent) la fiecare schimbare de activitate.
/// Recompensele de milestone se aplică o singură dată (`claimedMilestones` persistat).
final streakViewProvider = StreamProvider<StreakResult>((ref) {
  final service = ref.watch(gamificationServiceProvider);
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchActivityDays().asyncMap((_) => service.evaluateNow());
});

/// Misiunile de azi cu starea de completare + claim, live.
final questsViewProvider = StreamProvider<QuestsView>((ref) {
  final service = ref.watch(gamificationServiceProvider);
  final db = ref.watch(appDbProvider);
  // Se re-derivă la orice schimbare a rândului de activitate sau a claim-urilor.
  final activity = db.select(db.dailyActivityRows).watch();
  return activity.asyncMap((_) => service.questsToday());
});

class QuestView {
  const QuestView(this.def, {required this.done, required this.claimed});
  final QuestDef def;
  final bool done;
  final bool claimed;
}

class ChestView {
  const ChestView(
      {required this.progress, required this.openable, required this.earnedToday});
  final int progress; // misiuni revendicate azi (0..3)
  final bool openable; // câștigat într-o zi anterioară, încă nedeschis
  final bool earnedToday;
}

class QuestsView {
  const QuestsView(this.quests, this.chest);
  final List<QuestView> quests;
  final ChestView chest;
}

class GamificationService {
  GamificationService(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  // --- Streak ---------------------------------------------------------------

  Future<StreakSnapshot> _loadSnapshot() async {
    final row = await (_db.select(_db.streakStates)
          ..where((s) => s.id.equals(0)))
        .getSingleOrNull();
    if (row == null) return const StreakSnapshot();
    return StreakSnapshot(
      freezes: row.freezes,
      frozenDays: _set(row.frozenDays),
      earnbackValue: row.earnbackValue,
      earnbackUntil: row.earnbackUntil,
      earnbackGap: _set(row.earnbackGap),
      claimedMilestones: _set(row.claimedMilestones).map(int.parse).toSet(),
      lastEvaluated: row.lastEvaluated,
    );
  }

  Future<void> _saveSnapshot(StreakSnapshot s) {
    return _db.into(_db.streakStates).insertOnConflictUpdate(
          StreakStatesCompanion(
            id: const Value(0),
            freezes: Value(s.freezes),
            frozenDays: Value(jsonEncode(s.frozenDays.toList())),
            earnbackValue: Value(s.earnbackValue),
            earnbackUntil: Value(s.earnbackUntil),
            earnbackGap: Value(jsonEncode(s.earnbackGap.toList())),
            claimedMilestones: Value(
                jsonEncode(s.claimedMilestones.map((m) => '$m').toList())),
            lastEvaluated: Value(s.lastEvaluated),
          ),
        );
  }

  Set<String> _set(String json) =>
      (jsonDecode(json) as List).cast<String>().toSet();

  /// Rulează evaluarea streak-ului (idempotentă) și aplică efectele: cuferele
  /// de milestone creditează ghinde o singură dată.
  Future<StreakResult> evaluateNow() async {
    final today = dayKey(DateTime.now());
    final snapshot = await _loadSnapshot();
    final days = await _activityDays();
    final kinds = await _todayKinds();

    final result = evaluateStreak(
      snapshot: snapshot,
      activityDays: days,
      todayKindCount: kinds.length,
      today: today,
    );
    await _saveSnapshot(result.snapshot);
    for (final e in result.events) {
      if (e is MilestoneReached) {
        await _profiles.addAcorns(e.acorns, reason: 'milestone_${e.days}');
      }
    }
    return result;
  }

  /// Cumpără o Ghindă de Gheață (max 2 deținute) pentru [price] ghinde.
  Future<bool> buyFreeze({int price = 200}) async {
    final snapshot = await _loadSnapshot();
    if (snapshot.freezes >= StreakSnapshot.maxFreezes) return false;
    final profile = await _profiles.get();
    if (profile.acorns < price) return false;
    await _profiles.addAcorns(-price, reason: 'buy_freeze');
    await _saveSnapshot(snapshot.copyWith(freezes: snapshot.freezes + 1));
    return true;
  }

  // --- Quests + chest --------------------------------------------------------

  Future<QuestsView> questsToday() async {
    final today = dayKey(DateTime.now());
    final defs = questsFor(today);
    final kinds = await _todayKinds();
    final claims = await _claims(today);
    final categories = await _todayExpenseCategories();
    final streak = (await evaluateNow()).current;

    final quests = [
      for (final def in defs)
        QuestView(
          def,
          done: questDone(def.id,
              todayKinds: kinds,
              todayExpenseCategories: categories,
              streakCurrent: streak),
          claimed: claims.contains(def.slot),
        ),
    ];

    // Cufărul se câștigă în momentul în care toate 3 sunt revendicate; deschidere din ziua următoare.
    final chestRow = await (_db.select(_db.chestStates)
          ..where((c) => c.id.equals(0)))
        .getSingleOrNull();
    var earnedDate = chestRow?.earnedDate;
    if (claims.length == 3 && earnedDate != today) {
      // Cufăr nou pentru azi (nu retrogradează unul mai vechi nedeschis,
      // deschiderea se face pe date).
      if (earnedDate == null || chestRow?.openedDate == earnedDate) {
        earnedDate = today;
        await _db.into(_db.chestStates).insertOnConflictUpdate(
              ChestStatesCompanion(
                  id: const Value(0), earnedDate: Value(today)),
            );
      }
    }
    final openable = earnedDate != null &&
        earnedDate != today &&
        chestRow?.openedDate != earnedDate;

    return QuestsView(
      quests,
      ChestView(
        progress: claims.length,
        openable: openable,
        earnedToday: earnedDate == today,
      ),
    );
  }

  /// Revendică o misiune completată (idempotent) și creditează recompensa.
  Future<bool> claimQuest(QuestDef def) async {
    final today = dayKey(DateTime.now());
    final claims = await _claims(today);
    if (claims.contains(def.slot)) return false;
    await _db.into(_db.questClaims).insert(
          QuestClaimsCompanion.insert(
            date: today,
            slot: def.slot,
            claimedAt: DateTime.now(),
          ),
        );
    await _profiles.addAcorns(def.reward, reason: 'quest_${def.id.name}');
    return true;
  }

  /// Deschide cufărul câștigat ieri (sau mai vechi). Întoarce ghindele
  /// câștigate, sau null dacă nu e nimic de deschis.
  Future<int?> openChest() async {
    final today = dayKey(DateTime.now());
    final row = await (_db.select(_db.chestStates)
          ..where((c) => c.id.equals(0)))
        .getSingleOrNull();
    final earned = row?.earnedDate;
    if (earned == null || earned == today || row?.openedDate == earned) {
      return null;
    }
    final streak = (await evaluateNow()).current;
    final value = chestValue(earned, streak);
    await _profiles.addAcorns(value, reason: 'chest_$earned');
    await _db.into(_db.chestStates).insertOnConflictUpdate(
          ChestStatesCompanion(id: const Value(0), openedDate: Value(earned)),
        );
    return value;
  }

  // Rundele de joc (dojo/daily/turbo) sunt înregistrate prin
  // ArcadeRepository.recordRound, el deține marcarea activității 'game' și
  // economia primei runde a zilei.

  // --- Internals -------------------------------------------------------------

  Future<Set<String>> _activityDays() async {
    final rows = await _db.select(_db.dailyActivityRows).get();
    return rows.map((r) => r.date).toSet();
  }

  Future<Set<String>> _todayKinds() async {
    final today = dayKey(DateTime.now());
    final row = await (_db.select(_db.dailyActivityRows)
          ..where((r) => r.date.equals(today)))
        .getSingleOrNull();
    if (row == null) return const {};
    return (jsonDecode(row.kinds) as List).cast<String>().toSet();
  }

  Future<Set<int>> _claims(String date) async {
    final rows = await (_db.select(_db.questClaims)
          ..where((q) => q.date.equals(date)))
        .get();
    return rows.map((r) => r.slot).toSet();
  }

  Future<Set<String>> _todayExpenseCategories() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final rows = await (_db.select(_db.localTransactions)
          ..where((t) =>
              t.deleted.equals(false) &
              t.type.equals(TransactionType.expense.key) &
              t.transactionDate.isBiggerOrEqualValue(start)))
        .get();
    return rows.map((r) => r.category).toSet();
  }
}
