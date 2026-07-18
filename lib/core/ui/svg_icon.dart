import 'package:flutter/widgets.dart';

/// Cache de path-uri parsate, cheie = `d`. `d` determină singur geometria
/// (viewBox afectează doar scala); fără cache, aceleași path-uri erau
/// re-parsate la fiecare desenare.
final Map<String, Path> _pathCache = {};

/// Întoarce un [Path] din cache pentru `d` dat, parsat o singură dată.
Path cachedSvgPath(String d) => _pathCache.putIfAbsent(d, () => parseSvgPath(d));

/// Parsează un string SVG path `d` într-un [Path] Flutter.
/// Suportă M/m L/l H/h V/v C/c S/s Q/q T/t A/a Z/z (absolut + relativ).
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _tokenize(d);
  int i = 0;
  double cx = 0, cy = 0; // punctul curent
  double sx = 0, sy = 0; // începutul subpath-ului
  double lcx = 0, lcy = 0; // ultimul control cubic (pt. S)
  double lqx = 0, lqy = 0; // ultimul control quad (pt. T)
  String lastCmd = '';

  double num() => tokens[i++] as double;

  while (i < tokens.length) {
    var cmd = tokens[i] is String ? tokens[i++] as String : lastCmd;
    final rel = cmd.toLowerCase() == cmd;
    final u = cmd.toUpperCase();
    lastCmd = cmd;

    switch (u) {
      case 'M':
        double x = num(), y = num();
        if (rel) { x += cx; y += cy; }
        path.moveTo(x, y);
        cx = x; cy = y; sx = x; sy = y;
        lastCmd = rel ? 'l' : 'L'; // perechile următoare sunt lineto
        break;
      case 'L':
        double x = num(), y = num();
        if (rel) { x += cx; y += cy; }
        path.lineTo(x, y); cx = x; cy = y;
        break;
      case 'H':
        double x = num();
        if (rel) x += cx;
        path.lineTo(x, cy); cx = x;
        break;
      case 'V':
        double y = num();
        if (rel) y += cy;
        path.lineTo(cx, y); cy = y;
        break;
      case 'C':
        double x1 = num(), y1 = num(), x2 = num(), y2 = num(), x = num(), y = num();
        if (rel) { x1 += cx; y1 += cy; x2 += cx; y2 += cy; x += cx; y += cy; }
        path.cubicTo(x1, y1, x2, y2, x, y);
        lcx = x2; lcy = y2; cx = x; cy = y;
        break;
      case 'S':
        double x2 = num(), y2 = num(), x = num(), y = num();
        if (rel) { x2 += cx; y2 += cy; x += cx; y += cy; }
        final rc = (lastCmdWasCubic(lastCmd));
        final x1 = rc ? 2 * cx - lcx : cx;
        final y1 = rc ? 2 * cy - lcy : cy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        lcx = x2; lcy = y2; cx = x; cy = y;
        break;
      case 'Q':
        double x1 = num(), y1 = num(), x = num(), y = num();
        if (rel) { x1 += cx; y1 += cy; x += cx; y += cy; }
        path.quadraticBezierTo(x1, y1, x, y);
        lqx = x1; lqy = y1; cx = x; cy = y;
        break;
      case 'T':
        double x = num(), y = num();
        if (rel) { x += cx; y += cy; }
        final rq = lastCmdWasQuad(lastCmd);
        final x1 = rq ? 2 * cx - lqx : cx;
        final y1 = rq ? 2 * cy - lqy : cy;
        path.quadraticBezierTo(x1, y1, x, y);
        lqx = x1; lqy = y1; cx = x; cy = y;
        break;
      case 'A':
        double rx = num(), ry = num(), rot = num(), large = num(), sweep = num(), x = num(), y = num();
        if (rel) { x += cx; y += cy; }
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx.abs(), ry.abs()),
          rotation: rot,
          largeArc: large != 0,
          clockwise: sweep != 0,
        );
        cx = x; cy = y;
        break;
      case 'Z':
        path.close();
        cx = sx; cy = sy;
        break;
    }
    // Ține evidența controlului reflectat pentru continuitatea S/T.
    if (u != 'C' && u != 'S') { lcx = cx; lcy = cy; }
    if (u != 'Q' && u != 'T') { lqx = cx; lqy = cy; }
  }
  return path;
}

bool lastCmdWasCubic(String c) => c == 'C' || c == 'c' || c == 'S' || c == 's';
bool lastCmdWasQuad(String c) => c == 'Q' || c == 'q' || c == 'T' || c == 't';

