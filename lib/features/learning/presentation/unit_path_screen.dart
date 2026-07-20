import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/motion.dart';
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

/// Traseul unei unități: un drum continuu care șerpuiește prin lecții, cu
/// porțiunea parcursă colorată. La deschidere sare singur la lecția curentă.
class UnitPathScreen extends ConsumerStatefulWidget {
  const UnitPathScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<UnitPathScreen> createState() => _UnitPathScreenState();
}

class _UnitPathScreenState extends ConsumerState<UnitPathScreen> {
  final _currentKey = GlobalKey();
  bool _autoScrolled = false;

  /// Geometria drumului: sloturi cu înălțime FIXĂ, ca șoseaua să se poată
  /// picta dintr-o singură bucată prin centrele bulelor.
  static const _slotH = 192.0;
  static const _bubbleCY = 78.0;
  static const _amp = 56.0;

  /// Offset-ul orizontal al nodului [i]: 0, dreapta, 0, stânga, 0, ...
  double _dx(int i) => math.sin(i * math.pi / 2) * _amp;

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
        child: Stack(
          children: [
            // Aceeași ploaie de ghinde ca pe pagina principală de învățare.
            const Positioned.fill(child: AcornRain()),
            Column(
              children: [
                const StatusBar(),
                Expanded(
                  child: unit == null
                      ? const Center(child: CircularProgressIndicator())
                      : _body(unit, done, unlocked: unlocked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(LearnUnit unit, Set<String> done, {required bool unlocked}) {
    final n = unit.lessons.length;
    final currentIndex = unlocked
        ? unit.lessons.indexWhere((l) => !done.contains(l.id))
        : -1;
    final complete = unit.lessons.every((l) => done.contains(l.id));
    // Drumul e „parcurs" până la bula lecției curente (sau până la trofeu
    // când unitatea e gata).
    final reached = !unlocked ? 0 : (complete ? n : currentIndex);
    final look = unitLook(unit.color);
    _scrollToCurrent();

    final dxs = [for (var i = 0; i <= n; i++) _dx(i)];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: _header(unit, done),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
            child: SizedBox(
              width: double.infinity,
              height: (n + 1) * _slotH,
              child: Stack(
                children: [
                  // Șoseaua, dintr-o singură bucată, sub toate nodurile.
                  // La deschidere se desenează singură de sus în jos.
                  Positioned.fill(
                    child: AnimatedFrac(
                      value: 1,
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeInOutCubic,
                      builder: (_, drawn) => CustomPaint(
                        painter: _RoadPainter(
                          dxs: dxs,
                          slotH: _slotH,
                          bubbleCY: _bubbleCY,
                          reached: reached,
                          drawn: drawn,
                          ribbon: look.gradient.colors.first.withValues(
                            alpha: 0.14,
                          ),
                          traveled: C.green.withValues(alpha: 0.22),
                          dash: look.gradient.colors.last.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < n; i++)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: i * _slotH,
                      height: _slotH,
                      child: _node(
                        unit.lessons[i],
                        index: i,
                        dx: _dx(i),
                        state: done.contains(unit.lessons[i].id)
                            ? _NodeState.done
                            : (i == currentIndex
                                  ? _NodeState.current
                                  : _NodeState.locked),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: n * _slotH,
                    height: _slotH,
                    child: _finishNode(
                      unit,
                      dx: _dx(n),
                      complete: complete,
                      index: n,
                    ),
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
        Pressable(
          onTap: () => context.pop(),
          scale: 0.9,
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
                  child: AnimatedFrac(
                    value: (doneIn / unit.lessons.length).clamp(0.04, 1.0),
                    duration: const Duration(milliseconds: 900),
                    builder: (_, v) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: math.max(v, 0.001),
                      child: Container(color: Colors.white),
                    ),
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

  Widget _node(
    Lesson lesson, {
    required int index,
    required double dx,
    required _NodeState state,
  }) {
    final locked = state == _NodeState.locked;
    final isCurrent = state == _NodeState.current;
    final size = switch (state) {
      _NodeState.current => 100.0,
      _NodeState.done => 84.0,
      _NodeState.locked => 76.0,
    };

    return PopIn(
      index: index,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Column(
          key: isCurrent ? _currentKey : null,
          children: [
            // Zona etichetei START are înălțime fixă la toate nodurile, ca
            // centrul bulei să rămână pe traiectoria pictată a drumului.
            SizedBox(
              height: 28,
              child: isCurrent
                  ? Container(
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
                    )
                  : null,
            ),
            SizedBox(
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Cashy stă lângă lecția curentă și arată spre ea, mereu
                  // dinspre axul drumului (oglindit când nodul e pe stânga).
                  if (isCurrent)
                    Positioned(
                      left: dx >= 0 ? -78 : null,
                      right: dx < 0 ? -78 : null,
                      child: Floaty(
                        child: Transform.flip(
                          flipX: dx < 0,
                          child: const CashySprite(
                            asset: Cashy.cashyPoint,
                            width: 64,
                          ),
                        ),
                      ),
                    ),
                  Pressable(
                    scale: 0.92,
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
                        : () => context.push('/learn/lesson/${lesson.id}'),
                    // Bula curentă pulsează discret: se vede unde ești.
                    child: Pulse(
                      scale: isCurrent ? 1.045 : 1.0,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          gradient: state == _NodeState.done
                              ? Grad.green
                              : null,
                          color: switch (state) {
                            _NodeState.done => null,
                            _NodeState.current => C.surface,
                            _NodeState.locked => C.inset,
                          },
                          shape: BoxShape.circle,
                          border: switch (state) {
                            // Inelul alb dă adâncime; albastrul marchează startul.
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
                            style: const TextStyle(fontSize: 36),
                          ),
                          _NodeState.locked => const SvgIcon(
                            Ic.lock,
                            size: 22,
                            color: C.text3,
                            strokeWidth: 2.2,
                          ),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 190,
              height: 36,
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: T.display(
                  size: 14,
                  weight: FontWeight.w700,
                  color: locked ? C.text3 : C.text,
                  height: 1.15,
                ),
              ),
            ),
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

  /// Capătul drumului: trofeul de final de unitate, pe aceeași geometrie.
  Widget _finishNode(
    LearnUnit unit, {
    required double dx,
    required bool complete,
    required int index,
  }) {
    final look = unitLook(unit.color);
    return PopIn(
      index: index,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Column(
          children: [
            const SizedBox(height: 28),
            SizedBox(
              height: 100,
              child: Center(
                // Trofeul câștigat plutește, cel blocat stă pe loc.
                child: Floaty(
                  amplitude: complete ? 1 : 0,
                  child: Container(
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
                      child: const Text('🏆', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
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
    );
  }
}

/// Pictează șoseaua continuă prin centrele bulelor: panglica lată, porțiunea
/// parcursă în verde și linia punctată din mijloc. Curbele intră și ies
/// vertical din fiecare nod, deci drumul trece exact prin bule.
class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.dxs,
    required this.slotH,
    required this.bubbleCY,
    required this.reached,
    required this.ribbon,
    required this.traveled,
    required this.dash,
    this.drawn = 1,
  });

  final List<double> dxs;
  final double slotH;
  final double bubbleCY;
  final int reached;
  final Color ribbon;
  final Color traveled;
  final Color dash;

  /// Cât din drum e desenat (0..1), pentru efectul de la deschidere.
  final double drawn;

  Path _roadThrough(Size size, int upTo) {
    final cx = size.width / 2;
    Offset p(int i) => Offset(cx + dxs[i], i * slotH + bubbleCY);
    final path = Path()..moveTo(p(0).dx, p(0).dy);
    final k = slotH * 0.45;
    for (var i = 1; i <= upTo; i++) {
      final a = p(i - 1);
      final b = p(i);
      path.cubicTo(a.dx, a.dy + k, b.dx, b.dy - k, b.dx, b.dy);
    }
    return path;
  }

  /// Taie traseul la fracția [f] din lungimea lui.
  Path _trim(Path p, double f) {
    if (f >= 1) return p;
    final out = Path();
    for (final m in p.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * f), Offset.zero);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final full = _trim(_roadThrough(size, dxs.length - 1), drawn);

    canvas.drawPath(
      full,
      Paint()
        ..color = ribbon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.round,
    );

    if (reached > 0) {
      canvas.drawPath(
        _trim(_roadThrough(size, reached), drawn),
        Paint()
          ..color = traveled
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round,
      );
    }

    // Linia punctată din mijloc, doar pe porțiunea deja desenată.
    final paint = Paint()
      ..color = dash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in full.computeMetrics()) {
      var d = 10.0;
      while (d + 10 < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 10), paint);
        d += 24;
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.dxs != dxs ||
      old.reached != reached ||
      old.drawn != drawn ||
      old.ribbon != ribbon ||
      old.traveled != traveled ||
      old.dash != dash;
}

enum _NodeState { done, current, locked }
