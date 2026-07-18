/// Motorul de avans pentru „30 de Zile". [createRun] pornește luna din rol,
/// [advanceDay] procesează o zi în ordine fixă (salariu → recurente →
/// datorii → efecte programate → drift de stat → director), [applyChoice]
/// aplică decizia jucătorului, [allocateSalary] mută bani pe plicuri.
///
/// Determinism: rng-ul se derivă `LifeSimRng(seed).fork(zi)` per zi, apoi în
/// sub-stream-uri (salariu, director), o decizie diferită într-o zi nu
/// deplasează randomul altor zile.
///
/// [advanceDay] doar afișează evenimentul, nu-i aplică alegerea, UI-ul arată
/// opțiunile, apoi cheamă [applyChoice].
library;

import 'life_sim_content.dart';
import 'life_sim_director.dart';
import 'life_sim_effects.dart';
import 'life_sim_rng.dart';
import 'life_sim_state.dart';
import 'money.dart';

/// Rezumatul unei zile procesate. [event] NU e încă aplicat (UI arată alegerea).
class DayResult {
  const DayResult({
    required this.state,
    required this.salaryReceived,
    required this.billsPaid,
    required this.billsMissed,
    required this.effectsFired,
    required this.event,
    this.arrearsPaid = const [],
  });

  final LifeSimState state;
  final Money? salaryReceived;
  final List<String> billsPaid;
  final List<String> billsMissed;

  /// Consecințe întârziate care s-au declanșat azi: (notă, rezumat delta).
  final List<(String, String)> effectsFired;

  /// Restanțe stinse automat azi (id-uri recurente), pentru sumarul zilei.
  final List<String> arrearsPaid;

  final LifeSimEvent? event;
}

/// Construiește starea inițială din rol (cash, fond, datorii, facturi, flag-uri
/// din beneficii). Ziua începe la 0; primul [advanceDay] o duce la 1.
LifeSimState createRun({
  required LifeSimContent c,
  required String roleId,
  required String goalId,
  required String mode,
  required int seed,
}) {
  final role = c.roleById(roleId);
  if (role == null) throw ArgumentError('rol inexistent: $roleId');
  final goal = c.goalById(goalId);
  if (goal == null) throw ArgumentError('obiectiv inexistent: $goalId');

  return LifeSimState(
    day: 0,
    cash: role.initialCash,
    emergencyFund: role.initialFund,
    goalSavings: Money.zero,
    debts: List.of(role.debts),
    bills: List.of(role.bills),
    stats: LifeStats.initial(),
    jobStability: 70,
    flags: {...role.benefitFlags},
    scheduledEffects: const [],
    scheduledEvents: const [],
    completedEvents: <String>{},
    decisions: const [],
    categoryCounts: <String, int>{},
    missedBills: const [],
    paidBillsOnTime: 0,
    penaltiesPaid: Money.zero,
    fundUsed: Money.zero,
    eventLastSeen: <String, int>{},
    firedEffects: const [],
    daysCashNegative: 0,
    seed: seed,
    contentVersion: c.version,
    mode: mode,
    roleId: roleId,
    goalId: goalId,
    goalTarget: goal.target,
  );
}

