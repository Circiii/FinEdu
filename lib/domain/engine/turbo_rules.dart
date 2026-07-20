/// Turbo Buget, mașină de scor pură pentru jocul de sortare need/want/save
/// de 45s: combo recompensează șiruri de răspunsuri corecte, 3 vieți termină
/// runda devreme, timer-ul o termină altfel (gestionat de UI).
library;

const turboSeconds = 45;
const turboLives = 3;

/// Plafon pentru bonusul de combo, ca un șir lung să nu strivească punctele de bază.
const _maxComboBonus = 5;

class TurboState {
  const TurboState({
    this.score = 0,
    this.combo = 0,
    this.lives = turboLives,
    this.answered = 0,
    this.correct = 0,
  });

  final int score;
  final int combo; // șirul curent de răspunsuri corecte
  final int lives;
  final int answered;
  final int correct;

  bool get over => lives <= 0;

  /// Punctele pe care le-ar câștiga URMĂTORUL răspuns corect (pastila de combo).
  int get nextPoints =>
      10 + 2 * (combo < _maxComboBonus ? combo : _maxComboBonus);
}

/// Aplică un card sortat. Corect: score += 10 + bonus de combo; greșit:
/// combo se resetează și se pierde o viață (game over la 0).
TurboState applyAnswer(TurboState s, {required bool isCorrect}) {
  if (isCorrect) {
    return TurboState(
      score: s.score + s.nextPoints,
      combo: s.combo + 1,
      lives: s.lives,
      answered: s.answered + 1,
      correct: s.correct + 1,
    );
  }
  return TurboState(
    score: s.score,
    combo: 0,
    lives: s.lives - 1,
    answered: s.answered + 1,
    correct: s.correct,
  );
}
