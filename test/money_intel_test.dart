import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/insight_rules.dart';
import 'package:finedu_flutter/domain/engine/money_intel.dart';

/// Inputs minime pentru motorul de insights (modelul din insight_rules_test),
/// cu câmpurile expuse ca parametri.
InsightInputs _inputs({
  DateTime? now,
  double budget = 800,
  double spent = 0,
  int txCount = 10,
  ({String category, double amount, DateTime date})? latestExpense,
  Map<String, List<double>> cat90d = const {},
  double recurringDueSoon = 0,
  double goalContrib = 0,
  List<RecurringGuess> guesses = const [],
  Set<String> declared = const {},
}) => InsightInputs(
  now: now ?? DateTime(2026, 7, 15), // miercuri, ziua 15 din 31
  budget: budget,
  spentThisMonth: spent,
  txCountThisMonth: txCount,
  categorySpendThisMonth: const {},
  category3mMonthlyAvg: const {},
  fullMonthsOfHistory: 3,
  thisWeekSpent: 0,
  prevWeekSpent: 0,
  thisWeekTxCount: 5,
  prevWeekTxCount: 5,
  thisWeekTopCategory: 'mancare',
  goals: const [],
  upcomingRecurring: const [],
  monthlyRecurringTotal: 0,
  savedAllTime: 0,
  lastMonthSpent: 0,
  lastMonthSaved: 0,
  latestExpense: latestExpense,
  categoryAmounts90d: cat90d,
  recurringDueSoon: recurringDueSoon,
  goalContributionsThisMonth: goalContrib,
  recurringGuesses: guesses,
  declaredRecurringCategories: declared,
);

Iterable<String> _keys(List<InsightCandidate> list) =>
    list.map((c) => c.ruleKey);

