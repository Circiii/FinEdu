/// Motorul „Pentru tine": carduri calculate din datele de pe telefon, cu reguli
/// fixe. Motorul e pur, cine îl cheamă aduce agregatele și ține istoricul.
library;

import 'money_intel.dart';

/// Ce fel de card e, motorul de afișare garantează raportul 2:1
/// pozitiv:corectiv (un feed care apare doar când „e rău" se ignoră).
enum InsightKind { positive, corrective, utility }

class InsightCandidate {
  const InsightCandidate({
    required this.id,
    required this.ruleKey,
    required this.kind,
    required this.score,
    this.values = const {},
  });

  /// Identitate pentru cooldown/dedup (poate include ținta: `goal_x_50`).
  final String id;

  /// Cheia de copy din content/insights.json.
  final String ruleKey;
  final InsightKind kind;

  /// Prioritate 0-100 (motorul afișează top 1-2).
  final int score;

  /// Valorile injectate în template ({spent}, {perDay}...), deja formatate.
  final Map<String, String> values;
}

class GoalLite {
  const GoalLite({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
  });
  final String id;
  final String name;
  final String emoji;
  final double target;
  final double saved;
}

class RecurringLite {
  const RecurringLite({
    required this.merchant,
    required this.amount,
    required this.dueInDays,
  });
  final String merchant;
  final double amount;
  final int dueInDays;
}

class InsightInputs {
  const InsightInputs({
    required this.now,
    required this.budget,
    required this.spentThisMonth,
    required this.txCountThisMonth,
    required this.categorySpendThisMonth,
    required this.category3mMonthlyAvg,
    required this.fullMonthsOfHistory,
    required this.thisWeekSpent,
    required this.prevWeekSpent,
    required this.thisWeekTxCount,
    required this.prevWeekTxCount,
    required this.thisWeekTopCategory,
    required this.goals,
    required this.upcomingRecurring,
    required this.monthlyRecurringTotal,
    required this.savedAllTime,
    required this.lastMonthSpent,
    required this.lastMonthSaved,
    // Toate opționale: apelanții existenți rămân neatinși, iar lipsa datelor
    // înseamnă porți închise, nu erori.
    this.latestExpense,
    this.categoryAmounts90d = const {},
    this.recurringDueSoon = 0,
    this.goalContributionsThisMonth = 0,
    this.recurringGuesses = const [],
    this.declaredRecurringCategories = const {},
  });

  final DateTime now;
  final double budget;
  final double spentThisMonth;
  final int txCountThisMonth;
  final Map<String, double> categorySpendThisMonth;

  /// Media LUNARĂ pe categoria X în ultimele 3 luni calendaristice pline.
  final Map<String, double> category3mMonthlyAvg;
  final int fullMonthsOfHistory;

  final double thisWeekSpent;
  final double prevWeekSpent;
  final int thisWeekTxCount;
  final int prevWeekTxCount;
  final String? thisWeekTopCategory;

  final List<GoalLite> goals;
  final List<RecurringLite> upcomingRecurring;
  final double monthlyRecurringTotal;
  final double savedAllTime;
  final double lastMonthSpent;
  final double lastMonthSaved;

  /// Ultima cheltuială logată, candidatul întrebării de anomalie. NULL =
  /// nicio cheltuială în fereastră.
  final ({String category, double amount, DateTime date})? latestExpense;

  /// Sumele cheltuielilor pe categorie din ultimele ~90 zile, FĂRĂ ultima
  /// cheltuială (istoricul curat cu care o comparăm).
  final Map<String, List<double>> categoryAmounts90d;

  /// Recurentele declarate scadente până la finalul lunii (suma lor).
  final double recurringDueSoon;

  /// Banii puși deoparte luna asta, cu sau fără obiectiv legat, nu mai sunt
  /// „liberi de cheltuit".
  final double goalContributionsThisMonth;

  /// Tiparele „posibil recurent" găsite de [detectRecurring] în jurnal.
  final List<RecurringGuess> recurringGuesses;

