import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/ui/juice.dart';
import 'package:finedu_flutter/core/ui/tokens.dart';

void main() {
  testWidgets('AnimatedCount lands exactly on the final value',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedCount(
          value: 40, prefix: '+', suffix: ' XP', style: T.display(size: 16)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('+40 XP'), findsOneWidget);
  });

  testWidgets('AnimatedCount skips the tween under reduce-motion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: AnimatedCount(value: 40, style: T.display(size: 16)),
      ),
    ));
    // Un singur frame, valoarea finală trebuie să fie deja acolo.
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('JuiceShake moves the child when trigger changes, then settles',
      (tester) async {
    Future<void> pumpWith(int trigger) => tester.pumpWidget(MaterialApp(
          home: JuiceShake(trigger: trigger, child: const Text('X')),
        ));

    await pumpWith(0);
    await pumpWith(1); // trigger schimbat → pornește scuturarea
    await tester.pump(const Duration(milliseconds: 80));
    final mid = tester.getTopLeft(find.text('X'));
    expect(mid.dx, isNot(0), reason: 'la mijlocul animației e deplasat');
    await tester.pumpAndSettle();
  });

  testWidgets('JuiceShake is a no-op under reduce-motion', (tester) async {
    Future<void> pumpWith(int trigger) => tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: JuiceShake(trigger: trigger, child: const Text('X')),
          ),
        ));

    await pumpWith(0);
    final before = tester.getTopLeft(find.text('X'));
    await pumpWith(1);
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getTopLeft(find.text('X')), before);
    await tester.pumpAndSettle();
  });

  testWidgets('ConfettiBurst inserts an overlay and removes itself',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));

    ConfettiBurst.show(ctx);
    await tester.pump();
    expect(find.byType(CustomPaint).hitTestable(), findsWidgets);

    // După Dur.epic (1200ms) overlay-ul dispare singur.
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ConfettiOverlay'),
        findsNothing);
  });

  testWidgets(
      'ConfettiBurst does not steal taps: one tap hits the button below '
      'AND dismisses the burst', (tester) async {
    late BuildContext ctx;
    var pressed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return Center(
            child: ElevatedButton(
              onPressed: () => pressed++,
              child: const Text('Continuă'),
            ),
          );
        }),
      ),
    ));

    ConfettiBurst.show(ctx);
    await tester.pump();
    await tester.tap(find.text('Continuă'));
    await tester.pumpAndSettle();

    expect(pressed, 1, reason: 'confetti-ul nu are voie să înghită tap-ul');
    expect(
        find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ConfettiOverlay'),
        findsNothing,
        reason: 'același tap face și skip pe confetti');
  });

  testWidgets('ConfettiBurst is a no-op under reduce-motion', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    ));

    ConfettiBurst.show(ctx);
    await tester.pump();
    expect(
        find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ConfettiOverlay'),
        findsNothing);
  });
}
