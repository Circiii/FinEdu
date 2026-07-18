import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/db_provider.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_content.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_engine.dart'
    as engine;
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_scoring.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_state.dart';
import 'package:finedu_flutter/domain/engine/life_sim/money.dart';
import 'package:finedu_flutter/domain/util/day_key.dart';
import 'package:finedu_flutter/features/arcade/life_month/data/life_month_repository.dart';
import 'package:finedu_flutter/features/arcade/life_month/presentation/life_month_intro_screen.dart';
import 'package:finedu_flutter/features/arcade/life_month/presentation/life_month_report_screen.dart';
import 'package:finedu_flutter/features/arcade/life_month/presentation/life_month_screen.dart';
import 'package:finedu_flutter/features/wardrobe/presentation/cashy_avatar.dart';

// ---------------------------------------------------------------------------
// Fixture de conținut INLINE (nu depinde de asset-uri reale, pot lipsi).
// 1 rol, 1 obiectiv, 1 recurentă, 2 finaluri, 1 eveniment (min_day 2, max_day 25
// → ziua 1 e liniștită iar zilele 26-30 nu au niciun eveniment).
// ---------------------------------------------------------------------------

Map<String, dynamic> _bi(String s) => {'ro': s, 'en': s};

LifeSimContent _fixtureContent() {
  final manifest = {'contentVersion': '1.0.0-test'};
  final roles = {
    'version': '1.0.0-test',
    'roles': [
      {
        'id': 'r1',
        'emoji': '🧪',
        'name': _bi('Rol de test'),
        'bio': _bi('O viață de test, într-un oraș de test.'),
        'age': 22,
        'salary': {'net_min': 2500, 'net_max': 3500, 'scenario_net': 3000},
        'pay_day': 1,
        'salary_variability': 0.0,
        'city_profile': 'oras_mare',
        'housing': 'chirie',
        'transport': 'bicicleta',
        'initial_cash': 100000, // 1000 lei
        'initial_fund': 50000, // 500 lei
        'bills': ['chirie'],
        'risks': _bi('Venit fix, dar chirie mare.'),
        'goal_default': 'g1',
      },
    ],
  };
  final recurring = {
    'recurring': [
      {
        'id': 'chirie',
        'kind': 'bill',
        'name': _bi('Chirie'),
        'amount': 90000,
        'due_day': 5,
        'category': 'housing',
        'miss_effects': [
          {'type': 'cash', 'delta': -10000},
        ],
      },
    ],
  };
  final goals = {
    'goals': [
      {'id': 'g1', 'name': _bi('Garsonieră'), 'target_bani': 200000, 'why': _bi('Casa mea.')},
    ],
  };
  final endings = {
    'endings': [
      {
        'id': 'strategul',
        'title': _bi('Strategul'),
        'description': _bi('Ai ținut cârma strâns.'),
        'thresholds': {'control': 60, 'rezilienta': 50},
      },
      {
        'id': 'navigatorul',
        'title': _bi('Navigatorul de furtună'),
        'description': _bi('Ai trecut prin valuri.'),
      },
    ],
  };
  final events = {
    'events': [
      {
        'id': 'ev_test',
        'category': 'work',
        'weight': 10,
        'min_day': 2,
        'max_day': 25,
        'difficulty': 1,
        'skill_tags': ['budgeting'],
        'title': _bi('Eveniment test'),
        'narrative': _bi('Trebuie să alegi.'),
        'choices': [
          {
            'label': _bi('Cheltui (-10 lei)'),
            'effects': [
              {'type': 'cash', 'delta': -1000},
            ],
            'debrief': _bi('...'),
          },
          {'label': _bi('Nu faci nimic'), 'effects': [], 'debrief': _bi('...')},
        ],
      },
    ],
  };
  return LifeSimContent.fromJsonBundle({
    'content/life_sim/manifest.json': jsonEncode(manifest),
    'content/life_sim/roles.json': jsonEncode(roles),
    'content/life_sim/recurring.json': jsonEncode(recurring),
    'content/life_sim/goals.json': jsonEncode(goals),
    'content/life_sim/endings.json': jsonEncode(endings),
    'content/life_sim/events/pack.json': jsonEncode(events),
  });
}

