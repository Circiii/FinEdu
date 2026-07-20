import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/bandit.dart';
import '../../../domain/engine/insight_rules.dart';
import '../../../domain/engine/money_intel.dart';
import '../../../domain/models/transaction.dart' show TransactionType;
import '../../../domain/util/day_key.dart';
import '../../home/data/home_providers.dart';

/// Card rezolvat pentru feed-ul „Pentru tine": copy + CTA + explicație.
class InsightCard {
  const InsightCard({
    required this.id,
    required this.ruleKey,
    required this.kind,
    required this.emoji,
    required this.title,
    required this.body,
    required this.how,
    required this.ctaLabel,
    required this.ctaRoute,
    this.arm,
    this.propensity,
  });

  final String id;
  final String ruleKey;
  final InsightKind kind;
  final String emoji;
  final String title;
  final String body;
  final String? how;
  final String ctaLabel;
  final String ctaRoute;

  /// Brațul de bandit care a produs varianta (null când personalizarea e oprită).
  final int? arm;
  final double? propensity;
}

/// Context de personalizare: observații istorice per regulă + ziua curentă (seed stabil).
class BanditContext {
  const BanditContext({required this.observations, required this.dayKey});
  final Map<String, List<ArmObservation>> observations;
  final String dayKey;
}

/// Cooldown per tip de regulă (zile); milestone-urile o singură dată per id.
const _cooldownDays = {
  'pace_over': 1,
  'pace_under': 1,
  'weekly_recap': 6,
  'category_anomaly': 7,
  'category_win': 7,
  'goal_milestone': 3650,
  'goal_done': 3650,
  'saving_total': 3650,
  'recurring_due': 3,
  'recurring_share': 25,
  'fresh_start': 25,
  // safe-to-spend e ambient (revine repede); anomalia și radarul sunt rare prin design.
  'safe_to_spend': 2,
  'category_anomaly_question': 5,
  'recurring_radar': 14,
};

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(appDbProvider));
});

/// Cardurile „Pentru tine" de azi (max 2), reactive la tranzacțiile lunii.
final insightCardsProvider = FutureProvider.family<List<InsightCard>, String>((
  ref,
  locale,
) async {
  // Reactivitate: orice mișcare în luna curentă re-derivă selecția.
  ref.watch(monthTransactionsProvider);
  final profile = ref.watch(localProfileStreamProvider).valueOrNull;
  final repo = ref.watch(insightsRepositoryProvider);

  final inputs = await repo.buildInputs(
    budget: (profile?.monthlyBudget ?? 0).toDouble(),
  );
  final candidates = evaluateInsights(inputs);
  final history = await repo.history();
  final picked = selectInsights(
    candidates,
    recentlyShown: history.recentlyShown,
    suppressedRules: history.suppressedRules,
    recentCorrectiveStreak: history.correctiveStreak,
  );

  // Opt-in explicit: oprită → selecția rămâne pe seed-ul zilei; pornită →
  // banditul alege din istoricul pe device al utilizatorului.
  BanditContext? bandit;
  if (profile?.personalizationOn ?? false) {
    bandit = BanditContext(
      observations: await repo.banditObservations(),
      dayKey: dayKey(inputs.now),
    );
  }

  final copy = await repo.copy(locale);
  final cards = <InsightCard>[];
  for (final c in picked) {
    final resolved = repo.resolve(c, copy, inputs.now, locale, bandit: bandit);
    if (resolved != null) cards.add(resolved);
  }

  // Cold start / zi liniștită: card educațional, fără statistici premature.
  if (cards.isEmpty) {
    cards.add(repo.educationCard(copy, inputs.now, locale, bandit: bandit));
  }

  await repo.recordShown(cards);
  return cards;
});

class InsightHistory {
  const InsightHistory({
    required this.recentlyShown,
    required this.suppressedRules,
    required this.correctiveStreak,
  });
  final Set<String> recentlyShown;
  final Set<String> suppressedRules;
  final int correctiveStreak;
}

class InsightsRepository {
  InsightsRepository(this._db);