  /// Categoriile recurentelor DECLARATE de utilizator, radarul tace pe ele.
  final Set<String> declaredRecurringCategories;
}

String _lei(double v) => v.round().toString();

int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// Evaluează toate regulile și întoarce candidații care AU dreptul să apară
/// azi (porțile de date trecute). Cooldown-urile și raportul 2:1 se aplică
/// deasupra, cu istoricul persistat.
List<InsightCandidate> evaluateInsights(InsightInputs i) {
  final out = <InsightCandidate>[];
  final daysIn = _daysInMonth(i.now);
  final dayOfMonth = i.now.day;
  final daysLeft = daysIn - dayOfMonth + 1;

  // --- Ritmul lunii (pacing), regula cu cea mai mare valoare zilnică
  // Poartă: buget setat, ≥5 tranzacții, măcar ziua 5 (altfel zgomot).
  if (i.budget > 0 && i.txCountThisMonth >= 5 && dayOfMonth >= 5) {
    final expected = i.budget * dayOfMonth / daysIn;
    final ratio = expected <= 0 ? 1.0 : i.spentThisMonth / expected;
    final perDay = ((i.budget - i.spentThisMonth) / daysLeft).clamp(0, 99999);
    if (ratio <= 0.9) {
      out.add(
        InsightCandidate(
          id: 'pace_under',
          ruleKey: 'pace_under',
          kind: InsightKind.positive,
          score: 70,
          values: {
            'delta': _lei(expected - i.spentThisMonth),
            'perDay': _lei(perDay.toDouble()),
            'spent': _lei(i.spentThisMonth),
            'expected': _lei(expected),
          },
        ),
      );
    } else if (ratio >= 1.1) {
      out.add(
        InsightCandidate(
          id: 'pace_over',
          ruleKey: 'pace_over',
          kind: InsightKind.corrective,
          score: 65,
          values: {
            'perDay': _lei(perDay.toDouble()),
            'daysLeft': '$daysLeft',
            'spent': _lei(i.spentThisMonth),
            'expected': _lei(expected),
          },
        ),
      );
    }
  }

  // --- Recap săptămânal (lunea; „mini-Wrapped" predictibil)
  if (i.now.weekday == DateTime.monday &&
      i.prevWeekTxCount + i.thisWeekTxCount >= 3 &&
      i.prevWeekSpent > 0) {
    final delta = i.prevWeekSpent == 0
        ? 0
        : ((i.thisWeekSpent - i.prevWeekSpent) / i.prevWeekSpent * 100).round();
    out.add(
      InsightCandidate(
        id: 'weekly_recap',
        ruleKey: 'weekly_recap',
        kind: delta <= 0 ? InsightKind.positive : InsightKind.utility,
        score: 75,
        values: {
          'total': _lei(i.thisWeekSpent),
          'top': i.thisWeekTopCategory ?? ', ',
          'deltaPct': '${delta.abs()}',
          'direction': delta <= 0 ? 'less' : 'more',
        },
      ),
    );
  }

  // --- Anomalie pe categorie vs. PROPRIA medie (nu praguri absolute)
  if (i.fullMonthsOfHistory >= 2) {
    String? worstCat;
    double worstExcess = 0;
    i.categorySpendThisMonth.forEach((cat, spend) {
      final avg = i.category3mMonthlyAvg[cat] ?? 0;
      if (avg > 0 && spend > avg * 1.5 && spend > avg + 30) {
        final excess = spend - avg;
        if (excess > worstExcess) {
          worstExcess = excess;
          worstCat = cat;
        }
      }
    });
    if (worstCat != null) {
      out.add(
        InsightCandidate(
          id: 'anomaly_$worstCat',
          ruleKey: 'category_anomaly',
          kind: InsightKind.corrective,
          score: 60,
          values: {
            'category': worstCat!,
            'now': _lei(i.categorySpendThisMonth[worstCat]!),
            'avg': _lei(i.category3mMonthlyAvg[worstCat]!),
          },
        ),
      );
    }

    // Simetric pozitiv: categorie mult sub media ei (după ziua 10).
    if (dayOfMonth >= 10) {
      String? bestCat;
      double bestSaving = 0;
      i.category3mMonthlyAvg.forEach((cat, avg) {
        final spend = i.categorySpendThisMonth[cat] ?? 0;
        if (avg > 30 && spend < avg * 0.6) {
          final saving = avg - spend;
          if (saving > bestSaving) {
            bestSaving = saving;
            bestCat = cat;
          }
        }
      });
      if (bestCat != null) {
        out.add(
          InsightCandidate(
            id: 'category_win_$bestCat',
            ruleKey: 'category_win',
            kind: InsightKind.positive,
            score: 62,
            values: {'category': bestCat!, 'saved': _lei(bestSaving)},
          ),
        );
      }
    }
  }

  // --- Praguri de obiectiv (25/50/75/100%)
  for (final g in i.goals) {
    if (g.target <= 0) continue;
    final pct = (g.saved / g.target * 100).floor();
    for (final threshold in const [100, 75, 50, 25]) {
      if (pct >= threshold) {
        out.add(
          InsightCandidate(
            id: 'goal_${g.id}_$threshold',
            ruleKey: threshold == 100 ? 'goal_done' : 'goal_milestone',
            kind: InsightKind.positive,
            score: threshold == 100 ? 90 : 78,
            values: {
              'goal': g.name,
              'emoji': g.emoji,
              'pct': '$threshold',
              'saved': _lei(g.saved),
              'target': _lei(g.target),
            },
          ),
        );
        break; // doar cel mai înalt prag atins; istoricul dedup-uie restul
      }
    }
  }

  // --- Recurente: „vine plata" + ponderea lunară
  for (final r in i.upcomingRecurring) {
    if (r.dueInDays >= 1 && r.dueInDays <= 3) {
      final remaining = i.budget - i.spentThisMonth - r.amount;
      out.add(
        InsightCandidate(
          id: 'recurring_due_${r.merchant}',
          ruleKey: 'recurring_due',
          kind: InsightKind.utility,
          score: 68,
          values: {
            'merchant': r.merchant,
            'amount': _lei(r.amount),
            'inDays': '${r.dueInDays}',
            'remaining': _lei(remaining.clamp(0, 999999)),
          },
        ),
      );
    }
  }
  if (i.monthlyRecurringTotal > 0 && i.budget > 0 && dayOfMonth >= 2) {
    final pct = (i.monthlyRecurringTotal / i.budget * 100).round();
    out.add(
      InsightCandidate(
        id: 'recurring_share_${i.now.year}_${i.now.month}',
        ruleKey: 'recurring_share',
        kind: InsightKind.utility,
        score: pct >= 25 ? 58 : 45,
        values: {'total': _lei(i.monthlyRecurringTotal), 'pct': '$pct'},
      ),
    );
  }

  // --- Fresh start (1 ale lunii): foaie curată, nu judecată retroactivă
  if (dayOfMonth <= 2 && i.lastMonthSpent > 0) {
    out.add(
      InsightCandidate(
        id: 'fresh_start_${i.now.year}_${i.now.month}',
        ruleKey: 'fresh_start',
        kind: InsightKind.utility,
        score: 80,
        values: {
          'spent': _lei(i.lastMonthSpent),
          'saved': _lei(i.lastMonthSaved),
        },
      ),
    );
  }

  // --- Milestone-uri absolute de economisire
  for (final threshold in const [1000, 500, 100]) {
    if (i.savedAllTime >= threshold) {
      out.add(
        InsightCandidate(
          id: 'saving_total_$threshold',
          ruleKey: 'saving_total',
          kind: InsightKind.positive,
          score: 72,
          values: {'threshold': '$threshold'},
        ),
      );
      break;
    }
  }

  // --- Cât mai poți cheltui: aritmetică la vedere
  // Poartă: buget setat, ≥5 tranzacții, minim 3 zile rămase (pacing-ul spune
  // deja tot pe final de lună). Ambient, scor modest, nu concurează evenimentele.
  if (i.budget > 0 && i.txCountThisMonth >= 5 && daysLeft >= 3) {
    final s = safeToSpend(
      budget: i.budget,
      spentSoFar: i.spentThisMonth,
      recurringDue: i.recurringDueSoon,
      goalContributions: i.goalContributionsThisMonth,
      daysLeft: daysLeft,
    );
    out.add(
      InsightCandidate(
        id: 'safe_to_spend',
        ruleKey: 'safe_to_spend',
        kind: InsightKind.utility,
        score: 50,
        values: {
          'safe': _lei(s.safe),
          'perDay': _lei(s.perDay),
          'daysLeft': '$daysLeft',
          // Pentru „cum am calculat": scăderea, termen cu termen.
          'budget': _lei(i.budget),
          'spent': _lei(i.spentThisMonth),
          'recurring': _lei(i.recurringDueSoon),
          'goals': _lei(i.goalContributionsThisMonth),
        },
      ),
    );
  }

  // --- Întrebarea de anomalie: mediană+MAD, formulare de ÎNTREBARE
  // Coexistă cu `category_anomaly` (aia compară totaluri lunare, asta o
  // singură cheltuială vs. istoric). Porți: cheltuială recentă (≤48h) și
  // ≥6 observații în istoric (garantat în isAnomaly).
  final last = i.latestExpense;
  if (last != null && i.now.difference(last.date).inHours <= 48) {
    final hist = i.categoryAmounts90d[last.category] ?? const <double>[];
    if (isAnomaly(amount: last.amount, history: hist)) {
      out.add(
        InsightCandidate(
          id: 'anomaly_q_${last.category}',
          ruleKey: 'category_anomaly_question',
          kind: InsightKind.corrective,
          score: 64,
          values: {
            'category': last.category,
            'amount': _lei(last.amount),
            'median': _lei(robustCenter(hist)),
          },
        ),
      );
    }
  }

  // --- Radarul de recurente: „posibil abonament", nu verdict
  // Doar tiparele care NU sunt deja declarate de utilizator; una singură pe
  // afișare (cea mai sigură, ghicirile sunt sortate după apariții).
  for (final g in i.recurringGuesses) {
    if (i.declaredRecurringCategories.contains(g.category)) continue;
    out.add(
      InsightCandidate(
        id: 'recurring_radar_${g.category}',
        ruleKey: 'recurring_radar',
        kind: InsightKind.utility,
        score: 56,
        values: {
          'category': g.category,
          'amount': _lei(g.medianAmount),
          'period': '${g.periodDays}',
        },
      ),
    );
    break;
  }

  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
}

