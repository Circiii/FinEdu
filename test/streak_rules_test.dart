import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/quest_engine.dart';
import 'package:finedu_flutter/domain/engine/streak_rules.dart';

void main() {
  group('evaluateStreak, freezes', () {
    test('one missed day is silently frozen and the streak survives', () {
      final r = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: {'2026-07-04', '2026-07-05', '2026-07-07'},
        todayKindCount: 1,
        today: '2026-07-07',
      );
      expect(r.events.whereType<FreezeUsed>().single.day, '2026-07-06');
      expect(r.snapshot.freezes, 1);
      expect(r.current, 4); // 4,5,(6 frozen),7
    });

    test('two missed days consume both freezes', () {
      final r = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: {'2026-07-03', '2026-07-04', '2026-07-07'},
        todayKindCount: 1,
        today: '2026-07-07',
      );
      expect(r.events.whereType<FreezeUsed>().length, 2);
      expect(r.snapshot.freezes, 0);
      expect(r.current, 5);
    });

    test('rollover is idempotent per day (no double freeze burn)', () {
      final first = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: {'2026-07-05', '2026-07-07'},
        todayKindCount: 1,
        today: '2026-07-07',
      );
      final second = evaluateStreak(
        snapshot: first.snapshot,
        activityDays: {'2026-07-05', '2026-07-07'},
        todayKindCount: 1,
        today: '2026-07-07',
      );
      expect(second.snapshot.freezes, first.snapshot.freezes);
      expect(second.events.whereType<FreezeUsed>(), isEmpty);
    });

    test('today itself is never frozen (yesterday-holds rule applies)', () {
      final r = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: {'2026-07-05', '2026-07-06'},
        todayKindCount: 0,
        today: '2026-07-07',
      );
      expect(r.snapshot.freezes, 2); // nothing to protect yet
      expect(r.current, 2);
    });
  });

  group('evaluateStreak, break + earn-back', () {
    StreakSnapshot broken() {
      // Streak de 3 zile, apoi o pauză de 3 zile (peste 2 înghețuri) → rupt.
      final r = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: {'2026-06-29', '2026-06-30', '2026-07-01', '2026-07-05'},
        todayKindCount: 1,
        today: '2026-07-05',
      );
      final ev = r.events.whereType<StreakBrokenEvent>().single;
      expect(ev.previous, 3);
      expect(ev.until, '2026-07-06');
      expect(r.current, 1); // doar ziua de azi
      expect(
        r.snapshot.freezes,
        2,
      ); // nu ardem înghețurile pe un streak deja pierdut
      return r.snapshot;
    }

    test('break arms earn-back with the previous value', broken);

    test('earn-back succeeds with 2 kinds inside the window', () {
      final s = broken();
      final r = evaluateStreak(
        snapshot: s,
        activityDays: {'2026-06-29', '2026-06-30', '2026-07-01', '2026-07-05'},
        todayKindCount: 2,
        today: '2026-07-05',
      );
      expect(r.events.whereType<EarnbackSucceeded>(), isNotEmpty);
      // Golul acoperit: 29,30,1,(2,3,4 acoperite),5 → 7 zile la rând.
      expect(r.current, 7);
      expect(r.snapshot.earnbackUntil, isNull);
    });

    test('earn-back expires silently; the fresh gap is then freeze-protected '
        '(Duolingo semantics: freezes burn on any missed day)', () {
      final s = broken();
      final r = evaluateStreak(
        snapshot: s,
        activityDays: {
          '2026-06-29',
          '2026-06-30',
          '2026-07-01',
          '2026-07-05',
          '2026-07-08',
        },
        todayKindCount: 1,
        today: '2026-07-08',
      );
      expect(r.snapshot.earnbackUntil, isNull);
      expect(r.events.whereType<EarnbackSucceeded>(), isEmpty);
      // 05 (real) + 06,07 (înghețate) + 08 (real) → 4, ambele înghețuri consumate.
      expect(r.current, 4);
      expect(r.snapshot.freezes, 0);
      expect(r.events.whereType<FreezeUsed>().length, 2);
    });
  });

  group('evaluateStreak, milestones', () {
    test('reaching 7 fires once, with the right reward', () {
      final days = {for (var d = 1; d <= 7; d++) '2026-07-0$d'};
      final first = evaluateStreak(
        snapshot: const StreakSnapshot(),
        activityDays: days,
        todayKindCount: 1,
        today: '2026-07-07',
      );
      final m = first.events.whereType<MilestoneReached>().single;
      expect(m.days, 7);
      expect(m.acorns, 15);

      final again = evaluateStreak(
        snapshot: first.snapshot,
        activityDays: days,
        todayKindCount: 1,
        today: '2026-07-07',
      );
      expect(again.events.whereType<MilestoneReached>(), isEmpty);
    });
  });

  group('quest engine', () {
    test('3 quests per day, slot 3 rotates by day parity', () {
      final even = questsFor('2026-07-06');
      final odd = questsFor('2026-07-07');
      expect(even.length, 3);
      expect(even[2].id, QuestId.noFunSpend);
      expect(odd[2].id, QuestId.keepFlame);
    });

    test('completion rules derive from real data', () {
      expect(
        questDone(
          QuestId.logToday,
          todayKinds: {'log'},
          todayExpenseCategories: {},
          streakCurrent: 0,
        ),
        isTrue,
      );
      expect(
        questDone(
          QuestId.noFunSpend,
          todayKinds: {'log'},
          todayExpenseCategories: {'mancare'},
          streakCurrent: 1,
        ),
        isTrue,
      );
      expect(
        questDone(
          QuestId.noFunSpend,
          todayKinds: {'log'},
          todayExpenseCategories: {'distractie'},
          streakCurrent: 1,
        ),
        isFalse,
      );
      expect(
        questDone(
          QuestId.dojoRound,
          todayKinds: {'log'},
          todayExpenseCategories: {},
          streakCurrent: 1,
        ),
        isFalse,
      );
    });

    test(
      'chest value: transparent floor grows with streak, bounded spread',
      () {
        final v0 = chestValue('2026-07-07', 0);
        final v20 = chestValue('2026-07-07', 20);
        final v99 = chestValue('2026-07-07', 99);
        expect(v0, inInclusiveRange(5, 20));
        expect(v20, inInclusiveRange(25, 40));
        expect(v99, v20); // capped at +20
        // Determinist pe dată.
        expect(chestValue('2026-07-07', 5), chestValue('2026-07-07', 5));
      },
    );
  });
}
