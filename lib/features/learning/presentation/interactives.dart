import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../data/lessons_repository.dart';
import 'lesson_blocks.dart' show RichLessonText;
import 'param_sim.dart';

/// Un widget per tip de interactiv. Raportează gate-ul de avansare prin [onDone];
/// tipurile cu răspuns corect raportează și prima încercare prin [onResult].
Widget buildInteractive(
  LessonInteractive it, {
  required ValueChanged<bool> onDone,
  ValueChanged<bool>? onResult,
}) {
  return switch (it.kind) {
    'checklist' => ChecklistInteractive(it: it, onDone: onDone),
    'swipe' => SwipeInteractive(it: it, onDone: onDone, onResult: onResult),
    'poll' => PollInteractive(it: it, onDone: onDone),
    'cloze' => ClozeInteractive(it: it, onDone: onDone, onResult: onResult),
    'order' => OrderInteractive(it: it, onDone: onDone, onResult: onResult),
    'pairs' => PairsInteractive(it: it, onDone: onDone, onResult: onResult),
    'reveal' => RevealInteractive(it: it, onDone: onDone),
    'param_sim' => ParamSimInteractive(it: it),
    _ => McqInteractive(it: it, onDone: onDone, onResult: onResult),
  };
}

/// Tipuri cu gate deschis din start (fără răspuns obligatoriu). `param_sim`
/// e sandbox (AADC): explorezi cât vrei, nimic nu te ține pe loc.
bool interactiveGatesAdvance(String kind) =>
    kind != 'checklist' && kind != 'param_sim';

/// Tipurile pe care recap-ul le poate reîntreba după o primă încercare greșită.
bool interactiveRetryable(String kind) => kind == 'mcq' || kind == 'cloze';

Widget _label([String text = '🎮 MINI-JOC']) => Text(
  text,
  style: T.display(
    size: 12,
    weight: FontWeight.w800,
    color: C.violet,
    letterSpacing: 12 * 0.12,
  ),
);

