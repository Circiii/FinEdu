import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/domain/engine/leitner.dart';
import 'package:finedu_flutter/features/learning/data/lessons_repository.dart';

Lesson _lesson(String id, {int xp = 15}) => Lesson(
  id: id,
  emoji: '📖',
  minutes: 3,
  xp: xp,
  difficulty: 'beginner',
  title: 'T',
  hook: 'H',
  concept: const ['C'],
  example: 'E',
  interactive: const LessonInteractive(kind: 'mcq'),
  recap: const ['R'],
  action: 'A',
  cards: const [ConceptCard('c1', 'Q1', 'A1'), ConceptCard('c2', 'Q2', 'A2')],
);

void main() {
  group('content', () {
    test(
      'units parse in both locales; ids unique; interactives valid',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        for (final locale in ['ro', 'en']) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final units = await container.read(unitsProvider(locale).future);
          expect(
            [for (final u in units) u.ord],
            [for (var i = 1; i <= units.length; i++) i],
          );

          // Id-urile cardurilor trebuie unice ÎNTRE unități: tabelul are cheia
          // pe cardId cu insertOrIgnore, deci un duplicat ar dispărea în tăcere.
          final lessonIds = <String>{};
          final cardIds = <String>{};
          for (final unit in units) {
            expect(
              ['blue', 'green', 'amber', 'violet', 'danger'],
              contains(unit.color),
              reason: unit.id,
            );
            String? previousKind;
            for (final lesson in unit.lessons) {
              expect(
                lessonIds.add(lesson.id),
                isTrue,
                reason: 'duplicate lesson id ${lesson.id}',
              );
              expect(lesson.cards, hasLength(3));
              expect(lesson.recap, hasLength(3));
              expect(lesson.xp, lessonXp(lesson.difficulty));
              for (final card in lesson.cards) {
                expect(
                  cardIds.add(card.id),
                  isTrue,
                  reason: 'duplicate card id ${card.id}',
                );
              }

              final it = lesson.interactive;
              final where = '${lesson.id}/${it.kind}';
              switch (it.kind) {
                case 'mcq':
                  expect(
                    it.options.length,
                    greaterThanOrEqualTo(2),
                    reason: where,
                  );
                  expect(
                    it.correct,
                    inInclusiveRange(0, it.options.length - 1),
                    reason: where,
                  );
                  expect(it.explain, isNotNull, reason: where);
                  if (unit.format >= 2) {
                    // Feedback elaborativ: fiecare distractor își numește
                    // neînțelegerea.
                    for (var i = 0; i < it.options.length; i++) {
                      if (i != it.correct) {
                        expect(
                          it.options[i].why,
                          isNotNull,
                          reason: '$where option $i missing why',
                        );
                      }
                    }
                  }
                case 'checklist':
                  expect(it.items, isNotEmpty, reason: where);
                case 'swipe':
                  expect(
                    it.cards.length,
                    greaterThanOrEqualTo(4),
                    reason: where,
                  );
                  expect(it.left, isNotNull, reason: where);
                  expect(it.right, isNotNull, reason: where);
                  for (final c in it.cards) {
                    expect(c.why, isNotEmpty, reason: where);
                  }
                case 'poll':
                  expect(
                    it.pollOptions.length,
                    greaterThanOrEqualTo(2),
                    reason: where,
                  );
                  for (final o in it.pollOptions) {
                    expect(o.comment, isNotEmpty, reason: where);
                  }
                case 'cloze':
                  expect(it.question, contains('___'), reason: where);
                  expect(
                    it.chips.length,
                    greaterThanOrEqualTo(2),
                    reason: where,
                  );
                  expect(
                    it.correct,
                    inInclusiveRange(0, it.chips.length - 1),
                    reason: where,
                  );
                  expect(it.explain, isNotNull, reason: where);
                case 'order':
                  expect(it.title, isNotNull, reason: where);
                  expect(
                    it.options.length,
                    inInclusiveRange(3, 6),
                    reason: where,
                  );
                  for (final o in it.options) {
                    expect(o.text, isNotEmpty, reason: where);
                  }
                case 'pairs':
                  expect(it.title, isNotNull, reason: where);
                  expect(
                    it.pairs.length,
                    inInclusiveRange(3, 5),
                    reason: where,
                  );
                  for (final p in it.pairs) {
                    expect(p.left, isNotEmpty, reason: where);
                    expect(p.right, isNotEmpty, reason: where);
                  }
                case 'reveal':
                  expect(it.title, isNotNull, reason: where);
                  expect(
                    it.reveals.length,
                    inInclusiveRange(2, 4),
                    reason: where,
                  );
                  for (final c in it.reveals) {
                    expect(c.front, isNotEmpty, reason: where);
                    expect(c.back, isNotEmpty, reason: where);
                  }
                case 'param_sim':
                  // Simulatorul dobânzii compuse. Onestitate RO:
                  // rata implicită în 0-8, sume teen, expunere graduală validă.
                  final sim = it.sim!;
                  expect(it.title, isNotNull, reason: where);
                  expect(sim.exposed, isNotEmpty, reason: where);
                  for (final e in sim.exposed) {
                    expect(
                      ['years', 'monthly', 'rate'],
                      contains(e),
                      reason: where,
                    );
                  }
                  expect(
                    sim.rateDefault,
                    inInclusiveRange(0, 8),
                    reason: '$where honest RO rates only',
                  );
                  expect(
                    sim.monthlyDefault,
                    inInclusiveRange(0, 500),
                    reason: '$where teen-sized sums',
                  );
                  expect(
                    sim.yearsDefault,
                    inInclusiveRange(1, sim.yearsMax),
                    reason: where,
                  );
                  expect(sim.yearsMax, lessThanOrEqualTo(40), reason: where);
                default:
                  fail('unknown interactive kind: $where');
              }

              final g = lesson.guess;
              if (g != null) {
                expect(
                  g.actual,
                  inInclusiveRange(g.min, g.max),
                  reason: lesson.id,
                );
                expect(g.step, greaterThan(0), reason: lesson.id);
                expect(
                  (g.max - g.min) % g.step,
                  0,
                  reason: '${lesson.id} slider divisions',
                );
              }
              final check = lesson.check;
              if (check != null) {
                expect(
                  check.options.length,
                  inInclusiveRange(2, 3),
                  reason: lesson.id,
                );
                expect(
                  check.correct,
                  inInclusiveRange(0, check.options.length - 1),
                  reason: lesson.id,
                );
                for (final o in check.options) {
                  expect(o.why, isNotNull, reason: '${lesson.id} check why');
                }
              }
              final sc = lesson.scenario;
              if (sc != null) {
                expect(
                  sc.options.length,
                  inInclusiveRange(2, 4),
                  reason: lesson.id,
                );
                for (final o in sc.options) {
                  expect(o.consequence, isNotEmpty, reason: lesson.id);
                }
              }

              if (unit.format >= 2) {
                // Densitate 2.1: minim 2 din guess/check/scenario per lecție,
                // teaser prezent, fără două lecții consecutive cu același tip.
                final density = [g, check, sc].whereType<Object>().length;
                expect(
                  density,
                  greaterThanOrEqualTo(2),
                  reason: '${lesson.id} has only $density 2.1 interactions',
                );
                expect(lesson.teaser, isNotNull, reason: lesson.id);
                expect(
                  it.kind,
                  isNot(previousKind),
                  reason:
                      '${lesson.id} repeats kind ${it.kind} (rotation rule)',
                );
              }

              if (unit.format >= 3) {
                // Format 3: concept pe blocuri vizuale, cu mix de tipuri și
                // markup echilibrat (un ** sau == deschis fără pereche ar
                // ajunge literal pe ecran).
                final blocks = lesson.blocks;
                expect(
                  blocks,
                  isNotNull,
                  reason: '${lesson.id} missing blocks',
                );
                expect(
                  blocks!.length,
                  inInclusiveRange(3, 7),
                  reason: '${lesson.id} block count',
                );
                expect(
                  blocks.whereType<TextBlock>().length,
                  lessThan(blocks.length),
                  reason: '${lesson.id} needs non-text blocks too',
                );
                for (final b in blocks) {
                  final texts = switch (b) {
                    TextBlock(:final text) => [text],
                    CalloutBlock(:final title, :final text) => [?title, text],
                    StatBlock(:final label) => [label],
                    VsBlock() => [
                      b.leftTitle,
                      b.leftText,
                      b.rightTitle,
                      b.rightText,
                    ],
                    StepsBlock(:final items) => items,
                    QuoteBlock(:final text) => [text],
                  };
                  for (final t in texts) {
                    expect(t, isNotEmpty, reason: lesson.id);
                    expect(
                      '**'.allMatches(t).length.isEven,
                      isTrue,
                      reason: '${lesson.id} unbalanced ** in "$t"',
                    );
                    expect(
                      '=='.allMatches(t).length.isEven,
                      isTrue,
                      reason: '${lesson.id} unbalanced == in "$t"',
                    );
                  }
                  if (b is CalloutBlock) {
                    expect(
                      ['blue', 'amber', 'green', 'violet', 'danger'],
                      contains(b.tone),
                      reason: lesson.id,
                    );
                  }
                  if (b is StatBlock) {
                    expect(b.value, greaterThan(0), reason: lesson.id);
                  }
                  if (b is StepsBlock) {
                    expect(
                      b.items.length,
                      inInclusiveRange(2, 6),
                      reason: lesson.id,
                    );
                  }
                }
              }
              previousKind = it.kind;
            }
          }
        }
      },
    );
  });

  group('leitner', () {
    test('xp/levels: 300 per level', () {
      expect(lessonXp('beginner'), 15);
      expect(lessonXp('intermediate'), 20);
      expect(levelForXp(0), 1);
      expect(levelForXp(299), 1);
      expect(levelForXp(300), 2);
      expect(xpInLevel(350), 50);
    });
  });

  group('LearnRepository', () {
    late AppDb db;
    late LearnRepository repo;
    late LocalProfileRepository profiles;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      profiles = LocalProfileRepository(db);
      repo = LearnRepository(db, profiles);
    });
    tearDown(() => db.close());

    test('completeLesson: XP + acorns + cards enqueued + idempotent', () async {
      final earned = await repo.completeLesson(_lesson('l1', xp: 20));
      expect(earned, 20);

      final profile = await profiles.get();
      expect(profile.xp, 20);
      expect(profile.acorns, 5);

      // Cardurile intră în coadă, scadente mâine, nu azi.
      expect(await repo.dueCards(), isEmpty);
      final all = await db.select(db.reviewCards).get();
      expect(all.length, 2);

      // A doua finalizare nu mai schimbă nimic.
      expect(await repo.completeLesson(_lesson('l1', xp: 20)), isNull);
      expect((await profiles.get()).xp, 20);
    });

    test('grade moves a card through the schedule', () async {
      await repo.completeLesson(_lesson('l1'));
      final card = (await db.select(db.reviewCards).get()).first;

      await repo.grade(card, known: true);
      final updated = await (db.select(
        db.reviewCards,
      )..where((c) => c.cardId.equals(card.cardId))).getSingle();
      expect(updated.box, 2);
    });
  });
}