/// Procesează o zi. Ordinea e contractuală (testată), nu o schimba fără să
/// actualizezi golden-testul de determinism.
DayResult advanceDay(LifeSimState s, LifeSimContent c) {
  final newDay = s.day + 1;
  final role = c.roleById(s.roleId)!;

  // Rng per zi, apoi sub-stream-uri independente (salariul nu deplasează
  // directorul și invers).
  final dayRng = LifeSimRng(s.seed).fork(newDay);
  final salaryRng = dayRng.fork(1);
  final directorRng = dayRng.fork(2);

  var st = s.copyWith(day: newDay);

  // 1. Salariul (dacă e ziua de plată). Variabilitatea se aplică determinist
  //    prin salaryRng; modul ghidat o oprește (venit predictibil).
  Money? salaryReceived;
  if (newDay == role.payDay) {
    var salary = role.scenarioNet;
    if (st.mode != 'ghidat' && role.salaryVariability > 0) {
      final v = role.salaryVariability;
      final mult = (1 - v) + salaryRng.nextDouble() * (2 * v);
      salary = Money((role.scenarioNet.bani * mult).round());
    }
    st = st.copyWith(cash: st.cash + salary);
    salaryReceived = salary;
  }

  // 2. Recurente scadente azi: plătite dacă cash-ul acoperă (paidBillsOnTime++),
  //    altfel ratate (missedBills + miss_effects, penalitatea contorizată).
  final billsPaid = <String>[];
  final billsMissed = <String>[];
  for (final billId in st.bills) {
    final def = c.recurringById(billId);
    if (def == null || def.dueDay != newDay) continue;
    if (st.cash >= def.amount) {
      st = st.copyWith(
        cash: st.cash - def.amount,
        paidBillsOnTime: st.paidBillsOnTime + 1,
      );
      billsPaid.add(billId);
    } else {
      st = st.copyWith(
        missedBills: [...st.missedBills, (billId, newDay)],
        arrears: [...st.arrears, (billId, newDay)],
      );
      final before = st;
      for (final eff in def.missEffects) {
        st = eff.apply(st, today: newDay);
      }
      final penalty = before.cash - st.cash; // pozitiv = penalitate în cash
      if (penalty.bani > 0) {
        st = st.copyWith(penaltiesPaid: st.penaltiesPaid + penalty);
      }
      billsMissed.add(billId);
    }
  }

  // 3. Rate lunare de datorie scadente azi. Dobânda după perioada de grație și
  //    taxa de întârziere la ratare fac datoria să coste cu adevărat.
  {
    var cash = st.cash;
    var paidOnTime = st.paidBillsOnTime;
    var penalties = st.penaltiesPaid;
    var stats = st.stats;
    final missed = [...st.missedBills];
    final newDebts = <DebtState>[];
    for (final debt0 in st.debts) {
      if (debt0.dueDay != newDay) {
        newDebts.add(debt0);
        continue;
      }
      // Dobânda după grație: principalul crește 1,5% (rotunjit la ban) ÎNAINTE
      // de calculul plății.
      var debt = debt0;
      final freeUntil = debt.interestFreeUntil;
      if (freeUntil != null && newDay > freeUntil) {
        final interest = Money((debt.principal.bani * 0.015).round());
        if (interest > Money.zero) {
          debt = debt.copyWith(principal: debt.principal + interest);
        }
      }
      final pay =
          debt.monthly <= debt.principal ? debt.monthly : debt.principal;
      if (cash >= pay) {
        cash = cash - pay;
        paidOnTime++;
        final np = debt.principal - pay;
        if (np > Money.zero) newDebts.add(debt.copyWith(principal: np));
        // np ≤ 0 → datorie stinsă, o scoatem.
      } else {
        // Ratare: taxă de întârziere max(2% din rată, 20 lei), rotunjită, pe
        // principal ȘI pe penaltiesPaid; stres +8.
        missed.add((debt.id, newDay));
        final feeBani = (debt.monthly.bani * 0.02).round();
        final fee = Money(feeBani < 2000 ? 2000 : feeBani);
        penalties = penalties + fee;
        stats = stats.withDelta('stress', 8);
        newDebts.add(debt.copyWith(principal: debt.principal + fee));
      }
    }
    st = st.copyWith(
      cash: cash,
      debts: newDebts,
      paidBillsOnTime: paidOnTime,
      penaltiesPaid: penalties,
      stats: stats,
      missedBills: missed,
    );
  }

  // 3b. Restanțele se sting automat, cea mai veche prima, doar integral, când
  //     intră cash. Plata târzie NU contează „la timp" (paidBillsOnTime stă).
  final arrearsPaid = <String>[];
  {
    var cash = st.cash;
    final remaining = <(String, int)>[];
    for (final ar in st.arrears) {
      final def = c.recurringById(ar.$1);
      if (def != null && cash >= def.amount) {
        cash = cash - def.amount;
        arrearsPaid.add(ar.$1);
      } else {
        remaining.add(ar);
      }
    }
    st = st.copyWith(cash: cash, arrears: remaining);
    // Stres de restanță: +1 o singură dată pe zi cât timp mai există restanțe.
    if (remaining.isNotEmpty) {
      st = st.copyWith(stats: st.stats.withDelta('stress', 1));
    }
  }

  // 4. Efecte programate scadente azi, se declanșează O SINGURĂ DATĂ. Un
  //    efect declanșat poate programa altele (persistă). Colectăm notele +
  //    rezumatul delta pentru sumarul zilei și ledger-ul de lineage.
  final effectsFired = <(String, String)>[];
  {
    final toFire = [
      for (final se in st.scheduledEffects) if (se.fireOnDay <= newDay) se,
    ];
    final remaining = [
      for (final se in st.scheduledEffects) if (se.fireOnDay > newDay) se,
    ];
    st = st.copyWith(scheduledEffects: remaining);
    final firedRecords = [...st.firedEffects];
    for (final se in toFire) {
      final before = st;
      for (final eff in se.effects) {
        st = eff.apply(st, today: newDay, sourceEventId: se.sourceEventId);
      }
      final cashD = st.cash - before.cash;
      final fundD = st.emergencyFund - before.emergencyFund;
      final goalD = st.goalSavings - before.goalSavings;
      firedRecords.add(FiredEffect(
        day: newDay,
        note: se.note,
        cashDelta: cashD,
        fundDelta: fundD,
        goalDelta: goalD,
        sourceEventId: se.sourceEventId,
      ));
      effectsFired.add((se.note, _deltaSummary(cashD, fundD, goalD)));
    }
    st = st.copyWith(firedEffects: firedRecords);
  }

  // 5. Drift natural de stat: energia scade, stresul crește la descoperit,
  //    relațiile se erodează la fiecare a 3-a zi fără viață socială activă.
  {
    var stats = st.stats.withDelta('energy', -2);
    if (st.cash.isNegative) stats = stats.withDelta('stress', 1);
    if (newDay % 3 == 0 && !st.flags.contains('social')) {
      stats = stats.withDelta('relationships', -1);
    }
    // Presiune cuplată: bucle lente, evaluate secvențial (fiecare regulă vede
    // efectul precedentei) pe valorile de după driftul de bază.
    if (stats.stress > 70) stats = stats.withDelta('energy', -2);
    if (stats.energy < 25) stats = stats.withDelta('health', -1);
    if (stats.health < 35) stats = stats.withDelta('stress', 2);
    st = st.copyWith(stats: stats);
  }

  // 6. Directorul alege evenimentul zilei (sau zi liniștită). Bookkeeping-ul
  //    de director se scrie ACUM (la afișare); alegerea se aplică separat.
  final event = pickEvent(s: st, c: c, rng: directorRng, mode: st.mode);
  if (event != null) {
    var scheduledEvents = st.scheduledEvents;
    final due = dueScheduledEntry(st, c);
    if (due != null && due.$2 == event.id) {
      scheduledEvents = [...st.scheduledEvents]..remove(due);
    }
    st = st.copyWith(
      lastEventDay: newDay,
      lastEventCategory: event.category,
      lastEventDifficulty: event.difficulty,
      categoryCounts: {
        ...st.categoryCounts,
        event.category: (st.categoryCounts[event.category] ?? 0) + 1,
      },
      eventLastSeen: {...st.eventLastSeen, event.id: newDay},
      completedEvents: event.repeatable
          ? st.completedEvents
          : {...st.completedEvents, event.id},
      scheduledEvents: scheduledEvents,
    );
  }

  // 7. Contorul de zile în descoperit (ponderea „cash≥0" din scor).
  if (st.cash.isNegative) {
    st = st.copyWith(daysCashNegative: st.daysCashNegative + 1);
  }

  return DayResult(
    state: st,
    salaryReceived: salaryReceived,
    billsPaid: billsPaid,
    billsMissed: billsMissed,
    effectsFired: effectsFired,
    arrearsPaid: arrearsPaid,
    event: event,
  );
}

