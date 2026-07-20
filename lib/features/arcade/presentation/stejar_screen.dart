import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/compound.dart';

/// Stejarul lui Cashy: loc de joacă cu dobânda compusă. Miști suma, dobânda
/// și anii, iar copacul, graficul și cifrele reacționează pe loc. Fără bani
/// reali, fără salvare: doar intuiția „banii lăsați să crească se dublează".
class StejarScreen extends StatefulWidget {
  const StejarScreen({super.key});

  @override
  State<StejarScreen> createState() => _StejarScreenState();
}

class _StejarScreenState extends State<StejarScreen> {
  double _monthly = 100;
  double _rate = 0.07;
  int _years = 10;

  static const _rates = [0.03, 0.05, 0.07, 0.10];

  List<double> get _series =>
      compoundSeries(monthly: _monthly, annualRate: _rate, years: _years);

  List<double> get _flat => flatSeries(monthly: _monthly, years: _years);

  /// Stadiul copacului crește cu soldul final: de la ghindă la stejar bătrân.
  String get _tree {
    final total = _series.last;
    if (total < 3000) return '🌰';
    if (total < 12000) return '🌱';
    if (total < 40000) return '🌿';
    if (total < 120000) return '🌳';
    return '🌳✨';
  }

  String get _treeLabel {
    final total = _series.last;
    if (total < 3000) return 'ghindă plantată';
    if (total < 12000) return 'puiet';
    if (total < 40000) return 'copăcel';
    if (total < 120000) return 'stejar în putere';
    return 'stejar bătrân';
  }

  @override
  Widget build(BuildContext context) {
    final total = _series.last;
    final interest = interestEarned(
      monthly: _monthly,
      annualRate: _rate,
      years: _years,
    );
    final years2x = doublingYears(_rate);

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          Column(
            children: [
              const StatusBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(context),
                      const SizedBox(height: 14),
                      StaggerIn(index: 0, child: _treeCard(total)),
                      const SizedBox(height: 12),
                      StaggerIn(index: 1, child: _chartCard()),
                      const SizedBox(height: 12),
                      StaggerIn(
                        index: 2,
                        child: _surpriseCard(interest, years2x),
                      ),
                      const SizedBox(height: 12),
                      StaggerIn(index: 3, child: _controlsCard()),
                      const SizedBox(height: 12),
                      StaggerIn(index: 4, child: _cashyLine()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: () => context.pop(),
          scale: 0.9,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            alignment: Alignment.center,
            child: const SvgIcon(
              Ic.chevronLeft,
              size: 18,
              color: C.text2,
              strokeWidth: 2.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Stejarul lui Cashy',
            style: T.display(size: 24, weight: FontWeight.w800, color: C.text),
          ),
        ),
      ],
    );
  }

