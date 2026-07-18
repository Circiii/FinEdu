import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/daily_challenge.dart';
import '../../../domain/util/day_key.dart';

// ---------------------------------------------------------------------------
// Modele de conținut (parsate din content/arcade/*.json)
// ---------------------------------------------------------------------------

class PriceItem {
  const PriceItem(this.name,
      {required this.actual,
      required this.min,
      required this.max,
      required this.step});
  final String name;
  final int actual;
  final int min;
  final int max;
  final int step;
}

class PricePuzzle {
  const PricePuzzle(this.id, this.title, this.items);
  final String id;
  final String title;
  final List<PriceItem> items;
}

class MythStatement {
  const MythStatement(this.text, {required this.truth, required this.explain});
  final String text;
  final bool truth;
  final String explain;
}

class MythPuzzle {
  const MythPuzzle(this.id, this.statements);
  final String id;
  final List<MythStatement> statements;
}

class DilemmaOption {
  const DilemmaOption(this.text, this.comment);
  final String text;
  final String comment;
}

class DilemmaPuzzle {
  const DilemmaPuzzle(this.id, this.scenario, this.options);
  final String id;
  final String scenario;
  final List<DilemmaOption> options;
}

class DailyContent {
  const DailyContent(
      {required this.price, required this.myth, required this.dilemma});
  final List<PricePuzzle> price;
  final List<MythPuzzle> myth;
  final List<DilemmaPuzzle> dilemma;
}

class TurboItem {
  const TurboItem(this.id, this.label,
      {required this.price, required this.bucket, this.note});
  final String id;
  final String label;
  final int price;
  final String bucket; // 'need' | 'want' | 'save'
  final String? note;
}

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;

final dailyContentProvider =
    FutureProvider.family<DailyContent, String>((ref, locale) async {
  final json = jsonDecode(await loadAssetString('content/arcade/daily.json'))
      as Map<String, dynamic>;
  return DailyContent(
    price: [
      for (final p in (json['price'] as List).cast<Map<String, dynamic>>())
        PricePuzzle(
          p['id'] as String,
          _t(p['title'] as Map<String, dynamic>, locale),
          [
            for (final i in (p['items'] as List).cast<Map<String, dynamic>>())
              PriceItem(
                _t(i['name'] as Map<String, dynamic>, locale),
                actual: i['actual'] as int,
                min: i['min'] as int,
                max: i['max'] as int,
                step: i['step'] as int,
              ),
          ],
        ),
    ],
    myth: [
      for (final m in (json['myth'] as List).cast<Map<String, dynamic>>())
        MythPuzzle(
          m['id'] as String,
          [
            for (final s
                in (m['statements'] as List).cast<Map<String, dynamic>>())
              MythStatement(
                _t(s['text'] as Map<String, dynamic>, locale),
                truth: s['truth'] as bool,
                explain: _t(s['explain'] as Map<String, dynamic>, locale),
              ),
          ],
        ),
    ],
    dilemma: [
      for (final d in (json['dilemma'] as List).cast<Map<String, dynamic>>())
        DilemmaPuzzle(
          d['id'] as String,
          _t(d['scenario'] as Map<String, dynamic>, locale),
          [
            for (final o
                in (d['options'] as List).cast<Map<String, dynamic>>())
              DilemmaOption(
                _t(o['text'] as Map<String, dynamic>, locale),
                _t(o['comment'] as Map<String, dynamic>, locale),
              ),
          ],
        ),
    ],
  );
});

final turboItemsProvider =
    FutureProvider.family<List<TurboItem>, String>((ref, locale) async {
  final json =
      jsonDecode(await loadAssetString('content/arcade/turbo_items.json'))
          as Map<String, dynamic>;
  return [
    for (final i in (json['items'] as List).cast<Map<String, dynamic>>())
      TurboItem(
        i['id'] as String,
        _t(i['label'] as Map<String, dynamic>, locale),
        price: i['price'] as int,
        bucket: i['bucket'] as String,
        note: i['note'] == null
            ? null
            : _t(i['note'] as Map<String, dynamic>, locale),
      ),
  ];
});

// ---------------------------------------------------------------------------
// Runde + recompense
// ---------------------------------------------------------------------------

