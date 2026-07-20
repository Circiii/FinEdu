/// Comentariile lui Cashy pentru „30 de Zile".
///
/// Determinist: `LifeSimRng(seed).fork(zi)` alege varianta din pool, apoi
/// interpolează doar valori deja existente în stare/debrief, nicio cifră nouă.
library;

import 'life_sim_content.dart';
import 'life_sim_debrief.dart';
import 'life_sim_rng.dart';
import 'life_sim_state.dart';
import 'money.dart';

/// Prag (bani) peste care o mișcare devine „mare", folosit simetric la
/// cheltuială și câștig.
const _bigMoveBani = 50000; // 500 lei

/// Cât „cumpără" o zi de mâncare, pentru costul de oportunitate (`more[1]`).
const _foodDayBani = 3000; // 30 lei/zi, aproximare didactică, nu cifră reală

/// Fraze interzise, niciodată shaming. Verificate case-insensitive peste
/// toate pool-urile de mai jos.
const bannedCashyPhrases = [
  'prea mult',
  'iar ai',
  'trebuie',
  'decizie proastă',
];

/// Starea de spirit a lui Cashy pe ecranul de joc (derivată, nu aleasă manual).
enum CashyMoodGame { happy, worried, thinking, celebrate }

/// Un comentariu al lui Cashy: linia principală + până la 2 replici extra
/// dezvăluite la tap, în ordine.
class CashyComment {
  const CashyComment({
    required this.line,
    required this.more,
    required this.mood,
  });

  final String line;
  final List<String> more;
  final CashyMoodGame mood;
}

// ---------------------------------------------------------------------------
// Pool-uri, linia principală per situație.
// ---------------------------------------------------------------------------

const _bigSpendLines = [
  'Uau, asta a fost o cheltuială cu greutate! Am simțit cum s-a scuturat portofelul.',
  'Bani serioși au plecat acum. Sper că a meritat freamătul!',
  'Asta e o mișcare mare, portofelul tău tocmai a făcut un pas înapoi.',
  'Cheltuială grea azi! Măcar a fost o alegere cu cap, nu la nimereală.',
];

const _smallSpendLines = [
  'Un mic pas înapoi cu banii, nimic dramatic.',
  'S-a dus puțin azi. Portofelul abia a simțit.',
  'O sumă mică a ieșit din cont, viața merge înainte.',
  'Câțiva lei mai puțin, dar nu-i vreo dramă aici.',
];

const _gainLines = [
  'Uite bani intrând! Portofelul tău zâmbește acum.',
  'Ka-ching! Un plus frumos în cont azi.',
  'Bani în plus, hai să-i folosim cu cap mai încolo.',
  'Asta da veste bună, soldul tău tocmai a crescut!',
];

const _freeChoiceLines = [
  'N-ai mișcat niciun leu acum, alegere pur strategică.',
  'Fără bani implicați aici, doar tu și decizia ta.',
  'Zero mișcare de cash, dar alegerea tot contează la final.',
];

const _scheduledLines = [
  'Am notat ceva în calendar, o să revină vorba despre asta.',
  'Asta lasă un fir deschis. Ne vedem cu urmările mai încolo.',
  'Am pus o alarmă mentală, ziua asta o să aibă o continuare.',
];

const _situationPools = {
  _Situation.bigSpend: _bigSpendLines,
  _Situation.smallSpend: _smallSpendLines,
  _Situation.gain: _gainLines,
  _Situation.freeChoice: _freeChoiceLines,
  _Situation.scheduledConsequence: _scheduledLines,
};

/// Rezervă (rar folosită) când `LifeChoice.debrief` vine gol din conținut.
const _fallbackTradeoffLines = [
  'Fiecare alegere are un revers, pe ăsta nu-l vedem încă azi.',
  'Compromisul de azi rămâne discret, dar există mereu unul.',
  'Nimic vizibil acum, dar orice decizie mișcă ceva, undeva.',
];

