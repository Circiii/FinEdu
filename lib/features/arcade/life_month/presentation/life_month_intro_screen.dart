import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/analytics/events.dart';
import '../../../../core/ui/clay.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../domain/engine/life_sim/life_sim_content.dart';
import '../../../wardrobe/presentation/cashy_avatar.dart';
import '../data/life_month_repository.dart';
import 'life_month_common.dart';

/// „30 de Zile", intro: alegi modul (ghidat/realist) + rolul (PageView), apoi
/// pornești. Dacă există o lună terminată, poți „Reia aceeași lună" (același
/// seed). După Start → cardul de identitate animat → „Începe luna".
class LifeMonthIntroScreen extends ConsumerStatefulWidget {
  const LifeMonthIntroScreen({super.key});

  @override
  ConsumerState<LifeMonthIntroScreen> createState() =>
      _LifeMonthIntroScreenState();
}

enum _Phase { select, identity }

class _LifeMonthIntroScreenState extends ConsumerState<LifeMonthIntroScreen> {
  _Phase _phase = _Phase.select;
  String _mode = 'ghidat';
  int _roleIndex = 0;
  final _pager = PageController(viewportFraction: 0.86);
  bool _starting = false;

  // Runda creată (pentru cardul de identitate + „Începe luna").
  LifeMonthRun? _run;
  LifeSimRole? _role;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  String _goalIdFor(LifeSimContent content, LifeSimRole role) {
    if (role.goalDefault.isNotEmpty &&
        content.goalById(role.goalDefault) != null) {
      return role.goalDefault;
    }
    return content.goals.isNotEmpty ? content.goals.first.id : role.goalDefault;
  }

  Future<void> _start(LifeSimContent content, {int? seed, bool replay = false}) async {
    if (_starting) return;
    Juice.tick();
    setState(() => _starting = true);
    final roles = content.roles;
    if (roles.isEmpty) {
      setState(() => _starting = false);
      return;
    }
    final role = roles[_roleIndex.clamp(0, roles.length - 1)];
    final repo = ref.read(lifeMonthRepositoryProvider);
    final run = await repo.createRun(
      content: content,
      roleId: role.id,
      goalId: _goalIdFor(content, role),
      mode: _mode,
      seed: seed,
    );
    ref.read(analyticsProvider).track(
      replay ? AnalyticsEvents.lifeSimReplayed : AnalyticsEvents.lifeSimStarted,
      {'role': role.id, 'mode': _mode, if (!replay) 'replay': false},
    );
    ref.invalidate(activeRunProvider);
    if (!mounted) return;
    setState(() {
      _run = run;
      _role = role;
      _phase = _Phase.identity;
      _starting = false;
    });
  }

  Future<void> _replayLast(LifeSimContent content, LifeMonthRun last) async {
    // Aliniem selecția la runda anterioară, apoi pornim cu același seed.
    final idx = content.roles.indexWhere((r) => r.id == last.state.roleId);
    setState(() {
      _mode = last.state.mode;
      if (idx >= 0) _roleIndex = idx;
    });
    await _start(content, seed: last.state.seed, replay: true);
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(lifeSimContentProvider);
    final lastCompleted = ref.watch(lastCompletedRunProvider).valueOrNull;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: contentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _errorState(),
              data: (content) {
                if (content.roles.isEmpty) return _emptyContentState();
                return _phase == _Phase.identity && _run != null && _role != null
                    ? _identity(content)
                    : _select(content, lastCompleted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nu am putut încărca luna. Încearcă din nou.',
              textAlign: TextAlign.center),
        ),
      );

