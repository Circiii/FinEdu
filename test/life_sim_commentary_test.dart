import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/life_sim/life_sim_commentary.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_content.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_debrief.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_state.dart';
import 'package:finedu_flutter/domain/engine/life_sim/money.dart';

// ---------------------------------------------------------------------------
// Fixture-uri minimale, construite direct (fără JSON), comentariile lui
// Cashy operează pe stare/debrief/eveniment, nu pe conținutul brut.
// ---------------------------------------------------------------------------

LifeSimState _state({
  int day = 5,
  Money cash = const Money(100000),
  Money goalSavings = Money.zero,
  LifeStats stats = const LifeStats(
    health: 75,
    energy: 75,
    stress: 25,
    relationships: 70,
  ),
  List<ScheduledEffect> scheduledEffects = const [],
  List<(int, String)> scheduledEvents = const [],
}) => LifeSimState(
  day: day,
  cash: cash,
  emergencyFund: Money.zero,
  goalSavings: goalSavings,
  debts: const [],
  bills: const [],
  stats: stats,
  jobStability: 70,
  flags: const {},
  scheduledEffects: scheduledEffects,
  scheduledEvents: scheduledEvents,
  completedEvents: const {},
  decisions: const [],
  categoryCounts: const {},
  missedBills: const [],
  paidBillsOnTime: 0,
  penaltiesPaid: Money.zero,
  fundUsed: Money.zero,
  eventLastSeen: const {},
  firedEffects: const [],
  daysCashNegative: 0,
  seed: 1,
  contentVersion: 'test',
  mode: 'realist',
  roleId: 'r',
  goalId: 'g',
  goalTarget: const Money(500000),
);

LifeSimEvent _event(List<LifeChoice> choices) => LifeSimEvent(
  id: 'ev_test',
  category: 'test',
  rarity: 'common',
  weight: 1,
  cooldownDays: 0,
  minDay: 1,
  maxDay: 30,
  roleTags: const [],
  difficulty: 1,
  conditions: const [],
  exclusions: const [],
  prerequisites: const [],
  chainId: null,
  skillTags: const [],
  title: 'Eveniment test',
  narrative: '',
  illustration: '',
  choices: choices,
  source: const SourceMeta(label: ''),
);

DebriefModel _debrief({
  List<(int, String)> timeline = const [],
  List<DebriefDecision> efficient = const [],
  List<DebriefDecision> risky = const [],
  String counterfactual =
      'Nu ai lăsat nicio penalizare evitabilă, cash-flow curat.',
  int paidBillsOnTime = 5,
}) => DebriefModel(
  timeline: timeline,
  efficient: efficient,
  risky: risky,
  paidBillsOnTime: paidBillsOnTime,
  missedBills: const [],
  debtCreated: const [],
  fundUsed: Money.zero,
  goalSaved: const Money(100000),
  goalTarget: const Money(200000),
  penaltiesPaid: Money.zero,
  counterfactual: counterfactual,
  concept: const DebriefConcept(skillTag: 'budgeting', lessonId: 'l_buget'),
);

