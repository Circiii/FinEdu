import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/compound.dart';

void main() {
  group('compound engine (param_sim math)', () {
    test('series grows and always beats the mattress', () {
      final c = compoundSeries(monthly: 100, annualRate: 0.06, years: 10);
      final f = flatSeries(monthly: 100, years: 10);
      expect(c.length, 11);
      expect(f.length, 11);
      expect(c.first, 0);
      expect(f[1], 1200);
      // Primul an cu 6% pe an, capitalizat lunar: ~1233 lei la 1200 depuși.
      expect(c[1], closeTo(1233.6, 1));
      for (var y = 1; y <= 10; y++) {
        expect(c[y], greaterThan(f[y]), reason: 'year $y');
      }
      // 10 ani cu 100 lei pe lună la 6%: ~16,4k față de 12k ținuți la saltea.
      expect(c.last, closeTo(16388, 20));
    });

    test('zero rate degenerates to the flat series', () {
      final c = compoundSeries(monthly: 50, annualRate: 0, years: 5);
      final f = flatSeries(monthly: 50, years: 5);
      for (var y = 0; y <= 5; y++) {
        expect(c[y], closeTo(f[y], 0.001));
      }
    });

    test('rule of 72 and interest earned', () {
      expect(doublingYears(0.06), closeTo(12, 0.01));
      expect(doublingYears(0.08), closeTo(9, 0.01));
      expect(doublingYears(0), double.infinity);

      final earned = interestEarned(monthly: 100, annualRate: 0.06, years: 10);
      expect(earned, closeTo(16388 - 12000, 20));
    });

    test('axis helpers: compact lei and nice ceilings', () {
      expect(compactLei(850), '850');
      expect(compactLei(1200), '1.2k');
      expect(compactLei(16388), '16k');
      expect(niceCeiling(850), 1000);
      expect(niceCeiling(1600), 2000);
      expect(niceCeiling(4200), 5000);
      expect(niceCeiling(16388), 20000);
    });
  });
}
