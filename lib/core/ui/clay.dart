import 'dart:math' as math;
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'motion.dart';
import 'tokens.dart';
import 'svg_icon.dart';

/// Card cu bordură subțire și umbră clay
class ClayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final Color color;
  final bool border;
  final Gradient? gradient;

  const ClayCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.shadow,
    this.color = C.surface,
    this.border = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: C.line, width: 1) : null,
        boxShadow: shadow ?? Sh.card,
      ),
      child: child,
    );
  }
}

/// Pătrat colorat pentru iconițe (tranzacții, insights)
class ClayIcon extends StatelessWidget {
  final String path;
  final double size;
  final double radius;
  final double iconSize;
  final Color tint;
  final Color color;
  final double strokeWidth;
  final bool fill;

  const ClayIcon({
    super.key,
    required this.path,
    required this.tint,
    required this.color,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 23,
    this.strokeWidth = 2,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: SvgIcon(
        path,
        size: iconSize,
        color: color,
        strokeWidth: strokeWidth,
        fill: fill,
      ),
    );
  }
}

/// Buton pill cu gradient, full-width. Dacă [onTap] e null, se dezactivează
/// (opacity 0.5). Rămâne pe [GestureDetector] în loc de Material/InkWell
/// pentru că ripple-ul nu arată bine peste gradient.
class ClayButton extends StatefulWidget {
  final String label;
  final Gradient gradient;
  final List<BoxShadow> shadow;
  final Color textColor;
  final double height;
  final double fontSize;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ClayButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.shadow,
    this.textColor = C.blueInk,
    this.height = 58,
    this.fontSize = 17,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  /// Umbra „comprimată" la apăsare: butonul chiar coboară spre suprafață.
  List<BoxShadow> get _pressedShadow => [
    for (final s in widget.shadow)
      BoxShadow(
        color: s.color,
        offset: Offset(s.offset.dx * 0.45, s.offset.dy * 0.45),
        blurRadius: s.blurRadius * 0.55,
        spreadRadius: s.spreadRadius * 0.7,
        inset: s.inset,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Squish asimetric: coboară repede, revine cu arc. De-aici vine senzația
    // de „clay" apăsat. Cu reduce-motion, stările comută instant (fără overshoot).
    final content = AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: reduceMotion
          ? Duration.zero
          : (_pressed ? Dur.tap : const Duration(milliseconds: 350)),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : Dur.fast,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(R.pill),
          boxShadow: _pressed ? _pressedShadow : widget.shadow,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: T.display(
                size: widget.fontSize,
                weight: FontWeight.w800,
                color: widget.textColor,
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.5, child: content);
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: content,
    );
  }
}

/// Inelul de buget. [percent] merge de la 0 la 1.
class RingGauge extends StatelessWidget {
  final double size;
  final double percent;
  final Gradient gradient;
  // Ambele se măsoară în unitățile viewBox-ului, care are latura 120.
  final double strokeWidth;
  final double radius;
  final Color trackColor;
  final Widget? center;

  const RingGauge({
    super.key,
    this.size = 134,
    required this.percent,
    this.gradient = Grad.ring,
    this.strokeWidth = 15,
    this.radius = 50,
    this.trackColor = C.inset,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    // Inelul se umple animat la deschidere și alunecă lin la orice schimbare.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedFrac(
            value: percent,
            duration: const Duration(milliseconds: 900),
            builder: (_, v) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                v,
                gradient,
                strokeWidth / 120 * size,
                radius / 120 * size,
                trackColor,
              ),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Gradient gradient;
  final double strokeWidth;
  final double radius;
  final Color trackColor;
  _RingPainter(
    this.percent,
    this.gradient,
    this.strokeWidth,
    this.radius,
    this.trackColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final prog = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, prog);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.percent != percent;
}

/// Cadranul de scor, un arc de 270 de grade. [percent] merge de la 0 la 1.
class ScoreGauge extends StatelessWidget {
  final double width;
  final double visibleHeight;
  final double percent;
  final Widget? center;

