import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/notification_planner.dart';

void main() {
  // Motorul e Dart pur, nu are nevoie de binding Flutter. Lint-ul de conținut
  // citește fișierul direct de pe disc (fără plugin de asset-uri).

  List<DateTime> atHours(List<int> hours) =>
      hours.map((h) => DateTime(2026, 1, 1, h)).toList();

  group('preferredHour', () {
    test('mediana orei, adusă în fereastra sigură', () {
      // 17,17,18,19,20,20,22 → mediana 19, deja în [16,20].
      expect(preferredHour(atHours([17, 17, 18, 19, 20, 20, 22])), 19);
    });

    test('sub 5 mostre → ora implicită F1 (19)', () {
      expect(preferredHour(atHours([17, 18])), 19);
      expect(preferredHour(const <DateTime>[]), 19);
    });

    test('numai seara târziu → clamp la 20', () {
      expect(preferredHour(atHours([23, 23, 23, 23, 23])), 20);
    });

    test('numai dimineața → clamp la 16', () {
      expect(preferredHour(atHours([8, 8, 8, 8, 8])), 16);
    });
  });

  group('planEscalation', () {
    test('offset-uri +1/+3/+7 zile la ora dată, id-uri și feluri corecte', () {
      final now = DateTime(2026, 3, 10, 12, 0);
      final plan = planEscalation(now: now, hour: 18);

      expect(plan.length, 3);

      expect(plan[0].id, 2001);
      expect(plan[0].kind, 'd1');
      expect(plan[0].when, DateTime(2026, 3, 11, 18));

      expect(plan[1].id, 2003);
      expect(plan[1].kind, 'd3');
      expect(plan[1].when, DateTime(2026, 3, 13, 18));

      expect(plan[2].id, 2007);
      expect(plan[2].kind, 'd7');
      expect(plan[2].when, DateTime(2026, 3, 17, 18));

      // Fiecare slot strict după `now`.
      for (final p in plan) {
        expect(p.when.isAfter(now), isTrue);
      }
    });

    test('ora 22 e clampată defensiv la 20', () {
      final now = DateTime(2026, 3, 10, 12, 0);
      final plan = planEscalation(now: now, hour: 22);
      for (final p in plan) {
        expect(p.when.hour, 20);
      }
    });

    test('ora 6 (noaptea) e clampată defensiv la 16', () {
      final now = DateTime(2026, 3, 10, 12, 0);
      final plan = planEscalation(now: now, hour: 6);
      for (final p in plan) {
        expect(p.when.hour, 16);
      }
    });
  });

  group('variantIndex', () {
    test('determinist: același dayKey → același index', () {
      final a = variantIndex(dayKey: '2026-03-11', count: 3);
      final b = variantIndex(dayKey: '2026-03-11', count: 3);
      expect(a, b);
    });

    test('mereu în [0, count)', () {
      for (final key in ['2026-01-01', '2026-07-14', '2027-12-31', 'x']) {
        for (final count in [1, 2, 3]) {
          final i = variantIndex(dayKey: key, count: count);
          expect(i, inInclusiveRange(0, count - 1));
        }
      }
    });
  });

  group('content lint: content/notifications.json', () {
    final raw = File('content/notifications.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    test('felurile D1/D3/D7 au ≥3/≥3/≥2 variante bilingve complete', () {
      const minVariants = {'d1': 3, 'd3': 3, 'd7': 2};
      minVariants.forEach((kind, min) {
        final list = json[kind];
        expect(list, isA<List>(), reason: 'lipsește felul $kind');
        expect((list as List).length, greaterThanOrEqualTo(min),
            reason: '$kind are prea puține variante');
        for (final v in list.cast<Map<String, dynamic>>()) {
          for (final field in ['title', 'body']) {
            final node = v[field] as Map<String, dynamic>;
            for (final loc in ['ro', 'en']) {
              expect(node[loc], isA<String>());
              expect((node[loc] as String).trim(), isNotEmpty,
                  reason: '$kind.$field.$loc e gol');
            }
          }
        }
      });
    });

    test('fără limbaj interzis AADC (vinovăție / amenințare cu pierderea)', () {
      const forbidden = [
        'pierzi',
        'pierdut',
        'ai stricat',
        'trebuie',
        'ultima șansă',
        'last chance',
        'you lost',
        'you must',
      ];
      // Verificăm DOAR copy-ul afișat (title/body), nu și `$schema_note`,
      // nota de meta chiar enumeră cuvintele interzise ca să documenteze regula.
      final haystack = StringBuffer();
      for (final kind in ['d1', 'd3', 'd7']) {
        for (final v in (json[kind] as List).cast<Map<String, dynamic>>()) {
          for (final field in ['title', 'body']) {
            final node = v[field] as Map<String, dynamic>;
            for (final loc in ['ro', 'en']) {
              haystack.write((node[loc] as String).toLowerCase());
              haystack.write('\n');
            }
          }
        }
      }
      final text = haystack.toString();
      for (final needle in forbidden) {
        expect(text.contains(needle.toLowerCase()), isFalse,
            reason: 'text interzis: „$needle"');
      }
    });

    test('fără mojibake (encoding UTF-8 curat)', () {
      for (final bad in ['Ã', 'â€', 'Äƒ', 'È™']) {
        expect(raw.contains(bad), isFalse, reason: 'mojibake: $bad');
      }
    });
  });
}