/// Decontează la finalul rundei orice [ScheduledEffect] neaplicat, altfel
/// consecințele cu `fireOnDay` > 30 s-ar pierde tăcut și amânarea ar fi gratuită.
LifeSimState settleRemainingEffects(LifeSimState s) {
  final toFire = s.scheduledEffects;
  var st = s.copyWith(scheduledEffects: const []);
  final firedRecords = [...st.firedEffects];
  for (final se in toFire) {
    final before = st;
    for (final eff in se.effects) {
      st = eff.apply(st, today: st.day, sourceEventId: se.sourceEventId);
    }
    final cashD = st.cash - before.cash;
    final fundD = st.emergencyFund - before.emergencyFund;
    final goalD = st.goalSavings - before.goalSavings;
    firedRecords.add(FiredEffect(
      day: st.day,
      note: se.note,
      cashDelta: cashD,
      fundDelta: fundD,
      goalDelta: goalD,
      sourceEventId: se.sourceEventId,
    ));
  }
  return st.copyWith(firedEffects: firedRecords);
}

/// Aplică alegerea [choiceIdx] la evenimentul [e]: efectele (cu lineage spre
/// [e]), înregistrează decizia și marchează evenimentul terminat.
LifeSimState applyChoice(
  LifeSimState s,
  LifeSimEvent e,
  int choiceIdx,
  LifeSimContent c,
) {
  var st = s;
  final choice = e.choices[choiceIdx];
  for (final eff in choice.effects) {
    st = eff.apply(st, today: st.day, sourceEventId: e.id);
  }
  return st.copyWith(
    decisions: [
      ...st.decisions,
      DecisionRecord(day: st.day, eventId: e.id, choiceIdx: choiceIdx),
    ],
    completedEvents: {...st.completedEvents, e.id},
  );
}

