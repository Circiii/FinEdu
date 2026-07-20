/// Scor transparent pentru „30 de Zile", 4 dimensiuni, ponderi 30/30/20/20.
/// Niciodată clasament pe cash-ul final: fiecare factor de cash e plafonat,
/// ca un run care doar tezaurizează bani să nu învingă unul echilibrat.
library;

import 'life_sim_content.dart';
import 'life_sim_state.dart';
import 'money.dart';

/// Praguri de referință (bani). Peste ele, „mai mult cash" nu mai adaugă scor,
/// exact ce rupe monotonia pe cash.
const _bufferRefBani = 50000; // 500 lei tampon „sănătos"
const _fundRefBani = 150000; // 1500 lei ≈ o lună de plasă de siguranță
const _debtRefBani = 200000; // 2000 lei datorie „grea"
const _penaltyRefBani = 50000; // 500 lei penalizări = factor 0

class LifeSimScore {
  const LifeSimScore({
    required this.control,
    required this.rezilienta,
    required this.obiective,
    required this.echilibru,
    required this.total,
    required this.endingId,
  });

  final int control;
  final int rezilienta;
  final int obiective;
  final int echilibru;
  final int total;
  final String endingId;

  Map<String, dynamic> toJson() => {
    'control': control,
    'rezilienta': rezilienta,
    'obiective': obiective,
    'echilibru': echilibru,
    'total': total,
    'endingId': endingId,
  };
}

double _ratio(num part, num whole) => whole <= 0 ? 1.0 : part / whole;

double _cap(num v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v.toDouble());

int _pct(double x) => (x * 100).round().clamp(0, 100);

LifeSimScore score(LifeSimState s, LifeSimContent c) {
  final billsAttempted = s.paidBillsOnTime + s.missedBills.length;
  final billsRatio = _ratio(s.paidBillsOnTime, billsAttempted);

  final daysElapsed = s.day <= 0 ? 1 : s.day;
  final cashPositiveShare = _cap(1 - s.daysCashNegative / daysElapsed);
  final penaltyFactor = _cap(1 - s.penaltiesPaid.bani / _penaltyRefBani);

  // --- Control financiar: facturi la timp + cash gestionabil + fără penalizări.
  final control = _pct(
    0.5 * billsRatio + 0.3 * cashPositiveShare + 0.2 * penaltyFactor,
  );

  // --- Reziliență: fond de urgență + datorie mică + tampon rămas (plafonat).
  final fundFactor = _cap(s.emergencyFund.bani / _fundRefBani);
  final debtFactor = _cap(1 - s.totalDebt.bani / _debtRefBani);
  final bufferFactor = _cap(s.cash.bani / _bufferRefBani); // negativ → 0
  final rezilienta = _pct(
    0.5 * fundFactor + 0.3 * debtFactor + 0.2 * bufferFactor,
  );

  // --- Obiective: progres obiectiv + reducerea datoriei + consecvență facturi.
  final goalProgress = s.goalTarget.bani > 0
      ? _cap(s.goalSavings.bani / s.goalTarget.bani)
      : (s.goalSavings.bani > 0 ? 1.0 : 0.0);
  final initialDebt = _initialDebt(s, c);
  final debtReduction = initialDebt.bani > 0
      ? _cap((initialDebt.bani - s.totalDebt.bani) / initialDebt.bani)
      : 1.0;
  final obiective = _pct(
    0.6 * goalProgress + 0.25 * debtReduction + 0.15 * billsRatio,
  );

  // --- Echilibru de viață: media celor 4 stat-uri (stresul inversat, un stres
  //     mic e bun). Zero cash aici: banii nu cumpără echilibru.
  final echilibru =
      ((s.stats.health +
                  s.stats.energy +
                  s.stats.relationships +
                  (100 - s.stats.stress)) /
              4)
          .round()
          .clamp(0, 100);

  final total =
      (0.30 * control + 0.30 * rezilienta + 0.20 * obiective + 0.20 * echilibru)
          .round()
          .clamp(0, 100);

  final endingId = _pickEnding(
    c,
    control: control,
    rezilienta: rezilienta,
    obiective: obiective,
    echilibru: echilibru,
    total: total,
  );

  return LifeSimScore(
    control: control,
    rezilienta: rezilienta,
    obiective: obiective,
    echilibru: echilibru,
    total: total,
    endingId: endingId,
  );
}

/// Datoria inițială a rolului (referință pentru „reducerea datoriei").
Money _initialDebt(LifeSimState s, LifeSimContent c) {
  final role = c.roleById(s.roleId);
  if (role == null) return Money.zero;
  return role.debts.fold(Money.zero, (sum, d) => sum + d.principal);
}

/// Primul final ale cărui praguri sunt TOATE atinse (ordinea din endings.json
/// contează). Fallback: ultimul final (catch-all) sau un id gol.
String _pickEnding(
  LifeSimContent c, {
  required int control,
  required int rezilienta,
  required int obiective,
  required int echilibru,
  required int total,
}) {
  for (final e in c.endings) {
    if (control >= e.minControl &&
        rezilienta >= e.minRezilienta &&
        obiective >= e.minObiective &&
        echilibru >= e.minEchilibru &&
        total >= e.minTotal) {
      return e.id;
    }
  }
  return c.endings.isEmpty ? '' : c.endings.last.id;
}