/// Rândul de feedback după răspuns (vocea lui Cashy vine din `why`/`explain`
/// din conținut, nu din cod).
Widget feedbackRow({required bool correct, required String text}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SvgIcon(
        correct ? Ic.check : Ic.alert,
        size: 17,
        color: correct ? C.green : C.amberDeep,
        strokeWidth: 2.6,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: RichLessonText(
          text,
          style: T.body(
            size: 13.5,
            weight: FontWeight.w600,
            color: C.text2,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

// ---- MCQ (2.1: `why` per opțiune la reveal)

class McqInteractive extends StatefulWidget {
  const McqInteractive({
    super.key,
    required this.it,
    required this.onDone,
    this.onResult,
    this.compact = false,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;
  final ValueChanged<bool>? onResult;

  /// Formă compactă pentru retry pe recap (fără eticheta MINI-JOC).
  final bool compact;

  @override
  State<McqInteractive> createState() => _McqInteractiveState();
}

class _McqInteractiveState extends State<McqInteractive> {
  int? _picked;
  int _wrongShakes = 0;

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final answered = _picked != null;
    final feedback = !answered
        ? null
        : (_picked == it.correct
              ? (it.explain ?? '')
              : (it.options[_picked!].why ?? it.explain ?? ''));

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          const SizedBox(height: 8),
          _label(),
          const SizedBox(height: 10),
        ],
        ClayCard(
          radius: R.md,
          padding: const EdgeInsets.all(16),
          child: Text(
            it.question ?? '',
            style: T.display(
              size: widget.compact ? 15.5 : 17.5,
              weight: FontWeight.w700,
              color: C.text,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        JuiceShake(
          trigger: _wrongShakes,
          child: Column(
            children: [
              for (var i = 0; i < it.options.length; i++)
                GestureDetector(
                  onTap: answered
                      ? null
                      : () {
                          final correct = i == it.correct;
                          setState(() {
                            _picked = i;
                            if (!correct) _wrongShakes++;
                          });
                          if (correct) Juice.correct();
                          widget.onDone(true);
                          widget.onResult?.call(correct);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: answered && i == it.correct
                          ? C.greenSoft
                          : (answered && i == _picked
                                ? C.dangerSoft
                                : C.surface2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: answered && i == it.correct
                            ? C.green
                            : (answered && i == _picked
                                  ? C.danger
                                  : Colors.transparent),
                        width: 2,
                      ),
                      boxShadow: answered ? null : Sh.raise,
                    ),
                    child: Text(
                      it.options[i].text,
                      style: T.body(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: C.text,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (feedback != null && feedback.isNotEmpty) ...[
          const SizedBox(height: 4),
          feedbackRow(correct: _picked == it.correct, text: feedback),
        ],
      ],
    );
    return widget.compact ? column : SingleChildScrollView(child: column);
  }
}

// ---- Checklist

class ChecklistInteractive extends StatefulWidget {
  const ChecklistInteractive({
    super.key,
    required this.it,
    required this.onDone,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;

  @override
  State<ChecklistInteractive> createState() => _ChecklistInteractiveState();
}

class _ChecklistInteractiveState extends State<ChecklistInteractive> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _label(),
          const SizedBox(height: 8),
          Text(
            it.title ?? '',
            style: T.display(size: 20, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < it.items.length; i++) ...[
            GestureDetector(
              onTap: () {
                Juice.tick();
                setState(
                  () => _checked.contains(i)
                      ? _checked.remove(i)
                      : _checked.add(i),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _checked.contains(i) ? C.greenSoft : C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _checked.contains(i) ? C.green : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: Sh.raise,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _checked.contains(i) ? C.green : C.inset,
                      ),
                      alignment: Alignment.center,
                      child: _checked.contains(i)
                          ? const SvgIcon(
                              Ic.check,
                              size: 13,
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it.items[i],
                        style: T.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: C.text,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Swipe, sortator cu 6-8 carduri, două găleți. Cardul ratat revine la
// finalul cozii: retry-ul E mecanica, deci swipe nu are recap re-ask.

class SwipeInteractive extends StatefulWidget {
  const SwipeInteractive({
    super.key,
    required this.it,
    required this.onDone,
    this.onResult,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;
  final ValueChanged<bool>? onResult;

  @override
  State<SwipeInteractive> createState() => _SwipeInteractiveState();
}

class _SwipeInteractiveState extends State<SwipeInteractive> {
  late final List<SwipeCard> _queue = [...widget.it.cards];
  late final int _total = widget.it.cards.length;
  int _done = 0;
  bool _missedAny = false;
  double _drag = 0;
  // Feedback-ul ultimului răspuns (why + corectitudine), sub stivă.
  String? _feedback;
  bool _feedbackCorrect = true;

  void _answer({required bool choseLeft}) {
    final card = _queue.first;
    final correct = card.isLeft == choseLeft;
    if (correct) Juice.tick(); // micro: gestul de swipe; greșeala tace
    setState(() {
      _drag = 0;
      _queue.removeAt(0);
      _feedback = card.why;
      _feedbackCorrect = correct;
      if (correct) {
        _done++;
      } else {
        _missedAny = true;
        _queue.add(card); // retry la finalul cozii
      }
    });
    if (_queue.isEmpty) {
      widget.onDone(true);
      widget.onResult?.call(!_missedAny);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final finished = _queue.isEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(),
              Text(
                '$_done / $_total',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: C.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            it.title ?? '',
            style: T.display(size: 20, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 14),
          if (finished)
            ClayCard(
              radius: R.md,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Image.asset(Cashy.cashyCelebrate, width: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _missedAny
                          ? 'Gata! Cele ratate au revenit până le-ai prins.'
                          : 'Toate din prima. Semințele mele sunt mândre.',
                      style: T.body(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: C.text,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Stiva de carduri: cel de sus urmează drag-ul cu o ușoară înclinare.
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_queue.length > 1)
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: Transform.scale(
                        scale: 0.94,
                        child: _card(_queue[1].text, faded: true),
                      ),
                    ),
                  GestureDetector(
                    onPanUpdate: (d) => setState(() => _drag += d.delta.dx),
                    onPanEnd: (_) {
                      if (_drag < -80) {
                        _answer(choseLeft: true);
                      } else if (_drag > 80) {
                        _answer(choseLeft: false);
                      } else {
                        setState(() => _drag = 0);
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(_drag, 0),
                      child: Transform.rotate(
                        angle: _drag / 1200,
                        child: _card(_queue.first.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _bucketButton(
                    it.left ?? '',
                    gradient: Grad.amber,
                    shadow: Sh.amber,
                    onTap: () => _answer(choseLeft: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _bucketButton(
                    it.right ?? '',
                    gradient: Grad.blue,
                    shadow: Sh.blue,
                    onTap: () => _answer(choseLeft: false),
                  ),
                ),
              ],
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            feedbackRow(correct: _feedbackCorrect, text: _feedback!),
          ],
        ],
      ),
    );
  }

  Widget _card(String text, {bool faded = false}) {
    return Opacity(
      opacity: faded ? 0.45 : 1,
      child: ClayCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: T.display(
              size: 17,
              weight: FontWeight.w700,
              color: C.text,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bucketButton(
    String label, {
    required LinearGradient gradient,
    required List<BoxShadow> shadow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(R.pill),
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: T.display(
            size: 14,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Poll, dilemă fără răspuns corect unic. Reveal-ul e comentariul lui Cashy
// pe alegerea ta (fără procente fabricate, AADC). Re-alegerea e permisă.

class PollInteractive extends StatefulWidget {
  const PollInteractive({super.key, required this.it, required this.onDone});
  final LessonInteractive it;
  final ValueChanged<bool> onDone;

  @override
  State<PollInteractive> createState() => _PollInteractiveState();
}

class _PollInteractiveState extends State<PollInteractive> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _label('🤔 DILEMĂ, NU EXISTĂ GREȘIT'),
          const SizedBox(height: 10),
          ClayCard(
            radius: R.md,
            padding: const EdgeInsets.all(16),
            child: Text(
              it.question ?? '',
              style: T.display(
                size: 17,
                weight: FontWeight.w700,
                color: C.text,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < it.pollOptions.length; i++) ...[
            GestureDetector(
              onTap: () {
                if (_picked != i) Juice.tick();
                setState(() => _picked = i);
                widget.onDone(true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _picked == i ? C.blueSoft : C.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _picked == i ? C.blue : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: _picked == null ? Sh.raise : null,
                ),
                child: Opacity(
                  opacity: _picked == null || _picked == i ? 1 : 0.5,
                  child: Text(
                    it.pollOptions[i].text,
                    style: T.body(
                      size: 14.5,
                      weight: FontWeight.w600,
                      color: C.text,
                      height: 1.3,
                    ),
                  ),
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
                    child: RichLessonText(
                      it.pollOptions[_picked!].comment,
                      style: T.body(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: C.text2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Poți atinge și celelalte variante, fiecare are urmarea ei.',
              style: T.body(
                size: 11.5,
                weight: FontWeight.w500,
                color: C.text3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Cloze, propoziția cheie cu un gol + chipuri; distractorii sunt neînțelegeri reale.

class ClozeInteractive extends StatefulWidget {
  const ClozeInteractive({
    super.key,
    required this.it,
    required this.onDone,
    this.onResult,
    this.compact = false,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;
  final ValueChanged<bool>? onResult;
  final bool compact;

  @override
  State<ClozeInteractive> createState() => _ClozeInteractiveState();
}

class _ClozeInteractiveState extends State<ClozeInteractive> {
  final Set<int> _wrongTaps = {};
  bool _solved = false;
  bool _reported = false;

  void _tap(int i) {
    if (_solved) return;
    final correct = i == widget.it.correct;
    if (!_reported) {
      _reported = true;
      widget.onResult?.call(correct);
    }
    if (correct) Juice.correct();
    setState(() {
      if (correct) {
        _solved = true;
      } else {
        _wrongTaps.add(i);
      }
    });
    if (correct) widget.onDone(true);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final parts = (it.question ?? '___').split('___');
    final before = parts.first;
    final after = parts.length > 1 ? parts.sublist(1).join('___') : '';

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          const SizedBox(height: 8),
          _label('🧩 COMPLETEAZĂ'),
          const SizedBox(height: 10),
        ],
        JuiceShake(
          trigger: _wrongTaps.length,
          child: ClayCard(
            radius: R.md,
            padding: const EdgeInsets.all(16),
            child: Text.rich(
              TextSpan(
                style: T.display(
                  size: 17,
                  weight: FontWeight.w700,
                  color: C.text,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: before),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _solved ? C.greenSoft : C.inset,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _solved ? C.green : C.line,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _solved ? it.chips[it.correct] : '···',
                        style: T.display(
                          size: 15.5,
                          weight: FontWeight.w800,
                          color: _solved ? C.greenDeep : C.text3,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: after),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < it.chips.length; i++)
              GestureDetector(
                onTap: _wrongTaps.contains(i) ? null : () => _tap(i),
                child: Opacity(
                  opacity:
                      _wrongTaps.contains(i) || (_solved && i != it.correct)
                      ? 0.4
                      : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _solved && i == it.correct
                          ? C.greenSoft
                          : (_wrongTaps.contains(i) ? C.dangerSoft : C.surface),
                      borderRadius: BorderRadius.circular(R.sm),
                      border: Border.all(
                        color: _solved && i == it.correct
                            ? C.green
                            : (_wrongTaps.contains(i) ? C.danger : C.line),
                        width: 1.5,
                      ),
                      boxShadow: _solved || _wrongTaps.contains(i)
                          ? null
                          : Sh.raise,
                    ),
                    child: Text(
                      it.chips[i],
                      style: T.display(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: C.text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_solved)
          feedbackRow(correct: _wrongTaps.isEmpty, text: it.explain ?? '')
        else if (_wrongTaps.isNotEmpty)
          feedbackRow(
            correct: false,
            text: 'Aha, capcană clasică, fix asta cred mulți. Mai încearcă.',
          ),
      ],
    );
    return widget.compact ? column : SingleChildScrollView(child: column);
  }
}

/// Amestecă indicii 0..n-1 evitând să pice fix ordinea inițială (care la
/// order/pairs ar da răspunsul mură-n gură).
List<int> _shuffledIndices(int n) {
  final rng = math.Random();
  final idx = [for (var i = 0; i < n; i++) i];
  do {
    idx.shuffle(rng);
  } while (n > 2 && _isSorted(idx));
  return idx;
}

bool _isSorted(List<int> idx) {
  for (var i = 1; i < idx.length; i++) {
    if (idx[i] < idx[i - 1]) return false;
  }
  return true;
}

// Order, pașii amestecați; îi atingi în ordinea corectă. Greșeala scutură
// și rămâne pe loc (retry-ul e mecanica), succesul mută pasul sus în listă.

class OrderInteractive extends StatefulWidget {
  const OrderInteractive({
    super.key,
    required this.it,
    required this.onDone,
    this.onResult,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;
  final ValueChanged<bool>? onResult;

  @override
  State<OrderInteractive> createState() => _OrderInteractiveState();
}

class _OrderInteractiveState extends State<OrderInteractive> {
  late final List<int> _display = _shuffledIndices(widget.it.options.length);

  /// Câți pași din secvența corectă au fost deja plasați.
  int _placed = 0;
  bool _missedAny = false;
  int _shakes = 0;

  void _tap(int optionIndex) {
    if (optionIndex < _placed) return;
    if (optionIndex == _placed) {
      Juice.correct();
      setState(() => _placed++);
      if (_placed == widget.it.options.length) {
        widget.onDone(true);
        widget.onResult?.call(!_missedAny);
      }
    } else {
      setState(() {
        _missedAny = true;
        _shakes++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final total = it.options.length;
    final finished = _placed == total;
    // Sus: pașii deja plasați, în ordine; jos: restul, în ordinea amestecată.
    final pending = [
      for (final i in _display)
        if (i >= _placed) i,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('🔢 PUNE ÎN ORDINE'),
              Text(
                '$_placed / $total',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: C.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            it.title ?? '',
            style: T.display(size: 20, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Atinge pașii în ordinea corectă.',
            style: T.body(size: 12.5, weight: FontWeight.w500, color: C.text3),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _placed; i++)
            // Cheia ține StaggerIn stabil per pas: doar pasul proaspăt
            // plasat primește animația de intrare.
            StaggerIn(
              key: ValueKey('placed$i'),
              child: _stepTile(i, placed: true),
            ),
          if (!finished)
            JuiceShake(
              trigger: _shakes,
              child: Column(children: [for (final i in pending) _stepTile(i)]),
            ),
          if (finished) ...[
            const SizedBox(height: 6),
            feedbackRow(
              correct: !_missedAny,
              text: _missedAny
                  ? 'Ordinea contează, acum o știi pe cea corectă.'
                  : it.options.last.why ?? 'Fix așa, pas cu pas.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(int index, {bool placed = false}) {
    return GestureDetector(
      onTap: placed ? null : () => _tap(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: placed ? C.greenSoft : C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: placed ? C.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: placed ? null : Sh.raise,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: placed ? C.green : C.inset,
              ),
              alignment: Alignment.center,
              child: placed
                  ? Text(
                      '${index + 1}',
                      style: T.display(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : const SvgIcon(
                      Ic.chevronRight,
                      size: 13,
                      color: C.text3,
                      strokeWidth: 2.6,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.it.options[index].text,
                style: T.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: C.text,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pairs, potrivire stânga-dreapta stil Duolingo: alegi din stânga, apoi
// perechea din dreapta; potrivirea blochează perechea în verde.

class PairsInteractive extends StatefulWidget {
  const PairsInteractive({
    super.key,
    required this.it,
    required this.onDone,
    this.onResult,
  });
  final LessonInteractive it;
  final ValueChanged<bool> onDone;
  final ValueChanged<bool>? onResult;

  @override
  State<PairsInteractive> createState() => _PairsInteractiveState();
}

class _PairsInteractiveState extends State<PairsInteractive> {
  late final List<int> _rightOrder = _shuffledIndices(widget.it.pairs.length);
  final Set<int> _matched = {};
  int? _selectedLeft;
  bool _missedAny = false;
  int _shakes = 0;

  void _tapLeft(int i) {
    if (_matched.contains(i)) return;
    Juice.tick();
    setState(() => _selectedLeft = i);
  }

  void _tapRight(int i) {
    if (_matched.contains(i) || _selectedLeft == null) return;
    if (i == _selectedLeft) {
      Juice.correct();
      setState(() {
        _matched.add(i);
        _selectedLeft = null;
      });
      if (_matched.length == widget.it.pairs.length) {
        widget.onDone(true);
        widget.onResult?.call(!_missedAny);
      }
    } else {
      setState(() {
        _missedAny = true;
        _shakes++;
        _selectedLeft = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final finished = _matched.length == it.pairs.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('🧲 POTRIVEȘTE'),
              Text(
                '${_matched.length} / ${it.pairs.length}',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: C.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            it.title ?? '',
            style: T.display(size: 20, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Atinge o carte din stânga, apoi perechea ei din dreapta.',
            style: T.body(size: 12.5, weight: FontWeight.w500, color: C.text3),
          ),
          const SizedBox(height: 14),
          JuiceShake(
            trigger: _shakes,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < it.pairs.length; i++)
                        _pairTile(
                          it.pairs[i].left,
                          matched: _matched.contains(i),
                          selected: _selectedLeft == i,
                          onTap: () => _tapLeft(i),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      for (final i in _rightOrder)
                        _pairTile(
                          it.pairs[i].right,
                          matched: _matched.contains(i),
                          selected: false,
                          onTap: () => _tapRight(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (finished) ...[
            const SizedBox(height: 6),
            feedbackRow(
              correct: !_missedAny,
              text: _missedAny
                  ? 'Toate perechile stau acum la locul lor.'
                  : 'Toate din prima, se leagă, nu-i așa?',
            ),
          ],
        ],
      ),
    );
  }

  Widget _pairTile(
    String text, {
    required bool matched,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: matched ? null : onTap,
      child: JuiceBounce(
        // 0 → 1 exact o dată, la potrivire, pulsul de confirmare.
        trigger: matched ? 1 : 0,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          margin: const EdgeInsets.only(bottom: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: matched ? C.greenSoft : (selected ? C.blueSoft : C.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: matched
                  ? C.green
                  : (selected ? C.blue : Colors.transparent),
              width: 2,
            ),
            boxShadow: matched ? null : Sh.raise,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: T.body(
              size: 13.5,
              weight: FontWeight.w600,
              color: matched ? C.greenDeep : C.text,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

// Reveal, carduri mit → realitate: golul de curiozitate e mecanica.
// Fără corect/greșit; gate-ul se deschide când toate au fost întoarse.

class RevealInteractive extends StatefulWidget {
  const RevealInteractive({super.key, required this.it, required this.onDone});
  final LessonInteractive it;
  final ValueChanged<bool> onDone;

  @override
  State<RevealInteractive> createState() => _RevealInteractiveState();
}

class _RevealInteractiveState extends State<RevealInteractive> {
  final Set<int> _flipped = {};

  void _flip(int i) {
    if (_flipped.contains(i)) return;
    Juice.tick();
    setState(() => _flipped.add(i));
    if (_flipped.length == widget.it.reveals.length) {
      widget.onDone(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.it;
    final finished = _flipped.length == it.reveals.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('🃏 MIT SAU REALITATE?'),
              Text(
                '${_flipped.length} / ${it.reveals.length}',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: C.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            it.title ?? '',
            style: T.display(size: 20, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Atinge fiecare card ca să vezi adevărul din spate.',
            style: T.body(size: 12.5, weight: FontWeight.w500, color: C.text3),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < it.reveals.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FlipCard(
                front: it.reveals[i].front,
                back: it.reveals[i].back,
                flipped: _flipped.contains(i),
                onTap: () => _flip(i),
              ),
            ),
          if (finished)
            feedbackRow(
              correct: true,
              text: 'Acum știi ce e mit și ce e realitate. Mai departe!',
            ),
        ],
      ),
    );
  }
}

/// Card cu întoarcere 3D pe axa Y; la reduce-motion face crossfade simplu.
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.front,
    required this.back,
    required this.flipped,
    required this.onTap,
  });

  final String front;
  final String back;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: onTap,
      child: reduceMotion
          ? (flipped ? _face(back, isBack: true) : _face(front, isBack: false))
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: flipped ? 1 : 0),
              duration: Dur.emph,
              curve: Curves.easeInOutCubic,
              builder: (_, t, _) {
                final showBack = t > 0.5;
                // Fața din spate se pre-oglindește ca textul să iasă drept.
                final angle = t * math.pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle + (showBack ? math.pi : 0)),
                  child: showBack
                      ? _face(back, isBack: true)
                      : _face(front, isBack: false),
                );
              },
            ),
    );
  }

  Widget _face(String text, {required bool isBack}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBack ? C.greenSoft : C.violetSoft,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: isBack ? C.green : C.violet, width: 1.5),
        boxShadow: isBack ? null : Sh.raise,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBack ? '✅ REALITATEA' : '🤔 SE ZICE CĂ…',
            style: T.display(
              size: 11,
              weight: FontWeight.w800,
              color: isBack ? C.greenDeep : C.violetDeep,
              letterSpacing: 11 * 0.1,
            ),
          ),
          const SizedBox(height: 6),
          RichLessonText(
            text,
            style: T.body(
              size: 14,
              weight: FontWeight.w600,
              color: C.text,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
