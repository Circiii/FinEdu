import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/features/learning/data/lessons_repository.dart';
import 'package:finedu_flutter/features/learning/presentation/interactives.dart';
import 'package:finedu_flutter/features/learning/presentation/lesson_blocks.dart';

Widget _app(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

/// Toate span-urile de text din primul Text.rich găsit.
List<TextSpan> _spans(WidgetTester tester) {
  final rich = tester.widget<Text>(find.byType(Text).first);
  final root = rich.textSpan! as TextSpan;
  return root.children!.cast<TextSpan>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RichLessonText', () {
    testWidgets('**bold** și ==evidențiat== devin span-uri stilate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          RichLessonText(
            'A **b** și ==c== d',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
      final spans = _spans(tester);
      expect(spans.map((s) => s.text).toList(), ['A ', 'b', ' și ', 'c', ' d']);
      expect(spans[1].style!.fontWeight, FontWeight.w800);
      expect(
        spans[3].style!.background,
        isNotNull,
        reason: 'evidențierea are fundal de marker',
      );
      expect(spans[0].style, isNull, reason: 'textul simplu moștenește stilul');
    });

    testWidgets('fără markup rămâne Text simplu', (tester) async {
      await tester.pumpWidget(
        _app(
          RichLessonText(
            'Fără nimic special',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text).first);
      expect(text.textSpan, isNull);
      expect(text.data, 'Fără nimic special');
    });

    testWidgets('markup neînchis se afișează literal, nu crapă', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          RichLessonText(
            'A **b fără pereche',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
      expect(find.text('A **b fără pereche'), findsOneWidget);
    });
  });

  group('LessonBlocksPage', () {
    testWidgets('dezvăluie blocurile pe rând și anunță finalul o dată', (
      tester,
    ) async {
      var revealed = 0;
      await tester.pumpWidget(
        _app(
          LessonBlocksPage(
            blocks: const [
              TextBlock('Primul bloc'),
              TextBlock('Al doilea bloc'),
              CalloutBlock(icon: '💡', text: 'Capcana', tone: 'amber'),
            ],
            header: const SizedBox(),
            trailing: const Text('CHECK-UL'),
            onAllRevealed: () => revealed++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primul bloc'), findsOneWidget);
      expect(find.text('Al doilea bloc'), findsNothing);
      expect(find.text('Atinge pentru mai mult'), findsOneWidget);
      expect(find.text('CHECK-UL'), findsNothing);

      await tester.tap(find.byType(LessonBlocksPage));
      await tester.pumpAndSettle();
      expect(find.text('Al doilea bloc'), findsOneWidget);
      expect(revealed, 0);

      await tester.tap(find.byType(LessonBlocksPage));
      await tester.pumpAndSettle();
      expect(find.text('Capcana'), findsOneWidget);
      expect(revealed, 1);
      expect(find.text('Atinge pentru mai mult'), findsNothing);
      expect(
        find.text('CHECK-UL'),
        findsOneWidget,
        reason: 'micro-check-ul apare abia după ultimul bloc',
      );
    });

    testWidgets('cu un singur bloc anunță imediat', (tester) async {
      var revealed = 0;
      await tester.pumpWidget(
        _app(
          LessonBlocksPage(
            blocks: const [TextBlock('Unicul')],
            header: const SizedBox(),
            onAllRevealed: () => revealed++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(revealed, 1);
    });
  });

  group('order', () {
    const it = LessonInteractive(
      kind: 'order',
      title: 'Pașii',
      options: [
        LessonOption('Unu'),
        LessonOption('Doi'),
        LessonOption('Trei', 'Fix așa.'),
      ],
    );

    testWidgets('ordinea corectă din prima → onResult true', (tester) async {
      var done = false;
      bool? firstTry;
      await tester.pumpWidget(
        _app(
          buildInteractive(
            it,
            onDone: (d) => done = d,
            onResult: (r) => firstTry = r,
          ),
        ),
      );

      for (final label in ['Unu', 'Doi', 'Trei']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(done, isTrue);
      expect(firstTry, isTrue);
      expect(
        find.text('Fix așa.'),
        findsOneWidget,
        reason: 'why-ul ultimului pas devine feedback final',
      );
    });

    testWidgets('pasul greșit scutură și contează ca ratare', (tester) async {
      var done = false;
      bool? firstTry;
      await tester.pumpWidget(
        _app(
          buildInteractive(
            it,
            onDone: (d) => done = d,
            onResult: (r) => firstTry = r,
          ),
        ),
      );

      await tester.tap(find.text('Trei'));
      await tester.pumpAndSettle();
      expect(done, isFalse);

      for (final label in ['Unu', 'Doi', 'Trei']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(done, isTrue);
      expect(firstTry, isFalse);
    });
  });

  group('pairs', () {
    const it = LessonInteractive(
      kind: 'pairs',
      title: 'Potrivește',
      pairs: [
        MatchPair('Brut', 'Suma din contract'),
        MatchPair('Net', 'Suma din mână'),
        MatchPair('CAS', 'Pensia ta'),
      ],
    );

    testWidgets('potrivirile blochează perechile; nepotrivirea e ratare', (
      tester,
    ) async {
      var done = false;
      bool? firstTry;
      await tester.pumpWidget(
        _app(
          buildInteractive(
            it,
            onDone: (d) => done = d,
            onResult: (r) => firstTry = r,
          ),
        ),
      );

      // Nepotrivire: Brut + „Suma din mână".
      await tester.tap(find.text('Brut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suma din mână'));
      await tester.pumpAndSettle();
      expect(done, isFalse);

      Future<void> match(String l, String r) async {
        await tester.tap(find.text(l));
        await tester.pumpAndSettle();
        await tester.tap(find.text(r));
        await tester.pumpAndSettle();
      }

      await match('Brut', 'Suma din contract');
      await match('Net', 'Suma din mână');
      await match('CAS', 'Pensia ta');
      expect(done, isTrue);
      expect(firstTry, isFalse);
    });
  });

  group('reveal', () {
    const it = LessonInteractive(
      kind: 'reveal',
      title: 'Mituri',
      reveals: [
        RevealCard('Mitul unu', 'Adevărul unu'),
        RevealCard('Mitul doi', 'Adevărul doi'),
      ],
    );

    testWidgets('gate-ul se deschide după ce toate cardurile sunt întoarse', (
      tester,
    ) async {
      var done = false;
      await tester.pumpWidget(
        _app(buildInteractive(it, onDone: (d) => done = d)),
      );

      expect(find.text('Adevărul unu'), findsNothing);
      await tester.tap(find.text('Mitul unu'));
      await tester.pumpAndSettle();
      expect(find.text('Adevărul unu'), findsOneWidget);
      expect(done, isFalse);

      await tester.tap(find.text('Mitul doi'));
      await tester.pumpAndSettle();
      expect(find.text('Adevărul doi'), findsOneWidget);
      expect(done, isTrue);
    });
  });
}
