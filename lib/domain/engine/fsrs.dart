/// FSRS-6, memoria personalizată a conceptelor (înlocuiește Leitner v1).
/// Implementare proprie, Dart pur (formulele sunt publice), zero dependențe noi.
library;

import 'dart:math' as math;

/// Parametrii impliciti FSRS-6 (21 de greutăți, w0..w20), copiați verbatim
/// din py-fsrs (open-spaced-repetition, MIT) `DEFAULT_PARAMETERS`.
///
/// w0..w3  = stabilitatea inițială per notă (Again/Hard/Good/Easy).
/// w4,w5   = dificultatea inițială.  w6,w7 = actualizarea dificultății.
/// w8..w16 = stabilitatea la reamintire/uitare.  w17..w19 = termeni short-term.
/// w20     = decay-ul curbei uitării, optimizabil, noutatea FSRS-6 față de
///           FSRS-5, care avea decay fix -0,5.
const fsrsDefaultWeights = <double>[
  0.212, // w0
  1.2931, // w1
  2.3065, // w2
  8.2956, // w3
  6.4133, // w4
  0.8334, // w5
  3.0194, // w6
  0.001, // w7
  1.8722, // w8
  0.1666, // w9
  0.796, // w10
  1.4835, // w11
  0.0614, // w12
  0.2629, // w13
  1.6483, // w14
  0.6014, // w15
  1.8729, // w16
  0.5425, // w17
  0.0912, // w18
  0.0658, // w19
  0.1542, // w20 (FSRS_DEFAULT_DECAY)
];

/// Retenția-țintă pentru următoarea recapitulare. NU 0,90 (cramming), la
/// R=0,90 intervalul == stabilitatea; la R=0,83 intervalul e mai LUNG, deci
/// mai puține carduri pe zi (coadă prietenoasă, educație relaxată, nu examen).
const desiredRetention = 0.83;

/// Plafon de siguranță: chiar și un concept foarte stabil revine cel puțin o
/// dată la ~6 luni (nimic nu dispare complet din coadă).
const maxIntervalDays = 180;

// --- Constante derivate din greutăți (ca în py-fsrs: _DECAY = -w20). ---
// Ținute ca `final` (nu `const`) fiindcă se derivă din listă și dintr-un `pow`.
final double _decay = -fsrsDefaultWeights[20]; // = -0.1542
final double _factor = math.pow(0.9, 1 / _decay) - 1; // ≈ 0.980438

// Praguri de clampare, identice cu referința (STABILITY_MIN / MIN/MAX_DIFF).
const double _stabilityMin = 0.001;
const double _minDifficulty = 1.0;
const double _maxDifficulty = 10.0;

/// Starea de memorie a unui card: cele două variabile latente FSRS.
class FsrsMemory {
  const FsrsMemory({required this.stability, required this.difficulty});

  /// Stabilitatea S (zile): peste câte zile retenția scade la 90%.
  final double stability;

  /// Dificultatea D ∈ [1,10]: cât de greu e conceptul pentru ACEST user.
  final double difficulty;
}

/// Retrievabilitatea R ∈ (0,1]: probabilitatea de reamintire după [elapsedDays]
/// zile de la ultima recenzie, dată stabilitatea. Curba puterii FSRS-6:
///   R = (1 + FACTOR · t/S) ^ DECAY
/// R(0) = 1 și descrește monoton cu t (DECAY < 0). Expusă și pentru footer-ul
/// de transparență din UI.
double retrievability({required double stability, required double elapsedDays}) {
  final s = stability < _stabilityMin ? _stabilityMin : stability;
  return math.pow(1 + _factor * elapsedDays / s, _decay).toDouble();
}

/// Notează un card și întoarce noua memorie + intervalul (zile) până la
/// următoarea recapitulare.
///
/// Mapare 2 butoane → 2 note FSRS: „Știu" = Good (3), „Nu știu" = Again (1).
/// Renunțăm deliberat la Hard/Easy, UI-ul rămâne binar, prietenos pentru
/// adolescenți (deci hard_penalty / easy_bonus sunt mereu 1).
({FsrsMemory memory, int intervalDays}) fsrsGrade({
  FsrsMemory? memory,
  required bool known,
  required double elapsedDays,
}) {
  final rating = known ? 3 : 1;

  if (memory == null) {
    // Prima recenzie: S și D din formulele de inițializare (fără istoric).
    final s = _clampStability(_initialStability(rating));
    final d = _initialDifficulty(rating);
    return (
      memory: FsrsMemory(stability: s, difficulty: d),
      intervalDays: _nextInterval(s),
    );
  }

  // Recenzie ulterioară: întâi R din curba uitării, apoi S nou (calculat cu D
  // VECHI, exact ca în referință), apoi D nou prin mean-reversion.
  final r = retrievability(
    stability: memory.stability,
    elapsedDays: elapsedDays,
  );
  final newS = _clampStability(
    known
        ? _recallStability(memory.difficulty, memory.stability, r)
        : _forgetStability(memory.difficulty, memory.stability, r),
  );
  final newD = _nextDifficulty(memory.difficulty, rating);
  return (
    memory: FsrsMemory(stability: newS, difficulty: newD),
    intervalDays: _nextInterval(newS),
  );
}

