/// Mașina de stări completă a streak-ului: freezes silențioase, earn-back
/// de 48h și milestone-uri, peste numărătoarea simplă din `streak_engine.dart`.
///
/// Freezes și earn-back nu modifică NICIODATĂ istoricul de activitate, zilele
/// protejate se țin în [StreakSnapshot.frozenDays], iar streak-ul e mereu
/// `computeStreak(activity ∪ frozen)`. Un singur mecanism, o singură sursă de adevăr.
library;

import 'day_math.dart';
import 'streak_engine.dart';

/// Starea de streak persistată (tabelul drift `StreakStates`, un singur rând).
class StreakSnapshot {
  const StreakSnapshot({
    this.freezes = 2,
    this.frozenDays = const {},
    this.earnbackValue = 0,
    this.earnbackUntil,
    this.earnbackGap = const {},
    this.claimedMilestones = const {},
    this.lastEvaluated,
  });

  /// Ghinde de Gheață deținute (max [maxFreezes]); 2 gratis la start.
  final int freezes;

  /// Zile protejate de un freeze (sau reconectate prin earn-back).
  final Set<String> frozenDays;

  /// Valoarea de streak de restaurat dacă earn-back reușește.
  final int earnbackValue;

  /// Ultima zi (inclusiv) în care earn-back mai poate fi finalizat.
  final String? earnbackUntil;

  /// Zilele-gol pe care earn-back le-ar reconecta la succes.
  final Set<String> earnbackGap;

  /// Milestone-uri deja recompensate (7/30/100/365).
  final Set<int> claimedMilestones;

  /// Ultima zi în care a rulat rollover-ul (idempotență).
  final String? lastEvaluated;

  static const maxFreezes = 2;

  StreakSnapshot copyWith({
    int? freezes,
    Set<String>? frozenDays,
    int? earnbackValue,
    String? earnbackUntil,
    bool clearEarnback = false,
    Set<String>? earnbackGap,
    Set<int>? claimedMilestones,
    String? lastEvaluated,
  }) {
    return StreakSnapshot(
      freezes: freezes ?? this.freezes,
      frozenDays: frozenDays ?? this.frozenDays,
      earnbackValue:
          clearEarnback ? 0 : (earnbackValue ?? this.earnbackValue),
      earnbackUntil:
          clearEarnback ? null : (earnbackUntil ?? this.earnbackUntil),
      earnbackGap:
          clearEarnback ? const {} : (earnbackGap ?? this.earnbackGap),
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      lastEvaluated: lastEvaluated ?? this.lastEvaluated,
    );
  }
}

sealed class StreakEvent {
  const StreakEvent();
}

/// O zi ratată a fost protejată silențios (patternul Duolingo: userul află
/// după aceea că a fost salvat, fără popup de vinovăție).
class FreezeUsed extends StreakEvent {
  const FreezeUsed(this.day);
  final String day;
}

/// Streak-ul s-a rupt; earn-back e armat până la [until].
class StreakBrokenEvent extends StreakEvent {
  const StreakBrokenEvent({required this.previous, required this.until});
  final int previous;
  final String until;
}

/// Earn-back a reușit: golul a fost reconectat și streak-ul restaurat.
class EarnbackSucceeded extends StreakEvent {
  const EarnbackSucceeded(this.restored);
  final int restored;
}

/// Un milestone nou (7/30/100/365) a fost atins, recompensă în ghinde.
class MilestoneReached extends StreakEvent {
  const MilestoneReached(this.days, this.acorns);
  final int days;
  final int acorns;
}

const streakMilestones = <int, int>{7: 15, 30: 40, 100: 100, 365: 365};

class StreakResult {
  const StreakResult(this.snapshot, this.events, this.current, this.longest);
  final StreakSnapshot snapshot;
  final List<StreakEvent> events;
  final int current;
  final int longest;
}

/// Rulează rollover-ul zilnic + verificarea de milestone-uri. Idempotent per
/// [today]: sigur de apelat la fiecare pornire și după fiecare scriere de activitate.
///
/// [activityDays], zilele reale de activitate; [todayKindCount], câte
/// tipuri distincte de activitate azi (earn-back are nevoie de 2 = „efort dublu").
StreakResult evaluateStreak({
  required StreakSnapshot snapshot,
  required Set<String> activityDays,
  required int todayKindCount,
  required String today,
}) {
  var s = snapshot;
  final events = <StreakEvent>[];
  final effective = {...activityDays, ...s.frozenDays};

  // --- 1. Verificarea ferestrei de earn-back (înainte de rollover, ca
  // efortul de azi să conteze).
  if (s.earnbackUntil != null) {
    if (compareDayKeys(today, s.earnbackUntil!) <= 0) {
      if (todayKindCount >= 2) {
        // Reconectăm golul: zilele ratate devin (retroactiv) protejate.
        final bridged = {...s.frozenDays, ...s.earnbackGap};
        s = s.copyWith(frozenDays: bridged, clearEarnback: true);
        effective.addAll(s.frozenDays);
        final restored = computeStreak(
          {...activityDays, ...s.frozenDays},
          today,
        ).current;
        events.add(EarnbackSucceeded(restored));
      }
    } else {
      s = s.copyWith(clearEarnback: true); // fereastra a expirat, silențios
    }
  }

  // --- 2. Rollover: protejăm sau rupem peste zilele ratate strict înainte
  // de azi. Rulează cel mult o dată pe zi.
  if (s.lastEvaluated != today) {
    final lastActive = _lastEffectiveDayBefore(effective, today);
    if (lastActive != null) {
      final gap = dayKeysBetween(lastActive, today); // exclusiv la ambele capete
      if (gap.isNotEmpty && s.earnbackUntil == null) {
        if (gap.length <= s.freezes) {
          final frozen = {...s.frozenDays, ...gap};
          s = s.copyWith(
              freezes: s.freezes - gap.length, frozenDays: frozen);
          effective.addAll(gap);
          for (final d in gap) {
            events.add(FreezeUsed(d));
          }
        } else {
          // Rupere: armăm earn-back pentru azi + mâine (fereastră de 48h).
          final previous =
              computeStreak(effective, lastActive).current;
          if (previous > 0) {
            final until = addDaysToKey(today, 1);
            s = s.copyWith(
              earnbackValue: previous,
              earnbackUntil: until,
              earnbackGap: gap,
            );
            events.add(StreakBrokenEvent(previous: previous, until: until));
          }
        }
      }
    }
    s = s.copyWith(lastEvaluated: today);
  }

  // --- 3. Curent/cel mai lung + milestone-uri.
  final counted = computeStreak(effective, today);
  for (final entry in streakMilestones.entries) {
    if (counted.current >= entry.key &&
        !s.claimedMilestones.contains(entry.key)) {
      s = s.copyWith(
          claimedMilestones: {...s.claimedMilestones, entry.key});
      events.add(MilestoneReached(entry.key, entry.value));
    }
  }

  return StreakResult(s, events, counted.current, counted.longest);
}

String? _lastEffectiveDayBefore(Set<String> effective, String today) {
  String? best;
  for (final d in effective) {
    if (compareDayKeys(d, today) >= 0) continue;
    if (best == null || compareDayKeys(d, best) > 0) best = d;
  }
  return best;
}