final arcadeRepositoryProvider = Provider<ArcadeRepository>((ref) {
  return ArcadeRepository(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Runda de azi la Provocarea Zilei, sau null.
final dailyRoundTodayProvider = StreamProvider<ArcadeRound?>((ref) {
  return ref.watch(arcadeRepositoryProvider).watchTodayRound('daily');
});

/// Cel mai bun scor la Turbo Buget (null înainte de prima rundă).
final turboBestProvider = StreamProvider<int?>((ref) {
  return ref.watch(arcadeRepositoryProvider).watchBestScore('turbo');
});

/// Câte runde de Provocarea Zilei au fost jucate (stats Profil).
final dailySolvedCountProvider = StreamProvider<int>((ref) {
  return ref.watch(arcadeRepositoryProvider).watchRoundsCount('daily');
});

/// Cât valorează prima rundă a zilei, per joc. Ziua bonus din hub dublează
/// alunele.
class ArcadeReward {
  const ArcadeReward({required this.acorns, required this.xp});
  final int acorns;
  final int xp;
}

const _baseRewards = {
  'dojo': ArcadeReward(acorns: 2, xp: 0),
  'daily': ArcadeReward(acorns: 8, xp: 10),
  'turbo': ArcadeReward(acorns: 5, xp: 10),
};

class ArcadeRepository {
  ArcadeRepository(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  Stream<ArcadeRound?> watchTodayRound(String game) {
    final today = dayKey(DateTime.now());
    return (_db.select(_db.arcadeRounds)
          ..where((r) => r.game.equals(game) & r.date.equals(today))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Total runde jucate pentru un joc (stats Profil).
  Stream<int> watchRoundsCount(String game) {
    final count = _db.arcadeRounds.id.count();
    final query = (_db.selectOnly(_db.arcadeRounds)
      ..addColumns([count])
      ..where(_db.arcadeRounds.game.equals(game)));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Stream<int?> watchBestScore(String game) {
    final max = _db.arcadeRounds.score.max();
    final query = (_db.selectOnly(_db.arcadeRounds)
      ..addColumns([max])
      ..where(_db.arcadeRounds.game.equals(game)));
    return query.watchSingle().map((row) => row.read(max));
  }

  /// Înregistrează o rundă jucată. Prima rundă a zilei per joc dă recompensa
  /// (alune duble în ziua bonus) și marchează activitatea 'game'; întoarce 0
  /// după. Provocarea Zilei rămâne o dată pe zi, a doua înregistrare e ignorată.
  Future<int> recordRound(
      {required String game,
      required int score,
      Map<String, Object?> meta = const {}}) async {
    final today = dayKey(DateTime.now());
    final existing = await (_db.select(_db.arcadeRounds)
          ..where((r) => r.game.equals(game) & r.date.equals(today))
          ..limit(1))
        .getSingleOrNull();
    if (game == 'daily' && existing != null) return 0;

    await _db.into(_db.arcadeRounds).insert(ArcadeRoundsCompanion.insert(
          game: game,
          date: today,
          score: score,
          meta: Value(jsonEncode(meta)),
        ));
    await _markGameActivity(today);
    if (existing != null) return 0;

    final base = _baseRewards[game] ?? const ArcadeReward(acorns: 2, xp: 0);
    final acorns =
        dailyBonusGame(today) == game ? base.acorns * 2 : base.acorns;
    await _profiles.addAcorns(acorns, reason: 'arcade_${game}_first');
    if (base.xp > 0) {
      final profile = await _profiles.get();
      await _profiles
          .update(LocalProfilesCompanion(xp: Value(profile.xp + base.xp)));
    }
    return acorns;
  }

  Future<void> _markGameActivity(String date) async {
    final row = await (_db.select(_db.dailyActivityRows)
          ..where((r) => r.date.equals(date)))
        .getSingleOrNull();
    final kinds = <String>{
      if (row != null) ...(jsonDecode(row.kinds) as List).cast<String>(),
      'game',
    }.toList();
    await _db.into(_db.dailyActivityRows).insertOnConflictUpdate(
          DailyActivityRowsCompanion.insert(
            date: date,
            kinds: jsonEncode(kinds),
          ),
        );
  }
}
