/// Debrief-ul lunii din „30 de Zile": reconstituie luna DIN STARE, determinist
///, cronologia deciziilor, cele mai eficiente/riscante alegeri, un
/// contrafactual rule-based și un concept de învățat. Zero AI, zero shaming.
library;

import 'life_sim_content.dart';
import 'life_sim_effects.dart';
import 'life_sim_state.dart';
import 'money.dart';

/// Tabel skill-tag → lecție recomandată.
const _skillToLesson = <String, String>{
  'emergency_fund': 'l_fond_urgenta',
  'opportunity_cost': 'l_cost_oportunitate',
  'credit': 'l_credit_dobanda',
  'budgeting': 'l_buget',
  'needs_wants': 'l_nevoi_dorinte',
  'scams': 'l_scutul_antiteapa',
  'saving': 'l_economisire',
};
const _defaultLesson = 'l_buget';

/// O decizie cu rezultatul ei net (imediat + întârziat), pentru clasamentele
/// „eficiente"/„riscante".
class DebriefDecision {
  const DebriefDecision({
    required this.day,
    required this.eventId,
    required this.title,
    required this.choiceIdx,
    required this.immediate,
    required this.delayed,
  });

  final int day;
  final String eventId;
  final String title;
  final int choiceIdx;

  /// Delta imediat de valoare (cash+fond+obiectiv) al alegerii.
  final Money immediate;

  /// Delta întârziat: consecințele programate care s-au declanșat mai târziu
  /// și sunt atribuite acestei decizii (lineage prin sourceEventId).
  final Money delayed;

  Money get net => immediate + delayed;
}

class DebriefConcept {
  const DebriefConcept({required this.skillTag, required this.lessonId});
  final String skillTag;
  final String lessonId;
}

class DebriefModel {
  const DebriefModel({
    required this.timeline,
    required this.efficient,
    required this.risky,
    required this.paidBillsOnTime,
    required this.missedBills,
    required this.debtCreated,
    required this.fundUsed,
    required this.goalSaved,
    required this.goalTarget,
    required this.penaltiesPaid,
    required this.counterfactual,
    required this.concept,
  });

  /// Cronologia deciziilor majore: (zi, titlu eveniment).
  final List<(int, String)> timeline;
  final List<DebriefDecision> efficient; // top 3, net ≥ 0
  final List<DebriefDecision> risky; // top 2, net < 0
  final int paidBillsOnTime;
  final List<(String, int)> missedBills;
  final List<String> debtCreated;
  final Money fundUsed;
  final Money goalSaved;
  final Money goalTarget;
  final Money penaltiesPaid;

  /// UN contrafactual rule-based (cea mai mare penalizare evitabilă).
  final String counterfactual;

  /// UN concept de învățat + lecția recomandată.
  final DebriefConcept concept;
}

DebriefModel buildDebrief(LifeSimState s, LifeSimContent c) {
  final outcomes = <DebriefDecision>[];
  for (final d in s.decisions) {
    final e = c.eventById(d.eventId);
    final title = e?.title ?? d.eventId;
    final immediate = (e != null && d.choiceIdx < e.choices.length)
        ? _immediateValue(e.choices[d.choiceIdx].effects)
        : Money.zero;
    final delayed = s.firedEffects
        .where((f) => f.sourceEventId == d.eventId)
        .fold<Money>(
          Money.zero,
          (sum, f) => sum + f.cashDelta + f.fundDelta + f.goalDelta,
        );
    outcomes.add(
      DebriefDecision(
        day: d.day,
        eventId: d.eventId,
        title: title,
        choiceIdx: d.choiceIdx,
        immediate: immediate,
        delayed: delayed,
      ),
    );
  }

  final timeline = [
    for (final d in s.decisions)
      (d.day, c.eventById(d.eventId)?.title ?? d.eventId),
  ];

  // Eficiente: net >= 0 desc. Riscante: net < 0 asc. Egalități rupte pe zi.
  final byNetDesc = [...outcomes]
    ..sort((a, b) {
      final byNet = b.net.compareTo(a.net);
      return byNet != 0 ? byNet : a.day.compareTo(b.day);
    });
  final byNetAsc = [...outcomes]
    ..sort((a, b) {
      final byNet = a.net.compareTo(b.net);
      return byNet != 0 ? byNet : a.day.compareTo(b.day);
    });
  final efficient = byNetDesc.where((o) => !o.net.isNegative).take(3).toList();
  final risky = byNetAsc.where((o) => o.net.isNegative).take(2).toList();

  return DebriefModel(
    timeline: timeline,
    efficient: efficient,
    risky: risky,
    paidBillsOnTime: s.paidBillsOnTime,
    missedBills: List.of(s.missedBills),
    debtCreated: _createdDebts(s, c),
    fundUsed: s.fundUsed,
    goalSaved: s.goalSavings,
    goalTarget: s.goalTarget,
    penaltiesPaid: s.penaltiesPaid,
    counterfactual: _counterfactual(s, c, outcomes),
    concept: _concept(s, c, risky),
  );
}

