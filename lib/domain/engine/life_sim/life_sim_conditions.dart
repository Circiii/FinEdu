/// Condiții tipizate de eligibilitate pentru evenimentele din „30 de Zile".
///
/// Ierarhie sealed: fiecare condiție se evaluează pe o stare ([eval]) și se
/// parsează din JSON ([LifeCondition.fromJson]). Un tip necunoscut aruncă
/// [FormatException], prins de validatorul de conținut înainte de jucător.
library;

import 'money.dart';
import 'life_sim_state.dart';

sealed class LifeCondition {
  const LifeCondition();

  bool eval(LifeSimState s);

  factory LifeCondition.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String;
    switch (type) {
      case 'statAbove':
        return StatAbove(j['stat'] as String, j['x'] as int);
      case 'statBelow':
        return StatBelow(j['stat'] as String, j['x'] as int);
      case 'cashAbove':
        return CashAbove(Money.fromJson(j['amount'] as int));
      case 'cashBelow':
        return CashBelow(Money.fromJson(j['amount'] as int));
      case 'fundAbove':
        return FundAbove(Money.fromJson(j['amount'] as int));
      case 'fundBelow':
        return FundBelow(Money.fromJson(j['amount'] as int));
      case 'debtAbove':
        return DebtAbove(Money.fromJson(j['amount'] as int));
      case 'dayRange':
        return DayRange(j['min'] as int, j['max'] as int);
      case 'hasFlag':
        return HasFlag(j['flag'] as String);
      case 'notFlag':
        return NotFlag(j['flag'] as String);
      case 'roleIs':
        return RoleIs((j['roles'] as List).cast<String>());
      case 'completedEvent':
        return CompletedEvent(j['id'] as String);
      case 'madeChoice':
        return MadeChoice(j['event_id'] as String, j['choice_idx'] as int);
      case 'hasRecurring':
        return HasRecurring(j['id'] as String);
      default:
        throw FormatException('condiție necunoscută: $type');
    }
  }
}

class StatAbove extends LifeCondition {
  const StatAbove(this.stat, this.x);
  final String stat;
  final int x;
  @override
  bool eval(LifeSimState s) => s.stats.get(stat) > x;
}

class StatBelow extends LifeCondition {
  const StatBelow(this.stat, this.x);
  final String stat;
  final int x;
  @override
  bool eval(LifeSimState s) => s.stats.get(stat) < x;
}

class CashAbove extends LifeCondition {
  const CashAbove(this.amount);
  final Money amount;
  @override
  bool eval(LifeSimState s) => s.cash > amount;
}

class CashBelow extends LifeCondition {
  const CashBelow(this.amount);
  final Money amount;
  @override
  bool eval(LifeSimState s) => s.cash < amount;
}

class FundAbove extends LifeCondition {
  const FundAbove(this.amount);
  final Money amount;
  @override
  bool eval(LifeSimState s) => s.emergencyFund > amount;
}

class FundBelow extends LifeCondition {
  const FundBelow(this.amount);
  final Money amount;
  @override
  bool eval(LifeSimState s) => s.emergencyFund < amount;
}

/// Datoria TOTALĂ (suma principalelor) peste prag.
class DebtAbove extends LifeCondition {
  const DebtAbove(this.amount);
  final Money amount;
  @override
  bool eval(LifeSimState s) => s.totalDebt > amount;
}

class DayRange extends LifeCondition {
  const DayRange(this.min, this.max);
  final int min;
  final int max;
  @override
  bool eval(LifeSimState s) => s.day >= min && s.day <= max;
}

class HasFlag extends LifeCondition {
  const HasFlag(this.flag);
  final String flag;
  @override
  bool eval(LifeSimState s) => s.flags.contains(flag);
}

class NotFlag extends LifeCondition {
  const NotFlag(this.flag);
  final String flag;
  @override
  bool eval(LifeSimState s) => !s.flags.contains(flag);
}

class RoleIs extends LifeCondition {
  const RoleIs(this.roles);
  final List<String> roles;
  @override
  bool eval(LifeSimState s) => roles.contains(s.roleId);
}

class CompletedEvent extends LifeCondition {
  const CompletedEvent(this.id);
  final String id;
  @override
  bool eval(LifeSimState s) => s.completedEvents.contains(id);
}

class MadeChoice extends LifeCondition {
  const MadeChoice(this.eventId, this.choiceIdx);
  final String eventId;
  final int choiceIdx;
  @override
  bool eval(LifeSimState s) =>
      s.decisions.any((d) => d.eventId == eventId && d.choiceIdx == choiceIdx);
}

class HasRecurring extends LifeCondition {
  const HasRecurring(this.id);
  final String id;
  @override
  bool eval(LifeSimState s) => s.bills.contains(id);
}