// ---------------------------------------------------------------------------
// Helpers de test.
// ---------------------------------------------------------------------------

ProviderContainer _container(AppDb db, LifeSimContent content) {
  final c = ProviderContainer(overrides: [
    appDbProvider.overrideWithValue(db),
    lifeSimContentProvider.overrideWith((ref) => content),
    // Evită dependența avatarului de garderobă/profil în teste.
    equippedLookProvider.overrideWithValue((bg: null, accessory: null)),
  ]);
  return c;
}

GoRouter _router(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
            path: '/arcade',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('ARCADE_HUB')))),
        GoRoute(
            path: '/arcade/luna',
            builder: (_, _) => const LifeMonthIntroScreen()),
        GoRoute(
            path: '/arcade/luna/joc',
            builder: (_, s) => LifeMonthScreen(runId: s.extra as String?)),
        GoRoute(
            path: '/arcade/luna/raport',
            builder: (_, s) => LifeMonthReportScreen(runId: s.extra as String?)),
        GoRoute(
            path: '/learn',
            builder: (_, _) => const Scaffold(body: Center(child: Text('LEARN')))),
      ],
    );

Future<void> _pump(WidgetTester tester, ProviderContainer container,
    String initial) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: _router(initial)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final content = _fixtureContent();

  // =========================================================================
  // Repository unit tests
  // =========================================================================

  group('LifeMonthRepository', () {
    late AppDb db;
    late LocalProfileRepository profiles;
    late LifeMonthRepository repo;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      profiles = LocalProfileRepository(db);
      repo = LifeMonthRepository(db, profiles);
    });
    tearDown(() => db.close());

    test('createRun persistă rândul și întoarce starea (ziua 0)', () async {
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 7);
      expect(run.state.day, 0);
      expect(run.state.cash.bani, 100000);
      final rows = await db.select(db.lifeSimRuns).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, run.id);
      expect(rows.single.seed, 7);
      expect(rows.single.completedAt, isNull);
    });

    test('saveSnapshot actualizează ziua + stateJson; activeRun le reflectă',
        () async {
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 7);
      final advanced = engine.advanceDay(run.state, content).state; // ziua 1
      await repo.saveSnapshot(run.id, advanced);
      final active = await repo.activeRun();
      expect(active, isNotNull);
      expect(active!.id, run.id);
      expect(active.state.day, 1);
      expect(active.state.cash.bani, 100000 + 300000); // + salariu 3000 lei
    });

    test('activeRun e null când nu există runde neterminate', () async {
      expect(await repo.activeRun(), isNull);
    });

    test('completeRun: prima terminare a zilei plătește 15🌰 + 30 XP o dată',
        () async {
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 1);
      final st = run.state.copyWith(day: 30);
      final sc = score(st, content);

      final res = await repo.completeRun(runId: run.id, state: st, score: sc);
      expect(res.acornsAwarded, 15);
      expect(res.xpAwarded, 30);
      expect(res.improved, isFalse);

      final profile = await profiles.get();
      expect(profile.acorns, 15);
      expect(profile.xp, 30);

      // Rândul e marcat terminat + resultJson scris.
      final row = await (db.select(db.lifeSimRuns)
            ..where((r) => r.id.equals(run.id)))
          .getSingle();
      expect(row.completedAt, isNotNull);
      expect(row.resultJson, isNotNull);

      // Ledger: exact o intrare 'life_sim_complete'.
      final ledger = await (db.select(db.acornEntries)
            ..where((e) => e.reason.equals('life_sim_complete')))
          .get();
      expect(ledger, hasLength(1));
      expect(ledger.single.delta, 15);
    });

    test('plafon: a doua terminare din aceeași zi nu plătește', () async {
      final a = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 1);
      final b = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 2);
      final sa = a.state.copyWith(day: 30);
      final sb = b.state.copyWith(day: 30);

      final first =
          await repo.completeRun(runId: a.id, state: sa, score: score(sa, content));
      expect(first.acornsAwarded, 15);
      final second =
          await repo.completeRun(runId: b.id, state: sb, score: score(sb, content));
      expect(second.acornsAwarded, 0);
      expect(second.xpAwarded, 0);
      // Runda b e totuși marcată terminată.
      final row = await (db.select(db.lifeSimRuns)
            ..where((r) => r.id.equals(b.id)))
          .getSingle();
      expect(row.completedAt, isNotNull);
    });

    test(
        'completeRun pe o rundă DEJA terminată nu mai recompensează (o rundă '
        'se plătește o dată în viața ei, nu o dată pe zi)', () async {
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 11);
      final st = run.state.copyWith(day: 30);
      final sc = score(st, content);

      final first =
          await repo.completeRun(runId: run.id, state: st, score: sc);
      expect(first.acornsAwarded, 15);
      expect(first.xpAwarded, 30);

      // Reapelat pe ACEEAȘI rundă (deja completedAt != null), chiar dacă
      // ledger-ul de azi ar mai avea loc de plată, nu se mai plătește nimic.
      final second =
          await repo.completeRun(runId: run.id, state: st, score: sc);
      expect(second.acornsAwarded, 0);
      expect(second.xpAwarded, 0);
      expect(second.improved, isFalse);

      // Ledger-ul nu are decât intrarea din prima terminare.
      final ledger = await (db.select(db.acornEntries)
            ..where((e) => e.reason.equals('life_sim_complete')))
          .get();
      expect(ledger, hasLength(1));
      final profile = await profiles.get();
      expect(profile.acorns, 15);
      expect(profile.xp, 30);
    });

    test('bonus de îmbunătățire pe același seed (rundă anterioară pe zi trecută)',
        () async {
      // Rundă anterioară A: același seed, terminată IERI (fără ledger azi), scor 40.
      final base = engine
          .createRun(c: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 999)
          .copyWith(day: 30);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.into(db.lifeSimRuns).insert(LifeSimRunsCompanion.insert(
            id: 'A',
            seed: 999,
            roleId: 'r1',
            goalId: 'g1',
            mode: 'realist',
            contentVersion: '1.0.0-test',
            stateJson: jsonEncode(base.toJson()),
            startedAt: yesterday,
            completedAt: Value(yesterday),
            resultJson: Value(jsonEncode(const LifeSimScore(
              control: 50,
              rezilienta: 50,
              obiective: 40,
              echilibru: 40,
              total: 40,
              endingId: 'navigatorul',
            ).toJson())),
          ));

      // Rundă B: același seed, scor 60 azi → 15 + 10 (improve).
      final b = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 999);
      const better = LifeSimScore(
        control: 70,
        rezilienta: 60,
        obiective: 55,
        echilibru: 55,
        total: 60,
        endingId: 'strategul',
      );
      final res = await repo.completeRun(
          runId: b.id, state: b.state.copyWith(day: 30), score: better);
      expect(res.improved, isTrue);
      expect(res.previousBest, 40);
      expect(res.acornsAwarded, 25);

      final improveLedger = await (db.select(db.acornEntries)
            ..where((e) => e.reason.equals('life_sim_improve')))
          .get();
      expect(improveLedger.single.delta, 10);
    });

    test('rewardReflection plătește o dată pe zi', () async {
      expect(await repo.rewardReflection(), 5);
      expect(await repo.rewardReflection(), 0); // plafonat
    });
  });

  // =========================================================================
  // Widget tests
  // =========================================================================

  group('LifeMonth widgets', () {
    late AppDb db;
    late ProviderContainer container;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      container = _container(db, content);
    });
    tearDown(() {
      container.dispose();
      db.close();
    });

    testWidgets('intro randează modurile și rolul', (tester) async {
      await _pump(tester, container, '/arcade/luna');
      expect(find.text('Prima lună'), findsOneWidget);
      expect(find.text('Pe cont propriu'), findsOneWidget);
      expect(find.text('Rol de test'), findsOneWidget);
      expect(find.text('Începe'), findsOneWidget);
    });

    testWidgets('pornirea unui run ajunge la ecranul principal cu „+ O zi"',
        (tester) async {
      await _pump(tester, container, '/arcade/luna');
      await tester.ensureVisible(find.text('Începe'));
      await tester.tap(find.text('Începe'));
      await tester.pumpAndSettle();
      // Cardul de identitate.
      expect(find.text('Începe luna'), findsOneWidget);
      await tester.ensureVisible(find.text('Începe luna'));
      await tester.tap(find.text('Începe luna'));
      await tester.pumpAndSettle();
      // Ecranul principal.
      expect(find.text('+ O zi'), findsOneWidget);
      expect(find.text('din 30'), findsOneWidget);
    });

    testWidgets('avansarea unei zile liniștite mișcă ziua și balanța',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 42);

      await _pump(tester, container, '/arcade/luna/joc');
      expect(find.text('+ O zi'), findsOneWidget);

      await tester.tap(find.text('+ O zi'));
      await tester.pumpAndSettle();
      // Ziua 1 = zi de salariu → foaia de alocare. Sărim peste.
      expect(find.text('Sar peste'), findsOneWidget);
      await tester.tap(find.text('Sar peste'));
      await tester.pumpAndSettle();

      expect(find.text('Ziua 1'), findsOneWidget);
      // Balanța: 1000 + 3000 salariu = 4.000 lei.
      expect(find.textContaining('4.000 lei'), findsWidgets);
    });

    testWidgets('o zi cu eveniment arată foaia; alegerea persistă decizia',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 5);
      // Aducem starea la ziua 1 și programăm ev_test pentru ziua 2 (prioritate).
      var st = engine.advanceDay(run.state, content).state; // ziua 1 + salariu
      st = st.copyWith(scheduledEvents: [(2, 'ev_test')]);
      await repo.saveSnapshot(run.id, st);

      await _pump(tester, container, '/arcade/luna/joc');
      expect(find.text('Ziua 1'), findsOneWidget);

      await tester.tap(find.text('+ O zi'));
      await tester.pumpAndSettle();
      // Foaia de eveniment.
      expect(find.text('Eveniment test'), findsOneWidget);
      expect(find.text('Nu faci nimic'), findsOneWidget);

      await tester.tap(find.text('Nu faci nimic'));
      await tester.pumpAndSettle();

      // Decizia s-a persistat în ledger-ul de decizii.
      final decisions = await db.select(db.lifeSimDecisions).get();
      expect(decisions, hasLength(1));
      expect(decisions.single.eventId, 'ev_test');
      expect(decisions.single.choiceIdx, 1);
    });

    testWidgets('terminarea la ziua 30 scrie rezultatul + recompensa o dată',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 3);
      // Sărim la ziua 29 (zilele 26-30 nu au evenimente → avansul e liniștit).
      await repo.saveSnapshot(run.id, run.state.copyWith(day: 29));

      await _pump(tester, container, '/arcade/luna/joc');
      expect(find.text('Ziua 29'), findsOneWidget);

      await tester.tap(find.text('+ O zi'));
      await tester.pumpAndSettle();

      // Am ajuns la raport (fără decizii → direct scorul).
      expect(find.text('SCORUL LUNII'), findsOneWidget);

      // Rândul e terminat cu rezultat.
      final row = await (db.select(db.lifeSimRuns)
            ..where((r) => r.id.equals(run.id)))
          .getSingle();
      expect(row.completedAt, isNotNull);
      expect(row.resultJson, isNotNull);

      // Ledger: exact o recompensă de terminare azi.
      final today = dayKey(DateTime.now());
      final ledger = await (db.select(db.acornEntries)
            ..where((e) => e.reason.equals('life_sim_complete')))
          .get();
      final todayEntries =
          ledger.where((e) => dayKey(e.createdAt) == today).toList();
      expect(todayEntries, hasLength(1));
      expect(todayEntries.single.delta, 15);
    });

    testWidgets(
        'dublu-tap pe „Vezi raportul" la resume-ul zilei 30 nu recompensează '
        'de două ori (butonul se dezactivează la primul tap)', (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'realist', seed: 77);
      // Rundă deja la ziua 30, ex. resume după o terminare întreruptă.
      await repo.saveSnapshot(run.id, run.state.copyWith(day: 30));

      await _pump(tester, container, '/arcade/luna/joc');
      expect(find.text('Vezi raportul'), findsOneWidget);

      // Dublu-tap ÎNAINTE de orice pump, reproduce cursa reală: al doilea
      // tap trebuie să lovească guard-ul `_busy` (setat sincron la primul).
      await tester.tap(find.text('Vezi raportul'));
      await tester.tap(find.text('Vezi raportul'));
      await tester.pumpAndSettle();

      expect(find.text('SCORUL LUNII'), findsOneWidget);
      final ledger = await (db.select(db.acornEntries)
            ..where((e) => e.reason.equals('life_sim_complete')))
          .get();
      expect(ledger, hasLength(1));
      final profile = await container.read(localProfileRepositoryProvider).get();
      expect(profile.acorns, 15);
      expect(profile.xp, 30);
    });

    testWidgets('resume: încărcarea din snapshot arată aceeași zi și cash',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 42);
      // Avansăm 3 zile în motor și salvăm instantaneul.
      var st = run.state;
      for (var i = 0; i < 3; i++) {
        final r = engine.advanceDay(st, content);
        st = r.state;
        if (r.event != null) st = engine.applyChoice(st, r.event!, 1, content);
      }
      await repo.saveSnapshot(run.id, st);

      await _pump(tester, container, '/arcade/luna/joc');
      expect(find.text('Ziua ${st.day}'), findsOneWidget);
      expect(find.textContaining(st.cash.lei), findsWidgets);
    });

    // --- Noul layout 2.0: stat-uri, portofel cu datorii, calendar cu restanțe -

    testWidgets('rândul de stat-uri există și deschide foaia care le explică',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 42);

      await _pump(tester, container, '/arcade/luna/joc');
      // Rândul celor 4 mini-bare de viață e pe ecranul principal.
      expect(find.byKey(const Key('lifeStatsRow')), findsOneWidget);

      await tester.tap(find.byKey(const Key('lifeStatsRow')));
      await tester.pumpAndSettle();
      expect(find.text('Cele 4 stat-uri de viață'), findsOneWidget);
      expect(find.text('Sănătate'), findsOneWidget);
      expect(find.text('Relații'), findsOneWidget);
    });

    testWidgets(
        'Portofelul deschide sumele rapide și plata anticipată a datoriei',
        (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 8);
      // Injectăm o datorie ca să apară secțiunea „Datorii" cu butonul de plată.
      final withDebt = run.state.copyWith(debts: const [
        DebtState(
          id: 'imprumut',
          principal: Money(200000),
          monthly: Money(20000),
          dueDay: 12,
        ),
      ]);
      await repo.saveSnapshot(run.id, withDebt);

      await _pump(tester, container, '/arcade/luna/joc');
      // Rândul de acces e sub prag pe ecranul de test: îl aducem în vizor.
      await tester.ensureVisible(find.text('Portofel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portofel'));
      await tester.pumpAndSettle();

      // Foaia nouă: sume rapide 50/250 și secțiunea de datorii.
      expect(find.text('MUTĂ BANI'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('DATORII'), findsOneWidget);
      expect(find.text('Plătește'), findsOneWidget);

      // Plata anticipată scade principalul prin motor (cash 1000 lei acoperă 100).
      await tester.ensureVisible(find.text('Plătește'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plătește'));
      await tester.pumpAndSettle();
      final saved = await repo.getRun(run.id);
      expect(saved!.state.debts.single.principal.bani, lessThan(200000));
    });

    testWidgets('Calendarul arată restanțele injectate în stare', (tester) async {
      final repo = container.read(lifeMonthRepositoryProvider);
      final run = await repo.createRun(
          content: content, roleId: 'r1', goalId: 'g1', mode: 'ghidat', seed: 9);
      // Chiria (ziua 5) ratată, cu ziua curentă trecută de scadență.
      final withArrears = run.state.copyWith(
        day: 8,
        arrears: const [('chirie', 5)],
        missedBills: const [('chirie', 5)],
      );
      await repo.saveSnapshot(run.id, withArrears);

      await _pump(tester, container, '/arcade/luna/joc');
      await tester.ensureVisible(find.text('Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('Calendarul facturilor'), findsOneWidget);
      expect(find.textContaining('Se sting automat'), findsOneWidget);
    });
  });
}