/// Aplica disciplina de afișare peste candidați: cooldown-uri (id-urile din
/// [recentlyShown]), suprimarea tipurilor ignorate ([suppressedRules]) și
/// raportul 2:1, dacă ultimele două carduri afișate au fost corective,
/// următorul slot acceptă doar non-corective. Întoarce top [limit].
List<InsightCandidate> selectInsights(
  List<InsightCandidate> candidates, {
  required Set<String> recentlyShown,
  required Set<String> suppressedRules,
  required int recentCorrectiveStreak,
  int limit = 2,
}) {
  final picked = <InsightCandidate>[];
  var correctiveStreak = recentCorrectiveStreak;
  for (final c in candidates) {
    if (picked.length >= limit) break;
    if (recentlyShown.contains(c.id)) continue;
    if (suppressedRules.contains(c.ruleKey) && c.kind != InsightKind.positive) {
      continue;
    }
    if (c.kind == InsightKind.corrective && correctiveStreak >= 2) continue;
    // Max un corectiv pe afișare, restul slot-urilor rămân blânde.
    if (c.kind == InsightKind.corrective &&
        picked.any((p) => p.kind == InsightKind.corrective)) {
      continue;
    }
    picked.add(c);
    correctiveStreak = c.kind == InsightKind.corrective
        ? correctiveStreak + 1
        : 0;
  }
  return picked;
}
