/// Dobânda compusă, matematica din spatele simulatorului `param_sim`
/// (Unitatea 6). Model generic al unui obicei de economisire, nu al unui
/// produs anume (educație, nu consultanță).
library;

import 'dart:math' as math;

/// Soldul la finalul fiecărui an (index 0 = start, 1 = după primul an...),
/// cu depunere [monthly] la sfârșitul fiecărei luni și dobândă anuală
/// [annualRate] (ex. 0.06), capitalizată lunar.
List<double> compoundSeries({
  required double monthly,
  required double annualRate,
  required int years,
}) {
  final r = annualRate / 12;
  final series = <double>[0];
  var balance = 0.0;
  for (var year = 1; year <= years; year++) {
    for (var month = 0; month < 12; month++) {
      balance = balance * (1 + r) + monthly;
    }
    series.add(balance);
  }
  return series;
}

/// Aceleași depuneri, ținute „la saltea" (fără dobândă), curba de contrast:
/// divergența dintre cele două E lecția.
List<double> flatSeries({required double monthly, required int years}) {
  return [for (var year = 0; year <= years; year++) monthly * 12 * year];
}

/// Regula lui 72: în câți ani se dublează o sumă la [annualRate] (aproximare clasică).
double doublingYears(double annualRate) =>
    annualRate <= 0 ? double.infinity : 72 / (annualRate * 100);

/// Câți lei din soldul final sunt DOBÂNDĂ (nu depuneri), cifra-surpriză.
double interestEarned({
  required double monthly,
  required double annualRate,
  required int years,
}) {
  final total =
      compoundSeries(monthly: monthly, annualRate: annualRate, years: years)
          .last;
  return total - monthly * 12 * years;
}

/// Formatare prietenoasă pentru axele graficului (1.2k, 15k).
String compactLei(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    return k >= 10 ? '${k.round()}k' : '${(k * 10).round() / 10}k';
  }
  return '${value.round()}';
}

/// Un „nice ceiling" pentru axa Y (1/2/5 × 10^n ≥ max).
double niceCeiling(double max) {
  if (max <= 0) return 100;
  final exp = (math.log(max) / math.ln10).floor();
  final base = math.pow(10, exp).toDouble();
  for (final m in [1, 2, 5, 10]) {
    if (m * base >= max) return m * base;
  }
  return 10 * base;
}
