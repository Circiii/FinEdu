import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/db/app_db.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/lessons_repository.dart';

/// „Recapitularea lui Cashy": carduri due, recall activ cu auto-notare
/// (Leitner). Retrieval-ul e scopul, programul doar îl servește.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ReviewCard>? _queue;
  int _index = 0;
  bool _revealed = false;
  int _known = 0;
  bool _finished = false;

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final cards = await ref.read(learnRepositoryProvider).dueCards();
    if (mounted) setState(() => _queue = cards);
  }

  Future<void> _grade(bool known) async {
    final repo = ref.read(learnRepositoryProvider);
    await repo.grade(_queue![_index], known: known);
    if (known) _known++;
    if (_index + 1 >= _queue!.length) {
      await repo.finishReviewSession(_queue!.length);
      ref.read(analyticsProvider).track(
          AnalyticsEvents.reviewDone, {'cards': _queue!.length, 'known': _known});
      setState(() => _finished = true);
    } else {
      setState(() {
        _index++;
        _revealed = false;
      });
    }
  }

  ConceptCard? _content(List<LearnUnit> units, String cardId) {
    for (final unit in units) {
      for (final lesson in unit.lessons) {
        for (final card in lesson.cards) {
          if (card.id == cardId) return card;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitsProvider(_locale)).valueOrNull;
    final queue = _queue;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: queue == null || units == null
                  ? const SizedBox()
                  : _finished
                      ? _done()
                      : queue.isEmpty
                          ? _empty()
                          : _card(units, queue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<LearnUnit> units, List<ReviewCard> queue) {
    final card = queue[_index];
    final content = _content(units, card.cardId);
    return Column(
      children: [
        Row(
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
                child: const SvgIcon(Ic.x,
                    size: 16, color: C.text2, strokeWidth: 2.4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Recapitulare · ${_index + 1} din ${queue.length}',
                  style: T.display(
                      size: 17, weight: FontWeight.w800, color: C.text)),
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Cashy.cashyStudy, width: 84),
              const SizedBox(height: 16),
              ClayCard(
                radius: 24,
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text(content?.question ?? '',
                        textAlign: TextAlign.center,
                        style: T.display(
                            size: 19,
                            weight: FontWeight.w700,
                            color: C.text,
                            height: 1.3)),
                    if (_revealed) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: C.inset,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: Sh.insetSoft,
                        ),
                        child: Text(content?.answer ?? '',
                            textAlign: TextAlign.center,
                            style: T.body(
                                size: 15,
                                weight: FontWeight.w600,
                                color: C.text2,
                                height: 1.45)),
                      ),
                    ],
                  ],
                ),
              ),
              // Transparență FSRS: stabilitatea reală („cât ține memoria"), doar
              // după migrarea la FSRS (stability != null).
              if (card.stability != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                      '💾 Stabilitatea memoriei: ~${card.stability!.round()} zile',
                      textAlign: TextAlign.center,
                      style: T.body(size: 11, weight: FontWeight.w600, color: C.text3)),
                ),
            ],
          ),
        ),
        if (!_revealed)
          ClayButton(
            label: 'Arată răspunsul',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 58,
            fontSize: 17,
            onTap: () => setState(() => _revealed = true),
          )
        else
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: 'N-am știut',
                  gradient: Grad.amber,
                  shadow: Sh.amber,
                  height: 58,
                  fontSize: 16,
                  onTap: () => _grade(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClayButton(
                  label: 'Știam!',
                  gradient: Grad.green,
                  shadow: Sh.green,
                  height: 58,
                  fontSize: 16,
                  onTap: () => _grade(true),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _done() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CashySprite(asset: Cashy.cashyCelebrate, width: 190),
        const SizedBox(height: 12),
        Text('Recapitulare gata!',
            style: T.display(size: 28, weight: FontWeight.w800, color: C.text)),
        const SizedBox(height: 6),
        AcornText('$_known din ${_queue!.length} știute · +3 🌰',
            style: T.display(size: 16, weight: FontWeight.w700, color: C.text2)),
        const SizedBox(height: 8),
        Text('Ce n-ai știut revine mâine. Ce ai știut, peste câteva zile.',
            textAlign: TextAlign.center,
            style: T.body(size: 13.5, weight: FontWeight.w500, color: C.text2)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClayButton(
            label: 'Închide',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 56,
            fontSize: 17,
            onTap: () => context.pop(),
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(Cashy.cashyDefault, width: 170),
        const SizedBox(height: 12),
        Text('Nimic de recapitulat azi',
            style: T.display(size: 22, weight: FontWeight.w800, color: C.text)),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClayButton(
            label: 'Înapoi',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 54,
            fontSize: 16,
            onTap: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
