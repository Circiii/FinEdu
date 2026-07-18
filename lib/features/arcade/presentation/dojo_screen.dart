import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/dojo_elo.dart';
import '../../gamification/data/gamification_service.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/arcade_repository.dart';
import '../data/dojo_repository.dart';

/// Scam Dojo: 60 de mesaje din JSON, servite la p(succes) ≈ 0,75 prin Elo
/// local pe itemi; centuri de dojo pe rating-ul tău. Runda = 5 mesaje →
/// sumar cu progresul centurii.
class DojoScreen extends ConsumerStatefulWidget {
  const DojoScreen({super.key});
  @override
  ConsumerState<DojoScreen> createState() => _DojoScreenState();
}

const _accentColors = {
  'danger': C.danger,
  'amber': C.amber,
  'sky': C.sky,
  'violet': C.violet,
  'green': C.green,
  'blue': C.blue,
};

class _DojoScreenState extends ConsumerState<DojoScreen> {
  List<DojoMessage>? _round;
  int _index = 0;
  String? verdict; // null | 'correct' | 'wrong'
  int streak = 0;
  int points = 0;
  int _roundCorrect = 0;
  bool _summary = false;
  bool _beltUp = false;
  bool _picking = false;

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  DojoMessage get msg => _round![_index];
  bool get correct => verdict == 'correct';

  Future<void> _startRound(List<DojoMessage> all) async {
    if (_picking) return;
    _picking = true;
    final round = await ref.read(dojoRepositoryProvider).pickRound(all);
    if (!mounted) return;
    setState(() {
      _round = round;
      _index = 0;
      verdict = null;
      points = 0;
      streak = 0;
      _roundCorrect = 0;
      _summary = false;
      _beltUp = false;
      _picking = false;
    });
  }

  Future<void> _answer(bool guessScam) async {
    if (verdict != null) return;
    final ok = guessScam == msg.isScam;
    setState(() {
      verdict = ok ? 'correct' : 'wrong';
      if (ok) {
        streak += 1;
        points += 20;
        _roundCorrect += 1;
      } else {
        streak = 0;
      }
    });
    // Elo: ambele rating-uri se mută la fiecare răspuns.
    final result =
        await ref.read(dojoRepositoryProvider).applyAnswer(msg, correct: ok);
    // Un moment = UN nivel de juice: la belt-up, epicul absoarbe minorul
    // (altfel light+heavy s-ar simți ca un bâlbâit, nu ca o centură nouă).
    if (result.beltUp && mounted) {
      setState(() => _beltUp = true);
      Juice.epic();
      ConfettiBurst.show(context);
    } else if (ok) {
      Juice.correct();
    }
  }