  const ScoreGauge({
    super.key,
    this.width = 86,
    this.visibleHeight = 62,
    required this.percent,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: visibleHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          AnimatedFrac(
            value: percent,
            duration: const Duration(milliseconds: 900),
            builder: (_, v) => CustomPaint(
              size: Size(width, width),
              painter: _ScorePainter(v, 22 / 220 * width, 90 / 220 * width),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final double radius;
  _ScorePainter(this.percent, this.strokeWidth, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.width / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = 135 * math.pi / 180;
    const total = 270 * math.pi / 180;
    final track = Paint()
      ..color = C.inset
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, total, false, track);

    final prog = Paint()
      ..shader = Grad.scoreRing.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, total * percent, false, prog);
  }

  @override
  bool shouldRepaint(_ScorePainter o) => o.percent != percent;
}

/// Bară orizontală segmentată de buget, cu goluri de 2px și capete rotunjite.
class SegmentBar extends StatelessWidget {
  final List<(int, Color)> segments; // (flex, color)
  final double height;
  const SegmentBar({super.key, required this.segments, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      children.add(
        Expanded(
          flex: segments[i].$1,
          child: Container(color: segments[i].$2),
        ),
      );
      if (i != segments.length - 1) children.add(const SizedBox(width: 2));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        child: Row(children: children),
      ),
    );
  }
}

/// Status bar stil iOS cu notch central (potrivit cu mockup-ul).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '9:41',
                  style: T.display(
                    size: 15,
                    weight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
                Row(
                  children: [_signal(), const SizedBox(width: 6), _battery()],
                ),
              ],
            ),
          ),
          Positioned(
            top: 13,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 106,
                height: 30,
                decoration: BoxDecoration(
                  color: C.notch,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double h, {double opacity = 1}) => Container(
    width: 3,
    height: h,
    margin: const EdgeInsets.only(left: 2),
    decoration: BoxDecoration(
      color: C.text.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(1),
    ),
  );

  Widget _signal() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [_bar(5), _bar(7.5), _bar(10), _bar(12, opacity: 0.4)],
  );

  Widget _battery() => SizedBox(
    width: 26,
    height: 13,
    child: Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          width: 22,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.2),
            border: Border.all(
              color: C.text.withValues(alpha: 0.5),
              width: 1.3,
            ),
          ),
        ),
        Positioned(
          left: 2,
          child: Container(
            width: 15,
            height: 7,
            decoration: BoxDecoration(
              color: C.blue,
              borderRadius: BorderRadius.circular(1.6),
            ),
          ),
        ),
        Positioned(
          left: 23.4,
          child: Container(
            width: 1.8,
            height: 4.2,
            decoration: BoxDecoration(
              color: C.text.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Thumb de slider: cerc gradient de 30px cu inel alb și umbră.
class ClaySliderThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool enabled, bool disabled) => const Size(30, 30);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawShadow(
      Path()
        ..addOval(Rect.fromCircle(center: center.translate(0, 3), radius: 13)),
      const Color(0xFF1560D8),
      6,
      true,
    );
    const grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7FB4FF), C.blue, C.blueDeep],
      stops: [0.0, 0.6, 1.0],
    );
    canvas.drawCircle(center, 15, Paint()..color = C.surface);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..shader = grad.createShader(
          Rect.fromCircle(center: center, radius: 12),
        ),
    );
  }
}

class NavItem {
  final String path;
  final String label;
  const NavItem(this.path, this.label);
}

/// Bară de navigare jos, cu buton central plutitor. Navigarea e delegată
/// prin callback-uri ([onTap]/[onFab]); widget-ul nu știe nimic de routing.
class BottomNav extends StatelessWidget {
  /// Indexul tab-ului activ; -1 pentru ecrane din afara setului de tab-uri.
  final int active;
  final bool fabGlow;
  final Color activeColor;
  final Color activeBg;

  /// Cele patru tab-uri (icon + etichetă). Implicit setul standard al aplicației.
  final List<NavItem> items;
  final ValueChanged<int>? onTap;
  final VoidCallback? onFab;

  const BottomNav({
    super.key,
    this.active = 0,
    this.fabGlow = false,
    this.activeColor = C.blue,
    this.activeBg = C.blueSoft,
    this.items = defaultItems,
    this.onTap,
    this.onFab,
  });

  /// Etichete implicite pentru apelanții care nu dau altele localizate.
  static const defaultItems = [
    NavItem(Ic.home, 'Acasă'),
    NavItem(Ic.book, 'Învață'),
    NavItem(Ic.target, 'Arcade'),
    NavItem(Ic.user, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(R.pill),
            border: Border.all(color: C.line, width: 1),
            boxShadow: Sh.nav,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navButton(0),
              _navButton(1),
              const SizedBox(width: 56),
              _navButton(2),
              _navButton(3),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -13),
          child: Pressable(onTap: onFab, scale: 0.9, child: _fab()),
        ),
      ],
    );
  }

  Widget _navButton(int i) {
    final item = items[i];
    final isActive = i == active;
    final color = isActive ? activeColor : C.text3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isActive) onTap?.call(i);
      },
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavBounce(
              active: isActive,
              child: AnimatedContainer(
                duration: Dur.base,
                curve: Curves.easeOut,
                width: 42,
                height: 32,
                // Lista goală e obligatorie: lerp-ul pachetului de umbre nu
                // acceptă boxShadow null și ar crăpa la schimbarea tabului.
                decoration: BoxDecoration(
                  color: isActive ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [],
                ),
                alignment: Alignment.center,
                child: SvgIcon(
                  item.path,
                  size: 22,
                  color: color,
                  strokeWidth: isActive ? 2.1 : 2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: T.display(
                size: 10,
                weight: isActive ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      gradient: Grad.navFab,
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        ...Sh.blue,
        if (fabGlow) const BoxShadow(color: C.blueSoft, spreadRadius: 5),
      ],
    ),
    alignment: Alignment.center,
    child: const SvgIcon(
      Ic.plus,
      size: 28,
      color: Colors.white,
      strokeWidth: 2.8,
    ),
  );
}

/// Săltătură scurtă a iconului când tabul devine activ.
class _NavBounce extends StatefulWidget {
  const _NavBounce({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_NavBounce> createState() => _NavBounceState();
}

class _NavBounceState extends State<_NavBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Dur.emph,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.22,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.22,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(_NavBounce old) {
    super.didUpdateWidget(old);
    if (!old.active &&
        widget.active &&
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
