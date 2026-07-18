import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/engine/streak_rules.dart';
import '../../features/gamification/data/gamification_service.dart';
import '../ui/tokens.dart';
import '../ui/clay.dart';
import '../ui/juice.dart';
import '../ui/svg_icon.dart';
import 'onboarding_gate.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/learning/presentation/lesson_player_screen.dart';
import '../../features/learning/presentation/review_screen.dart';
import '../../features/learning/presentation/unit_path_screen.dart';
import '../../features/arcade/presentation/arcade_screen.dart';
import '../../features/arcade/presentation/daily_challenge_screen.dart';
import '../../features/arcade/presentation/dojo_screen.dart';
import '../../features/arcade/presentation/turbo_budget_screen.dart';
import '../../features/arcade/life_month/presentation/life_month_intro_screen.dart';
import '../../features/arcade/life_month/presentation/life_month_screen.dart';
import '../../features/arcade/life_month/presentation/life_month_report_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/streak/presentation/streak_screen.dart';
import '../../features/tracking/presentation/add_expense_screen.dart';
import '../../features/finbot/presentation/finbot_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_screen.dart';
import '../../features/notifications/data/notification_scheduler.dart';

/// Construiește [GoRouter] al aplicației. Redirect-ul aplică gate-ul de
/// onboarding în ambele sensuri: neterminații ajung mereu în wizard, cei
/// terminați nu se mai pot întoarce în el.
GoRouter buildRouter({String initialLocation = '/onboarding'}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final inWizard = state.matchedLocation.startsWith('/onboarding');
      if (!OnboardingGate.done && !inWizard) return '/onboarding';
      if (OnboardingGate.done && inWizard) return '/home';
      return null;
    },
    routes: [
      // Rute fullscreen, în afara tab shell-ului.
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/add',
        builder: (_, state) => AddExpenseScreen(
          initialType: state.uri.queryParameters['type'],
          initialGoalId: state.uri.queryParameters['goal'],
        ),
      ),
      GoRoute(path: '/finbot', builder: (_, _) => const FinbotScreen()),
      GoRoute(path: '/challenges', builder: (_, _) => const StreakScreen()),
      GoRoute(path: '/recurring', builder: (_, _) => const RecurringScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(path: '/garderoba', builder: (_, _) => const WardrobeScreen()),

      // Shell cu taburi și BottomNav mereu vizibil
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (_, _) => const LearningScreen(),
                routes: [
                  GoRoute(
                    path: 'lesson/:id',
                    builder: (_, state) => LessonPlayerScreen(
                      lessonId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'unit/:uid',
                    builder: (_, state) =>
                        UnitPathScreen(unitId: state.pathParameters['uid']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/arcade',
                builder: (_, _) => const ArcadeScreen(),
                routes: [
                  // Jocurile sunt sub-ecrane deschise din hub-ul Arcade.
                  GoRoute(path: 'dojo', builder: (_, _) => const DojoScreen()),
                  GoRoute(
                    path: 'daily',
                    builder: (_, _) => const DailyChallengeScreen(),
                  ),
                  GoRoute(
                    path: 'turbo',
                    builder: (_, _) => const TurboBudgetScreen(),
                  ),
                  // „30 de Zile”: intro → joc → raport. Runda se pasează prin
                  // `extra` (id); dacă lipsește, ecranele cad pe runda activă
                  // / ultima terminată.
                  GoRoute(
                    path: 'luna',
                    builder: (_, _) => const LifeMonthIntroScreen(),
                  ),
                  GoRoute(
                    path: 'luna/joc',
                    builder: (_, state) =>
                        LifeMonthScreen(runId: state.extra as String?),
                  ),
                  GoRoute(
                    path: 'luna/raport',
                    builder: (_, state) =>
                        LifeMonthReportScreen(runId: state.extra as String?),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Scaffold-ul shell-ului: găzduiește tab-ul activ + [BottomNav] partajat.
/// FAB-ul central deschide fluxul de add-expense.
class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _AppShell({required this.shell});

  void _goBranch(int index) {
    // `initialLocation: true` readuce branch-ul la root când e re-apăsat.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bornele de streak (7/30/100/365) sunt moment EPIC oriunde s-ar atinge.
    // Un singur detector aici, pe emisiile providerului (zero timere, zero
    // curse), streak-ul crește o dată pe zi, deci borna se vede o singură dată.
    ref.listen(streakViewProvider, (prev, next) {
      final before = prev?.valueOrNull?.current;
      final now = next.valueOrNull?.current;
      if (before != null &&
          now != null &&
          now > before &&
          streakMilestones.containsKey(now)) {
        Juice.epic();
        ConfettiBurst.show(context);
      }
    });

    // La fiecare deschidere replanificăm escaladarea D1/D3/D7, notificările
    // „de absență" trăiesc doar dacă utilizatorul chiar lipsește.
    ref.watch(notificationsRescheduleProvider);

    final l10n = AppLocalizations.of(context)!;
    final items = [
      NavItem(Ic.home, l10n.tabHome),
      NavItem(Ic.book, l10n.tabLearn),
      NavItem(Ic.target, l10n.tabArcade),
      NavItem(Ic.user, l10n.tabProfile),
    ];

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          Expanded(child: shell),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00EAF1FB), C.bg],
                stops: [0.0, 0.42],
              ),
            ),
            child: BottomNav(
              active: shell.currentIndex,
              items: items,
              onTap: _goBranch,
              onFab: () => context.push('/add'),
            ),
          ),
        ],
      ),
    );
  }
}
