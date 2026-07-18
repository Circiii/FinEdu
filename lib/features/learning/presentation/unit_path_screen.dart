import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
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

    // Atmosfera unității: fundalul se tentează subtil cu culoarea ei.
    final tint = unit == null
        ? C.bg
        : Color.lerp(C.bg, unitLook(unit.color).gradient.colors.first, 0.10)!;

    return Scaffold(
      backgroundColor: C.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, C.bg],
            stops: const [0.0, 0.5],
          ),
        ),
        child: Column(
          children: [
            const StatusBar(),
            Expanded(
              child: unit == null
                  ? const Center(child: CircularProgressIndicator())
                  : _body(unit, done, unlocked: unlocked),
            ),
          ],
        ),
      ),
    );
  }

  /// Amplitudinea serpentinei: nodurile alternează stânga-dreapta față de ax.
  static const _amp = 56.0;

  /// Offset-ul orizontal al nodului [i]: 0, dreapta, 0, stânga, 0, ...
  double _dx(int i) => math.sin(i * math.pi / 2) * _amp;

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
                      _connector(
                        index: i,
                        fromDx: _dx(i - 1),
                        toDx: _dx(i),
                        done: done.contains(unit.lessons[i - 1].id),
                        unitColor: unitLook(unit.color).gradient.colors.first,
                      ),
                    _node(
                      unit.lessons[i],
                      index: i,
                      dx: _dx(i),
                      state: done.contains(unit.lessons[i].id)
                          ? _NodeState.done
                          : (i == currentIndex
                                ? _NodeState.current
                                : _NodeState.locked),
                    ),
                  ],
                  _connector(
                    index: unit.lessons.length,
                    fromDx: _dx(unit.lessons.length - 1),
                    toDx: _dx(unit.lessons.length),
                    done: done.contains(unit.lessons.last.id),
                    unitColor: unitLook(unit.color).gradient.colors.first,
                  ),
                  _finishNode(
                    unit,
                    dx: _dx(unit.lessons.length),
                    complete: unit.lessons.every((l) => done.contains(l.id)),
                    index: unit.lessons.length,
                  ),
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
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Filigran: emoji-ul unității, mare și discret, în colțul din dreapta.
            Positioned(
              right: -14,
              top: -18,
              child: Opacity(
                opacity: 0.18,
                child: Text(unit.emoji, style: const TextStyle(fontSize: 96)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _headerContent(unit, doneIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerContent(LearnUnit unit, int doneIn) {
    return Row(
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
              const SizedBox(height: 6),
              // Bara de progres a unității, subțire, direct în header.
              ClipRRect(
                borderRadius: BorderRadius.circular(R.pill),
                child: Container(
                  height: 7,
                  color: Colors.white.withValues(alpha: 0.25),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (doneIn / unit.lessons.length).clamp(
                      0.04,
                      1.0,
                    ),
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 4),
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
    );
  }

  /// Poteca dintre două noduri: o panglică lată în culoarea unității, cu
  /// puncte pe ea. Punctele se fac verzi după o lecție terminată.
  Widget _connector({
    required int index,
    required double fromDx,
    required double toDx,
    required bool done,
    required Color unitColor,
  }) => StaggerIn(
    index: index,
    child: SizedBox(
      width: double.infinity,
      height: 42,
      child: CustomPaint(
        painter: _TrailPainter(
          fromDx: fromDx,
          toDx: toDx,
          ribbon: unitColor.withValues(alpha: 0.16),
          color: done ? C.green.withValues(alpha: 0.6) : C.line2,
        ),
      ),
    ),
  );

  /// Capătul drumului: trofeul de final de unitate.
  Widget _finishNode(
    LearnUnit unit, {
    required double dx,
    required bool complete,
    required int index,
  }) {
    final look = unitLook(unit.color);
    return StaggerIn(
      index: index,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: complete ? look.gradient : null,
                  color: complete ? null : C.inset,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: complete
                        ? Colors.white.withValues(alpha: 0.45)
                        : C.line2,
                    width: 4,
                  ),
                  boxShadow: complete ? look.shadow : Sh.insetSoft,
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: complete ? 1 : 0.45,
                  child: Text('🏆', style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complete ? 'Unitate cucerită!' : 'Finalul unității',
                style: T.display(
                  size: 13.5,
                  weight: FontWeight.w800,
                  color: complete ? C.text : C.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node(
    Lesson lesson, {
    required int index,
    required double dx,
    required _NodeState state,
  }) {
    final locked = state == _NodeState.locked;
    final isCurrent = state == _NodeState.current;
    final size = isCurrent ? 100.0 : 84.0;

    return StaggerIn(
      index: index,
      child: Transform.translate(
        offset: Offset(dx, 0),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cashy stă lângă lecția curentă și arată spre ea, mereu
                  // dinspre axul drumului (oglindit când nodul e pe stânga).
                  if (isCurrent)
                    Positioned(
                      top: 14,
                      left: dx >= 0 ? -74 : null,
                      right: dx < 0 ? -74 : null,
                      child: Transform.flip(
                        flipX: dx < 0,
                        child: const CashySprite(
                          asset: Cashy.cashyPoint,
                          width: 64,
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
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 4,
                          ),
                          _NodeState.current => Border.all(
                            color: C.blue,
                            width: 4,
                          ),
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
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 190,
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
      ),
    );
  }
}

/// Pictează poteca punctată dintre două noduri, pe o curbă lină între
/// offset-urile serpentinei.
class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.fromDx,
    required this.toDx,
    required this.ribbon,
    required this.color,
  });

  final double fromDx;
  final double toDx;
  final Color ribbon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Depășim puțin capetele ca panglica să intre vizual sub noduri.
    final start = Offset(size.width / 2 + fromDx, -10);
    final end = Offset(size.width / 2 + toDx, size.height + 10);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        size.height / 2,
        end.dx,
        end.dy,
      );

    // Panglica lată (drumul), apoi punctele-pași pe ea.
    canvas.drawPath(
      path,
      Paint()
        ..color = ribbon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );
    final metric = path.computeMetrics().first;
    final paint = Paint()..color = color;
    const dots = 4;
    for (var i = 1; i <= dots; i++) {
      final pos = metric
          .getTangentForOffset(metric.length * i / (dots + 1))!
          .position;
      canvas.drawCircle(pos, 3.6, paint);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.fromDx != fromDx ||
      old.toDx != toDx ||
      old.ribbon != ribbon ||
      old.color != color;
}

enum _NodeState { done, current, locked }
