import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/insight_rules.dart';

InsightInputs _inputs({
  DateTime? now,
  double budget = 800,
  double spent = 0,
  int txCount = 10,
  Map<String, double> catMonth = const {},
  Map<String, double> cat3m = const {},
  int history = 3,
  double thisWeek = 0,
  double prevWeek = 0,
  int thisWeekTx = 5,
  int prevWeekTx = 5,
  List<GoalLite> goals = const [],
  List<RecurringLite> upcoming = const [],
  double recurringTotal = 0,
  double savedAllTime = 0,
  double lastMonthSpent = 0,
  double lastMonthSaved = 0,
}) =>
    InsightInputs(
      now: now ?? DateTime(2026, 7, 15), // miercuri, ziua 15 din 31
      budget: budget,
      spentThisMonth: spent,
      txCountThisMonth: txCount,
      categorySpendThisMonth: catMonth,
      category3mMonthlyAvg: cat3m,
      fullMonthsOfHistory: history,
      thisWeekSpent: thisWeek,
      prevWeekSpent: prevWeek,
      thisWeekTxCount: thisWeekTx,
      prevWeekTxCount: prevWeekTx,
      thisWeekTopCategory: 'mancare',
      goals: goals,
      upcomingRecurring: upcoming,
      monthlyRecurringTotal: recurringTotal,
      savedAllTime: savedAllTime,
      lastMonthSpent: lastMonthSpent,
      lastMonthSaved: lastMonthSaved,
    );

Iterable<String> _keys(List<InsightCandidate> list) =>
    list.map((c) => c.ruleKey);

