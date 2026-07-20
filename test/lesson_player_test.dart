import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/features/learning/data/lessons_repository.dart';
import 'package:finedu_flutter/features/learning/presentation/interactives.dart';
import 'package:finedu_flutter/features/learning/presentation/lesson_player_screen.dart';

Widget _app(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'fluxul playerului (u1-banii-tai: guess → blocuri+check → scenariu → pairs)',
    () {
      // MaterialApp-ul de test se rezolvă pe 'en', deci CONȚINUTUL e în engleză;
      // etichetele și butoanele (chrome) sunt în română, din cod.
      testWidgets('gate-urile țin până e răspunsă fiecare pagină', (
        tester,
      ) async {
        double page() => tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .page!
            .roundToDouble();

        await tester.pumpWidget(
          _app(const LessonPlayerScreen(lessonId: 'u1-banii-tai')),
        );
        await tester.pumpAndSettle();

        // Pagina 0: guess-ul. Avansarea e blocată până la blocarea răspunsului.
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 0, reason: 'gate-ul ține până e blocat guess-ul');

        await tester.tap(find.text('Blochează răspunsul'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Răspunsul: 300'), findsOneWidget);
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 1);

        // Pagina 1: blocurile se dezvăluie prin tap; check-ul apare la final.
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(
          page(),
          1,
          reason: 'gate-ul ține până sunt dezvăluite blocurile',
        );

        while (tester.any(find.text('Atinge pentru mai mult'))) {
          await tester.tap(find.text('Atinge pentru mai mult'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 1, reason: 'gate-ul ține până e răspuns check-ul');

        await tester.ensureVisible(find.text('KNOWING your monthly total'));
        await tester.tap(find.text('KNOWING your monthly total'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 2);

        // Pagina 2: scenariul.
        await tester.ensureVisible(find.textContaining('Add it all up'));
        await tester.tap(find.textContaining('Add it all up'));
        await tester.pumpAndSettle();
        expect(find.textContaining('~530 lei'), findsOneWidget);
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 3);

        // Pagina 3: pairs, sursă ↔ ritm; gate-ul cade la ultima potrivire.
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 3, reason: 'gate-ul ține până sunt potrivite perechile');

        const pairs = {
          'State allowance': 'monthly, arrives automatically',
          'Pocket money': 'weekly, from your folks',
          "Grandparents' gifts": 'occasional, holidays, big days',
          'The summer job': 'seasonal, earned by you',
        };
        for (final entry in pairs.entries) {
          await tester.ensureVisible(find.text(entry.key));
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          await tester.tap(find.text(entry.value));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Continuă'));
        await tester.pumpAndSettle();
        expect(page(), 4);

        // Pagina 4: recap + teaser (pairs nu se reîntreabă, are retry intern).
        expect(find.text('🔁 PRINDE-O DE DATA ASTA'), findsNothing);
        expect(find.text('✨ URMEAZĂ'), findsOneWidget);
        expect(find.textContaining('Finalizează'), findsOneWidget);
      });
    },
  );

  group('interactives', () {
    testWidgets('swipe: wrong answers re-queue, finishing opens the gate', (
      tester,
    ) async {
      var done = false;
      bool? firstTry;
      const it = LessonInteractive(
        kind: 'swipe',
        title: 'Sortează',
        left: 'Nevoie',
        right: 'Dorință',
        cards: [
          SwipeCard('Pastă de dinți', isLeft: true, why: 'Igiena e nevoie.'),
          SwipeCard('Skin nou', isLeft: false, why: 'Status = dorință.'),
        ],
      );
      await tester.pumpWidget(
        _app(
          buildInteractive(
            it,
            onDone: (d) => done = d,
            onResult: (r) => firstTry = r,
          ),
        ),
      );

      // Greșim intenționat: pasta de dinți e nevoie, nu dorință.
      await tester.tap(find.text('Dorință'));
      await tester.pumpAndSettle();
      expect(find.text('Igiena e nevoie.'), findsOneWidget);
      expect(done, isFalse);

      // Au rămas două cartonașe de reluat; le nimerim pe amândouă.
      await tester.tap(find.text('Dorință'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nevoie'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(firstTry, isFalse, reason: 'a miss happened along the way');
      expect(find.textContaining('Gata!'), findsOneWidget);
    });

    testWidgets('cloze: wrong chip disables, correct chip fills and explains', (
      tester,
    ) async {
      var done = false;
      const it = LessonInteractive(
        kind: 'cloze',
        question: 'Prețul tăiat e o ___ .',
        chips: ['ancoră', 'economie'],
        correct: 0,
        explain: 'Ancora mută comparația.',
      );
      await tester.pumpWidget(
        _app(buildInteractive(it, onDone: (d) => done = d)),
      );

      await tester.tap(find.text('economie'));
      await tester.pumpAndSettle();
      expect(find.textContaining('capcană clasică'), findsOneWidget);
      expect(done, isFalse);

      await tester.tap(find.text('ancoră'));
      await tester.pumpAndSettle();
      expect(find.text('Ancora mută comparația.'), findsOneWidget);
      expect(done, isTrue);
    });

    testWidgets('poll: picking reveals the per-option comment and opens gate', (
      tester,
    ) async {
      var done = false;
      const it = LessonInteractive(
        kind: 'poll',
        question: 'Cum împarți 300 de lei?',
        pollOptions: [
          PollOption('Totul pe un lucru', 'Concentrare maximă.'),
          PollOption('Împărțit', 'Mai multe bucurii.'),
        ],
      );
      await tester.pumpWidget(
        _app(buildInteractive(it, onDone: (d) => done = d)),
      );

      expect(find.textContaining('Concentrare'), findsNothing);
      await tester.tap(find.text('Totul pe un lucru'));
      await tester.pumpAndSettle();
      expect(find.text('Concentrare maximă.'), findsOneWidget);
      expect(done, isTrue);
    });
  });
}