List<Object> _tokenize(String d) {
  final out = <Object>[];
  // Literă de comandă, SAU un număr SVG: semn opțional, (cifre.cifre | cifre. | .cifre),
  // exponent opțional. Un '-'/'+' final NU e consumat (începe numărul următor).
  final re = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])|(-?(?:\d*\.\d+|\d+\.?)(?:[eE][+-]?\d+)?)');
  for (final m in re.allMatches(d)) {
    if (m.group(1) != null) {
      out.add(m.group(1)!);
    } else {
      out.add(double.parse(m.group(2)!));
    }
  }
  return out;
}

/// Randează un path SVG ca icon (stroke sau fill), scalat din [viewBox] la [size].
class SvgIcon extends StatelessWidget {
  final String path;
  final double size;
  final double viewBox;
  final Color color;
  final double strokeWidth;
  final bool fill;

  const SvgIcon(
    this.path, {
    super.key,
    required this.size,
    this.viewBox = 24,
    required this.color,
    this.strokeWidth = 2,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SvgPainter(path, viewBox, color, strokeWidth, fill),
      ),
    );
  }
}

class _SvgPainter extends CustomPainter {
  final String d;
  final double viewBox;
  final Color color;
  final double strokeWidth;
  final bool fill;
  late final Path _path = cachedSvgPath(d);

  _SvgPainter(this.d, this.viewBox, this.color, this.strokeWidth, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / viewBox;
    canvas.scale(s, s);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (fill) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }
    canvas.drawPath(_path, paint);
  }

  @override
  bool shouldRepaint(_SvgPainter old) =>
      old.d != d || old.color != color || old.strokeWidth != strokeWidth || old.fill != fill;
}

