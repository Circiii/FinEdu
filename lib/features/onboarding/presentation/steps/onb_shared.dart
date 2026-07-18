import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../../core/ui/acorn.dart';
import '../../../../core/ui/tokens.dart';

/// Paleta de culori pentru cheia Cashy ('sky'|'mint'|'amber'|'violet').
({Color accent, Color soft}) onbAccentFor(String key) => switch (key) {
      'mint' => (accent: C.green, soft: C.greenSoft),
      'amber' => (accent: C.amber, soft: C.amberSoft),
      'violet' => (accent: C.violet, soft: C.violetSoft),
      _ => (accent: C.sky, soft: C.skySoft),
    };

/// Scena cu halou radial + cerc punctat pe care se centrează fiecare pas.
class OnbHalo extends StatelessWidget {
  const OnbHalo({
    super.key,
    required this.accent,
    required this.child,
    this.size = 236,
  });

  final Color accent;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 14,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 36,
            height: size - 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.2),
                  accent.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
          CustomPaint(
            size: Size(size - 6, size - 6),
            painter: DashedCircle(accent.withValues(alpha: 0.25)),
          ),
          child,
        ],
      ),
    );
  }
}

/// Blocul kicker + titlu + body folosit de fiecare pas.
class OnbHeader extends StatelessWidget {
  const OnbHeader({
    super.key,
    required this.kicker,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String kicker;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AcornText(kicker.toUpperCase(),
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: accent,
                letterSpacing: 12 * 0.12)),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(title,
              textAlign: TextAlign.center,
              style: T.display(
                  size: 30,
                  weight: FontWeight.w800,
                  color: C.text,
                  height: 1.08,
                  letterSpacing: 30 * -0.015)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(body,
              textAlign: TextAlign.center,
              style: T.body(
                  size: 15.5,
                  weight: FontWeight.w400,
                  color: C.text2,
                  height: 1.5)),
        ),
      ],
    );
  }
}

/// Container clay inset care găzduiește un [TextField].
class ClayField extends StatelessWidget {
  const ClayField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: C.inset,
            borderRadius: BorderRadius.circular(16),
            boxShadow: Sh.insetSoft,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onChanged: onChanged,
            style: T.display(size: 18, weight: FontWeight.w700, color: C.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  T.display(size: 18, weight: FontWeight.w700, color: C.text3),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 6),
            child: Text(errorText!,
                style:
                    T.body(size: 13, weight: FontWeight.w600, color: C.danger)),
          ),
      ],
    );
  }
}

/// Wrapper de shake orizontal (feedback pentru răspuns greșit / nume nepotrivit).
class Shake extends StatelessWidget {
  const Shake({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) => Transform.translate(
        offset: Offset(math.sin(animation.value * math.pi * 5) * 7, 0),
        child: c,
      ),
      child: child,
    );
  }
}

class DashedCircle extends CustomPainter {
  DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dash = 6.0, gap = 7.0;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    final sweep = dash / radius;
    final gapAngle = (2 * math.pi - sweep * count) / count;
    double a = -math.pi / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), a, sweep,
          false, paint);
      a += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(DashedCircle o) => o.color != color;
}
