import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/flame.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/cashy_evolution.dart';
import '../../../domain/engine/leitner.dart';
import '../../../domain/engine/score_engine.dart';
import '../../arcade/data/arcade_repository.dart';
import '../../arcade/data/dojo_repository.dart';
import '../../gamification/data/evolution_providers.dart';
import '../../gamification/data/gamification_service.dart';
import '../../gamification/data/score_providers.dart';
import '../../home/data/home_providers.dart';
import '../../learning/data/lessons_repository.dart';
import '../../wardrobe/data/wardrobe_repository.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';

/// Ecranul de profil: identitate (Cashy + nivel/XP), scorul cu cei 4
/// factori, statisticile, uneltele și setarea de buget.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _cashyGradients = {
    'sky': [Color(0xFF7FD0F0), Color(0xFF2196C9)],
    'mint': [Color(0xFF4BE08A), C.greenDeep],
    'amber': [Color(0xFFFFCB63), C.amberDeep],
    'violet': [Color(0xFFB3A7FF), C.violetDeep],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(localProfileStreamProvider).valueOrNull;
    final score = ref.watch(scoreProvider).valueOrNull;
    final streak = ref.watch(streakViewProvider).valueOrNull;
    final done = ref.watch(completedLessonsProvider).valueOrNull ?? const {};
    final units = ref.watch(unitsProvider('ro')).valueOrNull ?? const [];
    final dojo = ref.watch(dojoStateProvider).valueOrNull;
    final turboBest = ref.watch(turboBestProvider).valueOrNull;
    final dailySolved = ref.watch(dailySolvedCountProvider).valueOrNull ?? 0;
    final activeDays =
        ref.watch(activityDaysProvider).valueOrNull?.length ?? 0;
    final carePts = ref.watch(carePointsProvider);

    final lessonsTotal = units.fold<int>(0, (n, u) => n + u.lessons.length);

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
                  Text('Profil',
                      style: T.display(
                          size: 24, weight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 14),
                  _hero(profile, carePts),
                  const SizedBox(height: 12),
                  _scoreSection(score),
                  const SizedBox(height: 12),
                  _evolutionCard(carePts),
                  const SizedBox(height: 12),
                  _statsGrid(
                    streakLongest: streak?.longest ?? 0,
                    activeDays: activeDays,
                    lessons: '${done.length}/$lessonsTotal',
                    belt: dojo == null || dojo.rounds == 0
                        ? ', '
                        : '${dojo.belt.$1} ${dojo.belt.$2}',
                    dailySolved: dailySolved,
                    turboBest: turboBest,
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('UNELTE'),
                  const SizedBox(height: 10),
                  _toolRow(context, Ic.repeat, 'Abonamente',
                      'Plățile care se repetă singure', '/recurring'),
                  const SizedBox(height: 10),
                  _toolRow(context, Ic.flame, 'Focul lui Cashy',
                      'Streak, gheață și borne', '/challenges'),
                  const SizedBox(height: 10),
                  _toolRow(context, Ic.book, 'Recapitularea lui Cashy',
                      'Cardurile tale scadente', '/review'),
                  const SizedBox(height: 16),
                  _sectionLabel('SETĂRI'),
                  const SizedBox(height: 10),
                  _budgetRow(context, ref, profile),
                  const SizedBox(height: 10),
                  _personalizationRow(context, ref, profile),
                  const SizedBox(height: 16),
                  _wardrobeEntry(context, ref),
                ],
              ),
            ),
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

  // ---- hero ----------------------------------------------------------------

  Widget _hero(LocalProfile? profile, int carePts) {
    final name = profile?.cashyName ?? 'Cashy';
    final xp = profile?.xp ?? 0;
    final acorns = profile?.acorns ?? 0;
    final level = levelForXp(xp);
    final grad = _cashyGradients[profile?.cashyColor] ??
        _cashyGradients['sky']!;

    final stage = stageFor(carePts);
    final next = nextStage(carePts);
    final progress = stageProgress(carePts);

    return ClayCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Garderoba îmbracă avatarul; fără fundal echipat rămâne culoarea de la onboarding.
          CashyAvatar(
              asset: Cashy.cashyDefault, size: 92, radius: 24, fallback: grad),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: T.display(
                        size: 22, weight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 4),
                Text('Nivel $level · ${fmtThousands(xp)} XP',
                    style: T.body(
                        size: 13, weight: FontWeight.w600, color: C.text2)),
                const SizedBox(height: 6),
                // Stadiul de evoluție: identitate + progres spre următorul.
                // JuiceBounce săltă titlul la creștere (trigger pe titlu, nu la primul load).
                if (next == null)
                  JuiceBounce(
                    trigger: stage.title,
                    child: AcornText('${stage.emoji} ${stage.title} · nivel maxim',
                        style: T.display(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: C.violetDeep)),
                  )
                else
                  Row(
                    children: [
                      JuiceBounce(
                        trigger: stage.title,
                        child: AcornText('${stage.emoji} ${stage.title}',
                            style: T.display(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: C.violetDeep)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(R.pill),
                          child: Container(
                            height: 6,
                            color: C.inset,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: C.violet,
                                  borderRadius: BorderRadius.circular(R.pill),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$carePts/${next.threshold}',
                          style: T.body(
                              size: 10.5,
                              weight: FontWeight.w600,
                              color: C.text3)),
                    ],
                  ),
                const SizedBox(height: 4),
                // Framing de identitate: „ai crescut", utilizatorul a făcut-o.
                Text('Ai crescut un ${stage.title}.',
                    style: T.body(
                        size: 11, weight: FontWeight.w600, color: C.text3)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: C.amberSoft,
                    borderRadius: BorderRadius.circular(R.pill),
                    border: Border.all(color: C.line, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AcornIcon(size: 15),
                      const SizedBox(width: 6),
                      Text('${fmtThousands(acorns)} ghinde',
                          style: T.display(
                              size: 13.5,
                              weight: FontWeight.w800,
                              color: C.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- evoluția lui Cashy --------------------------------------------------

  /// Cele 6 stadii ca chip-uri: atinse în culoare, viitoare gri, curent cu
  /// bordură violet. Fără cifre care împing „mai repede".
  Widget _evolutionCard(int carePts) {
    final current = stageFor(carePts);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('EVOLUȚIA LUI CASHY'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in cashyStages)
                _stageChip(
                  s,
                  reached: carePts >= s.threshold,
                  isCurrent: s.threshold == current.threshold,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'Punctele de grijă cresc din zilele active, lecții, streak, '
              'jocuri și cadourile pentru Cashy.',
              style: T.body(
                  size: 11.5, weight: FontWeight.w500, color: C.text3)),
        ],
      ),
    );
  }

  Widget _stageChip(CashyStage s,
      {required bool reached, required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: reached ? C.violetSoft : C.inset,
        borderRadius: BorderRadius.circular(R.pill),
        border: isCurrent ? Border.all(color: C.violet, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          reached
              ? AcornText(s.emoji, style: const TextStyle(fontSize: 15))
              : Opacity(
                  opacity: 0.45,
                  child:
                      AcornText(s.emoji, style: const TextStyle(fontSize: 15))),
          const SizedBox(width: 6),
          Text(s.title,
              style: T.display(
                  size: 12,
                  weight: FontWeight.w800,
                  color: reached ? C.violetDeep : C.text3)),
        ],
      ),
    );
  }

  // ---- score ---------------------------------------------------------------

  Widget _scoreSection(ScoreBreakdown? score) {
    final total = score?.total ?? 1;
    final factors = [
      ('Economii', score?.savingsFactor ?? 0, C.green),
      ('Buget', score?.budgetFactor ?? 0, C.amber),
      ('Constanță', score?.steadinessFactor ?? 0, C.blue),
      ('Cunoștințe', score?.knowledgeFactor ?? 0, C.violet),
    ];

    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            size: 15, weight: FontWeight.w800, color: C.text)),
                    const SizedBox(height: 4),
                    Text(scoreLevelLabel(total),
                        style: T.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: C.blue)),
                    const SizedBox(height: 2),
                    Text('Se recalculează din datele tale, live.',
                        style: T.body(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: C.text3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (label, value, color) in factors) ...[
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(label,
                      style: T.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: C.text2)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(R.pill),
                    child: Container(
                      height: 9,
                      color: C.inset,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (value / 100).clamp(0.02, 1.0),
                        child: Container(
                            decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(R.pill),
                          boxShadow: const [],
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text('$value',
                      textAlign: TextAlign.right,
                      style: T.display(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: C.text)),
                ),
              ],
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }

  // ---- stats ---------------------------------------------------------------

  Widget _statsGrid({
    required int streakLongest,
    required int activeDays,
    required String lessons,
    required String belt,
    required int dailySolved,
    required int? turboBest,
  }) {
    // SvgIcon înlocuiește emoji ca iconiță principală, dar rămân 🥋/⚡ unde
    // Ic.* nu are un fit bun (nicio centură/fulger în setul de iconițe).
    final stats = [
      (Ic.flame, '🔥', C.danger, 'Cel mai lung streak', '$streakLongest zile'),
      (Ic.clock, '📅', C.blue, 'Zile active', '$activeDays'),
      (Ic.book, '📚', C.sky, 'Lecții terminate', lessons),
      (null, '🥋', C.text, 'Centura Dojo', belt),
      (Ic.target, '🎯', C.violet, 'Provocări rezolvate', '$dailySolved'),
      (null, '⚡', C.text, 'Record Turbo', turboBest == null ? ', ' : '$turboBest'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: [
        for (final (icon, emoji, color, label, value) in stats)
          ClayCard(
            radius: 18,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                icon == null
                    ? Text(emoji, style: const TextStyle(fontSize: 20))
                    : icon == Ic.flame
                        ? const FlameIcon(size: 20)
                        : SvgIcon(icon, size: 20, color: color, strokeWidth: 2.1),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.display(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: C.text)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.body(
                              size: 10.5,
                              weight: FontWeight.w600,
                              color: C.text3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---- tools + settings -----------------------------------------------------

  Widget _toolRow(BuildContext context, String icon, String title,
      String subtitle, String route) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push(route);
      },
      child: ClayCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: C.blueSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: icon == Ic.flame
                  ? const FlameIcon(size: 22)
                  : SvgIcon(icon, size: 20, color: C.blue, strokeWidth: 2.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: T.display(
                          size: 14.5, weight: FontWeight.w800, color: C.text)),
                  Text(subtitle,
                      style: T.body(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: C.text3)),
                ],
              ),
            ),
            const SvgIcon(Ic.chevronRight,
                size: 17, color: C.text3, strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }

  Widget _budgetRow(
      BuildContext context, WidgetRef ref, LocalProfile? profile) {
    final budget = (profile?.monthlyBudget ?? 0).round();
    return GestureDetector(
      onTap: () {
        Juice.tick();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _BudgetSheet(current: budget),
        );
      },
      child: ClayCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: C.greenSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: const SvgIcon(Ic.wallet,
                  size: 20, color: C.green, strokeWidth: 2.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buget lunar',
                      style: T.display(
                          size: 14.5, weight: FontWeight.w800, color: C.text)),
                  Text('Ținta ta pentru luna curentă',
                      style: T.body(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: C.text3)),
                ],
              ),
            ),
            Text('${fmtThousands(budget)} lei',
                style: T.display(
                    size: 14.5, weight: FontWeight.w800, color: C.green)),
            const SizedBox(width: 6),
            const SvgIcon(Ic.chevronRight,
                size: 17, color: C.text3, strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }

  /// Gate de personalizare: opt-in explicit. Switch-ul deschide un sheet, doar
  /// „Activează" pornește profilarea (AADC/GDPR); oprirea e instantanee.
  Widget _personalizationRow(
      BuildContext context, WidgetRef ref, LocalProfile? profile) {
    final on = profile?.personalizationOn ?? false;
    Future<void> setOn(bool value) => ref
        .read(localProfileRepositoryProvider)
        .update(LocalProfilesCompanion(personalizationOn: Value(value)));

    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: C.violetSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: const Text('🧠', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personalizare inteligentă',
                    style: T.display(
                        size: 14.5, weight: FontWeight.w800, color: C.text)),
                Text(
                    on
                        ? 'Cashy învață local ce ți se potrivește'
                        : 'Oprită, nimic nu te profilează',
                    style: T.body(
                        size: 11.5, weight: FontWeight.w600, color: C.text3)),
              ],
            ),
          ),
          Switch(
            value: on,
            activeThumbColor: C.violet,
            activeTrackColor: C.violetSoft,
            onChanged: (v) async {
              if (!v) {
                await setOn(false);
                return;
              }
              // Aprindere = opt-in explicit prin sheet; se comută DOAR la „Activează".
              final accepted = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _PersonalizationSheet(),
              );
              if (accepted == true) await setOn(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _wardrobeEntry(BuildContext context, WidgetRef ref) {
    final ownedCount =
        ref.watch(ownedItemsProvider).valueOrNull?.length ?? 0;
    final catalogCount =
        ref.watch(wardrobeCatalogProvider('ro')).valueOrNull?.length;
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push('/garderoba');
      },
      child: ClayCard(
        radius: 22,
        shadow: Sh.raise,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: C.violetSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: const Text('👒', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Garderoba lui Cashy',
                      style: T.display(
                          size: 15, weight: FontWeight.w800, color: C.text)),
                  Text(
                      catalogCount == null
                          ? 'Fundaluri și accesorii pentru ghindele tale'
                          : '$ownedCount/$catalogCount în colecție',
                      style: T.body(
                          size: 12, weight: FontWeight.w600, color: C.text3)),
                ],
              ),
            ),
            const SvgIcon(Ic.chevronRight,
                size: 17, color: C.text3, strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }
}

