import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_db.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_profile_repository.dart';
import '../../../../core/utils/bundle.dart';
import '../../../../domain/engine/life_sim/life_sim_content.dart';
import '../../../../domain/engine/life_sim/life_sim_engine.dart' as engine;
import '../../../../domain/engine/life_sim/life_sim_scoring.dart';
import '../../../../domain/engine/life_sim/life_sim_state.dart';
import '../../../../domain/util/day_key.dart';

const _uuid = Uuid();

/// Toate asset-urile pachetului „30 de Zile". Ordinea nu contează
/// ([LifeSimContent.fromJsonBundle] recunoaște fișierele după cale).
const lifeSimAssetPaths = <String>[
  'content/life_sim/manifest.json',
  'content/life_sim/roles.json',
  'content/life_sim/cities.json',
  'content/life_sim/recurring.json',
  'content/life_sim/goals.json',
  'content/life_sim/endings.json',
  'content/life_sim/events/costs_debt_saving.json',
  'content/life_sim/events/health_transport_housing.json',
  'content/life_sim/events/work_social.json',
  'content/life_sim/events/scams_tech_rare.json',
];

/// Încarcă pachetul de conținut al simulării. Dacă un asset lipsește la
/// runtime, îl sărim, pachetul parțial se încarcă în continuare.
final lifeSimContentProvider = FutureProvider<LifeSimContent>((ref) async {
  final bundle = <String, String>{};
  for (final path in lifeSimAssetPaths) {
    try {
      bundle[path] = await loadAssetString(path);
    } catch (_) {
      // Asset lipsă → îl ignorăm (pachet parțial în dezvoltare).
    }
  }
  return LifeSimContent.fromJsonBundle(bundle);
});

/// O rundă hidratată: id-ul din DB + starea decodată (+ scorul, dacă e
/// terminată).
class LifeMonthRun {
  const LifeMonthRun({
    required this.id,
    required this.state,
    required this.startedAt,
    this.completedAt,
    this.score,
  });

  final String id;
  final LifeSimState state;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Scorul final, doar pentru rundele terminate (din `resultJson`).
  final LifeSimScore? score;

  factory LifeMonthRun.fromRow(LifeSimRun row) => LifeMonthRun(
    id: row.id,
    state: LifeSimState.fromJson(
      jsonDecode(row.stateJson) as Map<String, dynamic>,
    ),
    startedAt: row.startedAt,
    completedAt: row.completedAt,
    score: row.resultJson == null
        ? null
        : scoreFromJson(jsonDecode(row.resultJson!) as Map<String, dynamic>),
  );
}

/// [LifeSimScore] nu are `fromJson` în motor (înghețat), îl reconstruim aici
/// din agregatul persistat. Constructorul e public, deci nu atingem motorul.
LifeSimScore scoreFromJson(Map<String, dynamic> j) => LifeSimScore(
  control: (j['control'] as num).toInt(),
  rezilienta: (j['rezilienta'] as num).toInt(),
  obiective: (j['obiective'] as num).toInt(),
  echilibru: (j['echilibru'] as num).toInt(),
  total: (j['total'] as num).toInt(),
  endingId: j['endingId'] as String,
);

/// Rezultatul recompensării unei terminări (pentru afișaj în raport).
class LifeMonthCompletion {
  const LifeMonthCompletion({
    required this.acornsAwarded,
    required this.xpAwarded,
    required this.improved,
    required this.previousBest,
  });

  final int acornsAwarded;
  final int xpAwarded;

  /// A depășit scorul unei runde anterioare cu același seed (bonus de replay).
  final bool improved;

  /// Cel mai bun total anterior pe același seed (null dacă e prima rundă).
  final int? previousBest;
}

