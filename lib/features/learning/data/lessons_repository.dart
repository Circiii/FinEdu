import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/fsrs.dart';
import '../../../domain/engine/leitner.dart';
import '../../../domain/util/day_key.dart';

// ---- Modele de conținut (parsate din content/lessons/*.json) ----

class LearnUnit {
  const LearnUnit(this.id, this.ord, this.format, this.title, this.emoji,
      this.color, this.lessons);
  final String id;
  final int ord;

  /// Versiune de format: 1 = interactiv unic, 2 = „Lecții 2.1" (guess/check/
  /// scenario + swipe/poll/cloze + why per opțiune), 3 = 2.1 + blocuri vizuale
  /// de concept obligatorii. Player-ul randează toate.
  final int format;
  final String title;
  final String emoji;

  /// Culoarea banner-ului pe traseu: blue/green/amber/violet/danger.
  final String color;
  final List<Lesson> lessons;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.emoji,
    required this.minutes,
    required this.xp,
    required this.difficulty,
    required this.title,
    required this.hook,
    required this.concept,
    required this.example,
    required this.interactive,
    required this.recap,
    required this.action,
    required this.cards,
    this.blocks,
    this.guess,
    this.check,
    this.scenario,
    this.teaser,
  });

  final String id;
  final String emoji;
  final int minutes;
  final int xp;
  final String difficulty;
  final String title;
  final String hook;
  final List<String> concept;

  /// Pagina de concept ca blocuri vizuale (format 3). Când există, înlocuiesc
  /// paragrafele din [concept].
  final List<LessonBlock>? blocks;
  final String example;
  final LessonInteractive interactive;
  final List<String> recap;
  final String action;
  final List<ConceptCard> cards;

  // --- Lecții 2.1 (opționale, lecțiile format 1 rulează neschimbate) ---
  /// Slider de estimare înainte de concept (efect de pretesting).
  final LessonGuess? guess;

  /// Micro-alegere la finalul paginii de concept.
  final LessonCheck? check;

  /// „Tu ce-ai face?", înlocuiește exemplul; fiecare opțiune arată consecința.
  final LessonScenario? scenario;

  /// Cliffhanger spre lecția următoare (promite informație, nu amenință pierdere).
  final String? teaser;
}

/// Opțiune de răspuns cu motivul (why) pentru care e corectă/greșită.
/// Opțiunile vechi (string simplu) parsează cu [why] null.
class LessonOption {
  const LessonOption(this.text, [this.why]);
  final String text;
  final String? why;
}

class LessonGuess {
  const LessonGuess({
    required this.question,
    required this.min,
    required this.max,
    required this.step,
    required this.actual,
    required this.reveal,
    this.unit = 'lei',
  });
  final String question;
  final int min;
  final int max;
  final int step;
  final int actual;
  final String unit;
  final String reveal; // replica lui Cashy după blocarea răspunsului
}

class LessonCheck {
  const LessonCheck(
      {required this.question, required this.options, required this.correct});
  final String question;
  final List<LessonOption> options;
  final int correct;
}

class ScenarioOption {
  const ScenarioOption(this.text, this.consequence);
  final String text;
  final String consequence;
}

class LessonScenario {
  const LessonScenario(
      {required this.setup, required this.question, required this.options});
  final String setup;
  final String question;
  final List<ScenarioOption> options;
}

class SwipeCard {
  const SwipeCard(this.text, {required this.isLeft, required this.why});
  final String text;
  final bool isLeft;
  final String why;
}

class PollOption {
  const PollOption(this.text, this.comment);
  final String text;
  final String comment;
}

class MatchPair {
  const MatchPair(this.left, this.right);
  final String left;
  final String right;
}

class RevealCard {
  const RevealCard(this.front, this.back);
  final String front;
  final String back;
}

