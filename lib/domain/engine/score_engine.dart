/// Scorul FinEdu (0-100), sănătatea financiară din comportament, portat
/// 1:1 din formula web: buget 25p, economisire 25p (țintă 20% din buget),
/// streak 15p (max 21 zile), consistență 15p (max 10 tranzacții/lună),
/// învățare 10p, diversitate 10p (max 6 categorii). Total clamp 1..100.
///
/// O SINGURĂ autoritate a scorului, orice afișare derivă din [computeScore].
library;

class ScoreInputs {
  const ScoreInputs({
    required this.budget,
    required this.spentThisMonth,
    required this.savedThisMonth,
    required this.streak,
    required this.txThisMonth,
    required this.categoriesThisMonth,
    required this.lessonsDone,
    required this.lessonsTotal,
  });

  final double budget;
  final double spentThisMonth;
  final double savedThisMonth;
  final int streak;
  final int txThisMonth;
  final int categoriesThisMonth;
  final int lessonsDone;
  final int lessonsTotal;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.budget,
    required this.savings,
    required this.streak,
    required this.consistency,
    required this.learning,
    required this.diversity,
  });

  /// Puncte per componentă (maxime: 25/25/15/15/10/10).
  final int budget;
  final int savings;
  final int streak;
  final int consistency;
  final int learning;
  final int diversity;

  int get total =>
      (budget + savings + streak + consistency + learning + diversity).clamp(
        1,
        100,
      );

  /// Cei 4 factori din Profil, ca procent 0..100 din maximul propriu
  /// (Constanță = streak+consistență, Cunoștințe = învățare+diversitate).
  int get savingsFactor => (savings * 100 / 25).round();
  int get budgetFactor => (budget * 100 / 25).round();
  int get steadinessFactor => ((streak + consistency) * 100 / 30).round();
  int get knowledgeFactor => ((learning + diversity) * 100 / 20).round();
}

ScoreBreakdown computeScore(ScoreInputs i) {
  // Buget (25p): full până la buget, zero de la 140% în sus, liniar între
  // (praguri 1.0 / 1.4).
  final int budgetPts;
  if (i.budget <= 0) {
    budgetPts = 12; // fără buget setat: credit neutru, nu pedeapsă
  } else {
    final ratio = i.spentThisMonth / i.budget;
    budgetPts = (25 * ((1.4 - ratio) / 0.4).clamp(0.0, 1.0)).round();
  }

  // Economisire (25p): ținta = 20% din buget.
  final target = i.budget * 0.2;
  final savingsPts = target <= 0
      ? (i.savedThisMonth > 0 ? 25 : 0)
      : (25 * (i.savedThisMonth / target).clamp(0.0, 1.0)).round();

  // Streak (15p): max la 21 de zile.
  final streakPts = (15 * (i.streak.clamp(0, 21) / 21)).round();

  // Consistență (15p): max la 10 tranzacții logate în luna curentă.
  final consistencyPts = (15 * (i.txThisMonth.clamp(0, 10) / 10)).round();

  // Învățare (10p): progresul prin lecții.
  final learningPts = i.lessonsTotal <= 0
      ? 0
      : (10 * (i.lessonsDone / i.lessonsTotal).clamp(0.0, 1.0)).round();

  // Diversitate (10p): max la 6 categorii distincte de cheltuieli pe lună.
  final diversityPts = (10 * (i.categoriesThisMonth.clamp(0, 6) / 6)).round();

  return ScoreBreakdown(
    budget: budgetPts,
    savings: savingsPts,
    streak: streakPts,
    consistency: consistencyPts,
    learning: learningPts,
    diversity: diversityPts,
  );
}

/// Cele patru trepte de scor: sub 30, 30-59, 60-79 și de la 80 în sus.
String scoreLevelLabel(int score) {
  if (score < 30) return 'Începător';
  if (score < 60) return 'Econom';
  if (score < 80) return 'Investitor';
  return 'Expert';
}
