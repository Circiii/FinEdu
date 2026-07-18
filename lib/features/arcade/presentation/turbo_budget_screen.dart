import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/turbo_rules.dart';
import '../../gamification/data/gamification_service.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/arcade_repository.dart';

/// Turbo Buget: 45 de secunde, o cheltuială care cade pe rând, trei
/// buzunare, nevoie / dorință / economie. Combo-ul răsplătește seriile,
/// 3 vieți termină runda mai devreme.
class TurboBudgetScreen extends ConsumerStatefulWidget {
  const TurboBudgetScreen({super.key});

  @override
  ConsumerState<TurboBudgetScreen> createState() => _TurboBudgetScreenState();
}

enum _Phase { intro, playing, done }

class _TurboBudgetScreenState extends ConsumerState<TurboBudgetScreen> {
  _Phase _phase = _Phase.intro;
  TurboState _state = const TurboState();
  List<TurboItem> _deck = [];
  int _index = 0;
  int _secondsLeft = turboSeconds;
  Timer? _timer;
  final List<TurboItem> _mistakes = [];
  int? _prevBest;
  int _rewarded = 0;
  // Feedback pentru ultimul răspuns (afișat sub card).
  bool? _lastCorrect;
  String? _lastBucketLabel;

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  static const _bucketLabels = {
    'need': 'Nevoie',
    'want': 'Dorință',
    'save': 'Economie',
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(List<TurboItem> items) {
    _prevBest = ref.read(turboBestProvider).valueOrNull;
    setState(() {
      _phase = _Phase.playing;
      _state = const TurboState();
      _deck = [...items]..shuffle(Random());
      _index = 0;
      _secondsLeft = turboSeconds;
      _mistakes.clear();
      _lastCorrect = null;
      _lastBucketLabel = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _end();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  TurboItem get _item => _deck[_index % _deck.length];

  void _answer(String bucket) {
    if (_phase != _Phase.playing) return;
    final item = _item;
    final correct = item.bucket == bucket;
    // Micro (tick, nu light): la ritmul de 45s, orice haptic mai greu obosește.
    if (correct) Juice.tick();
    setState(() {
      _state = applyAnswer(_state, isCorrect: correct);
      _lastCorrect = correct;
      _lastBucketLabel = _bucketLabels[item.bucket];
      if (!correct && _mistakes.length < 4) _mistakes.add(item);
      _index++;
    });
    if (_state.over) _end();
  }

  Future<void> _end() async {
    _timer?.cancel();
    if (_phase != _Phase.playing) return;
    setState(() => _phase = _Phase.done);
    final earned = await ref.read(arcadeRepositoryProvider).recordRound(
      game: 'turbo',
      score: _state.score,
      meta: {'correct': _state.correct, 'answered': _state.answered},
    );
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.gamePlayed, {'game': 'turbo'});
    ref.invalidate(questsViewProvider);
    // Record personal = nivel minor (major e rezervat lecție/cufăr/obiectiv);
    // scorul 0 la prima rundă nu e record, e doar prima rundă.
    if (_state.score > 0 && (_prevBest == null || _state.score > _prevBest!)) {
      Juice.correct();
    }
    if (mounted) setState(() => _rewarded = earned);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(turboItemsProvider(_locale)).valueOrNull;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: items == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                    child: switch (_phase) {
                      _Phase.intro => _intro(items),
                      _Phase.playing => _game(),
                      _Phase.done => _done(items),
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
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
        Text('Turbo Buget ⚡',
            style: T.display(size: 18, weight: FontWeight.w800, color: C.text)),
      ],
    );
  }

  // -------------------------------------------------------------------------

  Widget _intro(List<TurboItem> items) {
    final best = ref.watch(turboBestProvider).valueOrNull;
    return Column(
      children: [
        _topBar(),
        const Spacer(),
        Image.asset(Cashy.cashyPoint, width: 120),
        const SizedBox(height: 14),
        Text('45 de secunde. 3 coșuri.',
            style: T.display(size: 24, weight: FontWeight.w800, color: C.text)),
        const SizedBox(height: 8),
        Text(
            'Sortează fiecare cheltuială: nevoie, dorință sau economie.\nSeriile corecte dau combo. 3 greșeli = stop.',
            textAlign: TextAlign.center,
            style: T.body(
                size: 14, weight: FontWeight.w500, color: C.text2,
                height: 1.45)),
        const SizedBox(height: 14),
        if (best != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(R.pill),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            child: Text('🏆 Recordul tău: $best',
                style: T.display(
                    size: 14, weight: FontWeight.w800, color: C.text)),
          ),
        const Spacer(),
        ClayButton(
          label: 'START',
          gradient: Grad.green,
          shadow: Sh.green,
          height: 58,
          fontSize: 18,
          onTap: () {
            Juice.tick();
            _start(items);
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------

  Widget _game() {
    return Column(
      children: [
        // HUD: timp, scor, vieți.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pill('⏱ $_secondsLeft s',
                accent: _secondsLeft <= 10 ? C.danger : C.text),
            _pill('★ ${_state.score}'),
            Text(
                List.generate(turboLives,
                    (i) => i < _state.lives ? '❤️' : '🖤').join(),
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        if (_state.combo >= 2) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FlameIcon(size: 14),
              const SizedBox(width: 4),
              Text('combo ×${_state.combo} · +${_state.nextPoints} pe corect',
                  style: T.display(
                      size: 13, weight: FontWeight.w800, color: C.amberDeep)),
            ],
          ),
        ],
        const Spacer(),
        // Cardul care cade.
        ClayCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Text(_item.label,
                    textAlign: TextAlign.center,
                    style: T.display(
                        size: 19,
                        weight: FontWeight.w800,
                        color: C.text,
                        height: 1.25)),
                const SizedBox(height: 8),
                Text('${_item.price} lei',
                    style: T.display(
                        size: 15, weight: FontWeight.w700, color: C.text3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 22,
          child: _lastCorrect == null
              ? null
              : Text(
                  _lastCorrect!
                      ? '✓ corect'
                      : '✗ era „${_lastBucketLabel ?? ''}"',
                  style: T.display(
                      size: 14,
                      weight: FontWeight.w800,
                      color: _lastCorrect! ? C.green : C.danger)),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
                child: _bucket('Nevoie', Grad.blue, Sh.blue,
                    onTap: () => _answer('need'))),
            const SizedBox(width: 10),
            Expanded(
                child: _bucket(
                    'Dorință',
                    const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFB3A7FF), C.violetDeep]),
                    Sh.raise,
                    onTap: () => _answer('want'))),
            const SizedBox(width: 10),
            Expanded(
                child: _bucket('Economie', Grad.green, Sh.green,
                    onTap: () => _answer('save'))),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, {Color accent = C.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: C.line, width: 1),
        boxShadow: Sh.raise,
      ),
      child: Text(text,
          style: T.display(size: 14, weight: FontWeight.w800, color: accent)),
    );
  }

  Widget _bucket(String label, LinearGradient gradient, List<BoxShadow> shadow,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(R.pill),
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: T.display(
                size: 14.5, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _done(List<TurboItem> items) {
    final isRecord = _prevBest == null || _state.score > _prevBest!;
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 14),
                CashySprite(
                    asset: isRecord ? Cashy.cashyCelebrate : Cashy.cashyStudy,
                    width: 130),
                const SizedBox(height: 8),
                Text(isRecord ? 'RECORD NOU! 🎉' : 'Rundă încheiată',
                    style: T.display(
                        size: 24, weight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 6),
                Text('${_state.score} puncte',
                    style: T.display(
                        size: 34, weight: FontWeight.w800, color: C.blue)),
                Text(
                    '${_state.correct} din ${_state.answered} sortate corect'
                    '${_prevBest != null && !isRecord ? ' · record: $_prevBest' : ''}',
                    style: T.body(
                        size: 13.5, weight: FontWeight.w600, color: C.text2)),
                if (_rewarded > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: C.amberSoft,
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(color: C.line, width: 1),
                    ),
                    child: AcornText('+$_rewarded 🌰 · +10 XP',
                        style: T.display(
                            size: 15, weight: FontWeight.w800, color: C.text)),
                  ),
                ],
                if (_mistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('DE DISCUTAT CU TINE ÎNSUȚI',
                        style: T.display(
                            size: 11,
                            weight: FontWeight.w800,
                            color: C.text3,
                            letterSpacing: 11 * 0.12)),
                  ),
                  const SizedBox(height: 8),
                  for (final m in _mistakes)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: C.surface,
                        borderRadius: BorderRadius.circular(R.sm),
                        border: Border.all(color: C.line, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${m.label} → ${_bucketLabels[m.bucket]}',
                              style: T.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: C.text)),
                          if (m.note != null) ...[
                            const SizedBox(height: 3),
                            Text(m.note!,
                                style: T.body(
                                    size: 12.5,
                                    weight: FontWeight.w500,
                                    color: C.text2,
                                    height: 1.35)),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ClayButton(
          label: 'Joacă din nou',
          gradient: Grad.green,
          shadow: Sh.green,
          height: 56,
          fontSize: 16,
          onTap: () {
            Juice.tick();
            _start(items);
          },
        ),
      ],
    );
  }
}
