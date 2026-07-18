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

/// Ploaie decorativă de ghinde pe fundal: multe, împrăștiate, cu mărimi,
/// rotații și transparențe diferite, ca și cum ar cădea din cer. Pozițiile
/// vin dintr-un seed fix, deci arată identic la fiecare deschidere.
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
    // seed fix: aceeași ploaie la fiecare deschidere
    final rng = math.Random(20260719);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final count = (size.width * size.height / 16000).clamp(26, 120).toInt();
    final placed = <(Offset, double)>[];
    for (var i = 0; i < count; i++) {
      final s = 14 + rng.nextDouble() * 26;
      // Câteva încercări per ghindă: dacă ar călca peste una deja pusă,
      // căutăm alt loc; dacă nu încape deloc, o sărim.
      Offset? pos;
      for (var t = 0; t < 12 && pos == null; t++) {
        final cand = Offset(
          rng.nextDouble() * size.width,
          rng.nextDouble() * size.height,
        );
        var free = true;
        for (final (p, ps) in placed) {
          final minDist = (s + ps) / 2 + 8;
          if ((cand - p).distanceSquared < minDist * minDist) {
            free = false;
            break;
          }
        }
        if (free) pos = cand;
      }
      if (pos == null) continue;
      placed.add((pos, s));
      final rot = (rng.nextDouble() - 0.5) * 1.3;
      final op = 0.05 + rng.nextDouble() * 0.09;
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(rot);
      canvas.drawImageRect(
        image,
        src,
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        Paint()
          ..color = Colors.white.withValues(alpha: op)
          ..filterQuality = FilterQuality.low,
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
