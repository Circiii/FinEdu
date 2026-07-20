import 'dart:convert';

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/daily_challenge.dart';
import '../../../domain/util/day_key.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/data/gamification_service.dart';
import '../../home/data/home_providers.dart';
import '../data/arcade_repository.dart';
import '../data/dojo_repository.dart';
import '../life_month/data/life_month_repository.dart';

/// Hub-ul Arcade („Poiana de Joacă"), pastile reale de streak/ghinde, bonusul
/// zilei rotativ, cele trei jocuri cu starea lor și teaser-ele v2.
class ArcadeScreen extends ConsumerWidget {
  const ArcadeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final streak = ref.watch(streakViewProvider).valueOrNull?.current ?? 0;
    final acorns =
        ref.watch(localProfileStreamProvider).valueOrNull?.acorns ?? 0;
    final today = dayKey(DateTime.now());
    final bonusGame = dailyBonusGame(today);
    final dailyRound = ref.watch(dailyRoundTodayProvider).valueOrNull;
    final turboBest = ref.watch(turboBestProvider).valueOrNull;
    final activeLifeRun = ref.watch(activeRunProvider).valueOrNull;

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AcornRain()),
          Column(
            children: [
              const StatusBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Row(
                  children: [
                    _statPill(const FlameIcon(size: 17), streak),
                    const SizedBox(width: 8),
                    _statPill(const AcornIcon(size: 17), acorns),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cardurile jocurilor intră în cascadă.
                      StaggerIn(index: 0, child: _header(l10n)),
                      const SizedBox(height: 12),
                      StaggerIn(index: 1, child: _bonusBanner(bonusGame)),
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 2,
                        child: _lifeMonthCard(context, activeLifeRun),
                      ),
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 3,
                        child: _dailyCard(context, today, dailyRound),
                      ),
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 4,
                        child: _turboCard(context, turboBest),
                      ),
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 5,
                        child: _dojoCard(
                          context,
                          l10n,
                          ref.watch(dojoStateProvider).valueOrNull,
                        ),
                      ),
                      const SizedBox(height: 14),
                      StaggerIn(index: 6, child: _stejarCard(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(Widget icon, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: C.line, width: 1),
          boxShadow: Sh.raise,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            JuiceBounce(
              trigger: value,
              child: AnimatedCount(
                value: value,
                duration: const Duration(milliseconds: 700),
                style: T.display(
                  size: 16,
                  weight: FontWeight.w800,
                  color: C.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.arcadeTitle,
            style: T.display(
              size: 28,
              weight: FontWeight.w800,
              color: C.text,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.arcadeSubtitle,
            style: T.body(
              size: 14,
              weight: FontWeight.w500,
              color: C.text2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bonusul zilei rotativ, reîmprospătează hub-ul zilnic, fără conținut nou.
  Widget _bonusBanner(String bonusGame) {
    final name = switch (bonusGame) {
      'dojo' => 'Scam Dojo',
      'daily' => 'Provocarea Zilei',
      _ => 'Turbo Buget',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: C.amberSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        children: [
          const Pulse(
            scale: 1.15,
            child: Text('🎁', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Bonusul zilei: ghinde duble la prima rundă de $name',
              style: T.body(
                size: 13,
                weight: FontWeight.w700,
                color: C.amberInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cardul-flagship: „30 de Zile: Pe Cont Propriu". Mai mare decât restul,
  /// cu accent de gradient. Reia ziua X când există o rundă activă.
  Widget _lifeMonthCard(BuildContext context, LifeMonthRun? active) {
    const grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B86FF), Color(0xFF5D45E0)],
    );
    final resuming = active != null;
    final day = active != null
        ? (active.state.day < 1 ? 1 : active.state.day)
        : 0;
    final route = resuming ? '/arcade/luna/joc' : '/arcade/luna';

    return Pressable(
      onTap: () {
        if (resuming) {
          context.push(route, extra: active.id);
        } else {
          context.push(route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(R.lg),
          boxShadow: Sh.blue,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🗓️', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '30 de Zile: Pe Cont Propriu',
                        style: T.display(
                          size: 20,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Primești salariul. Următorul vine peste 30 de zile.',
                        style: T.body(
                          size: 13,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final chip in const [
                  '12-18 min',
                  'Bugetare',
                  'Simulare',
                  'Consecințe reale',
                ])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(R.pill),
                    ),
                    child: Text(
                      chip,
                      style: T.display(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Butonul principal prinde periodic o sclipire care invită la joc.
            Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(R.pill),
                    boxShadow: Sh.raise,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        resuming ? 'Continuă ziua $day' : 'Începe luna',
                        style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: C.blueDeep,
                          letterSpacing: 15 * 0.03,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SvgIcon(
                        Ic.arrowRight,
                        size: 19,
                        color: C.blueDeep,
                        strokeWidth: 2.6,
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(period: 3600.ms))
                .shimmer(
                  delay: 1600.ms,
                  duration: 1400.ms,
                  color: C.blue.withValues(alpha: 0.22),
                ),
          ],
        ),
      ),
    );
  }

  Widget _dailyCard(BuildContext context, String today, dynamic dailyRound) {
    final format = switch (formatFor(today)) {
      DailyFormat.price => 'Azi: Ghicește prețul',
      DailyFormat.myth => 'Azi: Mit sau Adevăr',
      DailyFormat.dilemma => 'Azi: Dilema',
    };
    final played = dailyRound != null;
    String subtitle = format;
    if (played) {
      final meta =
          jsonDecode(dailyRound.meta as String) as Map<String, dynamic>;
      final isDilemma = meta['format'] == 'dilemma';
      subtitle = isDilemma
          ? '✓ Rezolvată azi'
          : '✓ Rezolvată azi · ${dailyRound.score} / 100';
    }

    return _gameCard(
      context,
      emoji: '🎯',
      title: 'Provocarea Zilei',
      subtitle: subtitle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9D8DFF), Color(0xFF5D45E0)],
      ),
      shadow: Sh.violet,
      accent: C.violetDeep,
      chips: const ['2 min', 'nou în fiecare zi'],
      buttonLabel: played ? 'Vezi rezultatul' : 'Joacă',
      route: '/arcade/daily',
    );
  }

  Widget _turboCard(BuildContext context, int? best) {
    return _gameCard(
      context,
      emoji: '⚡',
      title: 'Turbo Buget',
      subtitle: best == null
          ? 'Nevoie, dorință sau economie?'
          : 'Recordul tău: $best puncte',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3ED67E), Color(0xFF0FA152)],
      ),
      shadow: Sh.green,
      accent: C.greenDeep,
      chips: const ['45 s', 'reflexe', 'combo'],
      buttonLabel: 'Joacă',
      route: '/arcade/turbo',
    );
  }

  Widget _dojoCard(
    BuildContext context,
    AppLocalizations l10n,
    DojoState? state,
  ) {
    final subtitle = state == null || state.rounds == 0
        ? 'Detectează țepele din mesaje.'
        : '${state.belt.$1} Centura ${state.belt.$2} · imunitate ${state.rating}';
    return _gameCard(
      context,
      emoji: '🥷',
      // Animația de țeapă rulează continuu: cardul e despre pericol, iar
      // mișcarea îl ține viu în hub.
      iconWidget: Lottie.asset(
        'assets/lottie/scam_alert.json',
        width: 46,
        height: 46,
        repeat: true,
      ),
      title: l10n.dojoTitle,
      subtitle: subtitle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7D8B), Color(0xFFD63450)],
      ),
      shadow: Sh.danger,
      accent: C.dangerDeep,
      chips: const ['5 mesaje', 'anti-țeapă', 'centuri'],
      buttonLabel: l10n.arcadePlay,
      route: '/arcade/dojo',
    );
  }

  Widget _stejarCard(BuildContext context) {
    return _gameCard(
      context,
      emoji: '🌳',
      title: 'Stejarul lui Cashy',
      subtitle: 'Plantează lei lunar și lasă dobânda să crească copacul.',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2FCB8B), Color(0xFF0B7E5B)],
      ),
      shadow: Sh.green,
      accent: const Color(0xFF0B7E5B),
      chips: const ['simulator', 'dobândă compusă', 'regula 72'],
      buttonLabel: 'Plantează',
      route: '/arcade/stejar',
    );
  }

  /// Card de joc full-gradient: fiecare joc cu identitatea lui de culoare,
  /// chips-uri de gust și CTA alb care preia accentul jocului.
  Widget _gameCard(
    BuildContext context, {
    required String emoji,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required List<BoxShadow> shadow,
    required Color accent,
    required List<String> chips,
    required String buttonLabel,
    required String route,
  }) {
    return Pressable(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(R.lg),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(R.lg),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HubPatternPainter(
                    Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child:
                              iconWidget ??
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: T.display(
                                  size: 19,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: T.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final chip in chips)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(R.pill),
                            ),
                            child: Text(
                              chip,
                              style: T.display(
                                size: 11.5,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(R.pill),
                        boxShadow: Sh.raise,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonLabel,
                            style: T.display(
                              size: 15,
                              weight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 15 * 0.03,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgIcon(
                            Ic.arrowRight,
                            size: 19,
                            color: accent,
                            strokeWidth: 2.6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cerculețe albe discrete pe gradientul cardului, poziții fixe.
class _HubPatternPainter extends CustomPainter {
  const _HubPatternPainter(this.color);

  final Color color;

  static const _spots = [
    (0.86, 0.16, 30.0),
    (0.96, 0.7, 18.0),
    (0.72, 0.94, 12.0),
    (0.58, 0.1, 8.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final (fx, fy, r) in _spots) {
      canvas.drawCircle(Offset(size.width * fx, size.height * fy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_HubPatternPainter old) => old.color != color;
}
