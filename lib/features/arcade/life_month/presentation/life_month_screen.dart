import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/analytics/events.dart';
import '../../../../core/ui/clay.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/motion.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../domain/engine/life_sim/life_sim_commentary.dart';
import '../../../../domain/engine/life_sim/life_sim_content.dart';
import '../../../../domain/engine/life_sim/life_sim_engine.dart' as engine;
import '../../../../domain/engine/life_sim/life_sim_scoring.dart';
import '../../../../domain/engine/life_sim/life_sim_state.dart';
import '../../../../domain/engine/life_sim/money.dart';
import '../../../wardrobe/presentation/cashy_avatar.dart';
import '../data/life_month_repository.dart';
import '../data/life_sim_narrator.dart';
import 'life_month_common.dart';

/// Ecranul principal „30 de Zile": drumul lunii, balanța animată, sumarul
/// zilei și foile de jos (Portofel/Calendar/Obiectiv). Motorul e sursa de
/// adevăr; fiecare avans/alegere salvează un snapshot.
class LifeMonthScreen extends ConsumerStatefulWidget {
  const LifeMonthScreen({super.key, this.runId});

  /// Id-ul rundei (din rută). Dacă lipsește, se încarcă runda activă.
  final String? runId;

  @override
  ConsumerState<LifeMonthScreen> createState() => _LifeMonthScreenState();
}

class _LifeMonthScreenState extends ConsumerState<LifeMonthScreen> {
  LifeSimContent? _content;
  String? _runId;
  LifeSimState? _state;
  engine.DayResult? _lastResult;
  bool _busy = false;
  bool _loadError = false;

  /// Confetti-ul de „obiectiv atins" cade o singură dată pe rundă (flag local,
  /// nu stare de motor): tinta se atinge o dată, nu la fiecare rebuild.
  bool _goalCelebrated = false;

  /// Runda salvată e dintr-o versiune de conținut diferită de cea încărcată
  /// acum, nu o continuăm, dar mesajul de eroare e diferit de cel generic.
  bool _versionMismatch = false;
  final _stripCtrl = ScrollController();

  /// Bannerul „SALARIU +X" al zilei de plată; pleacă singur după câteva
  /// secunde sau la tap.
  Money? _salaryBanner;
  Timer? _salaryTimer;

  /// Borna zilelor 10 și 20, afișată peste conținut fără să blocheze fluxul.
  String? _milestone;
  Timer? _milestoneTimer;

  /// Fluxul de bani al zilelor jucate în sesiunea asta: zi -> (încasat,
  /// cheltuit). Sursa recapului de săptămână; la resume zilele vechi lipsesc
  /// și recapul pur și simplu nu apare.
  final Map<int, (Money, Money)> _dayFlows = {};
  int _flowDay = 0;
  Money _flowStartTotal = Money.zero;
  Money _flowIncome = Money.zero;

  /// Recapul săptămânii tocmai încheiate: (săptămâna, cheltuit, încasat).
  (int, Money, Money)? _weekRecap;

  /// Ultimul comentariu al lui Cashy (din [engine.applyChoice] via
  /// [commentOnChoice], sau din [commentOnQuietDay] după o zi fără eveniment).
  /// Null doar înainte de prima zi, atunci arătăm salutul implicit.
  CashyComment? _comment;

  /// Salutul implicit, înainte de orice decizie (nu vine dintr-un pool,
  /// nu-i o „situație" de comentat, doar un „bun venit").
  static const _greeting = CashyComment(
    line: 'Hai să pornim luna! Sunt lângă tine la fiecare decizie.',
    more: [],
    mood: CashyMoodGame.happy,
  );