  final AppDb _db;
  Map<String, dynamic>? _copyCache;

  // ---- agregatele pentru motor

  Future<InsightInputs> buildInputs({required double budget}) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final threeMonthsStart = DateTime(now.year, now.month - 3, 1);
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final all =
        await (_db.select(_db.localTransactions)..where(
              (t) =>
                  t.deleted.equals(false) &
                  t.transactionDate.isBiggerOrEqualValue(threeMonthsStart),
            ))
            .get();

    bool isExpense(LocalTransaction t) => t.type == TransactionType.expense.key;
    bool isSaving(LocalTransaction t) => t.type == TransactionType.saving.key;

    final monthTx = all
        .where((t) => !t.transactionDate.isBefore(monthStart))
        .toList();
    final monthExpenses = monthTx.where(isExpense).toList();

    final categoryMonth = <String, double>{};
    for (final t in monthExpenses) {
      categoryMonth[t.category] = (categoryMonth[t.category] ?? 0) + t.amount;
    }

    // Ultimele 3 luni calendaristice PLINE: medii per categorie.
    final prevWindow = all.where(
      (t) =>
          t.transactionDate.isBefore(monthStart) &&
          !t.transactionDate.isBefore(threeMonthsStart) &&
          isExpense(t),
    );
    final monthsSeen = <String>{};
    final categoryPrevTotals = <String, double>{};
    for (final t in prevWindow) {
      monthsSeen.add('${t.transactionDate.year}-${t.transactionDate.month}');
      categoryPrevTotals[t.category] =
          (categoryPrevTotals[t.category] ?? 0) + t.amount;
    }
    final fullMonths = monthsSeen.length;
    final categoryAvg = {
      for (final e in categoryPrevTotals.entries)
        e.key: e.value / (fullMonths == 0 ? 1 : fullMonths),
    };

    // Săptămâni rulante (recapul de luni: 7 zile vs cele 7 dinainte).
    final thisWeek = all.where(
      (t) => isExpense(t) && t.transactionDate.isAfter(oneWeekAgo),
    );
    final prevWeek = all.where(
      (t) =>
          isExpense(t) &&
          t.transactionDate.isAfter(twoWeeksAgo) &&
          !t.transactionDate.isAfter(oneWeekAgo),
    );
    final weekCats = <String, double>{};
    for (final t in thisWeek) {
      weekCats[t.category] = (weekCats[t.category] ?? 0) + t.amount;
    }
    String? topCat;
    double topVal = 0;
    weekCats.forEach((k, v) {
      if (v > topVal) {
        topVal = v;
        topCat = k;
      }
    });

    // Obiective + progresul lor (economii legate de goalId).
    final goals = await _db.select(_db.localGoals).get();
    final savingsByGoal = <String, double>{};
    final allSavings =
        await (_db.select(_db.localTransactions)..where(
              (t) =>
                  t.deleted.equals(false) &
                  t.type.equals(TransactionType.saving.key),
            ))
            .get();
    var savedAllTime = 0.0;
    for (final t in allSavings) {
      savedAllTime += t.amount;
      if (t.goalId != null) {
        savingsByGoal[t.goalId!] = (savingsByGoal[t.goalId!] ?? 0) + t.amount;
      }
    }

    // Recurente active: scadențe apropiate + totalul lunar normalizat.
    final recurring = await (_db.select(
      _db.localRecurring,
    )..where((r) => r.active.equals(true))).get();
    final upcoming = <RecurringLite>[];
    var recurringMonthly = 0.0;
    for (final r in recurring) {
      final due = DateTime.tryParse(r.nextDueDate);
      if (due != null) {
        final days = due
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        upcoming.add(
          RecurringLite(
            merchant: r.merchant,
            amount: r.amount,
            dueInDays: days,
          ),
        );
      }
      recurringMonthly += switch (r.frequency) {
        'daily' => r.amount * 30,
        'weekly' => r.amount * 4,
        _ => r.amount,
      };
    }