void main() {
  group('robustCenter / robustSpread (mediană + MAD)', () {
    test('median: odd, even, empty', () {
      expect(robustCenter([3, 1, 2]), 2);
      expect(robustCenter([1, 2, 3, 4]), 2.5);
      expect(robustCenter([]), 0);
    });

    test('the median shrugs at outliers (the mean does not)', () {
      // Media ar fi 58,25, mediana rămâne lângă restul datelor.
      expect(robustCenter([10, 11, 12, 200]), 11.5);
    });

    test('spread: zero on constant data, scaled MAD otherwise', () {
      expect(robustSpread([20, 20, 20]), 0);
      // [15,18,20,22,25,17]: mediană 19, deviații sortate [1,1,2,3,4,6],
      // MAD 2,5 → scalat 2,5 × 1,4826.
      expect(
        robustSpread([15, 18, 20, 22, 25, 17]),
        closeTo(2.5 * 1.4826, 1e-9),
      );
    });
  });

  group('isAnomaly', () {
    const history = <double>[15, 18, 20, 22, 25, 17];

    test('fires on 200 vs ~20±5 history, silent on 26', () {
      expect(isAnomaly(amount: 200, history: history), isTrue);
      expect(isAnomaly(amount: 26, history: history), isFalse);
    });

    test('needs at least 6 samples, below that, silence', () {
      expect(isAnomaly(amount: 200, history: [15, 18, 20, 22, 25]), isFalse);
    });

    test('MAD=0 fallback: 2× median AND +30 lei absolute', () {
      const flat = <double>[20, 20, 20, 20, 20, 20];
      expect(isAnomaly(amount: 100, history: flat), isTrue);
      // 45 > 2×20 dar nu > 20+30 → pragul absolut taie zgomotul mic.
      expect(isAnomaly(amount: 45, history: flat), isFalse);
    });
  });

  group('safeToSpend (scădere pură)', () {
    test('budget − spent − recurring − goals, split per day', () {
      final s = safeToSpend(
        budget: 500,
        spentSoFar: 200,
        recurringDue: 50,
        goalContributions: 50,
        daysLeft: 10,
      );
      expect(s.safe, 200);
      expect(s.perDay, 20);
    });

    test('clamps at 0, a negative "free" helps nobody', () {
      final s = safeToSpend(
        budget: 300,
        spentSoFar: 400,
        recurringDue: 0,
        goalContributions: 0,
        daysLeft: 5,
      );
      expect(s.safe, 0);
      expect(s.perDay, 0);
    });

    test('daysLeft=0 guard: divides by 1, never by zero', () {
      final s = safeToSpend(
        budget: 100,
        spentSoFar: 0,
        recurringDue: 0,
        goalContributions: 0,
        daysLeft: 0,
      );
      expect(s.perDay, 100);
    });
  });

  group('detectRecurring', () {
    List<({String category, double amount, DateTime date})> series(
      String cat,
      List<DateTime> dates,
      List<double> amounts,
    ) {
      return [
        for (var i = 0; i < dates.length; i++)
          (category: cat, amount: amounts[i], date: dates[i]),
      ];
    }

    test('monthly Netflix-like series (30±2d, ±5% amount) is detected', () {
      final guesses = detectRecurring(
        series(
          'distractie',
          [
            DateTime(2026, 1, 5),
            DateTime(2026, 2, 4), // +30
            DateTime(2026, 3, 6), // +30
            DateTime(2026, 4, 7), // +32
          ],
          [40, 40, 41, 39],
        ),
      );
      expect(guesses, hasLength(1));
      final g = guesses.single;
      expect(g.category, 'distractie');
      expect(g.periodDays, 30);
      expect(g.medianAmount, 40);
      expect(g.confidence, 4);
    });

    test('weekly series comes out with periodDays ~7', () {
      final guesses = detectRecurring(
        series(
          'transport',
          [
            DateTime(2026, 6, 1),
            DateTime(2026, 6, 8), // +7
            DateTime(2026, 6, 15), // +7
            DateTime(2026, 6, 23), // +8
          ],
          [25, 25, 25, 25],
        ),
      );
      expect(guesses.single.periodDays, 7);
    });

    test('irregular gaps are NOT a rhythm', () {
      final guesses = detectRecurring(
        series(
          'mancare',
          [
            DateTime(2026, 6, 1),
            DateTime(2026, 6, 6), // +5
            DateTime(2026, 6, 26), // +20
            DateTime(2026, 7, 29), // +33
          ],
          [40, 40, 40, 40],
        ),
      );
      expect(guesses, isEmpty);
    });

    test('under 3 occurrences: no guess (a coincidence is not a pattern)', () {
      final guesses = detectRecurring(
        series(
          'distractie',
          [DateTime(2026, 6, 1), DateTime(2026, 7, 1)],
          [40, 40],
        ),
      );
      expect(guesses, isEmpty);
    });

    test('unstable amounts break the pattern (±10% band)', () {
      final guesses = detectRecurring(
        series(
          'distractie',
          [DateTime(2026, 4, 1), DateTime(2026, 5, 1), DateTime(2026, 6, 1)],
          [40, 60, 80],
        ),
      );
      expect(guesses, isEmpty);
    });
  });

  group('categorySuggestion (naive Bayes cu abținere)', () {
    const cats = ['mancare', 'transport', 'distractie'];

    List<({String category, double amount, int weekday})> foodHistory(int n) {
      return [
        for (var i = 0; i < n; i++)
          (
            category: 'mancare',
            amount: 10.0 + (i % 15), // mereu în bucket-ul 10-25
            weekday: 1 + (i % 5), // zile lucrătoare
          ),
      ];
    }

    test('suggests food for 15 lei on a Tuesday, with confidence', () {
      final idx = categorySuggestion(
        amount: 15,
        weekday: DateTime.tuesday,
        history: foodHistory(20),
        categories: cats,
      );
      expect(idx, cats.indexOf('mancare'));
    });

    test('abstains (-1) under 15 history entries, cold start is silence', () {
      final idx = categorySuggestion(
        amount: 15,
        weekday: DateTime.tuesday,
        history: foodHistory(14),
        categories: cats,
      );
      expect(idx, -1);
    });

    test('abstains on ambiguous input (two equally likely categories)', () {
      final history = [
        for (var i = 0; i < 8; i++)
          (category: 'mancare', amount: 15.0, weekday: DateTime.tuesday),
        for (var i = 0; i < 8; i++)
          (category: 'transport', amount: 15.0, weekday: DateTime.tuesday),
      ];
      final idx = categorySuggestion(
        amount: 15,
        weekday: DateTime.tuesday,
        history: history,
        categories: cats,
      );
      expect(idx, -1, reason: 'posterior ~50/50 e sub pragul de 0,55');
    });

    test('never throws on empty history or empty categories', () {
      expect(
        categorySuggestion(
          amount: 15,
          weekday: 2,
          history: const [],
          categories: cats,
        ),
        -1,
      );
      expect(
        categorySuggestion(
          amount: 15,
          weekday: 2,
          history: foodHistory(20),
          categories: const [],
        ),
        -1,
      );
    });
  });

  group('regulile motorului', () {
    test('safe_to_spend fires with the subtraction spelled out', () {
      final list = evaluateInsights(
        _inputs(spent: 300, recurringDueSoon: 50, goalContrib: 100),
      );
      final safe = list.singleWhere((c) => c.ruleKey == 'safe_to_spend');
      expect(safe.kind, InsightKind.utility);
      // 800 − 300 − 50 − 100 = 350; 17 zile rămase → ~21/zi.
      expect(safe.values['safe'], '350');
      expect(safe.values['perDay'], '21');
      expect(safe.values['daysLeft'], '17');
      expect(safe.values['budget'], '800');
    });

    test('safe_to_spend gates: budget, tx count, days left', () {
      expect(
        _keys(evaluateInsights(_inputs(budget: 0))),
        isNot(contains('safe_to_spend')),
      );
      expect(
        _keys(evaluateInsights(_inputs(txCount: 4))),
        isNot(contains('safe_to_spend')),
      );
      // 30 iulie: mai sunt doar 2 zile, pacing-ul spune deja tot.
      expect(
        _keys(evaluateInsights(_inputs(now: DateTime(2026, 7, 30)))),
        isNot(contains('safe_to_spend')),
      );
    });

    test('anomaly question fires on a fresh outlier expense', () {
      final list = evaluateInsights(
        _inputs(
          latestExpense: (
            category: 'mancare',
            amount: 200,
            date: DateTime(2026, 7, 14, 22),
          ),
          cat90d: const {
            'mancare': [15, 18, 20, 22, 25, 17],
          },
        ),
      );
      final q = list.singleWhere(
        (c) => c.ruleKey == 'category_anomaly_question',
      );
      expect(q.kind, InsightKind.corrective);
      expect(q.id, 'anomaly_q_mancare');
      expect(q.values['amount'], '200');
      expect(q.values['median'], '19');
    });

    test('anomaly question gates: enough history AND a recent expense', () {
      // Doar 5 observații în istoric → tăcere.
      expect(
        _keys(
          evaluateInsights(
            _inputs(
              latestExpense: (
                category: 'mancare',
                amount: 200,
                date: DateTime(2026, 7, 14, 22),
              ),
              cat90d: const {
                'mancare': [15, 18, 20, 22, 25],
              },
            ),
          ),
        ),
        isNot(contains('category_anomaly_question')),
      );
      // Cheltuială veche de 3 zile → o întrebare acum ar suna a proces.
      expect(
        _keys(
          evaluateInsights(
            _inputs(
              latestExpense: (
                category: 'mancare',
                amount: 200,
                date: DateTime(2026, 7, 12),
              ),
              cat90d: const {
                'mancare': [15, 18, 20, 22, 25, 17],
              },
            ),
          ),
        ),
        isNot(contains('category_anomaly_question')),
      );
    });

    test('recurring radar fires only on undeclared patterns', () {
      const guess = RecurringGuess(
        category: 'distractie',
        medianAmount: 40,
        periodDays: 30,
        confidence: 3,
      );
      final list = evaluateInsights(_inputs(guesses: const [guess]));
      final radar = list.singleWhere((c) => c.ruleKey == 'recurring_radar');
      expect(radar.kind, InsightKind.utility);
      expect(radar.values['category'], 'distractie');
      expect(radar.values['amount'], '40');
      expect(radar.values['period'], '30');

      // Deja declarat → radarul tace.
      expect(
        _keys(
          evaluateInsights(
            _inputs(guesses: const [guess], declared: {'distractie'}),
          ),
        ),
        isNot(contains('recurring_radar')),
      );
    });

    test('radar skips declared guesses and falls to the next one', () {
      const declared = RecurringGuess(
        category: 'distractie',
        medianAmount: 40,
        periodDays: 30,
        confidence: 5,
      );
      const fresh = RecurringGuess(
        category: 'transport',
        medianAmount: 25,
        periodDays: 7,
        confidence: 3,
      );
      final list = evaluateInsights(
        _inputs(guesses: const [declared, fresh], declared: {'distractie'}),
      );
      final radar = list.singleWhere((c) => c.ruleKey == 'recurring_radar');
      expect(radar.values['category'], 'transport');
    });
  });

  group('continut: intrarile din insights.json', () {
    // Valorile pe care motorul le emite per regulă, orice placeholder din
    // copy trebuie să fie printre ele, altfel cardul ar afișa `{x}` brut.
    const emittedValues = {
      'safe_to_spend': {
        'safe',
        'perDay',
        'daysLeft',
        'budget',
        'spent',
        'recurring',
        'goals',
      },
      'category_anomaly_question': {'category', 'amount', 'median'},
      'recurring_radar': {'category', 'amount', 'period'},
    };

    test(
      'entries exist, bilingual, on-tone, mojibake-free, placeholders ok',
      () {
        final root =
            jsonDecode(
                  File(
                    'content/insights.json',
                  ).readAsStringSync(encoding: utf8),
                )
                as Map<String, dynamic>;
        final rules = root['rules'] as Map<String, dynamic>;

        // Mojibake guard: UTF-8 dublu-encodat apare ca 'Ã'/'â€', inexistente
        // în româna sau engleza reală (convenția din arcade_data_test).
        final mojibake = RegExp('Ã|â€|Äƒ|È™');
        // Lint de ton: descrie datele, nu judeca persoana.
        const banned = ['prea mult', 'iar ai', 'trebuie'];
        final placeholder = RegExp(r'\{(\w+)\}');

        emittedValues.forEach((key, allowed) {
          final rule = rules[key] as Map<String, dynamic>?;
          expect(rule, isNotNull, reason: 'lipsește regula $key');
          expect(rule!['emoji'] as String, isNotEmpty, reason: key);

          final cta = rule['cta'] as Map<String, dynamic>;
          expect(cta['route'] as String, startsWith('/'), reason: key);

          final texts = <String>[];
          for (final locale in ['ro', 'en']) {
            final label = (cta['label'] as Map)[locale] as String?;
            final how = (rule['how'] as Map)[locale] as String?;
            expect(label, isNotEmpty, reason: '$key cta.$locale');
            expect(how, isNotEmpty, reason: '$key how.$locale');
            texts.addAll([label!, how!]);
          }

          final variants = (rule['variants'] as List)
              .cast<Map<String, dynamic>>();
          expect(variants.length, inInclusiveRange(2, 3), reason: key);

          final roTexts = <String>[(rule['how'] as Map)['ro'] as String];
          for (final v in variants) {
            for (final locale in ['ro', 'en']) {
              final title = (v['title'] as Map)[locale] as String;
              final body = (v['body'] as Map)[locale] as String;
              expect(title, isNotEmpty, reason: key);
              expect(body, isNotEmpty, reason: key);
              texts.addAll([title, body]);
              if (locale == 'ro') roTexts.addAll([title, body]);
            }
          }

          for (final s in texts) {
            expect(
              mojibake.hasMatch(s),
              isFalse,
              reason: '$key: UTF-8 dublu-encodat în „$s"',
            );
            for (final m in placeholder.allMatches(s)) {
              expect(
                allowed,
                contains(m.group(1)),
                reason: '$key: placeholder {${m.group(1)}} fără valoare',
              );
            }
          }
          for (final s in roTexts) {
            for (final b in banned) {
              expect(
                s.toLowerCase().contains(b),
                isFalse,
                reason: '$key: ton interzis („$b") în „$s"',
              );
            }
            // Corectivele nu ridică vocea: fără semne de exclamare.
            if (key == 'category_anomaly_question') {
              expect(
                s.contains('!'),
                isFalse,
                reason: '$key: corectivele nu au exclamări („$s")',
              );
            }
          }
        });
      },
    );
  });
}
