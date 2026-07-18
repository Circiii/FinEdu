import 'dart:convert';

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/juice.dart';
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

const _violetGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB3A7FF), C.violetDeep]);

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
      body: Column(
        children: [
          const StatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                _statPill(const FlameIcon(size: 17), '$streak'),
                const SizedBox(width: 8),
                _statPill(const AcornIcon(size: 17), '$acorns'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(l10n),
                  const SizedBox(height: 12),
                  _bonusBanner(bonusGame),
                  const SizedBox(height: 14),
                  _lifeMonthCard(context, activeLifeRun),
                  const SizedBox(height: 14),
                  _dailyCard(context, today, dailyRound),
                  const SizedBox(height: 14),
                  _turboCard(context, turboBest),
                  const SizedBox(height: 14),
                  _dojoCard(context, l10n,
                      ref.watch(dojoStateProvider).valueOrNull),
                  const SizedBox(height: 14),
                  _lockedCard('🌳', 'Stejarul lui Cashy',
                      'Plantează ghinde. Dobânda compusă le crește.', l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(Widget icon, String value) {
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
            Text(value,
                style:
                    T.display(size: 16, weight: FontWeight.w800, color: C.text)),
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
          Text(l10n.arcadeTitle,
              style: T.display(
                  size: 28, weight: FontWeight.w800, color: C.text,
                  height: 1.05)),
          const SizedBox(height: 4),
          Text(l10n.arcadeSubtitle,
              style: T.body(
                  size: 14, weight: FontWeight.w500, color: C.text2,
                  height: 1.4)),
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
      child: Text('🎁 Bonusul zilei: ghinde duble la prima rundă de $name',
          style: T.body(
              size: 13, weight: FontWeight.w700, color: C.amberInk)),
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
    final day = active != null ? (active.state.day < 1 ? 1 : active.state.day) : 0;
    final route = resuming ? '/arcade/luna/joc' : '/arcade/luna';

    return GestureDetector(
      onTap: () {
        Juice.tick();
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
                      Text('30 de Zile: Pe Cont Propriu',
                          style: T.display(
                              size: 20,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1)),
                      const SizedBox(height: 3),
                      Text(
                          'Primești salariul. Următorul vine peste 30 de zile.',
                          style: T.body(
                              size: 13,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35)),
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
                  'Consecințe reale'
                ])
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(R.pill),
                    ),
                    child: Text(chip,
                        style: T.display(
                            size: 11.5,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                  Text(resuming ? 'Continuă ziua $day' : 'Începe luna',
                      style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: C.blueDeep,
                          letterSpacing: 15 * 0.03)),
                  const SizedBox(width: 8),
                  const SvgIcon(Ic.arrowRight,
                      size: 19, color: C.blueDeep, strokeWidth: 2.6),
                ],
              ),
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
      final meta = jsonDecode(dailyRound.meta as String) as Map<String, dynamic>;
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
      gradient: _violetGrad,
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
          ? '45 s. Nevoie, dorință sau economie?'
          : '45 s pe rundă · recordul tău: $best',
      gradient: Grad.green,
      buttonLabel: 'Joacă',
      route: '/arcade/turbo',
    );
  }

  Widget _dojoCard(
      BuildContext context, AppLocalizations l10n, DojoState? state) {
    final subtitle = state == null || state.rounds == 0
        ? 'Detectează țepele. 5 mesaje pe rundă.'
        : '${state.belt.$1} Centura ${state.belt.$2} · imunitate ${state.rating}';
    return _gameCard(
      context,
      emoji: '🥷',
      title: l10n.dojoTitle,
      subtitle: subtitle,
      gradient: Grad.danger,
      buttonLabel: l10n.arcadePlay,
      route: '/arcade/dojo',
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required String buttonLabel,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push(route);
      },
      child: ClayCard(
        radius: 26,
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
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Sh.raise,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: T.display(
                              size: 19,
                              weight: FontWeight.w800,
                              color: C.text,
                              height: 1.1)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: T.body(
                              size: 13,
                              weight: FontWeight.w500,
                              color: C.text2,
                              height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: Sh.raise,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(buttonLabel,
                      style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 15 * 0.04)),
                  const SizedBox(width: 8),
                  const SvgIcon(Ic.arrowRight,
                      size: 19, color: Colors.white, strokeWidth: 2.6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedCard(
      String emoji, String title, String desc, AppLocalizations l10n) {
    return ClayCard(
      radius: 26,
      shadow: Sh.raise,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: C.inset,
              borderRadius: BorderRadius.circular(16),
              boxShadow: Sh.insetSoft,
            ),
            alignment: Alignment.center,
            child: Opacity(
                opacity: 0.55,
                child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: T.display(
                        size: 17,
                        weight: FontWeight.w800,
                        color: C.text3,
                        height: 1.1)),
                const SizedBox(height: 3),
                Text(desc,
                    style: T.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: C.text3,
                        height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
                color: C.inset, borderRadius: BorderRadius.circular(R.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SvgIcon(Ic.lock, size: 13, color: C.text3, strokeWidth: 2),
                const SizedBox(width: 5),
                Text(l10n.arcadeSoon,
                    style: T.display(
                        size: 11.5, weight: FontWeight.w800, color: C.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