  Future<void> _next() async {
    if (_index < _round!.length - 1) {
      setState(() {
        _index++;
        verdict = null;
      });
      return;
    }
    // Rundă terminată: fereastra de recență + economia comună Arcade.
    await ref.read(dojoRepositoryProvider).finishRound();
    await ref
        .read(arcadeRepositoryProvider)
        .recordRound(game: 'dojo', score: points);
    ref.invalidate(questsViewProvider);
    if (mounted) setState(() => _summary = true);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(dojoMessagesProvider(_locale)).valueOrNull;
    if (messages != null && _round == null && !_picking) {
      _startRound(messages);
    }

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: _round == null
                ? const SizedBox()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),
                        _beltBar(),
                        if (_summary)
                          _summaryView(messages!)
                        else ...[
                          _progress(),
                          _messageCard(),
                          if (verdict == null) _question() else _reveal(),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38, height: 38,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.line, width: 1),
                    boxShadow: Sh.raise,
                  ),
                  alignment: Alignment.center,
                  child: const SvgIcon(Ic.chevronLeft, size: 18, color: C.text2, strokeWidth: 2.4),
                ),
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF8794), C.danger, C.dangerDeep], stops: [0, 0.6, 1]),
                  borderRadius: BorderRadius.circular(R.sm),
                  boxShadow: Sh.danger,
                ),
                alignment: Alignment.center,
                child: const SvgIcon(Ic.shield, size: 24, color: Colors.white, strokeWidth: 2),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scam Dojo', style: T.display(size: 23, weight: FontWeight.w800, color: C.text, height: 1.0)),
                  const SizedBox(height: 2),
                  Text('Antrenament anti-țeapă', style: T.body(size: 12, weight: FontWeight.w600, color: C.text2)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: C.amberSoft,
              borderRadius: BorderRadius.circular(R.pill),
              border: Border.all(color: C.line, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SvgIcon(Ic.star, size: 15, color: C.amber, fill: true),
                const SizedBox(width: 5),
                Text(fmtThousands(points), style: T.display(size: 15, weight: FontWeight.w800, color: C.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Centura: emoji + nume + progres live către următoarea.
  Widget _beltBar() {
    final state = ref.watch(dojoStateProvider).valueOrNull;
    if (state == null) return const SizedBox(height: 6);
    final (emoji, name) = state.belt;
    final next = dojoNextBeltAt(state.rating);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClayCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Centura $name',
                style: T.display(size: 13.5, weight: FontWeight.w800, color: C.text)),
            const Spacer(),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.pill),
                child: Container(
                  height: 8,
                  color: C.inset,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: dojoBeltProgress(state.rating).clamp(0.03, 1.0),
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: Grad.danger,
                            borderRadius: BorderRadius.circular(R.pill))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(next == null ? 'MAX' : '${state.rating} / $next',
                style: T.display(size: 11.5, weight: FontWeight.w700, color: C.text3)),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    final pct = (_index + 1) / _round!.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mesajul ${_index + 1} / ${_round!.length}',
                  style: T.display(size: 12.5, weight: FontWeight.w700, color: C.text2)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FlameIcon(size: 13),
                  const SizedBox(width: 4),
                  Text('Serie $streak', style: T.display(size: 12.5, weight: FontWeight.w800, color: C.danger)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 8,
              color: C.inset,
              child: FractionallySizedBox(
                widthFactor: pct,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.blue, C.sky]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard() {
    final accent = _accentColors[msg.accent] ?? C.danger;
    return ClayCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: const SvgIcon(Ic.message, size: 22, color: Colors.white, strokeWidth: 2),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg.from, style: T.display(size: 16, weight: FontWeight.w800, color: C.text)),
                    Text(msg.channel, style: T.body(size: 12, weight: FontWeight.w600, color: C.text3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(color: C.inset, borderRadius: BorderRadius.circular(R.pill)),
                child: Text(msg.tag, style: T.display(size: 11.5, weight: FontWeight.w700, color: C.text2)),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: C.inset, borderRadius: BorderRadius.circular(15)),
            child: Text(msg.text, style: T.body(size: 14.5, weight: FontWeight.w400, color: C.text, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _question() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Column(
            children: [
              Image.asset(Cashy.cashyPoint, width: 92),
              const SizedBox(height: 4),
              Text('Țeapă sau sigur?', style: T.display(size: 22, weight: FontWeight.w800, color: C.text)),
              const SizedBox(height: 2),
              Text('Citește cu atenție. Tu ce zici?', style: T.body(size: 14, weight: FontWeight.w400, color: C.text2)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _answerBtn('Țeapă!', Grad.danger, Sh.danger, Ic.flag, 2.2, () => _answer(true))),
              const SizedBox(width: 12),
              Expanded(child: _answerBtn('E sigur', Grad.green, Sh.green, Ic.check, 2.6, () => _answer(false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBtn(String label, Gradient grad, List<BoxShadow> shadow, String icon, double sw, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(R.md), boxShadow: shadow),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 22, color: Colors.white, strokeWidth: sw),
            const SizedBox(width: 8),
            Text(label, style: T.display(size: 17, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _reveal() {
    final flagColor = msg.isScam ? C.danger : C.green;
    final title = correct
        ? (msg.isScam ? 'Ai prins țeapa!' : 'Corect, e sigur.')
        : (msg.isScam ? 'Te-a păcălit, era țeapă.' : 'De fapt era în regulă.');
    final cashy = correct ? Cashy.cashyCelebrate : Cashy.cashyWorried;
    final last = _index == _round!.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(cashy, width: 82, height: 92, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: correct ? C.green : C.danger,
                        borderRadius: BorderRadius.circular(R.pill),
                        boxShadow: correct ? Sh.green : Sh.danger,
                      ),
                      child: Text(correct ? 'CORECT' : 'GREȘIT',
                          style: T.display(size: 11, weight: FontWeight.w800, color: Colors.white, letterSpacing: 11 * 0.12)),
                    ),
                    const SizedBox(height: 5),
                    Text(title, style: T.display(size: 21, weight: FontWeight.w800, color: C.text, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
          if (_beltUp) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: C.amberSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.line, width: 1),
              ),
              child: Text(
                  '🥋 CENTURĂ NOUĂ! Ești centura ${ref.watch(dojoStateProvider).valueOrNull?.belt.$2 ?? ''}.',
                  style: T.display(size: 13.5, weight: FontWeight.w800, color: C.amberInk)),
            ),
          ],
          const SizedBox(height: 14),
          ClayCard(
            radius: R.md,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.isScam ? 'STEAGURI ROȘII' : 'DE CE E SIGUR',
                    style: T.display(size: 12, weight: FontWeight.w800, color: flagColor, letterSpacing: 12 * 0.1)),
                const SizedBox(height: 12),
                for (var i = 0; i < msg.flags.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: flagColor),
                        alignment: Alignment.center,
                        child: const SvgIcon(Ic.check, size: 12, color: Colors.white, strokeWidth: 3.2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(msg.flags[i], style: T.body(size: 13.5, weight: FontWeight.w400, color: C.text, height: 1.45))),
                    ],
                  ),
                ],
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line, width: 1))),
                  child: Text(msg.explain, style: T.body(size: 13.5, weight: FontWeight.w400, color: C.text2, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClayButton(
            label: last ? 'Încheie runda' : 'Următorul',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 58,
            fontSize: 17,
            trailing: const SvgIcon(Ic.arrowRight, size: 20, color: Colors.white, strokeWidth: 2.6),
            onTap: _next,
          ),
        ],
      ),
    );
  }

  /// Sumarul rundei: scor, progres de centură, joacă din nou.
  Widget _summaryView(List<DojoMessage> all) {
    final state = ref.watch(dojoStateProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(child: CashySprite(
            asset: _roundCorrect >= 4 ? Cashy.cashyCelebrate : Cashy.cashyStudy,
            width: 130)),
        const SizedBox(height: 8),
        Center(
          child: Text('Rundă completă!',
              style: T.display(size: 24, weight: FontWeight.w800, color: C.text)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('$_roundCorrect din ${_round!.length} mesaje judecate corect',
              style: T.body(size: 14, weight: FontWeight.w600, color: C.text2)),
        ),
        if (state != null) ...[
          const SizedBox(height: 16),
          ClayCard(
            radius: R.md,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(state.belt.$1, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Text('Centura ${state.belt.$2}',
                        style: T.display(size: 17, weight: FontWeight.w800, color: C.text)),
                    const Spacer(),
                    Text(
                        dojoNextBeltAt(state.rating) == null
                            ? 'nivel maxim'
                            : 'imunitate ${state.rating}',
                        style: T.body(size: 12.5, weight: FontWeight.w600, color: C.text3)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.pill),
                  child: Container(
                    height: 10,
                    color: C.inset,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: dojoBeltProgress(state.rating).clamp(0.03, 1.0),
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: Grad.danger,
                              borderRadius: BorderRadius.circular(R.pill))),
                    ),
                  ),
                ),
                if (dojoNextBeltAt(state.rating) != null) ...[
                  const SizedBox(height: 6),
                  Text('Următoarea centură la ${dojoNextBeltAt(state.rating)}',
                      style: T.body(size: 12, weight: FontWeight.w600, color: C.text3)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ClayButton(
          label: 'Încă o rundă',
          gradient: Grad.danger,
          shadow: Sh.danger,
          height: 58,
          fontSize: 17,
          onTap: () {
            Juice.tick();
            _startRound(all);
          },
        ),
        const SizedBox(height: 10),
        ClayButton(
          label: 'Înapoi în Poiană',
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 52,
          fontSize: 15,
          onTap: () {
            Juice.tick();
            context.pop();
          },
        ),
      ],
    );
  }
}
