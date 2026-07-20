import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/analytics/events.dart';
import '../../../../core/ui/acorn.dart';
import '../../../../core/ui/clay.dart';
import '../../../../core/ui/acorn_celebration.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../domain/engine/life_sim/life_sim_commentary.dart';
import '../../../../domain/engine/life_sim/life_sim_content.dart';
import '../../../../domain/engine/life_sim/life_sim_debrief.dart';
import '../../../../domain/engine/life_sim/life_sim_scoring.dart';
import '../../../../domain/engine/life_sim/life_sim_state.dart';
import '../../../wardrobe/presentation/cashy_avatar.dart';
import '../data/life_month_repository.dart';
import 'life_month_common.dart';

/// Raportul de la finalul lunii: reflecția întâi, apoi scorul pe 4 dimensiuni,
/// finalul, debrief-ul determinist și, dacă există o rundă same-seed,
/// comparația side-by-side.
class LifeMonthReportScreen extends ConsumerStatefulWidget {
  const LifeMonthReportScreen({super.key, this.runId});
  final String? runId;

  @override
  ConsumerState<LifeMonthReportScreen> createState() =>
      _LifeMonthReportScreenState();
}

enum _Phase { reflect, report }

class _LifeMonthReportScreenState extends ConsumerState<LifeMonthReportScreen> {
  _Phase _phase = _Phase.reflect;
  bool _loadError = false;

  LifeSimContent? _content;
  LifeMonthRun? _run;
  LifeSimScore? _score;
  DebriefModel? _debrief;
  LifeMonthRun? _prev;

  int? _reflectionChoice;
  int _reflectReward = 0;

  /// Confetti-ul de scor mare cade o singură dată, oricâte rebuild-uri urmează.
  bool _celebrated = false;

  /// Povestea animată a lui Cashy, segmentele vin o singură dată din
  /// [narrateReport], determinist; UI-ul doar navighează printre ele.
  List<CashyComment> _narration = const [];
  int _narrationIndex = 0;

  /// Marchează secțiunea de scor, ca „Sari la scor" să poată derula până acolo.
  final _scoreSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  LifeMonthRepository get _repo => ref.read(lifeMonthRepositoryProvider);

  Future<void> _load() async {
    try {
      final content = await ref.read(lifeSimContentProvider.future);
      LifeMonthRun? run;
      if (widget.runId != null) run = await _repo.getRun(widget.runId!);
      run ??= await ref.read(lifeMonthRepositoryProvider).lastCompletedRun();
      if (!mounted) return;
      if (run == null || content.roleById(run.state.roleId) == null) {
        setState(() => _loadError = true);
        return;
      }
      // Run pinuit pe versiunea de conținut de la creare, un debrief construit
      // pe conținut schimbat ar afișa cifre nereconciliabile. Oprim curat.
      if (run.state.contentVersion != content.version) {
        setState(() => _loadError = true);
        return;
      }
      final sc = run.score ?? score(run.state, content);
      final debrief = buildDebrief(run.state, content);
      final prev = await _repo.previousCompletedForSeed(
        run.state.seed,
        exceptId: run.id,
      );
      if (!mounted) return;
      setState(() {
        _content = content;
        _run = run;
        _score = sc;
        _debrief = debrief;
        _narration = narrateReport(
          debrief: debrief,
          s: run!.state,
          seed: run.state.seed,
        );
        _prev = prev;
        // Fără decizii de reflectat → sărim direct la raport.
        if (run.state.decisions.isEmpty) _phase = _Phase.report;
      });
      if (_phase == _Phase.report) _onReportShown();
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  Future<void> _answerReflection(int idx) async {
    setState(() => _reflectionChoice = idx);
    final reward = await _repo.rewardReflection();
    Juice.correct();
    if (!mounted) return;
    setState(() {
      _reflectReward = reward;
      _phase = _Phase.report;
    });
    _onReportShown();
  }

  void _onReportShown() {
    ref.read(analyticsProvider).track(AnalyticsEvents.lifeSimDebriefViewed);
    final total = _score?.total ?? 0;
    if (total >= 70 && !_celebrated) {
      _celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AcornCelebration.show(
          context,
          title: 'Ai dus luna la capăt!',
          subtitle:
              'Scor $total din 100. Uită-te pe raport să vezi unde ai '
              'câștigat și unde te-a costat.',
        );
      });
    }
  }

