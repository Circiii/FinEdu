import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/leitner.dart';
import '../../home/data/home_providers.dart';
import '../data/lessons_repository.dart';
import 'unit_path_screen.dart' show unitLook;

/// Ecranul „Învață": HUD de XP/nivel, banner de recapitulare și unitățile ca
/// listă compactă. Traseul lecțiilor se deschide per unitate, fără scroll lung.
class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ro';
    final units = ref.watch(unitsProvider(locale)).valueOrNull ?? const [];
    final done = ref.watch(completedLessonsProvider).valueOrNull ?? const {};
    final due = ref.watch(dueCardsCountProvider).valueOrNull ?? 0;
    final profile = ref.watch(localProfileStreamProvider).valueOrNull;
    final xp = profile?.xp ?? 0;

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
                  Text(
                    'Învață',
                    style: T.display(
                      size: 24,
                      weight: FontWeight.w800,
                      color: C.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _hud(
                    xp,
                    done.length,
                    units.fold<int>(0, (n, u) => n + u.lessons.length),
                  ),
                  if (due > 0) ...[
                    const SizedBox(height: 12),
                    _reviewBanner(context, due),
                  ],
                  const SizedBox(height: 6),
                  ..._unitCards(context, units, done),
                  const SizedBox(height: 12),
                  _comingSoon(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hud(int xp, int doneCount, int totalCount) {
    final level = levelForXp(xp);
    final inLevel = xpInLevel(xp);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(Cashy.cashyStudy, width: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nivel $level',
                      style: T.display(
                        size: 16,
                        weight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                    Text(
                      '$inLevel / 300 XP',
                      style: T.display(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: C.text3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.pill),
                  child: Container(
                    height: 10,
                    color: C.inset,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (inLevel / 300).clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: Grad.blue,
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$doneCount din $totalCount lecții · ${fmtThousands(xp)} XP',
                  style: T.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: C.text2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewBanner(BuildContext context, int due) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        context.push('/review');
      },
      child: ClayCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Image.asset(Cashy.cashyPoint, width: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recapitularea lui Cashy',
                    style: T.display(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: C.text,
                    ),
                  ),
                  Text(
                    due == 1
                        ? 'Un card te așteaptă azi'
                        : '$due carduri te așteaptă azi',
                    style: T.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: C.text2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: Grad.amber,
                borderRadius: BorderRadius.circular(R.pill),
                boxShadow: Sh.amber,
              ),
              child: Text(
                'Începe',
                style: T.display(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Unitățile ca listă de carduri; unitatea N+1 se deblochează doar când
  /// toate lecțiile unității N sunt completate. Tap = traseul unității.
  List<Widget> _unitCards(
    BuildContext context,
    List<LearnUnit> units,
    Set<String> done,
  ) {
    final cards = <Widget>[];
    var unlocked = true;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      final isComplete = unit.lessons.every((l) => done.contains(l.id));
      cards
        ..add(const SizedBox(height: 10))
        ..add(
          StaggerIn(
            index: i,
            child: _unitCard(
              context,
              unit,
              done,
              unlocked: unlocked,
              active: unlocked && !isComplete,
            ),
          ),
        );
      unlocked = unlocked && isComplete;
    }
    return cards;
  }

  Widget _unitCard(
    BuildContext context,
    LearnUnit unit,
    Set<String> done, {
    required bool unlocked,
    required bool active,
  }) {
    final doneIn = unit.lessons.where((l) => done.contains(l.id)).length;
    final look = unitLook(unit.color);

    return GestureDetector(
      onTap: () {
        Juice.tick();
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔒 Termină unitatea anterioară ca să o deblochezi',
                style: T.display(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: C.text,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        context.push('/learn/unit/${unit.id}');
      },
      child: ClayCard(
        radius: 20,
        gradient: unlocked ? look.gradient : null,
        color: unlocked ? C.surface : C.inset,
        shadow: unlocked ? look.shadow : Sh.insetSoft,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(
              unit.emoji,
              style: TextStyle(fontSize: 26, color: unlocked ? null : C.text3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unitatea ${unit.ord} · ${unit.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.display(
                      size: 15,
                      weight: FontWeight.w800,
                      color: unlocked ? Colors.white : C.text3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$doneIn din ${unit.lessons.length} lecții',
                    style: T.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: unlocked ? Colors.white70 : C.text3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!unlocked)
              const SvgIcon(Ic.lock, size: 18, color: C.text3, strokeWidth: 2.2)
            else if (active)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(R.pill),
                ),
                child: Text(
                  'Continuă',
                  style: T.display(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const SvgIcon(
                Ic.chevronRight,
                size: 18,
                color: Colors.white,
                strokeWidth: 2.4,
              ),
          ],
        ),
      ),
    );
  }

  Widget _comingSoon() {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unitatea 8 · Banii împrumutați, în curând',
              style: T.body(size: 13, weight: FontWeight.w600, color: C.text3),
            ),
          ),
        ],
      ),
    );
  }
}
