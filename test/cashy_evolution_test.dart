import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/cashy_evolution.dart';

void main() {
  group('carePoints (grija derivată din date existente)', () {
    test('formula exactă pentru un set cunoscut', () {
      // 10*2 + 5*3 + 7*2 + min(20,50) + 3*2 + 2*3 = 20+15+14+20+6+6 = 81
      expect(
        carePoints(
          activeDays: 10,
          lessonsDone: 5,
          longestStreak: 7,
          dojoRounds: 20,
          dailySolved: 3,
          wardrobeOwned: 2,
        ),
        81,
      );
    });

    test('rundele de dojo se plafonează la 50 (fără farmat din spam)', () {
      int withRounds(int rounds) => carePoints(
            activeDays: 4,
            lessonsDone: 2,
            longestStreak: 3,
            dojoRounds: rounds,
            dailySolved: 1,
            wardrobeOwned: 0,
          );
      expect(withRounds(200), withRounds(50));
      expect(withRounds(50), greaterThan(withRounds(10)));
    });

    test('zero peste tot = zero puncte', () {
      expect(
        carePoints(
          activeDays: 0,
          lessonsDone: 0,
          longestStreak: 0,
          dojoRounds: 0,
          dailySolved: 0,
          wardrobeOwned: 0,
        ),
        0,
      );
    });
  });

  group('stageFor la praguri', () {
    test('fiecare graniță cade în stadiul corect', () {
      expect(stageFor(0).title, 'Oul norocos');
      expect(stageFor(24).title, 'Oul norocos');
      expect(stageFor(25).title, 'Puiul curios');
      expect(stageFor(549).title, 'Păzitorul ghindelor');
      expect(stageFor(550).title, 'Înțeleptul Pădurii');
      expect(stageFor(100000).title, 'Înțeleptul Pădurii');
    });
  });

  group('nextStage + stageProgress', () {
    test('următorul stadiu, cu null la maxim', () {
      expect(nextStage(0)?.title, 'Puiul curios');
      expect(nextStage(24)?.title, 'Puiul curios');
      expect(nextStage(25)?.title, 'Strângătorul isteț');
      expect(nextStage(549)?.title, 'Înțeleptul Pădurii');
      expect(nextStage(550), isNull);
      expect(nextStage(100000), isNull);
    });

    test('progresul e 0 la prag, ~1 lângă următorul', () {
      expect(stageProgress(25), 0.0); // exact pe pragul Puiului
      expect(stageProgress(69), closeTo(44 / 45, 0.001)); // 1 sub Strângătorul
    });

    test('exact 1.0 și next==null la maxim', () {
      expect(stageProgress(550), 1.0);
      expect(stageProgress(100000), 1.0);
      expect(nextStage(550), isNull);
    });
  });

  group('lista de stadii (guvernanță)', () {
    test('exact 6 stadii', () {
      expect(cashyStages.length, 6);
    });

    test('praguri strict crescătoare, începând de la 0', () {
      expect(cashyStages.first.threshold, 0);
      for (var i = 1; i < cashyStages.length; i++) {
        expect(cashyStages[i].threshold,
            greaterThan(cashyStages[i - 1].threshold));
      }
    });

    test('titluri ro+en ne-goale, fără duplicate', () {
      for (final s in cashyStages) {
        expect(s.title.trim(), isNotEmpty);
        expect(s.titleEn.trim(), isNotEmpty);
        expect(s.emoji.trim(), isNotEmpty);
      }
      final roTitles = cashyStages.map((s) => s.title).toSet();
      final enTitles = cashyStages.map((s) => s.titleEn).toSet();
      expect(roTitles.length, cashyStages.length);
      expect(enTitles.length, cashyStages.length);
    });
  });
}
