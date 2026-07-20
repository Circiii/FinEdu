import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/domain/engine/expedition_rules.dart';
import 'package:finedu_flutter/domain/util/day_key.dart';
import 'package:finedu_flutter/features/expeditions/data/expeditions_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('expeditionPhase (motorul pur)', () {
    final now = DateTime(2026, 7, 14, 20, 0);

    test('fără plecare: locked când cufărul nu e câștigat, ready când e', () {
      expect(
        expeditionPhase(
          chestEarnedToday: false,
          departedAt: null,
          collected: false,
          now: now,
        ),
        ExpeditionPhase.locked,
      );
      expect(
        expeditionPhase(
          chestEarnedToday: true,
          departedAt: null,
          collected: false,
          now: now,
        ),
        ExpeditionPhase.ready,
      );
    });

    test('plecat: away sub 6h, returned la ≥6h', () {
      // Plecat cu 3h în urmă → încă pe drum.
      expect(
        expeditionPhase(
          chestEarnedToday: true,
          departedAt: now.subtract(const Duration(hours: 3)),
          collected: false,
          now: now,
        ),
        ExpeditionPhase.away,
      );
      // Fix 6h → s-a întors.
      expect(
        expeditionPhase(
          chestEarnedToday: true,
          departedAt: now.subtract(const Duration(hours: 6)),
          collected: false,
          now: now,
        ),
        ExpeditionPhase.returned,
      );
      // 7h → tot returned.
      expect(
        expeditionPhase(
          chestEarnedToday: true,
          departedAt: now.subtract(const Duration(hours: 7)),
          collected: false,
          now: now,
        ),
        ExpeditionPhase.returned,
      );
    });

    test('collected are prioritate indiferent de timp', () {
      expect(
        expeditionPhase(
          chestEarnedToday: true,
          departedAt: now.subtract(const Duration(hours: 2)),
          collected: true,
          now: now,
        ),
        ExpeditionPhase.collected,
      );
    });
  });

  group('expeditionReward (determinist, calibrat sub cufăr)', () {
    test('aceleași intrări → aceeași valoare', () {
      expect(
        expeditionReward(streak: 5, dayKey: '2026-07-14'),
        expeditionReward(streak: 5, dayKey: '2026-07-14'),
      );
    });

    test('domeniu 16..34 pentru streak-uri și zile variate', () {
      for (var streak = 0; streak <= 30; streak++) {
        for (final dk in [
          '2026-07-14',
          '2026-01-01',
          '2025-12-31',
          '2026-11-09',
          '2027-03-22',
        ]) {
          final r = expeditionReward(streak: streak, dayKey: dk);
          expect(r, inInclusiveRange(16, 34), reason: 's=$streak d=$dk');
        }
      }
    });

    test('streak plătește constanța, dar capat la 7 zile', () {
      const dk = '2026-07-14';
      final r0 = expeditionReward(streak: 0, dayKey: dk);
      final r7 = expeditionReward(streak: 7, dayKey: dk);
      final r20 = expeditionReward(streak: 20, dayKey: dk);
      expect(r0, lessThan(r7), reason: 'streak-ul crește recompensa');
      expect(r7, r20, reason: 'plafonat la 7, nu răsplătește obsesia');
    });
  });

  group('postcardIndex', () {
    test('în interval [0, count) și determinist', () {
      for (final dk in ['2026-07-14', '2026-07-15', '2026-01-01']) {
        final i = postcardIndex(dayKey: dk, count: 10);
        expect(i, inInclusiveRange(0, 9));
        expect(
          i,
          postcardIndex(dayKey: dk, count: 10),
          reason: 'aceeași zi → aceeași vedere',
        );
      }
    });
  });

  group('ExpeditionsRepository (drift in-memory)', () {
    late AppDb db;
    late LocalProfileRepository profiles;
    late ExpeditionsRepository repo;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      profiles = LocalProfileRepository(db);
      repo = ExpeditionsRepository(db, profiles);
    });
    tearDown(() => db.close());

    Future<List<ExpeditionRow>> allRows() => db.select(db.expeditionRows).get();
    Future<List<AcornEntry>> ledger() => db.select(db.acornEntries).get();

    test(
      'depart e idempotent: două apeluri → un rând, recompensă neschimbată',
      () async {
        await repo.depart(streak: 3);
        final first = await allRows();
        expect(first, hasLength(1));
        final reward = first.single.reward;

        await repo.depart(
          streak: 9,
        ); // altă recompensă teoretică, dar e ignorat
        final after = await allRows();
        expect(after, hasLength(1), reason: 'insertOrIgnore pe cheia zilei');
        expect(
          after.single.reward,
          reward,
          reason: 'plecarea nu se re-pornește',
        );
        // NICIO ghindă la plecare.
        expect((await profiles.get()).acorns, 0);
      },
    );

    test('collect înainte de 6h → 0 și nicio ghindă', () async {
      await repo.depart(streak: 4); // departedAt = acum
      expect(await repo.collect(), 0, reason: 'încă pe drum');
      expect((await profiles.get()).acorns, 0);
      expect(
        ledger().then((l) => l.any((e) => e.reason.startsWith('expedition_'))),
        completion(isFalse),
      );
    });

    test('collect după 6h creditează exact o dată prin ledger', () async {
      final today = dayKey(DateTime.now());
      // Rând înghețat cu plecare acum 7h.
      await db
          .into(db.expeditionRows)
          .insert(
            ExpeditionRowsCompanion.insert(
              day: today,
              departedAt: DateTime.now().subtract(const Duration(hours: 7)),
              reward: 25,
            ),
          );

      expect(await repo.collect(), 25);
      expect((await profiles.get()).acorns, 25);
      final entries = (await ledger()).where(
        (e) => e.reason.startsWith('expedition_'),
      );
      expect(entries, hasLength(1), reason: 'o singură creditare');
      expect(entries.single.delta, 25);

      // Al doilea cules nu mai plătește.
      expect(await repo.collect(), 0);
      expect((await profiles.get()).acorns, 25);
      expect(
        (await ledger()).where((e) => e.reason.startsWith('expedition_')),
        hasLength(1),
        reason: 'fără dublă creditare',
      );
    });

    test(
      'autoCollectStale creditează ieri o dată, niciodată de două ori',
      () async {
        final yesterday = dayKey(
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Trimis ieri seară, user-ul revine azi, încă necolectat, ≥6h scurse.
        await db
            .into(db.expeditionRows)
            .insert(
              ExpeditionRowsCompanion.insert(
                day: yesterday,
                departedAt: DateTime.now().subtract(const Duration(hours: 14)),
                reward: 20,
              ),
            );

        expect(await repo.autoCollectStale(), 20);
        expect((await profiles.get()).acorns, 20);
        expect(
          (await ledger()).where((e) => e.reason == 'expedition_$yesterday'),
          hasLength(1),
        );

        // A doua rulare (altă sesiune) nu mai creditează.
        expect(await repo.autoCollectStale(), 0);
        expect((await profiles.get()).acorns, 20);
        expect(
          (await ledger()).where((e) => e.reason == 'expedition_$yesterday'),
          hasLength(1),
          reason: 'niciodată dublu',
        );

        // Rândul e marcat colectat.
        final row = (await allRows()).single;
        expect(row.collectedAt, isNotNull);
      },
    );

    test('autoCollectStale ignoră expedițiile prea recente', () async {
      final yesterday = dayKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      // Plecat acum 2h (chiar dacă „aparține" zilei de ieri ca dată-cheie).
      await db
          .into(db.expeditionRows)
          .insert(
            ExpeditionRowsCompanion.insert(
              day: yesterday,
              departedAt: DateTime.now().subtract(const Duration(hours: 2)),
              reward: 30,
            ),
          );
      expect(await repo.autoCollectStale(), 0, reason: 'încă nu s-a întors');
      expect((await profiles.get()).acorns, 0);
    });
  });

  group('content lint: content/expeditions.json', () {
    final raw = File('content/expeditions.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final postcards = (json['postcards'] as List).cast<Map<String, dynamic>>();

    test('≥10 vederi, ro+en complete', () {
      expect(postcards.length, greaterThanOrEqualTo(10));
      for (final p in postcards) {
        final node = p['text'] as Map<String, dynamic>;
        for (final loc in ['ro', 'en']) {
          expect(node[loc], isA<String>(), reason: 'lipsește $loc');
          expect(
            (node[loc] as String).trim(),
            isNotEmpty,
            reason: '$loc e gol',
          );
        }
      }
    });

    test('fără mojibake (encoding UTF-8 curat)', () {
      for (final bad in ['Ã', 'â€', 'Äƒ', 'È™']) {
        expect(raw.contains(bad), isFalse, reason: 'mojibake: $bad');
      }
    });

    test('fără limbaj de urgență AADC în vederi', () {
      const forbidden = [
        'grăbește',
        'ultima șansă',
        'pierzi',
        'hurry',
        'last chance',
      ];
      // DOAR textul vederilor, `$schema_note` enumeră intenționat cuvintele
      // interzise ca să documenteze regula.
      final haystack = StringBuffer();
      for (final p in postcards) {
        final node = p['text'] as Map<String, dynamic>;
        for (final loc in ['ro', 'en']) {
          haystack.write((node[loc] as String).toLowerCase());
          haystack.write('\n');
        }
      }
      final text = haystack.toString();
      for (final needle in forbidden) {
        expect(
          text.contains(needle.toLowerCase()),
          isFalse,
          reason: 'text interzis: „$needle"',
        );
      }
    });
  });
}
