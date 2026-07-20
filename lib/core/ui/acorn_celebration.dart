import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'juice.dart';
import 'motion.dart';
import 'tokens.dart';

/// Ploaia de ghinde pentru momentele mari: lecție terminată, luna încheiată,
/// cufăr deschis. Se deschide peste ecranul curent, ține până la atingere sau
/// până expiră, apoi dispare fără să schimbe nimic sub ea.
///
/// Ghindele cad pe trei planuri de adâncime, fiecare cu mărimea, viteza,
/// rotația și transparența ei. Tot ce nu se schimbă se calculează o singură
/// dată la deschidere, iar desenul se face într-un singur apel grafic pentru
/// toate ghindele deodată, ca să meargă și pe telefoane slabe.
class AcornCelebration {
  const AcornCelebration._();

  /// Deschide ploaia. [title] e rândul mare, [subtitle] cel mic de sub el.
  /// Cu reduce-motion pornit rămâne felicitarea, dar fără ghinde care cad.
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String mascot = Cashy.cashyCelebrate,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Stratul de sus al aplicației, ca ploaia să acopere și bara de navigare,
    // nu doar zona ecranului curent.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationLayer(
        title: title,
        subtitle: subtitle,
        mascot: mascot,
        duration: duration,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Juice.epic();
  }
}

/// O ghindă din ploaie. Valorile astea se aleg o dată și nu se mai schimbă.
class _Flake {
  const _Flake({
    required this.x,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
    required this.spin,
    required this.sway,
    required this.swayFreq,
  });

  /// Poziția orizontală de start, ca fracție din lățimea ecranului.
  final double x;
  final double size;
  final double opacity;

  /// Câte ecrane pe secundă coboară.
  final double speed;

  /// Decalajul de pornire, ca să nu cadă toate pe același rând.
  final double phase;

  /// Rotații pe secundă, negativ înseamnă în sens invers.
  final double spin;

  /// Cât se leagănă stânga-dreapta, ca fracție din lățime.
  final double sway;
  final double swayFreq;
}

/// Cele trei planuri de adâncime: în spate mici, palide și lente, în față mari,
/// opace și rapide. Câmpuri: mărime, opacitate, viteză, cota din total.
const _layers =
    <
      ({
        double minSize,
        double maxSize,
        double minOpacity,
        double maxOpacity,
        double minSpeed,
        double maxSpeed,
        double share,
      })
    >[
      (
        minSize: 12,
        maxSize: 22,
        minOpacity: 0.22,
        maxOpacity: 0.40,
        minSpeed: 0.16,
        maxSpeed: 0.24,
        share: 0.42,
      ),
      (
        minSize: 22,
        maxSize: 36,
        minOpacity: 0.45,
        maxOpacity: 0.70,
        minSpeed: 0.26,
        maxSpeed: 0.36,
        share: 0.35,
      ),
      (
        minSize: 36,
        maxSize: 58,
        minOpacity: 0.80,
        maxOpacity: 1.00,
        minSpeed: 0.40,
        maxSpeed: 0.55,
        share: 0.23,
      ),
    ];

