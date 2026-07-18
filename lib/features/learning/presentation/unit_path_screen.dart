import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../data/lessons_repository.dart';

/// Culorile unei unități, aduse din conținut (câmpul `color` din JSON).
({LinearGradient gradient, List<BoxShadow> shadow}) unitLook(String color) =>
    switch (color) {
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

/// Traseul unei singure unități: header colorat + drumul lecțiilor pe mijloc.
/// La deschidere, ecranul derulează singur la lecția curentă.
class UnitPathScreen extends ConsumerStatefulWidget {
  const UnitPathScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<UnitPathScreen> createState() => _UnitPathScreenState();
}

class _UnitPathScreenState extends ConsumerState<UnitPathScreen> {
  final _currentKey = GlobalKey();
  bool _autoScrolled = false;

  /// Derulează o singură dată la nodul curent, după ce lista e pe ecran.
  void _scrollToCurrent() {
    if (_autoScrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx == null || _autoScrolled) return;
      _autoScrolled = true;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ro';
    final units = ref.watch(unitsProvider(locale)).valueOrNull ?? const [];
    final done = ref.watch(completedLessonsProvider).valueOrNull ?? const {};

    LearnUnit? unit;
    var unlocked = true;
    for (final u in units) {
      if (u.id == widget.unitId) {
        unit = u;
        break;
      }
      unlocked = unlocked && u.lessons.every((l) => done.contains(l.id));
    }

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: unit == null
                ? const Center(child: CircularProgressIndicator())
                : _body(unit, done, unlocked: unlocked),
          ),
        ],
      ),
    );
  }

  Widget _body(LearnUnit unit, Set<String> done, {required bool unlocked}) {
    final currentIndex = unlocked
        ? unit.lessons.indexWhere((l) => !done.contains(l.id))
        : -1;
    _scrollToCurrent();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: _header(unit, done),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  for (var i = 0; i < unit.lessons.length; i++) ...[
                    if (i > 0)
                      _connector(done: done.contains(unit.lessons[i - 1].id)),
                    _node(
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(LearnUnit unit, Set<String> done) {
    final doneIn = unit.lessons.where((l) => done.contains(l.id)).length;
    final look = unitLook(unit.color);
    return ClayCard(
      radius: 22,
      gradient: look.gradient,
      shadow: look.shadow,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Juice.tick();
              context.pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const SvgIcon(
                Ic.chevronLeft,
                size: 18,
                color: Colors.white,
                strokeWidth: 2.6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(unit.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unitatea ${unit.ord} · ${unit.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.display(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$doneIn din ${unit.lessons.length} lecții',
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

  Widget _node(Lesson lesson, {required int index, required _NodeState state}) {
    final locked = state == _NodeState.locked;
    final isCurrent = state == _NodeState.current;
    final size = isCurrent ? 96.0 : 82.0;

    return StaggerIn(
      index: index,
      child: Padding(
        key: isCurrent ? _currentKey : null,
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
}

enum _NodeState { done, current, locked }