  Future<void> _replay() async {
    Juice.tick();
    final content = _content!;
    final st = _run!.state;
    final run = await _repo.createRun(
      content: content,
      roleId: st.roleId,
      goalId: st.goalId,
      mode: st.mode,
      seed: st.seed,
    );
    ref.read(analyticsProvider).track(AnalyticsEvents.lifeSimReplayed, {
      'role': st.roleId,
      'mode': st.mode,
    });
    ref.invalidate(activeRunProvider);
    if (!mounted) return;
    context.pushReplacement('/arcade/luna/joc', extra: run.id);
  }

  // --- Povestea lui Cashy

  /// Avansează la segmentul următor. Pe ultimul segment rămâne pe concluzie,
  /// butonul „Vezi scorul" preia de-acolo.
  void _advanceNarration() {
    if (_narration.isEmpty || _narrationIndex >= _narration.length - 1) return;
    final next = _narrationIndex + 1;
    // Concluzia devine vizibilă → moment epic, restul sunt tick-uri obișnuite.
    if (next == _narration.length - 1) {
      Juice.major();
    } else {
      Juice.tick();
    }
    setState(() => _narrationIndex = next);
  }

  /// Sare direct pe concluzie și derulează pagina până la secțiunea de scor.
  void _scrollToScore() {
    if (_narration.isNotEmpty && _narrationIndex < _narration.length - 1) {
      setState(() => _narrationIndex = _narration.length - 1);
    }
    final ctx = _scoreSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: Dur.base, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: _loadError
                ? _error()
                : (_run == null
                      ? const Center(child: CircularProgressIndicator())
                      : (_phase == _Phase.reflect ? _reflect() : _report())),
          ),
        ],
      ),
    );
  }

  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Raportul nu a putut fi încărcat.',
        textAlign: TextAlign.center,
        style: T.body(size: 14, weight: FontWeight.w600, color: C.text2),
      ),
    ),
  );

  // --- Reflecția

  Widget _reflect() {
    final s = _run!.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: CashySprite(asset: Cashy.cashyPoint, width: 96)),
          const SizedBox(height: 16),
          Text(
            'Luna s-a încheiat.',
            style: T.display(size: 15, weight: FontWeight.w700, color: C.text3),
          ),
          const SizedBox(height: 4),
          Text(
            'Care decizie crezi că ți-a schimbat cel mai mult luna?',
            style: T.display(
              size: 22,
              weight: FontWeight.w800,
              color: C.text,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < s.decisions.length; i++) ...[
            _reflectOption(i, s.decisions[i]),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _reflectOption(int idx, DecisionRecord d) {
    final e = _content!.eventById(d.eventId);
    final title = e?.title ?? d.eventId;
    return GestureDetector(
      onTap: _reflectionChoice == null ? () => _answerReflection(idx) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line2, width: 1),
          boxShadow: Sh.raise,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: C.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Z${d.day}',
                style: T.display(
                  size: 12,
                  weight: FontWeight.w800,
                  color: C.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: T.body(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: C.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Raportul

  Widget _report() {
    final sc = _score!;
    final ending = _endingFor(sc.endingId);
    final d = _debrief!;
    final moments = _topMoments();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          lifeMonthTopBar(
            context,
            'Raportul lunii',
            onClose: () => context.go('/arcade'),
          ),
          const SizedBox(height: 10),
          if (_reflectReward > 0) _reflectReceipt(),
          if (_narration.isNotEmpty) ...[
            _cashyNarrationCard(),
            const SizedBox(height: 20),
          ],
          KeyedSubtree(
            key: _scoreSectionKey,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'SCORUL LUNII',
                    style: T.display(
                      size: 11,
                      weight: FontWeight.w800,
                      color: C.text3,
                      letterSpacing: 11 * 0.14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCount(
                    value: sc.total,
                    style: T.display(
                      size: 56,
                      weight: FontWeight.w800,
                      color: C.blue,
                    ),
                    suffix: ' / 100',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          StaggerIn(
            index: 1,
            child: _dimBar('Control financiar', sc.control, 30, C.blue),
          ),
          StaggerIn(
            index: 2,
            child: _dimBar('Reziliență', sc.rezilienta, 30, C.green),
          ),
          StaggerIn(
            index: 3,
            child: _dimBar('Obiective', sc.obiective, 20, C.violet),
          ),
          StaggerIn(
            index: 4,
            child: _dimBar('Echilibru de viață', sc.echilibru, 20, C.amber),
          ),
          const SizedBox(height: 20),
          if (ending != null) _endingCard(ending, sc.total),
          const SizedBox(height: 20),
          if (moments.isNotEmpty) ...[
            _momentsCard(moments),
            const SizedBox(height: 20),
          ],
          if (_prev != null) ...[
            _compareTable(_prev!, _run!),
            const SizedBox(height: 20),
          ],
          _debriefSections(d),
          const SizedBox(height: 22),
          ClayButton(
            label: 'Reia aceeași lună',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB3A7FF), C.violetDeep],
            ),
            shadow: Sh.violet,
            height: 56,
            fontSize: 16,
            onTap: _replay,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Juice.tick();
              context.go('/arcade');
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(R.pill),
                border: Border.all(color: C.line, width: 1),
                boxShadow: Sh.raise,
              ),
              alignment: Alignment.center,
              child: Text(
                'Înapoi în Arcade',
                style: T.display(
                  size: 15,
                  weight: FontWeight.w800,
                  color: C.text2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reflectReceipt() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: C.amberSoft,
      borderRadius: BorderRadius.circular(R.sm),
      border: Border.all(color: C.line, width: 1),
    ),
    child: Row(
      children: [
        const AcornIcon(size: 17),
        const SizedBox(width: 8),
        AcornText(
          '+$_reflectReward 🌰 pentru reflecție',
          style: T.display(
            size: 14,
            weight: FontWeight.w800,
            color: C.amberInk,
          ),
        ),
      ],
    ),
  );

  /// „Cashy îți povestește luna": card mare, tap-to-advance prin segmentele
  /// din [narrateReport].
  Widget _cashyNarrationCard() {
    final segs = _narration;
    final idx = _narrationIndex.clamp(0, segs.length - 1);
    final seg = segs[idx];
    final isLast = idx == segs.length - 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // „Sari la scor" și butonul final au propriile taps, în afara
    // GestureDetector-ului de avansare, imbricarea nu garantează care
    // recognizer câștigă în arena de gesturi.
    return ClayCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'CASHY ÎȚI POVESTEȘTE LUNA',
                  style: T.display(
                    size: 11,
                    weight: FontWeight.w800,
                    color: C.text3,
                    letterSpacing: 11 * 0.12,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _scrollToScore,
                child: Text(
                  'Sari la scor',
                  style: T.display(
                    size: 12,
                    weight: FontWeight.w700,
                    color: C.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _advanceNarration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CashySprite(asset: assetForCashyMood(seg.mood), width: 130),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : Dur.base,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.12, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          seg.line,
                          key: ValueKey(idx),
                          style: T.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: C.text,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < segs.length; i++)
                AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : Dur.fast,
                  width: i == idx ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= idx ? C.blue : C.inset,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
            ],
          ),
          if (isLast) ...[
            const SizedBox(height: 16),
            ClayButton(
              label: 'Vezi scorul',
              gradient: Grad.blue,
              shadow: Sh.blue,
              height: 50,
              fontSize: 15,
              onTap: _scrollToScore,
            ),
          ],
        ],
      ),
    );
  }

  Widget _dimBar(String label, int value, int weight, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: T.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
              ),
              Text(
                '$weight%',
                style: T.body(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: C.text3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: T.display(
                  size: 14,
                  weight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(R.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                end: MediaQuery.of(context).disableAnimations
                    ? value / 100
                    : value / 100,
              ),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : Dur.epic,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: C.inset,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LifeSimEnding? _endingFor(String id) {
    for (final e in _content!.endings) {
      if (e.id == id) return e;
    }
    return _content!.endings.isEmpty ? null : _content!.endings.last;
  }

  Widget _endingCard(LifeSimEnding ending, int total) {
    final celebrate = total >= 70;
    return ClayCard(
      radius: 24,
      gradient: celebrate
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF63A4FF), C.blueDeep],
            )
          : null,
      color: celebrate ? C.blue : C.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINALUL TĂU',
            style: T.display(
              size: 11,
              weight: FontWeight.w800,
              color: celebrate ? Colors.white70 : C.text3,
              letterSpacing: 11 * 0.14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ending.title,
            style: T.display(
              size: 24,
              weight: FontWeight.w800,
              color: celebrate ? Colors.white : C.text,
            ),
          ),
          if (ending.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ending.description,
              style: T.body(
                size: 14,
                weight: FontWeight.w500,
                color: celebrate ? Colors.white : C.text2,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Note de parcurs

  /// Cele mai mari 3 mișcări de bani din deciziile lunii (imediat plus
  /// întârziat), luate din clasamentele deja calculate de debrief.
  List<DebriefDecision> _topMoments() {
    final d = _debrief;
    if (d == null) return const [];
    final seen = <String>{};
    final all = <DebriefDecision>[];
    for (final o in [...d.efficient, ...d.risky]) {
      if (o.net.isZero) continue;
      if (seen.add('${o.day}-${o.eventId}')) all.add(o);
    }
    all.sort((a, b) => b.net.bani.abs().compareTo(a.net.bani.abs()));
    return all.take(3).toList();
  }

  Widget _momentsCard(List<DebriefDecision> moments) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTE DE PARCURS',
            style: T.display(
              size: 11,
              weight: FontWeight.w800,
              color: C.text3,
              letterSpacing: 11 * 0.12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Momentele care ți-au mișcat cei mai mulți bani.',
            style: T.body(size: 12.5, weight: FontWeight.w500, color: C.text2),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < moments.length; i++)
            StaggerIn(index: i, child: _momentRow(moments[i])),
        ],
      ),
    );
  }

  Widget _momentRow(DebriefDecision o) {
    final positive = !o.net.isNegative;
    final color = positive ? C.greenDeep : C.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 26,
            decoration: BoxDecoration(
              color: C.blueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Z${o.day}',
              style: T.display(
                size: 11.5,
                weight: FontWeight.w800,
                color: C.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              o.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.body(size: 13, weight: FontWeight.w700, color: C.text),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            positive ? '+${o.net.lei}' : o.net.lei,
            style: T.display(size: 13, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // --- Comparație same-seed

  Widget _compareTable(LifeMonthRun prev, LifeMonthRun cur) {
    final p = prev.state;
    final c = cur.state;
    final ps = prev.score ?? score(p, _content!);
    final cs = cur.score ?? score(c, _content!);

    // (etichetă, valoare1, valoare2, „mai mare e mai bine")
    final rows = <(String, String, String, bool, num, num)>[
      (
        'Datorie',
        p.totalDebt.lei,
        c.totalDebt.lei,
        false,
        p.totalDebt.bani,
        c.totalDebt.bani,
      ),
      (
        'Fond',
        p.emergencyFund.lei,
        c.emergencyFund.lei,
        true,
        p.emergencyFund.bani,
        c.emergencyFund.bani,
      ),
      (
        'Facturi la timp',
        '${p.paidBillsOnTime}',
        '${c.paidBillsOnTime}',
        true,
        p.paidBillsOnTime,
        c.paidBillsOnTime,
      ),
      (
        'Stres',
        '${p.stats.stress}',
        '${c.stats.stress}',
        false,
        p.stats.stress,
        c.stats.stress,
      ),
      (
        'Sănătate',
        '${p.stats.health}',
        '${c.stats.health}',
        true,
        p.stats.health,
        c.stats.health,
      ),
      (
        'Relații',
        '${p.stats.relationships}',
        '${c.stats.relationships}',
        true,
        p.stats.relationships,
        c.stats.relationships,
      ),
      (
        'Obiectiv',
        p.goalSavings.lei,
        c.goalSavings.lei,
        true,
        p.goalSavings.bani,
        c.goalSavings.bani,
      ),
      ('Scor', '${ps.total}', '${cs.total}', true, ps.total, cs.total),
    ];

    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACEEAȘI LUNĂ, ALTE DECIZII',
            style: T.display(
              size: 11,
              weight: FontWeight.w800,
              color: C.text3,
              letterSpacing: 11 * 0.12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Text(
                  'Runda 1',
                  textAlign: TextAlign.center,
                  style: T.display(
                    size: 12,
                    weight: FontWeight.w800,
                    color: C.text3,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Runda 2',
                  textAlign: TextAlign.center,
                  style: T.display(
                    size: 12,
                    weight: FontWeight.w800,
                    color: C.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in rows) _compareRow(r),
        ],
      ),
    );
  }

  Widget _compareRow((String, String, String, bool, num, num) r) {
    final higherBetter = r.$4;
    final better = higherBetter ? r.$6 > r.$5 : r.$6 < r.$5;
    final worse = higherBetter ? r.$6 < r.$5 : r.$6 > r.$5;
    final color = better ? C.greenDeep : (worse ? C.danger : C.text2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              r.$1,
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text2),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              r.$2,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.display(
                size: 13,
                weight: FontWeight.w700,
                color: C.text3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    r.$3,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.display(
                      size: 13,
                      weight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                if (better || worse)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Text(
                      better ? '↑' : '↓',
                      style: T.display(
                        size: 12,
                        weight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Debrief

  Widget _debriefSections(DebriefModel d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.timeline.isNotEmpty) ...[
          _sectionTitle('Cronologia deciziilor'),
          ClayCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [for (final t in d.timeline) _timelineRow(t.$1, t.$2)],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (d.efficient.isNotEmpty) ...[
          _sectionTitle('Cele mai eficiente alegeri'),
          for (final o in d.efficient) _decisionRow(o, positive: true),
          const SizedBox(height: 16),
        ],
        if (d.risky.isNotEmpty) ...[
          _sectionTitle('Alegeri riscante'),
          for (final o in d.risky) _decisionRow(o, positive: false),
          const SizedBox(height: 16),
        ],
        _sectionTitle('Consecințe și contrafactual'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: C.amberSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SvgIcon(
                Ic.clock,
                size: 18,
                color: C.amberDeep,
                strokeWidth: 2.2,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.counterfactual,
                  style: T.body(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: C.amberInk,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _conceptCard(d.concept),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: T.display(size: 15, weight: FontWeight.w800, color: C.text),
    ),
  );

  Widget _timelineRow(int day, String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: T.display(
              size: 12.5,
              weight: FontWeight.w800,
              color: C.blue,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.body(size: 13, weight: FontWeight.w600, color: C.text),
          ),
        ),
      ],
    ),
  );

  Widget _decisionRow(DebriefDecision o, {required bool positive}) {
    final net = o.net;
    final netStr = net.isNegative ? net.lei : '+${net.lei}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        children: [
          SvgIcon(
            positive ? Ic.check : Ic.alert,
            size: 16,
            color: positive ? C.greenDeep : C.danger,
            strokeWidth: 2.2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Z${o.day} · ${o.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.body(size: 13, weight: FontWeight.w700, color: C.text),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            netStr,
            style: T.display(
              size: 13,
              weight: FontWeight.w800,
              color: positive ? C.greenDeep : C.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conceptCard(DebriefConcept concept) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SvgIcon(
                Ic.sparkles,
                size: 18,
                color: C.violetDeep,
                strokeWidth: 2,
              ),
              const SizedBox(width: 8),
              Text(
                'De învățat',
                style: T.display(
                  size: 15,
                  weight: FontWeight.w800,
                  color: C.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _conceptLabel(concept.skillTag),
            style: T.body(
              size: 13.5,
              weight: FontWeight.w600,
              color: C.text2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ClayButton(
            label: 'Deschide o lecție',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 48,
            fontSize: 15,
            onTap: () {
              Juice.tick();
              context.push('/learn');
            },
          ),
        ],
      ),
    );
  }

  String _conceptLabel(String skillTag) => switch (skillTag) {
    'emergency_fund' =>
      'Fondul de urgență te apără de șocuri fără să te împrumuți scump.',
    'opportunity_cost' =>
      'Costul de oportunitate: fiecare amânare are un preț mai târziu.',
    'credit' => 'Creditul are dobândă, banii de azi costă mâine mai mult.',
    'budgeting' => 'Bugetul îți arată unde pleacă banii înainte să dispară.',
    'needs_wants' => 'Nevoi vs dorințe: separă-le și cash-flow-ul respiră.',
    'scams' =>
      'Țepele exploatează graba, verifică înainte să dai date sau bani.',
    'saving' => 'Economisirea constantă bate sumele mari, dar rare.',
    _ => 'Un concept financiar de aprofundat într-o lecție.',
  };
}
