import 'dart:convert';

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/clay.dart';
import '../../../../core/ui/fmt.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import 'onb_shared.dart';

// ---- Mini-quiz de calibrare

class QuizQuestion {
  const QuizQuestion(this.question, this.options, this.correct, this.explain);

  final String question;
  final List<String> options;
  final int correct;
  final String explain;
}

/// Încarcă content/onboarding_quiz.json (după locale: 'ro' | 'en').
final onboardingQuizProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, locale) async {
      final raw = await rootBundle.loadString('content/onboarding_quiz.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return [
        for (final q in json['questions'] as List)
          QuizQuestion(
            (q['question'] as Map)[locale] as String,
            [
              for (final o in q['options'] as List)
                (o as Map)[locale] as String,
            ],
            q['correct'] as int,
            (q['explain'] as Map)[locale] as String,
          ),
      ];
    });

class QuizStep extends ConsumerStatefulWidget {
  const QuizStep({super.key, required this.onDone});

  /// Apelat după panoul de recompensă, cu indecșii răspunsurilor alese.
  final void Function(List<int> answers, int correct) onDone;

  @override
  ConsumerState<QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends ConsumerState<QuizStep> {
  final List<int> _answers = [];
  int _index = 0;
  int? _picked;
  bool _rewardPanel = false;

  int get _correctCount {
    final quiz = ref.read(onboardingQuizProvider(_locale(context))).valueOrNull;
    if (quiz == null) return 0;
    var n = 0;
    for (var i = 0; i < _answers.length; i++) {
      if (_answers[i] == quiz[i].correct) n++;
    }
    return n;
  }

  String _locale(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quiz = ref.watch(onboardingQuizProvider(_locale(context)));

    return quiz.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox(), // asset-ul e bundle-uit; inaccesibil
      data: (questions) {
        if (_rewardPanel) return _reward(l10n);
        final q = questions[_index];
        final answered = _picked != null;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(Cashy.cashyStudy, width: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.onbQuizKicker,
                                style: T.display(
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: C.sky,
                                  letterSpacing: 12 * 0.12,
                                ),
                              ),
                              Text(
                                l10n.onbQuizProgress(
                                  _index + 1,
                                  questions.length,
                                ),
                                style: T.display(
                                  size: 22,
                                  weight: FontWeight.w800,
                                  color: C.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClayCard(
                      radius: 22,
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        q.question,
                        style: T.display(
                          size: 18.5,
                          weight: FontWeight.w700,
                          color: C.text,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < q.options.length; i++) ...[
                      _option(q, i),
                      const SizedBox(height: 10),
                    ],
                    if (answered)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgIcon(
                              _picked == q.correct ? Ic.check : Ic.alert,
                              size: 17,
                              color: _picked == q.correct
                                  ? C.green
                                  : C.amberDeep,
                              strokeWidth: 2.6,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.explain,
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
                  ],
                ),
              ),
            ),
            ClayButton(
              label: l10n.onbQuizContinue,
              gradient: Grad.blue,
              shadow: Sh.blue,
              height: 60,
              fontSize: 18,
              onTap: answered ? _next : null,
            ),
          ],
        );
      },
    );
  }

  Widget _option(QuizQuestion q, int i) {
    final answered = _picked != null;
    final isPicked = _picked == i;
    final isCorrect = i == q.correct;

    Color border = Colors.transparent;
    Color bg = C.surface2;
    if (answered && isCorrect) {
      border = C.green;
      bg = C.greenSoft;
    } else if (answered && isPicked && !isCorrect) {
      border = C.danger;
      bg = C.dangerSoft;
    }

    return GestureDetector(
      onTap: answered
          ? null
          : () {
              if (i == q.correct) Juice.correct();
              setState(() => _picked = i);
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
          boxShadow: answered && (isCorrect || isPicked) ? null : Sh.raise,
        ),
        child: Text(
          q.options[i],
          style: T.body(
            size: 15,
            weight: FontWeight.w600,
            color: C.text,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  void _next() {
    _answers.add(_picked!);
    final total = ref
        .read(onboardingQuizProvider(_locale(context)))
        .valueOrNull!
        .length;
    setState(() {
      _picked = null;
      if (_answers.length >= total) {
        _rewardPanel = true;
      } else {
        _index++;
      }
    });
  }

  Widget _reward(AppLocalizations l10n) {
    final total = ref
        .read(onboardingQuizProvider(_locale(context)))
        .valueOrNull!
        .length;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbHalo(
                accent: C.amber,
                child: Image.asset(
                  Cashy.cashyCelebrate,
                  width: 186,
                  fit: BoxFit.contain,
                ),
              ),
              OnbHeader(
                kicker: l10n.onbQuizDoneKicker,
                title: l10n.onbQuizDoneTitle(_correctCount, total),
                body: l10n.onbQuizDoneBody,
                accent: C.amber,
              ),
            ],
          ),
        ),
        ClayButton(
          label: l10n.onbQuizDoneCta,
          gradient: Grad.amber,
          shadow: Sh.amber,
          height: 60,
          fontSize: 18,
          onTap: () {
            Juice.tick();
            widget.onDone(_answers, _correctCount);
          },
        ),
      ],
    );
  }
}

// ---- Poarta de vârstă (+ panou terminal too-young)

class AgeStep extends StatefulWidget {
  const AgeStep({super.key, required this.onDone});

