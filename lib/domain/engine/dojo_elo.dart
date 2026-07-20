/// Scam Dojo: Elo local-first pe mesaje individuale. Fiecare mesaj are un
/// rating care se auto-calibrează din răspunsuri; rundele țintesc p(succes) ≈ 0.75.
library;

import 'dart:math' as math;

const dojoStartRating = 1000;
const dojoTargetSuccess = 0.75;
const _userK = 32;
const _itemK = 16;

/// P(jucătorul răspunde corect la acest item).
double dojoExpected(int userRating, int itemRating) =>
    1 / (1 + math.pow(10, (itemRating - userRating) / 400));

/// Mișcarea de rating pentru un răspuns: jucătorul și itemul trag în direcții
/// opuse (un răspuns corect scade ratingul itemului: s-a dovedit mai ușor).
({int user, int item}) dojoUpdate({
  required int userRating,
  required int itemRating,
  required bool correct,
}) {
  final e = dojoExpected(userRating, itemRating);
  final s = correct ? 1.0 : 0.0;
  return (
    user: (userRating + _userK * (s - e)).round(),
    item: (itemRating - _itemK * (s - e)).round(),
  );
}

/// Prior de dificultate a conținutului (1..3) → ratingul inițial al itemului.
/// Se auto-calibrează din joc după aceea.
int dojoPriorRating(int difficulty) => switch (difficulty) {
  1 => 800,
  2 => 1000,
  _ => 1200,
};

// --- Belts (centurile de dojo)

const dojoBelts = [
  ('🤍', 'albă'),
  ('💛', 'galbenă'),
  ('🧡', 'portocalie'),
  ('💚', 'verde'),
  ('💙', 'albastră'),
  ('🤎', 'maro'),
  ('🖤', 'neagră'),
];

const _beltThresholds = [1050, 1150, 1250, 1350, 1450, 1550];

int dojoBeltIndex(int rating) {
  for (var i = 0; i < _beltThresholds.length; i++) {
    if (rating < _beltThresholds[i]) return i;
  }
  return dojoBelts.length - 1;
}

/// Ratingul necesar pentru centura următoare, sau null la centura neagră.
int? dojoNextBeltAt(int rating) {
  final i = dojoBeltIndex(rating);
  return i < _beltThresholds.length ? _beltThresholds[i] : null;
}

/// Progres (0..1) de la pragul centurii curente la următoarea.
double dojoBeltProgress(int rating) {
  final i = dojoBeltIndex(rating);
  if (i >= _beltThresholds.length) return 1;
  final floor = i == 0 ? dojoStartRating - 200 : _beltThresholds[i - 1];
  final ceil = _beltThresholds[i];
  return ((rating - floor) / (ceil - floor)).clamp(0.0, 1.0);
}

// --- Alegerea mesajelor din rundă

/// Alege [count] iteme pentru o rundă: preferă itemele cu succes așteptat
/// cel mai aproape de [dojoTargetSuccess], sare peste cele recente (cade pe
/// pool-ul complet la nevoie) și adaugă jitter ca rundele să difere.
List<T> dojoPickRound<T>(
  List<T> items, {
  required int Function(T) ratingOf,
  required String Function(T) idOf,
  required int userRating,
  Set<String> recent = const {},
  int count = 5,
  math.Random? rng,
}) {
  final random = rng ?? math.Random();
  var pool = items.where((i) => !recent.contains(idOf(i))).toList();
  if (pool.length < count) pool = [...items];

  final scored = [
    for (final item in pool)
      (
        item: item,
        score:
            (dojoExpected(userRating, ratingOf(item)) - dojoTargetSuccess)
                .abs() +
            random.nextDouble() * 0.15,
      ),
  ]..sort((a, b) => a.score.compareTo(b.score));

  final picked = [for (final s in scored.take(count)) s.item]..shuffle(random);
  return picked;
}
