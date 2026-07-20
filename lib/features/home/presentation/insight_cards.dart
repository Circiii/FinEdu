import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/insight_rules.dart';
import '../../insights/data/insights_providers.dart';

/// Secțiunea „Pentru tine": 1-2 carduri de insight derivate local din datele utilizatorului.
class InsightCardsSection extends ConsumerWidget {
  const InsightCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ro';
    final cards = ref.watch(insightCardsProvider(locale)).valueOrNull;
    if (cards == null || cards.isEmpty) return const SizedBox();
    return Column(
      children: [
        for (final card in cards) ...[
          _InsightTile(card: card, locale: locale),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InsightTile extends ConsumerStatefulWidget {
  const _InsightTile({required this.card, required this.locale});
  final InsightCard card;
  final String locale;

  @override
  ConsumerState<_InsightTile> createState() => _InsightTileState();
}

class _InsightTileState extends ConsumerState<_InsightTile> {
  bool _showHow = false;

  Color get _accent => switch (widget.card.kind) {
    InsightKind.positive => C.green,
    InsightKind.corrective => C.amberDeep,
    InsightKind.utility => C.blue,
  };

  Future<void> _dismiss() async {
    await ref.read(insightsRepositoryProvider).record(widget.card, 'dismissed');
    ref.invalidate(insightCardsProvider(widget.locale));
  }

  Future<void> _openCta() async {
    Juice.tick();
    await ref.read(insightsRepositoryProvider).record(widget.card, 'tapped');
    if (mounted) context.push(widget.card.ctaRoute);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final dismissible = card.ruleKey != 'education';
    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.all(14),
      child: AnimatedSize(
        duration: Dur.base,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(card.emoji, style: const TextStyle(fontSize: 21)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: T.display(
                          size: 15,
                          weight: FontWeight.w800,
                          color: C.text,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.body,
                        style: T.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: C.text2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dismissible)
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: SvgIcon(
                        Ic.x,
                        size: 14,
                        color: C.text3,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Pressable(
                  haptic: false,
                  onTap: _openCta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      card.ctaLabel,
                      style: T.display(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (card.how != null)
                  GestureDetector(
                    onTap: () {
                      Juice.tick();
                      setState(() => _showHow = !_showHow);
                    },
                    child: Text(
                      _showHow ? 'Ascunde calculul' : 'Cum am calculat?',
                      style: T.body(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: C.text3,
                      ),
                    ),
                  ),
              ],
            ),
            if (_showHow && card.how != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.inset,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.how!,
                  style: T.body(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: C.text2,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
