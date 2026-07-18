/// Motorul de bandiți FinEdu, Beta-Bernoulli Thompson Sampling pur,
/// determinist dat un [Random] injectat. Zero dependențe native, zero Flutter.
library;

import 'dart:math';

/// O observație istorică a unui braț: ce s-a arătat și dacă a „mers".
/// [success] = proxy de ÎNVĂȚARE (tap + acțiune), nu engagement brut;
/// [ageDays] hrănește decay-ul (săptămânile vechi contează mai puțin).
class ArmObservation {
  const ArmObservation({
    required this.arm,
    required this.success,
    required this.ageDays,
  });

  final int arm;
  final bool success;
  final double ageDays;
}

/// Contorii Beta per braț derivați din istoric. Fiecare braț pornește la
/// Beta(1,1) (prior neutru); fiecare observație adaugă `weeklyDecay^(ageDays/7)`
/// la [alpha] (succes) sau [beta] (eșec), fereastra efectivă e ~8-10
/// săptămâni, deci banditul urmărește gustul de ACUM, nu media pe viață.
Map<int, ({double alpha, double beta})> deriveCounters(
  Iterable<ArmObservation> obs, {
  double weeklyDecay = 0.95,
}) {
  final acc = <int, ({double alpha, double beta})>{};
  for (final o in obs) {
    // Decay exponențial: pow(0.95, ageDays/7). Fresh ≈ 1, 70 zile ≈ 0,60.
    final w = pow(weeklyDecay, o.ageDays / 7).toDouble();
    final cur = acc[o.arm] ?? (alpha: 1.0, beta: 1.0);
    acc[o.arm] = o.success
        ? (alpha: cur.alpha + w, beta: cur.beta)
        : (alpha: cur.alpha, beta: cur.beta + w);
  }
  return acc;
}

/// Un eșantion dintr-o distribuție Beta(alpha, beta), via două eșantioane Gamma:
/// Beta = X/(X+Y) cu X~Gamma(alpha), Y~Gamma(beta). Determinist dat [rng].
double sampleBeta(double alpha, double beta, Random rng) {
  final x = _sampleGamma(alpha, rng);
  final y = _sampleGamma(beta, rng);
  final sum = x + y;
  // Ambele Gamma pot fi ~0 numeric la parametri mici; cădem pe 0,5 (neutru).
  return sum <= 0 ? 0.5 : x / sum;
}

/// Eșantion Gamma(shape, scale=1) prin metoda Marsaglia-Tsang, rapid, fără
/// respingeri costisitoare, cu boost standard pentru shape<1.
double _sampleGamma(double shape, Random rng) {
  if (shape < 1) {
    // Boost: Gamma(shape) = Gamma(shape+1) * U^(1/shape).
    return _sampleGamma(shape + 1, rng) * pow(rng.nextDouble(), 1 / shape);
  }
  final d = shape - 1.0 / 3.0;
  final c = 1.0 / sqrt(9.0 * d);
  while (true) {
    double x;
    double v;
    do {
      x = _gaussian(rng);
      v = 1.0 + c * x;
    } while (v <= 0);
    v = v * v * v;
    final u = rng.nextDouble();
    final x2 = x * x;
    // Squeeze rapid, apoi testul exact al log-verosimilității.
    if (u < 1.0 - 0.0331 * x2 * x2) return d * v;
    if (log(u) < 0.5 * x2 + d * (1.0 - v + log(v))) return d * v;
  }
}

/// N(0,1) prin Box-Muller (o singură valoare per apel; suficient aici).
double _gaussian(Random rng) {
  // u1 strict >0 ca log-ul să fie finit.
  final u1 = 1.0 - rng.nextDouble();
  final u2 = rng.nextDouble();
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
}

/// Alege un braț și întoarce propensity-ul (probabilitatea cu care politica
/// l-ar fi ales), cheia evaluării off-policy.
///
/// Cu probabilitate [epsilon]: braț uniform (podeaua de explorare, niciun
/// braț nu moare). Altfel: Thompson, eșantion Beta per braț, argmax.
/// propensity = epsilon/armCount + (1-epsilon) * pWin, unde pWin vine din
/// [mcSamples] repetări Monte-Carlo ale tragerii Thompson.
({int arm, double propensity}) pickArm({
  required Map<int, ({double alpha, double beta})> counters,
  required int armCount,
  required Random rng,
  double epsilon = 0.10,
  int mcSamples = 60,
}) {
  if (armCount <= 1) return (arm: 0, propensity: 1.0);

  ({double alpha, double beta}) counterFor(int a) =>
      counters[a] ?? (alpha: 1.0, beta: 1.0);

  int thompsonDraw() {
    var best = 0;
    var bestSample = -1.0;
    for (var a = 0; a < armCount; a++) {
      final c = counterFor(a);
      final s = sampleBeta(c.alpha, c.beta, rng);
      if (s > bestSample) {
        bestSample = s;
        best = a;
      }
    }
    return best;
  }

  // Alegerea reală: podeaua epsilon peste Thompson.
  final int chosen;
  if (rng.nextDouble() < epsilon) {
    chosen = rng.nextInt(armCount);
  } else {
    chosen = thompsonDraw();
  }

  // Monte-Carlo: cât de des câștigă fiecare braț sub politica Thompson pură.
  final wins = List<int>.filled(armCount, 0);
  for (var i = 0; i < mcSamples; i++) {
    wins[thompsonDraw()]++;
  }
  final pWin = wins[chosen] / mcSamples;
  final propensity = epsilon / armCount + (1 - epsilon) * pWin;
  return (arm: chosen, propensity: propensity);
}
