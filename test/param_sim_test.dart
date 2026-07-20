import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/features/learning/data/lessons_repository.dart';
import 'package:finedu_flutter/features/learning/presentation/interactives.dart';
import 'package:finedu_flutter/features/learning/presentation/param_sim.dart';

LessonInteractive _sim({
  List<String> exposed = const ['years'],
  bool inflation = false,
  bool race = false,
  int yearsDefault = 10,
}) {
  return LessonInteractive(
    kind: 'param_sim',
    title: 'Mișcă anii și privește',
    sim: SimConfig(
      exposed: exposed,
      yearsDefault: yearsDefault,
      yearsMax: 30,
      monthlyDefault: 100,
      rateDefault: 5.5,
      inflation: inflation,
      race: race,
    ),
  );
}

Widget _app(LessonInteractive it) => MaterialApp(
  home: Scaffold(body: ParamSimInteractive(it: it)),
);

void main() {
  testWidgets('renders headline with compound total and exposed sliders only', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_sim()));
    await tester.pump();

    // 100 lei/lună, 5,5%, 10 ani → total > depuneri (12.000).
    expect(find.textContaining('în 10 ani'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget, reason: 'doar anii expuși');
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Pui deoparte pe lună'), findsNothing);
    // Badge-ul regulii lui 72: 72/5.5 ≈ 13.
    expect(find.textContaining('Regula lui 72'), findsOneWidget);
    expect(find.textContaining('~13 ani'), findsOneWidget);
  });

  testWidgets('full lab exposes 3 sliders + inflation and race toggles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _sim(
          exposed: ['years', 'monthly', 'rate'],
          inflation: true,
          race: true,
          yearsDefault: 15,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Slider), findsNWidgets(3));
    expect(
      find.textContaining('4-7%'),
      findsOneWidget,
      reason: 'eticheta de onestitate RO pe slider-ul de rată',
    );
    expect(find.textContaining('Valoarea reală'), findsOneWidget);
    expect(find.textContaining('Cursa: Ana'), findsOneWidget);
  });

  testWidgets('race mode shows Ana vs Vlad with the difference comment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_sim(exposed: ['years', 'monthly', 'rate'], race: true)),
    );
    await tester.pump();

    await tester.ensureVisible(find.textContaining('Cursa: Ana'));
    await tester.tap(find.textContaining('Cursa: Ana'));
    await tester.pump();

    expect(find.textContaining('Ana · de la 16'), findsOneWidget);
    expect(find.textContaining('Vlad · de la 26'), findsOneWidget);
    // Comentariul e pe DIFERENȚĂ, nu pe câștigător.
    expect(find.textContaining('Vlad nu e pierzător'), findsOneWidget);
  });

  testWidgets('inflation toggle draws the dashed real-value legend', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_sim(inflation: true)));
    await tester.pump();

    expect(find.text('Valoarea reală'), findsNothing);
    await tester.tap(find.textContaining('Valoarea reală (inflație'));
    await tester.pump();
    expect(find.text('Valoarea reală'), findsOneWidget, reason: 'în legendă');
  });

  testWidgets('"Cum calculăm?" expands the formula + disclaimer', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_sim()));
    await tester.pump();

    expect(
      find.textContaining('model educativ', findRichText: true),
      findsNothing,
    );
    await tester.tap(find.text('Cum calculăm?'));
    await tester.pump();
    expect(find.textContaining('Model educativ'), findsOneWidget);
    expect(find.textContaining('sold nou = sold'), findsOneWidget);
  });

  test('param_sim never gates the lesson advance (sandbox, AADC)', () {
    expect(interactiveGatesAdvance('param_sim'), isFalse);
    expect(interactiveGatesAdvance('mcq'), isTrue);
  });
}
