/// Expedițiile lui Cashy, al doilea robinet de ghinde din zi. După cele 3
/// misiuni, Cashy pleacă 6 ore și se întoarce cu ghinde + o vedere, fără
/// nicio notificare.
///
/// Guvernanță AADC: NIMIC random, recompensa și vederea sunt DETERMINISTE
/// din datele locale; fără cronometru de presiune; o zi ratată nu costă nimic.
library;

import 'dart:math';

/// Durata unei expediții. Cashy pleacă acum și se întoarce peste atâtea ore.
const expeditionHours = 6;

/// Starea expediției de AZI, așa cum o vede Home.
enum ExpeditionPhase {
  /// Misiunile nu sunt gata, Cashy nu poate pleca încă.
  locked,

  /// Cufărul zilei e câștigat: Cashy e gata de drum.
  ready,

  /// A plecat, dar n-au trecut încă 6 ore.
  away,

  /// Au trecut 6 ore: s-a întors, dar prada încă n-a fost culeasă.
  returned,

  /// Prada de azi a fost deja culeasă.
  collected,
}

/// Deduce faza pură din datele de azi. Repository-ul trece DOAR rândul de azi;
/// expediția de ieri necolectată e tratată separat prin auto-collect.
ExpeditionPhase expeditionPhase({
  required bool chestEarnedToday,
  required DateTime? departedAt,
  required bool collected,
  required DateTime now,
}) {
  if (departedAt != null) {
    // Există deja o expediție azi: soarta ei nu mai depinde de misiuni.
    if (collected) return ExpeditionPhase.collected;
    if (now.difference(departedAt) >= const Duration(hours: expeditionHours)) {
      return ExpeditionPhase.returned;
    }
    return ExpeditionPhase.away;
  }
  // N-a plecat încă: cheia e cufărul zilei (cele 3 misiuni bifate).
  return chestEarnedToday ? ExpeditionPhase.ready : ExpeditionPhase.locked;
}

/// Recompensa expediției, determinist, fără niciun random.
///
/// Faucet calibrat sub cufăr; ziua condimentează ±4, streak-ul plătește
/// constanța. Domeniu efectiv: 16 + 2·min(streak,7)∈[0,14] + hash%5∈[0,4] =
/// 16..34.
int expeditionReward({required int streak, required String dayKey}) {
  return 16 + 2 * min<int>(streak, 7) + (dayKey.hashCode.abs() % 5);
}

/// Indexul vederii pentru ziua dată, determinist, aceeași zi → aceeași vedere.
int postcardIndex({required String dayKey, required int count}) {
  return dayKey.hashCode.abs() % count;
}
