import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/db/app_db.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/daily_challenge.dart';
import '../../../domain/util/day_key.dart';
import '../../gamification/data/gamification_service.dart';
import '../data/arcade_repository.dart';

/// Provocarea Zilei: un singur puzzle pe zi, la fel pentru toți, determinist
/// din dată. Trei formate rotative; la final se afișează cardul de share
/// fără spoilere (mecanica de tip Wordle).
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  final _shareKey = GlobalKey();

  // Stare preț
  int _priceIndex = 0;
  double _slider = 0;
  bool _sliderInit = false;
  bool _locked = false;
  final List<int> _pricePoints = [];

  // Stare mit
  int _mythIndex = 0;
  bool? _mythPick; // alegerea adevăr/fals a userului pentru afirmația curentă
  final List<bool> _mythResults = [];

  // Stare dilemă
  int? _dilemmaPick;

  int? _justRewarded; // ghinde acordate în sesiunea asta (banner recompensă)
  bool _finishing = false;

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  String get _today => dayKey(DateTime.now());

  Future<void> _finish({required int score, required String grid}) async {
    if (_finishing) return;
    _finishing = true;
    final format = formatFor(_today).name;
    final earned = await ref.read(arcadeRepositoryProvider).recordRound(
      game: 'daily',
      score: score,
      meta: {'format': format, 'grid': grid, 'score': score},
    );
    ref.read(analyticsProvider).track(
        AnalyticsEvents.gamePlayed, {'game': 'daily', 'format': format});
    ref.invalidate(questsViewProvider);
    if (mounted) setState(() => _justRewarded = earned);
  }

  Future<void> _share() async {
    Juice.tick();
    final boundary = _shareKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/finedu_provocarea_$_today.png');
    await file.writeAsBytes(data.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)],
        text: 'Provocarea Zilei · FinEdu');
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(dailyContentProvider(_locale)).valueOrNull;
    final round = ref.watch(dailyRoundTodayProvider).valueOrNull;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: content == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                    child: Column(
                      children: [
                        _topBar(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: round != null
                              ? _resultView(round)
                              : _playView(content),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final format = formatFor(_today);
    final title = switch (format) {
      DailyFormat.price => '🎯 Ghicește prețul',
      DailyFormat.myth => '🧠 Mit sau Adevăr',
      DailyFormat.dilemma => '🤔 Dilema',
    };
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
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
            child:
                const SvgIcon(Ic.x, size: 16, color: C.text2, strokeWidth: 2.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provocarea Zilei',
                  style: T.display(
                      size: 18, weight: FontWeight.w800, color: C.text)),
              Text(title,
                  style: T.body(
                      size: 12.5, weight: FontWeight.w600, color: C.text3)),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Joc
  // -------------------------------------------------------------------------

  Widget _playView(DailyContent content) {
    final format = formatFor(_today);
    return switch (format) {
      DailyFormat.price => _pricePlay(
          content.price[puzzleIndexFor(_today, content.price.length)]),
      DailyFormat.myth =>
        _mythPlay(content.myth[puzzleIndexFor(_today, content.myth.length)]),
      DailyFormat.dilemma => _dilemmaPlay(
          content.dilemma[puzzleIndexFor(_today, content.dilemma.length)]),
    };
  }

  Widget _pricePlay(PricePuzzle puzzle) {
    final item = puzzle.items[_priceIndex];
    if (!_sliderInit) {
      _slider = ((item.min + item.max) / 2).roundToDouble();
      _sliderInit = true;
    }
    final last = _priceIndex == puzzle.items.length - 1;
    final points = pricePoints(guess: _slider.round(), actual: item.actual);

    return Column(
      children: [
        _progressDots(puzzle.items.length, _priceIndex, _locked),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(puzzle.title,
                    style: T.display(
                        size: 20, weight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 12),
                ClayCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: T.display(
                              size: 17,
                              weight: FontWeight.w700,
                              color: C.text,
                              height: 1.25)),
                      const SizedBox(height: 12),
                      Center(
                        child: Text('${_slider.round()} lei',
                            style: T.display(
                                size: 32,
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
                          value: _slider,
                          min: item.min.toDouble(),
                          max: item.max.toDouble(),
                          divisions:
                              ((item.max - item.min) / item.step).round(),
                          onChanged: _locked
                              ? null
                              : (v) => setState(() => _slider = v),
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
                      children: [
                        Text(priceEmoji(points),
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              'Prețul real: ${item.actual} lei · +$points puncte',
                              style: T.display(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: C.text)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClayButton(
          label: !_locked
              ? 'Blochează prețul'
              : (last ? 'Vezi rezultatul' : 'Următorul produs'),
          gradient: !_locked ? Grad.amber : Grad.blue,
          shadow: !_locked ? Sh.amber : Sh.blue,
          height: 56,
          fontSize: 16,
          onTap: () async {
            if (!_locked) {
              Juice.tick();
              setState(() {
                _locked = true;
                _pricePoints.add(points);
              });
              return;
            }
            if (last) {
              final score =
                  _pricePoints.fold<int>(0, (a, b) => a + b);
              final grid = _pricePoints.map(priceEmoji).join();
              await _finish(score: score, grid: grid);
            } else {
              setState(() {
                _priceIndex++;
                _locked = false;
                _sliderInit = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _mythPlay(MythPuzzle puzzle) {
    final statement = puzzle.statements[_mythIndex];
    final answered = _mythPick != null;
    final correct = _mythPick == statement.truth;
    final last = _mythIndex == puzzle.statements.length - 1;

    return Column(
      children: [
        _progressDots(puzzle.statements.length, _mythIndex, answered),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClayCard(
                  radius: 22,
                  padding: const EdgeInsets.all(20),
                  child: Text(statement.text,
                      style: T.display(
                          size: 18,
                          weight: FontWeight.w700,
                          color: C.text,
                          height: 1.35)),
                ),
                const SizedBox(height: 14),
                if (!answered)
                  Row(
                    children: [
                      Expanded(
                        child: ClayButton(
                          label: 'MIT',
                          gradient: Grad.danger,
                          shadow: Sh.danger,
                          height: 52,
                          fontSize: 15,
                          onTap: () {
                            if (!statement.truth) Juice.correct();
                            setState(() {
                              _mythPick = false;
                              _mythResults.add(!statement.truth);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClayButton(
                          label: 'ADEVĂR',
                          gradient: Grad.green,
                          shadow: Sh.green,
                          height: 52,
                          fontSize: 15,
                          onTap: () {
                            if (statement.truth) Juice.correct();
                            setState(() {
                              _mythPick = true;
                              _mythResults.add(statement.truth);
                            });
                          },
                        ),
                      ),
                    ],
                  )
                else ...[
                  ClayCard(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(correct ? '🟩' : '🟥',
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  correct
                                      ? 'Corect: e ${statement.truth ? 'adevăr' : 'mit'}!'
                                      : 'De fapt, e ${statement.truth ? 'adevăr' : 'mit'}.',
                                  style: T.display(
                                      size: 15,
                                      weight: FontWeight.w800,
                                      color: C.text)),
                              const SizedBox(height: 4),
                              Text(statement.explain,
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
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClayButton(
          label: last ? 'Vezi rezultatul' : 'Următoarea afirmație',
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 56,
          fontSize: 16,
          onTap: !answered
              ? null
              : () async {
                  if (last) {
                    final correctCount =
                        _mythResults.where((r) => r).length;
                    final grid = _mythResults
                        .map((r) => mythEmoji(correct: r))
                        .join();
                    await _finish(score: mythScore(correctCount), grid: grid);
                  } else {
                    setState(() {
                      _mythIndex++;
                      _mythPick = null;
                    });
                  }
                },
        ),
      ],
    );
  }

  Widget _dilemmaPlay(DilemmaPuzzle puzzle) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nu există răspuns greșit, doar consecințe.',
                    style: T.body(
                        size: 12.5, weight: FontWeight.w600, color: C.text3)),
                const SizedBox(height: 10),
                ClayCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Text(puzzle.scenario,
                      style: T.display(
                          size: 17,
                          weight: FontWeight.w700,
                          color: C.text,
                          height: 1.35)),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < puzzle.options.length; i++) ...[
                  GestureDetector(
                    onTap: () {
                      if (_dilemmaPick != i) Juice.tick();
                      setState(() => _dilemmaPick = i);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _dilemmaPick == i ? C.blueSoft : C.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _dilemmaPick == i
                                ? C.blue
                                : Colors.transparent,
                            width: 2),
                        boxShadow: _dilemmaPick == null ? Sh.raise : null,
                      ),
                      child: Opacity(
                        opacity: _dilemmaPick == null || _dilemmaPick == i
                            ? 1
                            : 0.55,
                        child: Text(puzzle.options[i].text,
                            style: T.body(
                                size: 14.5,
                                weight: FontWeight.w600,
                                color: C.text,
                                height: 1.3)),
                      ),
                    ),
                  ),
                ],
                if (_dilemmaPick != null) ...[
                  const SizedBox(height: 4),
                  ClayCard(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(Cashy.cashyPoint, width: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              puzzle.options[_dilemmaPick!].comment,
                              style: T.body(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: C.text2,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClayButton(
          label: 'Încheie provocarea',
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 56,
          fontSize: 16,
          onTap: _dilemmaPick == null
              ? null
              : () {
                  Juice.tick();
                  _finish(score: 100, grid: '💭✅');
                },
        ),
      ],
    );
  }

  Widget _progressDots(int total, int index, bool currentDone) {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: i < index || (i == index && currentDone)
                    ? C.violet
                    : C.line2,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: const [],
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Rezultat + card de share
  // -------------------------------------------------------------------------

  Widget _resultView(ArcadeRound round) {
    final meta = jsonDecode(round.meta) as Map<String, dynamic>;
    final grid = (meta['grid'] as String?) ?? '💭';
    final format = (meta['format'] as String?) ?? 'price';
    final isDilemma = format == 'dilemma';

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_justRewarded != null && _justRewarded! > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: C.amberSoft,
                borderRadius: BorderRadius.circular(R.pill),
                border: Border.all(color: C.line, width: 1),
              ),
              child: AcornText('+$_justRewarded 🌰 · +10 XP',
                  style: T.display(
                      size: 15, weight: FontWeight.w800, color: C.text)),
            ),
            const SizedBox(height: 12),
          ],
          // Cardul de share 9:16, ce se capturează efectiv.
          RepaintBoundary(
            key: _shareKey,
            child: Container(
              width: 290,
              height: 460,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB3A7FF), C.violetDeep],
                ),
                borderRadius: BorderRadius.circular(R.lg),
                boxShadow: Sh.raise,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROVOCAREA ZILEI',
                      style: T.display(
                          size: 13,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 13 * 0.12)),
                  Text(round.date,
                      style: T.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: Colors.white70)),
                  const Spacer(),
                  Center(
                    child: Text(grid,
                        style: const TextStyle(fontSize: 40, height: 1.2)),
                  ),
                  const SizedBox(height: 10),
                  if (!isDilemma)
                    Center(
                      child: Text('${round.score} / 100',
                          style: T.display(
                              size: 34,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    )
                  else
                    Center(
                      child: Text('Dilema, rezolvată',
                          style: T.display(
                              size: 20,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('🐿️ FinEdu',
                          style: T.display(
                              size: 15,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Tu cât faci?',
                          style: T.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Fără spoilere, grila arată doar cât de aproape ai fost.',
              textAlign: TextAlign.center,
              style:
                  T.body(size: 12.5, weight: FontWeight.w500, color: C.text3)),
          const SizedBox(height: 12),
          ClayButton(
            label: 'Trimite provocarea  📤',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 54,
            fontSize: 16,
            onTap: _share,
          ),
          const SizedBox(height: 10),
          Text('Puzzle nou mâine. Aceleași întrebări pentru toată lumea.',
              style:
                  T.body(size: 12.5, weight: FontWeight.w600, color: C.text2)),
        ],
      ),
    );
  }
}
