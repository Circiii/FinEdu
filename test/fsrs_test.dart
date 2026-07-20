import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/domain/engine/fsrs.dart';
import 'package:finedu_flutter/domain/util/day_key.dart';
import 'package:finedu_flutter/features/learning/data/lessons_repository.dart';

// Aritmetică INDEPENDENTĂ, rescrisă din aceleași formule FSRS-6 (nu apelăm
// motorul), ca golden-urile să prindă o eventuală eroare de implementare.
const _w = fsrsDefaultWeights;
final double _decay = -_w[20]; // -0.1542
final double _factor = math.pow(0.9, 1 / _decay) - 1; // ≈ 0.980438

int _expectedInterval(double s, double r) {
  final raw = (s / _factor) * (math.pow(r, 1 / _decay) - 1);
  final rounded = raw.round();
  return rounded < 1
      ? 1
      : (rounded > maxIntervalDays ? maxIntervalDays : rounded);
}

Lesson _lesson(String id) => Lesson(
  id: id,
  emoji: '📖',
  minutes: 3,
  xp: 15,
  difficulty: 'beginner',
  title: 'T',
  hook: 'H',
  concept: const ['C'],
  example: 'E',
  interactive: const LessonInteractive(kind: 'mcq'),
  recap: const ['R'],
  action: 'A',
  cards: const [ConceptCard('c1', 'Q1', 'A1')],
);