class LessonInteractive {
  const LessonInteractive({
    required this.kind,
    this.question,
    this.options = const [],
    this.correct = 0,
    this.explain,
    this.title,
    this.items = const [],
    this.left,
    this.right,
    this.cards = const [],
    this.pollOptions = const [],
    this.chips = const [],
    this.pairs = const [],
    this.reveals = const [],
    this.sim,
  });

  // 'mcq' | 'checklist' | 'swipe' | 'poll' | 'cloze' | 'param_sim'
  // | 'order' | 'pairs' | 'reveal'
  final String kind;
  final String? question;
  final List<LessonOption> options; // mcq + order (ordinea corectă)
  final int correct; // mcq + cloze
  final String? explain; // mcq + cloze
  final String? title; // checklist + swipe + param_sim + order/pairs/reveal
  final List<String> items; // checklist
  final String? left; // swipe bucket labels
  final String? right;
  final List<SwipeCard> cards; // swipe
  final List<PollOption> pollOptions; // poll
  final List<String> chips; // cloze (question contains '___')
  final List<MatchPair> pairs; // pairs
  final List<RevealCard> reveals; // reveal (mit → realitate)
  final SimConfig? sim; // param_sim
}

/// Configurația simulatorului de dobândă compusă. Sliderele se expun gradual din
/// conținut (`exposed`); „Laboratorul" final deblochează tot + inflația + cursa Ana/Vlad.
class SimConfig {
  const SimConfig({
    required this.exposed,
    required this.yearsDefault,
    required this.yearsMax,
    required this.monthlyDefault,
    required this.rateDefault,
    required this.inflation,
    required this.race,
  });

  final List<String> exposed; // subset din {years, monthly, rate}
  final int yearsDefault;
  final int yearsMax;
  final int monthlyDefault;
  final double rateDefault; // % anual (ex. 5.5)
  final bool inflation; // toggle „valoarea reală" (curbă punctată)
  final bool race; // modul Ana (16) vs Vlad (26)
}

class ConceptCard {
  const ConceptCard(this.id, this.question, this.answer);
  final String id;
  final String question;
  final String answer;
}

// ---- Blocuri vizuale de concept (format 3) ----
// Textele acceptă markup inline: **îngroșat** și ==evidențiat==.

sealed class LessonBlock {
  const LessonBlock();
}

/// Paragraf simplu.
class TextBlock extends LessonBlock {
  const TextBlock(this.text);
  final String text;
}

/// Card colorat cu o idee de reținut. [tone] ∈ blue/amber/green/violet/danger.
class CalloutBlock extends LessonBlock {
  const CalloutBlock(
      {required this.icon, this.title, required this.text, required this.tone});
  final String icon;
  final String? title;
  final String text;
  final String tone;
}

/// Cifra-vedetă a lecției, cu numărătoare animată la apariție.
class StatBlock extends LessonBlock {
  const StatBlock(
      {required this.value, required this.suffix, required this.label});
  final int value;
  final String suffix;
  final String label;
}

/// Comparație pe două coloane (ex. cash vs card).
class VsBlock extends LessonBlock {
  const VsBlock({
    required this.leftTitle,
    required this.leftText,
    required this.rightTitle,
    required this.rightText,
  });
  final String leftTitle;
  final String leftText;
  final String rightTitle;
  final String rightText;
}

/// Pași numerotați (rețete de acțiune).
class StepsBlock extends LessonBlock {
  const StepsBlock(this.items);
  final List<String> items;
}

/// Replica lui Cashy în bulă de dialog (principiul personalizării, ton
/// conversațional, Mayer).
class QuoteBlock extends LessonBlock {
  const QuoteBlock(this.text);
  final String text;
}

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;

List<String> _tl(Map<String, dynamic> node, String locale) =>
    ((node[locale] ?? node['ro']) as List).cast<String>();