/// Constante de path-uri, extrase 1:1 din dicționarul ICON din design reference.
class Ic {
  static const home = 'M3 9.9 12 3l9 6.9M5.6 8.8V20.5h12.8V8.8M9.7 20.5v-6.2h4.6v6.2';
  static const plus = 'M12 5v14M5 12h14';
  static const learn = 'M12 4 2.3 9 12 14l9.7-5L12 4ZM6.5 11v4.2c0 1.4 2.5 2.6 5.5 2.6s5.5-1.2 5.5-2.6V11M21.7 9v5';
  static const book = 'M5 5a2 2 0 0 1 2-2h11v16H7a2 2 0 0 0-2 2V5ZM5 19a2 2 0 0 0 2 2h11M9 7h6M9 11h5';
  static const shield = 'M12 3 5 6v5c0 4.5 3 7.6 7 9 4-1.4 7-4.5 7-9V6l-7-3ZM9 12l2.2 2.2L15 10';
  static const user = 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM5 20c0-3.3 3.1-6 7-6s7 2.7 7 6';
  static const flame = 'M12 2c1.3 3.6-2 4.7-2 7.7a2 2 0 0 0 4 .2c.2-.8.6-1.2.6-1.2 1.7 1.7 2.8 3.5 2.8 5.7a5.4 5.4 0 0 1-10.8 0C6.6 8.9 10 7.6 12 2Z';
  static const acorn = 'M12 2.4v1.8M5.6 8.2c0-2.2 2.9-3.9 6.4-3.9s6.4 1.7 6.4 3.9c0 .6-.5 1-1.2 1H6.8c-.7 0-1.2-.4-1.2-1ZM6.7 9.4c.5 4.7 2.6 11 5.3 11s4.8-6.3 5.3-11';
  static const target = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18ZM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM12 13.2a1.2 1.2 0 1 0 0-2.4 1.2 1.2 0 0 0 0 2.4';
  static const trending = 'M3 17l6-6 4 4 8-8M15 7h6v6';
  static const wallet = 'M3 7.5a2 2 0 0 1 2-2h11.5v3M3 7.5V17a2 2 0 0 0 2 2h13.5a1 1 0 0 0 1-1v-3M3 7.5h16.5M16.5 12h4v4h-4a2 2 0 0 1 0-4Z';
  static const trophy = 'M8 4h8v3.2a4 4 0 0 1-8 0V4ZM8 5.2H5.2v1a3 3 0 0 0 3 3M16 5.2h2.8v1a3 3 0 0 1-3 3M10 12.4h4V15h-4zM8 20h8M12 15v5';
  static const camera = 'M4 8h3l1.8-2.4h6.4L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1ZM12 16.6a3.4 3.4 0 1 0 0-6.8 3.4 3.4 0 0 0 0 6.8Z';
  static const mic = 'M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3ZM5 11a7 7 0 0 0 14 0M12 18v3';
  static const edit = 'M4 20h4.2L19 9.2 14.8 5 4 15.8V20ZM13.2 6.6l4.2 4.2';
  static const bus = 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v9H4V6ZM4 15h16v2a1 1 0 0 1-1 1h-1v1a1 1 0 0 1-2 0v-1H8v1a1 1 0 0 1-2 0v-1H5a1 1 0 0 1-1-1v-2ZM4 9h16M8 12h.01M16 12h.01';
  static const film = 'M4.5 4.5h15v15h-15zM4.5 9h15M4.5 15h15M9 4.5v15M15 4.5v15';
  static const bag = 'M6 8h12l1 12H5L6 8ZM9 8V6.2a3 3 0 0 1 6 0V8';
  static const repeat = 'M4 8h11a4 4 0 0 1 4 4M20 16H9a4 4 0 0 1-4-4M7 5 4 8l3 3M17 19l3-3-3-3';
  static const heart = 'M12 20C12 20 4 14.5 4 9a4 4 0 0 1 8-2 4 4 0 0 1 8 2c0 5.5-8 11-8 11Z';
  static const more = 'M6 12h.02M12 12h.02M18 12h.02';
  static const check = 'M4 12.5 9 17.5 20 6.5';
  static const x = 'M6 6l12 12M18 6 6 18';
  static const lock = 'M6.5 11V8a5.5 5.5 0 0 1 11 0v3M5 11h14v10H5zM12 15v3';
  static const chevron = 'M9 5l7 7-7 7';
  static const chevronRight = 'M9 5l7 7-7 7';
  static const chevronLeft = 'M15 5l-7 7 7 7';
  static const bell = 'M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6M10 20.5h4';
  static const sparkles = 'M12 3l1.7 4.6L18 9.3l-4.3 1.7L12 15.6l-1.7-4.6L6 9.3l4.3-1.7L12 3ZM18.5 14.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2Z';
  static const star = 'M12 3l1.7 4.6L18 9.3l-4.3 1.7L12 15.6l-1.7-4.6L6 9.3l4.3-1.7L12 3Z';
  static const link = 'M9.5 14.5l5-5M8 11 6.4 12.6a3.6 3.6 0 0 0 5 5L13 16M16 13l1.6-1.6a3.6 3.6 0 0 0-5-5L11 8';
  static const alert = 'M12 3.5 2.3 20.5h19.4L12 3.5ZM12 10v4M12 17.4v.1';
  static const phone = 'M8 3h8a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1ZM10.5 18h3';
  static const plane = 'M12 3c1 0 1.6 1 1.6 2.4v3.3l6.4 3.8v2l-6.4-1.9v3.7l1.9 1.4v1.6L12 22l-3.5-1.3v-1.6l1.9-1.4v-3.7L4 16.5v-2l6.4-3.8V5.4C10.4 4 11 3 12 3Z';
  static const gift = 'M4 11h16v9H4zM4 8h16v3H4zM12 8v12M12 8C10 8 8.5 7 8.5 5.5S9.7 3.5 10.5 4 12 6.4 12 8ZM12 8c2 0 3.5-1 3.5-2.5S14.3 3.5 13.5 4 12 6.4 12 8Z';
  static const clock = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18ZM12 7.5V12l3 2';
  static const scan = 'M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2M4 12h16';
  static const coins = 'M9 6.5a4.5 3 0 1 0 0 6 4.5 3 0 0 0 0-6ZM4.5 9.5v3c0 1.7 2 3 4.5 3s4.5-1.3 4.5-3M15 8.2a4.5 3 0 0 1 4.5 2.8c0 1.3-1.2 2.4-3 2.8M19.5 11v3c0 1.3-1.2 2.4-3 2.8';
  static const arrowRight = 'M5 12h14M13 6l6 6-6 6';
  static const message = 'M21 11.5a8.4 8.4 0 0 1-11.7 7.7L3 21l1.9-6.1A8.4 8.4 0 1 1 21 11.5Z';
  static const flag = 'M5 21V4M5 4h11l-1.5 4L16 12H5';
  static const pencilEdit = 'M10.5 4h-4a2 2 0 0 0-2 2v11.5a2 2 0 0 0 2 2H18a2 2 0 0 0 2-2v-4M18.5 3.5a1.6 1.6 0 0 1 2.3 2.3L12 15l-3 .7.7-3 8.8-9.2Z';
  static const glasses = 'M2 11h2.5l1.2 5.5a2.4 2.4 0 0 0 4.8-.3V13h3v3.2a2.4 2.4 0 0 0 4.8.3L19.5 11H22';
  static const medal = 'M8.5 3l3.5 5 3.5-5M12 21a5 5 0 1 0 0-10 5 5 0 0 0 0 10ZM12 8.5V11';
  static const crown = 'M4 8l3.5 3L12 5l4.5 6L20 8l-1.6 9.5H5.6L4 8Z';
  static const send = 'M4 12l16-8-6 8 6 8-16-8Z';
  static const star5 = 'M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.8 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8L12 2Z';
}