void main() {
  group('fsrs golden (aritmetică independentă)', () {
    test(
      'prima recenzie Good → S == w[2], interval = cel calculat la R=0.83',
      () {
        final r = fsrsGrade(known: true, elapsedDays: 1);
        expect(r.memory.stability, _w[2]); // 2.3065
        expect(r.intervalDays, _expectedInterval(_w[2], desiredRetention));
        expect(r.intervalDays, 6); // sanity: valoare concretă
      },
    );

    test('prima recenzie Again → S == w[0]', () {
      final r = fsrsGrade(known: false, elapsedDays: 1);
      expect(r.memory.stability, _w[0]); // 0.212
      expect(r.intervalDays, _expectedInterval(_w[0], desiredRetention));
    });

    test('D0 respectă formula w4 − e^(w5·(rating−1)) + 1', () {
      // Good (rating 3) și Again (rating 1), verificăm dificultatea inițială.
      final good = fsrsGrade(known: true, elapsedDays: 1);
      final again = fsrsGrade(known: false, elapsedDays: 1);
      final expGood = (_w[4] - math.exp(_w[5] * 2) + 1).clamp(1.0, 10.0);
      final expAgain = (_w[4] - math.exp(_w[5] * 0) + 1).clamp(1.0, 10.0);
      expect(good.memory.difficulty, closeTo(expGood, 1e-9));
      expect(again.memory.difficulty, closeTo(expAgain, 1e-9));
      // Again e mai greu decât Good (recall ușor ⇒ dificultate mică).
      expect(again.memory.difficulty, greaterThan(good.memory.difficulty));
    });
  });

  group('fsrs proprietăți', () {
    test('Good repetat pe program → S strict crescătoare; interval crește '
        'până la plafon', () {
      var m = fsrsGrade(known: true, elapsedDays: 1);
      var prevS = m.memory.stability;
      var prevI = m.intervalDays;
      var sawGrowth = false;
      for (var i = 0; i < 6; i++) {
        m = fsrsGrade(
          memory: m.memory,
          known: true,
          elapsedDays: prevI.toDouble(), // recenzie „la timp"
        );
        // Stabilitatea crește NELIMITAT la fiecare Good.
        expect(
          m.memory.stability,
          greaterThan(prevS),
          reason: 'pasul $i stabilitate',
        );
        // Intervalul crește strict cât timp e sub plafon; apoi saturează la 180.
        if (prevI < maxIntervalDays) {
          expect(
            m.intervalDays,
            greaterThan(prevI),
            reason: 'pasul $i interval',
          );
          sawGrowth = true;
        }
        prevS = m.memory.stability;
        prevI = m.intervalDays;
      }
      expect(sawGrowth, isTrue); // chiar am observat creșterea intervalului
    });

    test('Again după stabilitate mare → S scade dar NU la inițial', () {
      const high = FsrsMemory(stability: 50, difficulty: 5);
      final r = fsrsGrade(memory: high, known: false, elapsedDays: 50);
      expect(r.memory.stability, lessThan(50)); // a scăzut
      expect(
        r.memory.stability,
        greaterThan(_w[0]),
        reason: 'post-lapse păstrează o fracțiune, nu resetează la S0',
      );
      expect(r.memory.stability, greaterThan(1)); // net peste inițial
    });

    test('R=0.83 dă interval mai lung decât R=0.90 pentru aceeași S', () {
      final i083 = _expectedInterval(30, 0.83);
      final i090 = _expectedInterval(30, 0.90);
      expect(i083, greaterThan(i090));
      // La R=0.90, intervalul == stabilitatea (invariantul clasic FSRS).
      expect(i090, 30);
    });

    test('intervalul e prins la maxIntervalDays (180)', () {
      const huge = FsrsMemory(stability: 100000, difficulty: 1);
      final r = fsrsGrade(memory: huge, known: true, elapsedDays: 1);
      expect(r.intervalDays, maxIntervalDays);
    });

    test('retrievabilitatea: R(0)=1 și descrește cu elapsedDays', () {
      expect(retrievability(stability: 10, elapsedDays: 0), 1.0);
      final r5 = retrievability(stability: 10, elapsedDays: 5);
      final r10 = retrievability(stability: 10, elapsedDays: 10);
      final r20 = retrievability(stability: 10, elapsedDays: 20);
      expect(r5, greaterThan(r10));
      expect(r10, greaterThan(r20));
      expect(r5, lessThan(1.0));
      expect(r20, greaterThan(0.0));
      // La elapsed == S, retenția e ~0.90 (definiția stabilității).
      expect(
        retrievability(stability: 10, elapsedDays: 10),
        closeTo(0.90, 1e-6),
      );
    });
  });

  group('fsrs mapare 2 butoane', () {
    test(
      'known=true → cale Good (S urcă), known=false → Again (S coboară)',
      () {
        const m = FsrsMemory(stability: 10, difficulty: 5);
        final good = fsrsGrade(memory: m, known: true, elapsedDays: 10);
        final again = fsrsGrade(memory: m, known: false, elapsedDays: 10);
        expect(good.memory.stability, greaterThan(10));
        expect(again.memory.stability, lessThan(10));
      },
    );
  });

  group('fsrs migrare din cutie', () {
    test('seed din box: S/D aproximează cutia; box3 → S≈7', () {
      expect(fsrsSeedFromBox(1).stability, 1.0);
      expect(fsrsSeedFromBox(2).stability, 3.0);
      expect(fsrsSeedFromBox(3).stability, 7.0);
      expect(fsrsSeedFromBox(4).stability, 21.0);
      // dificultatea scade cu cutia (sus = mai ușor pentru user)
      expect(
        fsrsSeedFromBox(1).difficulty,
        greaterThan(fsrsSeedFromBox(4).difficulty),
      );
    });

    test('grade pe card seedat din box3 → S crește, interval sănătos', () {
      final seed = fsrsSeedFromBox(3); // S=7
      final r = fsrsGrade(memory: seed, known: true, elapsedDays: 7);
      expect(r.memory.stability, greaterThan(7));
      expect(r.intervalDays, inInclusiveRange(1, maxIntervalDays));
      expect(r.intervalDays, greaterThan(5)); // nu colapsează la 1
    });

    test('bucketul de box derivat din stabilitate e corect', () {
      expect(fsrsBoxBucket(1.0), 1);
      expect(fsrsBoxBucket(2.99), 1);
      expect(fsrsBoxBucket(3.0), 2);
      expect(fsrsBoxBucket(9.99), 2);
      expect(fsrsBoxBucket(10.0), 3);
      expect(fsrsBoxBucket(29.99), 3);
      expect(fsrsBoxBucket(30.0), 4);
      expect(fsrsBoxBucket(200.0), 4);
    });
  });

  group('fsrs wiring în LearnRepository (migrare lazy)', () {
    late AppDb db;
    late LearnRepository repo;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      repo = LearnRepository(db, LocalProfileRepository(db));
    });
    tearDown(() => db.close());

    test(
      'card moștenit (stability NULL) se migrează din box la prima notare',
      () async {
        await repo.completeLesson(_lesson('l1'));
        final legacy = (await db.select(db.reviewCards).get()).first;
        expect(legacy.stability, isNull); // creat pre-FSRS
        expect(legacy.box, 1);

        await repo.grade(legacy, known: true);

        final updated = await (db.select(
          db.reviewCards,
        )..where((c) => c.cardId.equals(legacy.cardId))).getSingle();
        expect(updated.stability, isNotNull); // FSRS a preluat cardul
        expect(updated.difficulty, isNotNull);
        expect(updated.lastReview, dayKey(DateTime.now()));
        expect(updated.box, fsrsBoxBucket(updated.stability!));
        // Programat în viitor (nu azi).
        expect(
          updated.nextDue.compareTo(dayKey(DateTime.now())),
          greaterThan(0),
        );
      },
    );

    test('„Nu știu" numără lapse-ul, ca la Leitner', () async {
      await repo.completeLesson(_lesson('l2'));
      final card = (await db.select(db.reviewCards).get()).first;
      await repo.grade(card, known: false);
      final updated = await (db.select(
        db.reviewCards,
      )..where((c) => c.cardId.equals(card.cardId))).getSingle();
      expect(updated.lapses, card.lapses + 1);
    });
  });
}