/// Ceasul ploii: o durată lungă parcursă o singură dată. Din ea scoatem
/// secundele scurse, monoton crescătoare, fără repornire.
const _clockSeconds = 60.0;

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer({
    required this.title,
    required this.subtitle,
    required this.mascot,
    required this.duration,
    required this.onDone,
  });

  final String title;
  final String? subtitle;
  final String mascot;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with TickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _clockSeconds ~/ 1),
  )..forward();

  /// Intrarea și ieșirea stratului, o singură dată.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: Dur.emph,
  )..forward();

  ui.Image? _acorn;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  List<_Flake> _flakes = const [];

  /// Tabelele pentru desen, alocate o singură dată. Pe fiecare cadru se
  /// rescriu doar transformările, restul rămâne neatins.
  Float32List? _transforms;
  Float32List? _rects;
  Int32List? _colors;

  bool _closing = false;

  /// Închiderea automată. E ținut ca să poată fi anulat dacă utilizatorul
  /// atinge ecranul mai devreme sau dacă stratul dispare din alt motiv.
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _autoClose = Timer(widget.duration, _close);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _stream = const AssetImage(
      'assets/icons/acorn.png',
    ).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _acorn = info.image);
    });
    _stream!.addListener(_listener!);
  }

  /// Alege ghindele și pregătește tabelele. Numărul crește cu ecranul, dar
  /// rămâne între limite ca să nu exagereze pe tablete.
  void _prepare(Size screen, ui.Image image) {
    if (_flakes.isNotEmpty) return;
    final count = (screen.width * screen.height / 5200).clamp(48, 110).toInt();
    final rng = math.Random();
    final flakes = <_Flake>[];
    for (final l in _layers) {
      final n = (count * l.share).round();
      for (var i = 0; i < n; i++) {
        flakes.add(
          _Flake(
            x: rng.nextDouble(),
            size: l.minSize + rng.nextDouble() * (l.maxSize - l.minSize),
            opacity:
                l.minOpacity + rng.nextDouble() * (l.maxOpacity - l.minOpacity),
            speed: l.minSpeed + rng.nextDouble() * (l.maxSpeed - l.minSpeed),
            phase: rng.nextDouble(),
            spin: (rng.nextDouble() - 0.5) * 1.6,
            sway: 0.01 + rng.nextDouble() * 0.05,
            swayFreq: 0.6 + rng.nextDouble() * 1.4,
          ),
        );
      }
    }

    final n = flakes.length;
    final transforms = Float32List(n * 4);
    final rects = Float32List(n * 4);
    final colors = Int32List(n);
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    for (var i = 0; i < n; i++) {
      rects[i * 4 + 2] = w;
      rects[i * 4 + 3] = h;
      // Alb cu transparența ghindei: amestecul „modulate" înmulțește doar
      // opacitatea, culorile desenului rămân neatinse.
      colors[i] = Color.fromRGBO(255, 255, 255, flakes[i].opacity).toARGB32();
    }

    _flakes = flakes;
    _transforms = transforms;
    _rects = rects;
    _colors = colors;
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _autoClose?.cancel();
    await _fade.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    if (_listener != null) _stream?.removeListener(_listener!);
    _rain.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Cu reduce-motion pornit rămâne felicitarea, dar fără ploaie și fără
    // tranziții: mesajul nu are voie să se piardă doar pentru că cineva a
    // oprit animațiile.
    final motion = !media.disableAnimations;
    final image = motion ? _acorn : null;
    if (image != null) _prepare(media.size, image);
    if (!motion) _fade.value = 1;

    // Mascota se strânge pe ecrane mici, iar coloana poate derula, ca să nu
    // dea pe dinafară nici cu textul sistemului mărit.
    final mascotWidth = math.min(190.0, media.size.width * 0.42);

    // Stratul stă deasupra tuturor ecranelor, deci n-are Material deasupra
    // lui. Fără ăsta, textul primește sublinierea galbenă de avarie.
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xCC0B1526)),
              if (image != null && _transforms != null)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _rain,
                    builder: (_, _) => CustomPaint(
                      painter: _RainPainter(
                        image: image,
                        flakes: _flakes,
                        transforms: _transforms!,
                        rects: _rects!,
                        colors: _colors!,
                        elapsed: _rain.value * _clockSeconds,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopIn(
                        child: Image.asset(widget.mascot, width: mascotWidth),
                      ),
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 1,
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: T.display(
                            size: 30,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 8),
                        StaggerIn(
                          index: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              style: T.body(
                                size: 15,
                                weight: FontWeight.w600,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      StaggerIn(
                        index: 3,
                        child: Text(
                          'atinge ca să continui',
                          style: T.body(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenează toată ploaia dintr-un singur apel grafic.
class _RainPainter extends CustomPainter {
  const _RainPainter({
    required this.image,
    required this.flakes,
    required this.transforms,
    required this.rects,
    required this.colors,
    required this.elapsed,
  });

  final ui.Image image;
  final List<_Flake> flakes;
  final Float32List transforms;
  final Float32List rects;
  final Int32List colors;

  /// Secunde de la deschiderea ploii.
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final anchorX = image.width / 2;
    final anchorY = image.height / 2;

    for (var i = 0; i < flakes.length; i++) {
      final f = flakes[i];
      // Coboară de deasupra ecranului până sub el, apoi o ia de la capăt.
      final p = (elapsed * f.speed + f.phase) % 1.0;
      final y = -0.2 + p * 1.4;
      final x =
          f.x +
          math.sin((elapsed * f.swayFreq + f.phase) * 2 * math.pi) * f.sway;
      final rot = (elapsed * f.spin + f.phase) * 2 * math.pi;
      final scale = f.size / image.width;

      final scos = math.cos(rot) * scale;
      final ssin = math.sin(rot) * scale;
      final tx = x * size.width;
      final ty = y * size.height;
      transforms[i * 4] = scos;
      transforms[i * 4 + 1] = ssin;
      transforms[i * 4 + 2] = tx - scos * anchorX + ssin * anchorY;
      transforms[i * 4 + 3] = ty - ssin * anchorX - scos * anchorY;
    }

    canvas.drawRawAtlas(
      image,
      transforms,
      rects,
      colors,
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.elapsed != elapsed;
}
