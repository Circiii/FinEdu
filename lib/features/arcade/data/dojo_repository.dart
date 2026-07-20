import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/dojo_elo.dart';

// ---------------------------------------------------------------------------
// Conținut (content/arcade/dojo_messages.json)
// ---------------------------------------------------------------------------

class DojoMessage {
  const DojoMessage({
    required this.id,
    required this.from,
    required this.channel,
    required this.tag,
    required this.accent,
    required this.isScam,
    required this.difficulty,
    required this.text,
    required this.flags,
    required this.explain,
  });

  final String id;
  final String from;
  final String channel;
  final String tag;
  final String accent; // 'danger'|'amber'|'sky'|'violet'|'green'|'blue'
  final bool isScam;
  final int difficulty; // 1..3 (prior-ul Elo)
  final String text;
  final List<String> flags;
  final String explain;
}

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;

final dojoMessagesProvider = FutureProvider.family<List<DojoMessage>, String>((
  ref,
  locale,
) async {
  final json =
      jsonDecode(await loadAssetString('content/arcade/dojo_messages.json'))
          as Map<String, dynamic>;
  return [
    for (final m in (json['messages'] as List).cast<Map<String, dynamic>>())
      DojoMessage(
        id: m['id'] as String,
        from: _t(m['from'] as Map<String, dynamic>, locale),
        channel: _t(m['channel'] as Map<String, dynamic>, locale),
        tag: _t(m['tag'] as Map<String, dynamic>, locale),
        accent: m['accent'] as String,
        isScam: m['scam'] as bool,
        difficulty: m['difficulty'] as int,
        text: _t(m['text'] as Map<String, dynamic>, locale),
        flags: [
          for (final f in (m['flags'] as List).cast<Map<String, dynamic>>())
            _t(f, locale),
        ],
        explain: _t(m['explain'] as Map<String, dynamic>, locale),
      ),
  ];
});

// ---------------------------------------------------------------------------
// Rating-uri + selecția rundei
// ---------------------------------------------------------------------------

final dojoRepositoryProvider = Provider<DojoRepository>((ref) {
  return DojoRepository(ref.watch(appDbProvider));
});

/// Starea live a jucătorului la Dojo (centura afișată în Dojo + hub).
final dojoStateProvider = StreamProvider<DojoState>((ref) {
  return ref.watch(dojoRepositoryProvider).watchState();
});

class DojoState {
  const DojoState({required this.rating, required this.rounds});
  final int rating;
  final int rounds;

  int get beltIndex => dojoBeltIndex(rating);
  (String, String) get belt => dojoBelts[beltIndex];
}

class DojoRepository {
  DojoRepository(this._db);

  final AppDb _db;

  Stream<DojoState> watchState() {
    return (_db.select(
      _db.dojoStates,
    )..where((s) => s.id.equals(0))).watchSingleOrNull().map(
      (row) => DojoState(
        rating: row?.rating ?? dojoStartRating,
        rounds: row?.rounds ?? 0,
      ),
    );
  }

  Future<DojoState> state() async {
    final row = await (_db.select(
      _db.dojoStates,
    )..where((s) => s.id.equals(0))).getSingleOrNull();
    return DojoState(
      rating: row?.rating ?? dojoStartRating,
      rounds: row?.rounds ?? 0,
    );
  }

  /// Rating-ul Elo curent al unui mesaj (persistat, sau prior-ul de
  /// dificultate înainte de prima jucare).
  Future<Map<String, int>> _itemRatings(List<DojoMessage> all) async {
    final stats = await _db.select(_db.dojoItemStats).get();
    final byId = {for (final s in stats) s.itemId: s};
    return {
      for (final m in all)
        m.id: byId[m.id]?.rating ?? dojoPriorRating(m.difficulty),
    };
  }

  /// Alege runda următoare aproape de p(succes) ≈ 0.75, sărind mesajele
  /// văzute în ultimele două runde.
  Future<List<DojoMessage>> pickRound(
    List<DojoMessage> all, {
    int count = 5,
  }) async {
    final s = await state();
    final ratings = await _itemRatings(all);
    final stats = await _db.select(_db.dojoItemStats).get();
    final recent = {
      for (final st in stats)
        if (st.lastSeenRound > s.rounds - 2) st.itemId,
    };
    return dojoPickRound(
      all,
      ratingOf: (m) => ratings[m.id]!,
      idOf: (m) => m.id,
      userRating: s.rating,
      recent: recent,
      count: count,
    );
  }

  /// Aplică un răspuns: mută ambele rating-uri și recența itemului.
  Future<({int rating, bool beltUp})> applyAnswer(
    DojoMessage msg, {
    required bool correct,
  }) async {
    final s = await state();
    final stat = await (_db.select(
      _db.dojoItemStats,
    )..where((r) => r.itemId.equals(msg.id))).getSingleOrNull();
    final itemRating = stat?.rating ?? dojoPriorRating(msg.difficulty);

    final updated = dojoUpdate(
      userRating: s.rating,
      itemRating: itemRating,
      correct: correct,
    );

    await _db
        .into(_db.dojoStates)
        .insertOnConflictUpdate(
          DojoStatesCompanion(
            id: const Value(0),
            rating: Value(updated.user),
            rounds: Value(s.rounds),
          ),
        );
    await _db
        .into(_db.dojoItemStats)
        .insertOnConflictUpdate(
          DojoItemStatsCompanion(
            itemId: Value(msg.id),
            rating: Value(updated.item),
            plays: Value((stat?.plays ?? 0) + 1),
            correct: Value((stat?.correct ?? 0) + (correct ? 1 : 0)),
            lastSeenRound: Value(s.rounds),
          ),
        );

    return (
      rating: updated.user,
      beltUp: dojoBeltIndex(updated.user) > dojoBeltIndex(s.rating),
    );
  }

  /// Închide o rundă (avansează fereastra de recență).
  Future<void> finishRound() async {
    final s = await state();
    await _db
        .into(_db.dojoStates)
        .insertOnConflictUpdate(
          DojoStatesCompanion(
            id: const Value(0),
            rating: Value(s.rating),
            rounds: Value(s.rounds + 1),
          ),
        );
  }
}