void main() {
  group('Determinism, aceleași intrări → aceeași ieșire', () {
    test('commentOnChoice e determinist', () {
      final before = _state(cash: const Money(100000));
      final after = _state(cash: const Money(50000));
      final event = _event([
        const LifeChoice(label: 'A', effects: [], debrief: 'Compromis test'),
      ]);
      final a = commentOnChoice(
        event: event,
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 42,
      );
      final b = commentOnChoice(
        event: event,
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 42,
      );
      expect(a.line, b.line);
      expect(a.more, b.more);
      expect(a.mood, b.mood);
    });

    test('commentOnQuietDay e determinist', () {
      final s = _state(day: 9);
      final a = commentOnQuietDay(s: s, seed: 7);
      final b = commentOnQuietDay(s: s, seed: 7);
      expect(a.line, b.line);
      expect(a.mood, b.mood);
    });

    test('narrateReport e determinist', () {
      final s = _state(day: 30);
      final d = _debrief();
      final a = narrateReport(debrief: d, s: s, seed: 3);
      final b = narrateReport(debrief: d, s: s, seed: 3);
      expect(a.map((c) => c.line).toList(), b.map((c) => c.line).toList());
      expect(a.map((c) => c.mood).toList(), b.map((c) => c.mood).toList());
    });
  });

  group(
    'commentOnChoice, mai multe (trade-off + calendar/cost de oportunitate)',
    () {
      test('more[0] e chiar debrief-ul alegerii, când există', () {
        final before = _state(cash: const Money(100000));
        final after = _state(cash: const Money(90000));
        final event = _event([
          const LifeChoice(
            label: 'A',
            effects: [],
            debrief: 'Compromisul exact al alegerii.',
          ),
        ]);
        final c = commentOnChoice(
          event: event,
          choiceIdx: 0,
          before: before,
          after: after,
          seed: 1,
        );
        expect(c.more[0], 'Compromisul exact al alegerii.');
      });

      test('more[1]: cost de oportunitate corect când ≥2 zile de mâncare', () {
        // delta = -9000 bani (90 lei) → 9000/3000 = 3 zile.
        final before = _state(cash: const Money(200000));
        final after = _state(cash: const Money(191000));
        final event = _event([
          const LifeChoice(label: 'A', effects: [], debrief: 'd'),
        ]);
        final c = commentOnChoice(
          event: event,
          choiceIdx: 0,
          before: before,
          after: after,
          seed: 5,
        );
        expect(c.more[1], contains('3'));
        expect(c.more[1], contains('zile'));
      });

      test('more[1]: sub 2 zile → replică de umplutură (fără „zile")', () {
        // delta = -3000 bani (30 lei) → 3000/3000 = 1 zi, sub prag.
        final before = _state(cash: const Money(50000));
        final after = _state(cash: const Money(47000));
        final event = _event([
          const LifeChoice(label: 'A', effects: [], debrief: 'd'),
        ]);
        final c = commentOnChoice(
          event: event,
          choiceIdx: 0,
          before: before,
          after: after,
          seed: 2,
        );
        expect(c.more[1], isNot(contains('zile')));
      });

      test(
        'more[1]: consecință programată → quip de calendar, nu cost de oportunitate',
        () {
          final before = _state(
            cash: const Money(100000),
            scheduledEvents: const [],
          );
          final after = _state(
            cash: const Money(100000),
            scheduledEvents: const [(10, 'ev_viitor')],
          );
          final event = _event([
            const LifeChoice(label: 'A', effects: [], debrief: 'd'),
          ]);
          final c = commentOnChoice(
            event: event,
            choiceIdx: 0,
            before: before,
            after: after,
            seed: 6,
          );
          expect(c.more[1], isNot(contains('zile de mâncare')));
        },
      );
    },
  );

  group('Derivarea mood-ului (spec exact)', () {
    LifeChoice choice() =>
        const LifeChoice(label: 'A', effects: [], debrief: 'd');

    test('cash negativ după alegere → worried', () {
      final before = _state(cash: const Money(10000));
      final after = _state(cash: const Money(-5000));
      final c = commentOnChoice(
        event: _event([choice()]),
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 1,
      );
      expect(c.mood, CashyMoodGame.worried);
    });

    test('stres > 70 → worried chiar cu cash pozitiv', () {
      final before = _state(
        cash: const Money(100000),
        stats: const LifeStats(
          health: 75,
          energy: 75,
          stress: 50,
          relationships: 70,
        ),
      );
      final after = _state(
        cash: const Money(100000),
        stats: const LifeStats(
          health: 75,
          energy: 75,
          stress: 75,
          relationships: 70,
        ),
      );
      final c = commentOnChoice(
        event: _event([choice()]),
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 1,
      );
      expect(c.mood, CashyMoodGame.worried);
    });

    test('câștig mare (≥500 lei) → celebrate', () {
      final before = _state(cash: const Money(10000));
      final after = _state(cash: const Money(70000)); // +600 lei
      final c = commentOnChoice(
        event: _event([choice()]),
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 1,
      );
      expect(c.mood, CashyMoodGame.celebrate);
    });

    test(
      'progres la obiectiv → celebrate, chiar fără mișcare mare de cash',
      () {
        final before = _state(
          cash: const Money(10000),
          goalSavings: Money.zero,
        );
        final after = _state(
          cash: const Money(10000),
          goalSavings: const Money(5000),
        );
        final c = commentOnChoice(
          event: _event([choice()]),
          choiceIdx: 0,
          before: before,
          after: after,
          seed: 1,
        );
        expect(c.mood, CashyMoodGame.celebrate);
      },
    );

    test('consecință programată, fără altceva notabil → thinking', () {
      final before = _state(cash: const Money(10000));
      final after = _state(
        cash: const Money(10000),
        scheduledEvents: const [(10, 'ev_x')],
      );
      final c = commentOnChoice(
        event: _event([choice()]),
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 1,
      );
      expect(c.mood, CashyMoodGame.thinking);
    });

    test('nimic notabil → happy', () {
      final before = _state(cash: const Money(10000));
      final after = _state(cash: const Money(10000));
      final c = commentOnChoice(
        event: _event([choice()]),
        choiceIdx: 0,
        before: before,
        after: after,
        seed: 1,
      );
      expect(c.mood, CashyMoodGame.happy);
    });

    test(
      'commentOnQuietDay: cash negativ sau stres mare → worried, altfel happy',
      () {
        final calm = _state(cash: const Money(1000));
        expect(commentOnQuietDay(s: calm, seed: 1).mood, CashyMoodGame.happy);
        final broke = _state(cash: const Money(-1000));
        expect(
          commentOnQuietDay(s: broke, seed: 1).mood,
          CashyMoodGame.worried,
        );
        final stressed = _state(
          cash: const Money(1000),
          stats: const LifeStats(
            health: 75,
            energy: 75,
            stress: 80,
            relationships: 70,
          ),
        );
        expect(
          commentOnQuietDay(s: stressed, seed: 1).mood,
          CashyMoodGame.worried,
        );
      },
    );
  });

  group('Lint, nicio linie din pool-uri nu conține fraze interzise', () {
    test('fără shaming în vreo variantă (FIECARE linie, nu un eșantion)', () {
      final all = allCommentaryTemplates();
      expect(all, isNotEmpty);
      for (final line in all) {
        final lower = line.toLowerCase();
        for (final banned in bannedCashyPhrases) {
          expect(
            lower.contains(banned),
            isFalse,
            reason: '„$banned" găsit în: "$line"',
          );
        }
      }
    });
  });

  group('narrateReport, segmente + cifre din debrief/stare', () {
    test('cu decizii eficiente/riscante → 7 segmente (în intervalul 5-8)', () {
      const efficient = [
        DebriefDecision(
          day: 3,
          eventId: 'e1',
          title: 'Oferta',
          choiceIdx: 0,
          immediate: Money(30000),
          delayed: Money.zero,
        ),
        DebriefDecision(
          day: 9,
          eventId: 'e2',
          title: 'Bonus',
          choiceIdx: 0,
          immediate: Money(50000),
          delayed: Money.zero,
        ),
      ];
      const risky = [
        DebriefDecision(
          day: 12,
          eventId: 'e3',
          title: 'Împrumut riscant',
          choiceIdx: 1,
          immediate: Money(-20000),
          delayed: Money(-40000),
        ),
      ];
      final d = _debrief(
        timeline: const [(3, 'Oferta'), (9, 'Bonus'), (12, 'Împrumut riscant')],
        efficient: efficient,
        risky: risky,
      );
      final s = _state(day: 30);
      final segs = narrateReport(debrief: d, s: s, seed: 11);
      expect(segs.length, 7);
      expect(segs.length, inInclusiveRange(5, 8));
    });

    test(
      'fără decizii notabile → segment „constant" ține totalul în interval',
      () {
        final d = _debrief();
        final s = _state(day: 30);
        final segs = narrateReport(debrief: d, s: s, seed: 4);
        expect(segs.length, 5);
        expect(segs.length, inInclusiveRange(5, 8));
      },
    );

    test('cifrele interpolate corespund EXACT stării/debrief-ului', () {
      const efficientDecision = DebriefDecision(
        day: 7,
        eventId: 'e1',
        title: 'Vânzare rapidă',
        choiceIdx: 0,
        immediate: Money(45000),
        delayed: Money.zero,
      );
      const riskyDecision = DebriefDecision(
        day: 14,
        eventId: 'e2',
        title: 'Pariu prostesc',
        choiceIdx: 1,
        immediate: Money(-10000),
        delayed: Money(-30000),
      );
      final d = _debrief(
        timeline: const [(7, 'Vânzare rapidă'), (14, 'Pariu prostesc')],
        efficient: const [efficientDecision],
        risky: const [riskyDecision],
        paidBillsOnTime: 8,
        counterfactual: 'Dacă plăteai 900 lei în ziua 5, evitai 100 lei.',
      );
      const stats = LifeStats(
        health: 82,
        energy: 60,
        stress: 45,
        relationships: 91,
      );
      final s = _state(day: 30, stats: stats);
      final segs = narrateReport(debrief: d, s: s, seed: 9);

      // Ordine: opener, eficientă, riscantă, lecție, bilanț, concluzie.
      expect(segs.length, 6);

      final opener = segs[0].line;
      expect(opener, contains('${s.day}'));
      expect(opener, contains('${d.timeline.length}'));

      final efficientLine = segs[1].line;
      expect(efficientLine, contains('${efficientDecision.day}'));
      expect(efficientLine, contains(efficientDecision.title));
      expect(efficientLine, contains(efficientDecision.net.lei));

      final riskyLine = segs[2].line;
      expect(riskyLine, contains('${riskyDecision.day}'));
      expect(riskyLine, contains(riskyDecision.title));
      expect(riskyLine, contains((-riskyDecision.net).lei));

      final lessonLine = segs[3].line;
      expect(lessonLine, contains(d.counterfactual));

      final balanceLine = segs[4].line;
      expect(balanceLine, contains('${stats.health}'));
      expect(balanceLine, contains('${stats.energy}'));
      expect(balanceLine, contains('${stats.stress}'));
      expect(balanceLine, contains('${stats.relationships}'));
    });

    test('fiecare segment are un mood atribuit', () {
      final d = _debrief();
      final s = _state(day: 30);
      final segs = narrateReport(debrief: d, s: s, seed: 1);
      for (final seg in segs) {
        expect(CashyMoodGame.values, contains(seg.mood));
      }
    });
  });
}
