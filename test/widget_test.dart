// Smoke tests for the FinEdu shell, Arcade tab and the data-driven Home.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/db_provider.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/core/router/app_router.dart';
import 'package:finedu_flutter/core/router/onboarding_gate.dart';
import 'package:finedu_flutter/core/ui/tokens.dart';
import 'package:finedu_flutter/features/tracking/data/transactions_repository.dart';
import 'package:finedu_flutter/l10n/app_localizations.dart';

/// Boots the router straight into the tab shell at `/home` with an in-memory
/// database, skipping onboarding.
Widget _testApp(AppDb db) {
  OnboardingGate.done = true;
  final router = buildRouter(initialLocation: '/home');
  return ProviderScope(
    overrides: [appDbProvider.overrideWithValue(db)],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: C.bg, useMaterial3: true),
      routerConfig: router,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ro'), Locale('en')],
      locale: const Locale('ro'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDb db;

  setUp(() => db = AppDb(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('shell renders with bottom nav and Arcade tab works',
      (tester) async {
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    expect(find.text('Acasă'), findsOneWidget);
    expect(find.text('Învață'), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    expect(find.text('Poiana de Joacă'), findsNothing);

    await tester.tap(find.text('Arcade'));
    await tester.pumpAndSettle();

    expect(find.text('Poiana de Joacă'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('Home shows real profile + transactions data', (tester) async {
    // Seed: a named profile with a budget and two expenses this month.
    final profiles = LocalProfileRepository(db);
    await profiles.update(LocalProfilesCompanion(
      cashyName: const Value('Ronți'),
      monthlyBudget: const Value(1000),
    ));
    final repo = TransactionsRepository(db);
    await repo.addExpense(amount: 120, category: 'mancare');
    await repo.addExpense(amount: 80, category: 'transport');

    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    // Cashy's chosen name is greeted.
    expect(find.text('Ronți'), findsOneWidget);
    // Both seeded transactions are listed with their amounts.
    expect(find.text('−120 lei'), findsOneWidget);
    expect(find.text('−80 lei'), findsOneWidget);
    // Total spent (200 of 1000) → 20% in the budget ring.
    expect(find.text('200'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);

    await _flushTimers(tester);
  });
}

/// Disposes the tree and advances fake time: drift's stream query store keeps
/// a short keep-alive timer after the last unsubscribe, which would otherwise
/// trip the `!timersPending` teardown invariant.
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}
