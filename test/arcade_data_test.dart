import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/domain/engine/daily_challenge.dart';
import 'package:finedu_flutter/domain/util/day_key.dart';
import 'package:finedu_flutter/features/arcade/data/arcade_repository.dart';
import 'package:finedu_flutter/features/arcade/data/dojo_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arcade content', () {
    test(
      'daily.json parses in both locales and every puzzle is playable',
      () async {
        for (final locale in ['ro', 'en']) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final content = await container.read(
            dailyContentProvider(locale).future,
          );

          expect(content.price, isNotEmpty);
          expect(content.myth, isNotEmpty);
          expect(content.dilemma, isNotEmpty);

          for (final p in content.price) {
            expect(p.items, hasLength(4), reason: p.id);
            for (final i in p.items) {
              expect(i.actual, inInclusiveRange(i.min, i.max), reason: p.id);
              expect(i.step, greaterThan(0), reason: p.id);
              // Sliderul are nevoie de diviziuni rotunde.
              expect((i.max - i.min) % i.step, 0, reason: '${p.id}/${i.name}');
            }
          }
          for (final m in content.myth) {
            expect(m.statements, hasLength(3), reason: m.id);
            for (final s in m.statements) {
              expect(s.explain, isNotEmpty, reason: m.id);
            }
          }
          for (final d in content.dilemma) {
            expect(d.options.length, greaterThanOrEqualTo(2), reason: d.id);
            for (final o in d.options) {
              expect(o.comment, isNotEmpty, reason: d.id);
            }
          }
        }
      },
    );

    test('dojo_messages.json: 70 messages, both locales, playable mix', () async {
      const accents = {'danger', 'amber', 'sky', 'violet', 'green', 'blue'};
      for (final locale in ['ro', 'en']) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final messages = await container.read(
          dojoMessagesProvider(locale).future,
        );
        expect(messages.length, 70);

        final ids = <String>{};
        var scams = 0;
        // Prinde textul stricat: UTF-8 dublu codat apare ca 'Ã' sau 'â€',
        // secvențe care nu există nici în română, nici în engleză.
        final mojibake = RegExp('Ã|â€|Äƒ|È™');
        for (final m in messages) {
          expect(ids.add(m.id), isTrue, reason: 'duplicate ${m.id}');
          expect(
            mojibake.hasMatch('${m.text}${m.flags.join()}${m.explain}'),
            isFalse,
            reason: '${m.id} contains double-encoded UTF-8',
          );
          expect(accents, contains(m.accent), reason: m.id);
          expect(m.difficulty, inInclusiveRange(1, 3), reason: m.id);
          expect(m.text, isNotEmpty, reason: m.id);
          expect(m.flags.length, inInclusiveRange(2, 4), reason: m.id);
          for (final f in m.flags) {
            expect(f, isNotEmpty, reason: m.id);
          }
          expect(m.explain, isNotEmpty, reason: m.id);
          if (m.isScam) scams++;
        }
        // Mesajele sigure țin jocul pe judecată, nu pe paranoia.
        expect(scams, inInclusiveRange(30, 45), reason: 'scam/safe mix');
        // Toate nivelurile de dificultate trebuie să existe, Elo are nevoie de ele.
        for (final d in [1, 2, 3]) {
          expect(
            messages.where((m) => m.difficulty == d).length,
            greaterThanOrEqualTo(8),
            reason: 'difficulty $d underpopulated',
          );
        }
      }
    });

    test('turbo_items.json: unique ids, valid buckets, both locales', () async {
      for (final locale in ['ro', 'en']) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final items = await container.read(turboItemsProvider(locale).future);
        expect(items.length, greaterThanOrEqualTo(50));
        final ids = <String>{};
        for (final i in items) {
          expect(ids.add(i.id), isTrue, reason: 'duplicate ${i.id}');
          expect(['need', 'want', 'save'], contains(i.bucket), reason: i.id);
          expect(i.price, greaterThan(0), reason: i.id);
          if (i.note != null) expect(i.note, isNotEmpty, reason: i.id);
        }
      }
    });
  });

  group('ArcadeRepository', () {
    late AppDb db;
    late ArcadeRepository repo;
    late LocalProfileRepository profiles;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      profiles = LocalProfileRepository(db);
      repo = ArcadeRepository(db, profiles);
    });
    tearDown(() => db.close());

    test('first round of the day pays once (doubled on the bonus day)', () async {
      final today = dayKey(DateTime.now());
      final multiplier = dailyBonusGame(today) == 'turbo' ? 2 : 1;

      final first = await repo.recordRound(game: 'turbo', score: 120);
      expect(first, 5 * multiplier);
      final profile = await profiles.get();
      expect(profile.acorns, 5 * multiplier);
      expect(profile.xp, 10, reason: 'first turbo round of the day pays XP');

      // A doua rundă se înregistrează, recordul poate crește, dar nu mai plătește.
      final second = await repo.recordRound(game: 'turbo', score: 200);
      expect(second, 0);
      expect((await profiles.get()).xp, 10);
      expect(await repo.watchBestScore('turbo').first, 200);

      // Ziua e marcată ca activitate de joc o singură dată.
      final activity = await db.select(db.dailyActivityRows).get();
      expect(activity.single.kinds, contains('game'));
    });

    test('Provocarea Zilei stays one per day', () async {
      final paid = await repo.recordRound(
        game: 'daily',
        score: 77,
        meta: {'format': 'price', 'grid': '🎯'},
      );
      expect(paid, greaterThan(0));
      // Al doilea record din aceeași zi e ignorat complet.
      final again = await repo.recordRound(game: 'daily', score: 99);
      expect(again, 0);
      final rounds = await db.select(db.arcadeRounds).get();
      expect(rounds, hasLength(1));
      expect(rounds.single.score, 77);
      final todayRound = await repo.watchTodayRound('daily').first;
      expect(todayRound?.score, 77);
    });

    test('dojo pays 2 acorns and no XP', () async {
      final today = dayKey(DateTime.now());
      final multiplier = dailyBonusGame(today) == 'dojo' ? 2 : 1;
      final paid = await repo.recordRound(game: 'dojo', score: 100);
      expect(paid, 2 * multiplier);
      expect((await profiles.get()).xp, 0);
    });
  });
}
