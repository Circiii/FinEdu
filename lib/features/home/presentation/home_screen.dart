import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_db.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/cashy_mood.dart';
import '../../../core/ui/category_icon.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/cashy_state.dart';
import '../../../domain/engine/quest_engine.dart';
import '../../../domain/engine/score_engine.dart';
import '../../../domain/models/transaction.dart';
import '../../gamification/data/gamification_service.dart';
import '../../gamification/data/score_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../../expeditions/presentation/expedition_card.dart';
import '../../tracking/data/transactions_repository.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/home_providers.dart';
import 'insight_cards.dart';

/// Ecranul principal: buget, scor, misiuni, obiective, tranzacții recente
/// și „Pentru tine".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _monthsRo = [
    'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
    'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(localProfileStreamProvider).valueOrNull;
    final monthTx =
        ref.watch(monthTransactionsProvider).valueOrNull ?? const [];
    final recent =
        ref.watch(recentTransactionsProvider).valueOrNull ?? const [];
    final quests = ref.watch(questsViewProvider).valueOrNull;

    final budget = profile?.monthlyBudget;
    final spent = monthTx
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final streak = ref.watch(streakViewProvider).valueOrNull?.current ?? 0;
    final mood = moodFor(spentThisMonth: spent, monthlyBudget: budget);

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _greeting(context, profile, streak),
                  _budgetHero(context, budget, spent, monthTx),
                  const SizedBox(height: 12),
                  _scoreCard(context, ref),
                  const SizedBox(height: 12),
                  _questsCard(context, ref, quests),
                  const SizedBox(height: 14),
                  const ExpeditionCard(),
                  const SizedBox(height: 12),
                  _goalsCard(context, ref),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      Juice.tick();
                      context.push('/finbot');
                    },
                    child: _cashySpeech(profile, mood, budget),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Tranzacții recente'),
                  const SizedBox(height: 12),
                  _transactions(context, ref, recent),
                  const SizedBox(height: 18),
                  _sectionLabel('Pentru tine'),
                  const SizedBox(height: 12),
                  const InsightCardsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- greeting ----------------------------------------------------------

  Widget _greeting(
    BuildContext context,
    LocalProfile? profile,
    int streak,
  ) {
    final name = profile?.cashyName ?? 'Cashy';
    final acorns = profile?.acorns ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Veverița-ghid, mare și fără casetă: salută cu degetul întins.
              const CashySprite(asset: Cashy.cashyPoint, width: 78),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Salut! Eu sunt',
                      style: T.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: C.text2,
                          height: 1.0)),
                  Text(name,
                      style: T.display(
                          size: 21,
                          weight: FontWeight.w800,
                          color: C.text,
                          height: 1.2)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Juice.tick();
                  context.push('/challenges');
                },
                child: _chip(
                  bg: C.amberSoft,
                  border: C.line,
                  child: Row(children: [
                    const FlameIcon(size: 15),
                    const SizedBox(width: 5),
                    Text('$streak',
                        style: T.display(
                            size: 15, weight: FontWeight.w800, color: C.text)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              // Contorul „respiră" la ghinde câștigate; trigger nullable ca
              // primul load să nu numere ca recompensă.
              JuiceBounce(
                trigger: profile?.acorns,
                child: _chip(
                  bg: C.surface,
                  border: C.line,
                  shadow: Sh.raise,
                  child: Row(children: [
                    const AcornIcon(size: 15),
                    const SizedBox(width: 5),
                    Text(fmtThousands(acorns),
                        style: T.display(
                            size: 15, weight: FontWeight.w800, color: C.text)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
      {required Color bg,
      required Color border,
      List<BoxShadow>? shadow,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: border, width: 1),
        boxShadow: shadow,
      ),
      child: child,
    );
  }

  // ---- budget hero --------------------------------------------------------

  Widget _budgetHero(
    BuildContext context,
    double? budget,
    double spent,
    List<Transaction> monthTx,
  ) {
    final now = DateTime.now();
    final pct = (budget == null || budget <= 0)
        ? 0.0
        : (spent / budget).clamp(0.0, 1.0);
    final remain = budget == null ? null : (budget - spent);
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

    return ClayCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Buget lunar · ${_monthsRo[now.month - 1]}',
                  style: T.display(
                      size: 17, weight: FontWeight.w800, color: C.text)),
              Row(children: [
                Text(budget == null ? 'Setează bugetul' : 'Detalii',
                    style: T.body(
                        size: 12.5, weight: FontWeight.w700, color: C.text3)),
                const SizedBox(width: 3),
                const SvgIcon(Ic.chevronRight,
                    size: 14, color: C.text3, strokeWidth: 2.4),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RingGauge(
                size: 134,
                percent: pct,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(pct * 100).round()}%',
                        style: T.display(
                            size: 33,
                            weight: FontWeight.w800,
                            color: C.text,
                            height: 1.0)),
                    Text('folosit',
                        style: T.body(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: C.text3)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmtThousands(spent.round()),
                        style: T.display(
                            size: 40,
                            weight: FontWeight.w800,
                            color: C.text,
                            height: 1.0)),
                    const SizedBox(height: 3),
                    Text(
                        budget == null
                            ? 'cheltuiți luna asta'
                            : 'din ${fmtThousands(budget.round())} lei',
                        style: T.display(
                            size: 14, weight: FontWeight.w700, color: C.text3)),
                    const SizedBox(height: 14),
                    Row(children: [
                      _miniStat(
                        remain == null || remain >= 0
                            ? C.greenSoft
                            : C.dangerSoft,
                        remain == null
                            ? ', '
                            : '${fmtThousands(remain.round())} lei',
                        remain == null || remain >= 0
                            ? C.greenDeep
                            : C.dangerDeep,
                        remain != null && remain < 0 ? 'peste' : 'rămân',
                      ),
                      const SizedBox(width: 8),
                      _miniStat(C.inset, '$daysLeft zile', C.text, 'reset'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          if (monthTx.any((t) => t.type == TransactionType.expense)) ...[
            const SizedBox(height: 18),
            Container(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: C.line, width: 1))),
              padding: const EdgeInsets.only(top: 14),
              child: _categoryBreakdown(monthTx),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryBreakdown(List<Transaction> monthTx) {
    final totals = <String, double>{};
    var total = 0.0;
    for (final t in monthTx) {
      if (t.type != TransactionType.expense) continue;
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
      total += t.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final restPct = sorted.skip(3).fold<double>(0, (s, e) => s + e.value);

    int pctOf(double v) => (v / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentBar(segments: [
          for (final e in top) (pctOf(e.value), _catVisual(e.key).color),
          if (restPct > 0) (pctOf(restPct), C.text3),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            for (final e in top)
              _legend(_catVisual(e.key).color,
                  '${_catVisual(e.key).label} ${pctOf(e.value)}%'),
          ],
        ),
      ],
    );
  }

  Widget _miniStat(Color bg, String value, Color valueColor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: T.display(
                    size: 15, weight: FontWeight.w800, color: valueColor)),
            Text(label,
                style:
                    T.body(size: 10.5, weight: FontWeight.w700, color: C.text2)),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: T.body(size: 11.5, weight: FontWeight.w600, color: C.text2)),
      ],
    );
  }

  // ---- scor ----

  Widget _scoreCard(BuildContext context, WidgetRef ref) {
    final score = ref.watch(scoreProvider).valueOrNull;
    final total = score?.total ?? 1;
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.go('/profil');
      },
      child: ClayCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ScoreGauge(
              percent: total / 100,
              center: Positioned(
                top: 22,
                left: 0,
                right: 0,
                child: Text('$total',
                    textAlign: TextAlign.center,
                    style: T.display(
                        size: 27, weight: FontWeight.w800, color: C.text)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scor FinEdu',
                      style: T.display(
                          size: 13, weight: FontWeight.w700, color: C.text2)),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: Grad.scorePill,
                      borderRadius: BorderRadius.circular(R.pill),
                      boxShadow: Sh.blue,
                    ),
                    child: Text(scoreLevelLabel(total),
                        style: T.display(
                            size: 13,
                            weight: FontWeight.w800,
                            color: C.blueInk)),
                  ),
                ],
              ),
            ),
            const SvgIcon(Ic.chevronRight,
                size: 18, color: C.text3, strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }

  // ---- misiunile zilei ----

  static String _questLabel(QuestId id) => switch (id) {
        QuestId.logToday => 'Loghează o cheltuială',
        // Id-ul rămâne `dojoRound` (persistat în ledger), dar orice joc din
        // Arcade îl bifează, toate marchează kind-ul 'game'.
        QuestId.dojoRound => 'Joacă un joc din Arcade',
        QuestId.noFunSpend => 'Zi fără cheltuieli pe distracție',
        QuestId.keepFlame => 'Ține focul aprins azi',
      };

  Widget _questsCard(BuildContext context, WidgetRef ref, QuestsView? view) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MISIUNILE ZILEI',
                  style: T.display(
                      size: 12,
                      weight: FontWeight.w700,
                      color: C.text3,
                      letterSpacing: 12 * 0.12)),
              if (view != null)
                Text('${view.chest.progress}/3',
                    style: T.display(
                        size: 12, weight: FontWeight.w800, color: C.text2)),
            ],
          ),
          const SizedBox(height: 12),
          if (view == null)
            Text('Se încarcă...',
                style: T.body(size: 13, weight: FontWeight.w600, color: C.text3))
          else ...[
            for (final q in view.quests) ...[
              _questRow(context, ref, q),
              const SizedBox(height: 10),
            ],
            _chestRow(context, ref, view.chest),
          ],
        ],
      ),
    );
  }

  Widget _questRow(BuildContext context, WidgetRef ref, QuestView q) {
    final showClaim = q.done && !q.claimed;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: q.claimed ? C.green : (q.done ? C.amber : C.inset),
            boxShadow: q.done || q.claimed ? null : Sh.insetSoft,
          ),
          alignment: Alignment.center,
          child: q.claimed || q.done
              ? const SvgIcon(Ic.check,
                  size: 13, color: Colors.white, strokeWidth: 3)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_questLabel(q.def.id),
              style: T.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: q.claimed ? C.text3 : C.text)),
        ),
        if (showClaim)
          GestureDetector(
            onTap: () async {
              final ok = await ref
                  .read(gamificationServiceProvider)
                  .claimQuest(q.def);
              ref.invalidate(questsViewProvider);
              if (ok) Juice.correct();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: AcornText('+${q.def.reward} 🌰',
                      style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  duration: const Duration(seconds: 1),
                  backgroundColor: C.text,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: Grad.amber,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: Sh.amber,
              ),
              child: AcornText('+${q.def.reward} 🌰',
                  style: T.display(
                      size: 12.5, weight: FontWeight.w800, color: Colors.white)),
            ),
          )
        else if (q.claimed)
          AcornText('+${q.def.reward} 🌰',
              style: T.display(
                  size: 12.5, weight: FontWeight.w700, color: C.text3)),
      ],
    );
  }

  Widget _chestRow(BuildContext context, WidgetRef ref, ChestView chest) {
    final String label;
    if (chest.openable) {
      label = 'Cufărul de ieri e gata, deschide-l!';
    } else if (chest.earnedToday) {
      label = 'Cufăr câștigat! Se deschide mâine.';
    } else {
      label = 'Bifează toate 3 → primești un cufăr';
    }
    return GestureDetector(
      onTap: chest.openable
          ? () async {
              final won =
                  await ref.read(gamificationServiceProvider).openChest();
              ref.invalidate(questsViewProvider);
              if (won != null) Juice.major();
              if (won != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🎁 +$won 🌰 din cufăr!',
                      style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  duration: const Duration(seconds: 2),
                  backgroundColor: C.text,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: chest.openable ? C.amberSoft : C.inset,
          borderRadius: BorderRadius.circular(R.sm),
          border: Border.all(
              color: chest.openable ? C.amber : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Text(chest.openable ? '🎁' : '📦',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: T.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: chest.openable ? C.amberInk : C.text2)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- obiective de economisire ----

  Widget _goalsCard(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsWithProgressProvider).valueOrNull ?? const [];
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OBIECTIVELE MELE',
                  style: T.display(
                      size: 12,
                      weight: FontWeight.w700,
                      color: C.text3,
                      letterSpacing: 12 * 0.12)),
              GestureDetector(
                onTap: () {
                  Juice.tick();
                  _createGoalSheet(context, ref);
                },
                child: Text('+ Nou',
                    style: T.display(
                        size: 12.5, weight: FontWeight.w800, color: C.blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            GestureDetector(
              onTap: () {
                Juice.tick();
                _createGoalSheet(context, ref);
              },
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Setează-ți primul obiectiv, Cashy strânge cu tine.',
                        style: T.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: C.text2)),
                  ),
                  const SvgIcon(Ic.chevronRight,
                      size: 16, color: C.text3, strokeWidth: 2.4),
                ],
              ),
            )
          else
            for (final g in goals.take(3)) ...[
              _goalRow(context, g),
              if (g != goals.take(3).last) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _goalRow(BuildContext context, GoalProgress g) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push('/add?type=saving&goal=${g.goal.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(g.goal.emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(g.goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.display(
                        size: 14.5, weight: FontWeight.w700, color: C.text)),
              ),
              Text(
                  g.reached
                      ? 'Atins! 🎉'
                      : '${fmtThousands(g.saved.round())} / ${fmtThousands(g.goal.targetAmount.round())} lei',
                  style: T.display(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: g.reached ? C.green : C.text2)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(R.pill),
            child: Container(
              height: 10,
              color: C.inset,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: g.pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: g.reached ? Grad.green : Grad.blue,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createGoalSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => const _GoalSheet(),
    );
  }

  // ---- cashy speech --------------------------------------------------------

  Widget _cashySpeech(LocalProfile? profile, CashyMood mood, double? budget) {
    final message = budget == null
        ? 'Setează-ți bugetul lunar și îți păzesc banii de-acum încolo.'
        : switch (mood) {
            CashyMood.happy => 'Arăți bine cu banii luna asta. Ține-o tot așa!',
            CashyMood.alert =>
              'Ai trecut de 80% din buget. O lăsăm mai încet cu cheltuielile?',
            CashyMood.worried =>
              'Bugetul e depășit luna asta. Hai să vedem împreună unde s-au dus banii.',
          };

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CashySprite(asset: mood.asset, width: 76),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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
              child: Text(message,
                  style: T.body(
                      size: 14,
                      weight: FontWeight.w400,
                      color: C.text2,
                      height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- sections ------------------------------------------------------------

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label.toUpperCase(),
          style: T.display(
              size: 12,
              weight: FontWeight.w700,
              color: C.text3,
              letterSpacing: 12 * 0.12)),
    );
  }

  // ---- transactions ---------------------------------------------------------

  Widget _transactions(
      BuildContext context, WidgetRef ref, List<Transaction> recent) {
    if (recent.isEmpty) {
      return ClayCard(
        radius: 22,
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const ClayIcon(
                path: Ic.plus,
                tint: C.blueSoft,
                color: C.blue,
                size: 44,
                radius: R.sm,
                iconSize: 22,
                strokeWidth: 2.4),
            const SizedBox(width: 13),
            Expanded(
              child: Text('Nicio tranzacție încă, apasă + și loghează prima.',
                  style: T.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: C.text2,
                      height: 1.4)),
            ),
          ],
        ),
      );
    }

    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Column(
        children: [
          for (final t in recent) _txRow(context, ref, t),
        ],
      ),
    );
  }

  Widget _txRow(BuildContext context, WidgetRef ref, Transaction t) {
    final visual = _catVisual(t.category);
    final saving = t.type == TransactionType.saving;
    final amountText = saving
        ? '+${_fmtLei(t.amount)} lei'
        : '−${_fmtLei(t.amount)} lei';

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            saving
                ? const ClayIcon(
                    path: Ic.coins,
                    tint: Color(0x2622C55E),
                    color: C.green,
                    size: 42,
                    radius: 13,
                    iconSize: 21,
                    strokeWidth: 2)
                : CategoryTileIcon(
                    category: t.category,
                    fallbackPath: visual.icon,
                    tint: visual.tint,
                    color: visual.color,
                    size: 42,
                    radius: 13,
                    iconSize: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.merchant ?? visual.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.display(
                          size: 15,
                          weight: FontWeight.w700,
                          color: C.text,
                          height: 1.1)),
                  const SizedBox(height: 2),
                  Text('${visual.label} · ${_relativeDate(t.transactionDate)}',
                      style: T.body(
                          size: 12, weight: FontWeight.w600, color: C.text3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amountText,
                style: T.display(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: saving ? C.green : C.text)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Ștergi tranzacția?',
            style: T.display(size: 18, weight: FontWeight.w800, color: C.text)),
        content: Text(
            '${t.merchant ?? _catVisual(t.category).label} · ${_fmtLei(t.amount)} lei',
            style: T.body(size: 14, weight: FontWeight.w600, color: C.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Nu',
                style:
                    T.display(size: 15, weight: FontWeight.w700, color: C.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Șterge',
                style: T.display(
                    size: 15, weight: FontWeight.w800, color: C.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(transactionsRepositoryProvider).softDelete(t.id);
    }
  }

  String _fmtLei(double v) {
    if (v == v.roundToDouble()) return fmtThousands(v.round());
    return '${fmtThousands(v.truncate())},${((v - v.truncate()) * 100).round().toString().padLeft(2, '0')}';
  }

  String _relativeDate(DateTime d) {
    final today = dayKey(DateTime.now());
    final yesterday =
        dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final key = dayKey(d);
    if (key == today) return 'azi';
    if (key == yesterday) return 'ieri';
    return '${d.day} ${_monthsRo[d.month - 1].substring(0, 3).toLowerCase()}';
  }

}

/// Sheet de creare obiectiv. StatefulWidget ca să disposăm controller-ul o
/// dată cu elementul sheet-ului, nu în timp ce fieldul încă animă ieșirea.
class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet();

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  final _name = TextEditingController();
  int _target = 300;
  String _emoji = '🎯';

  static const _targets = [100, 300, 600, 1000, 2000];
  static const _emojis = ['🎯', '📱', '✈️', '👟', '🎮', '💻'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 22, 20, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Obiectiv nou',
              style: T.display(size: 21, weight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: C.inset,
              borderRadius: BorderRadius.circular(16),
              boxShadow: Sh.insetSoft,
            ),
            child: TextField(
              controller: _name,
              maxLength: 24,
              style: T.display(size: 17, weight: FontWeight.w700, color: C.text),
              decoration: InputDecoration(
                hintText: 'ex. Căști noi',
                hintStyle:
                    T.display(size: 17, weight: FontWeight.w700, color: C.text3),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _targets)
                GestureDetector(
                  onTap: () {
                    if (_target != t) Juice.tick();
                    setState(() => _target = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: _target == t ? C.blueSoft : C.surface,
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(
                          color: _target == t ? C.blue : C.line, width: 1.5),
                    ),
                    child: Text('${fmtThousands(t)} lei',
                        style: T.display(
                            size: 13,
                            weight: FontWeight.w800,
                            color: _target == t ? C.blueInk : C.text2)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final e in _emojis)
                GestureDetector(
                  onTap: () {
                    if (_emoji != e) Juice.tick();
                    setState(() => _emoji = e);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _emoji == e ? C.blueSoft : C.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: _emoji == e ? C.blue : C.line, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClayButton(
            label: 'Creează obiectivul',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 54,
            fontSize: 16,
            onTap: () async {
              final n = _name.text.trim();
              if (n.isEmpty) return;
              Juice.tick();
              await ref.read(goalsRepositoryProvider).create(
                  name: n, targetAmount: _target.toDouble(), emoji: _emoji);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ---- Vizualele categoriilor (catalog local, temporar) ----

class _CatVisual {
  const _CatVisual(this.label, this.icon, this.tint, this.color);

  final String label;
  final String icon;
  final Color tint;
  final Color color;
}

_CatVisual _catVisual(String category) => switch (category) {
      'mancare' =>
        const _CatVisual('Mâncare', Ic.heart, Color(0x26FF7A59), C.catFood),
      'transport' =>
        const _CatVisual('Transport', Ic.bus, Color(0x242B86FF), C.blue),
      'distractie' =>
        const _CatVisual('Distracție', Ic.film, Color(0x26A78BFA), C.violet),
      'educatie' =>
        const _CatVisual('Educație', Ic.book, Color(0x242B86FF), C.sky),
      'haine' =>
        const _CatVisual('Haine', Ic.bag, Color(0x29FFB020), C.amber),
      'sanatate' =>
        const _CatVisual('Sănătate', Ic.heart, Color(0x2622C55E), C.green),
      'chirie' =>
        const _CatVisual('Chirie', Ic.home, Color(0x26A78BFA), C.violet),
      // Destinații de economisire (familia verde, bani puși deoparte, nu cheltuiți).
      'fond_urgenta' =>
        const _CatVisual('Fond urgență', Ic.shield, Color(0x2622C55E), C.green),
      'obiectiv' =>
        const _CatVisual('Obiectiv', Ic.target, Color(0x2622C55E), C.green),
      'investitii' =>
        const _CatVisual('Investiții', Ic.trending, Color(0x2622C55E), C.green),
      'pensie' => const _CatVisual(
          'Pe termen lung', Ic.clock, Color(0x2622C55E), C.green),
      'depozit' =>
        const _CatVisual('Depozit', Ic.wallet, Color(0x2622C55E), C.green),
      'altele_economii' =>
        const _CatVisual('Economii', Ic.coins, Color(0x2622C55E), C.green),
      _ => const _CatVisual('Altele', Ic.plus, Color(0x229AABC5), C.text2),
    };