    // Luna trecută (fresh start).
    final lastMonthTx = all.where(
      (t) =>
          !t.transactionDate.isBefore(prevMonthStart) &&
          t.transactionDate.isBefore(monthStart),
    );
    final lastSpent = lastMonthTx
        .where(isExpense)
        .fold(0.0, (a, t) => a + t.amount);
    final lastSaved = lastMonthTx
        .where(isSaving)
        .fold(0.0, (a, t) => a + t.amount);

    // Fereastra de ~90 zile vine din query-ul pe 3 luni calendaristice pline
    // (minim 89 de zile), fără query nou.
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final window90 =
        all
            .where(
              (t) => isExpense(t) && !t.transactionDate.isBefore(ninetyDaysAgo),
            )
            .toList()
          ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    // Ultima cheltuială vs. istoricul categoriei ei, fără ea însăși (nu-și
    // poate trage singură mediana spre sine).
    final latest = window90.isEmpty ? null : window90.last;
    final catAmounts90d = <String, List<double>>{};
    for (final t in window90) {
      if (identical(t, latest)) continue;
      (catAmounts90d[t.category] ??= <double>[]).add(t.amount);
    }

    // Categoria e proxy pentru comerciant, fluxul manual nu populează `merchant`.
    final recurringGuesses = detectRecurring([
      for (final t in window90)
        (category: t.category, amount: t.amount, date: t.transactionDate),
    ]);
    final declaredCategories = {for (final r in recurring) r.category};

    // Safe-to-spend scade recurentele scadente până la finalul lunii și banii
    // deja puși deoparte (nu mai sunt liberi, cu sau fără obiectiv).
    final daysLeftInMonth =
        DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final recurringDueSoon = upcoming
        .where((r) => r.dueInDays >= 0 && r.dueInDays < daysLeftInMonth)
        .fold(0.0, (a, r) => a + r.amount);
    final savedThisMonth = monthTx
        .where(isSaving)
        .fold(0.0, (a, t) => a + t.amount);

