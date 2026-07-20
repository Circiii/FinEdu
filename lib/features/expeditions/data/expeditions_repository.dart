import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/expedition_rules.dart';
import '../../../domain/util/day_key.dart';

/// Al doilea faucet de ghinde din zi. Recompensa e fixată determinist la plecare
/// (streak + zi), nu se recalculează la colectare. Fără notificări/cronometru (AADC).

final expeditionsRepositoryProvider = Provider<ExpeditionsRepository>((ref) {
  return ExpeditionsRepository(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Rândul expediției de AZI (sau null dacă Cashy n-a plecat încă).
final expeditionTodayProvider = StreamProvider<ExpeditionRow?>((ref) {
  return ref.watch(expeditionsRepositoryProvider).watchToday();
});

/// Rulează o dată per sesiune: creditează expedițiile vechi necolectate.
/// Orice eroare e no-op silențios, ca să nu dărâme Home.
final expeditionAutoCollectProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(expeditionsRepositoryProvider).autoCollectStale();
  } catch (e) {
    debugPrint('expedition auto-collect skipped: $e');
  }
});

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;

/// Replicile de pe vederile lui Cashy (bilingv, din content/expeditions.json).
final postcardsProvider = FutureProvider.family<List<String>, String>((
  ref,
  locale,
) async {
  final json =
      jsonDecode(await loadAssetString('content/expeditions.json'))
          as Map<String, dynamic>;
  return [
    for (final p in (json['postcards'] as List).cast<Map<String, dynamic>>())
      _t(p['text'] as Map<String, dynamic>, locale),
  ];
});

class ExpeditionsRepository {
  ExpeditionsRepository(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  static const _duration = Duration(hours: expeditionHours);

  Stream<ExpeditionRow?> watchToday() {
    final today = dayKey(DateTime.now());
    return (_db.select(
      _db.expeditionRows,
    )..where((e) => e.day.equals(today))).watchSingleOrNull();
  }

  /// Trimite-l pe Cashy azi (idempotent, insertOrIgnore pe cheia zilei); recompensa
  /// e fixată acum, nu la colectare.
  Future<void> depart({required int streak}) async {
    final today = dayKey(DateTime.now());
    await _db
        .into(_db.expeditionRows)
        .insert(
          ExpeditionRowsCompanion.insert(
            day: today,
            departedAt: DateTime.now(),
            reward: expeditionReward(streak: streak, dayKey: today),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Culege expediția de azi dacă s-a întors (≥6h) și nu a fost deja culeasă.
  /// `collectedAt` e lock optimist: un dublu-tap nu creditează de două ori.
  Future<int> collect() async {
    final today = dayKey(DateTime.now());
    final row = await (_db.select(
      _db.expeditionRows,
    )..where((e) => e.day.equals(today))).getSingleOrNull();
    if (row == null || row.collectedAt != null) return 0;
    if (DateTime.now().difference(row.departedAt) < _duration) return 0;

    final updated =
        await (_db.update(_db.expeditionRows)
              ..where((e) => e.day.equals(today) & e.collectedAt.isNull()))
            .write(ExpeditionRowsCompanion(collectedAt: Value(DateTime.now())));
    if (updated == 0) return 0; // altcineva a cules între timp
    await _profiles.addAcorns(row.reward, reason: 'expedition_$today');
    return row.reward;
  }

  /// Creditează expedițiile vechi necolectate cu ≥6h scurse, o dată fiecare (lock optimist).
  Future<int> autoCollectStale() async {
    final today = dayKey(DateTime.now());
    final now = DateTime.now();
    final rows = await (_db.select(
      _db.expeditionRows,
    )..where((e) => e.collectedAt.isNull() & e.day.isNotValue(today))).get();
    var total = 0;
    for (final row in rows) {
      if (now.difference(row.departedAt) < _duration) continue;
      final updated =
          await (_db.update(_db.expeditionRows)
                ..where((e) => e.day.equals(row.day) & e.collectedAt.isNull()))
              .write(ExpeditionRowsCompanion(collectedAt: Value(now)));
      if (updated == 0) continue;
      await _profiles.addAcorns(row.reward, reason: 'expedition_${row.day}');
      total += row.reward;
    }
    return total;
  }
}