final lifeMonthRepositoryProvider = Provider<LifeMonthRepository>((ref) {
  return LifeMonthRepository(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Runda activă (cu `completedAt` null), sau null. Reîncărcabilă cu
/// `ref.invalidate` după crearea/terminarea unui run. Trecem versiunea de
/// conținut curentă, ca o rundă rămasă pe o versiune veche să se abandoneze
/// singură și cardul din Arcade să-și revină.
final activeRunProvider = FutureProvider<LifeMonthRun?>((ref) async {
  final content = await ref.watch(lifeSimContentProvider.future);
  return ref
      .watch(lifeMonthRepositoryProvider)
      .activeRun(currentVersion: content.version);
});

/// Ultima rundă terminată (pentru „Reia aceeași lună" din intro + compararea
/// same-seed în raport).
final lastCompletedRunProvider = FutureProvider<LifeMonthRun?>((ref) {
  return ref.watch(lifeMonthRepositoryProvider).lastCompletedRun();
});

class LifeMonthRepository {
  LifeMonthRepository(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  // --- Ciclu de viață al unui run

  /// Creează un run nou. Seed-ul e derivat din ceas XOR un hash al alegerilor,
  /// ca două combinații pornite în aceeași milisecundă să difere. Pentru „Reia
  /// aceeași lună" se trece [seed] explicit → aceeași lună, alte decizii.
  Future<LifeMonthRun> createRun({
    required LifeSimContent content,
    required String roleId,
    required String goalId,
    required String mode,
    int? seed,
  }) async {
    final actualSeed =
        seed ??
        (DateTime.now().millisecondsSinceEpoch ^
            Object.hash(roleId, goalId, mode));
    final state = engine.createRun(
      c: content,
      roleId: roleId,
      goalId: goalId,
      mode: mode,
      seed: actualSeed,
    );
    final id = _uuid.v4();
    await _db
        .into(_db.lifeSimRuns)
        .insert(
          LifeSimRunsCompanion.insert(
            id: id,
            seed: actualSeed,
            roleId: roleId,
            goalId: goalId,
            mode: mode,
            contentVersion: content.version,
            day: Value(state.day),
            stateJson: jsonEncode(state.toJson()),
            startedAt: DateTime.now(),
          ),
        );
    return LifeMonthRun(id: id, state: state, startedAt: DateTime.now());
  }

  /// Salvează instantaneul (stateJson + ziua), apelat după fiecare avans/
  /// alegere, ca resume-ul să fie sigur.
  Future<void> saveSnapshot(String runId, LifeSimState state) async {
    await (_db.update(_db.lifeSimRuns)..where((r) => r.id.equals(runId))).write(
      LifeSimRunsCompanion(
        day: Value(state.day),
        stateJson: Value(jsonEncode(state.toJson())),
      ),
    );
  }

  /// O rundă după id (pentru ecranele care primesc id-ul prin rută).
  Future<LifeMonthRun?> getRun(String id) async {
    final row = await (_db.select(
      _db.lifeSimRuns,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : LifeMonthRun.fromRow(row);
  }

  /// Cea mai recentă rundă neterminată (resume din Arcade). Dacă
  /// [currentVersion] e dat, orice rundă pe alt contentVersion se abandonează
  /// (completedAt setat, fără resultJson) și e sărită: continuarea pe conținut
  /// schimbat ar rupe determinismul same-seed. Parametru opțional ca metoda să
  /// rămână testabilă fără conținut încărcat.
  Future<LifeMonthRun?> activeRun({String? currentVersion}) async {
    final rows =
        await (_db.select(_db.lifeSimRuns)
              ..where((r) => r.completedAt.isNull())
              ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
            .get();
    for (final row in rows) {
      final run = LifeMonthRun.fromRow(row);
      if (currentVersion != null &&
          run.state.contentVersion != currentVersion) {
        await (_db.update(_db.lifeSimRuns)..where((r) => r.id.equals(row.id)))
            .write(LifeSimRunsCompanion(completedAt: Value(DateTime.now())));
        continue;
      }
      return run;
    }
    return null;
  }

  /// Cea mai recentă rundă terminată. Rundele abandonate (fără resultJson) sunt
  /// excluse: nu au scor, nu contează ca „ultima lună jucată".
  Future<LifeMonthRun?> lastCompletedRun() async {
    final row =
        await (_db.select(_db.lifeSimRuns)
              ..where(
                (r) => r.completedAt.isNotNull() & r.resultJson.isNotNull(),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.completedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : LifeMonthRun.fromRow(row);
  }

  /// Înregistrează o decizie în ledger (o intrare per alegere de eveniment).
  Future<void> recordDecision({
    required String runId,
    required int day,
    required String eventId,
    required int choiceIdx,
  }) async {
    await _db
        .into(_db.lifeSimDecisions)
        .insert(
          LifeSimDecisionsCompanion.insert(
            runId: runId,
            day: day,
            eventId: eventId,
            choiceIdx: choiceIdx,
            createdAt: DateTime.now(),
          ),
        );
  }

  // --- Terminare + recompense

  /// Marchează runda terminată și creditează recompensele, plafonate la o
  /// terminare pe zi: prima +15🌰 'life_sim_complete' + 30 XP; dacă bate scorul
  /// unei runde anterioare cu același seed, încă +10🌰 'life_sim_improve'.
  /// Terminările ulterioare din aceeași zi se salvează dar nu plătesc.
  Future<LifeMonthCompletion> completeRun({
    required String runId,
    required LifeSimState state,
    required LifeSimScore score,
  }) async {
    // Toată secvența citire→verificare→scriere e o tranzacție, altfel două
    // apeluri concurente (dublu-tap) ar putea citi amândouă „nerecompensat".
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.lifeSimRuns,
      )..where((r) => r.id.equals(runId))).getSingleOrNull();

      // O rundă se recompensează o singură dată în viața ei, nu pe zi
      // calendaristică, dacă a fost deja terminată, nu mai atingem nimic.
      if (row?.completedAt != null) {
        return const LifeMonthCompletion(
          acornsAwarded: 0,
          xpAwarded: 0,
          improved: false,
          previousBest: null,
        );
      }

      // Cel mai bun total anterior pe același seed (rundele terminate, alt id).
      int? previousBest;
      if (row != null) {
        final priors =
            await (_db.select(_db.lifeSimRuns)..where(
                  (r) =>
                      r.seed.equals(row.seed) &
                      r.completedAt.isNotNull() &
                      r.id.equals(runId).not(),
                ))
                .get();
        for (final p in priors) {
          if (p.resultJson == null) continue;
          final total =
              (jsonDecode(p.resultJson!) as Map<String, dynamic>)['total'];
          if (total is num) {
            previousBest = previousBest == null
                ? total.toInt()
                : (total.toInt() > previousBest ? total.toInt() : previousBest);
          }
        }
      }

      await (_db.update(
        _db.lifeSimRuns,
      )..where((r) => r.id.equals(runId))).write(
        LifeSimRunsCompanion(
          day: Value(state.day),
          stateJson: Value(jsonEncode(state.toJson())),
          completedAt: Value(DateTime.now()),
          resultJson: Value(jsonEncode(score.toJson())),
        ),
      );

      final today = dayKey(DateTime.now());
      final alreadyRewardedToday = await _hasLedgerToday(
        'life_sim_complete',
        today,
      );

      var acorns = 0;
      var xp = 0;
      var improved = false;
      if (!alreadyRewardedToday) {
        await _profiles.addAcorns(15, reason: 'life_sim_complete');
        acorns += 15;
        if (previousBest != null && score.total > previousBest) {
          improved = true;
          await _profiles.addAcorns(10, reason: 'life_sim_improve');
          acorns += 10;
        }
        final profile = await _profiles.get();
        await _profiles.update(
          LocalProfilesCompanion(xp: Value(profile.xp + 30)),
        );
        xp = 30;
        await _markGameActivity(today);
      }

      return LifeMonthCompletion(
        acornsAwarded: acorns,
        xpAwarded: xp,
        improved: improved,
        previousBest: previousBest,
      );
    });
  }

  /// Recompensează răspunsul la reflecția din raport: +5🌰 'life_sim_reflect',
  /// plafonat la o dată pe zi. Întoarce ghindele creditate (0 dacă e plafonat).
  Future<int> rewardReflection() async {
    final today = dayKey(DateTime.now());
    if (await _hasLedgerToday('life_sim_reflect', today)) return 0;
    await _profiles.addAcorns(5, reason: 'life_sim_reflect');
    return 5;
  }

  /// Cea mai recentă rundă terminată cu un anumit seed, alta decât [exceptId]
  /// (pentru comparația side-by-side same-seed din raport).
  Future<LifeMonthRun?> previousCompletedForSeed(
    int seed, {
    required String exceptId,
  }) async {
    final row =
        await (_db.select(_db.lifeSimRuns)
              ..where(
                (r) =>
                    r.seed.equals(seed) &
                    r.completedAt.isNotNull() &
                    r.resultJson.isNotNull() &
                    r.id.equals(exceptId).not(),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.completedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : LifeMonthRun.fromRow(row);
  }

  // --- Ajutoare

  Future<bool> _hasLedgerToday(String reason, String today) async {
    final rows = await (_db.select(
      _db.acornEntries,
    )..where((e) => e.reason.equals(reason))).get();
    return rows.any((r) => dayKey(r.createdAt) == today);
  }

  Future<void> _markGameActivity(String date) async {
    final row = await (_db.select(
      _db.dailyActivityRows,
    )..where((r) => r.date.equals(date))).getSingleOrNull();
    final kinds = <String>{
      if (row != null) ...(jsonDecode(row.kinds) as List).cast<String>(),
      'game',
    }.toList();
    await _db
        .into(_db.dailyActivityRows)
        .insertOnConflictUpdate(
          DailyActivityRowsCompanion.insert(
            date: date,
            kinds: jsonEncode(kinds),
          ),
        );
  }
}