/// „Ce-a notat Cashy în calendar", folosit când decizia a programat ceva.
const _calendarQuipLines = [
  'L-am scris în jurnalul meu de veveriță, nu uit nimic.',
  'Calendarul meu de alune ține minte exact ziua asta.',
  'Am pus un semnuleț pe pagina de mâine, să nu-mi scape.',
];

/// Umplutură pentru `more[1]` când nu s-a programat nimic ȘI costul de
/// oportunitate nu e relevant (sub 2 zile de mâncare).
const _fillerQuipLines = [
  'Bifat în jurnalul meu de veveriță, partea ușoară de azi.',
  'Nimic de calculat aici, doar o notiță mică pentru mine.',
  'Asta a fost floare la ureche pentru contabilitatea mea de alune.',
];

/// Template-uri cu `{days}` pentru costul de oportunitate (`more[1]`).
const _opportunityTemplates = [
  'Cu banii ăștia luai {days} zile de mâncare.',
  'Suma asta acoperea {days} zile de masă bună.',
  'Ar fi fost {days} zile de mâncare, dacă stăteai să calculezi.',
];

/// Linii de zi liniștită.
const _quietDayLines = [
  'Zi liniștită, am verificat calendarul, totul e sub control.',
  'Fondul tău de urgență stă cuminte și crește încet, fără presiune.',
  'Obiectivul tău mai are un pic până la linia de sosire. Constanța contează.',
  'O zi de respiro, și eu mă odihnesc puțin lângă tine.',
  'Nimic nou azi. Moment bun să te uiți peste portofel, fără grabă.',
  'Calmul de azi contează la fel de mult ca deciziile mari de ieri.',
];

// ---------------------------------------------------------------------------
// Situație + mood
// ---------------------------------------------------------------------------

enum _Situation { bigSpend, smallSpend, gain, freeChoice, scheduledConsequence }

_Situation _situationFor({
  required Money cashDelta,
  required bool bigSpend,
  required bool scheduled,
}) {
  if (bigSpend) return _Situation.bigSpend;
  if (cashDelta.bani > 0) return _Situation.gain;
  if (scheduled) return _Situation.scheduledConsequence;
  if (cashDelta.bani < 0) return _Situation.smallSpend;
  return _Situation.freeChoice;
}

/// Verificată în ordine, primul „adevărat" câștigă.
CashyMoodGame _moodFor({
  required bool cashNegative,
  required bool stressHigh,
  required bool bigGain,
  required bool goalProgress,
  required bool scheduled,
}) {
  if (cashNegative || stressHigh) return CashyMoodGame.worried;
  if (bigGain || goalProgress) return CashyMoodGame.celebrate;
  if (scheduled) return CashyMoodGame.thinking;
  return CashyMoodGame.happy;
}

T _pick<T>(List<T> pool, LifeSimRng rng) => pool[rng.nextInt(pool.length)];

String _fill(String template, Map<String, String> values) {
  var out = template;
  for (final e in values.entries) {
    out = out.replaceAll('{${e.key}}', e.value);
  }
  return out;
}

// ---------------------------------------------------------------------------
// API public
// ---------------------------------------------------------------------------

/// Comentariul lui Cashy pe marginea unei decizii. Determinist: aceleași
/// [before]/[after]/[seed] dau mereu aceeași linie.
CashyComment commentOnChoice({
  required LifeSimEvent event,
  required int choiceIdx,
  required LifeSimState before,
  required LifeSimState after,
  required int seed,
}) {
  final cashDelta = after.cash - before.cash;
  final scheduledBefore =
      before.scheduledEffects.length + before.scheduledEvents.length;
  final scheduledAfter =
      after.scheduledEffects.length + after.scheduledEvents.length;
  final scheduled = scheduledAfter > scheduledBefore;
  final goalProgress = after.goalSavings > before.goalSavings;
  final bigGain = cashDelta.bani >= _bigMoveBani;
  final bigSpend = cashDelta.bani <= -_bigMoveBani;

  final mood = _moodFor(
    cashNegative: after.cash.isNegative,
    stressHigh: after.stats.stress > 70,
    bigGain: bigGain,
    goalProgress: goalProgress,
    scheduled: scheduled,
  );

  final situation = _situationFor(
    cashDelta: cashDelta,
    bigSpend: bigSpend,
    scheduled: scheduled,
  );
  final rng = LifeSimRng(seed).fork(after.day);
  final line = _pick(_situationPools[situation]!, rng);

  final choice = event.choices[choiceIdx];
  final tradeOff = choice.debrief.isNotEmpty
      ? choice.debrief
      : _pick(_fallbackTradeoffLines, rng);

  final String secondMore;
  if (scheduled) {
    secondMore = _pick(_calendarQuipLines, rng);
  } else {
    final days = (cashDelta.bani.abs() / _foodDayBani).round();
    secondMore = days >= 2
        ? _fill(_pick(_opportunityTemplates, rng), {'days': '$days'})
        : _pick(_fillerQuipLines, rng);
  }

  return CashyComment(line: line, more: [tradeOff, secondMore], mood: mood);
}

