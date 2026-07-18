import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/tokens.dart';
import '../data/lessons_repository.dart';
import 'interactives.dart' show feedbackRow;
import 'lesson_blocks.dart' show RichLessonText;

/// Widget-uri de pagină 2.1 (guess, micro-check, scenariu). Același contract
/// ca interactivele, deschid gate-ul prin [onDone].

// ---- Guess, estimare înainte de concept (discrepanța e hook-ul) ----

class GuessSlider extends StatefulWidget {
  const GuessSlider({super.key, required this.guess, required this.onDone});
  final LessonGuess guess;
  final ValueChanged<bool> onDone;

  @override
  State<GuessSlider> createState() => _GuessSliderState();
}

class _GuessSliderState extends State<GuessSlider> {
  late double _value =
      (widget.guess.min + (widget.guess.max - widget.guess.min) / 2)
          .roundToDouble();
  bool _locked = false;

  String get _closeness {
    final g = widget.guess;
    final err = (_value - g.actual).abs() / (g.actual == 0 ? 1 : g.actual);
    if (err <= 0.05) return '🎯 Fix în țintă!';
    if (err <= 0.20) return 'Aproape, ai simțul cifrelor.';
    if (_value < g.actual) return 'E mai mult de-atât. Surpriză…';
    return 'E mai puțin de-atât. Surpriză…';
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guess;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🔮 GHICEȘTE ÎNAINTE',
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: C.amberDeep,
                letterSpacing: 12 * 0.12)),
        const SizedBox(height: 10),
        ClayCard(
          radius: R.md,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.question,
                  style: T.display(
                      size: 16.5,
                      weight: FontWeight.w700,
                      color: C.text,
                      height: 1.3)),
              const SizedBox(height: 10),
              Center(
                child: Text('${_value.round()} ${g.unit}',
                    style: T.display(
                        size: 30,
                        weight: FontWeight.w800,
                        color: _locked ? C.text3 : C.blue)),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: C.blue,
                  inactiveTrackColor: C.inset,
                  thumbColor: C.blue,
                  overlayColor: C.blueSoft,
                  trackHeight: 8,
                ),
                child: Slider(
                  value: _value,
                  min: g.min.toDouble(),
                  max: g.max.toDouble(),
                  divisions: ((g.max - g.min) / g.step).round(),
                  onChanged:
                      _locked ? null : (v) => setState(() => _value = v),
                ),
              ),
              if (!_locked)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Juice.tick();
                      setState(() => _locked = true);
                      widget.onDone(true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: Grad.amber,
                        borderRadius: BorderRadius.circular(R.pill),
                        boxShadow: Sh.amber,
                      ),
                      child: Text('Blochează răspunsul',
                          style: T.display(
                              size: 14,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_locked) ...[
          const SizedBox(height: 12),
          ClayCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(Cashy.cashyPoint, width: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Răspunsul: ${g.actual} ${g.unit}',
                          style: T.display(
                              size: 16,
                              weight: FontWeight.w800,
                              color: C.text)),
                      const SizedBox(height: 4),
                      RichLessonText('$_closeness ${g.reveal}',
                          style: T.body(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: C.text2,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---- Check, micro-alegerea paginii de concept ----

class ConceptCheck extends StatefulWidget {
  const ConceptCheck({super.key, required this.check, required this.onDone});
  final LessonCheck check;
  final ValueChanged<bool> onDone;

  @override
  State<ConceptCheck> createState() => _ConceptCheckState();
}

class _ConceptCheckState extends State<ConceptCheck> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final c = widget.check;
    final answered = _picked != null;
    final feedback = !answered ? null : c.options[_picked!].why;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⚡ PE REPEDE',
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: C.violet,
                letterSpacing: 12 * 0.12)),
        const SizedBox(height: 8),
        Text(c.question,
            style: T.display(
                size: 15.5, weight: FontWeight.w700, color: C.text,
                height: 1.3)),
        const SizedBox(height: 10),
        for (var i = 0; i < c.options.length; i++)
          GestureDetector(
            onTap: answered
                ? null
                : () {
                    if (i == c.correct) Juice.correct();
                    setState(() => _picked = i);
                    widget.onDone(true);
                  },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: answered && i == c.correct
                    ? C.greenSoft
                    : (answered && i == _picked ? C.dangerSoft : C.surface2),
                borderRadius: BorderRadius.circular(R.sm),
                border: Border.all(
                    color: answered && i == c.correct
                        ? C.green
                        : (answered && i == _picked
                            ? C.danger
                            : Colors.transparent),
                    width: 2),
                boxShadow: answered ? null : Sh.raise,
              ),
              child: Text(c.options[i].text,
                  style: T.body(
                      size: 14, weight: FontWeight.w600, color: C.text,
                      height: 1.3)),
            ),
          ),
        if (feedback != null && feedback.isNotEmpty) ...[
          const SizedBox(height: 2),
          feedbackRow(correct: _picked == c.correct, text: feedback),
        ],
      ],
    );
  }
}

// ---- Scenario, „tu ce-ai face?" cu o consecință per opțiune (fără răspuns corect) ----

class ScenarioDecision extends StatefulWidget {
  const ScenarioDecision(
      {super.key, required this.scenario, required this.onDone});
  final LessonScenario scenario;
  final ValueChanged<bool> onDone;

  @override
  State<ScenarioDecision> createState() => _ScenarioDecisionState();
}

class _ScenarioDecisionState extends State<ScenarioDecision> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('🎬 TU CE-AI FACE?',
              style: T.display(
                  size: 12,
                  weight: FontWeight.w800,
                  color: C.amberDeep,
                  letterSpacing: 12 * 0.12)),
          const SizedBox(height: 12),
          ClayCard(
            radius: 22,
            padding: const EdgeInsets.all(18),
            child: RichLessonText(s.setup,
                style: T.body(
                    size: 15.5,
                    weight: FontWeight.w500,
                    color: C.text,
                    height: 1.5)),
          ),
          const SizedBox(height: 12),
          Text(s.question,
              style: T.display(
                  size: 16, weight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 10),
          for (var i = 0; i < s.options.length; i++) ...[
            GestureDetector(
              onTap: () {
                if (_picked != i) Juice.tick();
                setState(() => _picked = i);
                widget.onDone(true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _picked == i ? C.blueSoft : C.surface2,
                  borderRadius: BorderRadius.circular(R.sm),
                  border: Border.all(
                      color: _picked == i ? C.blue : Colors.transparent,
                      width: 2),
                  boxShadow: _picked == null ? Sh.raise : null,
                ),
                child: Opacity(
                  opacity: _picked == null || _picked == i ? 1 : 0.55,
                  child: Text(s.options[i].text,
                      style: T.body(
                          size: 14, weight: FontWeight.w600, color: C.text,
                          height: 1.3)),
                ),
              ),
            ),
          ],
          if (_picked != null) ...[
            const SizedBox(height: 4),
            ClayCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(Cashy.cashyPoint, width: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichLessonText(s.options[_picked!].consequence,
                        style: T.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: C.text2,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Nu există variantă „greșită", atinge-le și pe celelalte.',
                style: T.body(
                    size: 11.5, weight: FontWeight.w500, color: C.text3)),
          ],
        ],
      ),
    );
  }
}
