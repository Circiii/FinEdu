import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/leitner.dart';
import '../../home/data/home_providers.dart';
import '../data/lessons_repository.dart';
import 'unit_path_screen.dart' show unitLook;

/// Ecranul „Învață": hero cu inelul de nivel, banner de recapitulare și
/// unitățile ca tărâmuri colorate. Traseul se deschide per unitate.
class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ro';
    final units = ref.watch(unitsProvider(locale)).valueOrNull ?? const [];
    final done = ref.watch(completedLessonsProvider).valueOrNull ?? const {};
    final due = ref.watch(dueCardsCountProvider).valueOrNull ?? 0;
    final profile = ref.watch(localProfileStreamProvider).valueOrNull;
    final xp = profile?.xp ?? 0;

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          // Ploaia de ghinde din fundal (pictată o dată, cost minim).
          const Positioned.fill(child: AcornRain()),
          Column(
            children: [
              const StatusBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Învață',
                        style: T.display(
                          size: 24,
                          weight: FontWeight.w800,
                          color: C.text,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _hero(
                        xp,
                        done.length,
                        units.fold<int>(0, (n, u) => n + u.lessons.length),
                      ),
                      if (due > 0) ...[
                        const SizedBox(height: 12),
                        _reviewBanner(context, due),
                      ],
                      const SizedBox(height: 6),
                      ..._unitCards(context, units, done),
                      const SizedBox(height: 12),
                      _comingSoon(),
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

  /// Hero-ul de progres: inelul de nivel în jurul lui Cashy + bara de XP.
  Widget _hero(int xp, int doneCount, int totalCount) {
    final level = levelForXp(xp);
    final inLevel = xpInLevel(xp);
    return ClayCard(
      radius: 22,
      gradient: Grad.blue,
      shadow: Sh.blue,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(78, 78),
                  painter: _RingPainter(
                    progress: (inLevel / 300).clamp(0.02, 1.0),
                    track: Colors.white.withValues(alpha: 0.25),
                    fill: Colors.white,
                    stroke: 6,
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(Cashy.cashyStudy, width: 44),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nivel $level',
                      style: T.display(
                        size: 18,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$inLevel / 300 XP',
                      style: T.display(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.pill),
                  child: Container(
                    height: 9,
                    color: Colors.white.withValues(alpha: 0.25),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (inLevel / 300).clamp(0.02, 1.0),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$doneCount din $totalCount lecții · ${fmtThousands(xp)} XP',
                  style: T.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewBanner(BuildContext context, int due) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push('/review');
      },
      child: ClayCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Image.asset(Cashy.cashyPoint, width: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recapitularea lui Cashy',
                    style: T.display(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: C.text,
                    ),
                  ),
                  Text(
                    due == 1
                        ? 'Un card te așteaptă azi'
                        : '$due carduri te așteaptă azi',
                    style: T.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: C.text2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: Grad.amber,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: Sh.amber,
              ),
              child: Text(
                'Începe',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Unitățile ca tărâmuri; unitatea N+1 se deblochează doar când toate
  /// lecțiile unității N sunt completate. Tap = traseul unității.
  List<Widget> _unitCards(
    BuildContext context,
    List<LearnUnit> units,
    Set<String> done,
  ) {
    final cards = <Widget>[];
    var unlocked = true;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      final isComplete = unit.lessons.every((l) => done.contains(l.id));
      cards
        ..add(const SizedBox(height: 10))
        ..add(
          StaggerIn(
            index: i,
            child: _unitCard(
              context,
              unit,
              done,
              unlocked: unlocked,
              active: unlocked && !isComplete,
            ),
          ),
        );
      unlocked = unlocked && isComplete;
    }
    return cards;
  }

  Widget _unitCard(
    BuildContext context,
    LearnUnit unit,
    Set<String> done, {
    required bool unlocked,
    required bool active,
  }) {
    final doneIn = unit.lessons.where((l) => done.contains(l.id)).length;
    final look = unitLook(unit.color);
    final currentIndex = active
        ? unit.lessons.indexWhere((l) => !done.contains(l.id))
        : -1;

    return GestureDetector(
      onTap: () {
        Juice.tick();
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔒 Termină unitatea anterioară ca să o deblochezi',
                style: T.display(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: C.text,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        context.push('/learn/unit/${unit.id}');
      },
      child: ClayCard(
        radius: 20,
        gradient: unlocked ? look.gradient : null,
        color: unlocked ? C.surface : C.inset,
        shadow: unlocked ? look.shadow : Sh.insetSoft,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Textura discretă a tărâmului: cerculețe albe pe gradient.
              if (unlocked)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardPatternPainter(
                      Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    // Sigiliul unității: emoji în cerc alb, cu inel de progres.
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (unlocked)
                            CustomPaint(
                              size: const Size(62, 62),
                              painter: _RingPainter(
                                progress: doneIn / unit.lessons.length,
                                track: Colors.white.withValues(alpha: 0.3),
                                fill: Colors.white,
                                stroke: 5,
                              ),
                            ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: unlocked ? Colors.white : C.surface2,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: unlocked
                                ? Text(
                                    unit.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : const SvgIcon(
                                    Ic.lock,
                                    size: 18,
                                    color: C.text3,
                                    strokeWidth: 2.2,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unitatea ${unit.ord} · ${unit.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.display(
                              size: 15,
                              weight: FontWeight.w800,
                              color: unlocked ? Colors.white : C.text3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Preview-ul lecțiilor: un punct per lecție.
                          Row(
                            children: [
                              for (var i = 0; i < unit.lessons.length; i++) ...[
                                if (i > 0) const SizedBox(width: 5),
                                Container(
                                  width: i == currentIndex ? 11 : 8,
                                  height: i == currentIndex ? 11 : 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !unlocked
                                        ? C.line2
                                        : i == currentIndex
                                        ? C.amber
                                        : done.contains(unit.lessons[i].id)
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Text(
                                '$doneIn/${unit.lessons.length}',
                                style: T.display(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: unlocked ? Colors.white70 : C.text3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!unlocked)
                      const SvgIcon(
                        Ic.lock,
                        size: 18,
                        color: C.text3,
                        strokeWidth: 2.2,
                      )
                    else if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                        child: Text(
                          'Continuă',
                          style: T.display(
                            size: 11.5,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SvgIcon(
                        Ic.chevronRight,
                        size: 18,
                        color: Colors.white,
                        strokeWidth: 2.4,
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

  Widget _comingSoon() {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unitatea 8 · Banii împrumutați, în curând',
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inel de progres: arc plin peste un arc-șină, cu capete rotunjite.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}

/// Cerculețe discrete pe gradientul cardului, poziții fixe (determinist).
class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter(this.color);

  final Color color;

  static const _spots = [
    (0.82, 0.2, 26.0),
    (0.94, 0.75, 16.0),
    (0.68, 0.9, 10.0),
    (0.55, 0.12, 8.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final (fx, fy, r) in _spots) {
      canvas.drawCircle(Offset(size.width * fx, size.height * fy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => old.color != color;
}