  /// Copacul + soldul final: reacția mare la orice schimbare de parametri.
  Widget _treeCard(double total) {
    return ClayCard(
      radius: 26,
      gradient: Grad.green,
      shadow: Sh.green,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: Dur.emph,
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                _tree,
                key: ValueKey(_tree),
                style: const TextStyle(fontSize: 46),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _treeLabel,
                  style: T.display(
                    size: 13,
                    weight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
                JuiceBounce(
                  trigger: total.round(),
                  child: AnimatedCount(
                    value: total.round(),
                    format: fmtThousands,
                    suffix: ' lei',
                    duration: const Duration(milliseconds: 700),
                    style: T.display(
                      size: 30,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                ),
                Text(
                  'după $_years ${_years == 1 ? 'an' : 'ani'} cu ${fmtThousands(_monthly.round())} lei pe lună',
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
      ),
    );
  }

  /// Graficul: curba compusă față de banii ținuți la saltea. Diferența dintre
  /// ele E lecția, așa că salteaua rămâne mereu vizibilă ca linie de contrast.
  Widget _chartCard() {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(C.green, 'cu dobândă compusă'),
              const SizedBox(width: 14),
              _legendDot(C.text3, 'la saltea'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            width: double.infinity,
            // Cheia pe parametri: graficul se redesenează animat la fiecare
            // schimbare, ca și cum curba ar crește sub degetul tău.
            child: AnimatedFrac(
              key: ValueKey('${_monthly.round()}_${_rate}_$_years'),
              value: 1,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, drawn) => CustomPaint(
                painter: _ChartPainter(
                  compound: _series,
                  flat: _flat,
                  drawn: drawn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: T.body(size: 11.5, weight: FontWeight.w600, color: C.text2),
        ),
      ],
    );
  }

  /// Cifra-surpriză: cât din sold e dobândă pură, plus regula lui 72.
  Widget _surpriseCard(double interest, double years2x) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOBÂNDA SINGURĂ ȚI-A ADUS',
                  style: T.display(
                    size: 11,
                    weight: FontWeight.w700,
                    color: C.text3,
                    letterSpacing: 11 * 0.12,
                  ),
                ),
                const SizedBox(height: 4),
                JuiceBounce(
                  trigger: interest.round(),
                  child: AnimatedCount(
                    value: interest.round(),
                    format: fmtThousands,
                    prefix: '+',
                    suffix: ' lei',
                    duration: const Duration(milliseconds: 700),
                    style: T.display(
                      size: 24,
                      weight: FontWeight.w800,
                      color: C.greenDeep,
                    ),
                  ),
                ),
                Text(
                  'bani munciți de banii tăi, nu de tine',
                  style: T.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: C.text3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: C.violetSoft,
              borderRadius: BorderRadius.circular(R.sm),
            ),
            child: Column(
              children: [
                Text(
                  'se dublează în',
                  style: T.body(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: C.text2,
                  ),
                ),
                Text(
                  '~${years2x.round()} ani',
                  style: T.display(
                    size: 17,
                    weight: FontWeight.w800,
                    color: C.violetDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlsCard() {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sliderRow(
            label: 'Pui deoparte pe lună',
            valueText: '${fmtThousands(_monthly.round())} lei',
            value: _monthly,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (v) {
              if (v.round() != _monthly.round()) Juice.tick();
              setState(() => _monthly = v);
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Dobândă pe an',
            style: T.body(size: 12.5, weight: FontWeight.w700, color: C.text2),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final r in _rates) ...[
                Expanded(
                  child: Pressable(
                    haptic: false,
                    onTap: () {
                      if (_rate != r) Juice.tick();
                      setState(() => _rate = r);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _rate == r ? C.greenSoft : C.surface,
                        borderRadius: BorderRadius.circular(R.pill),
                        border: Border.all(
                          color: _rate == r ? C.green : C.line,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${(r * 100).round()}%',
                        style: T.display(
                          size: 14,
                          weight: FontWeight.w800,
                          color: _rate == r ? C.greenDeep : C.text2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (r != _rates.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _sliderRow(
            label: 'Ani de răbdare',
            valueText: '$_years ${_years == 1 ? 'an' : 'ani'}',
            value: _years.toDouble(),
            min: 1,
            max: 40,
            divisions: 39,
            onChanged: (v) {
              if (v.round() != _years) Juice.tick();
              setState(() => _years = v.round());
            },
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: T.body(
                size: 12.5,
                weight: FontWeight.w700,
                color: C.text2,
              ),
            ),
            JuiceBounce(
              trigger: valueText,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: C.greenSoft,
                  borderRadius: BorderRadius.circular(R.pill),
                ),
                child: Text(
                  valueText,
                  style: T.display(
                    size: 13,
                    weight: FontWeight.w800,
                    color: C.greenDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 10,
            activeTrackColor: C.green,
            inactiveTrackColor: C.inset,
            thumbShape: ClaySliderThumb(),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _cashyLine() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(Cashy.cashyDefault, width: 56),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(5),
              ),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            child: Text(
              'Secretul nu e suma, e timpul. Mută anii și uită-te la distanța dintre linii.',
              style: T.body(
                size: 13,
                weight: FontWeight.w500,
                color: C.text2,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cele două curbe pe ani: compusa (verde, plină) și salteaua (gri, punctată).
/// [drawn] taie ambele la aceeași fracție ca să crească împreună.
class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.compound,
    required this.flat,
    required this.drawn,
  });

  final List<double> compound;
  final List<double> flat;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 18.0;
    final plotW = size.width - leftPad;
    final plotH = size.height - bottomPad;
    final maxY = niceCeiling(compound.last);
    final n = compound.length - 1;

    Offset point(int i, double v) => Offset(
      leftPad + plotW * (n == 0 ? 0 : i / n),
      plotH - plotH * (v / maxY),
    );

    // Grila orizontală cu 3 repere și etichete compacte.
    final gridPaint = Paint()
      ..color = C.line
      ..strokeWidth = 1;
    final labelStyle = T.body(
      size: 9.5,
      weight: FontWeight.w600,
      color: C.text3,
    );
    for (var g = 1; g <= 3; g++) {
      final y = plotH - plotH * g / 3;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: compactLei(maxY * g / 3), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 5, y - tp.height / 2));
    }
    canvas.drawLine(
      Offset(leftPad, plotH),
      Offset(size.width, plotH),
      gridPaint,
    );

    // Etichete pe ani: start, mijloc, final.
    for (final i in {0, n ~/ 2, n}) {
      final tp = TextPainter(
        text: TextSpan(text: '${i}a', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(point(i, 0).dx - tp.width / 2, plotH + 4));
    }

    Path lineOf(List<double> values) {
      final path = Path()
        ..moveTo(point(0, values[0]).dx, point(0, values[0]).dy);
      for (var i = 1; i <= n; i++) {
        final p = point(i, values[i]);
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    Path trim(Path p) {
      if (drawn >= 1) return p;
      final out = Path();
      for (final m in p.computeMetrics()) {
        out.addPath(m.extractPath(0, m.length * drawn), Offset.zero);
      }
      return out;
    }

    // Salteaua: punctată, mereu sub compusa.
    final flatPath = trim(lineOf(flat));
    final flatPaint = Paint()
      ..color = C.text3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final m in flatPath.computeMetrics()) {
      var d = 0.0;
      while (d + 6 < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), flatPaint);
        d += 12;
      }
    }

    // Compusa: umplere moale sub curbă + linia verde.
    final compPath = trim(lineOf(compound));
    final fill = Path.from(compPath)
      ..lineTo(point(math.max(1, (n * drawn).floor()), 0).dx, plotH)
      ..lineTo(leftPad, plotH)
      ..close();
    canvas.drawPath(fill, Paint()..color = C.green.withValues(alpha: 0.10));
    canvas.drawPath(
      compPath,
      Paint()
        ..color = C.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.drawn != drawn || old.compound != compound || old.flat != flat;
}