  final ValueChanged<int> onDone;

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late final FixedExtentScrollController _wheel;
  late final List<int> _years;
  late int _year;
  bool _tooYoung = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    // De la cel mai vechi; acoperă 10-30 ani ca under-14 să fie reprezentabil.
    _years = [for (var y = now - 30; y <= now - 10; y++) y];
    _year = now - 16;
    _wheel = FixedExtentScrollController(initialItem: _years.indexOf(_year));
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_tooYoung) {
      return Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnbHalo(
                  accent: C.violet,
                  child: Image.asset(
                    Cashy.cashyWorried,
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                OnbHeader(
                  kicker: l10n.onbAgeKicker,
                  title: l10n.onbAgeTooYoungTitle,
                  body: l10n.onbAgeTooYoungBody,
                  accent: C.violet,
                ),
              ],
            ),
          ),
          // Panou terminal: fără CTA de continuare. Back e în rândul de sus.
          const SizedBox(height: 60),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbHeader(
                kicker: l10n.onbAgeKicker,
                title: l10n.onbAgeTitle,
                body: l10n.onbAgeBody,
                accent: C.blue,
              ),
              const SizedBox(height: 20),
              Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  color: C.inset,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: Sh.insetSoft,
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: _wheel,
                  itemExtent: 46,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) =>
                      setState(() => _year = _years[i]),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _years.length,
                    builder: (context, i) => Center(
                      child: Text(
                        '${_years[i]}',
                        style: T.display(
                          size: _years[i] == _year ? 26 : 20,
                          weight: FontWeight.w800,
                          color: _years[i] == _year ? C.blue : C.text3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ClayButton(
          label: l10n.onbAgeCta,
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 60,
          fontSize: 18,
          onTap: () {
            final age = DateTime.now().year - _year;
            if (age < 14) {
              setState(() => _tooYoung = true);
            } else {
              Juice.tick();
              widget.onDone(_year);
            }
          },
          trailing: const SvgIcon(
            Ic.arrowRight,
            size: 20,
            color: Colors.white,
            strokeWidth: 2.6,
          ),
        ),
      ],
    );
  }
}

// ---- Email părinte (sub 16 ani)

class ParentStep extends StatefulWidget {
  const ParentStep({super.key, required this.onDone});

  final ValueChanged<String> onDone;

  @override
  State<ParentStep> createState() => _ParentStepState();
}

class _ParentStepState extends State<ParentStep> {
  final _email = TextEditingController();
  String? _error;

  static final _emailRx = RegExp(
    r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                OnbHalo(
                  accent: C.green,
                  size: 180,
                  child: Image.asset(
                    Cashy.cashyPoint,
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ),
                OnbHeader(
                  kicker: l10n.onbParentKicker,
                  title: l10n.onbParentTitle,
                  body: l10n.onbParentBody,
                  accent: C.green,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.onbParentFieldLabel,
                    style: T.display(
                      size: 13,
                      weight: FontWeight.w700,
                      color: C.text2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClayField(
                  controller: _email,
                  hint: l10n.onbParentHint,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _error,
                  onChanged: (_) => setState(() => _error = null),
                ),
              ],
            ),
          ),
        ),
        ClayButton(
          label: l10n.onbParentCta,
          gradient: Grad.green,
          shadow: Sh.green,
          height: 60,
          fontSize: 18,
          onTap: () {
            final email = _email.text.trim();
            if (!_emailRx.hasMatch(email)) {
              setState(() => _error = l10n.onbParentInvalid);
              return;
            }
            Juice.tick();
            widget.onDone(email);
          },
        ),
      ],
    );
  }
}

// ---- Buget lunar

class BudgetStep extends StatefulWidget {
  const BudgetStep({super.key, required this.onDone});

  final ValueChanged<double> onDone;

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  double _value = 800;

  static const _presets = [300, 800, 1500, 3000];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbHeader(
                kicker: l10n.onbBudgetKicker,
                title: l10n.onbBudgetTitle,
                body: l10n.onbBudgetBody,
                accent: C.blue,
              ),
              const SizedBox(height: 22),
              ClayCard(
                radius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.onbBudgetSliderLabel,
                          style: T.display(
                            size: 14,
                            weight: FontWeight.w700,
                            color: C.text2,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              fmtThousands(_value.round()),
                              style: T.display(
                                size: 28,
                                weight: FontWeight.w800,
                                color: C.blue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.onbBudgetUnit,
                              style: T.display(
                                size: 15,
                                weight: FontWeight.w800,
                                color: C.text2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 14,
                        activeTrackColor: C.inset,
                        inactiveTrackColor: C.inset,
                        trackShape: const RoundedRectSliderTrackShape(),
                        thumbShape: ClaySliderThumb(),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        min: 100,
                        max: 5000,
                        value: _value,
                        onChanged: (v) =>
                            setState(() => _value = (v / 50).round() * 50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final p in _presets)
                          GestureDetector(
                            onTap: () {
                              if (_value != p.toDouble()) Juice.tick();
                              setState(() => _value = p.toDouble());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _value == p.toDouble()
                                    ? C.blueSoft
                                    : C.surface2,
                                borderRadius: BorderRadius.circular(R.pill),
                                border: Border.all(
                                  color: _value == p.toDouble()
                                      ? C.blue
                                      : C.line,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                fmtThousands(p),
                                style: T.display(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: _value == p.toDouble()
                                      ? C.blueInk
                                      : C.text2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ClayButton(
          label: l10n.onbBudgetCta,
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 60,
          fontSize: 18,
          onTap: () {
            Juice.tick();
            widget.onDone(_value);
          },
          trailing: const SvgIcon(
            Ic.arrowRight,
            size: 20,
            color: Colors.white,
            strokeWidth: 2.6,
          ),
        ),
      ],
    );
  }
}
