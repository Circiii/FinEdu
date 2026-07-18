import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/compound.dart';
import '../data/lessons_repository.dart';

/// Rata de inflație a modelului; curba punctată arată puterea de cumpărare, nu soldul.
const _inflationRate = 0.04;

/// Explorabilul dobânzii compuse. Două curbe: „la saltea" (dreaptă) vs. cu
/// dobândă (exponențială), divergența e lecția. Sandbox (AADC): fără scor.
class ParamSimInteractive extends StatefulWidget {
  const ParamSimInteractive({super.key, required this.it});

  final LessonInteractive it;

  @override
  State<ParamSimInteractive> createState() => _ParamSimInteractiveState();
}

class _ParamSimInteractiveState extends State<ParamSimInteractive>
    with SingleTickerProviderStateMixin {
  late final SimConfig cfg = widget.it.sim!;
  late int _years = cfg.yearsDefault;
  late int _monthly = cfg.monthlyDefault;
  late double _rate = cfg.rateDefault;
  bool _showReal = false;
  bool _raceOn = false;
  bool _how = false;
  bool _crossoverCelebrated = false;

  // Pulsul markerului de crossover.
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double get _rateFrac => _rate / 100;

  /// Anul în care dobânda acumulată depășește depunerile (-1 dacă nu se atinge).
  int _crossoverYear(List<double> compound) {
    for (var y = 1; y < compound.length; y++) {
      final deposited = _monthly * 12.0 * y;
      if (compound[y] - deposited > deposited) return y;
    }
    return -1;
  }

  void _maybeCelebrateCrossover(int crossover) {
    if (crossover > 0 && !_crossoverCelebrated) {
      _crossoverCelebrated = true;
      // Prima dată când utilizatorul își găsește crossover-ul, moment major.
      WidgetsBinding.instance.addPostFrameCallback((_) => Juice.major());
    }
  }

  @override
  Widget build(BuildContext context) {
    final compound = compoundSeries(
        monthly: _monthly.toDouble(), annualRate: _rateFrac, years: _years);
    final flat = flatSeries(monthly: _monthly.toDouble(), years: _years);
    final real = _showReal
        ? [
            for (var y = 0; y < compound.length; y++)
              compound[y] / math.pow(1 + _inflationRate, y),
          ]
        : null;

    // Cursa: Ana pune `monthly` din anul 0 (16 ani); Vlad pune DUBLU, dar
    // abia din anul 10 (26 de ani). Aceiași bani depuși în total la 36.
    List<double>? ana;
    List<double>? vlad;
    if (_raceOn) {
      ana = compoundSeries(
          monthly: _monthly.toDouble(), annualRate: _rateFrac, years: 20);
      final vladTail = compoundSeries(
          monthly: _monthly * 2.0, annualRate: _rateFrac, years: 10);
      vlad = [...List.filled(10, 0.0), ...vladTail];
    }

    final crossover = _raceOn ? -1 : _crossoverYear(compound);
    _maybeCelebrateCrossover(crossover);
    final interest =
        interestEarned(monthly: _monthly.toDouble(), annualRate: _rateFrac, years: _years);
    final doubling = doublingYears(_rateFrac);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('🧮 SIMULATOR',
              style: T.display(
                  size: 12,
                  weight: FontWeight.w700,
                  color: C.text3,
                  letterSpacing: 12 * 0.12)),
          const SizedBox(height: 8),
          Text(widget.it.title ?? '',
              style:
                  T.display(size: 20, weight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 12),

          // Rezultatul cu numărătoare vie, cifra care face sliderele să merite mișcate.
          if (!_raceOn) _headline(compound.last, interest),
          if (_raceOn) _raceHeadline(ana!.last, vlad!.last),
          const SizedBox(height: 12),

          ClayCard(
            radius: R.md,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Column(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => CustomPaint(
                      painter: _CurvesPainter(
                        flat: _raceOn ? null : flat,
                        compound: _raceOn ? null : compound,
                        real: _raceOn ? null : real,
                        ana: ana,
                        vlad: vlad,
                        crossoverYear: crossover,
                        pulse: _pulse.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _legend(),
              ],
            ),
          ),

          if (crossover > 0) ...[
            const SizedBox(height: 10),
            _crossoverBanner(crossover),
          ],
          if (!_raceOn && _rate > 0) ...[
            const SizedBox(height: 10),
            _doublingBadge(doubling),
          ],
          if (_raceOn) ...[
            const SizedBox(height: 10),
            _raceComment(ana!.last, vlad!.last),
          ],

          const SizedBox(height: 14),
          if (cfg.exposed.contains('years'))
            _slider(
              label: 'Ani',
              value: '$_years ${_years == 1 ? "an" : "ani"}',
              child: Slider(
                value: _years.toDouble(),
                min: 1,
                max: cfg.yearsMax.toDouble(),
                divisions: cfg.yearsMax - 1,
                onChanged: (v) => setState(() => _years = v.round()),
                onChangeEnd: (_) => Juice.tick(),
              ),
            ),
          if (cfg.exposed.contains('monthly'))
            _slider(
              label: 'Pui deoparte pe lună',
              value: '$_monthly lei',
              child: Slider(
                value: _monthly.toDouble(),
                min: 0,
                max: 500,
                divisions: 50,
                onChanged: (v) => setState(() => _monthly = v.round()),
                onChangeEnd: (_) => Juice.tick(),
              ),
            ),
          if (cfg.exposed.contains('rate'))
            _slider(
              label: 'Dobânda pe an',
              value: '${_rate.toStringAsFixed(1)}%',
              hint: 'depozitele în RO sunt azi ~4-7%',
              child: Slider(
                value: _rate,
                min: 0,
                max: 8,
                divisions: 16,
                onChanged: (v) => setState(() => _rate = v),
                onChangeEnd: (_) => Juice.tick(),
              ),
            ),

          if (cfg.inflation || cfg.race) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (cfg.inflation && !_raceOn)
                  _toggleChip(
                    on: _showReal,
                    label: '📉 Valoarea reală (inflație ~4%)',
                    onTap: () => setState(() => _showReal = !_showReal),
                  ),
                if (cfg.race)
                  _toggleChip(
                    on: _raceOn,
                    label: '🏁 Cursa: Ana (16) vs Vlad (26)',
                    onTap: () => setState(() => _raceOn = !_raceOn),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          _howWeCompute(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- headline-uri ---------------------------------------------------------

  Widget _headline(double total, double interest) {
    return ClayCard(
      radius: R.md,
      gradient: Grad.green,
      shadow: Sh.green,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCount(
                value: total.round(),
                suffix: ' lei',
                duration: Dur.emph,
                style: T.display(
                    size: 26, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('în $_years ${_years == 1 ? "an" : "ani"}',
                    style: T.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
              interest > 0.5
                  ? 'din care ${compactLei(interest)} lei sunt dobândă, bani '
                      'făcuți de bani, nu de tine'
                  : 'deocamdată doar depunerile tale, mișcă anii!',
              style: T.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92))),
        ],
      ),
    );
  }

  Widget _raceHeadline(double anaTotal, double vladTotal) {
    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ana · de la 16 ani',
                    style: T.body(
                        size: 12, weight: FontWeight.w700, color: C.greenDeep)),
                Text('${compactLei(anaTotal)} lei',
                    style: T.display(
                        size: 20, weight: FontWeight.w800, color: C.text)),
                Text('$_monthly lei/lună · 20 de ani',
                    style: T.body(
                        size: 11, weight: FontWeight.w500, color: C.text3)),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: C.line),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vlad · de la 26 de ani',
                    style: T.body(
                        size: 12, weight: FontWeight.w700, color: C.blueDeep)),
                Text('${compactLei(vladTotal)} lei',
                    style: T.display(
                        size: 20, weight: FontWeight.w800, color: C.text)),
                Text('${_monthly * 2} lei/lună · 10 ani',
                    style: T.body(
                        size: 11, weight: FontWeight.w500, color: C.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _raceComment(double anaTotal, double vladTotal) {
    final diff = (anaTotal - vladTotal).abs();
    return _banner(
        '⏱️',
        'Au depus AMÂNDOI aceiași bani. Diferența de ${compactLei(diff)} lei '
            'n-a făcut-o suma, a făcut-o timpul. Vlad nu e pierzător; doar '
            'urcă un deal mai abrupt.');
  }

  Widget _crossoverBanner(int year) {
    return _banner(
        '🎉',
        'În anul $year, dobânda ta a depășit tot ce ai depus. De aici, banii '
            'tăi muncesc mai tare decât tine.');
  }

  Widget _doublingBadge(double years) {
    return _banner(
        '💡',
        'Regula lui 72: la ${_rate.toStringAsFixed(1)}% pe an, banii se '
            'dublează în ~${years.isFinite ? years.toStringAsFixed(0) : "∞"} ani.');
  }

  Widget _banner(String emoji, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: C.amberSoft,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: T.body(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: C.text,
                    height: 1.35)),
          ),
        ],
      ),
    );
  }

  // ---- controale -------------------------------------------------------------

  Widget _slider({
    required String label,
    required String value,
    required Widget child,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: T.body(
                    size: 13, weight: FontWeight.w700, color: C.text2)),
            const Spacer(),
            Text(value,
                style: T.display(
                    size: 14, weight: FontWeight.w800, color: C.blueDeep)),
          ],
        ),
        if (hint != null)
          Text(hint,
              style:
                  T.body(size: 11, weight: FontWeight.w500, color: C.text3)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: C.blue,
            inactiveTrackColor: C.inset,
            thumbShape: ClaySliderThumb(),
            overlayShape: SliderComponentShape.noOverlay,
            trackHeight: 8,
          ),
          child: child,
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _toggleChip(
      {required bool on, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? C.blueSoft : C.surface,
          borderRadius: BorderRadius.circular(R.pill),
          border: Border.all(color: on ? C.blue : C.line, width: 1.5),
          boxShadow: on ? null : Sh.raise,
        ),
        child: Text(label,
            style: T.display(
                size: 12.5,
                weight: FontWeight.w800,
                color: on ? C.blueDeep : C.text2)),
      ),
    );
  }

  Widget _legend() {
    Widget dot(Color color, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: dashed ? Colors.transparent : color,
                border: dashed ? Border.all(color: color, width: 1.2) : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(label,
                style:
                    T.body(size: 11, weight: FontWeight.w600, color: C.text3)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: _raceOn
          ? [dot(C.green, 'Ana (de la 16)'), dot(C.blue, 'Vlad (de la 26)')]
          : [
              dot(C.green, 'Cu dobândă'),
              dot(const Color(0xFFB9C6DA), 'La saltea'),
              if (_showReal) dot(C.violet, 'Valoarea reală', dashed: true),
            ],
    );
  }

  Widget _howWeCompute() {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        setState(() => _how = !_how);
      },
      child: ClayCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Cum calculăm?',
                    style: T.display(
                        size: 13.5, weight: FontWeight.w800, color: C.text2)),
                const Spacer(),
                Text(_how ? '▴' : '▾',
                    style: const TextStyle(fontSize: 14, color: C.text3)),
              ],
            ),
            if (_how) ...[
              const SizedBox(height: 8),
              Text(
                  'În fiecare lună, soldul crește cu dobânda lunii '
                  '(dobânda anuală împărțită la 12) și primește depunerea ta:\n'
                  'sold nou = sold × (1 + rată/12) + depunere\n\n'
                  'Curba „reală" împarte soldul la inflația acumulată (~4%/an) '
                  ', cât ai putea CUMPĂRA cu banii, nu câți lei sunt.\n\n'
                  'Model educativ, nu o promisiune: ratele reale variază, iar '
                  'produsele au comisioane și impozite. Lecția e FORMA curbei, '
                  'nu cifra exactă.',
                  style: T.body(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: C.text2,
                      height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Painterul curbelor ----

class _CurvesPainter extends CustomPainter {
  _CurvesPainter({
    required this.flat,
    required this.compound,
    required this.real,
    required this.ana,
    required this.vlad,
    required this.crossoverYear,
    required this.pulse,
  });

  final List<double>? flat;
  final List<double>? compound;
  final List<double>? real;
  final List<double>? ana;
  final List<double>? vlad;
  final int crossoverYear;
  final double pulse; // 0..1

  static const _mattress = Color(0xFFB9C6DA);

  @override
  void paint(Canvas canvas, Size size) {
    final series = [?compound, ?flat, ?ana, ?vlad];
    if (series.isEmpty) return;
    final maxVal = series
        .map((s) => s.reduce(math.max))
        .reduce(math.max)
        .clamp(1.0, double.infinity);
    final ceiling = niceCeiling(maxVal);
    final n = series.map((s) => s.length).reduce(math.max) - 1;
    if (n < 1) return;

    const leftPad = 34.0;
    final plotW = size.width - leftPad;
    final plotH = size.height - 18;

    Offset pt(int i, double v) =>
        Offset(leftPad + plotW * i / n, plotH - plotH * (v / ceiling));

    // Gridul orizontal + etichetele axei Y (0, 1/2, max).
    final grid = Paint()
      ..color = C.line
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = plotH - plotH * frac;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      tp.text = TextSpan(
          text: compactLei(ceiling * frac),
          style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF8FA3BF),
              fontWeight: FontWeight.w600));
      tp.layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 5, y - tp.height / 2));
    }

    void curve(List<double> s, Color color,
        {bool dashed = false, bool fill = false}) {
      final path = Path()..moveTo(pt(0, s[0]).dx, pt(0, s[0]).dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(pt(i, s[i]).dx, pt(i, s[i]).dy);
      }
      if (fill) {
        final f = Path.from(path)
          ..lineTo(pt(s.length - 1, 0).dx, plotH)
          ..lineTo(leftPad, plotH)
          ..close();
        canvas.drawPath(
            f, Paint()..color = color.withValues(alpha: 0.10));
      }
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      if (!dashed) {
        canvas.drawPath(path, paint);
        return;
      }
      // Punctată: segmentăm manual pe metrică.
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 6), paint);
          d += 11;
        }
      }
    }

    if (flat != null) curve(flat!, _mattress);
    if (compound != null) curve(compound!, C.green, fill: true);
    if (real != null) curve(real!, C.violet, dashed: true);
    if (ana != null) curve(ana!, C.green, fill: true);
    if (vlad != null) curve(vlad!, C.blue);

    // Markerul de crossover, pulsând.
    if (crossoverYear > 0 && compound != null) {
      final p = pt(crossoverYear, compound![crossoverYear]);
      canvas.drawCircle(
          p,
          7 + 3 * pulse,
          Paint()..color = C.amber.withValues(alpha: 0.35 - 0.2 * pulse));
      canvas.drawCircle(p, 5, Paint()..color = C.amber);
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_CurvesPainter old) =>
      old.pulse != pulse ||
      old.compound != compound ||
      old.flat != flat ||
      old.real != real ||
      old.ana != ana ||
      old.vlad != vlad ||
      old.crossoverYear != crossoverYear;
}