void main() {
  group('pacing', () {
    test('over pace fires as corrective with the new daily budget', () {
      // Ziua 15/31: ritmul așteptat ~387; cheltuit 600 → ratio 1.55.
      final list = evaluateInsights(_inputs(spent: 600));
      final pace = list.singleWhere((c) => c.ruleKey == 'pace_over');
      expect(pace.kind, InsightKind.corrective);
      // (800-600)/17 zile rămase ≈ 11 lei/zi.
      expect(pace.values['perDay'], '12');
      expect(_keys(list), isNot(contains('pace_under')));
    });

    test('under pace praises; near pace stays silent; gates hold', () {
      expect(_keys(evaluateInsights(_inputs(spent: 200))),
          contains('pace_under'));
      expect(_keys(evaluateInsights(_inputs(spent: 380))),
          isNot(anyOf(contains('pace_over'), contains('pace_under'))));
      // Sub 5 tranzacții sau fără buget: tăcere.
      expect(_keys(evaluateInsights(_inputs(spent: 600, txCount: 3))),
          isNot(contains('pace_over')));
      expect(_keys(evaluateInsights(_inputs(spent: 600, budget: 0))),
          isNot(contains('pace_over')));
    });
  });

  test('weekly recap fires only on Monday with enough data', () {
    final monday = DateTime(2026, 7, 13);
    final list = evaluateInsights(
        _inputs(now: monday, thisWeek: 80, prevWeek: 120));
    final recap = list.singleWhere((c) => c.ruleKey == 'weekly_recap');
    expect(recap.kind, InsightKind.positive); // a cheltuit mai puțin
    expect(recap.values['direction'], 'less');

    expect(_keys(evaluateInsights(_inputs(thisWeek: 80, prevWeek: 120))),
        isNot(contains('weekly_recap')),
        reason: 'miercurea nu e zi de recap');
  });

  group('category anomaly vs own average', () {
    test('picks the worst offender, respects both thresholds', () {
      final list = evaluateInsights(_inputs(
        catMonth: {'fastfood': 180, 'transport': 50},
        cat3m: {'fastfood': 100, 'transport': 45},
      ));
      final anomaly =
          list.singleWhere((c) => c.ruleKey == 'category_anomaly');
      expect(anomaly.values['category'], 'fastfood');
      // transport: 50 < 45*1.5 → nu e anomalie.
    });

    test('needs 2 full months of history; win fires after day 10', () {
      expect(
          _keys(evaluateInsights(_inputs(
            catMonth: {'fastfood': 180},
            cat3m: {'fastfood': 100},
            history: 1,
          ))),
          isNot(contains('category_anomaly')));

      final win = evaluateInsights(_inputs(
        catMonth: {'fastfood': 20},
        cat3m: {'fastfood': 100},
      )).singleWhere((c) => c.ruleKey == 'category_win');
      expect(win.kind, InsightKind.positive);
      expect(win.values['saved'], '80');
    });
  });

  test('goal milestones report only the highest crossed threshold', () {
    final list = evaluateInsights(_inputs(goals: [
      const GoalLite(
          id: 'g1', name: 'Căști', emoji: '🎧', target: 600, saved: 460),
    ]));
    final goal = list.singleWhere((c) => c.ruleKey == 'goal_milestone');
    expect(goal.id, 'goal_g1_75');
    expect(_keys(list).where((k) => k.startsWith('goal')).length, 1);

    final done = evaluateInsights(_inputs(goals: [
      const GoalLite(
          id: 'g1', name: 'Căști', emoji: '🎧', target: 600, saved: 600),
    ]));
    expect(done.singleWhere((c) => c.id.startsWith('goal_')).ruleKey,
        'goal_done');
  });

  test('recurring: due window 1-3 days + monthly share', () {
    final list = evaluateInsights(_inputs(
      spent: 380, // aproape de ritm, pacing tace
      upcoming: [
        const RecurringLite(merchant: 'Spotify', amount: 26, dueInDays: 2),
        const RecurringLite(merchant: 'Netflix', amount: 40, dueInDays: 9),
      ],
      recurringTotal: 66,
    ));
    final due = list.singleWhere((c) => c.ruleKey == 'recurring_due');
    expect(due.values['merchant'], 'Spotify');
    expect(due.values['remaining'], '394');
    final share = list.singleWhere((c) => c.ruleKey == 'recurring_share');
    expect(share.values['pct'], '8');
  });

  test('fresh start on the 1st-2nd; saving milestone picks highest', () {
    final fresh = evaluateInsights(_inputs(
      now: DateTime(2026, 8, 1),
      txCount: 0,
      lastMonthSpent: 640,
      lastMonthSaved: 90,
    ));
    expect(_keys(fresh), contains('fresh_start'));

    final saving = evaluateInsights(_inputs(savedAllTime: 620))
        .singleWhere((c) => c.ruleKey == 'saving_total');
    expect(saving.values['threshold'], '500');
  });

  group('selectInsights (disciplina de afișare)', () {
    const corrective = InsightCandidate(
        id: 'c1',
        ruleKey: 'pace_over',
        kind: InsightKind.corrective,
        score: 90);
    const corrective2 = InsightCandidate(
        id: 'c2',
        ruleKey: 'category_anomaly',
        kind: InsightKind.corrective,
        score: 85);
    const positive = InsightCandidate(
        id: 'p1',
        ruleKey: 'category_win',
        kind: InsightKind.positive,
        score: 60);

    test('cooldown skips shown ids; max one corrective per batch', () {
      final picked = selectInsights(
        [corrective, corrective2, positive],
        recentlyShown: {'c1'},
        suppressedRules: {},
        recentCorrectiveStreak: 0,
      );
      expect(picked.map((c) => c.id), ['c2', 'p1']);
    });

    test('after 2 corectives in a row, only gentle cards pass', () {
      final picked = selectInsights(
        [corrective, positive],
        recentlyShown: {},
        suppressedRules: {},
        recentCorrectiveStreak: 2,
      );
      expect(picked.map((c) => c.id), ['p1']);
    });

    test('suppressed rule types stay out, except positives', () {
      final picked = selectInsights(
        [corrective, positive],
        recentlyShown: {},
        suppressedRules: {'pace_over', 'category_win'},
        recentCorrectiveStreak: 0,
      );
      expect(picked.map((c) => c.id), ['p1'],
          reason: 'pozitivele nu se suprimă niciodată');
    });
  });
}
