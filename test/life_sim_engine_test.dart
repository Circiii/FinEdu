import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/life_sim/money.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_rng.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_state.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_conditions.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_effects.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_content.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_director.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_engine.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_scoring.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_debrief.dart';

// ---------------------------------------------------------------------------
// Fixture de conținut INLINE (nu pachetul real). 10 evenimente incl. un
// lanț (parbriz → parbriz_extins), 3 recurente, 1 rol, 1 obiectiv, 2 finaluri.
// ---------------------------------------------------------------------------

Map<String, dynamic> _bi(String s) => {'ro': s, 'en': s};

Map<String, String> _fixture() {
  final manifest = {'contentVersion': '1.0.0-test'};

  final roles = {
    'version': '1.0.0-test',
    'roles': [
      {
        'id': 'test_rol',
        'emoji': '🧪',
        'name': _bi('Rol de test'),
        'bio': _bi('Bio de test'),
        'age': 20,
        'salary': {
          'net_min': 2500,
          'net_max': 3500,
          'scenario_net': 3000, // lei
          'source_label': 'fixture',
          'source_date': '2026-07',
          'needs_expert_review': true,
        },
        'pay_day': 1,
        'salary_variability': 0.10,
        'city_profile': 'oras_mare',
        'housing': 'chirie',
        'transport': 'masina_veche',
        'initial_cash': 100000, // bani = 1000 lei
        'initial_fund': 50000, // 500 lei
        'debts': [
          {'id': 'rata_telefon', 'principal': 60000, 'monthly': 15000, 'due_day': 20},
        ],
        'bills': ['chirie', 'utilitati', 'abonament'],
        'benefits': [
          {'kind': 'flag', 'id': 'are_masina'},
        ],
        'risks': _bi('venit variabil'),
        'goal_default': 'goal_studio',
      },
    ],
  };

  final recurring = {
    'recurring': [
      {
        'id': 'chirie',
        'kind': 'bill',
        'name': _bi('Chirie'),
        'amount': 90000, // 900 lei
        'due_day': 5,
        'flexible': false,
        'category': 'housing',
        'miss_effects': [
          {'type': 'cash', 'delta': -10000},
          {'type': 'stat', 'stat': 'stress', 'delta': 5},
        ],
      },
      {
        'id': 'utilitati',
        'kind': 'bill',
        'name': _bi('Utilități'),
        'amount': 20000, // 200 lei
        'due_day': 10,
        'flexible': false,
        'category': 'utilities',
        'miss_effects': [
          {'type': 'cash', 'delta': -3000},
          {'type': 'stat', 'stat': 'stress', 'delta': 3},
        ],
      },
      {
        'id': 'abonament',
        'kind': 'subscription',
        'name': _bi('Abonament telefon'),
        'amount': 5000, // 50 lei
        'due_day': 15,
        'flexible': true,
        'category': 'subscriptions',
        'miss_effects': [
          {'type': 'stat', 'stat': 'stress', 'delta': 2},
        ],
      },
    ],
  };

  final goals = {
    'goals': [
      {'id': 'goal_studio', 'name': _bi('Garsonieră'), 'target_bani': 200000, 'why': _bi('...')},
    ],
  };

  final endings = {
    'endings': [
      {
        'id': 'strategul',
        'title': _bi('Strategul'),
        'description': _bi('Ai ținut cârma strâns.'),
        'thresholds': {'control': 60, 'rezilienta': 60},
      },
      {
        'id': 'navigatorul',
        'title': _bi('Navigatorul de furtună'),
        'description': _bi('Ai trecut prin valuri.'),
      },
    ],
  };

  final events = {
    'events': [
      {
        'id': 'cafea',
        'category': 'daily_living',
        'weight': 10,
        'cooldown_days': 2,
        'min_day': 1,
        'max_day': 30,
        'difficulty': 1,
        'skill_tags': ['budgeting'],
        'title': _bi('Cafeaua de dimineață'),
        'choices': [
          {'label': _bi('Cumperi (-15 lei)'), 'effects': [{'type': 'cash', 'delta': -1500}], 'debrief': _bi('...')},
          {'label': _bi('Faci acasă'), 'effects': [], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'parbriz',
        'category': 'transport',
        'weight': 8,
        'cooldown_days': 30,
        'min_day': 2,
        'max_day': 25,
        'role_tags': ['are_masina'],
        'difficulty': 2,
        'chain_id': 'parbriz',
        'skill_tags': ['emergency_fund', 'opportunity_cost'],
        'conditions': [
          {'type': 'hasFlag', 'flag': 'are_masina'},
        ],
        'title': _bi('Parbrizul a pocnit'),
        'choices': [
          {'label': _bi('Repari acum (-850 lei)'), 'effects': [{'type': 'cash', 'delta': -85000}], 'debrief': _bi('...')},
          {
            'label': _bi('Amâni reparația'),
            'effects': [
              {'type': 'setFlag', 'flag': 'parbriz_amanat'},
              {'type': 'scheduleEvent', 'delay_days': 5, 'event_id': 'parbriz_extins'},
            ],
            'debrief': _bi('...'),
          },
        ],
      },
      {
        'id': 'parbriz_extins',
        'category': 'transport',
        'weight': 5,
        'min_day': 1,
        'max_day': 30,
        'difficulty': 3,
        'chain_id': 'parbriz',
        'skill_tags': ['opportunity_cost'],
        'title': _bi('Fisura s-a extins'),
        'choices': [
          {'label': _bi('Repari complet (-1.100 lei)'), 'effects': [{'type': 'cash', 'delta': -110000}], 'debrief': _bi('...')},
          {
            'label': _bi('Mergi la risc'),
            'effects': [
              {
                'type': 'scheduleEffect',
                'delay_days': 3,
                'effects': [
                  {'type': 'cash', 'delta': -40000},
                  {'type': 'stat', 'stat': 'stress', 'delta': 8},
                ],
                'note': _bi('Amenda a venit prin poștă'),
              },
            ],
            'debrief': _bi('...'),
          },
        ],
      },
      {
        'id': 'bonus',
        'category': 'work',
        'weight': 6,
        'min_day': 3,
        'max_day': 25,
        'difficulty': 1,
        'skill_tags': ['saving'],
        'title': _bi('Bonus surpriză'),
        'choices': [
          {'label': _bi('Accepți (+500 lei)'), 'effects': [{'type': 'cash', 'delta': 50000}, {'type': 'jobStability', 'delta': 5}], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'raceala',
        'category': 'health',
        'weight': 7,
        'min_day': 2,
        'max_day': 28,
        'difficulty': 2,
        'skill_tags': ['emergency_fund'],
        'title': _bi('Ai răcit'),
        'choices': [
          {'label': _bi('Te odihnești'), 'effects': [{'type': 'stat', 'stat': 'energy', 'delta': 10}, {'type': 'stat', 'stat': 'health', 'delta': 5}], 'debrief': _bi('...')},
          {
            'label': _bi('Împingi înainte'),
            'effects': [
              {'type': 'stat', 'stat': 'stress', 'delta': 5},
              {
                'type': 'scheduleEffect',
                'delay_days': 2,
                'effects': [
                  {'type': 'cash', 'delta': -20000},
                  {'type': 'stat', 'stat': 'health', 'delta': -10},
                ],
                'note': _bi('Ai făcut febră, ai lipsit de la muncă'),
              },
            ],
            'debrief': _bi('...'),
          },
        ],
      },
      {
        'id': 'iesire',
        'category': 'friends',
        'weight': 6,
        'min_day': 1,
        'max_day': 30,
        'difficulty': 1,
        'skill_tags': ['needs_wants'],
        'title': _bi('Ieșire cu prietenii'),
        'choices': [
          {'label': _bi('Ieși (-80 lei)'), 'effects': [{'type': 'cash', 'delta': -8000}, {'type': 'setFlag', 'flag': 'social'}, {'type': 'stat', 'stat': 'relationships', 'delta': 5}], 'debrief': _bi('...')},
          {'label': _bi('Rămâi acasă'), 'effects': [{'type': 'stat', 'stat': 'relationships', 'delta': -2}], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'ajutor',
        'category': 'family',
        'weight': 5,
        'min_day': 5,
        'max_day': 30,
        'difficulty': 2,
        'skill_tags': ['budgeting'],
        'title': _bi('Familia cere ajutor'),
        'choices': [
          {'label': _bi('Ajuți (-300 lei)'), 'effects': [{'type': 'cash', 'delta': -30000}, {'type': 'stat', 'stat': 'relationships', 'delta': 8}], 'debrief': _bi('...')},
          {'label': _bi('Refuzi'), 'effects': [{'type': 'stat', 'stat': 'relationships', 'delta': -5}], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'oferta',
        'category': 'saving',
        'weight': 4,
        'min_day': 3,
        'max_day': 28,
        'difficulty': 1,
        'skill_tags': ['saving'],
        'title': _bi('Oferta de economisire'),
        'choices': [
          {'label': _bi('Pui deoparte (+300 lei)'), 'effects': [{'type': 'goal', 'delta': 30000}], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'phishing',
        'category': 'scams',
        'weight': 4,
        'min_day': 4,
        'max_day': 30,
        'difficulty': 2,
        'skill_tags': ['scams'],
        'title': _bi('Mesaj suspect'),
        'choices': [
          {'label': _bi('Ignori și raportezi'), 'effects': [{'type': 'jobStability', 'delta': 0}], 'debrief': _bi('...')},
          {'label': _bi('Dai datele'), 'effects': [{'type': 'cash', 'delta': -50000}, {'type': 'stat', 'stat': 'stress', 'delta': 10}], 'debrief': _bi('...')},
        ],
      },
      {
        'id': 'windfall',
        'category': 'windfall',
        'rarity': 'rare',
        'weight': 2,
        'min_day': 8,
        'max_day': 30,
        'difficulty': 1,
        'skill_tags': ['saving'],
        'title': _bi('Bani neașteptați'),
        'choices': [
          {'label': _bi('Primești (+400 lei)'), 'effects': [{'type': 'cash', 'delta': 40000}], 'debrief': _bi('...')},
        ],
      },
    ],
  };

  return {
    'content/life_sim/manifest.json': jsonEncode(manifest),
    'content/life_sim/roles.json': jsonEncode(roles),
    'content/life_sim/recurring.json': jsonEncode(recurring),
    'content/life_sim/goals.json': jsonEncode(goals),
    'content/life_sim/endings.json': jsonEncode(endings),
    'content/life_sim/events/pack.json': jsonEncode(events),
  };
}

LifeSimContent _content() => LifeSimContent.fromJsonBundle(_fixture());

/// Rulează o lună întreagă cu o politică de alegere, întorcând (secvența de
/// id-uri de eveniment pe zi, starea finală). null = zi liniștită.
({List<String?> seq, LifeSimState state}) _runMonth(
  LifeSimContent c, {
  required int seed,
  required String mode,
  required int Function(LifeSimEvent) policy,
  int days = 30,
}) {
  var st = createRun(c: c, roleId: 'test_rol', goalId: 'goal_studio', mode: mode, seed: seed);
  final seq = <String?>[];
  for (var i = 0; i < days; i++) {
    final r = advanceDay(st, c);
    st = r.state;
    seq.add(r.event?.id);
    final e = r.event;
    if (e != null) st = applyChoice(st, e, policy(e), c);
  }
  return (seq: seq, state: st);
}

void main() {
  final content = _content();

  // Stare de bază pentru testele de condiții/efecte (ziua 1, valorile rolului).
  LifeSimState base() =>
      createRun(c: content, roleId: 'test_rol', goalId: 'goal_studio', mode: 'realist', seed: 1);

  group('Content parsing', () {
    test('pachetul parsează; lookup-urile funcționează', () {
      expect(content.version, '1.0.0-test');
      expect(content.roles, hasLength(1));
      expect(content.recurring, hasLength(3));
      expect(content.events, hasLength(10));
      expect(content.goals, hasLength(1));
      expect(content.endings, hasLength(2));
      expect(content.roleById('test_rol')!.scenarioNet, Money.fromLei(3000));
      expect(content.recurringById('chirie')!.amount, const Money(90000));
      expect(content.eventById('parbriz')!.chainId, 'parbriz');
      expect(content.goalById('goal_studio')!.target, const Money(200000));
    });

    test('flag-urile de beneficiu și datoriile inițiale se parsează', () {
      final role = content.roleById('test_rol')!;
      expect(role.benefitFlags, contains('are_masina'));
      expect(role.debts.single.id, 'rata_telefon');
      expect(role.debts.single.principal, const Money(60000));
    });

    test('tip necunoscut de condiție/efect → FormatException', () {
      expect(() => LifeCondition.fromJson({'type': 'inexistent'}),
          throwsA(isA<FormatException>()));
      expect(() => LifeEffect.fromJson({'type': 'inexistent'}),
          throwsA(isA<FormatException>()));
    });
  });

  group('Condiții, adevărat/fals la margini', () {
    test('StatAbove/StatBelow sunt stricte', () {
      final s = base(); // stress 25, energy 75
      expect(const StatAbove('stress', 25).eval(s), isFalse);
      expect(const StatAbove('stress', 24).eval(s), isTrue);
      expect(const StatBelow('stress', 25).eval(s), isFalse);
      expect(const StatBelow('stress', 26).eval(s), isTrue);
    });

    test('Cash/Fund above/below', () {
      final s = base(); // cash 1000 lei, fund 500 lei
      expect(CashAbove(const Money(99999)).eval(s), isTrue);
      expect(CashBelow(const Money(100001)).eval(s), isTrue);
      expect(FundAbove(const Money(50000)).eval(s), isFalse);
      expect(FundBelow(const Money(50001)).eval(s), isTrue);
    });

    test('DebtAbove pe datoria totală', () {
      final s = base(); // datorie 600 lei
      expect(DebtAbove(const Money(59999)).eval(s), isTrue);
      expect(DebtAbove(const Money(60000)).eval(s), isFalse);
    });

    test('DayRange inclusiv la ambele capete', () {
      final s = base().copyWith(day: 5);
      expect(const DayRange(5, 10).eval(s), isTrue);
      expect(const DayRange(6, 10).eval(s), isFalse);
      expect(const DayRange(1, 5).eval(s), isTrue);
    });

    test('HasFlag/NotFlag', () {
      final s = base(); // flag are_masina din beneficii
      expect(const HasFlag('are_masina').eval(s), isTrue);
      expect(const NotFlag('are_masina').eval(s), isFalse);
      expect(const HasFlag('inexistent').eval(s), isFalse);
    });

    test('RoleIs, CompletedEvent, MadeChoice, HasRecurring', () {
      var s = base();
      expect(const RoleIs(['test_rol', 'altul']).eval(s), isTrue);
      expect(const RoleIs(['altul']).eval(s), isFalse);
      expect(const HasRecurring('chirie').eval(s), isTrue);
      expect(const HasRecurring('inexistent').eval(s), isFalse);
      s = s.copyWith(
        completedEvents: {'ev1'},
        decisions: [const DecisionRecord(day: 1, eventId: 'ev1', choiceIdx: 2)],
      );
      expect(const CompletedEvent('ev1').eval(s), isTrue);
      expect(const CompletedEvent('ev2').eval(s), isFalse);
      expect(const MadeChoice('ev1', 2).eval(s), isTrue);
      expect(const MadeChoice('ev1', 1).eval(s), isFalse);
    });
  });

  group('Efecte, mută starea + imutabilitate', () {
    test('cash poate merge negativ; fond/obiectiv se taie la 0', () {
      final s = base();
      final s2 = const CashDelta(Money(-200000)).apply(s, today: 1);
      expect(s2.cash, const Money(-100000)); // 1000 - 2000 lei
      expect(s.cash, const Money(100000)); // originalul intact (imutabilitate)

      final s3 = const FundDelta(Money(-90000)).apply(s, today: 1);
      expect(s3.emergencyFund, const Money(0)); // taiat la 0 (avea 500 lei)
      expect(s3.fundUsed, const Money(50000)); // s-au folosit efectiv 500 lei

      final s4 = const GoalDelta(Money(-100)).apply(s, today: 1);
      expect(s4.goalSavings, const Money(0));
    });

    test('stat clamp 0-100; jobStability clamp', () {
      final s = base();
      expect(const StatDelta('stress', 200).apply(s, today: 1).stats.stress, 100);
      expect(const StatDelta('energy', -200).apply(s, today: 1).stats.energy, 0);
      expect(const JobStabilityDelta(200).apply(s, today: 1).jobStability, 100);
    });

    test('createDebt / payDebt', () {
      final s = base();
      final withDebt = const CreateDebt(
        id: 'card',
        principal: Money(40000),
        monthly: Money(10000),
        dueDay: 12,
      ).apply(s, today: 1);
      expect(withDebt.debts.any((d) => d.id == 'card'), isTrue);
      // Plată parțială a datoriei inițiale (600 lei), din cash.
      final paid = const PayDebt(id: 'rata_telefon', amount: Money(20000))
          .apply(s, today: 1);
      expect(paid.debts.single.principal, const Money(40000));
      expect(paid.cash, const Money(80000)); // 1000 - 200 lei
      // Plată integrală → datoria dispare.
      final full = const PayDebt(id: 'rata_telefon', full: true).apply(s, today: 1);
      expect(full.debts, isEmpty);
      expect(full.cash, const Money(40000)); // 1000 - 600 lei
    });

    test('addRecurring / removeRecurring / setFlag / clearFlag', () {
      final s = base();
      expect(const AddRecurring('netflix').apply(s, today: 1).bills, contains('netflix'));
      expect(const RemoveRecurring('chirie').apply(s, today: 1).bills, isNot(contains('chirie')));
      expect(const SetFlag('x').apply(s, today: 1).flags, contains('x'));
      expect(const ClearFlag('are_masina').apply(s, today: 1).flags, isNot(contains('are_masina')));
    });

    test('scheduleEffect / scheduleEvent programează pentru viitor', () {
      final s = base();
      final sched = const ScheduleEffect(
        delayDays: 3,
        effects: [CashDelta(Money(-40000))],
        note: 'consecință',
      ).apply(s, today: 5, sourceEventId: 'ev');
      expect(sched.scheduledEffects.single.fireOnDay, 8);
      expect(sched.scheduledEffects.single.sourceEventId, 'ev');

      final ev = const ScheduleEvent(delayDays: 7, eventId: 'parbriz_extins')
          .apply(s, today: 5);
      expect(ev.scheduledEvents.single, (12, 'parbriz_extins'));
    });
  });

  group('createRun + allocateSalary', () {
    test('starea inițială reflectă rolul', () {
      final s = base();
      expect(s.day, 0);
      expect(s.cash, const Money(100000));
      expect(s.emergencyFund, const Money(50000));
      expect(s.bills, ['chirie', 'utilitati', 'abonament']);
      expect(s.flags, contains('are_masina'));
      expect(s.contentVersion, '1.0.0-test');
      expect(s.goalTarget, const Money(200000));
    });

    test('alocarea pe plicuri conservă suma totală', () {
      final s = base();
      final total = s.cash + s.emergencyFund + s.goalSavings;
      final a = allocateSalary(s, toFund: const Money(30000), toGoal: const Money(20000));
      expect(a.cash, const Money(50000));
      expect(a.emergencyFund, const Money(80000));
      expect(a.goalSavings, const Money(20000));
      expect(a.cash + a.emergencyFund + a.goalSavings, total);
    });

    test('alocarea invalidă e respinsă', () {
      final s = base();
      expect(() => allocateSalary(s, toFund: const Money(-1), toGoal: Money.zero),
          throwsArgumentError);
      expect(() => allocateSalary(s, toFund: const Money(999999), toGoal: Money.zero),
          throwsArgumentError);
    });
  });

  group('advanceDay, salariu, facturi, efecte programate', () {
    test('salariul intră în ziua de plată (ghidat = fără variabilitate)', () {
      final s = createRun(c: content, roleId: 'test_rol', goalId: 'goal_studio', mode: 'ghidat', seed: 1);
      final r = advanceDay(s, content);
      expect(r.state.day, 1);
      expect(r.salaryReceived, Money.fromLei(3000)); // exact, fără variabilitate
      expect(r.state.cash, const Money(100000) + Money.fromLei(3000));
    });

    test('factura se plătește la scadență când cash-ul acoperă', () {
      // Avansăm până în ziua 5 (chirie) cu salariu în ziua 1.
      var s = createRun(c: content, roleId: 'test_rol', goalId: 'goal_studio', mode: 'ghidat', seed: 1);
      DayResult r;
      for (var d = 0; d < 5; d++) {
        r = advanceDay(s, content);
        s = r.state;
        if (r.event != null) s = applyChoice(s, r.event!, 1, content); // alegeri ieftine
      }
      expect(s.paidBillsOnTime, greaterThanOrEqualTo(1));
      expect(s.missedBills.where((m) => m.$1 == 'chirie'), isEmpty);
    });

    test('factura ratată → missedBills + miss_effects + penalitate contorizată', () {
      // Rol fără cash: golim cash-ul înainte de scadență.
      var s = createRun(c: content, roleId: 'test_rol', goalId: 'goal_studio', mode: 'ghidat', seed: 1);
      // Ziua 1: salariu, apoi golim cash cu un efect uriaș pentru a rata chiria.
      var r = advanceDay(s, content); // ziua 1
      s = r.state;
      if (r.event != null) s = applyChoice(s, r.event!, 1, content);
      s = const CashDelta(Money(-10000000)).apply(s, today: s.day); // cash mult negativ
      for (var d = s.day; d < 5; d++) {
        r = advanceDay(s, content);
        s = r.state;
        if (r.event != null) s = applyChoice(s, r.event!, 1, content);
      }
      expect(s.missedBills.any((m) => m.$1 == 'chirie'), isTrue);
      expect(s.penaltiesPaid.bani, greaterThan(0)); // -100 lei din miss_effects
      expect(s.stats.stress, greaterThan(25)); // stresul a urcat
    });

    test('efect programat se declanșează exact în ziua sa, o singură dată', () {
      var s = base();
      s = s.copyWith(day: 4, scheduledEffects: [
        const ScheduledEffect(
          fireOnDay: 6,
          effects: [CashDelta(Money(-40000))],
          note: 'amenda',
          sourceEventId: 'parbriz_extins',
        ),
      ]);
      // Ziua 5: nu se declanșează încă.
      var r = advanceDay(s, content);
      s = r.state;
      if (r.event != null) s = applyChoice(s, r.event!, 1, content);
      expect(r.effectsFired, isEmpty);
      final cashBefore = s.cash;
      // Ziua 6: se declanșează exact acum.
      r = advanceDay(s, content);
      s = r.state;
      expect(r.effectsFired.map((e) => e.$1), contains('amenda'));
      expect(s.cash, cashBefore - const Money(40000));
      expect(s.scheduledEffects, isEmpty);
      expect(s.firedEffects.single.sourceEventId, 'parbriz_extins');
      // Ziua 7+: nu se mai repetă.
      if (r.event != null) s = applyChoice(s, r.event!, 1, content);
      r = advanceDay(s, content);
      expect(r.effectsFired, isEmpty);
    });

    test(
        'settleRemainingEffects aplică tot ce a rămas programat, o singură '
        'dată, indiferent de fireOnDay, și golește scheduledEffects', () {
      var s = base().copyWith(day: 30, scheduledEffects: [
        const ScheduledEffect(
          fireOnDay: 33, // dincolo de finalul lunii, n-ar mai apuca niciodată
          effects: [CashDelta(Money(-70000)), StatDelta('health', -8)],
          note: 'infecția s-a extins',
          sourceEventId: 'dinte_urgenta',
        ),
        const ScheduledEffect(
          fireOnDay: 31,
          effects: [FundDelta(Money(-5000))],
          note: 'altă consecință amânată',
        ),
      ]);
      final cashBefore = s.cash;
      final fundBefore = s.emergencyFund;
      final healthBefore = s.stats.health;

      final settled = settleRemainingEffects(s);

      expect(settled.scheduledEffects, isEmpty);
      expect(settled.cash, cashBefore - const Money(70000));
      expect(settled.emergencyFund, fundBefore - const Money(5000));
      expect(settled.stats.health, healthBefore - 8);
      // Ambele consecințe s-au înregistrat în firedEffects (lineage debrief).
      expect(settled.firedEffects, hasLength(2));
      expect(settled.firedEffects.map((f) => f.sourceEventId),
          contains('dinte_urgenta'));

      // Idempotent la re-aplicare: nimic rămas de decontat a doua oară.
      final settledAgain = settleRemainingEffects(settled);
      expect(settledAgain.cash, settled.cash);
      expect(settledAgain.firedEffects, hasLength(2));
    });
  });

  group('Restanțe, facturile nu mai dispar', () {
    test('factura ratată intră în restanțe (pe lângă missedBills)', () {
      // Cash negativ înainte de scadența chiriei (ziua 5): chiria se ratează.
      final s = base().copyWith(day: 4, cash: Money.fromLei(-100));
      final r = advanceDay(s, content);
      expect(r.state.day, 5);
      expect(r.state.missedBills.any((m) => m.$1 == 'chirie'), isTrue);
      expect(r.state.arrears.any((a) => a.$1 == 'chirie'), isTrue);
      expect(r.billsMissed, contains('chirie'));
    });

    test('restanța se stinge automat când intră cash; nu contează la timp', () {
      // Restanță veche la chirie, cash suficient: pasul 3b o plătește integral.
      final s = base().copyWith(
        day: 8, // scadem la ziua 9: fără facturi/datorii scadente
        arrears: [('chirie', 5)],
        cash: Money.fromLei(1000),
        debts: const [],
      );
      final before = s.paidBillsOnTime;
      final r = advanceDay(s, content);
      expect(r.arrearsPaid, contains('chirie'));
      expect(r.state.arrears, isEmpty);
      // Chiria (900 lei) a ieșit din cash; plata târzie nu urcă paidBillsOnTime.
      expect(r.state.cash, Money.fromLei(100));
      expect(r.state.paidBillsOnTime, before);
    });

    test('restanța neplătită adaugă stres +1 pe zi, o singură dată', () {
      // Două restanțe, cash sub oricare: stresul urcă exact cu 1 (nu cu 2).
      final s = base().copyWith(
        day: 7, // ziua 8: fără facturi/datorii scadente
        arrears: [('chirie', 5), ('utilitati', 10)],
        cash: Money.fromLei(50),
        debts: const [],
        stats: const LifeStats(
            health: 75, energy: 75, stress: 40, relationships: 70),
      );
      final r = advanceDay(s, content);
      expect(r.arrearsPaid, isEmpty);
      expect(r.state.arrears, hasLength(2));
      // +1 restanță (o dată); fără stres din drift (cash 50 lei nu e negativ).
      expect(r.state.stats.stress, 41);
    });

    test('restanța cea mai veche prima; cash acoperă doar cea mică', () {
      // utilitati (200 lei) mai veche, chirie (900 lei) mai nouă, cash 250 lei.
      final s = base().copyWith(
        day: 7,
        arrears: [('utilitati', 4), ('chirie', 5)],
        cash: Money.fromLei(250),
        debts: const [],
      );
      final r = advanceDay(s, content);
      expect(r.arrearsPaid, ['utilitati']);
      expect(r.state.arrears.map((a) => a.$1).toList(), ['chirie']);
      expect(r.state.cash, Money.fromLei(50)); // 250 - 200
    });
  });

  group('Datorii, dobândă + taxă de întârziere + plată anticipată', () {
    test('rata ratată: taxă pe principal ȘI penaltiesPaid, stres +8', () {
      // rata_telefon: principal 600 lei, rată 150 lei, scadență ziua 20. Cash
      // 100 lei sub rată => ratare. Taxă = max(2% din 150, 20 lei) = 20 lei.
      final s = base().copyWith(day: 19, cash: Money.fromLei(100));
      final r = advanceDay(s, content);
      expect(r.state.debts.single.principal, Money.fromLei(620)); // 600 + 20
      expect(r.state.penaltiesPaid, Money.fromLei(20));
      expect(r.state.missedBills.any((m) => m.$1 == 'rata_telefon'), isTrue);
      expect(r.state.stats.stress, 33); // 25 + 8, fără alte surse
      expect(r.billsMissed, isEmpty); // datoria nu e „factură"
    });

    test('taxa minimă de 20 lei se aplică la rate mici', () {
      // Rată 300 lei: 2% = 6 lei sub 20 lei => taxă = 20 lei (plafon minim).
      const debt = DebtState(
          id: 'card', principal: Money(50000), monthly: Money(30000),
          dueDay: 20);
      final s = base().copyWith(day: 19, cash: Money.zero, debts: [debt]);
      final r = advanceDay(s, content);
      expect(r.state.debts.single.principal, Money.fromLei(520)); // 500 + 20
      expect(r.state.penaltiesPaid, Money.fromLei(20));
    });

    test('taxa proporțională (2%) când depășește minimul', () {
      // Rată 2000 lei: 2% = 40 lei peste 20 lei => taxă = 40 lei.
      const debt = DebtState(
          id: 'card', principal: Money(500000), monthly: Money(200000),
          dueDay: 20);
      final s = base().copyWith(day: 19, cash: Money.zero, debts: [debt]);
      final r = advanceDay(s, content);
      expect(r.state.debts.single.principal, Money.fromLei(5040)); // 5000 + 40
      expect(r.state.penaltiesPaid, Money.fromLei(40));
    });

    test('dobânda după grație: principalul crește 1,5% înainte de plată', () {
      // Grație până în ziua 10, scadență ziua 20 (20 peste 10) => dobândă.
      const debt = DebtState(
          id: 'card', principal: Money(100000), monthly: Money(20000),
          dueDay: 20, interestFreeUntil: 10);
      final s =
          base().copyWith(day: 19, debts: [debt], cash: Money.fromLei(500));
      final r = advanceDay(s, content);
      // 1,5% din 1000 lei = 15 lei; principal 1000 -> 1015; plată 200 -> 815.
      expect(r.state.debts.single.principal, Money.fromLei(815));
      expect(r.state.cash, Money.fromLei(300)); // 500 - 200
      expect(r.state.missedBills.any((m) => m.$1 == 'card'), isFalse);
    });

    test('fără dobândă în grație (ziua scadenței sub interestFreeUntil)', () {
      // Scadență ziua 20, grație până în ziua 25: 20 nu depășește 25.
      const debt = DebtState(
          id: 'card', principal: Money(100000), monthly: Money(20000),
          dueDay: 20, interestFreeUntil: 25);
      final s =
          base().copyWith(day: 19, debts: [debt], cash: Money.fromLei(500));
      final r = advanceDay(s, content);
      // Fără dobândă: principal 1000 -> plată 200 -> 800.
      expect(r.state.debts.single.principal, Money.fromLei(800));
    });

    test('payDebtEarly plătește și plafonează la principal și la cash', () {
      final s = base(); // cash 1000 lei, rata_telefon principal 600 lei
      final a = payDebtEarly(s, 'rata_telefon', Money.fromLei(200));
      expect(a.debts.single.principal, Money.fromLei(400)); // 600 - 200
      expect(a.cash, Money.fromLei(800)); // 1000 - 200
      // Plafon la principal: cerem 5000 lei, plătește doar 600 lei, stinge tot.
      final b = payDebtEarly(s, 'rata_telefon', Money.fromLei(5000));
      expect(b.debts, isEmpty);
      expect(b.cash, Money.fromLei(400)); // 1000 - 600
    });

    test('payDebtEarly: plafon la cash, nu duce cash-ul sub zero', () {
      final s = base().copyWith(cash: Money.fromLei(120));
      final a = payDebtEarly(s, 'rata_telefon', Money.fromLei(500));
      expect(a.cash, Money.zero); // plătește doar 120 lei
      expect(a.debts.single.principal, Money.fromLei(480)); // 600 - 120
    });

    test('payDebtEarly: sumă invalidă sau datorie inexistentă => neschimbat', () {
      final s = base();
      expect(identical(payDebtEarly(s, 'rata_telefon', Money.zero), s), isTrue);
      expect(identical(payDebtEarly(s, 'rata_telefon', Money.fromLei(-10)), s),
          isTrue);
      expect(identical(payDebtEarly(s, 'inexistent', Money.fromLei(100)), s),
          isTrue);
    });

    test('payDebtEarly: cash sub 50 lei => nu plătește nimic', () {
      final s = base().copyWith(cash: Money.fromLei(49));
      expect(identical(payDebtEarly(s, 'rata_telefon', Money.fromLei(10)), s),
          isTrue);
    });
  });

  group('Presiune cuplată pe stat-uri (bucle lente)', () {
    // Ziua 8: fără salariu/facturi/datorii scadente, cash pozitiv. Doar driftul
    // de bază (energie -2) și presiunea cuplată mișcă stat-urile.
    LifeSimState at8({required LifeStats stats}) =>
        base().copyWith(day: 7, debts: const [], stats: stats);

    test('stres > 70 => energie -2 în plus, peste driftul de bază', () {
      final r = advanceDay(
          at8(
              stats: const LifeStats(
                  health: 75, energy: 50, stress: 75, relationships: 70)),
          content);
      expect(r.state.stats.energy, 46); // 50 - 2 (bază) - 2 (cuplaj)
      expect(r.state.stats.stress, 75);
    });

    test('energie < 25 => sănătate -1', () {
      final r = advanceDay(
          at8(
              stats: const LifeStats(
                  health: 50, energy: 26, stress: 30, relationships: 70)),
          content);
      expect(r.state.stats.energy, 24); // 26 - 2 (bază)
      expect(r.state.stats.health, 49); // 50 - 1 (energie sub 25)
    });

    test('sănătate < 35 => stres +2', () {
      final r = advanceDay(
          at8(
              stats: const LifeStats(
                  health: 30, energy: 60, stress: 40, relationships: 70)),
          content);
      expect(r.state.stats.stress, 42); // 40 + 2 (sănătate sub 35)
      expect(r.state.stats.health, 30);
    });

    test('cascadă secvențială: stres>70 împinge energia sub 25, apoi sănătate -1',
        () {
      final r = advanceDay(
          at8(
              stats: const LifeStats(
                  health: 50, energy: 27, stress: 75, relationships: 70)),
          content);
      // bază: energie 27->25; cuplaj: stres>70 => energie 25->23; energie<25 =>
      // sănătate 50->49. Dovada evaluării secvențiale (nu pe un instantaneu).
      expect(r.state.stats.energy, 23);
      expect(r.state.stats.health, 49);
    });

    test('fără presiune când stat-urile sunt sănătoase', () {
      final r = advanceDay(
          at8(
              stats: const LifeStats(
                  health: 75, energy: 75, stress: 25, relationships: 70)),
          content);
      expect(r.state.stats.energy, 73); // doar driftul de bază
      expect(r.state.stats.health, 75);
      expect(r.state.stats.stress, 25);
    });
  });

  group('Director, noile probabilități de zi liniștită (mai greu)', () {
    test('baza realistă ~0,15 și ghidată ~0,32 (fără bonusul de +0,20)', () {
      // Ziua 1, stare proaspătă: lastEventDay e null, deci pQuiet = baza. Pool
      // eligibil nevid (cafea, ieșire), deci null vine doar din ruleta liniștită.
      const n = 400;
      var quietReal = 0;
      var quietGhid = 0;
      for (var seed = 0; seed < n; seed++) {
        final s = createRun(
                c: content,
                roleId: 'test_rol',
                goalId: 'goal_studio',
                mode: 'realist',
                seed: seed)
            .copyWith(day: 1);
        if (pickEvent(s: s, c: content, rng: _rngFor(s, 1), mode: 'realist') ==
            null) {
          quietReal++;
        }
        if (pickEvent(s: s, c: content, rng: _rngFor(s, 1), mode: 'ghidat') ==
            null) {
          quietGhid++;
        }
      }
      expect(quietReal / n, closeTo(0.15, 0.06), reason: 'realist $quietReal/$n');
      expect(quietGhid / n, closeTo(0.32, 0.07), reason: 'ghidat $quietGhid/$n');
      // Realistul e vizibil mai greu: mai puține zile liniștite decât ghidatul.
      expect(quietReal, lessThan(quietGhid));
    });
  });

  group('Director, eligibilitate, cooldown, prioritate programată', () {
    test('parbriz cere flag-ul are_masina', () {
      final withCar = base(); // are are_masina
      final withoutCar = base().copyWith(flags: <String>{}, day: 3);
      final parbriz = content.eventById('parbriz')!;
      expect(eventEligible(parbriz, withCar.copyWith(day: 3)), isTrue);
      expect(eventEligible(parbriz, withoutCar), isFalse);
    });

    test('fereastra de zile e respectată', () {
      final parbriz = content.eventById('parbriz')!; // min 2, max 25
      expect(eventEligible(parbriz, base().copyWith(day: 1)), isFalse);
      expect(eventEligible(parbriz, base().copyWith(day: 2)), isTrue);
      expect(eventEligible(parbriz, base().copyWith(day: 26)), isFalse);
    });

    test('cooldown: reapariția e blocată până trece', () {
      final cafea = content.eventById('cafea')!; // cooldown 2, repetabil
      var s = base().copyWith(day: 5, eventLastSeen: {'cafea': 4});
      expect(eventEligible(cafea, s), isFalse); // 5-4=1 < 2
      s = s.copyWith(day: 6);
      expect(eventEligible(cafea, s), isTrue); // 6-4=2 ≥ 2
    });

    test('one-shot terminat nu reapare; daily_living repetabil da', () {
      final parbriz = content.eventById('parbriz')!;
      final cafea = content.eventById('cafea')!;
      final s = base().copyWith(day: 5, completedEvents: {'parbriz', 'cafea'});
      expect(eventEligible(parbriz, s), isFalse); // one-shot consumat
      expect(eventEligible(cafea, s), isTrue); // repetabil (doar cooldown gateează)
    });

    test('prerequisite/exclusion: parbriz_extins fără condiții e mereu eligibil', () {
      final ext = content.eventById('parbriz_extins')!;
      expect(eventEligible(ext, base().copyWith(day: 10)), isTrue);
    });

    test('eveniment programat are PRIORITATE (sare peste ruleta liniștită)', () {
      // Programăm parbriz_extins scadent azi; pickEvent trebuie să-l aleagă.
      var s = base().copyWith(day: 8, scheduledEvents: [(8, 'parbriz_extins')]);
      final picked = pickEvent(s: s, c: content, rng: _rngFor(s, 8), mode: 'realist');
      expect(picked?.id, 'parbriz_extins');
      expect(dueScheduledEntry(s, content), (8, 'parbriz_extins'));
    });
  });

  group('Determinism, testul de aur', () {
    int firstChoice(LifeSimEvent e) => 0;

    test('același seed + aceleași decizii → run IDENTIC, eveniment cu eveniment', () {
      final a = _runMonth(content, seed: 12345, mode: 'realist', policy: firstChoice);
      final b = _runMonth(content, seed: 12345, mode: 'realist', policy: firstChoice);
      expect(a.seq, b.seq);
      // Starea finală serializată e identică bit-cu-bit.
      expect(jsonEncode(a.state.toJson()), jsonEncode(b.state.toJson()));
    });

    test('seed diferit → run diferit', () {
      final a = _runMonth(content, seed: 1, mode: 'realist', policy: firstChoice);
      final b = _runMonth(content, seed: 2, mode: 'realist', policy: firstChoice);
      expect(a.seq, isNot(equals(b.seq)));
    });

    test('lanțul parbriz: amânarea programează parbriz_extins mai târziu', () {
      // Politică: la parbriz alege „Amâni" (idx 1), restul idx 0.
      int policy(LifeSimEvent e) => e.id == 'parbriz' ? 1 : 0;
      final run = _runMonth(content, seed: 777, mode: 'realist', policy: policy);
      final sawParbriz = run.seq.contains('parbriz');
      if (sawParbriz) {
        // Dacă a apărut parbriz și a fost amânat, parbriz_extins trebuie să fie
        // fie declanșat, fie încă programat.
        final firedOrScheduled = run.seq.contains('parbriz_extins') ||
            run.state.scheduledEvents.any((e) => e.$2 == 'parbriz_extins') ||
            run.state.completedEvents.contains('parbriz_extins');
        expect(firedOrScheduled, isTrue);
      }
    });
  });

  group('Director, echilibrul de categorii (mecanism exact)', () {
    test('eventWeight aplică penalizările exact ca în spec', () {
      final raceala = content.eventById('raceala')!; // dif. 2, weight 7, health
      final s0 = base().copyWith(day: 5);
      expect(eventWeight(raceala, s0, 'realist'), 7.0, reason: 'fără penalizări');

      // Categoria de ieri → ×0,4.
      expect(
        eventWeight(raceala, s0.copyWith(lastEventCategory: 'health'), 'realist'),
        closeTo(7 * 0.4, 1e-9),
      );
      // Categorie deja „grea" (count ≥3) → ×0,5.
      expect(
        eventWeight(raceala, s0.copyWith(categoryCounts: {'health': 3}), 'realist'),
        closeTo(7 * 0.5, 1e-9),
      );
      // Cumulate.
      expect(
        eventWeight(
            raceala,
            s0.copyWith(lastEventCategory: 'health', categoryCounts: {'health': 3}),
            'realist'),
        closeTo(7 * 0.4 * 0.5, 1e-9),
      );
      // Anti-hammer: un negativ (dif. ≥2) IERI înmoaie negativele azi ×0,3.
      expect(
        eventWeight(
            raceala, s0.copyWith(lastEventDay: 4, lastEventDifficulty: 2), 'realist'),
        closeTo(7 * 0.3, 1e-9),
      );
      // Ghidat: șocurile intense (dif. ≥3) ×0,4; realist le lasă întregi.
      final ext = content.eventById('parbriz_extins')!; // dif. 3, weight 5
      expect(eventWeight(ext, s0, 'ghidat'), closeTo(5 * 0.4, 1e-9));
      expect(eventWeight(ext, s0, 'realist'), 5.0);
    });
  });

  group('Director, zile liniștite + spread pe un run de 30 zile', () {
    final run = _runMonth(content, seed: 2026, mode: 'realist', policy: (_) => 0);

    test('≥6 zile liniștite în modul realist', () {
      final quiet = run.seq.where((id) => id == null).length;
      expect(quiet, greaterThanOrEqualTo(6), reason: 'zile liniștite: $quiet');
    });

    test('directorul spread-uie pe multe categorii; niciun one-shot nu domină',
        () {
      final events = run.seq.whereType<String>().toList();
      final counts = <String, int>{};
      for (final id in events) {
        counts[content.eventById(id)!.category] =
            (counts[content.eventById(id)!.category] ?? 0) + 1;
      }
      // Varietate reală: directorul atinge multe categorii, nu una singură.
      expect(counts.keys.length, greaterThanOrEqualTo(6), reason: '$counts');
      // În fixture-ul minimal, „daily_living" (SINGURUL repetabil) umple coada
      // lunii după ce one-shot-urile se consumă, cap-ul global de 40% e o
      // proprietate de SCALĂ DE CONȚINUT (80-120 evenimente), validată de
      // Monte-Carlo. Aici verificăm că nicio categorie ONE-SHOT nu
      // domină și că mecanismul de echilibru (testat exact mai sus) e activ.
      counts.remove('daily_living');
      final maxOneShot =
          counts.values.fold(0, (a, b) => a > b ? a : b) / events.length;
      expect(maxOneShot, lessThanOrEqualTo(0.40), reason: 'one-shot: $counts');
    });
  });

  group('Scor, 4 dimensiuni + anti-monoton pe cash', () {
    test('mai mult cash peste pragul de tampon NU crește scorul', () {
      final s = base().copyWith(day: 30);
      final moderate = s.copyWith(cash: const Money(50000)); // exact la prag
      final hoarder = s.copyWith(cash: const Money(5000000)); // 50.000 lei
      expect(score(hoarder, content).total, score(moderate, content).total);
    });

    test('run echilibrat bate run-ul care doar tezaurizează cash', () {
      final s = base().copyWith(day: 30);
      // Tezaurizator: mult cash, dar fond 0, obiectiv 0, relații 0, facturi ratate.
      final hoarder = s.copyWith(
        cash: const Money(9000000),
        emergencyFund: Money.zero,
        goalSavings: Money.zero,
        debts: const [],
        stats: const LifeStats(health: 40, energy: 40, stress: 90, relationships: 5),
        paidBillsOnTime: 0,
        missedBills: [('chirie', 5), ('utilitati', 10)],
        daysCashNegative: 0,
      );
      // Echilibrat: cash modest, fond bun, obiectiv atins, relații bune, facturi la timp.
      final balanced = s.copyWith(
        cash: const Money(80000),
        emergencyFund: const Money(200000),
        goalSavings: const Money(200000),
        debts: const [],
        stats: const LifeStats(health: 85, energy: 80, stress: 20, relationships: 85),
        paidBillsOnTime: 6,
        missedBills: const [],
        daysCashNegative: 0,
      );
      expect(score(balanced, content).total,
          greaterThan(score(hoarder, content).total));
    });

    test('finalul se selectează la praguri (strategul vs navigatorul)', () {
      final s = base().copyWith(day: 30);
      final strong = s.copyWith(
        cash: const Money(80000),
        emergencyFund: const Money(200000),
        goalSavings: const Money(200000),
        debts: const [],
        stats: const LifeStats(health: 90, energy: 85, stress: 15, relationships: 90),
        paidBillsOnTime: 8,
      );
      expect(score(strong, content).endingId, 'strategul');
      final weak = s.copyWith(
        stats: const LifeStats(health: 30, energy: 30, stress: 95, relationships: 10),
        paidBillsOnTime: 0,
        missedBills: [('chirie', 5)],
        emergencyFund: Money.zero,
      );
      expect(score(weak, content).endingId, 'navigatorul'); // catch-all
    });
  });

  group('Debrief, derivat din ledger, cifre din stare', () {
    test('contrafactualul numește cea mai mare factură ratată', () {
      final s = base().copyWith(
        day: 30,
        missedBills: [('chirie', 5), ('utilitati', 10)],
      );
      final d = buildDebrief(s, content);
      // Chiria are penalitatea cea mai mare (-100 lei) → contrafactual pe ea.
      expect(d.counterfactual, contains('ziua 5'));
      expect(d.counterfactual, contains('900 lei')); // suma chiriei
    });

    test('deciziile eficiente/riscante ies din lineage-ul decizie→consecință', () {
      // Simulăm o lună în care „raceala" e împinsă (consecință întârziată -200 lei).
      int policy(LifeSimEvent e) {
        if (e.id == 'raceala') return 1; // împinge → programează cost
        if (e.id == 'bonus' || e.id == 'oferta' || e.id == 'windfall') return 0; // pozitive
        return 0;
      }
      final run = _runMonth(content, seed: 55, mode: 'realist', policy: policy);
      final d = buildDebrief(run.state, content);
      // Toate cifrele din debrief provin din stare.
      expect(d.paidBillsOnTime, run.state.paidBillsOnTime);
      expect(d.fundUsed, run.state.fundUsed);
      expect(d.goalSaved, run.state.goalSavings);
      // Eficiente au net ≥ 0, riscante net < 0 (dacă există).
      expect(d.efficient.every((o) => !o.net.isNegative), isTrue);
      expect(d.risky.every((o) => o.net.isNegative), isTrue);
      expect(d.efficient.length, lessThanOrEqualTo(3));
      expect(d.risky.length, lessThanOrEqualTo(2));
    });

    test('conceptul mapează un skill-tag la o lecție determinist', () {
      final s = base().copyWith(
        day: 30,
        decisions: const [
          DecisionRecord(day: 3, eventId: 'phishing', choiceIdx: 1),
        ],
        firedEffects: const [],
      );
      final d = buildDebrief(s, content);
      // phishing → skill_tag 'scams' → lecția mapată.
      expect(d.concept.skillTag, 'scams');
      expect(d.concept.lessonId, 'l_scutul_antiteapa');
    });
  });

  group('Persistență, round-trip JSON complet', () {
    test('starea inițială round-trip', () {
      final s = base();
      final back = LifeSimState.fromJson(s.toJson());
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    });

    test('o stare de mijloc bogată round-trip', () {
      final run = _runMonth(content, seed: 999, mode: 'realist', policy: (_) => 0, days: 18);
      final s = run.state;
      final back = LifeSimState.fromJson(s.toJson());
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
      // Câteva câmpuri verificate explicit după re-hidratare.
      expect(back.day, s.day);
      expect(back.decisions.length, s.decisions.length);
      expect(back.cash, s.cash);
      expect(back.flags, s.flags);
    });

    test('resume din snapshot continuă identic (seed + decizii → același rezultat)', () {
      int policy(LifeSimEvent e) => 0;
      // Rulăm 15 zile, serializăm, re-hidratăm, continuăm 15, comparăm cu un
      // run neîntrerupt.
      final full = _runMonth(content, seed: 314, mode: 'realist', policy: policy);

      var s = createRun(c: content, roleId: 'test_rol', goalId: 'goal_studio', mode: 'realist', seed: 314);
      for (var i = 0; i < 15; i++) {
        final r = advanceDay(s, content);
        s = r.state;
        if (r.event != null) s = applyChoice(s, r.event!, policy(r.event!), content);
      }
      s = LifeSimState.fromJson(s.toJson()); // snapshot → resume
      for (var i = 0; i < 15; i++) {
        final r = advanceDay(s, content);
        s = r.state;
        if (r.event != null) s = applyChoice(s, r.event!, policy(r.event!), content);
      }
      expect(jsonEncode(s.toJson()), jsonEncode(full.state.toJson()));
    });
  });
}

/// rng-ul deterministic pe care îl folosește motorul pentru o zi dată (fork
/// pe zi → sub-stream 2 pentru director), reconstruit ca în advanceDay.
LifeSimRng _rngFor(LifeSimState s, int day) =>
    LifeSimRng(s.seed).fork(day).fork(2);