/// Încarcă toate unitățile pentru [locale]. Bazat pe assets, unități noi
/// vin ca și conținut, nu cod.
final unitsProvider =
    FutureProvider.family<List<LearnUnit>, String>((ref, locale) async {
  const unitAssets = [
    'content/lessons/unit1.json',
    'content/lessons/unit2.json',
    'content/lessons/unit3.json',
    'content/lessons/unit4.json',
    'content/lessons/unit5.json',
    'content/lessons/unit6.json',
    'content/lessons/unit7.json',
  ];
  final units = <LearnUnit>[];
  for (final asset in unitAssets) {
    final json =
        jsonDecode(await loadAssetString(asset)) as Map<String, dynamic>;
    final unit = json['unit'] as Map<String, dynamic>;
    units.add(LearnUnit(
      unit['id'] as String,
      unit['ord'] as int,
      (unit['format'] as int?) ?? 1,
      _t(unit['title'] as Map<String, dynamic>, locale),
      unit['emoji'] as String,
      (unit['color'] as String?) ?? 'blue',
      [
        for (final l in (json['lessons'] as List).cast<Map<String, dynamic>>())
          Lesson(
            id: l['id'] as String,
            emoji: l['emoji'] as String,
            minutes: l['minutes'] as int,
            xp: l['xp'] as int,
            difficulty: l['difficulty'] as String,
            title: _t(l['title'] as Map<String, dynamic>, locale),
            hook: _t(l['hook'] as Map<String, dynamic>, locale),
            // Lecțiile pe blocuri (format 3) nu mai au paragrafe `concept`.
            concept: l['concept'] == null
                ? const []
                : _tl(l['concept'] as Map<String, dynamic>, locale),
            // Opțional din 2.1: lecțiile cu `scenario` pot renunța la exemplu.
            example: l['example'] == null
                ? ''
                : _t(l['example'] as Map<String, dynamic>, locale),
            interactive: _parseInteractive(
                l['interactive'] as Map<String, dynamic>, locale),
            recap: _tl(l['recap'] as Map<String, dynamic>, locale),
            action: _t(l['action'] as Map<String, dynamic>, locale),
            cards: [
              for (final c
                  in (l['cards'] as List).cast<Map<String, dynamic>>())
                ConceptCard(
                  c['id'] as String,
                  _t(c['q'] as Map<String, dynamic>, locale),
                  _t(c['a'] as Map<String, dynamic>, locale),
                ),
            ],
            blocks: _parseBlocks(l['blocks'] as List?, locale),
            guess: _parseGuess(l['guess'] as Map<String, dynamic>?, locale),
            check: _parseCheck(l['check'] as Map<String, dynamic>?, locale),
            scenario: _parseScenario(
                l['scenario'] as Map<String, dynamic>?, locale),
            teaser: l['teaser'] == null
                ? null
                : _t(l['teaser'] as Map<String, dynamic>, locale),
          ),
      ],
    ));
  }
  return units;
});

/// Un nod de opțiune e fie string bilingv vechi ({ro,en}), fie obiect 2.1
/// ({text:{…}, why:{…}}).
LessonOption _parseOption(Map<String, dynamic> node, String locale) {
  if (node.containsKey('text')) {
    return LessonOption(
      _t(node['text'] as Map<String, dynamic>, locale),
      node['why'] == null
          ? null
          : _t(node['why'] as Map<String, dynamic>, locale),
    );
  }
  return LessonOption(_t(node, locale));
}