/// Comentariul de zi liniștită (fără eveniment). Fără replici extra.
CashyComment commentOnQuietDay({required LifeSimState s, required int seed}) {
  final rng = LifeSimRng(seed).fork(s.day);
  final line = _pick(_quietDayLines, rng);
  final mood = s.cash.isNegative || s.stats.stress > 70
      ? CashyMoodGame.worried
      : CashyMoodGame.happy;
  return CashyComment(line: line, more: const [], mood: mood);
}

// ---------------------------------------------------------------------------
// Narațiunea raportului final
// ---------------------------------------------------------------------------

const _openerTemplates = [
  'Ai trecut prin {day} de zile și ai luat {n} decizii, hai să vedem cum ai stat.',
  '{n} decizii în {day} de zile. Iată povestea lor, pe scurt.',
  'O lună întreagă, {n} alegeri, le-am ținut minte pe toate.',
];

const _efficientTemplates = [
  'La „{title}" (ziua {day}) ai ieșit în plus cu {net}, mișcare inteligentă.',
  'Ziua {day}, „{title}": {net} net. Aplaud din toată inima de veveriță.',
  '„{title}" din ziua {day} ți-a adus {net} în plus, ține minte rețeta.',
];

const _riskyTemplates = [
  'La „{title}" (ziua {day}) ai pierdut net {loss}, dar acum știi ce-a urmat.',
  'Ziua {day}, „{title}": {loss} per total. O lecție utilă pentru data viitoare.',
  '„{title}" te-a costat {loss} pe termen lung, o țin minte pentru tine.',
];

const _steadyTemplates = [
  'Nicio mișcare mare în plus sau minus, lună constantă, {paid} facturi la timp.',
  'Lună lină: {paid} facturi la timp și niciun cutremur financiar.',
  'Ai navigat drept, fără valuri mari, {paid} facturi bifate la timp.',
];

const _lessonTemplates = [
  'Un lucru de reținut: {cf}',
  'Ce rămâne pentru data viitoare: {cf}',
  'Notă în jurnalul meu de veveriță: {cf}',
];

const _balanceTemplates = [
  'La final: sănătate {health}, energie {energy}, stres {stress}, relații {rel}.',
  'Bilanțul tău de viață: sănătate {health}, stres {stress}, relații {rel}, energie {energy}.',
  'Cifrele tale de suflet: {health} sănătate, {rel} relații, {stress} stres.',
];

const _conclusionLines = [
  'Asta a fost luna ta! Joacă din nou și vezi cum se schimbă povestea cu alte alegeri.',
  'Gata cu luna asta. Te aștept pentru o rundă nouă, cu alt drum.',
  'Povestea se termină aici, dar poți s-o iei de la capăt oricând, cu alte decizii.',
];

