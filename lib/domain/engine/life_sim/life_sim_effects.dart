/// Efecte tipizate pentru „30 de Zile", fiecare efect mută starea ([apply])
/// și se (de)serializează.
///
/// Reguli: cash-ul poate coborî sub zero (descoperitul e urmărit în scor);
/// fondul și obiectivul se taie la 0; stat-urile se clampează 0-100; fiecare
/// retragere din fond se contorizează în [LifeSimState.fundUsed].
///
/// [sourceEventId] curge prin [apply] pentru lineage-ul din debrief.
library;

import 'money.dart';
import 'life_sim_state.dart';

Money _min(Money a, Money b) => a <= b ? a : b;

/// Rezolvă un text care poate fi deja String (round-trip din stare) sau un
/// nod bilingv {ro,en} (parsare din conținut).
String _resolveText(dynamic node, String locale) => node is String
    ? node
    : ((node as Map)[locale] ?? node['ro']) as String;

sealed class LifeEffect {
  const LifeEffect();

  /// Aplică efectul, întorcând o stare nouă. [today] e ziua curentă (pentru
  /// programări); [sourceEventId] e decizia-sursă, propagată la efectele
  /// programate.
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId});

  Map<String, dynamic> toJson();

  factory LifeEffect.fromJson(Map<String, dynamic> j, {String locale = 'ro'}) {
    final type = j['type'] as String;
    switch (type) {
      case 'cash':
        return CashDelta(Money.fromJson(j['delta'] as int));
      case 'fund':
        return FundDelta(Money.fromJson(j['delta'] as int));
      case 'goal':
        return GoalDelta(Money.fromJson(j['delta'] as int));
      case 'stat':
        return StatDelta(j['stat'] as String, j['delta'] as int);
      case 'jobStability':
        return JobStabilityDelta(j['delta'] as int);
      case 'createDebt':
        return CreateDebt(
          id: j['id'] as String,
          principal: Money.fromJson(j['principal'] as int),
          monthly: Money.fromJson(j['monthly'] as int),
          dueDay: j['due_day'] as int,
          interestFreeUntil: j['interest_free_until'] as int?,
        );
      case 'payDebt':
        return PayDebt(
          id: j['id'] as String,
          amount: j['amount'] == null
              ? null
              : Money.fromJson(j['amount'] as int),
          full: (j['full'] as bool?) ?? false,
        );
      case 'addRecurring':
        return AddRecurring(j['id'] as String);
      case 'removeRecurring':
        return RemoveRecurring(j['id'] as String);
      case 'setFlag':
        return SetFlag(j['flag'] as String);
      case 'clearFlag':
        return ClearFlag(j['flag'] as String);
      case 'scheduleEffect':
        return ScheduleEffect(
          delayDays: j['delay_days'] as int,
          effects: [
            for (final e in (j['effects'] as List).cast<Map<String, dynamic>>())
              LifeEffect.fromJson(e, locale: locale),
          ],
          note: _resolveText(j['note'], locale),
        );
      case 'scheduleEvent':
        return ScheduleEvent(
          delayDays: j['delay_days'] as int,
          eventId: j['event_id'] as String,
        );
      default:
        throw FormatException('efect necunoscut: $type');
    }
  }
}

class CashDelta extends LifeEffect {
  const CashDelta(this.delta);
  final Money delta;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(cash: s.cash + delta);
  @override
  Map<String, dynamic> toJson() => {'type': 'cash', 'delta': delta.toJson()};
}

class FundDelta extends LifeEffect {
  const FundDelta(this.delta);
  final Money delta;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) {
    final newFund = (s.emergencyFund + delta).clampAtZero();
    // Cât s-a retras efectiv, ținând cont de tăierea la 0.
    final used = s.emergencyFund - newFund;
    return s.copyWith(
      emergencyFund: newFund,
      fundUsed: used.isNegative ? s.fundUsed : s.fundUsed + used,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'fund', 'delta': delta.toJson()};
}

class GoalDelta extends LifeEffect {
  const GoalDelta(this.delta);
  final Money delta;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(goalSavings: (s.goalSavings + delta).clampAtZero());
  @override
  Map<String, dynamic> toJson() => {'type': 'goal', 'delta': delta.toJson()};
}

class StatDelta extends LifeEffect {
  const StatDelta(this.stat, this.delta);
  final String stat;
  final int delta;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(stats: s.stats.withDelta(stat, delta));
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'stat', 'stat': stat, 'delta': delta};
}