  static const _tileExtent = 54.0; // 46 lățime + 8 margine

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _salaryTimer?.cancel();
    _milestoneTimer?.cancel();
    _stripCtrl.dispose();
    super.dispose();
  }

  LifeMonthRepository get _repo => ref.read(lifeMonthRepositoryProvider);

  Future<void> _load() async {
    try {
      final content = await ref.read(lifeSimContentProvider.future);
      LifeMonthRun? run;
      if (widget.runId != null) {
        run = await _repo.getRun(widget.runId!);
      }
      run ??= await _repo.activeRun();
      if (!mounted) return;
      if (run == null || content.roleById(run.state.roleId) == null) {
        setState(() => _loadError = true);
        return;
      }
      // Run pinuit pe versiunea de conținut de la creare, continuarea pe
      // conținut schimbat ar rupe determinismul same-seed. Oprim curat.
      if (run.state.contentVersion != content.version) {
        setState(() {
          _loadError = true;
          _versionMismatch = true;
        });
        return;
      }
      setState(() {
        _content = content;
        _runId = run!.id;
        _state = run.state;
      });
      _scrollToCurrentDay();
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  // --- Bucla de joc

  Future<void> _advance() async {
    final content = _content;
    final state = _state;
    if (_busy || content == null || state == null || _runId == null) return;
    // Rundă deja la ziua 30 → raport. _busy se pune înainte de await, ca un
    // dublu-tap să nu intre de două ori în _complete().
    if (state.day >= 30) {
      setState(() => _busy = true);
      await _complete();
      return;
    }

    Juice.tick();
    _closeDayFlow();
    final result = engine.advanceDay(state, content);
    _startDayFlow(state, result);
    setState(() {
      _state = result.state;
      _lastResult = result;
      _busy = true;
      _weekRecap = null;
      _salaryBanner = result.salaryReceived;
    });
    if (result.salaryReceived != null) {
      _salaryTimer?.cancel();
      _salaryTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _salaryBanner = null);
      });
    }
    await _repo.saveSnapshot(_runId!, result.state);
    // Cardul din Arcade citește ziua din activeRunProvider (cache); fără asta
    // rămâne pe „Continuă ziua 1" cât timp joci.
    ref.invalidate(activeRunProvider);
    _scrollToCurrentDay();
    ref.read(analyticsProvider).track(AnalyticsEvents.lifeSimDayAdvanced, {
      'day': result.state.day,
      'had_event': result.event != null,
    });

    if (!mounted) return;
    if (result.salaryReceived != null) {
      // Salariul e un moment: confetti + haptic mare, bannerul sare în scenă
      // și contorul urcă la vedere; abia apoi vine foaia de alocare.
      Juice.major();
      ConfettiBurst.show(context);
      await _beat(650);
      if (!mounted) return;
      await _showAllocationSheet(result.salaryReceived!);
    }
    if (result.event != null) {
      // Întâi intră ziua și rândurile ei, apoi foaia de eveniment.
      await _beat(300);
      if (!mounted) return;
      await _showEventSheet(result.event!);
    } else {
      // Zi liniștită, tot merită o vorbă din partea lui Cashy.
      await _applyCashyComment(
        commentOnQuietDay(s: result.state, seed: result.state.seed),
      );
    }
    if (!mounted) return;
    _maybeShowMilestone(_state!.day);
    _maybeShowWeekRecap(_state!.day);
    if (_state!.day >= 30) {
      await _complete();
      return;
    }
    setState(() => _busy = false);
  }

  /// Pauză scurtă de ritm între momentele zilei. Sare complet cu reduce-motion
  /// sau dacă ecranul a dispărut între timp.
  Future<void> _beat(int ms) async {
    if (!mounted || MediaQuery.of(context).disableAnimations) return;
    await Future.delayed(Duration(milliseconds: ms));
  }

  // --- Fluxul de bani pe zile (recapul de săptămână)

  /// Închide măsurătoarea zilei curente: venitul l-am adunat pe parcurs, iar
  /// cheltuiala iese din diferența față de totalul de la începutul zilei.
  void _closeDayFlow() {
    final s = _state;
    if (_flowDay <= 0 || s == null) return;
    final net = _moneyValue(s) - _flowStartTotal;
    var spent = _flowIncome - net;
    if (spent.isNegative) spent = Money.zero;
    _dayFlows[_flowDay] = (_flowIncome, spent);
    _flowDay = 0;
  }

  void _startDayFlow(LifeSimState before, engine.DayResult result) {
    _flowDay = result.state.day;
    _flowStartTotal = _moneyValue(before);
    var income = Money.zero;
    if (result.salaryReceived != null) {
      income = income + result.salaryReceived!;
    }
    for (final f in result.state.firedEffects) {
      if (f.day != result.state.day) continue;
      final tot = f.cashDelta + f.fundDelta + f.goalDelta;
      if (tot > Money.zero) income = income + tot;
    }
    _flowIncome = income;
  }

  /// La finalul zilelor 7/14/21/28 arată recapul, dar doar dacă toate cele 7
  /// zile au fost jucate în sesiunea asta (la resume istoricul lipsește).
  void _maybeShowWeekRecap(int day) {
    if (day < 7 || day % 7 != 0 || day >= 30) return;
    _closeDayFlow();
    var income = Money.zero;
    var spent = Money.zero;
    for (var d = day - 6; d <= day; d++) {
      final f = _dayFlows[d];
      if (f == null) return;
      income = income + f.$1;
      spent = spent + f.$2;
    }
    setState(() => _weekRecap = (day ~/ 7, spent, income));
  }

  /// Borna zilelor 10 și 20: un banner mic care nu blochează nimic și pleacă
  /// singur după câteva secunde sau la tap.
  void _maybeShowMilestone(int day) {
    if (day != 10 && day != 20) return;
    _milestoneTimer?.cancel();
    setState(
      () => _milestone = day == 10
          ? 'Ai trecut de ziua 10! Jumătatea drumului se apropie.'
          : 'Ziua 20 bifată! Ultima linie dreaptă începe.',
    );
    _milestoneTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _milestone = null);
    });
  }

  Future<void> _complete() async {
    final content = _content!;
    // Decontăm consecințele amânate dincolo de ziua 30 înainte de scor,
    // altfel amânarea în ultimele zile ale lunii ar fi gratuită.
    final settled = engine.settleRemainingEffects(_state!);
    final sc = score(settled, content);
    await _repo.saveSnapshot(_runId!, settled);
    await _repo.completeRun(runId: _runId!, state: settled, score: sc);
    ref.read(analyticsProvider).track(AnalyticsEvents.lifeSimCompleted, {
      'score': sc.total,
      'ending': sc.endingId,
    });
    ref.invalidate(activeRunProvider);
    ref.invalidate(lastCompletedRunProvider);
    if (!mounted) return;
    context.pushReplacement('/arcade/luna/raport', extra: _runId);
  }

  /// Aplică un [CashyComment] compus determinist, dându-i mai întâi șansa
  /// hook-ului pentru un model de limbaj să-l lustruiască. Offline, [polish]
  /// întoarce null, deci rămâne linia compusă.
  Future<void> _applyCashyComment(CashyComment comment) async {
    final narrator = ref.read(cashyNarratorProvider);
    final polished = await narrator.polish(comment.line, {
      'mood': comment.mood.name,
      'day': _state?.day,
    });
    if (!mounted) return;
    setState(
      () => _comment = polished == null
          ? comment
          : CashyComment(
              line: polished,
              more: comment.more,
              mood: comment.mood,
            ),
    );
  }

  /// Dacă tocmai s-a atins tinta obiectivului, sărbătorim o singură dată pe
  /// rundă. Se cheamă după orice mișcare care poate crește plicul obiectivului.
  void _maybeCelebrateGoal() {
    final s = _state;
    if (s == null || _goalCelebrated) return;
    if (s.goalTarget.bani > 0 && s.goalSavings >= s.goalTarget) {
      _goalCelebrated = true;
      if (!mounted) return;
      Juice.epic();
      ConfettiBurst.show(context);
    }
  }

  void _scrollToCurrentDay() {
    if (!_stripCtrl.hasClients || _state == null) return;
    final target = ((_state!.day - 1).clamp(0, 29)) * _tileExtent;
    final max = _stripCtrl.position.maxScrollExtent;
    final offset = (target - _tileExtent * 2).clamp(0.0, max);
    if (MediaQuery.of(context).disableAnimations) {
      _stripCtrl.jumpTo(offset);
    } else {
      _stripCtrl.animateTo(offset, duration: Dur.base, curve: Curves.easeOut);
    }
  }

  // --- Foaia de eveniment

  Future<void> _showEventSheet(LifeSimEvent event) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      // isDismissible/enableDrag nu opresc back-ul Android, doar PopScope o
      // face. Fără el, back-ul ar închide evenimentul fără niciun efect aplicat.
      builder: (_) => PopScope(canPop: false, child: _EventSheet(event: event)),
    );
    if (chosen == null || !mounted) return;

    final beforeState = _state!;
    final before = _moneyValue(beforeState);
    final after = engine.applyChoice(beforeState, event, chosen, _content!);
    final choiceDelta = _moneyValue(after) - before;
    final gained = !choiceDelta.isNegative;
    // Câștig → haptic pozitiv; pierderile sunt tăcute (fără shaming).
    if (gained) Juice.correct();
    // Banii câștigați din alegere intră la venitul zilei, pentru recap.
    if (choiceDelta > Money.zero && _flowDay == after.day) {
      _flowIncome = _flowIncome + choiceDelta;
    }

    await _applyCashyComment(
      commentOnChoice(
        event: event,
        choiceIdx: chosen,
        before: beforeState,
        after: after,
        seed: after.seed,
      ),
    );
    if (!mounted) return;

    setState(() => _state = after);
    _maybeCelebrateGoal();
    await _repo.recordDecision(
      runId: _runId!,
      day: after.day,
      eventId: event.id,
      choiceIdx: chosen,
    );
    await _repo.saveSnapshot(_runId!, after);
    ref.read(analyticsProvider).track(AnalyticsEvents.lifeSimChoiceMade, {
      'event_id': event.id,
      'choice_idx': chosen,
    });

    if (!mounted) return;
    _toast(_consequenceLine(event, chosen, before, after), gained: gained);
  }

  Money _moneyValue(LifeSimState s) => s.cash + s.emergencyFund + s.goalSavings;

  String _consequenceLine(
    LifeSimEvent e,
    int idx,
    Money before,
    LifeSimState after,
  ) {
    final total = _moneyValue(after) - before;
    if (!total.isZero) {
      final signed = total.isNegative ? total.lei : '+${total.lei}';
      return '${e.choices[idx].label} · $signed';
    }
    // Fără mișcare de bani imediată, arătăm eticheta alegerii.
    return e.choices[idx].label;
  }

  void _toast(String message, {required bool gained}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: gained ? C.greenDeep : C.text,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.sm),
        ),
        content: Text(
          message,
          style: T.body(
            size: 13.5,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // --- Foaia de alocare a salariului

  Future<void> _showAllocationSheet(Money salary) async {
    final result = await showModalBottomSheet<(Money, Money)?>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      // Ca la foaia de eveniment: back-ul Android nu trebuie să scoată din
      // alocare fără o alegere explicită (isDismissible nu-l oprește).
      builder: (_) => PopScope(
        canPop: false,
        child: _AllocationSheet(salary: salary, cash: _state!.cash),
      ),
    );
    if (result == null || !mounted) return;
    final (toFund, toGoal) = result;
    if (toFund.isZero && toGoal.isZero) return;
    try {
      final after = engine.allocateSalary(
        _state!,
        toFund: toFund,
        toGoal: toGoal,
      );
      Juice.tick();
      setState(() => _state = after);
      _maybeCelebrateGoal();
      await _repo.saveSnapshot(_runId!, after);
    } catch (_) {
      // Alocare invalidă (peste cash), o ignorăm silențios.
    }
  }

  // --- Foile de acces permanent

  void _openWallet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      // Foaia ține o copie de lucru și aplică mutările prin motor; noi doar
      // reflectăm rezultatul pe ecran și îl persistăm.
      builder: (_) => _WalletSheet(
        initial: _state!,
        onChanged: (after) async {
          setState(() => _state = after);
          _maybeCelebrateGoal();
          await _repo.saveSnapshot(_runId!, after);
        },
      ),
    );
  }

  void _openCalendar() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _CalendarSheet(state: _state!, content: _content!),
    );
  }

  void _openGoal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _GoalSheet(state: _state!, content: _content!),
    );
  }

  // --- Construcția ecranului

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
                : (_state == null ? _loading() : _body()),
          ),
        ],
      ),
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _error() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        lifeMonthTopBar(
          context,
          '30 de Zile',
          onClose: () => context.go('/arcade'),
        ),
        const Spacer(),
        Image.asset(Cashy.cashyWorried, width: 110),
        const SizedBox(height: 12),
        Text(
          _versionMismatch
              ? 'Runda asta e dintr-o versiune mai veche a jocului, pornește o lună nouă.'
              : 'Runda nu a putut fi încărcată',
          textAlign: TextAlign.center,
          style: T.display(size: 19, weight: FontWeight.w800, color: C.text),
        ),
        const Spacer(),
      ],
    ),
  );

  Widget _body() {
    final s = _state!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          child: lifeMonthTopBar(
            context,
            '30 de Zile',
            onClose: () => context.go('/arcade'),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dayHeader(s),
                    const SizedBox(height: 12),
                    _daysStrip(s),
                    if (_salaryBanner != null) ...[
                      const SizedBox(height: 8),
                      _salaryBannerCard(_salaryBanner!),
                      const SizedBox(height: 10),
                    ] else
                      const SizedBox(height: 18),
                    _BalancePanel(cash: s.cash),
                    const SizedBox(height: 14),
                    _chips(s),
                    const SizedBox(height: 12),
                    _statsRow(s),
                    const SizedBox(height: 18),
                    _CashyCommentator(comment: _comment ?? _greeting),
                    const SizedBox(height: 16),
                    if (_weekRecap != null) ...[
                      _weekRecapCard(),
                      const SizedBox(height: 16),
                    ],
                    _situationCard(s),
                    const SizedBox(height: 16),
                    _accessRow(),
                  ],
                ),
              ),
              if (_milestone != null)
                Positioned(
                  top: 6,
                  left: 26,
                  right: 26,
                  child: Center(child: _milestoneBanner()),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: ClayButton(
            label: s.day >= 30 ? 'Vezi raportul' : '+ O zi',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 58,
            fontSize: 18,
            onTap: _busy ? null : _advance,
          ),
        ),
      ],
    );
  }

  Widget _dayHeader(LifeSimState s) {
    final day = s.day < 1 ? 1 : s.day;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : Dur.base,
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween(begin: 0.06, end: 0.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            'Ziua $day',
            key: ValueKey(s.day),
            style: T.display(size: 26, weight: FontWeight.w800, color: C.text),
          ),
        ),
        Text(
          'din 30',
          style: T.body(size: 15, weight: FontWeight.w700, color: C.text3),
        ),
      ],
    );
  }

  /// Bannerul zilei de salariu: sare în scenă o singură dată pe zi de plată.
  Widget _salaryBannerCard(Money salary) {
    return PopIn(
      key: ValueKey('salariu${_state?.day}'),
      child: GestureDetector(
        onTap: () {
          _salaryTimer?.cancel();
          setState(() => _salaryBanner = null);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: Grad.green,
            borderRadius: BorderRadius.circular(16),
            boxShadow: Sh.green,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SvgIcon(
                Ic.coins,
                size: 18,
                color: Colors.white,
                strokeWidth: 2.4,
              ),
              const SizedBox(width: 8),
              Text(
                'SALARIU +${salary.lei}',
                style: T.display(
                  size: 15.5,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 15.5 * 0.04,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _milestoneBanner() {
    return PopIn(
      key: ValueKey(_milestone),
      child: GestureDetector(
        onTap: () {
          _milestoneTimer?.cancel();
          setState(() => _milestone = null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(R.pill),
            border: Border.all(color: C.line2, width: 1),
            boxShadow: Sh.raise,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SvgIcon(Ic.flag, size: 15, color: C.blue, strokeWidth: 2.2),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  _milestone!,
                  maxLines: 2,
                  style: T.display(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Recapul compact al săptămânii încheiate: cât a intrat, cât a ieșit, cu
  /// două bare care se umplu la vedere.
  Widget _weekRecapCard() {
    final (week, spent, income) = _weekRecap!;
    final maxBani = spent.bani > income.bani ? spent.bani : income.bani;
    double frac(Money m) => maxBani <= 0 ? 0 : m.bani / maxBani;
    return PopIn(
      key: ValueKey('sapt$week'),
      child: ClayCard(
        radius: R.md,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SĂPTĂMÂNA $week',
              style: T.display(
                size: 11,
                weight: FontWeight.w800,
                color: C.text3,
                letterSpacing: 11 * 0.12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ai cheltuit ${spent.lei}, ai încasat ${income.lei}.',
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text2),
            ),
            const SizedBox(height: 12),
            _recapBar('Cheltuieli', spent, C.danger, frac(spent)),
            const SizedBox(height: 8),
            _recapBar('Încasări', income, C.greenDeep, frac(income)),
          ],
        ),
      ),
    );
  }

  Widget _recapBar(String label, Money m, Color color, double frac) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: T.body(size: 12, weight: FontWeight.w600, color: C.text2),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(R.pill),
            child: SizedBox(
              height: 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: C.inset),
                  AnimatedFrac(
                    value: frac,
                    builder: (_, v) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          m.lei,
          style: T.display(size: 12.5, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _daysStrip(LifeSimState s) {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _stripCtrl,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 30,
        itemBuilder: (_, i) => _dayTile(s, i + 1),
      ),
    );
  }

  Widget _dayTile(LifeSimState s, int day) {
    final isCurrent = s.day == day || (s.day < 1 && day == 1);
    final isPast = day < s.day;
    final bills = _billsDueOn(day);
    final isPayday = day == (_content!.roleById(s.roleId)?.payDay ?? 1);
    final ghidat = s.mode == 'ghidat';

    // Urma zilei trecute: rosu (factura ratata) > violet (eveniment) > verde
    // (totul platit la timp). O singura marca pe zi, prioritatea e fixa.
    _DayMark? mark;
    if (isPast) {
      if (s.missedBills.any((m) => m.$2 == day)) {
        mark = _DayMark.missed;
      } else if (s.decisions.any((d) => d.day == day)) {
        mark = _DayMark.event;
      } else if (_hasDueOn(day)) {
        mark = _DayMark.paid;
      }
    }

    // Zona de sus (40px): Cashy (azi) > moneda de salariu (puls) > urma > preview.
    Widget top;
    if (isCurrent) {
      top = JuiceBounce(
        trigger: s.day,
        child: CashySprite(asset: Cashy.cashyDefault, width: 34),
      );
    } else if (isPayday) {
      top = JuiceBounce(
        trigger: s.day,
        child: const SvgIcon(
          Ic.coins,
          size: 20,
          color: C.greenDeep,
          strokeWidth: 2.2,
        ),
      );
    } else if (mark != null) {
      top = _markDot(mark);
    } else if (bills.isNotEmpty) {
      top = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 2,
            children: [
              for (var k = 0; k < bills.length && k < 3; k++)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: C.amber,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
            ],
          ),
          if (ghidat)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${_billsTotal(bills).bani ~/ 100}',
                style: T.body(
                  size: 9,
                  weight: FontWeight.w700,
                  color: C.amberDeep,
                ),
              ),
            ),
        ],
      );
    } else {
      top = const SizedBox.shrink();
    }

    final borderColor = isCurrent
        ? C.blueDeep
        : mark == _DayMark.missed
        ? C.danger.withValues(alpha: 0.55)
        : mark == _DayMark.event
        ? C.violet.withValues(alpha: 0.55)
        : mark == _DayMark.paid
        ? C.green.withValues(alpha: 0.45)
        : C.line;

    return Container(
      width: 46,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          SizedBox(height: 40, child: Center(child: top)),
          const SizedBox(height: 3),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isCurrent ? C.blue : (isPast ? C.inset : C.surface),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isCurrent ? Sh.blue : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: T.display(
                size: 13,
                weight: FontWeight.w800,
                color: isCurrent ? Colors.white : (isPast ? C.text3 : C.text2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markDot(_DayMark mark) => switch (mark) {
    _DayMark.missed => Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: C.danger, shape: BoxShape.circle),
    ),
    _DayMark.event => Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: C.violet, shape: BoxShape.circle),
    ),
    _DayMark.paid => const SvgIcon(
      Ic.check,
      size: 14,
      color: C.green,
      strokeWidth: 2.8,
    ),
  };

  /// Rândul de stat-uri de viață: 4 mini-bare animate. Tap pe o bară → foaia
  /// statului atins; tap între bare → foaia care le explică pe toate.
  Widget _statsRow(LifeSimState s) {
    final st = s.stats;
    Widget bar(_StatDetail d, int value, bool critical) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Juice.tick();
        _openStatDetail(d, value);
      },
      child: _StatBar(
        icon: d.icon,
        color: d.color,
        value: value,
        critical: critical,
      ),
    );
    return GestureDetector(
      key: const Key('lifeStatsRow'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Juice.tick();
        _openStats(st);
      },
      child: Row(
        children: [
          Expanded(child: bar(_statHealth, st.health, st.health < 25)),
          const SizedBox(width: 10),
          Expanded(child: bar(_statEnergy, st.energy, st.energy < 25)),
          const SizedBox(width: 10),
          Expanded(child: bar(_statStress, st.stress, st.stress > 75)),
          const SizedBox(width: 10),
          Expanded(
            child: bar(_statRelations, st.relationships, st.relationships < 25),
          ),
        ],
      ),
    );
  }

  void _openStats(LifeStats stats) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _StatsSheet(stats: stats),
    );
  }

  void _openStatDetail(_StatDetail d, int value) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _StatDetailSheet(detail: d, value: value),
    );
  }

  Widget _chips(LifeSimState s) {
    return Row(
      children: [
        Expanded(
          child: _chip(
            Ic.shield,
            'Fond',
            s.emergencyFund.lei,
            C.green,
            C.greenSoft,
            onTap: _openWallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            Ic.coins,
            'Datorii',
            s.totalDebt.lei,
            s.totalDebt.isZero ? C.text3 : C.danger,
            s.totalDebt.isZero ? C.inset : C.dangerSoft,
            onTap: _openWallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _billChip(s)),
      ],
    );
  }

  /// Chip-ul de factură își schimbă culoarea după cât de aproape e scadența:
  /// liniștit când e departe, amber cu 1-2 zile înainte, roșu pe restanță.
  /// Pulsul stă doar pe iconiță și doar când chiar arde. Tap → calendarul.
  Widget _billChip(LifeSimState s) {
    final next = _nextDue(s);
    final overdue = s.arrears.isNotEmpty;
    final daysLeft = next == null ? null : next.$3 - s.day;
    final (color, bg) = overdue
        ? (C.dangerDeep, C.dangerSoft)
        : daysLeft == null
        ? (C.text3, C.inset)
        : daysLeft <= 2
        ? (C.amberDeep, C.amberSoft)
        : (C.greenDeep, C.greenSoft);
    final urgent = overdue || (daysLeft != null && daysLeft <= 2);
    return _chip(
      Ic.clock,
      'Factură',
      next == null ? ', ' : '${next.$2.lei} · z${next.$3}',
      color,
      bg,
      onTap: _openCalendar,
      pulseTrigger: urgent ? s.day : null,
    );
  }

  Widget _chip(
    String icon,
    String label,
    String value,
    Color color,
    Color bg, {
    VoidCallback? onTap,
    Object? pulseTrigger,
  }) {
    Widget iconW = SvgIcon(icon, size: 13, color: color, strokeWidth: 2);
    if (pulseTrigger != null) {
      iconW = _UrgentPulse(trigger: pulseTrigger, child: iconW);
    }
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconW,
              const SizedBox(width: 4),
              Text(
                label,
                style: T.display(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.display(
              size: 12.5,
              weight: FontWeight.w800,
              color: C.text,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Pressable(scale: 0.96, onTap: onTap, child: chip);
  }

  Widget _situationCard(LifeSimState s) {
    final r = _lastResult;
    if (r == null) {
      return ClayCard(
        radius: R.md,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Image.asset(Cashy.cashyPoint, width: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Apasă „+ O zi" ca să pornești luna. Salariul intră azi.',
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
      );
    }

    final lines = <Widget>[];
    if (r.salaryReceived != null) {
      lines.add(
        _sitLine(Ic.coins, C.greenDeep, 'Salariu', '+${r.salaryReceived!.lei}'),
      );
    }
    for (final id in r.billsPaid) {
      final def = _content!.recurringById(id);
      lines.add(
        _sitLine(
          Ic.check,
          C.text2,
          def?.name ?? id,
          def == null ? 'plătită' : '-${def.amount.lei}',
        ),
      );
    }
    for (final id in r.billsMissed) {
      final def = _content!.recurringById(id);
      lines.add(_sitLine(Ic.alert, C.danger, def?.name ?? id, 'ratată'));
    }
    for (final id in r.arrearsPaid) {
      final def = _content!.recurringById(id);
      lines.add(
        _sitLine(Ic.check, C.amberDeep, def?.name ?? id, 'restanță stinsă'),
      );
    }
    for (final eff in r.effectsFired) {
      lines.add(_sitLine(Ic.clock, C.amberDeep, eff.$1, eff.$2));
    }
    if (lines.isEmpty) {
      lines.add(_sitLine(Ic.check, C.text3, 'Zi liniștită', 'nimic de plătit'));
    }

    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZIUA ${s.day}',
            style: T.display(
              size: 11,
              weight: FontWeight.w800,
              color: C.text3,
              letterSpacing: 11 * 0.12,
            ),
          ),
          const SizedBox(height: 10),
          // Cheile pe zi refac stagger-ul în fiecare dimineață, nu doar la
          // prima construire a cardului.
          ...List.generate(
            lines.length,
            (i) => StaggerIn(
              key: ValueKey('zi${s.day}r$i'),
              index: i,
              child: lines[i],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sitLine(String icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SvgIcon(icon, size: 15, color: color, strokeWidth: 2.2),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: T.display(size: 13, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _accessRow() {
    return Row(
      children: [
        Expanded(child: _accessBtn(Ic.wallet, 'Portofel', _openWallet)),
        const SizedBox(width: 10),
        Expanded(child: _accessBtn(Ic.clock, 'Calendar', _openCalendar)),
        const SizedBox(width: 10),
        Expanded(child: _accessBtn(Ic.target, 'Obiectiv', _openGoal)),
      ],
    );
  }

  Widget _accessBtn(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        onTap();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line, width: 1),
          boxShadow: Sh.raise,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 18, color: C.blue, strokeWidth: 2),
            const SizedBox(height: 3),
            Text(
              label,
              style: T.display(
                size: 11,
                weight: FontWeight.w800,
                color: C.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers de conținut

  List<RecurringDef> _billsDueOn(int day) {
    final s = _state!;
    final out = <RecurringDef>[];
    for (final id in s.bills) {
      final def = _content!.recurringById(id);
      if (def != null && def.dueDay == day) out.add(def);
    }
    return out;
  }

  /// Ziua avea ceva scadent (factură sau rată)? Semnalul pentru bifa verde de
  /// „plătit la timp" pe drumul lunii.
  bool _hasDueOn(int day) {
    final s = _state!;
    for (final id in s.bills) {
      final def = _content!.recurringById(id);
      if (def != null && def.dueDay == day) return true;
    }
    for (final d in s.debts) {
      if (d.dueDay == day) return true;
    }
    return false;
  }

  Money _billsTotal(List<RecurringDef> bills) =>
      bills.fold(Money.zero, (sum, b) => sum + b.amount);

  /// Următoarea scadență după ziua curentă: (nume, sumă, zi).
  (String, Money, int)? _nextDue(LifeSimState s) {
    (String, Money, int)? best;
    void consider(String name, Money amount, int day) {
      if (day <= s.day) return;
      if (best == null || day < best!.$3) best = (name, amount, day);
    }

    for (final id in s.bills) {
      final def = _content!.recurringById(id);
      if (def != null) consider(def.name, def.amount, def.dueDay);
    }
    for (final d in s.debts) {
      consider('Rată', d.monthly, d.dueDay);
    }
    return best;
  }
}

// Cashy comentatorul, mare, reacționează la fiecare decizie, spune MAI MULT
// la tap (line → more[0] → more[1] → înapoi la line).

class _CashyCommentator extends StatefulWidget {
  const _CashyCommentator({required this.comment});
  final CashyComment comment;

  @override
  State<_CashyCommentator> createState() => _CashyCommentatorState();
}

class _CashyCommentatorState extends State<_CashyCommentator> {
  int _revealIndex = 0;

  /// Cel mai avansat index văzut pentru comentariul curent, hint-ul
  /// „atinge-mă" dispare abia după ce jucătorul a văzut ultima replică.
  int _maxSeen = 0;

  @override
  void didUpdateWidget(covariant _CashyCommentator old) {
    super.didUpdateWidget(old);
    // Comentariu nou (altă decizie/zi) → repornim ciclul de la prima linie.
    if (old.comment.line != widget.comment.line ||
        old.comment.more != widget.comment.more) {
      _revealIndex = 0;
      _maxSeen = 0;
    }
  }

  void _onTap() {
    final lines = [widget.comment.line, ...widget.comment.more];
    if (lines.length <= 1) return; // nimic de dezvăluit
    Juice.tick();
    setState(() {
      _revealIndex = (_revealIndex + 1) % lines.length;
      if (_revealIndex > _maxSeen) _maxSeen = _revealIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = [widget.comment.line, ...widget.comment.more];
    final index = _revealIndex < lines.length ? _revealIndex : 0;
    final text = lines[index];
    final showHint = _maxSeen < lines.length - 1;
    final asset = assetForCashyMood(widget.comment.mood);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          JuiceBounce(
            trigger: text,
            child: CashySprite(asset: asset, width: 110),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : Dur.base,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey(text),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(6),
                      ),
                      border: Border.all(color: C.line, width: 1),
                      boxShadow: Sh.raise,
                    ),
                    child: Text(
                      text,
                      style: T.body(
                        size: 14,
                        weight: FontWeight.w500,
                        color: C.text2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (showHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Opacity(
                      opacity: 0.6,
                      child: Text(
                        'atinge-mă',
                        style: T.display(
                          size: 11,
                          weight: FontWeight.w800,
                          color: C.text3,
                        ),
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
}

// Drumul lunii: marca unei zile trecute.

enum _DayMark { missed, event, paid }

// Balanța „în buzunar": contor animat + chip de delta care sare lângă sold,
// urcă și se estompează la fiecare schimbare de cash (900ms, sare cu
// reduce-motion). Verde pe plus, roșu pe minus.

class _BalancePanel extends StatefulWidget {
  const _BalancePanel({required this.cash});
  final Money cash;

  @override
  State<_BalancePanel> createState() => _BalancePanelState();
}

class _BalancePanelState extends State<_BalancePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// Textul care plutește acum; null cât timp nu se ridică nimic.
  String? _floater;
  bool _floaterGain = true;

  @override
  void initState() {
    super.initState();
    // Creat aici, nu ca `late` leneș: build atinge controllerul doar cât timp
    // floater-ul nu e null, deci fără schimbare de cash inițializarea leneșă ar
    // pica abia în dispose si ar crea un ticker pe un element deja scos.
    _c =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed && mounted) {
            setState(() => _floater = null);
          }
        });
  }

  @override
  void didUpdateWidget(_BalancePanel old) {
    super.didUpdateWidget(old);
    if (old.cash.bani == widget.cash.bani) return;
    if (MediaQuery.of(context).disableAnimations) return;
    final delta = widget.cash - old.cash;
    _floater = delta.isNegative ? delta.lei : '+${delta.lei}';
    _floaterGain = !delta.isNegative;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ÎN BUZUNAR',
          style: T.display(
            size: 11,
            weight: FontWeight.w800,
            color: C.text3,
            letterSpacing: 11 * 0.14,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            JuiceBounce(
              trigger: widget.cash.bani,
              child: _MoneyCount(
                value: widget.cash,
                style: T.display(
                  size: 38,
                  weight: FontWeight.w800,
                  color: widget.cash.isNegative ? C.danger : C.text,
                ),
              ),
            ),
            if (_floater != null)
              Positioned(
                top: 0,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) {
                      final t = _c.value;
                      final fg = _floaterGain ? C.greenDeep : C.danger;
                      // Pop scurt la intrare, urcă lin, se stinge pe final.
                      final pop = Curves.easeOutBack.transform(
                        (t / 0.22).clamp(0.0, 1.0),
                      );
                      final fade = t < 0.4 ? 1.0 : 1 - (t - 0.4) / 0.6;
                      return Opacity(
                        opacity: fade.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -20 - 24 * t),
                          child: Transform.scale(
                            scale: pop,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _floaterGain
                                    ? C.greenSoft
                                    : C.dangerSoft,
                                borderRadius: BorderRadius.circular(R.pill),
                                border: Border.all(
                                  color: fg.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _floater!,
                                style: T.display(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Mini-barele de stat-uri de viață + foaia care le explică.

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.icon,
    required this.color,
    required this.value,
    required this.critical,
  });

  final String icon;
  final Color color;
  final int value;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final display = critical ? C.danger : color;
    final track = critical ? C.dangerSoft : C.inset;
    return JuiceShake(
      // Tremură doar cât e critic, la fiecare schimbare de valoare.
      trigger: critical ? value : 0,
      child: Row(
        children: [
          SvgIcon(icon, size: 13, color: display, strokeWidth: 2.2),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(R.pill),
              child: SizedBox(
                height: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: track),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: (value / 100).clamp(0.0, 1.0)),
                      duration: reduceMotion ? Duration.zero : Dur.base,
                      curve: Curves.easeOut,
                      builder: (_, v, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: ColoredBox(color: display),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSheet extends StatelessWidget {
  const _StatsSheet({required this.stats});
  final LifeStats stats;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cele 4 stat-uri de viață',
              style: T.display(
                size: 19,
                weight: FontWeight.w800,
                color: C.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Media lor, cu stresul inversat, e „Echilibru": 20% din scorul lunii.',
              style: T.body(
                size: 13,
                weight: FontWeight.w500,
                color: C.text2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _row(
              Ic.heart,
              C.green,
              'Sănătate',
              stats.health,
              'Scade dacă te epuizezi sau stai prea mult sub stres. O ții sus odihnindu-te.',
            ),
            _row(
              Ic.flame,
              C.blue,
              'Energie',
              stats.energy,
              'Scade puțin zilnic și mai mult când ești stresat. Fără energie, sănătatea suferă.',
            ),
            _row(
              Ic.alert,
              C.amberDeep,
              'Stres',
              stats.stress,
              'Crește la facturi ratate și presiune. Un pic e normal, prea mult îți arde energia.',
            ),
            _row(
              Ic.message,
              C.violet,
              'Relații',
              stats.relationships,
              'Se răcesc dacă uiți de viața socială. Timpul cu oamenii le ține calde.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String icon, Color color, String name, int value, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: SvgIcon(icon, size: 20, color: color, strokeWidth: 2.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: T.display(
                        size: 15,
                        weight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$value',
                      style: T.display(
                        size: 15,
                        weight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: T.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: C.text2,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Puls finit pe iconițe urgente: trei bătăi amortizate la intrare și la
// fiecare schimbare de trigger, apoi liniște. Bucla infinită ar obosi ochiul
// și ar ține ecranul într-o animație permanentă.

class _UrgentPulse extends StatefulWidget {
  const _UrgentPulse({required this.trigger, required this.child});

  final Object trigger;
  final Widget child;

  @override
  State<_UrgentPulse> createState() => _UrgentPulseState();
}

class _UrgentPulseState extends State<_UrgentPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.of(context).disableAnimations) _c.forward();
  }

  @override
  void didUpdateWidget(_UrgentPulse old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        !MediaQuery.of(context).disableAnimations) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final scale = 1 + 0.24 * math.sin(t * math.pi * 3).abs() * (1 - t);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

// Foaia unui singur stat: ce înseamnă bara atinsă și cum o refaci.

class _StatDetail {
  const _StatDetail({
    required this.icon,
    required this.color,
    required this.name,
    required this.meaning,
    required this.tip,
    this.inverted = false,
  });

  final String icon;
  final Color color;
  final String name;
  final String meaning;
  final String tip;

  /// La stres, mult înseamnă rău: pragul critic e sus, nu jos.
  final bool inverted;
}

const _statHealth = _StatDetail(
  icon: Ic.heart,
  color: C.green,
  name: 'Sănătate',
  meaning: 'Arată cât de bine se simte corpul tău luna asta.',
  tip:
      'Se reface când te odihnești și nu lași stresul să stea sus zile la rând.',
);

const _statEnergy = _StatDetail(
  icon: Ic.flame,
  color: C.blue,
  name: 'Energie',
  meaning: 'Puterea ta pentru ziua de azi. Scade câte puțin în fiecare zi.',
  tip: 'Somnul și pauzele o încarcă la loc. Dacă ajunge jos, suferă sănătatea.',
);

const _statStress = _StatDetail(
  icon: Ic.alert,
  color: C.amberDeep,
  name: 'Stres',
  meaning: 'Presiunea care se adună când apar facturi și surprize.',
  tip: 'Scade când plătești la timp și nu stai pe minus. Puțin stres e normal.',
  inverted: true,
);

const _statRelations = _StatDetail(
  icon: Ic.message,
  color: C.violet,
  name: 'Relații',
  meaning: 'Cât de aproape rămâi de prieteni și familie.',
  tip: 'Un mesaj sau o ieșire scurtă le ține calde, fără să golești buzunarul.',
);

class _StatDetailSheet extends StatelessWidget {
  const _StatDetailSheet({required this.detail, required this.value});

  final _StatDetail detail;
  final int value;

  @override
  Widget build(BuildContext context) {
    final critical = detail.inverted ? value > 75 : value < 25;
    final color = critical ? C.danger : detail.color;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: SvgIcon(
                    detail.icon,
                    size: 22,
                    color: color,
                    strokeWidth: 2.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail.name,
                    style: T.display(
                      size: 19,
                      weight: FontWeight.w800,
                      color: C.text,
                    ),
                  ),
                ),
                Text(
                  '$value',
                  style: T.display(
                    size: 26,
                    weight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(R.pill),
              child: SizedBox(
                height: 14,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: C.inset),
                    AnimatedFrac(
                      value: value / 100,
                      builder: (_, v) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: ColoredBox(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$value din 100',
                style: T.body(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: C.text3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detail.meaning,
              style: T.body(
                size: 13.5,
                weight: FontWeight.w500,
                color: C.text2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(R.sm),
                border: Border.all(color: C.line, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SvgIcon(
                    Ic.sparkles,
                    size: 16,
                    color: C.violetDeep,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail.tip,
                      style: T.body(
                        size: 12.5,
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
    );
  }
}

// Balanța animată (bani → lei formatat), reduce-motion aware.

class _MoneyCount extends StatelessWidget {
  const _MoneyCount({required this.value, required this.style});
  final Money value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(value.lei, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.bani.toDouble()),
      duration: Dur.base,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(Money(v.round()).lei, style: style),
    );
  }
}

// Foaia de eveniment (nu se închide la tap-outside).

class _EventSheet extends StatefulWidget {
  const _EventSheet({required this.event});
  final LifeSimEvent event;

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  // Trigger de bounce pentru Cashy: 0 -> 1 după primul frame, ca JuiceBounce
  // (care ignoră null -> valoare) să salte totuși la intrarea foii.
  int _bounce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _bounce = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JuiceBounce(
              trigger: _bounce,
              child: CashySprite(
                asset: cashyForIllustration(
                  event.illustration,
                  difficulty: event.difficulty,
                ),
                width: 88,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: T.display(
                size: 21,
                weight: FontWeight.w800,
                color: C.text,
              ),
            ),
            const SizedBox(height: 8),
            _IntensityChip(difficulty: event.difficulty),
            if (event.narrative.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                event.narrative,
                textAlign: TextAlign.center,
                style: T.body(
                  size: 14,
                  weight: FontWeight.w500,
                  color: C.text2,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 18),
            for (var i = 0; i < event.choices.length; i++) ...[
              StaggerIn(
                index: i,
                child: _ChoiceButton(
                  label: event.choices[i].label,
                  onTap: () => Navigator.of(context).pop(i),
                ),
              ),
              if (i != event.choices.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip de intensitate din difficulty: Ușor (verde) / Mediu (amber) / Șoc (roșu).
class _IntensityChip extends StatelessWidget {
  const _IntensityChip({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = difficulty >= 3
        ? ('Șoc', C.danger, C.dangerSoft)
        : difficulty == 2
        ? ('Mediu', C.amberDeep, C.amberSoft)
        : ('Ușor', C.greenDeep, C.greenSoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(R.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: T.display(size: 12, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatefulWidget {
  const _ChoiceButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Juice.tick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: reduceMotion ? Duration.zero : Dur.tap,
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line2, width: 1),
            boxShadow: Sh.raise,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: T.body(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SvgIcon(
                Ic.chevronRight,
                size: 18,
                color: C.text3,
                strokeWidth: 2.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Foaia de alocare a salariului.

class _AllocationSheet extends StatelessWidget {
  const _AllocationSheet({required this.salary, required this.cash});
  final Money salary;
  final Money cash;

  Money _pct(int percent) {
    final want = Money((salary.bani * percent / 100).round());
    return want > cash ? cash : want;
  }

  @override
  Widget build(BuildContext context) {
    // Presetări clamped la cash-ul disponibil. Total (fond+obiectiv) ≤ cash.
    final presets = <(String, String, Money, Money)>[
      ('Sar peste', 'Las tot ca lichid', Money.zero, Money.zero),
      (
        'Echilibrat',
        '20% fond · 10% obiectiv',
        _pct(20),
        _clampGoal(_pct(20), _pct(10)),
      ),
      (
        'Prudent',
        '35% fond · 5% obiectiv',
        _pct(35),
        _clampGoal(_pct(35), _pct(5)),
      ),
      (
        'Spre obiectiv',
        '10% fond · 25% obiectiv',
        _pct(10),
        _clampGoal(_pct(10), _pct(25)),
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SvgIcon(
                  Ic.coins,
                  size: 20,
                  color: C.greenDeep,
                  strokeWidth: 2.2,
                ),
                const SizedBox(width: 8),
                Text(
                  'A intrat salariul: ${salary.lei}',
                  style: T.display(
                    size: 17,
                    weight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pune deoparte înainte să cheltui, sau sari și înveți din consecințe.',
              style: T.body(
                size: 13,
                weight: FontWeight.w500,
                color: C.text2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            for (final p in presets) ...[
              _AllocOption(
                title: p.$1,
                subtitle: p.$2,
                toFund: p.$3,
                toGoal: p.$4,
                onTap: () => Navigator.of(context).pop((p.$3, p.$4)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Money _clampGoal(Money fund, Money goal) {
    final remaining = cash - fund;
    if (remaining.isNegative) return Money.zero;
    return goal > remaining ? remaining : goal;
  }
}

class _AllocOption extends StatelessWidget {
  const _AllocOption({
    required this.title,
    required this.subtitle,
    required this.toFund,
    required this.toGoal,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Money toFund;
  final Money toGoal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skip = toFund.isZero && toGoal.isZero;
    return GestureDetector(
      onTap: () {
        Juice.tick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: skip ? C.inset : C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line, width: 1),
          boxShadow: skip ? null : Sh.raise,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: T.display(
                      size: 15,
                      weight: FontWeight.w800,
                      color: C.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: T.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: C.text2,
                    ),
                  ),
                ],
              ),
            ),
            if (!skip)
              const SvgIcon(
                Ic.chevronRight,
                size: 18,
                color: C.text3,
                strokeWidth: 2.4,
              ),
          ],
        ),
      ),
    );
  }
}

// Foaia „Portofel", solduri + transferuri pe plicuri.

class _WalletSheet extends StatefulWidget {
  const _WalletSheet({required this.initial, required this.onChanged});

  final LifeSimState initial;

  /// Apelat cu starea nouă după fiecare mutare, ca ecranul principal să o
  /// reflecte și repository-ul să o persiste.
  final Future<void> Function(LifeSimState after) onChanged;

  @override
  State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  late LifeSimState _s = widget.initial;

  /// Suma rapidă selectată pentru mutări și plăți anticipate.
  Money _amount = const Money(10000); // 100 lei implicit

  /// Podeaua motorului pentru plata anticipată (nu scădem cash-ul sub asta).
  static const _debtFloor = Money(5000); // 50 lei

  void _apply(LifeSimState after) {
    if (identical(after, _s)) return; // motorul a întors starea neschimbată
    setState(() => _s = after);
    widget.onChanged(after);
  }

  void _move({required bool toFund}) {
    if (_s.cash < _amount) return;
    Juice.tick();
    _apply(
      engine.allocateSalary(
        _s,
        toFund: toFund ? _amount : Money.zero,
        toGoal: toFund ? Money.zero : _amount,
      ),
    );
  }

  void _payDebt(String id) {
    if (_s.cash < _debtFloor) return;
    Juice.tick();
    _apply(engine.payDebtEarly(_s, id, _amount));
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portofel',
              style: T.display(
                size: 19,
                weight: FontWeight.w800,
                color: C.text,
              ),
            ),
            const SizedBox(height: 14),
            _row('În buzunar', s.cash, C.text),
            _row('Fond de urgență', s.emergencyFund, C.greenDeep),
            _row('Obiectiv', s.goalSavings, C.blue),
            _row(
              'Datorii',
              s.totalDebt,
              s.totalDebt.isZero ? C.text3 : C.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'MUTĂ BANI',
              style: T.display(
                size: 11,
                weight: FontWeight.w800,
                color: C.text3,
                letterSpacing: 11 * 0.12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _amountChip(const Money(5000), '50'),
                const SizedBox(width: 8),
                _amountChip(const Money(10000), '100'),
                const SizedBox(width: 8),
                _amountChip(const Money(25000), '250'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _moveBtn(
                    '→ Fond',
                    C.green,
                    Sh.green,
                    s.cash >= _amount,
                    () => _move(toFund: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _moveBtn(
                    '→ Obiectiv',
                    C.blue,
                    Sh.blue,
                    s.cash >= _amount,
                    () => _move(toFund: false),
                  ),
                ),
              ],
            ),
            if (s.debts.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'DATORII',
                style: T.display(
                  size: 11,
                  weight: FontWeight.w800,
                  color: C.text3,
                  letterSpacing: 11 * 0.12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plătește anticipat ca să scazi principalul și dobânda viitoare.',
                style: T.body(
                  size: 12,
                  weight: FontWeight.w500,
                  color: C.text2,
                ),
              ),
              const SizedBox(height: 10),
              for (final d in s.debts) _debtRow(d),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Money value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: T.body(size: 14, weight: FontWeight.w600, color: C.text2),
        ),
        JuiceBounce(
          trigger: value.bani,
          child: Text(
            value.lei,
            style: T.display(size: 15, weight: FontWeight.w800, color: color),
          ),
        ),
      ],
    ),
  );

  Widget _amountChip(Money m, String label) {
    final selected = _amount.bani == m.bani;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Juice.tick();
          setState(() => _amount = m);
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? C.blueSoft : C.surface,
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(
              color: selected ? C.blue : C.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: T.display(
              size: 15,
              weight: FontWeight.w800,
              color: selected ? C.blue : C.text2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _moveBtn(
    String label,
    Color color,
    List<BoxShadow> shadow,
    bool enabled,
    VoidCallback onTap,
  ) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(color, Colors.white, 0.12)!, color],
            ),
            borderRadius: BorderRadius.circular(R.pill),
            boxShadow: enabled ? shadow : null,
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
      ),
    );
  }

  Widget _debtRow(DebtState d) {
    final enabled = _s.cash >= _debtFloor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        children: [
          const SvgIcon(Ic.coins, size: 16, color: C.danger, strokeWidth: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rată datorie',
                  style: T.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
                JuiceBounce(
                  trigger: d.principal.bani,
                  child: Text(
                    d.principal.lei,
                    style: T.display(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: C.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: GestureDetector(
              onTap: enabled ? () => _payDebt(d.id) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: C.dangerSoft,
                  borderRadius: BorderRadius.circular(R.pill),
                  border: Border.all(color: C.danger, width: 1),
                ),
                child: Text(
                  'Plătește',
                  style: T.display(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: C.dangerDeep,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Foaia „Calendar", recurente cu ziua scadenței.

class _CalendarSheet extends StatelessWidget {
  const _CalendarSheet({required this.state, required this.content});
  final LifeSimState state;
  final LifeSimContent content;

  @override
  Widget build(BuildContext context) {
    // Scadențe: (id, nume, sumă, ziua).
    final items = <(String, String, Money, int)>[];
    for (final id in state.bills) {
      final def = content.recurringById(id);
      if (def != null) items.add((id, def.name, def.amount, def.dueDay));
    }
    for (final d in state.debts) {
      items.add((d.id, 'Rată datorie', d.monthly, d.dueDay));
    }

    final restante = <(String, Money, int)>[]; // nume, sumă, ziua ratată
    for (final a in state.arrears) {
      final def = content.recurringById(a.$1);
      restante.add((def?.name ?? a.$1, def?.amount ?? Money.zero, a.$2));
    }
    restante.sort((a, b) => a.$3.compareTo(b.$3));

    final urmeaza = [
      for (final i in items)
        if (i.$4 > state.day) i,
    ]..sort((a, b) => a.$4.compareTo(b.$4));
    final trecute = [
      for (final i in items)
        if (i.$4 <= state.day) i,
    ]..sort((a, b) => a.$4.compareTo(b.$4));

    bool wasMissed(String id, int day) =>
        state.missedBills.any((m) => m.$1 == id && m.$2 == day);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendarul facturilor',
              style: T.display(
                size: 19,
                weight: FontWeight.w800,
                color: C.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ce ai plătit, ce urmează și ce a rămas restanță.',
              style: T.body(size: 13, weight: FontWeight.w500, color: C.text2),
            ),
            const SizedBox(height: 14),
            if (restante.isEmpty && urmeaza.isEmpty && trecute.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nicio recurentă activă.',
                  style: T.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: C.text3,
                  ),
                ),
              ),
            if (restante.isNotEmpty) ...[
              _section('Restanțe', C.danger),
              const SizedBox(height: 4),
              Text(
                'Se sting automat, cea mai veche prima, când intră bani.',
                style: T.body(
                  size: 12,
                  weight: FontWeight.w500,
                  color: C.text2,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in restante)
                _rowTile(
                  day: r.$3,
                  name: r.$1,
                  dayBg: C.dangerSoft,
                  dayColor: C.dangerDeep,
                  trailing: Text(
                    r.$2.lei,
                    style: T.display(
                      size: 14,
                      weight: FontWeight.w800,
                      color: C.danger,
                    ),
                  ),
                ),
            ],
            if (urmeaza.isNotEmpty) ...[
              const SizedBox(height: 6),
              _section('Urmează', C.blue),
              const SizedBox(height: 8),
              for (final i in urmeaza)
                _rowTile(
                  day: i.$4,
                  name: i.$2,
                  dayBg: C.blueSoft,
                  dayColor: C.blue,
                  trailing: Text(
                    i.$3.lei,
                    style: T.display(
                      size: 14,
                      weight: FontWeight.w800,
                      color: C.text2,
                    ),
                  ),
                ),
            ],
            if (trecute.isNotEmpty) ...[
              const SizedBox(height: 6),
              _section('Trecute', C.text3),
              const SizedBox(height: 8),
              for (final i in trecute)
                _rowTile(
                  day: i.$4,
                  name: i.$2,
                  dayBg: C.inset,
                  dayColor: C.text3,
                  trailing: wasMissed(i.$1, i.$4)
                      ? const SvgIcon(
                          Ic.alert,
                          size: 18,
                          color: C.danger,
                          strokeWidth: 2.2,
                        )
                      : const SvgIcon(
                          Ic.check,
                          size: 18,
                          color: C.green,
                          strokeWidth: 2.6,
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String label, Color color) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(
        label.toUpperCase(),
        style: T.display(
          size: 12,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 12 * 0.08,
        ),
      ),
    ],
  );

  Widget _rowTile({
    required int day,
    required String name,
    required Color dayBg,
    required Color dayColor,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dayBg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              'z$day',
              style: T.display(
                size: 13,
                weight: FontWeight.w800,
                color: dayColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.body(size: 14, weight: FontWeight.w700, color: C.text),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// Foaia „Obiectiv", progres.

class _GoalSheet extends StatelessWidget {
  const _GoalSheet({required this.state, required this.content});
  final LifeSimState state;
  final LifeSimContent content;

  @override
  Widget build(BuildContext context) {
    final goal = content.goalById(state.goalId);
    final target = state.goalTarget.bani;
    final saved = state.goalSavings.bani;
    final pct = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal?.name ?? 'Obiectivul lunii',
              style: T.display(
                size: 19,
                weight: FontWeight.w800,
                color: C.text,
              ),
            ),
            if (goal != null && goal.why.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                goal.why,
                style: T.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: C.text2,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(R.pill),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 14,
                backgroundColor: C.inset,
                valueColor: const AlwaysStoppedAnimation(C.blue),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.goalSavings.lei} strânși',
                  style: T.display(
                    size: 14,
                    weight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
                Text(
                  'din ${state.goalTarget.lei}',
                  style: T.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: C.text2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(pct * 100).round()}% atins',
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text3),
            ),
          ],
        ),
      ),
    );
  }
}
