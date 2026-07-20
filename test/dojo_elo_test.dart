import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/domain/engine/dojo_elo.dart';
import 'package:finedu_flutter/features/arcade/data/dojo_repository.dart';

DojoMessage _msg(String id, {int difficulty = 2, bool scam = true}) =>
    DojoMessage(
      id: id,
      from: 'X',
      channel: 'SMS',
      tag: 'T',
      accent: 'danger',
      isScam: scam,
      difficulty: difficulty,
      text: 'text',
      flags: const ['f'],
      explain: 'e',
    );

void main() {
  group('dojo elo', () {
    test('expected success: equal ratings = 50%, easier items = higher', () {
      expect(dojoExpected(1000, 1000), closeTo(0.5, 1e-9));
      expect(dojoExpected(1000, 800), greaterThan(0.7));
      expect(dojoExpected(1000, 1200), lessThan(0.3));
    });

    test('update moves both ratings in opposite directions', () {
      final win = dojoUpdate(userRating: 1000, itemRating: 1000, correct: true);
      expect(win.user, greaterThan(1000));
      expect(win.item, lessThan(1000));

      final loss = dojoUpdate(
        userRating: 1000,
        itemRating: 1000,
        correct: false,
      );
      expect(loss.user, lessThan(1000));
      expect(loss.item, greaterThan(1000));

      // Un mesaj ușor prins mișcă puțin, unul ratat costă mult.
      final easyWin = dojoUpdate(
        userRating: 1200,
        itemRating: 800,
        correct: true,
      );
      final easyLoss = dojoUpdate(
        userRating: 1200,
        itemRating: 800,
        correct: false,
      );
      expect(easyWin.user - 1200, lessThan(5));
      expect(1200 - easyLoss.user, greaterThan(25));
    });

    test('belts climb with rating and progress stays in [0,1]', () {
      expect(dojoBeltIndex(dojoStartRating), 0); // albă
      expect(dojoBeltIndex(1100), 1);
      expect(dojoBeltIndex(1600), dojoBelts.length - 1); // neagră
      expect(dojoNextBeltAt(1000), 1050);
      expect(dojoNextBeltAt(1600), isNull);
      for (final r in [800, 1000, 1049, 1050, 1300, 1600, 2000]) {
        expect(dojoBeltProgress(r), inInclusiveRange(0, 1), reason: '$r');
      }
    });

    test('pickRound prefers the challenge zone and skips recent items', () {
      // La rating 1000: mesajele de ~810 stau la p≈0,75, 1600 e fără șanse.
      final near = [for (var i = 0; i < 6; i++) _msg('near$i')];
      final far = [for (var i = 0; i < 6; i++) _msg('far$i')];
      final ratings = {
        for (final m in near) m.id: 810,
        for (final m in far) m.id: 1600,
      };
      final picked = dojoPickRound(
        [...far, ...near],
        ratingOf: (m) => ratings[m.id]!,
        idOf: (m) => m.id,
        userRating: 1000,
        rng: Random(42),
      );
      expect(picked, hasLength(5));
      expect(
        picked.where((m) => m.id.startsWith('near')).length,
        greaterThanOrEqualTo(4),
        reason: 'the challenge zone should dominate the round',
      );

      // Prospețime: id-urile excluse nu apar cât timp ajunge pool-ul.
      final recentPick = dojoPickRound(
        [...near, ...far],
        ratingOf: (m) => ratings[m.id]!,
        idOf: (m) => m.id,
        userRating: 1000,
        recent: {for (final m in near) m.id},
        rng: Random(1),
      );
      expect(recentPick.every((m) => m.id.startsWith('far')), isTrue);

      // Rezervă: când pool-ul e prea mic, revin și mesajele recente.
      final fallback = dojoPickRound(
        near,
        ratingOf: (m) => ratings[m.id]!,
        idOf: (m) => m.id,
        userRating: 1000,
        recent: {for (final m in near) m.id},
        rng: Random(1),
      );
      expect(fallback, hasLength(5));
    });
  });

  group('DojoRepository', () {
    late AppDb db;
    late DojoRepository repo;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      repo = DojoRepository(db);
    });
    tearDown(() => db.close());

    test('applyAnswer persists both ratings and detects belt-up', () async {
      final msg = _msg('m1', difficulty: 3); // pleacă de la 1200, câștig mare
      var result = await repo.applyAnswer(msg, correct: true);
      expect(result.rating, greaterThan(dojoStartRating));

      final stat = await db.select(db.dojoItemStats).get();
      expect(stat.single.plays, 1);
      expect(stat.single.correct, 1);
      expect(stat.single.rating, lessThan(1200));

      // Câștiguri până la prima centură (1050): beltUp se aprinde o dată.
      var beltUps = 0;
      for (var i = 0; i < 10; i++) {
        result = await repo.applyAnswer(
          _msg('m$i', difficulty: 3),
          correct: true,
        );
        if (result.beltUp) beltUps++;
        if (result.rating >= 1100) break;
      }
      expect(beltUps, greaterThanOrEqualTo(1));
    });

    test('pickRound avoids the last two rounds, then recycles', () async {
      final all = [for (var i = 0; i < 12; i++) _msg('m$i')];
      final round1 = await repo.pickRound(all);
      expect(round1, hasLength(5));
      for (final m in round1) {
        await repo.applyAnswer(m, correct: true);
      }
      await repo.finishRound();

      final round2 = await repo.pickRound(all);
      final ids1 = round1.map((m) => m.id).toSet();
      expect(
        round2.where((m) => ids1.contains(m.id)),
        isEmpty,
        reason: 'round 2 must not repeat round 1',
      );
    });
  });
}
