/// Evoluția lui Cashy, Cashy crește prin stadii, de la Ou la Înțeleptul
/// Pădurii, din „puncte de grijă" derivate DOAR din datele locale existente.
/// Guvernanță: evoluția reflectă grija și consecvența, nu se poate cumpăra
/// (niciun cost de ghinde, niciun tabel nou, niciun grind).
library;

import 'dart:math' show min;

/// Un stadiu al evoluției: prag de puncte de grijă + identitate.
class CashyStage {
  const CashyStage({
    required this.threshold,
    required this.emoji,
    required this.title,
    required this.titleEn,
  });
  final int threshold;
  final String emoji;
  final String title;
  final String titleEn;
}

const cashyStages = [
  CashyStage(
    threshold: 0,
    emoji: '🥚',
    title: 'Oul norocos',
    titleEn: 'The lucky egg',
  ),
  CashyStage(
    threshold: 25,
    emoji: '🐿️',
    title: 'Puiul curios',
    titleEn: 'The curious pup',
  ),
  CashyStage(
    threshold: 70,
    emoji: '🌰',
    title: 'Strângătorul isteț',
    titleEn: 'The clever gatherer',
  ),
  CashyStage(
    threshold: 150,
    emoji: '🧭',
    title: 'Exploratorul pădurii',
    titleEn: 'The forest explorer',
  ),
  CashyStage(
    threshold: 300,
    emoji: '🛡️',
    title: 'Păzitorul ghindelor',
    titleEn: 'The acorn guardian',
  ),
  CashyStage(
    threshold: 550,
    emoji: '🌳',
    title: 'Înțeleptul Pădurii',
    titleEn: 'The Forest Sage',
  ),
];

/// Punctele de grijă: cât de bine ai avut grijă de Cashy, din date deja
/// existente. Ponderi: consecvență (zile active ×2, cel mai lung streak ×2),
/// lecții ×3, dojo plafonat la 50 (anti-farm din spam de runde), provocări
/// ×2, cadouri din Garderobă ×3.
int carePoints({
  required int activeDays,
  required int lessonsDone,
  required int longestStreak,
  required int dojoRounds,
  required int dailySolved,
  required int wardrobeOwned,
}) {
  return activeDays * 2 +
      lessonsDone * 3 +
      longestStreak * 2 +
      min<int>(dojoRounds, 50) +
      dailySolved * 2 +
      wardrobeOwned * 3;
}

/// Stadiul curent: ultimul stadiu al cărui prag e ≤ [points].
CashyStage stageFor(int points) {
  var current = cashyStages.first;
  for (final s in cashyStages) {
    if (points >= s.threshold) {
      current = s;
    } else {
      break;
    }
  }
  return current;
}

/// Următorul stadiu, sau null când Cashy e la maxim.
CashyStage? nextStage(int points) {
  for (final s in cashyStages) {
    if (s.threshold > points) return s;
  }
  return null;
}

/// Progresul 0..1 de la pragul stadiului curent spre următorul (1.0 la maxim).
double stageProgress(int points) {
  final current = stageFor(points);
  final next = nextStage(points);
  if (next == null) return 1.0;
  final span = next.threshold - current.threshold;
  if (span <= 0) return 1.0;
  return ((points - current.threshold) / span).clamp(0.0, 1.0);
}
