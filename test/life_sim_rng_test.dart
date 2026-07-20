import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/life_sim/life_sim_rng.dart';

/// Vectori de aur captați din implementarea SplitMix64 pe întregi de 64 de biți
/// nativi, ÎNAINTE de rescrierea pe jumătăți de 32 de biți. Rolul lor e să
/// dovedească un singur lucru: portarea pentru browser nu a schimbat niciun
/// număr, deci o rundă începută pe telefon arată identic pe web.
///
/// Dacă un test de aici pică, nu ajusta valorile. Înseamnă că runda salvată a
/// unui elev ar arăta alte evenimente decât atunci când a jucat-o.
void main() {
  group('LifeSimRng, paritate cu implementarea pe 64 de biți', () {
    const goldenHex = <int, List<String>>{
      0: [
        'e220a8397b1dcdaf',
        '6e789e6aa1b965f4',
        '06c45d188009454f',
        'f88bb8a8724c81ec',
        '1b39896a51a8749b',
        '53cb9f0c747ea2ea',
        '2c829abe1f4532e1',
        'c584133ac916ab3c',
      ],
      1: [
        '910a2dec89025cc1',
        'beeb8da1658eec67',
        'f893a2eefb32555e',
        '71c18690ee42c90b',
        '71bb54d8d101b5b9',
        'c34d0bff90150280',
        'e099ec6cd7363ca5',
        '85e7bb0f12278575',
      ],
      42: [
        'bdd732262feb6e95',
        '28efe333b266f103',
        '47526757130f9f52',
        '581ce1ff0e4ae394',
        '09bc585a244823f2',
        'de4431fa3c80db06',
        '37e9671c45376d5d',
        'ccf635ee9e9e2fa4',
      ],
      // Seed negativ: verifică desfacerea în complement față de doi.
      -1: [
        'e4d971771b652c20',
        'e99ff867dbf682c9',
        '382ff84cb27281e9',
        '6d1db36ccba982d2',
        'b4a0472e578069ae',
        'd31dadbda438bb33',
        'f14f2cf802083fa5',
        '405da438a39e8064',
      ],
      // Ordinul de mărime al seed-urilor reale (`millisecondsSinceEpoch`).
      1234567890123: [
        '9a253c9557cd08d8',
        '13a4d3c1ab4b6b6a',
        '6fda11718b5667f7',
        '001d69aed30d6c3c',
        '3cf634343d0e5551',
        'f213cd7bc5d3de0e',
        'baf17494c9f8405e',
        '78bc55edb612d4bc',
      ],
    };

    goldenHex.forEach((seed, expected) {
      test('secvența brută pentru seed $seed', () {
        final r = LifeSimRng(seed);
        final out = [for (var i = 0; i < expected.length; i++) r.nextHex()];
        expect(out, expected);
      });
    });

    // Bound-urile acoperă puteri ale lui 2 și numere care nu sunt, ca să prindă
    // și eventualele greșeli din restul calculat pe jumătăți.
    const bounds = [2, 3, 6, 7, 100, 1000, 65536];
    const goldenInt = <int, List<int>>{
      0: [1, 0, 3, 2, 73, 45, 39280],
      1: [0, 0, 3, 3, 80, 24, 7762],
      42: [0, 0, 3, 1, 25, 531, 46766],
      -1: [0, 1, 0, 3, 3, 537, 8146],
      1234567890123: [0, 1, 5, 6, 0, 479, 8239],
    };

    goldenInt.forEach((seed, expected) {
      test('nextInt pentru seed $seed', () {
        final r = LifeSimRng(seed);
        expect([for (final b in bounds) r.nextInt(b)], expected);
      });
    });

    const goldenDouble = <int, List<double>>{
      0: [
        0.88331080821364261,
        0.43152799704850997,
        0.026433771592597743,
        0.97088197815382848,
        0.10634669156721244,
      ],
      42: [
        0.74156487877182331,
        0.15991039287692010,
        0.27860113025513866,
        0.34419071652363753,
        0.038030168540246212,
      ],
      1234567890123: [
        0.60213068624561938,
        0.076733813078403323,
        0.43692120573117554,
        0.00044880407499692243,
        0.23813177371362682,
      ],
    };

    goldenDouble.forEach((seed, expected) {
      test('nextDouble pentru seed $seed', () {
        final r = LifeSimRng(seed);
        final out = [for (var i = 0; i < expected.length; i++) r.nextDouble()];
        // Egalitate exactă: aceiași biți de mantisă, nu doar aceeași valoare
        // aproximativă.
        expect(out, expected);
      });
    });

    const goldenFork = <int, List<String>>{
      0: [
        '568a9b0b1a2c05ec',
        '6ec85f1f8547bc0c',
        'f33dc6bd55ffa86b',
        '238150f3418b5cf2',
        'ebae1a1a417cf49e',
      ],
      42: [
        'ca685846b557f0fc',
        '33aa906d7b87bf0e',
        'deb745320506897a',
        '6edb4b760614fd7a',
        '30931df1079e4096',
      ],
      -1: [
        '02a28b166501827c',
        '4cf4029d585d83a0',
        '822949915fdc98e2',
        '2e1855d3ea1c056e',
        '14756c0badd13189',
      ],
    };

    // Include un streamId negativ, ca să acopere și acolo complementul.
    const streams = [0, 1, 7, 30, -3];

    goldenFork.forEach((seed, expected) {
      test('fork pentru seed $seed', () {
        expect([
          for (final s in streams) LifeSimRng(seed).fork(s).nextHex(),
        ], expected);
      });
    });
  });

  group('LifeSimRng, proprietăți', () {
    test('nextDouble rămâne în [0, 1)', () {
      final r = LifeSimRng(2024);
      for (var i = 0; i < 20000; i++) {
        final d = r.nextDouble();
        expect(d, greaterThanOrEqualTo(0.0));
        expect(d, lessThan(1.0));
      }
    });

    test('nextInt rămâne în [0, bound)', () {
      final r = LifeSimRng(2024);
      for (final b in [1, 2, 5, 13, 1000, 67108864]) {
        for (var i = 0; i < 2000; i++) {
          final n = r.nextInt(b);
          expect(n, greaterThanOrEqualTo(0));
          expect(n, lessThan(b));
        }
      }
    });

    test('jumătățile rămân valori pe 32 de biți fără semn', () {
      final r = LifeSimRng(7);
      for (var i = 0; i < 5000; i++) {
        final h = r.nextHex();
        expect(h.length, 16, reason: 'mereu 16 cifre, cu zerouri în față');
        expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(h), isTrue);
      }
    });

    test(
      'nextInt acoperă tot intervalul, nu se blochează pe câteva valori',
      () {
        final r = LifeSimRng(5);
        final seen = <int>{};
        for (var i = 0; i < 4000; i++) {
          seen.add(r.nextInt(20));
        }
        expect(seen.length, 20);
      },
    );
  });
}
