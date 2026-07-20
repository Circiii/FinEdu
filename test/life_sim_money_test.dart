import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/life_sim/money.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_rng.dart';

void main() {
  group('Money, aritmetică pe int bani (niciun double)', () {
    test('constructori: bani, fromLei, fromJson', () {
      expect(const Money(12345).bani, 12345);
      expect(Money.fromLei(3).bani, 300);
      expect(Money.fromJson(500).bani, 500);
      expect(Money.zero.bani, 0);
    });

    test('adunare, scădere, negare, scalare', () {
      expect((const Money(300) + const Money(150)).bani, 450);
      expect((const Money(300) - const Money(150)).bani, 150);
      expect((-const Money(300)).bani, -300);
      expect((const Money(150) * 3).bani, 450);
    });

    test('comparații și isNegative', () {
      expect(const Money(300) < const Money(400), isTrue);
      expect(const Money(400) <= const Money(400), isTrue);
      expect(const Money(500) > const Money(400), isTrue);
      expect(const Money(400) >= const Money(400), isTrue);
      expect(const Money(-1).isNegative, isTrue);
      expect(const Money(0).isNegative, isFalse);
      expect(const Money(0).isZero, isTrue);
      expect(const Money(300).compareTo(const Money(400)), lessThan(0));
    });

    test('clampAtZero: cash poate fi negativ, fondul nu', () {
      expect(const Money(-500).clampAtZero(), const Money(0));
      expect(const Money(500).clampAtZero(), const Money(500));
    });

    test('formatare lei: punct pe mii, banii cazuți la zero, semn păstrat', () {
      expect(const Money(0).lei, '0 lei');
      expect(const Money(123400).lei, '1.234 lei'); // 1234 lei fix
      expect(const Money(123450).lei, '1.234,50 lei'); // ,50 nenul
      expect(const Money(100000).lei, '1.000 lei');
      expect(const Money(1234567).lei, '12.345,67 lei');
      expect(const Money(-85000).lei, '-850 lei');
      expect(const Money(-12345).lei, '-123,45 lei');
      expect(const Money(5).lei, '0,05 lei');
    });

    test('fromLeiDouble multiplică și rotunjește O DATĂ', () {
      expect(Money.fromLeiDouble(12.34).bani, 1234);
      // 900 lei × 1,15 profil oraș = 1035 lei → 103500 bani.
      expect(Money.fromLeiDouble(900 * 1.15).bani, 103500);
    });

    test('round-trip JSON', () {
      const m = Money(98765);
      expect(Money.fromJson(m.toJson()), m);
    });

    test('egalitate structurală', () {
      expect(const Money(42), const Money(42));
      expect(const Money(42) == const Money(43), isFalse);
      expect(
        const Money(1).hashCode,
        const Money(1).hashCode,
      ); // dedup în set-uri
    });
  });

  group('LifeSimRng, SplitMix64 determinist', () {
    // Vector de aur ÎNGHEȚAT la scrierea testului (produs de implementare
    // pentru seed 42), orice regresie de determinism cross-versiune pică aici.
    // În hexazecimal, nu ca `int`: în browser un `int` ține exact doar 53 de
    // biți, deci forma asta e singura care se compară la fel peste tot.
    const goldenU64 = [
      'bdd732262feb6e95',
      '28efe333b266f103',
      '47526757130f9f52',
      '581ce1ff0e4ae394',
      '09bc585a244823f2',
    ];

    test('vector de aur: primele 5 extrageri pentru seed 42', () {
      final r = LifeSimRng(42);
      final out = [for (var i = 0; i < 5; i++) r.nextHex()];
      expect(out, goldenU64);
    });

    test('același seed → aceeași secvență', () {
      final a = LifeSimRng(7);
      final b = LifeSimRng(7);
      for (var i = 0; i < 50; i++) {
        expect(a.nextHex(), b.nextHex());
      }
    });

    test('seed diferit → secvență diferită', () {
      final aa = LifeSimRng(1);
      final bb = LifeSimRng(2);
      final seqA = [for (var i = 0; i < 5; i++) aa.nextHex()];
      final seqB = [for (var i = 0; i < 5; i++) bb.nextHex()];
      expect(seqA, isNot(equals(seqB)));
    });

    test('nextDouble în [0,1) și determinist', () {
      final r = LifeSimRng(42);
      for (var i = 0; i < 1000; i++) {
        final d = r.nextDouble();
        expect(d, greaterThanOrEqualTo(0.0));
        expect(d, lessThan(1.0));
      }
      // Prima valoare înghețată.
      expect(LifeSimRng(42).nextDouble(), closeTo(0.7415648787718233, 1e-15));
    });

    test('nextInt în [0,bound) și determinist', () {
      final r = LifeSimRng(42);
      for (var i = 0; i < 1000; i++) {
        final n = r.nextInt(100);
        expect(n, inInclusiveRange(0, 99));
      }
      final r2 = LifeSimRng(42);
      expect(
        [for (var i = 0; i < 5; i++) r2.nextInt(100)],
        [6, 45, 29, 82, 25],
      );
    });

    test('fork: sub-stream-uri independente și deterministe', () {
      final f1a = LifeSimRng(42).fork(1);
      final f1b = LifeSimRng(42).fork(1);
      final s1a = [for (var i = 0; i < 5; i++) f1a.nextHex()];
      final s1b = [for (var i = 0; i < 5; i++) f1b.nextHex()];
      expect(s1a, s1b, reason: 'același (seed, streamId) → aceeași secvență');

      final f2 = LifeSimRng(42).fork(2);
      final s2 = [for (var i = 0; i < 5; i++) f2.nextHex()];
      expect(
        s1a,
        isNot(equals(s2)),
        reason: 'stream-uri diferite nu se corelează',
      );
    });

    test('fork nu depinde de starea consumată a părintelui', () {
      final parent = LifeSimRng(99);
      for (var i = 0; i < 10; i++) {
        parent.nextHex(); // consumă starea
      }
      final forkAfter = parent.fork(3);
      final forkFresh = LifeSimRng(99).fork(3);
      expect(
        [for (var i = 0; i < 5; i++) forkAfter.nextHex()],
        [for (var i = 0; i < 5; i++) forkFresh.nextHex()],
      );
    });
  });
}
