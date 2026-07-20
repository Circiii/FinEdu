import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/score_engine.dart';

ScoreInputs _inputs({
  double budget = 800,
  double spent = 0,
  double saved = 0,
  int streak = 0,
  int tx = 0,
  int categories = 0,
  int lessonsDone = 0,
  int lessonsTotal = 25,
}) => ScoreInputs(
  budget: budget,
  spentThisMonth: spent,
  savedThisMonth: saved,
  streak: streak,
  txThisMonth: tx,
  categoriesThisMonth: categories,
  lessonsDone: lessonsDone,
  lessonsTotal: lessonsTotal,
);

void main() {
  group('score engine (specificația executabilă a webului)', () {
    test('budget: full at ratio<=1, zero at ratio>=1.4, linear between', () {
      expect(computeScore(_inputs(spent: 800)).budget, 25); // ratio = 1
      expect(computeScore(_inputs(spent: 400)).budget, 25); // under budget
      expect(computeScore(_inputs(spent: 1120)).budget, 0); // ratio = 1.4
      expect(computeScore(_inputs(spent: 2000)).budget, 0);
      final mid = computeScore(_inputs(spent: 960)).budget; // ratio = 1.2
      expect(mid, inInclusiveRange(12, 13));
    });

    test('savings: target is 20% of budget', () {
      expect(computeScore(_inputs(saved: 160)).savings, 25); // 20% of 800
      expect(computeScore(_inputs(saved: 80)).savings, 13); // half target
      expect(computeScore(_inputs(saved: 0)).savings, 0);
      expect(computeScore(_inputs(saved: 999)).savings, 25); // capped
    });

    test('streak: maxes at 21 days; consistency at 10 transactions', () {
      expect(computeScore(_inputs(streak: 21)).streak, 15);
      expect(computeScore(_inputs(streak: 50)).streak, 15);
      expect(computeScore(_inputs(streak: 7)).streak, 5);
      expect(computeScore(_inputs(tx: 10)).consistency, 15);
      expect(computeScore(_inputs(tx: 5)).consistency, 8);
    });

    test('learning + diversity: proportional, capped at 6 categories', () {
      expect(
        computeScore(_inputs(lessonsDone: 25, lessonsTotal: 25)).learning,
        10,
      );
      expect(
        computeScore(_inputs(lessonsDone: 13, lessonsTotal: 25)).learning,
        5,
      );
      expect(computeScore(_inputs(categories: 6)).diversity, 10);
      expect(computeScore(_inputs(categories: 9)).diversity, 10);
      expect(computeScore(_inputs(categories: 3)).diversity, 5);
    });

    test('total clamps to 1..100 and levels match the web thresholds', () {
      // Fără nicio dată tot arată 1, niciodată 0.
      expect(computeScore(_inputs(spent: 5000)).total, greaterThanOrEqualTo(1));

      final perfect = computeScore(
        _inputs(
          spent: 700,
          saved: 200,
          streak: 30,
          tx: 12,
          categories: 6,
          lessonsDone: 25,
        ),
      );
      expect(perfect.total, 100);

      expect(scoreLevelLabel(10), 'Începător');
      expect(scoreLevelLabel(30), 'Econom');
      expect(scoreLevelLabel(60), 'Investitor');
      expect(scoreLevelLabel(80), 'Expert');
    });

    test('profile factors are percentages of their own maximum', () {
      final b = computeScore(
        _inputs(
          spent: 400,
          saved: 160,
          streak: 21,
          tx: 10,
          categories: 6,
          lessonsDone: 25,
        ),
      );
      expect(b.budgetFactor, 100);
      expect(b.savingsFactor, 100);
      expect(b.steadinessFactor, 100);
      expect(b.knowledgeFactor, 100);

      final half = computeScore(_inputs(saved: 80));
      expect(half.savingsFactor, inInclusiveRange(50, 52));
    });

    test('no budget set: neutral credit, not punishment', () {
      final b = computeScore(_inputs(budget: 0, saved: 50));
      expect(b.budget, 12);
      expect(b.savings, 25, reason: 'any saving counts when no target exists');
    });
  });
}
