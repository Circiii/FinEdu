import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/daily_challenge.dart';
import 'package:finedu_flutter/domain/engine/turbo_rules.dart';

void main() {
  group('daily challenge selection', () {
    test('format rotates price -> myth -> dilemma, deterministic per date',
        () {
      expect(formatFor('2026-07-06'), formatFor('2026-07-06'));
      final f0 = formatFor('2026-07-06');
      final f1 = formatFor('2026-07-07');
      final f2 = formatFor('2026-07-08');
      expect({f0, f1, f2}, DailyFormat.values.toSet());
      // Full cycle: 3 days later the same format returns...
      expect(formatFor('2026-07-09'), f0);
      // ...but the pool index has advanced by one (and wraps).
      final i0 = puzzleIndexFor('2026-07-06', 5);
      expect(puzzleIndexFor('2026-07-09', 5), (i0 + 1) % 5);
    });

    test('price points reward closeness in tiers', () {
      expect(pricePoints(guess: 100, actual: 100), 25); // exact
      expect(pricePoints(guess: 104, actual: 100), 25); // <=5%
      expect(pricePoints(guess: 114, actual: 100), 20); // <=15%
      expect(pricePoints(guess: 130, actual: 100), 12); // <=30%
      expect(pricePoints(guess: 150, actual: 100), 5); // <=50%
      expect(pricePoints(guess: 250, actual: 100), 0);
      // Symmetric: undershooting scores the same as overshooting.
      expect(pricePoints(guess: 86, actual: 100), 20);
    });

    test('myth score: 3/3 rounds to a clean 100', () {
      expect(mythScore(0), 0);
      expect(mythScore(1), 33);
      expect(mythScore(2), 66);
      expect(mythScore(3), 100);
    });

    test('daily bonus game rotates through all games', () {
      expect(
        {
          dailyBonusGame('2026-07-06'),
          dailyBonusGame('2026-07-07'),
          dailyBonusGame('2026-07-08'),
        },
        arcadeGames.toSet(),
      );
    });
  });

  group('turbo rules', () {
    test('combo grows points, capped; wrong answer costs a life and combo',
        () {
      var s = const TurboState();
      expect(s.nextPoints, 10);
      s = applyAnswer(s, isCorrect: true); // +10
      expect(s.score, 10);
      expect(s.nextPoints, 12);
      s = applyAnswer(s, isCorrect: true); // +12
      expect(s.score, 22);

      // Cap: from combo 5 onward every correct is worth 20.
      for (var i = 0; i < 10; i++) {
        s = applyAnswer(s, isCorrect: true);
      }
      final before = s.score;
      s = applyAnswer(s, isCorrect: true);
      expect(s.score - before, 20);

      final lives = s.lives;
      s = applyAnswer(s, isCorrect: false);
      expect(s.lives, lives - 1);
      expect(s.combo, 0);
      expect(s.score, greaterThan(0)); // score never drops
    });

    test('three mistakes end the run', () {
      var s = const TurboState();
      s = applyAnswer(s, isCorrect: false);
      s = applyAnswer(s, isCorrect: false);
      expect(s.over, isFalse);
      s = applyAnswer(s, isCorrect: false);
      expect(s.over, isTrue);
      expect(s.answered, 3);
      expect(s.correct, 0);
    });
  });
}