/// Blocurile de concept (format 3). Tip necunoscut = eroare de conținut,
/// preferăm crash la parse decât un bloc dispărut în tăcere.
List<LessonBlock>? _parseBlocks(List? json, String locale) {
  if (json == null) return null;
  return [
    for (final raw in json.cast<Map<String, dynamic>>())
      switch (raw['t'] as String) {
        'text' => TextBlock(_t(raw['text'] as Map<String, dynamic>, locale)),
        'callout' => CalloutBlock(
            icon: raw['icon'] as String,
            title: raw['title'] == null
                ? null
                : _t(raw['title'] as Map<String, dynamic>, locale),
            text: _t(raw['text'] as Map<String, dynamic>, locale),
            tone: (raw['tone'] as String?) ?? 'blue',
          ),
        'stat' => StatBlock(
            value: raw['value'] as int,
            suffix: switch (raw['suffix']) {
              null => '',
              final String s => s,
              final Map<String, dynamic> m => _t(m, locale),
              _ => '',
            },
            label: _t(raw['label'] as Map<String, dynamic>, locale),
          ),
        'vs' => VsBlock(
            leftTitle: _t(
                (raw['left'] as Map<String, dynamic>)['title']
                    as Map<String, dynamic>,
                locale),
            leftText: _t(
                (raw['left'] as Map<String, dynamic>)['text']
                    as Map<String, dynamic>,
                locale),
            rightTitle: _t(
                (raw['right'] as Map<String, dynamic>)['title']
                    as Map<String, dynamic>,
                locale),
            rightText: _t(
                (raw['right'] as Map<String, dynamic>)['text']
                    as Map<String, dynamic>,
                locale),
          ),
        'steps' => StepsBlock([
            for (final i in (raw['items'] as List).cast<Map<String, dynamic>>())
              _t(i, locale),
          ]),
        'quote' => QuoteBlock(_t(raw['text'] as Map<String, dynamic>, locale)),
        final other => throw FormatException('bloc necunoscut: $other'),
      },
  ];
}

LessonGuess? _parseGuess(Map<String, dynamic>? json, String locale) {
  if (json == null) return null;
  // `unit` e fie string simplu ('lei', '%'), fie bilingv.
  final unit = json['unit'];
  return LessonGuess(
    question: _t(json['question'] as Map<String, dynamic>, locale),
    min: json['min'] as int,
    max: json['max'] as int,
    step: (json['step'] as int?) ?? 1,
    actual: json['actual'] as int,
    unit: unit == null
        ? 'lei'
        : (unit is String ? unit : _t(unit as Map<String, dynamic>, locale)),
    reveal: _t(json['reveal'] as Map<String, dynamic>, locale),
  );
}

LessonCheck? _parseCheck(Map<String, dynamic>? json, String locale) {
  if (json == null) return null;
  return LessonCheck(
    question: _t(json['question'] as Map<String, dynamic>, locale),
    options: [
      for (final o in (json['options'] as List).cast<Map<String, dynamic>>())
        _parseOption(o, locale),
    ],
    correct: json['correct'] as int,
  );
}

LessonScenario? _parseScenario(Map<String, dynamic>? json, String locale) {
  if (json == null) return null;
  return LessonScenario(
    setup: _t(json['setup'] as Map<String, dynamic>, locale),
    question: _t(json['question'] as Map<String, dynamic>, locale),
    options: [
      for (final o in (json['options'] as List).cast<Map<String, dynamic>>())
        ScenarioOption(
          _t(o['text'] as Map<String, dynamic>, locale),
          _t(o['consequence'] as Map<String, dynamic>, locale),
        ),
    ],
  );
}