/// Suma delta-urilor de valoare (cash+fond+obiectiv) ale unei liste de efecte.
Money _immediateValue(List<LifeEffect> effects) {
  var sum = Money.zero;
  for (final e in effects) {
    switch (e) {
      case CashDelta(:final delta):
        sum = sum + delta;
      case FundDelta(:final delta):
        sum = sum + delta;
      case GoalDelta(:final delta):
        sum = sum + delta;
      default:
        break;
    }
  }
  return sum;
}

/// Penalitatea în cash a ratării unei recurente (suma scăderilor de cash din
/// miss_effects).
Money _penaltyOf(RecurringDef def) {
  var pen = Money.zero;
  for (final e in def.missEffects) {
    if (e is CashDelta && e.delta.isNegative) pen = pen + (-e.delta);
  }
  return pen;
}

/// Contrafactualul: cea mai mare penalizare evitabilă. Întâi facturile ratate
/// (plăteai X → evitai Y); altfel cea mai costisitoare consecință întârziată.
String _counterfactual(
  LifeSimState s,
  LifeSimContent c,
  List<DebriefDecision> outcomes,
) {
  (String id, int day, Money x, Money y)? best;
  for (final m in s.missedBills) {
    // Datoriile ratate ajung și ele în missedBills dar n-au definiție în
    // recurring.json, skip, altfel am fabrica o penalizare inexistentă.
    if (s.debts.any((d) => d.id == m.$1)) continue;
    final def = c.recurringById(m.$1);
    if (def == null) continue;
    final y = _penaltyOf(def);
    if (best == null || y > best.$4) best = (m.$1, m.$2, def.amount, y);
  }
  if (best != null && best.$4.bani > 0) {
    return 'Dacă plăteai ${best.$3.lei} în ziua ${best.$2}, '
        'evitai ${best.$4.lei}.';
  }

  DebriefDecision? worst;
  for (final o in outcomes) {
    if (o.delayed.isNegative && (worst == null || o.delayed < worst.delayed)) {
      worst = o;
    }
  }
  if (worst != null) {
    return 'Dacă alegeai altfel la „${worst.title}" în ziua ${worst.day}, '
        'evitai ${(-worst.delayed).lei}.';
  }

  return 'Nu ai lăsat în urmă nicio penalizare evitabilă, cash-flow curat.';
}

/// Conceptul de învățat: skill-tag-ul cel mai frecvent în deciziile riscante
/// (fallback pe toate deciziile), mapat la o lecție. Egalități → alfabetic.
DebriefConcept _concept(
  LifeSimState s,
  LifeSimContent c,
  List<DebriefDecision> risky,
) {
  final tally = <String, int>{};
  void count(String eventId) {
    final e = c.eventById(eventId);
    for (final t in e?.skillTags ?? const <String>[]) {
      tally[t] = (tally[t] ?? 0) + 1;
    }
  }

  for (final o in risky) {
    count(o.eventId);
  }
  if (tally.isEmpty) {
    for (final d in s.decisions) {
      count(d.eventId);
    }
  }
  if (tally.isEmpty) {
    return const DebriefConcept(
      skillTag: 'budgeting',
      lessonId: _defaultLesson,
    );
  }

  final top =
      (tally.entries.toList()..sort((a, b) {
            final byCount = b.value.compareTo(a.value);
            return byCount != 0 ? byCount : a.key.compareTo(b.key);
          }))
          .first
          .key;
  return DebriefConcept(
    skillTag: top,
    lessonId: _skillToLesson[top] ?? _defaultLesson,
  );
}

/// Id-urile datoriilor create în timpul lunii (efectul createDebt), nu cele
/// inițiale ale rolului.
List<String> _createdDebts(LifeSimState s, LifeSimContent c) {
  final created = <String>{};
  for (final d in s.decisions) {
    final e = c.eventById(d.eventId);
    if (e == null || d.choiceIdx >= e.choices.length) continue;
    for (final eff in e.choices[d.choiceIdx].effects) {
      if (eff is CreateDebt) created.add(eff.id);
    }
  }
  return created.toList()..sort();
}
