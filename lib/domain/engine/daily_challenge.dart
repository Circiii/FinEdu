/// Provocarea Zilei, pure rules, mecanica stil Wordle: UN puzzle pe zi,
/// la fel pentru toți, determinist din dată.
///
/// Statisticile comunității („X% au răspuns ca tine") vin cu backend-ul;
/// tot ce e aici funcționează complet offline.
library;

enum DailyFormat { price, myth, dilemma }

/// Zile de la epoch Unix pentru o cheie `yyyy-MM-dd` (stabil UTC: cheia e
/// deja în timp local, nu mai trebuie calcul de fus orar aici).
int epochDays(String day) =>
    DateTime.parse(day).difference(DateTime.parse('1970-01-01')).inDays;

/// Formatul zilei rotește price → myth → dilemma.
DailyFormat formatFor(String day) =>
    DailyFormat.values[epochDays(day) % DailyFormat.values.length];

/// Index în pool-ul formatului zilei. Zile consecutive cu același format
/// (la 3 zile distanță) avansează pool-ul cu unu; se reia când conținutul se termină.
int puzzleIndexFor(String day, int poolSize) {
  assert(poolSize > 0);
  return (epochDays(day) ~/ DailyFormat.values.length) % poolSize;
}

/// Puncte pentru o ghicire de preț, după apropierea relativă. 4 iteme/zi → max 100.
int pricePoints({required int guess, required int actual}) {
  assert(actual > 0);
  final err = (guess - actual).abs() / actual;
  if (err <= 0.05) return 25;
  if (err <= 0.15) return 20;
  if (err <= 0.30) return 12;
  if (err <= 0.50) return 5;
  return 0;
}

/// Tile de share fără spoiler pentru o ghicire (ideea grilei Wordle).
String priceEmoji(int points) => switch (points) {
  25 => '🎯',
  20 => '🟩',
  12 || 5 => '🟨',
  _ => '⬜',
};

/// Runda myth: 3 afirmații; all-correct rotunjește la 100.
int mythScore(int correct) => correct >= 3 ? 100 : correct * 33;

String mythEmoji({required bool correct}) => correct ? '🟩' : '🟥';

/// Bonusul zilnic rotativ din hub („azi: ghinde duble la ..."), dublează
/// ghindele primei runde din zi la un singur joc. Rotație pură, fără config.
const arcadeGames = ['dojo', 'daily', 'turbo'];

String dailyBonusGame(String day) =>
    arcadeGames[(epochDays(day) + 1) % arcadeGames.length];
