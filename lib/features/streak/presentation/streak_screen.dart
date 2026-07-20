import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/streak_rules.dart';
import '../../../domain/util/day_key.dart';
import '../../gamification/data/gamification_service.dart';
import '../../home/data/home_providers.dart';

/// Hub-ul de streak: curent/cel mai lung, calendar lunar cu zile înghețate,
/// Ghinde de Gheață, milestone-uri și banner-ul de earn-back.
class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(streakViewProvider).valueOrNull;
    final days = ref.watch(activityDaysProvider).valueOrNull ?? const {};
    final snapshot = result?.snapshot ?? const StreakSnapshot();
    final current = result?.current ?? 0;
    final longest = result?.longest ?? 0;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  const SizedBox(height: 14),
                  StaggerIn(index: 0, child: _hero(current, longest)),
                  if (snapshot.earnbackUntil != null) ...[
                    const SizedBox(height: 12),
                    StaggerIn(index: 1, child: _earnbackBanner(snapshot)),
                  ],
                  const SizedBox(height: 12),
                  StaggerIn(
                    index: 1,
                    child: _freezesCard(context, ref, snapshot),
                  ),
                  const SizedBox(height: 12),
                  StaggerIn(
                    index: 2,
                    child: _calendarCard(days, snapshot.frozenDays),
                  ),
                  const SizedBox(height: 12),
                  StaggerIn(
                    index: 3,
                    child: _milestonesCard(current, snapshot.claimedMilestones),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: () => context.pop(),
          scale: 0.9,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            alignment: Alignment.center,
            child: const SvgIcon(
              Ic.chevronLeft,
              size: 18,
              color: C.text2,
              strokeWidth: 2.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Focul lui Cashy',
          style: T.display(size: 24, weight: FontWeight.w800, color: C.text),
        ),
      ],
    );
  }

  Widget _hero(int current, int longest) {
    final next = streakMilestones.keys
        .where((m) => m > current)
        .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
    final pct = next == null ? 1.0 : (current / next).clamp(0.0, 1.0);

    return ClayCard(
      radius: 26,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7A59), Color(0xFFFFB020)],
      ),
      shadow: Sh.amber,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          RingGauge(
            size: 110,
            percent: pct,
            trackColor: Colors.white24,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pulse(
                  scale: current > 0 ? 1.12 : 1.0,
                  child: const FlameIcon(size: 24),
                ),
                AnimatedCount(
                  value: current,
                  duration: const Duration(milliseconds: 900),
                  style: T.display(
                    size: 30,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current == 1 ? 'zi la rând' : 'zile la rând',
                  style: T.display(
                    size: 16,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cel mai lung: $longest',
                  style: T.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Încă ${next - current} zile până la cufărul de $next',
                    style: T.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earnbackBanner(StreakSnapshot s) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Floaty(child: Image.asset(Cashy.cashyWorried, width: 44)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Streak-ul de ${s.earnbackValue} zile s-a rupt, dar îl poți '
              'recupera: fă 2 acțiuni azi (loghează + o rundă de Dojo).',
              style: T.body(
                size: 13,
                weight: FontWeight.w600,
                color: C.text,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _freezesCard(BuildContext context, WidgetRef ref, StreakSnapshot s) {
    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (var i = 0; i < StreakSnapshot.maxFreezes; i++) ...[
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: i < s.freezes ? C.skySoft : C.inset,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: i < s.freezes ? C.sky : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                i < s.freezes ? '❄️' : '·',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghinde de Gheață',
                  style: T.display(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
                Text(
                  'Îți păzesc streak-ul când lipsești o zi. Se aplică singure.',
                  style: T.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: C.text2,
                  ),
                ),
              ],
            ),
          ),
          if (s.freezes < StreakSnapshot.maxFreezes)
            Pressable(
              haptic: false,
              onTap: () async {
                final ok = await ref
                    .read(gamificationServiceProvider)
                    .buyFreeze();
                ref.invalidate(streakViewProvider);
                if (ok) Juice.correct();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AcornText(
                        ok
                            ? '❄️ Ghindă de Gheață cumpărată!'
                            : 'Nu ai destule ghinde (200 🌰)',
                        style: T.display(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: C.text,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: Grad.blue,
                  borderRadius: BorderRadius.circular(R.pill),
                  boxShadow: Sh.blue,
                ),
                child: AcornText(
                  '200 🌰',
                  style: T.display(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendarCard(Set<String> activeDays, Set<String> frozenDays) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Offset cu luni prima zi (weekday: Lun=1..Dum=7).
    final leading = first.weekday - 1;
    const monthsRo = [
      'Ianuarie',
      'Februarie',
      'Martie',
      'Aprilie',
      'Mai',
      'Iunie',
      'Iulie',
      'August',
      'Septembrie',
      'Octombrie',
      'Noiembrie',
      'Decembrie',
    ];

    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthsRo[now.month - 1].toUpperCase(),
            style: T.display(
              size: 12,
              weight: FontWeight.w700,
              color: C.text3,
              letterSpacing: 12 * 0.12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: T.body(
                        size: 11,
                        weight: FontWeight.w700,
                        color: C.text3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox(),
              for (var d = 1; d <= daysInMonth; d++)
                _dayCell(
                  d,
                  key_: dayKey(DateTime(now.year, now.month, d)),
                  today: d == now.day,
                  future: d > now.day,
                  activeDays: activeDays,
                  frozenDays: frozenDays,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend(C.green, 'activ'),
              _legend(C.sky, 'protejat ❄️'),
              _legend(C.inset, 'liber'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
    int day, {
    required String key_,
    required bool today,
    required bool future,
    required Set<String> activeDays,
    required Set<String> frozenDays,
  }) {
    Color bg = C.inset;
    Color fg = C.text3;
    if (activeDays.contains(key_)) {
      bg = C.green;
      fg = Colors.white;
    } else if (frozenDays.contains(key_)) {
      bg = C.sky;
      fg = Colors.white;
    } else if (future) {
      bg = C.surface2;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: today ? Border.all(color: C.text, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: T.display(size: 12, weight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: T.body(size: 11.5, weight: FontWeight.w600, color: C.text2),
        ),
      ],
    );
  }

  Widget _milestonesCard(int current, Set<int> claimed) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BORNE',
            style: T.display(
              size: 12,
              weight: FontWeight.w700,
              color: C.text3,
              letterSpacing: 12 * 0.12,
            ),
          ),
          const SizedBox(height: 12),
          for (final e in streakMilestones.entries) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: claimed.contains(e.key) ? C.amberSoft : C.inset,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    claimed.contains(e.key) ? '🏆' : '🔒',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${e.key} zile la rând',
                    style: T.display(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: claimed.contains(e.key) ? C.text : C.text2,
                    ),
                  ),
                ),
                AcornText(
                  '+${e.value} 🌰',
                  style: T.display(
                    size: 13,
                    weight: FontWeight.w800,
                    color: claimed.contains(e.key) ? C.amberInk : C.text3,
                  ),
                ),
              ],
            ),
            if (e.key != streakMilestones.keys.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