/// Seed de migrare din cutia Leitner: la trecerea Leitner→FSRS „nimeni nu-și
/// pierde coada". Stabilitatea aproximează intervalul cutiei (1/3/7/21 zile),
/// dificultatea scade cu cutia (card ajuns sus = mai ușor pentru user).
FsrsMemory fsrsSeedFromBox(int box) => switch (box) {
      1 => const FsrsMemory(stability: 1.0, difficulty: 6.0),
      2 => const FsrsMemory(stability: 3.0, difficulty: 5.0),
      3 => const FsrsMemory(stability: 7.0, difficulty: 4.5),
      _ => const FsrsMemory(stability: 21.0, difficulty: 4.0),
    };

/// Bucket grosier de „cutie" derivat din stabilitate, păstrat DOAR ca să
/// supraviețuiască ordonarea `dueCards()` (box asc = materialul greu primul) și
/// semantica UI moștenite. NU intră în matematica FSRS.
int fsrsBoxBucket(double stability) => stability < 3
    ? 1
    : stability < 10
        ? 2
        : stability < 30
            ? 3
            : 4;

// ---------------------------------------------------------------------------
// Formulele FSRS-6 (private), fidele referinței py-fsrs.
// ---------------------------------------------------------------------------

double _clampStability(double s) => s < _stabilityMin ? _stabilityMin : s;

double _clampDifficulty(double d) => d < _minDifficulty
    ? _minDifficulty
    : (d > _maxDifficulty ? _maxDifficulty : d);

/// S0 = w[rating-1] (rating 1..4 → w0..w3).
double _initialStability(int rating) => fsrsDefaultWeights[rating - 1];

/// D0 = w4 − e^(w5·(rating−1)) + 1, prins în [1,10].
double _initialDifficulty(int rating) => _clampDifficulty(
      fsrsDefaultWeights[4] -
          math.exp(fsrsDefaultWeights[5] * (rating - 1)) +
          1,
    );

/// Actualizarea dificultății: linear damping + mean-reversion spre D0(Easy).
double _nextDifficulty(double d, int rating) {
  final w = fsrsDefaultWeights;
  final arg1 = w[4] - math.exp(w[5] * 3) + 1; // ținta = D0 pentru rating Easy
  final deltaD = -(w[6] * (rating - 3));
  final arg2 = d + (10.0 - d) * deltaD / 9.0; // linear damping
  return _clampDifficulty(w[7] * arg1 + (1 - w[7]) * arg2);
}

/// Stabilitatea după reamintire (calea Good; hard_penalty = easy_bonus = 1).
double _recallStability(double d, double s, double r) {
  final w = fsrsDefaultWeights;
  return (s *
          (1 +
              math.exp(w[8]) *
                  (11 - d) *
                  math.pow(s, -w[9]) *
                  (math.exp((1 - r) * w[10]) - 1)))
      .toDouble();
}

/// Stabilitatea după uitare (calea Again): min(termen lung, termen scurt).
/// Termenul scurt (~0,95·S) împiedică o cădere brutală după o singură ratare,
/// „post-lapse păstrează o fracțiune", nu resetează la inițial.
double _forgetStability(double d, double s, double r) {
  final w = fsrsDefaultWeights;
  final longTerm = w[11] *
      math.pow(d, -w[12]) *
      (math.pow(s + 1, w[13]) - 1) *
      math.exp((1 - r) * w[14]);
  final shortTerm = s / math.exp(w[17] * w[18]);
  return math.min(longTerm.toDouble(), shortTerm);
}

/// Intervalul următor pentru [desiredRetention]:
///   I = (S / FACTOR) · (r ^ (1/DECAY) − 1), rotunjit, prins în [1, max].
int _nextInterval(double stability) {
  final raw =
      (stability / _factor) * (math.pow(desiredRetention, 1 / _decay) - 1);
  final rounded = raw.round();
  return rounded < 1
      ? 1
      : (rounded > maxIntervalDays ? maxIntervalDays : rounded);
}
