import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Ghinda oficială a aplicației (PNG), moneda se vede identic peste tot:
/// balanțe, recompense, prețuri. Înlocuiește emoji-ul 🌰 și iconița vectorială.
class AcornIcon extends StatelessWidget {
  const AcornIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/acorn.png',
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
  );
}

/// Seed-ul ploii, ales o dată la pornirea aplicației: de fiecare dată când
/// intri, ghindele cad altfel, dar rămân pe loc cât timp te plimbi prin ecrane.
final int acornRainSeed = DateTime.now().microsecondsSinceEpoch & 0x3fffffff;

/// O ghindă din fundal, cu locul, mărimea, rotația și transparența ei.
class _Acorn {
  const _Acorn(this.pos, this.size, this.rot, this.opacity);

  final Offset pos;
  final double size;
  final double rot;
  final double opacity;
}

/// Așezările deja calculate, pe mărime de ecran. Toate ecranele refolosesc
/// aceeași ploaie, deci fundalul nu sare când treci dintr-unul în altul.
final _rainCache = <String, List<_Acorn>>{};

List<_Acorn> _rainFor(Size size) {
  final key = '${size.width.round()}x${size.height.round()}';
  final cached = _rainCache[key];
  if (cached != null) return cached;

  final rng = math.Random(acornRainSeed);
  final count = (size.width * size.height / 6500).clamp(40, 220).toInt();
  final placed = <_Acorn>[];
  for (var i = 0; i < count; i++) {
    final s = 20 + rng.nextDouble() * 38;
    // Câteva încercări per ghindă: dacă ar călca peste una deja pusă, căutăm
    // alt loc; dacă nu încape nicăieri, o sărim.
    Offset? pos;
    for (var t = 0; t < 20 && pos == null; t++) {
      final cand = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      var free = true;
      for (final a in placed) {
        final minDist = (s + a.size) / 2 + 6;
        if ((cand - a.pos).distanceSquared < minDist * minDist) {
          free = false;
          break;
        }
      }
      if (free) pos = cand;
    }
    if (pos == null) continue;
    placed.add(
      _Acorn(
        pos,
        s,
        (rng.nextDouble() - 0.5) * 1.5,
        0.045 + rng.nextDouble() * 0.085,
      ),
    );
  }

  if (_rainCache.length > 6) _rainCache.clear();
  _rainCache[key] = placed;
  return placed;
}

/// Ploaie decorativă de ghinde pe fundal: multe, împrăștiate, cu mărimi,
/// rotații și transparențe diferite, ca și cum ar cădea din cer.
class AcornRain extends StatefulWidget {
  const AcornRain({super.key});

  @override
  State<AcornRain> createState() => _AcornRainState();
}

class _AcornRainState extends State<AcornRain> {
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _stream = const AssetImage(
      'assets/icons/acorn.png',
    ).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _image = info.image);
    });
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.expand();
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AcornRainPainter(image),
        size: Size.infinite,
      ),
    );
  }
}

class _AcornRainPainter extends CustomPainter {
  const _AcornRainPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.low;
    for (final a in _rainFor(size)) {
      canvas
        ..save()
        ..translate(a.pos.dx, a.pos.dy)
        ..rotate(a.rot);
      canvas.drawImageRect(
        image,
        src,
        Rect.fromCenter(center: Offset.zero, width: a.size, height: a.size),
        paint..color = Colors.white.withValues(alpha: a.opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AcornRainPainter old) => old.image != image;
}

/// Text în care fiecare 🌰 devine imaginea ghindei, aliniată pe mijlocul
/// rândului. Stilul, alinierea și overflow-ul se comportă ca la [Text].
class AcornText extends StatelessWidget {
  const AcornText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final size = (style?.fontSize ?? 14) * 1.1;
    final parts = text.split('🌰');
    if (parts.length == 1) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AcornIcon(size: size),
                ),
              ),
            if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
          ],
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
