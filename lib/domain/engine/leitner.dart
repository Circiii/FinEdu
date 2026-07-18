/// Intervale Leitner (1/3/7/21 zile), FSRS a înlocuit logica de notare,
/// dar acest tabel supraviețuiește ca bucket-ul `box` derivat din stability
/// (vezi fsrs.dart).
library;

const leitnerIntervals = <int, int>{1: 1, 2: 3, 3: 7, 4: 21};

/// XP per dificultate de lecție: 15/20/25.
int lessonXp(String difficulty) => switch (difficulty) {
      'beginner' => 15,
      'intermediate' => 20,
      _ => 25,
    };

/// Nivel din XP persistat: 300 XP per nivel, nivel indexat de la 1.
int levelForXp(int xp) => xp ~/ 300 + 1;

int xpInLevel(int xp) => xp % 300;
