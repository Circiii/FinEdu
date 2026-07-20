import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Limbajul tactil/vizual unic al aplicației. Patru niveluri, alocate
/// O SINGURĂ dată per moment:
///  - micro  → [tick]    : swipe, slidere, sume rapide
///  - minor  → [correct] : răspuns bun, quest, cheltuială logată
///  - major  → [major]   : lecție completă, cufăr, obiectiv atins
///  - epic   → [epic]    : milestone de streak, belt-up, unitate completă
/// Greșeala NU primește haptic: costă doar un zâmbet ([JuiceShake]).
class Juice {
  static void tick() => HapticFeedback.selectionClick();
  static void correct() => HapticFeedback.lightImpact();
  static void major() => HapticFeedback.mediumImpact();
  static void epic() => HapticFeedback.heavyImpact();
}

/// Săltătură scurtă (scale 1 → 1.12 → 1) de fiecare dată când [trigger] se
/// schimbă. Pentru contoare/badge-uri care „reacționează" la valori noi.
/// Tranziția null → valoare NU sare: e primul load, nu o recompensă.
/// Dă un trigger nullable ca să nu „celebrezi" pornirea aplicației.
class JuiceBounce extends StatefulWidget {
  const JuiceBounce({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<JuiceBounce> createState() => _JuiceBounceState();
}

class _JuiceBounceState extends State<JuiceBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Dur.emph,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(JuiceBounce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        old.trigger != null &&
        !MediaQuery.of(context).disableAnimations) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Scuturare orizontală (±8px, 3 oscilații, 300ms) când [trigger] se schimbă.
/// Feedback-ul de greșeală: vizibil, moale, fără haptic.
class JuiceShake extends StatefulWidget {
  const JuiceShake({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<JuiceShake> createState() => _JuiceShakeState();
}

class _JuiceShakeState extends State<JuiceShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(JuiceShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        !MediaQuery.of(context).disableAnimations) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        // 3 oscilații complete, amortizate spre final.
        final dx = 8 * math.sin(t * math.pi * 6) * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Intrare moale (fade + alunecare 14px în sus) la prima construire, cu
/// întârziere dată de [index], pentru liste care „curg" în ecran pe rând.
/// Cu reduce-motion conținutul apare direct.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, this.index = 0, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Dur.emph,
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Numărătoare animată (0 → valoare) pentru XP/ghinde în celebrații.
/// [format] schimbă afișarea numărului (ex. separatori de mii).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = Dur.epic,
    this.format,
    this.textAlign,
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final String Function(int value)? format;
  final TextAlign? textAlign;

  String _text(int v) => '$prefix${format?.call(v) ?? '$v'}$suffix';

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(_text(value), style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) =>
          Text(_text(v.round()), style: style, textAlign: textAlign),
    );
  }
}

/// Explozie de confetti fără niciun pachet extern: un overlay de 1200ms cu
/// 36 de particule pictate manual. Skippable (tap oriunde), no-op cu
/// reduce-motion. DOAR pentru momentele epice: folosită des, moare.
class ConfettiBurst {
  static void show(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiOverlay(
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Dur.epic)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  late final List<_Particle> _particles = _spawn();

  static const _palette = [C.blue, C.amber, C.green, C.violet, C.danger];

  List<_Particle> _spawn() {
    final rng = math.Random();
    return List.generate(36, (i) {
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 1.1;
      final speed = 0.55 + rng.nextDouble() * 0.65;
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 5 + rng.nextDouble() * 5,
        spin: (rng.nextDouble() - 0.5) * 10,
        color: _palette[i % _palette.length],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer scoate confetti din hit-test (butoanele de dedesubt merg
    // normal); Listener doar observă pointerul (fără gesture arena) și îl
    // folosește ca „skip". Un singur tap: butonul merge, petrecerea tace.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.onDone(),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_particles, _c.value),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double vx;
  final double vy;
  final double size;
  final double spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.32);
    final travel = size.height * 0.9;
    final paint = Paint();
    for (final p in particles) {
      // Traiectorie balistică simplă: impuls inițial + gravitație.
      final x = origin.dx + p.vx * travel * t;
      final y = origin.dy + p.vy * travel * t + travel * 0.85 * t * t;
      if (y > size.height + 20) continue;
      paint.color = p.color.withValues(alpha: (1.6 - 1.6 * t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.62,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