LessonInteractive _parseInteractive(
    Map<String, dynamic> json, String locale) {
  final kind = json['kind'] as String;
  switch (kind) {
    case 'checklist':
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        items: [
          for (final i
              in (json['items'] as List).cast<Map<String, dynamic>>())
            _t(i, locale),
        ],
      );
    case 'swipe':
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        left: _t(json['left'] as Map<String, dynamic>, locale),
        right: _t(json['right'] as Map<String, dynamic>, locale),
        cards: [
          for (final c
              in (json['cards'] as List).cast<Map<String, dynamic>>())
            SwipeCard(
              _t(c['text'] as Map<String, dynamic>, locale),
              isLeft: c['side'] == 'left',
              why: _t(c['why'] as Map<String, dynamic>, locale),
            ),
        ],
      );
    case 'poll':
      return LessonInteractive(
        kind: kind,
        question: _t(json['question'] as Map<String, dynamic>, locale),
        pollOptions: [
          for (final o
              in (json['options'] as List).cast<Map<String, dynamic>>())
            PollOption(
              _t(o['text'] as Map<String, dynamic>, locale),
              _t(o['comment'] as Map<String, dynamic>, locale),
            ),
        ],
      );
    case 'cloze':
      return LessonInteractive(
        kind: kind,
        question: _t(json['question'] as Map<String, dynamic>, locale),
        chips: [
          for (final c
              in (json['chips'] as List).cast<Map<String, dynamic>>())
            _t(c, locale),
        ],
        correct: json['correct'] as int,
        explain: _t(json['explain'] as Map<String, dynamic>, locale),
      );
    case 'order':
      // `items` vine în ordinea CORECTĂ; UI-ul amestecă la afișare.
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        options: [
          for (final o in (json['items'] as List).cast<Map<String, dynamic>>())
            _parseOption(o, locale),
        ],
      );
    case 'pairs':
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        pairs: [
          for (final p in (json['pairs'] as List).cast<Map<String, dynamic>>())
            MatchPair(
              _t(p['l'] as Map<String, dynamic>, locale),
              _t(p['r'] as Map<String, dynamic>, locale),
            ),
        ],
      );
    case 'reveal':
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        reveals: [
          for (final c in (json['cards'] as List).cast<Map<String, dynamic>>())
            RevealCard(
              _t(c['front'] as Map<String, dynamic>, locale),
              _t(c['back'] as Map<String, dynamic>, locale),
            ),
        ],
      );
    case 'param_sim':
      final cfg = json['config'] as Map<String, dynamic>;
      return LessonInteractive(
        kind: kind,
        title: _t(json['title'] as Map<String, dynamic>, locale),
        sim: SimConfig(
          exposed: (cfg['exposed'] as List).cast<String>(),
          yearsDefault: (cfg['years_default'] as int?) ?? 10,
          yearsMax: (cfg['years_max'] as int?) ?? 30,
          monthlyDefault: (cfg['monthly_default'] as int?) ?? 100,
          rateDefault: ((cfg['rate_default'] as num?) ?? 5.5).toDouble(),
          inflation: (cfg['inflation'] as bool?) ?? false,
          race: (cfg['race'] as bool?) ?? false,
        ),
      );
    default: // mcq
      return LessonInteractive(
        kind: kind,
        question: _t(json['question'] as Map<String, dynamic>, locale),
        options: [
          for (final o
              in (json['options'] as List).cast<Map<String, dynamic>>())
            _parseOption(o, locale),
        ],
        correct: json['correct'] as int,
        explain: _t(json['explain'] as Map<String, dynamic>, locale),
      );
  }
}

// ---- Progres + repository de recapitulare ----

final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  return LearnRepository(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Id-urile lecțiilor completate (starea done/current/locked pe traseu).
final completedLessonsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(learnRepositoryProvider).watchCompleted();
});

/// Numărul de carduri de recapitulat azi (banner-ul de recapitulare).
final dueCardsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(learnRepositoryProvider).watchDueCount();
});

