import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/cashy_state.dart';
import 'package:finedu_flutter/domain/engine/streak_engine.dart';

void main() {
  group('computeStreak', () {
    test('empty history → 0/0', () {
      expect(computeStreak({}, '2026-07-07'), (current: 0, longest: 0));
    });

    test('only today → 1/1', () {
      expect(computeStreak({'2026-07-07'}, '2026-07-07'), (
        current: 1,
        longest: 1,
      ));
    });

    test('yesterday still holds the streak (Duolingo rule)', () {
      expect(computeStreak({'2026-07-05', '2026-07-06'}, '2026-07-07'), (
        current: 2,
        longest: 2,
      ));
    });

    test('a 2-day gap breaks the current streak but longest survives', () {
      expect(
        computeStreak({
          '2026-07-01',
          '2026-07-02',
          '2026-07-03',
          '2026-07-07',
        }, '2026-07-07'),
        (current: 1, longest: 3),
      );
    });

    test(
      'gap of exactly 2 days (activity day-before-yesterday) → 0 current',
      () {
        expect(computeStreak({'2026-07-05'}, '2026-07-07'), (
          current: 0,
          longest: 1,
        ));
      },
    );

    test('consecutive run across a month boundary', () {
      expect(computeStreak({'2026-06-30', '2026-07-01'}, '2026-07-01'), (
        current: 2,
        longest: 2,
      ));
    });

    test('leap day: Feb 28 → Feb 29 → Mar 1 2028 is consecutive', () {
      expect(
        computeStreak({'2028-02-28', '2028-02-29', '2028-03-01'}, '2028-03-01'),
        (current: 3, longest: 3),
      );
    });

    test('longest can exceed current', () {
      final days = {
        '2026-06-01',
        '2026-06-02',
        '2026-06-03',
        '2026-06-04',
        '2026-06-05',
        '2026-07-06',
        '2026-07-07',
      };
      expect(computeStreak(days, '2026-07-07'), (current: 2, longest: 5));
    });
  });

  group('moodFor', () {
    test('no budget → happy', () {
      expect(
        moodFor(spentThisMonth: 900, monthlyBudget: null),
        CashyMood.happy,
      );
      expect(moodFor(spentThisMonth: 900, monthlyBudget: 0), CashyMood.happy);
    });

    test('thresholds: 79.9% happy, 80% alert, 99.9% alert, 100% worried', () {
      expect(
        moodFor(spentThisMonth: 799, monthlyBudget: 1000),
        CashyMood.happy,
      );
      expect(
        moodFor(spentThisMonth: 800, monthlyBudget: 1000),
        CashyMood.alert,
      );
      expect(
        moodFor(spentThisMonth: 999, monthlyBudget: 1000),
        CashyMood.alert,
      );
      expect(
        moodFor(spentThisMonth: 1000, monthlyBudget: 1000),
        CashyMood.worried,
      );
      expect(
        moodFor(spentThisMonth: 1400, monthlyBudget: 1000),
        CashyMood.worried,
      );
    });
  });
}
