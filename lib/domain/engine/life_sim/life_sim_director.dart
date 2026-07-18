/// Directorul de evenimente din „30 de Zile", determinist dat (stare,
/// conținut, rng, mod), alege cel mult un eveniment pe zi.
///
/// Evenimentele-consecință programate ([LifeSimState.scheduledEvents]) au
/// prioritate: sar peste ruleta de zi liniștită (sunt urmări, nu surprize).
library;

import 'life_sim_content.dart';
import 'life_sim_rng.dart';
import 'life_sim_state.dart';

/// Cea mai devreme intrare programată scadentă azi, al cărei eveniment există
/// în conținut. Sursă unică de adevăr, folosită și de motor pentru a scoate
/// intrarea din listă.
(int, String)? dueScheduledEntry(LifeSimState s, LifeSimContent c) {
  (int, String)? best;
  for (final e in s.scheduledEvents) {
    if (e.$1 <= s.day && c.eventById(e.$2) != null) {
      if (best == null || e.$1 < best.$1) best = e;
    }
  }
  return best;
}

/// Eligibil azi: în fereastra de zile, nu terminat (dacă one-shot), cooldown
/// trecut, tag-uri/condiții/excluderi/prerechizite OK.
bool eventEligible(LifeSimEvent e, LifeSimState s) {
  if (s.day < e.minDay || s.day > e.maxDay) return false;
  if (!e.repeatable && s.completedEvents.contains(e.id)) return false;
  final last = s.eventLastSeen[e.id];
  if (last != null && e.cooldownDays > 0 && s.day - last < e.cooldownDays) {
    return false;
  }
  for (final tag in e.roleTags) {
    if (tag != s.roleId && !s.flags.contains(tag)) return false;
  }
  for (final cond in e.conditions) {
    if (!cond.eval(s)) return false;
  }
  for (final ex in e.exclusions) {
    if (ex.eval(s)) return false;
  }
  for (final pre in e.prerequisites) {
    if (!s.completedEvents.contains(pre)) return false;
  }
  return true;
}

/// Greutatea ajustată a unui eveniment eligibil (echilibru de categorii +
/// anti-hammer + intensitate de mod). Multiplicatorii se cumulează.
double eventWeight(LifeSimEvent e, LifeSimState s, String mode) {
  var w = e.weight.toDouble();

  // Echilibru: penalizează categoria de ieri și categoriile deja „grele".
  if (e.category == s.lastEventCategory) w *= 0.4;
  if ((s.categoryCounts[e.category] ?? 0) >= 3) w *= 0.5;

  // Anti-hammer: dacă ieri a lovit un negativ (dificultate ≥2), negativele de
  // azi devin mult mai improbabile.
  final firedYesterday = s.lastEventDay == s.day - 1;
  final lastWasNegative = (s.lastEventDifficulty ?? 0) >= 2;
  if (firedYesterday && lastWasNegative && e.difficulty >= 2) w *= 0.3;

  // Modul ghidat („Prima lună"): șocurile intense (dificultate ≥3) sunt rare.
  if (mode == 'ghidat' && e.difficulty >= 3) w *= 0.4;

  return w;
}

/// Alege evenimentul zilei (sau `null` = zi liniștită). Determinist dat [rng].
///
/// Ordinea consumului de rng e FIXĂ: întâi ruleta de zi liniștită, apoi
/// selecția ponderată, ca replay-ul cu alt seed/altă decizie să rămână
/// comparabil.
LifeSimEvent? pickEvent({
  required LifeSimState s,
  required LifeSimContent c,
  required LifeSimRng rng,
  required String mode,
}) {
  // 1. Consecințele programate au prioritate, sar peste ruleta liniștită.
  final scheduled = dueScheduledEntry(s, c);
  if (scheduled != null) return c.eventById(scheduled.$2);

  // 2. Ruleta de zi liniștită se rulează prima.
  //    Bază: 0,15 realist / 0,32 ghidat; +0,20 dacă ieri a fost eveniment.
  var pQuiet = mode == 'ghidat' ? 0.32 : 0.15;
  if (s.lastEventDay == s.day - 1) pQuiet += 0.20;
  if (rng.nextDouble() < pQuiet) return null;

  // 3. Pool-ul eligibil (ordine de conținut = deterministă).
  final eligible = [for (final e in c.events) if (eventEligible(e, s)) e];
  if (eligible.isEmpty) return null;

  // 4. Greutăți ajustate.
  final weights = [for (final e in eligible) eventWeight(e, s, mode)];
  final total = weights.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return null;

  // 5. Selecție ponderată cumulativă.
  var r = rng.nextDouble() * total;
  for (var i = 0; i < eligible.length; i++) {
    r -= weights[i];
    if (r < 0) return eligible[i];
  }
  return eligible.last; // gardă numerică (r == total)
}