/// Transferă din cash pe plicuri (fond + obiectiv). Validat: sume nenegative
/// care nu depășesc cash-ul. Conservă suma totală (cash+fond+obiectiv).
LifeSimState allocateSalary(
  LifeSimState s, {
  required Money toFund,
  required Money toGoal,
}) {
  if (toFund.isNegative || toGoal.isNegative) {
    throw ArgumentError('alocările pe plicuri nu pot fi negative');
  }
  final total = toFund + toGoal;
  if (total > s.cash) {
    throw ArgumentError('alocare (${total.lei}) peste cash-ul disponibil '
        '(${s.cash.lei})');
  }
  return s.copyWith(
    cash: s.cash - total,
    emergencyFund: s.emergencyFund + toFund,
    goalSavings: s.goalSavings + toGoal,
  );
}

/// Plată anticipată pe o datorie din cash, apelată din UI. Validează suma
/// pozitivă, o plafonează la principal și la cash (cash-ul nu devine negativ
/// prin plăți voluntare). Dacă cash-ul e sub 50 lei nu se plătește nimic:
/// întoarce starea neschimbată.
LifeSimState payDebtEarly(LifeSimState s, String debtId, Money amount) {
  if (amount <= Money.zero) return s;
  if (s.cash < Money.fromLei(50)) return s;
  final idx = s.debts.indexWhere((d) => d.id == debtId);
  if (idx < 0) return s;
  var pay = amount;
  final principal = s.debts[idx].principal;
  if (pay > principal) pay = principal;
  if (pay > s.cash) pay = s.cash;
  if (pay <= Money.zero) return s;
  return PayDebt(id: debtId, amount: pay).apply(s, today: s.day);
}

/// Rezumat scurt al unui delta declanșat (semnul explicit ajută animația).
String _deltaSummary(Money cash, Money fund, Money goal) {
  String signed(Money m) => '${m.isNegative ? '' : '+'}${m.lei}';
  final parts = <String>[
    if (!cash.isZero) 'cash ${signed(cash)}',
    if (!fund.isZero) 'fond ${signed(fund)}',
    if (!goal.isZero) 'obiectiv ${signed(goal)}',
  ];
  return parts.isEmpty ? ', ' : parts.join(', ');
}