  Widget _emptyContentState() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            lifeMonthTopBar(context, '30 de Zile'),
            const Spacer(),
            Image.asset(Cashy.cashyStudy, width: 120),
            const SizedBox(height: 14),
            Text('Luna se pregătește',
                style:
                    T.display(size: 22, weight: FontWeight.w800, color: C.text)),
            const SizedBox(height: 8),
            Text('Conținutul „30 de Zile" nu e încă disponibil.',
                textAlign: TextAlign.center,
                style: T.body(size: 14, weight: FontWeight.w500, color: C.text2)),
            const Spacer(),
          ],
        ),
      );

  // --- Selecția modului și a rolului ---------------------------------------

  Widget _select(LifeSimContent content, LifeMonthRun? last) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          lifeMonthTopBar(context, '30 de Zile'),
          const SizedBox(height: 6),
          Text('Pe Cont Propriu',
              style: T.display(size: 27, weight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 4),
          Text('Primești salariul. Următorul vine peste 30 de zile.',
              style: T.body(size: 14, weight: FontWeight.w500, color: C.text2)),
          const SizedBox(height: 18),
          _sectionLabel('CUM VREI SĂ JOCI'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  mode: 'ghidat',
                  emoji: '🧭',
                  title: 'Prima lună',
                  desc: 'Ghidat: vezi facturile viitoare, primești hint-uri.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeCard(
                  mode: 'realist',
                  emoji: '🎲',
                  title: 'Pe cont propriu',
                  desc: 'Realist: informație incompletă, consecințe întârziate.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('ALEGE-ȚI VIAȚA'),
          const SizedBox(height: 10),
          SizedBox(
            height: 316,
            child: PageView.builder(
              controller: _pager,
              itemCount: content.roles.length,
              onPageChanged: (i) => setState(() => _roleIndex = i),
              itemBuilder: (_, i) =>
                  _roleCard(content.roles[i], selected: i == _roleIndex),
            ),
          ),
          const SizedBox(height: 8),
          _dots(content.roles.length),
          const SizedBox(height: 18),
          if (last != null) ...[
            _replayButton(content, last),
            const SizedBox(height: 10),
          ],
          ClayButton(
            label: _starting ? 'Se pregătește...' : 'Începe',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 58,
            fontSize: 18,
            onTap: _starting ? null : () => _start(content),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: T.display(
          size: 11.5,
          weight: FontWeight.w800,
          color: C.text3,
          letterSpacing: 11.5 * 0.12));

  Widget _modeCard({
    required String mode,
    required String emoji,
    required String title,
    required String desc,
  }) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        Juice.tick();
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : Dur.fast,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? C.blueSoft : C.surface,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(
              color: selected ? C.blue : C.line, width: selected ? 2 : 1),
          boxShadow: selected ? Sh.raise : Sh.insetSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title,
                style: T.display(
                    size: 16, weight: FontWeight.w800, color: C.text)),
            const SizedBox(height: 4),
            Text(desc,
                style: T.body(
                    size: 12, weight: FontWeight.w500, color: C.text2,
                    height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(LifeSimRole role, {required bool selected}) {
    return AnimatedPadding(
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : Dur.fast,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: selected ? 0 : 10),
      child: ClayCard(
        radius: 24,
        shadow: selected ? Sh.card : Sh.raise,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(role.emoji.isEmpty ? '🙂' : role.emoji,
                    style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.display(
                              size: 19, weight: FontWeight.w800, color: C.text)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: C.greenSoft,
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                        child: Text('${role.scenarioNet.lei} net',
                            style: T.display(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: C.greenDeep)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _roleLine(Ic.home, lifeMonthHousingTransportLabel(role.housing)),
            const SizedBox(height: 6),
            _roleLine(Ic.bus, lifeMonthHousingTransportLabel(role.transport)),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                role.bio,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: T.body(
                    size: 13, weight: FontWeight.w500, color: C.text2,
                    height: 1.4),
              ),
            ),
            if (role.risks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: C.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SvgIcon(Ic.alert,
                        size: 15, color: C.amberDeep, strokeWidth: 2.2),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(role.risks,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: T.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: C.amberInk,
                              height: 1.3)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleLine(String icon, String text) => Row(
        children: [
          SvgIcon(icon, size: 16, color: C.text3, strokeWidth: 2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.body(size: 13, weight: FontWeight.w600, color: C.text2)),
          ),
        ],
      );

  Widget _dots(int count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: i == _roleIndex ? 20 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _roleIndex ? C.blue : C.line2,
                borderRadius: BorderRadius.circular(R.pill),
              ),
            ),
        ],
      );

  Widget _replayButton(LifeSimContent content, LifeMonthRun last) {
    return GestureDetector(
      onTap: _starting ? null : () => _replayLast(content, last),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(R.pill),
          border: Border.all(color: C.line, width: 1),
          boxShadow: Sh.raise,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SvgIcon(Ic.repeat, size: 18, color: C.violetDeep, strokeWidth: 2.2),
            const SizedBox(width: 8),
            Text('Reia aceeași lună',
                style: T.display(
                    size: 15, weight: FontWeight.w800, color: C.violetDeep)),
          ],
        ),
      ),
    );
  }

  // --- Cardul de identitate al rolului ------------------------------------

  Widget _identity(LifeSimContent content) {
    final role = _role!;
    final run = _run!;
    final goal = content.goalById(run.state.goalId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        children: [
          lifeMonthTopBar(context, '30 de Zile'),
          const Spacer(),
          LifeMonthScaleIn(
            child: ClayCard(
              radius: R.lg,
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CashyAvatar(asset: Cashy.cashyDefault, size: 92),
                  const SizedBox(height: 14),
                  Text(role.emoji.isEmpty ? role.name : '${role.emoji}  ${role.name}',
                      textAlign: TextAlign.center,
                      style: T.display(
                          size: 22, weight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 6),
                  Text(_mode == 'ghidat' ? 'Prima lună · ghidat' : 'Pe cont propriu · realist',
                      style: T.body(
                          size: 13, weight: FontWeight.w600, color: C.text2)),
                  const SizedBox(height: 16),
                  _identityRow('Salariu net', role.scenarioNet.lei),
                  _identityRow('În buzunar', run.state.cash.lei),
                  _identityRow('Fond de urgență', run.state.emergencyFund.lei),
                  if (goal != null)
                    _identityRow('Obiectiv', '${goal.name} (${goal.target.lei})'),
                  if (!run.state.totalDebt.isZero)
                    _identityRow('Datorii', run.state.totalDebt.lei,
                        accent: C.danger),
                ],
              ),
            ),
          ),
          const Spacer(),
          ClayButton(
            label: 'Începe luna',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 58,
            fontSize: 18,
            onTap: () {
              Juice.major();
              context.pushReplacement('/arcade/luna/joc', extra: run.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _identityRow(String label, String value, {Color accent = C.text}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: T.body(size: 13.5, weight: FontWeight.w600, color: C.text2)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.display(size: 14.5, weight: FontWeight.w800, color: accent)),
            ),
          ],
        ),
      );
}
