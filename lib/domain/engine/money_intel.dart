/// Money intelligence, banii înțeleși 100% local, zero AI mare. Matematică
/// deterministă, praguri conservatoare; sub incertitudine, motorul SE ABȚINE.
library;

import 'dart:math';

/// Mediana unei liste, centrul robust al distribuției. De ce mediana și nu
/// media: rezistă la outlieri pe eșantioane mici (o cheltuială de vacanță ar
/// trage media oriunde; mediana nici nu clipește).
double robustCenter(List<double> xs) {
  if (xs.isEmpty) return 0;
  final sorted = [...xs]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// MAD-ul scalat (Median Absolute Deviation × 1,4826), împrăștierea robustă.
/// Factorul 1,4826 îl aduce la scara deviației standard, deci pragurile
/// „k×spread" se citesc ca „k sigma", dar fără să fie umflate de outlieri.
double robustSpread(List<double> xs) {
  if (xs.isEmpty) return 0;
  final center = robustCenter(xs);
  final deviations = [for (final x in xs) (x - center).abs()];
  return robustCenter(deviations) * 1.4826;
}

/// E [amount] o anomalie față de istoricul propriu al categoriei?
///
/// Regula: |amount − mediană| > k × MAD scalat (k=3,5, prag conservator).
/// Porți: minim 6 observații. Când MAD=0 (istoric constant, ex. abonament
/// de 20 lei), cade pe o regulă simplă: dublul medianei ȘI ≥30 lei peste ea.
bool isAnomaly({
  required double amount,
  required List<double> history,
  double k = 3.5,
}) {
  if (history.length < 6) return false;
  final center = robustCenter(history);
  final spread = robustSpread(history);
  if (spread > 0) return (amount - center).abs() > k * spread;
  return amount > 2 * center && amount > center + 30;
}

/// „Liber de cheltuit", scădere pură, documentată ca atare. safe = buget −
/// cheltuit − recurente − contribuții la obiective, tăiat la ≥0. perDay =
/// safe / max(daysLeft, 1). Atât, balanță minus promisiuni, nu AI.
({double safe, double perDay}) safeToSpend({
  required double budget,
  required double spentSoFar,
  required double recurringDue,
  required double goalContributions,
  required int daysLeft,
}) {
  final safe = (budget - spentSoFar - recurringDue - goalContributions).clamp(
    0.0,
    double.infinity,
  );
  return (safe: safe, perDay: safe / max(daysLeft, 1));
}

/// Un tipar de plată detectat în jurnal, semantica etichetei e „posibil
/// recurent", niciodată un verdict. [confidence] = numărul de apariții.
class RecurringGuess {
  const RecurringGuess({
    required this.category,
    required this.medianAmount,
    required this.periodDays,
    required this.confidence,
  });

  /// Categoria e proxy-ul nostru de comerciant (câmpul merchant există în
  /// schemă dar fluxul manual nu-l populează).
  final String category;
  final double medianAmount;
  final int periodDays;
  final int confidence;
}

/// Caută ritmuri de plată în jurnal: aceeași categorie, sume aproape identice
/// (±10% din mediană), la intervale ~săptămânale (6-8 zile) sau ~lunare
/// (26-35 zile), de minim 3 ori.
///
/// Praguri deliberat stricte: un fals pozitiv („Abonament nedeclarat?" la
/// mersul la cinema) costă mai multă încredere decât câștigă un adevărat
/// pozitiv. Abținerea e o decizie.
List<RecurringGuess> detectRecurring(
  List<({String category, double amount, DateTime date})> tx,
) {
  final byCategory = <String, List<({double amount, DateTime date})>>{};
  for (final t in tx) {
    (byCategory[t.category] ??= []).add((amount: t.amount, date: t.date));
  }

  final out = <RecurringGuess>[];
  byCategory.forEach((category, entries) {
    if (entries.length < 3) return; // sub 3 apariții nu există „ritm"
    entries.sort((a, b) => a.date.compareTo(b.date));

    final gaps = <double>[
      for (var i = 1; i < entries.length; i++)
        entries[i].date.difference(entries[i - 1].date).inDays.toDouble(),
    ];
    // Două plăți în aceeași zi rup periodicitatea, categoria e prea
    // aglomerată ca să fie un abonament; ne abținem.
    if (gaps.any((g) => g < 1)) return;

    final medianGap = robustCenter(gaps);
    final weekly = medianGap >= 6 && medianGap <= 8;
    final monthly = medianGap >= 26 && medianGap <= 35;
    if (!weekly && !monthly) return;
    // Consistență: fiecare interval la ±3 zile de mediană (abonamentele reale
    // alunecă puțin, weekendurile mută debitări).
    if (gaps.any((g) => (g - medianGap).abs() > 3)) return;

    final medianAmount = robustCenter([for (final e in entries) e.amount]);
    if (medianAmount <= 0) return;
    // Sumă stabilă: ±10% din mediană pentru FIECARE apariție.
    if (entries.any(
      (e) => (e.amount - medianAmount).abs() > medianAmount * 0.10,
    )) {
      return;
    }

    out.add(
      RecurringGuess(
        category: category,
        medianAmount: medianAmount,
        periodDays: medianGap.round(),
        confidence: entries.length,
      ),
    );
  });

  // Cele mai multe apariții primele (cea mai sigură ghicire); egalitate →
  // alfabetic, ca rezultatul să fie determinist.
  out.sort((a, b) {
    final byConf = b.confidence.compareTo(a.confidence);
    return byConf != 0 ? byConf : a.category.compareTo(b.category);
  });
  return out;
}

/// Bucket-ul de sumă pe scară log (banii de buzunar trăiesc pe ordine de
/// mărime, nu pe lei individuali): <10, 10-25, 25-50, 50-100, >100.
int _amountBucket(double amount) {
  if (amount < 10) return 0;
  if (amount < 25) return 1;
  if (amount < 50) return 2;
  if (amount < 100) return 3;
  return 4;
}

/// Sugerează o categorie pentru o cheltuială nouă, sau SE ABȚINE (-1).
///
/// Naive Bayes cu două trăsături (bucket de sumă + ziua săptămânii), netezire
/// Laplace, prioruri din frecvență. Fără text de comerciant, „cât + când" e
/// tot ce știm cinstit.
///
/// Întoarce indexul doar dacă posteriorul câștigătorului e ≥ [minConfidence]
/// ȘI istoricul are ≥15 observații utile; altfel -1.
int categorySuggestion({
  required double amount,
  required int weekday,
  required List<({String category, double amount, int weekday})> history,
  required List<String> categories,
  double minConfidence = 0.55,
}) {
  if (categories.isEmpty) return -1;
  // Doar observațiile din categoriile propuse contează (restul nu pot fi
  // nici sugerate, nici comparate cinstit).
  final usable = history.where((h) => categories.contains(h.category)).toList();
  if (usable.length < 15) return -1; // prea puțin istoric ca să merite o părere

  final bucket = _amountBucket(amount);
  final countByCat = <String, int>{};
  final bucketByCat = <String, int>{};
  final weekdayByCat = <String, int>{};
  for (final h in usable) {
    countByCat[h.category] = (countByCat[h.category] ?? 0) + 1;
    if (_amountBucket(h.amount) == bucket) {
      bucketByCat[h.category] = (bucketByCat[h.category] ?? 0) + 1;
    }
    if (h.weekday == weekday) {
      weekdayByCat[h.category] = (weekdayByCat[h.category] ?? 0) + 1;
    }
  }

  // P(cat) × P(bucket|cat) × P(zi|cat), fiecare cu Laplace (+1), nicio
  // categorie nu are probabilitate zero, deci scorurile rămân comparabile.
  final scores = <double>[];
  var total = 0.0;
  for (final cat in categories) {
    final n = countByCat[cat] ?? 0;
    final prior = (n + 1) / (usable.length + categories.length);
    final pBucket = ((bucketByCat[cat] ?? 0) + 1) / (n + 5);
    final pWeekday = ((weekdayByCat[cat] ?? 0) + 1) / (n + 7);
    final s = prior * pBucket * pWeekday;
    scores.add(s);
    total += s;
  }
  if (total <= 0) return -1;

  var best = 0;
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[best]) best = i;
  }
  final posterior = scores[best] / total;
  return posterior >= minConfidence ? best : -1;
}
