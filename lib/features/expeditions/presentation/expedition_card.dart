import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/expedition_rules.dart';
import '../../gamification/data/gamification_service.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/expeditions_repository.dart';

/// Secțiunea „Expediția lui Cashy" de pe Home. Randează după fază, dedusă
/// din providere; totul e defensiv (valueOrNull) ca Home să nu se blocheze.
class ExpeditionCard extends ConsumerWidget {
  const ExpeditionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-collect-ul expedițiilor vechi rulează o dată per sesiune; provider-ul e exception-proof.
    ref.watch(expeditionAutoCollectProvider);

    final chest = ref.watch(questsViewProvider).valueOrNull?.chest;
    final today = ref.watch(expeditionTodayProvider).valueOrNull;
    final now = DateTime.now();

    final phase = expeditionPhase(
      chestEarnedToday: chest?.earnedToday ?? false,
      departedAt: today?.departedAt,
      collected: today?.collectedAt != null,
      now: now,
    );

    return switch (phase) {
      ExpeditionPhase.locked => _locked(),
      ExpeditionPhase.ready => _ready(context, ref),
      ExpeditionPhase.away => _away(today!.departedAt),
      ExpeditionPhase.returned => _returned(context, ref, today!),
      ExpeditionPhase.collected => _collected(ref, today!),
    };
  }

  // ---- blocat

  Widget _locked() {
    return ClayCard(
      radius: R.md,
      color: C.surface2,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🎒', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Expediția lui Cashy',
                  style: T.display(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: C.text2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Termină cele 3 misiuni și Cashy pleacă după ghinde.',
                  style: T.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: C.text3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- gata de plecare

  Widget _ready(BuildContext context, WidgetRef ref) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CashySprite(asset: Cashy.cashyPoint, width: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cashy e gata de drum',
                      style: T.display(
                        size: 16,
                        weight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Se întoarce în ~6 ore cu ce găsește.',
                      style: T.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: C.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClayButton(
            label: 'Trimite-l în expediție',
            gradient: Grad.green,
            shadow: Sh.green,
            height: 48,
            fontSize: 15,
            onTap: () async {
              Juice.tick();
              final streak =
                  ref.read(streakViewProvider).valueOrNull?.current ?? 0;
              await ref
                  .read(expeditionsRepositoryProvider)
                  .depart(streak: streak);
            },
          ),
        ],
      ),
    );
  }

  // ---- plecat

  Widget _away(DateTime departedAt) {
    final back = departedAt.add(const Duration(hours: expeditionHours));
    final hh = back.hour.toString().padLeft(2, '0');
    final mm = back.minute.toString().padLeft(2, '0');
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🥾', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cashy e în expediție',
                  style: T.display(
                    size: 16,
                    weight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Se întoarce pe la $hh:$mm',
                  style: T.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: C.text2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vezi-ți de zi, se descurcă.',
                  style: T.body(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: C.text3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- întors

  Widget _returned(BuildContext context, WidgetRef ref, ExpeditionRow row) {
    final postcards =
        ref.watch(postcardsProvider('ro')).valueOrNull ?? const [];
    final postcard = postcards.isEmpty
        ? ''
        : postcards[postcardIndex(dayKey: row.day, count: postcards.length)];
    return ClayCard(
      radius: 22,
      color: C.amberSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CashySprite(asset: Cashy.cashyCelebrate, width: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'S-a întors!',
                      style: T.display(
                        size: 16,
                        weight: FontWeight.w800,
                        color: C.amberInk,
                      ),
                    ),
                    if (postcard.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        postcard,
                        style: T.body(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: C.text,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClayButton(
            label: 'Vezi ce-a adus · +${row.reward}',
            trailing: const AcornIcon(size: 17),
            gradient: Grad.amber,
            shadow: Sh.amber,
            height: 48,
            fontSize: 15,
            onTap: () async {
              Juice.major();
              await ref.read(expeditionsRepositoryProvider).collect();
            },
          ),
        ],
      ),
    );
  }

  // ---- ridicat

  Widget _collected(WidgetRef ref, ExpeditionRow row) {
    final postcards =
        ref.watch(postcardsProvider('ro')).valueOrNull ?? const [];
    final postcard = postcards.isEmpty
        ? ''
        : postcards[postcardIndex(dayKey: row.day, count: postcards.length)];
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: AcornText(
              postcard.isEmpty
                  ? 'Expediția de azi: +${row.reward} 🌰'
                  : 'Expediția de azi: +${row.reward} 🌰 · $postcard',
              style: T.body(
                size: 12.5,
                weight: FontWeight.w600,
                color: C.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
