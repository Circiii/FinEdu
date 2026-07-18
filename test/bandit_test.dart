import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/db_provider.dart';
import 'package:finedu_flutter/domain/engine/bandit.dart';
import 'package:finedu_flutter/domain/util/day_key.dart';
import 'package:finedu_flutter/features/home/data/home_providers.dart';
import 'package:finedu_flutter/features/insights/data/insights_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // --- deriveCounters --------------------------------------------------------

  group('deriveCounters', () {
    test('fresh observations weigh ~1; success→alpha, failure→beta', () {
      final c = deriveCounters(const [
        ArmObservation(arm: 0, success: true, ageDays: 0),
        ArmObservation(arm: 1, success: false, ageDays: 0),
      ]);
      // Baza e Beta(1,1); o observație proaspătă adaugă ~1.
      expect(c[0]!.alpha, closeTo(2.0, 0.001));
      expect(c[0]!.beta, 1.0);
      expect(c[1]!.alpha, 1.0);
      expect(c[1]!.beta, closeTo(2.0, 0.001));
    });

    test('70-day-old observations decay to ~pow(0.95,10)≈0.60', () {
      final c = deriveCounters(const [
        ArmObservation(arm: 0, success: true, ageDays: 70),
      ]);
      // Greutatea peste baza de 1: pow(0.95, 70/7) = pow(0.95,10) ≈ 0.5987.
      expect(c[0]!.alpha - 1.0, closeTo(0.60, 0.02));
      expect(c[0]!.beta, 1.0);
    });

    test('accumulates multiple observations per arm', () {
      final c = deriveCounters(const [
        ArmObservation(arm: 0, success: true, ageDays: 0),
        ArmObservation(arm: 0, success: true, ageDays: 0),
        ArmObservation(arm: 0, success: false, ageDays: 0),
      ]);
      expect(c[0]!.alpha, closeTo(3.0, 0.001)); // 1 + 2 succese
      expect(c[0]!.beta, closeTo(2.0, 0.001)); // 1 + 1 eșec
    });
  });

  // --- sampleBeta ------------------------------------------------------------

  group('sampleBeta', () {
    test('Beta(8,2) mean ≈ 0.8', () {
      final rng = Random(42);
      var sum = 0.0;
      for (var i = 0; i < 2000; i++) {
        sum += sampleBeta(8, 2, rng);
      }
      expect(sum / 2000, closeTo(0.8, 0.05));
    });

    test('Beta(1,1) is roughly uniform, mean ≈ 0.5', () {
      final rng = Random(7);
      var sum = 0.0;
      for (var i = 0; i < 2000; i++) {
        sum += sampleBeta(1, 1, rng);
      }
      expect(sum / 2000, closeTo(0.5, 0.05));
    });

    test('every sample lands in [0, 1]', () {
      final rng = Random(3);
      for (var i = 0; i < 500; i++) {
        final s = sampleBeta(0.5, 0.5, rng); // parametri mici (calea de boost)
        expect(s, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  // --- pickArm ---------------------------------------------------------------

  group('pickArm', () {
    test('converges to the better arm; epsilon floor keeps the worse alive',
        () {
      final counters = {
        0: (alpha: 5.0, beta: 20.0), // medie ≈ 0.2
        1: (alpha: 20.0, beta: 5.0), // medie ≈ 0.8
      };
      var arm1 = 0;
      var arm0 = 0;
      for (var i = 0; i < 200; i++) {
        final p = pickArm(counters: counters, armCount: 2, rng: Random(i));
        if (p.arm == 1) {
          arm1++;
        } else {
          arm0++;
        }
      }
      expect(arm1, greaterThan(140)); // > 70% din 200
      expect(arm0, greaterThanOrEqualTo(1)); // podeaua de explorare funcționează
    });

    test('returned propensity stays in [epsilon/K, 1] and favors the winner',
        () {
      final counters = {
        0: (alpha: 20.0, beta: 5.0), // brațul tare
        1: (alpha: 5.0, beta: 20.0),
      };
      const floor = 0.10 / 2;
      var sum0 = 0.0;
      var sum1 = 0.0;
      var n0 = 0;
      var n1 = 0;
      for (var i = 0; i < 500; i++) {
        final p = pickArm(counters: counters, armCount: 2, rng: Random(i));
        expect(p.propensity, inInclusiveRange(floor - 1e-9, 1.0 + 1e-9));
        if (p.arm == 0) {
          sum0 += p.propensity;
          n0++;
        } else {
          sum1 += p.propensity;
          n1++;
        }
      }
      expect(n0, greaterThan(n1)); // brațul tare e ales mult mai des
      expect(sum0 / n0, greaterThan(sum1 / max(1, n1)));
    });

    test('per-arm propensities sum to ~1 (epsilon/K + (1-eps)·pWin)', () {
      // Verificăm identitatea direct: o singură rulare MC consistentă dă o
      // distribuție proprie a câștigurilor (Σ = mcSamples), deci Σ propensity = 1.
      final counters = {
        0: (alpha: 8.0, beta: 4.0),
        1: (alpha: 3.0, beta: 6.0),
        2: (alpha: 5.0, beta: 5.0),
      };
      const eps = 0.10;
      const k = 3;
      const mc = 4000;
      final rng = Random(99);
      final wins = List<int>.filled(k, 0);
      for (var i = 0; i < mc; i++) {
        var best = 0;
        var bestS = -1.0;
        for (var a = 0; a < k; a++) {
          final c = counters[a]!;
          final s = sampleBeta(c.alpha, c.beta, rng);
          if (s > bestS) {
            bestS = s;
            best = a;
          }
        }
        wins[best]++;
      }
      var sum = 0.0;
      for (var a = 0; a < k; a++) {
        final prop = eps / k + (1 - eps) * (wins[a] / mc);
        expect(prop, greaterThanOrEqualTo(eps / k - 1e-9));
        sum += prop;
      }
      expect(sum, closeTo(1.0, 1e-9));
    });

    test('single arm always yields propensity 1', () {
      final p = pickArm(counters: const {}, armCount: 1, rng: Random(1));
      expect(p.arm, 0);
      expect(p.propensity, 1.0);
    });
  });

  // --- provider wiring (in-memory db) ---------------------------------------

  group('personalization wiring', () {
    Future<List<InsightCard>> run(ProviderContainer container) {
      final settled = Completer<List<InsightCard>>();
      container.listen<AsyncValue<List<InsightCard>>>(
        insightCardsProvider('ro'),
        (_, next) {
          final cards = next.valueOrNull;
          if (cards != null && !settled.isCompleted) settled.complete(cards);
          if (next.hasError && !settled.isCompleted) {
            settled.completeError(next.error!);
          }
        },
        fireImmediately: true,
      );
      return settled.future.timeout(const Duration(seconds: 15));
    }

    // 6 tranzacții mici sub un buget de 800 → pace_under (pozitiv) apare sigur.
    Future<void> seedPaceUnder(AppDb db) async {
      final now = DateTime.now();
      for (var i = 0; i < 6; i++) {
        await db.into(db.localTransactions).insert(
              LocalTransactionsCompanion.insert(
                id: 'tx$i',
                amount: 10.0 + i,
                category: 'mancare',
                transactionDate: now.subtract(Duration(days: i)),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }

    test('OFF: the shown event keeps arm null (legacy path intact)', () async {
      final db = AppDb(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
          overrides: [appDbProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);

      // id=0 explicit: coloana e alias de rowid în SQLite, altfel primește 1 și
      // stream-ul profilului (care veghează id=0) nu-l vede niciodată.
      await db.into(db.localProfiles).insert(LocalProfilesCompanion.insert(
            id: const Value(0),
            monthlyBudget: const Value(800),
          ));
      await seedPaceUnder(db);
      // Încălzim stream-ul profilului: prima construcție a insights trebuie să
      // vadă bugetul (altfel budget=0 → cade pe cardul educațional).
      await container.read(localProfileStreamProvider.future);

      final cards = await run(container);
      expect(cards, isNotEmpty);

      final shown = await (db.select(db.insightEvents)
            ..where((e) => e.event.equals('shown')))
          .get();
      expect(shown, isNotEmpty);
      expect(shown.every((e) => e.arm == null && e.propensity == null), isTrue,
          reason: 'personalizare oprită → nimic logat, byte-identic cu F8-a');
    });

    test('ON: bandit logs arm+propensity and favors the tapped variant',
        () async {
      final db = AppDb(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
          overrides: [appDbProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);

      // id=0 explicit (vezi nota din testul OFF: coloana e alias de rowid).
      await db.into(db.localProfiles).insert(LocalProfilesCompanion.insert(
            id: const Value(0),
            monthlyBudget: const Value(800),
            personalizationOn: const Value(true),
          ));
      await seedPaceUnder(db);
      // Încălzim stream-ul profilului (buget + flag personalizare) înainte de
      // prima construcție a insights.
      await container.read(localProfileStreamProvider.future);

      // Istoric: varianta 1 (arm=1) mereu apăsată (succes); varianta 0 mereu
      // ignorată (eșec). Banditul ar trebui să învețe să prefere brațul 1.
      final now = DateTime.now();
      for (var i = 0; i < 8; i++) {
        final shownAt = now.subtract(Duration(days: 3, hours: i));
        await db.into(db.insightEvents).insert(InsightEventsCompanion.insert(
              insightId: 'pu_s$i',
              ruleKey: 'pace_under',
              kind: 'positive',
              event: 'shown',
              createdAt: shownAt,
              arm: const Value(1),
              propensity: const Value(0.5),
            ));
        await db.into(db.insightEvents).insert(InsightEventsCompanion.insert(
              insightId: 'pu_s$i',
              ruleKey: 'pace_under',
              kind: 'positive',
              event: 'tapped',
              createdAt: shownAt.add(const Duration(hours: 1)),
            ));
        await db.into(db.insightEvents).insert(InsightEventsCompanion.insert(
              insightId: 'pu_f$i',
              ruleKey: 'pace_under',
              kind: 'positive',
              event: 'shown',
              createdAt: shownAt,
              arm: const Value(0),
            ));
      }

      // Evidența din DB favorizează puternic brațul 1 (varianta apăsată),
      // demonstrat determinist peste 100 de seed-uri distincte.
      final repo = container.read(insightsRepositoryProvider);
      final obs = await repo.banditObservations();
      final counters = deriveCounters(obs['pace_under']!);
      var arm1 = 0;
      for (var i = 0; i < 100; i++) {
        if (pickArm(counters: counters, armCount: 2, rng: Random(i)).arm == 1) {
          arm1++;
        }
      }
      expect(arm1, greaterThan(85));

      // Alegerea deterministă pentru seed-ul zilei, oglindește exact wiring-ul
      // provider-ului (Random pe (zi|regulă)), deci fără flake pe calendar.
      final expected = pickArm(
        counters: counters,
        armCount: 2,
        rng: Random(('${dayKey(now)}|pace_under').hashCode),
      );

      final cards = await run(container);
      expect(cards.any((c) => c.ruleKey == 'pace_under'), isTrue);

      final shown = await (db.select(db.insightEvents)
            ..where((e) => e.insightId.equals('pace_under'))
            ..where((e) => e.event.equals('shown')))
          .get();
      expect(shown, hasLength(1));
      final row = shown.single;
      expect(row.arm, isNotNull, reason: 'brațul ales e persistat pe shown');
      expect(row.propensity, isNotNull, reason: 'propensity-ul e logat');
      expect(row.propensity, inInclusiveRange(0.0, 1.0));
      expect(row.arm, expected.arm,
          reason: 'brațul persistat = decizia deterministă a banditului');
    });
  });
}