/// Toate template-urile, folosite de testul de lint care verifică fiecare
/// variantă posibilă. Funcție simplă, fișierul e Dart pur, fără Flutter.
List<String> allCommentaryTemplates() => [
  ..._bigSpendLines,
  ..._smallSpendLines,
  ..._gainLines,
  ..._freeChoiceLines,
  ..._scheduledLines,
  ..._fallbackTradeoffLines,
  ..._calendarQuipLines,
  ..._fillerQuipLines,
  ..._opportunityTemplates,
  ..._quietDayLines,
  ..._openerTemplates,
  ..._efficientTemplates,
  ..._riskyTemplates,
  ..._steadyTemplates,
  ..._lessonTemplates,
  ..._balanceTemplates,
  ..._conclusionLines,
];

/// Segmente în ordine: opener, decizii eficiente (max 2), riscante (max 1,
/// sau „constant" dacă niciuna), lecția din contrafactual, bilanț, concluzie.
List<CashyComment> narrateReport({
  required DebriefModel debrief,
  required LifeSimState s,
  required int seed,
}) {
  final rng = LifeSimRng(seed).fork(s.day);
  final segments = <CashyComment>[];

  segments.add(_openerSegment(debrief, s, rng));
  for (final o in debrief.efficient.take(2)) {
    segments.add(_efficientSegment(o, rng));
  }
  for (final o in debrief.risky.take(1)) {
    segments.add(_riskySegment(o, rng));
  }
  if (debrief.efficient.isEmpty && debrief.risky.isEmpty) {
    segments.add(_steadySegment(debrief, rng));
  }
  segments.add(_lessonSegment(debrief, rng));
  segments.add(_balanceSegment(s, rng));
  segments.add(_conclusionSegment(rng));
  return segments;
}

CashyComment _openerSegment(DebriefModel d, LifeSimState s, LifeSimRng rng) {
  final template = _pick(_openerTemplates, rng);
  final line = _fill(template, {
    'day': '${s.day}',
    'n': '${d.timeline.length}',
  });
  final mood = d.efficient.length > d.risky.length
      ? CashyMoodGame.celebrate
      : (d.risky.length > d.efficient.length
            ? CashyMoodGame.worried
            : CashyMoodGame.thinking);
  return CashyComment(line: line, more: const [], mood: mood);
}

CashyComment _efficientSegment(DebriefDecision o, LifeSimRng rng) {
  final template = _pick(_efficientTemplates, rng);
  final line = _fill(template, {
    'title': o.title,
    'day': '${o.day}',
    'net': o.net.lei,
  });
  return CashyComment(
    line: line,
    more: const [],
    mood: CashyMoodGame.celebrate,
  );
}

CashyComment _riskySegment(DebriefDecision o, LifeSimRng rng) {
  final loss = -o.net;
  final template = _pick(_riskyTemplates, rng);
  final line = _fill(template, {
    'title': o.title,
    'day': '${o.day}',
    'loss': loss.lei,
  });
  return CashyComment(line: line, more: const [], mood: CashyMoodGame.worried);
}

CashyComment _steadySegment(DebriefModel d, LifeSimRng rng) {
  final template = _pick(_steadyTemplates, rng);
  final line = _fill(template, {'paid': '${d.paidBillsOnTime}'});
  return CashyComment(line: line, more: const [], mood: CashyMoodGame.happy);
}

CashyComment _lessonSegment(DebriefModel d, LifeSimRng rng) {
  final template = _pick(_lessonTemplates, rng);
  final line = _fill(template, {'cf': d.counterfactual});
  return CashyComment(line: line, more: const [], mood: CashyMoodGame.thinking);
}

CashyComment _balanceSegment(LifeSimState s, LifeSimRng rng) {
  final st = s.stats;
  final template = _pick(_balanceTemplates, rng);
  final line = _fill(template, {
    'health': '${st.health}',
    'energy': '${st.energy}',
    'stress': '${st.stress}',
    'rel': '${st.relationships}',
  });
  final mood = st.stress > 70 ? CashyMoodGame.worried : CashyMoodGame.happy;
  return CashyComment(line: line, more: const [], mood: mood);
}

CashyComment _conclusionSegment(LifeSimRng rng) => CashyComment(
  line: _pick(_conclusionLines, rng),
  more: const [],
  mood: CashyMoodGame.celebrate,
);