/// Editor de buget, controller propriu; nu se dispose din opener-ul sheet-ului.
class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({required this.current});
  final int current;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current > 0 ? '${widget.current}' : '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) return;
    Juice.tick();
    await ref
        .read(localProfileRepositoryProvider)
        .update(LocalProfilesCompanion(monthlyBudget: Value(value.toDouble())));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bugetul tău lunar',
                style: T.display(
                    size: 19, weight: FontWeight.w800, color: C.text)),
            const SizedBox(height: 4),
            Text('Cât îți propui să cheltui într-o lună, în total.',
                style: T.body(
                    size: 13, weight: FontWeight.w500, color: C.text2)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: C.inset,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: T.display(
                    size: 22, weight: FontWeight.w800, color: C.text),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '800',
                  suffixText: 'lei',
                  suffixStyle: T.body(
                      size: 15, weight: FontWeight.w600, color: C.text3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ClayButton(
              label: 'Salvează',
              gradient: Grad.green,
              shadow: Sh.green,
              height: 54,
              fontSize: 16,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de consimțământ pentru personalizare: totul pe telefon, nimic în
/// cloud, oprire oricând. Întoarce `true` doar la „Activează".
class _PersonalizationSheet extends StatelessWidget {
  const _PersonalizationSheet();

  static const _violet = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB3A7FF), C.violet, C.violetDeep],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: C.violetSoft,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🧠', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Vrei să învăț ce ți se potrivește?',
                      style: T.display(
                          size: 18, weight: FontWeight.w800, color: C.text)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
                'Dacă pornești asta, mă uit la ce carduri și sfaturi te ajută '
                'cu adevărat și ți le arăt pe alea mai des. Fără să te bat la cap.',
                style: T.body(
                    size: 13.5, weight: FontWeight.w500, color: C.text2)),
            const SizedBox(height: 12),
            _point('📱', 'Totul se întâmplă PE telefonul tău.'),
            _point('☁️', 'Nimic nu pleacă în cloud, nici la mine, nici altundeva.'),
            _point('🎚️', 'O poți opri oricând, din același loc. Zero drama.'),
            const SizedBox(height: 18),
            ClayButton(
              label: 'Activează',
              gradient: _violet,
              shadow: Sh.violet,
              textColor: C.violetInk,
              height: 54,
              fontSize: 16,
              onTap: () {
                Juice.tick();
                Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: Text('Nu acum',
                    style: T.display(
                        size: 15, weight: FontWeight.w800, color: C.text3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(String emoji, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: T.body(
                      size: 12.5, weight: FontWeight.w600, color: C.text2)),
            ),
          ],
        ),
      );
}
