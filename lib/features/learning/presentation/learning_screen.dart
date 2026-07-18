import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/leitner.dart';
import '../../home/data/home_providers.dart';
import '../data/lessons_repository.dart';

/// Ecranul „Învață": HUD de XP/nivel, banner de recapitulare și traseul
/// unităților cu deblocare strict secvențială.
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
      body: Column(
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
                  _hud(
                    xp,
                    done.length,
                    units.fold<int>(0, (n, u) => n + u.lessons.length),
                  ),
                  if (due > 0) ...[
                    const SizedBox(height: 12),
                    _reviewBanner(context, due),
                  ],
                  ..._unitSections(context, units, done),
                  const SizedBox(height: 10),
                  _comingSoon(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hud(int xp, int doneCount, int totalCount) {
    final level = levelForXp(xp);
    final inLevel = xpInLevel(xp);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(Cashy.cashyStudy, width: 56),
          const SizedBox(width: 12),
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
                        size: 16,
                        weight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                    Text(
                      '$inLevel / 300 XP',
                      style: T.display(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: C.text3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.pill),
                  child: Container(
                    height: 10,
                    color: C.inset,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (inLevel / 300).clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: Grad.blue,
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$doneCount din $totalCount lecții · ${fmtThousands(xp)} XP',
                  style: T.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: C.text2,
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

  /// Banner-e + trasee de unități; unitatea N+1 se deblochează doar când
  /// toate lecțiile unității N sunt completate.
  List<Widget> _unitSections(
    BuildContext context,
    List<LearnUnit> units,
    Set<String> done,
  ) {
    final sections = <Widget>[];
    var unlocked = true;
    for (final unit in units) {
      sections
        ..add(const SizedBox(height: 16))
        ..add(_unitBanner(unit, done))
        ..add(const SizedBox(height: 8))
        ..add(_path(context, unit, done, unlocked: unlocked));
      unlocked = unlocked && unit.lessons.every((l) => done.contains(l.id));
    }
    return sections;
  }

  /// Fiecare unitate își aduce culoarea din conținut, traseul respiră vizual.
  static ({LinearGradient gradient, List<BoxShadow> shadow}) _unitLook(
    String color,
  ) => switch (color) {
    'green' => (gradient: Grad.green, shadow: Sh.green),
    'amber' => (gradient: Grad.amber, shadow: Sh.amber),
    'violet' => (
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA99CFF), C.violet, C.violetDeep],
        stops: [0.0, 0.55, 1.0],
      ),
      shadow: Sh.violet,
    ),
    'danger' => (gradient: Grad.danger, shadow: Sh.danger),
    _ => (gradient: Grad.blue, shadow: Sh.blue),
  };

  Widget _unitBanner(LearnUnit unit, Set<String> done) {
    final doneIn = unit.lessons.where((l) => done.contains(l.id)).length;
    final look = _unitLook(unit.color);
    return ClayCard(
      radius: 22,
      gradient: look.gradient,
      shadow: look.shadow,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(unit.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unitatea ${unit.ord} · ${unit.title}',
                  style: T.display(
                    size: 16,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$doneIn din ${unit.lessons.length} lecții',
                  style: T.body(
                    size: 12.5,
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

  Widget _path(
    BuildContext context,
    LearnUnit unit,
    Set<String> done, {
    required bool unlocked,
  }) {
    // Current = prima lecție necompletată; restul e locked (strict secvențial).
    // O unitate ale cărei predecesoare nu sunt terminate nu are niciun nod current.
    final currentIndex = unlocked
        ? unit.lessons.indexWhere((l) => !done.contains(l.id))
        : -1;

    // Părintele aliniază la stânga (CrossAxisAlignment.start); lățimea plină
    // lasă nodurile să se centreze pe ecran, nu pe propria coloană îngustă.
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          for (var i = 0; i < unit.lessons.length; i++) ...[
            if (i > 0) _connector(done: done.contains(unit.lessons[i - 1].id)),
            _node(
              context,
              unit.lessons[i],
              index: i,
              state: done.contains(unit.lessons[i].id)
                  ? _NodeState.done
                  : (i == currentIndex
                        ? _NodeState.current
                        : _NodeState.locked),
            ),
          ],
        ],
      ),
    );
  }

  /// Firul traseului dintre două noduri: verde după o lecție terminată,
  /// gri înaintea celor blocate.
  Widget _connector({required bool done}) => Container(
    width: 5,
    height: 22,
    decoration: BoxDecoration(
      color: done ? C.green.withValues(alpha: 0.45) : C.line2,
      borderRadius: BorderRadius.circular(R.pill),
    ),
  );

  Widget _node(
    BuildContext context,
    Lesson lesson, {
    required int index,
    required _NodeState state,
  }) {
    final locked = state == _NodeState.locked;
    final isCurrent = state == _NodeState.current;
    final size = isCurrent ? 96.0 : 82.0;

    return StaggerIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: Grad.amber,
                  borderRadius: BorderRadius.circular(R.pill),
                  boxShadow: Sh.amber,
                ),
                child: Text(
                  'START',
                  style: T.display(
                    size: 11,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            GestureDetector(
              onTap: locked
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔒 Finalizează lecția anterioară',
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
                    )
                  : () {
                      Juice.tick();
                      context.push('/learn/lesson/${lesson.id}');
                    },
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: switch (state) {
                    _NodeState.done => C.green,
                    _NodeState.current => C.surface,
                    _NodeState.locked => C.inset,
                  },
                  shape: BoxShape.circle,
                  border: switch (state) {
                    // Inelul alb dă adâncime pe verde; albastrul marchează startul.
                    _NodeState.done => Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 3,
                    ),
                    _NodeState.current => Border.all(color: C.blue, width: 3),
                    _NodeState.locked => null,
                  },
                  boxShadow: switch (state) {
                    _NodeState.done => Sh.green,
                    _NodeState.current => Sh.blue,
                    _NodeState.locked => Sh.insetSoft,
                  },
                ),
                alignment: Alignment.center,
                child: switch (state) {
                  _NodeState.done => const SvgIcon(
                    Ic.check,
                    size: 30,
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  _NodeState.current => Text(
                    lesson.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                  _NodeState.locked => const SvgIcon(
                    Ic.lock,
                    size: 24,
                    color: C.text3,
                    strokeWidth: 2.2,
                  ),
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 230,
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: T.display(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: locked ? C.text3 : C.text,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${lesson.minutes} min · +${lesson.xp} XP',
              style: T.body(
                size: 11.5,
                weight: FontWeight.w600,
                color: C.text3,
              ),
            ),
          ],
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

enum _NodeState { done, current, locked }