    return InsightInputs(
      now: now,
      budget: budget,
      spentThisMonth: monthExpenses.fold(0.0, (a, t) => a + t.amount),
      txCountThisMonth: monthTx.length,
      categorySpendThisMonth: categoryMonth,
      category3mMonthlyAvg: categoryAvg,
      fullMonthsOfHistory: fullMonths,
      thisWeekSpent: thisWeek.fold(0.0, (a, t) => a + t.amount),
      prevWeekSpent: prevWeek.fold(0.0, (a, t) => a + t.amount),
      thisWeekTxCount: thisWeek.length,
      prevWeekTxCount: prevWeek.length,
      thisWeekTopCategory: topCat == null ? null : _categoryLabel(topCat!),
      goals: [
        for (final g in goals)
          GoalLite(
            id: g.id,
            name: g.name,
            emoji: g.emoji,
            target: g.targetAmount,
            saved: savingsByGoal[g.id] ?? 0,
          ),
      ],
      upcomingRecurring: upcoming,
      monthlyRecurringTotal: recurringMonthly,
      savedAllTime: savedAllTime,
      lastMonthSpent: lastSpent,
      lastMonthSaved: lastSaved,
      latestExpense: latest == null
          ? null
          : (
              category: latest.category,
              amount: latest.amount,
              date: latest.transactionDate,
            ),
      categoryAmounts90d: catAmounts90d,
      recurringDueSoon: recurringDueSoon,
      goalContributionsThisMonth: savedThisMonth,
      recurringGuesses: recurringGuesses,
      declaredRecurringCategories: declaredCategories,
    );
  }

  // ---- istoric: cooldown, suprimare, raportul 2:1

  Future<InsightHistory> history() async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final events =
        await (_db.select(_db.insightEvents)
              ..where((e) => e.createdAt.isBiggerOrEqualValue(since))
              ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
            .get();

    final now = DateTime.now();
    final recentlyShown = <String>{};
    for (final e in events) {
      if (e.event == 'shown' || e.event == 'dismissed') {
        final window = _cooldownDays[e.ruleKey] ?? 7;
        final age = now.difference(e.createdAt).inDays;
        // Cooldown-ul pentru `shown` începe de mâine, altfel cardul de azi
        // s-ar auto-răci la fiecare re-rulare a provider-ului.
        final suppressed = e.event == 'dismissed'
            ? age < window
            : age >= 1 && age < window;
        if (suppressed) recentlyShown.add(e.insightId);
      }
    }

    // Suprimare: 3+ dismiss-uri pe tip, zero tap-uri, în 30 de zile.
    final dismissed = <String, int>{};
    final tapped = <String>{};
    for (final e in events) {
      if (e.event == 'dismissed') {
        dismissed[e.ruleKey] = (dismissed[e.ruleKey] ?? 0) + 1;
      }
      if (e.event == 'tapped') tapped.add(e.ruleKey);
    }
    final suppressed = {
      for (final e in dismissed.entries)
        if (e.value >= 3 && !tapped.contains(e.key)) e.key,
    };

    // Streak-ul de corective din cele mai recente afișări (id-uri distincte).
    var streak = 0;
    final seen = <String>{};
    for (final e in events.where((e) => e.event == 'shown')) {
      if (!seen.add(e.insightId)) continue;
      if (e.kind == 'corrective') {
        streak++;
        if (streak >= 2) break;
      } else {
        break;
      }
    }

    return InsightHistory(
      recentlyShown: recentlyShown,
      suppressedRules: suppressed,
      correctiveStreak: streak,
    );
  }

  Future<void> recordShown(List<InsightCard> cards) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    for (final card in cards) {
      final existing =
          await (_db.select(_db.insightEvents)
                ..where(
                  (e) =>
                      e.insightId.equals(card.id) &
                      e.event.equals('shown') &
                      e.createdAt.isBiggerOrEqualValue(dayStart),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing == null) {
        await _db
            .into(_db.insightEvents)
            .insert(
              InsightEventsCompanion.insert(
                insightId: card.id,
                ruleKey: card.ruleKey,
                kind: card.kind.name,
                event: 'shown',
                createdAt: DateTime.now(),
                // Null când personalizarea e oprită; altfel logăm pentru evaluare off-policy.
                arm: Value(card.arm),
                propensity: Value(card.propensity),
              ),
            );
      }
    }
  }

  /// Observațiile de bandit din ultimele 90 de zile (success = tap în 48h).
  /// Doar afișările cu `arm != null` contează, ca să nu biasăm cu date vechi.
  Future<Map<String, List<ArmObservation>>> banditObservations() async {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 90));
    final events = await (_db.select(
      _db.insightEvents,
    )..where((e) => e.createdAt.isBiggerOrEqualValue(since))).get();

    // Index-ul tap-urilor per insightId pentru verificarea ferestrei de 48h.
    final tapsById = <String, List<DateTime>>{};
    for (final e in events) {
      if (e.event == 'tapped') {
        (tapsById[e.insightId] ??= <DateTime>[]).add(e.createdAt);
      }
    }

    final byRule = <String, List<ArmObservation>>{};
    for (final e in events) {
      if (e.event != 'shown' || e.arm == null) continue;
      final success = (tapsById[e.insightId] ?? const <DateTime>[]).any(
        (t) => t.difference(e.createdAt).inMinutes.abs() <= 48 * 60,
      );
      (byRule[e.ruleKey] ??= <ArmObservation>[]).add(
        ArmObservation(
          arm: e.arm!,
          success: success,
          ageDays: now.difference(e.createdAt).inMinutes / (60 * 24),
        ),
      );
    }
    return byRule;
  }

  Future<void> record(InsightCard card, String event) {
    return _db
        .into(_db.insightEvents)
        .insert(
          InsightEventsCompanion.insert(
            insightId: card.id,
            ruleKey: card.ruleKey,
            kind: card.kind.name,
            event: event,
            createdAt: DateTime.now(),
          ),
        );
  }

  // ---- textele

  Future<Map<String, dynamic>> copy(String locale) async {
    _copyCache ??=
        jsonDecode(await loadAssetString('content/insights.json'))
            as Map<String, dynamic>;
    return _copyCache!;
  }

  String _t(Map<String, dynamic> node, String locale) =>
      (node[locale] ?? node['ro']) as String;

  String _fill(String template, Map<String, String> values) {
    var out = template;
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  /// Etichete de afișare pentru categoriile stocate ca id-uri.
  String _categoryLabel(String key) => switch (key) {
    'mancare' => 'Mâncare',
    'distractie' => 'Distracție',
    'transport' => 'Transport',
    'haine' => 'Haine',
    'scoala' => 'Școală',
    'gaming' => 'Gaming',
    'abonamente' => 'Abonamente',
    _ => key.isEmpty ? key : key[0].toUpperCase() + key.substring(1),
  };

  /// Alege indexul variantei. Oprită → [legacyIndex] (seed pe zi, neschimbat).
  /// Pornită → banditul, cu Random seed-uit pe (zi|regulă) ca să nu clipească.
  ({int index, int? arm, double? propensity}) _pickVariant(
    String ruleKey,
    int count,
    int legacyIndex,
    BanditContext? bandit,
  ) {
    if (bandit == null) {
      return (index: legacyIndex, arm: null, propensity: null);
    }
    final counters = deriveCounters(
      bandit.observations[ruleKey] ?? const <ArmObservation>[],
    );
    final rng = Random(('${bandit.dayKey}|$ruleKey').hashCode);
    final pick = pickArm(counters: counters, armCount: count, rng: rng);
    return (index: pick.arm, arm: pick.arm, propensity: pick.propensity);
  }

  InsightCard? resolve(
    InsightCandidate c,
    Map<String, dynamic> copy,
    DateTime now,
    String locale, {
    BanditContext? bandit,
  }) {
    final rule =
        (copy['rules'] as Map<String, dynamic>)[c.ruleKey]
            as Map<String, dynamic>?;
    if (rule == null) return null;
    final variants = (rule['variants'] as List).cast<Map<String, dynamic>>();
    final pick = _pickVariant(
      c.ruleKey,
      variants.length,
      (now.day + c.ruleKey.length) % variants.length,
      bandit,
    );
    final variant = variants[pick.index];
    final values = {
      ...c.values,
      if (c.values.containsKey('category'))
        'category': _categoryLabel(c.values['category']!),
      if (c.values.containsKey('direction'))
        'direction': switch ((c.values['direction'], locale)) {
          ('less', 'en') => 'less',
          ('more', 'en') => 'more',
          ('less', _) => 'mai puțin',
          _ => 'mai mult',
        },
    };
    final cta = rule['cta'] as Map<String, dynamic>;
    return InsightCard(
      id: c.id,
      ruleKey: c.ruleKey,
      kind: c.kind,
      emoji: rule['emoji'] as String,
      title: _fill(
        _t(variant['title'] as Map<String, dynamic>, locale),
        values,
      ),
      body: _fill(_t(variant['body'] as Map<String, dynamic>, locale), values),
      how: _fill(_t(rule['how'] as Map<String, dynamic>, locale), values),
      ctaLabel: _t(cta['label'] as Map<String, dynamic>, locale),
      ctaRoute: cta['route'] as String,
      arm: pick.arm,
      propensity: pick.propensity,
    );
  }

  InsightCard educationCard(
    Map<String, dynamic> copy,
    DateTime now,
    String locale, {
    BanditContext? bandit,
  }) {
    final pool = (copy['education'] as List).cast<Map<String, dynamic>>();
    final pick = _pickVariant(
      'education',
      pool.length,
      now.difference(DateTime(2026)).inDays % pool.length,
      bandit,
    );
    final e = pool[pick.index];
    return InsightCard(
      id: 'education',
      ruleKey: 'education',
      kind: InsightKind.utility,
      emoji: e['emoji'] as String,
      title: _t(e['title'] as Map<String, dynamic>, locale),
      body: _t(e['body'] as Map<String, dynamic>, locale),
      how: null,
      ctaLabel: locale == 'en' ? 'Open' : 'Deschide',
      ctaRoute: e['route'] as String,
      arm: pick.arm,
      propensity: pick.propensity,
    );
  }
}
