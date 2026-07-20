import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'juice.dart';
import 'tokens.dart';

/// Face orice widget apăsabil cu senzație de clay: se strânge puțin la
/// atingere și revine cu arc la ridicare. Opțional dă și un haptic scurt.
/// Pentru carduri, tile-uri, chip-uri, tot ce nu e deja [ClayButton].
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        if (widget.haptic) Juice.tick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: reduceMotion
            ? Duration.zero
            : (_down ? Dur.tap : const Duration(milliseconds: 320)),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Plutire abia perceptibilă în sus și-n jos, ca o respirație. Amplitudinea
/// stă la 1 pixel: mascota trebuie să pară vie, nu să se legene.
class Floaty extends StatefulWidget {
  const Floaty({
    super.key,
    required this.child,
    this.amplitude = 1,
    this.period = const Duration(milliseconds: 3400),
    this.phase = 0,
  });

  final Widget child;
  final double amplitude;
  final Duration period;

  /// Defazaj 0..1, ca două mascote vecine să nu respire identic.
  final double phase;

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Cu amplitudine 0 nu are ce pluti, nu pornim degeaba ticker-ul.
    if (widget.amplitude != 0 && !MediaQuery.of(context).disableAnimations) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amplitude == 0) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = (_c.value + widget.phase) % 1.0;
        final dy = math.sin(t * 2 * math.pi) * widget.amplitude;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Pulsare ușoară de scală în buclă (1 → 1.06 → 1). Pentru flacăra de streak
/// și alte accente care merită să atragă privirea fără să deranjeze.
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.scale = 1.06,
    this.period = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final double scale;
  final Duration period;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Cu scala 1 nu are ce pulsa, nu pornim degeaba ticker-ul.
    if (widget.scale != 1.0 && !MediaQuery.of(context).disableAnimations) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scale == 1.0) return widget.child;
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: widget.scale,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Fracție animată 0..1 pentru bare de progres: la prima construire se umple
/// de la 0, la schimbări alunecă lin spre noua valoare.
class AnimatedFrac extends StatelessWidget {
  const AnimatedFrac({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    if (MediaQuery.of(context).disableAnimations) {
      return builder(context, v);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: duration,
      curve: curve,
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// Intrare cu „pop": fade + scală de la 0.7 cu arc elastic, întârziată după
/// [index]. Pentru noduri de path și elemente care sar în scenă pe rând.
class PopIn extends StatefulWidget {
  const PopIn({super.key, this.index = 0, this.step = 55, required this.child});

  final int index;
  final int step;
  final Widget child;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
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
    Future.delayed(Duration(milliseconds: widget.step * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: const Interval(0, 0.5)),
      child: ScaleTransition(
        scale: Tween(
          begin: 0.7,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
        child: widget.child,
      ),
    );
  }
}

/// Pagină cu tranziția standard a aplicației: alunecă puțin de jos + fade,
/// iar la închidere iese repede. Folosită de toate rutele push.
class ClayPage<TResult> extends CustomTransitionPage<TResult> {
  ClayPage({required super.child, super.key, super.name})
    : super(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondary, child) {
          if (MediaQuery.of(context).disableAnimations) return child;
          final t = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: t,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(t),
              child: child,
            ),
          );
        },
      );
}

/// Fade scurt la schimbarea tabului activ din shell. IndexedStack-ul de sub
/// el păstrează starea; aici doar înmuiem saltul dintre taburi.
class TabFade extends StatefulWidget {
  const TabFade({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Dur.base,
    value: 1,
  );

  @override
  void didUpdateWidget(TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index &&
        !MediaQuery.of(context).disableAnimations) {
      _c.forward(from: 0.25);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: widget.child,
    );
  }
}