class JobStabilityDelta extends LifeEffect {
  const JobStabilityDelta(this.delta);
  final int delta;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(jobStability: (s.jobStability + delta).clamp(0, 100));
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'jobStability', 'delta': delta};
}

class CreateDebt extends LifeEffect {
  const CreateDebt({
    required this.id,
    required this.principal,
    required this.monthly,
    required this.dueDay,
    this.interestFreeUntil,
  });
  final String id;
  final Money principal;
  final Money monthly;
  final int dueDay;
  final int? interestFreeUntil;

  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) {
    // Id deja existent → nu dublăm datoria (idempotent la re-aplicare).
    if (s.debts.any((d) => d.id == id)) return s;
    return s.copyWith(debts: [
      ...s.debts,
      DebtState(
        id: id,
        principal: principal,
        monthly: monthly,
        dueDay: dueDay,
        interestFreeUntil: interestFreeUntil,
      ),
    ]);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'createDebt',
        'id': id,
        'principal': principal.toJson(),
        'monthly': monthly.toJson(),
        'due_day': dueDay,
        if (interestFreeUntil != null) 'interest_free_until': interestFreeUntil,
      };
}

/// Plată extra pe o datorie (din cash). Cu [full] stinge tot principalul;
/// altfel plătește [amount], plafonat la principalul rămas.
class PayDebt extends LifeEffect {
  const PayDebt({required this.id, this.amount, this.full = false});
  final String id;
  final Money? amount;
  final bool full;

  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) {
    final idx = s.debts.indexWhere((d) => d.id == id);
    if (idx < 0) return s; // datorie inexistentă → no-op
    final debt = s.debts[idx];
    final pay = full
        ? debt.principal
        : _min(amount ?? Money.zero, debt.principal);
    final newPrincipal = debt.principal - pay;
    final newDebts = [...s.debts];
    if (newPrincipal <= Money.zero) {
      newDebts.removeAt(idx);
    } else {
      newDebts[idx] = debt.copyWith(principal: newPrincipal);
    }
    return s.copyWith(cash: s.cash - pay, debts: newDebts);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'payDebt',
        'id': id,
        if (amount != null) 'amount': amount!.toJson(),
        if (full) 'full': true,
      };
}

class AddRecurring extends LifeEffect {
  const AddRecurring(this.id);
  final String id;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.bills.contains(id) ? s : s.copyWith(bills: [...s.bills, id]);
  @override
  Map<String, dynamic> toJson() => {'type': 'addRecurring', 'id': id};
}

class RemoveRecurring extends LifeEffect {
  const RemoveRecurring(this.id);
  final String id;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(bills: s.bills.where((b) => b != id).toList());
  @override
  Map<String, dynamic> toJson() => {'type': 'removeRecurring', 'id': id};
}

class SetFlag extends LifeEffect {
  const SetFlag(this.flag);
  final String flag;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.flags.contains(flag) ? s : s.copyWith(flags: {...s.flags, flag});
  @override
  Map<String, dynamic> toJson() => {'type': 'setFlag', 'flag': flag};
}

class ClearFlag extends LifeEffect {
  const ClearFlag(this.flag);
  final String flag;
  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(flags: {...s.flags}..remove(flag));
  @override
  Map<String, dynamic> toJson() => {'type': 'clearFlag', 'flag': flag};
}

/// Programează un pachet de efecte peste [delayDays] zile, motorul
/// consecințelor întârziate. Nota (deja rezolvată la locale) e afișată în
/// sumarul zilei când efectul se declanșează.
class ScheduleEffect extends LifeEffect {
  const ScheduleEffect({
    required this.delayDays,
    required this.effects,
    required this.note,
  });
  final int delayDays;
  final List<LifeEffect> effects;
  final String note;

  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(scheduledEffects: [
        ...s.scheduledEffects,
        ScheduledEffect(
          fireOnDay: today + delayDays,
          effects: effects,
          note: note,
          sourceEventId: sourceEventId,
        ),
      ]);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'scheduleEffect',
        'delay_days': delayDays,
        'effects': [for (final e in effects) e.toJson()],
        'note': note,
      };
}

/// Programează un eveniment-consecință peste [delayDays] zile, va fi ridicat
/// cu PRIORITATE de director (nu trece prin ruleta de zi liniștită).
class ScheduleEvent extends LifeEffect {
  const ScheduleEvent({required this.delayDays, required this.eventId});
  final int delayDays;
  final String eventId;

  @override
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId}) =>
      s.copyWith(scheduledEvents: [
        ...s.scheduledEvents,
        (today + delayDays, eventId),
      ]);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'scheduleEvent', 'delay_days': delayDays, 'event_id': eventId};
}