class LearnRepository {
  LearnRepository(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  Stream<Set<String>> watchCompleted() {
    return _db
        .select(_db.lessonProgressRows)
        .watch()
        .map((rows) => rows.map((r) => r.lessonId).toSet());
  }

  Stream<int> watchDueCount() {
    final today = dayKey(DateTime.now());
    return (_db.select(_db.reviewCards)
          ..where((c) => c.nextDue.isSmallerOrEqualValue(today)))
        .watch()
        .map((rows) => rows.length);
  }

  /// Completează o lecție (idempotent): XP + ghinde + cardurile intră în coada de
  /// recapitulare (due mâine). Întoarce XP-ul câștigat, sau null dacă era deja completată.
  Future<int?> completeLesson(Lesson lesson) async {
    final existing = await (_db.select(_db.lessonProgressRows)
          ..where((r) => r.lessonId.equals(lesson.id)))
        .getSingleOrNull();
    if (existing != null) return null;

    final today = dayKey(DateTime.now());
    await _db.transaction(() async {
      await _db.into(_db.lessonProgressRows).insert(
            LessonProgressRowsCompanion.insert(
              lessonId: lesson.id,
              completedAt: DateTime.now(),
            ),
          );
      for (final card in lesson.cards) {
        await _db.into(_db.reviewCards).insert(
              ReviewCardsCompanion.insert(
                cardId: card.id,
                lessonId: lesson.id,
                nextDue: addDaysToKeyLocal(today, 1),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _markActivity(today, 'lesson');
    });

    final profile = await _profiles.get();
    await _profiles.update(
        LocalProfilesCompanion(xp: Value(profile.xp + lesson.xp)));
    await _profiles.addAcorns(5, reason: 'lesson_${lesson.id}');
    return lesson.xp;
  }

  /// Cardurile due azi, cutiile cele mai vechi primele.
  Future<List<ReviewCard>> dueCards() {
    final today = dayKey(DateTime.now());
    return (_db.select(_db.reviewCards)
          ..where((c) => c.nextDue.isSmallerOrEqualValue(today))
          ..orderBy([(c) => OrderingTerm.asc(c.box)]))
        .get();
  }

  /// Aplică o notă FSRS-6 unui card. Card moștenit (stability null) își seed-uiește
  /// memoria din cutia Leitner la prima notare; scrie și `box` pentru compat cu UI-ul vechi.
  Future<void> grade(ReviewCard card, {required bool known}) async {
    final today = dayKey(DateTime.now());

    final FsrsMemory memory;
    if (card.stability == null) {
      // Card moștenit: fără `lastReview`, ghicim ultima recenzie ca `nextDue − interval(cutie)`.
      memory = fsrsSeedFromBox(card.box);
    } else {
      memory = FsrsMemory(
        stability: card.stability!,
        difficulty: card.difficulty ?? 5.0,
      );
    }
    final lastReview = card.lastReview ??
        addDaysToKeyLocal(card.nextDue, -(leitnerIntervals[card.box] ?? 1));
    final elapsed = _daysBetween(lastReview, today);

    final result = fsrsGrade(
      // Prima notare a unui card seedat din cutie e tot o recenzie ulterioară, nu una inițială.
      memory: memory,
      known: known,
      elapsedDays: (elapsed < 1 ? 1 : elapsed).toDouble(),
    );

    await (_db.update(_db.reviewCards)
          ..where((c) => c.cardId.equals(card.cardId)))
        .write(ReviewCardsCompanion(
      box: Value(fsrsBoxBucket(result.memory.stability)),
      stability: Value(result.memory.stability),
      difficulty: Value(result.memory.difficulty),
      lastReview: Value(today),
      nextDue: Value(addDaysToKeyLocal(today, result.intervalDays)),
      lapses: Value(known ? card.lapses : card.lapses + 1),
    ));
  }

  /// Recompensează o sesiune de recapitulare terminată și marchează activitatea zilei.
  Future<void> finishReviewSession(int reviewed) async {
    if (reviewed == 0) return;
    await _markActivity(dayKey(DateTime.now()), 'review');
    await _profiles.addAcorns(3, reason: 'review_session');
  }

  Future<void> _markActivity(String date, String kind) async {
    final row = await (_db.select(_db.dailyActivityRows)
          ..where((r) => r.date.equals(date)))
        .getSingleOrNull();
    final kinds = <String>{
      if (row != null) ...(jsonDecode(row.kinds) as List).cast<String>(),
      kind,
    }.toList();
    await _db.into(_db.dailyActivityRows).insertOnConflictUpdate(
          DailyActivityRowsCompanion.insert(
            date: date,
            kinds: jsonEncode(kinds),
          ),
        );
  }
}

/// Alias local ca să nu importăm day_math în fișierele UI prin aici.
String addDaysToKeyLocal(String key, int days) =>
    dayKey(DateTime.parse(key).add(Duration(days: days)));

/// Zile calendaristice între [from] și [to] (day-keys); folosit de FSRS pentru elapsedDays.
int _daysBetween(String from, String to) =>
    DateTime.parse(to).difference(DateTime.parse(from)).inDays;
