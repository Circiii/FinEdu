import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../gamification/data/gamification_service.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/lessons_repository.dart';
import 'interactives.dart';
import 'lesson_blocks.dart';
import 'lesson_widgets.dart';

/// Player-ul de lecții. Format 2.1: guess → concept(+check) → scenariu/exemplu
/// → interactiv → recap (reîntreabă dacă a fost ratat). Format 1 randează neschimbat.
class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonPlayerScreen> createState() =>
      _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  final _pages = PageController();
  int _page = 0;

  /// Indicii de pagină al căror gate de avansare a fost satisfăcut.
  final Set<int> _gatesOpen = {};

  /// Interactivul principal a fost ratat prima dată → recap-ul îl reîntreabă.
  bool _firstTryWrong = false;
  bool _celebrating = false;
  int _earnedXp = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ro';

  Lesson? _findLesson(List<LearnUnit> units) {
    for (final unit in units) {
      for (final lesson in unit.lessons) {
        if (lesson.id == widget.lessonId) return lesson;
      }
    }
    return null;
  }

  int _pageCount(Lesson l) => l.guess != null ? 5 : 4;

  /// Dacă [page] cere răspuns înainte de a avansa. Parcurge layout-ul:
  /// [guess?] → concept(+check?) → scenario|exemplu → interactiv → recap.
  bool _pageGated(Lesson l, int page) {
    var i = 0;
    if (l.guess != null) {
      if (page == i) return true;
      i++;
    }
    // Concept: blocurile se dezvăluie prin tap, apoi (dacă există) micro-check.
    if (page == i) return l.check != null || l.blocks != null;
    i++;
    if (page == i) return l.scenario != null;
    i++;
    if (page == i) return interactiveGatesAdvance(l.interactive.kind);
    return false;
  }

  bool _canAdvance(Lesson lesson) =>
      !_pageGated(lesson, _page) || _gatesOpen.contains(_page);

  void _openGate(int page) => setState(() => _gatesOpen.add(page));

  Future<void> _next(Lesson lesson) async {
    if (_page < _pageCount(lesson) - 1) {
      Juice.tick();
      setState(() => _page++);
      _pages.animateToPage(_page,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    // Final: completează + sărbătorește.
    final earned =
        await ref.read(learnRepositoryProvider).completeLesson(lesson);
    // Utilizatorul poate închide player-ul cât timp scrierea e în zbor.
    if (!mounted) return;
    ref.read(analyticsProvider).track(
        AnalyticsEvents.lessonComplete, {'lesson': lesson.id});
    ref.invalidate(questsViewProvider);
    setState(() {
      _earnedXp = earned ?? 0;
      _celebrating = true;
    });
    // Lecția completă e „major"; dacă tocmai a închis UNITATEA, e epic.
    // `earned > 0` = prima terminare a lecției, recitirile nu re-sărbătoresc.
    if (_earnedXp > 0 && await _unitJustCompleted(lesson) && mounted) {
      Juice.epic();
      ConfettiBurst.show(context);
    } else {
      Juice.major();
    }
  }

  Future<bool> _unitJustCompleted(Lesson lesson) async {
    final units = ref.read(unitsProvider(_locale)).valueOrNull ?? const [];
    final done =
        await ref.read(learnRepositoryProvider).watchCompleted().first;
    for (final u in units) {
      if (u.lessons.any((l) => l.id == lesson.id)) {
        return u.lessons.every((l) => done.contains(l.id));
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitsProvider(_locale)).valueOrNull;
    final lesson = units == null ? null : _findLesson(units);

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: lesson == null
                ? const SizedBox()
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                        child: Column(
                          children: [
                            _topBar(lesson),
                            const SizedBox(height: 8),
                            Expanded(
                              child: PageView(
                                controller: _pages,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  if (lesson.guess != null)
                                    _hookGuessPage(lesson),
                                  _conceptPage(lesson),
                                  if (lesson.scenario != null)
                                    _scenarioPage(lesson)
                                  else
                                    _examplePage(lesson),
                                  _interactivePage(lesson),
                                  _recapPage(lesson),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClayButton(
                              label: _page < _pageCount(lesson) - 1
                                  ? 'Continuă'
                                  : 'Finalizează · +${lesson.xp} XP',
                              gradient: _page < _pageCount(lesson) - 1
                                  ? Grad.blue
                                  : Grad.green,
                              shadow: _page < _pageCount(lesson) - 1
                                  ? Sh.blue
                                  : Sh.green,
                              height: 58,
                              fontSize: 17,
                              onTap: _canAdvance(lesson)
                                  ? () => _next(lesson)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      if (_celebrating) _celebration(lesson),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(Lesson lesson) {
    return Row(
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
          child: Row(
            children: [
              for (var i = 0; i < _pageCount(lesson); i++) ...[
                Expanded(
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(
                        right: i < _pageCount(lesson) - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _page ? C.blue : C.line2,
                      borderRadius: BorderRadius.circular(R.pill),
                      boxShadow: const [],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Pagina 0 (doar 2.1): emoji + titlu + hook + sliderul de estimare,
  /// intrând eșalonat în ecran.
  Widget _hookGuessPage(Lesson lesson) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          StaggerIn(
            index: 0,
            child: Center(
                child:
                    Text(lesson.emoji, style: const TextStyle(fontSize: 46))),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            index: 1,
            child: Center(
              child: Text(lesson.title,
                  textAlign: TextAlign.center,
                  style: T.display(
                      size: 26,
                      weight: FontWeight.w800,
                      color: C.text,
                      height: 1.1)),
            ),
          ),
          const SizedBox(height: 8),
          StaggerIn(
            index: 2,
            child: Center(
              child: Text(lesson.hook,
                  textAlign: TextAlign.center,
                  style: T.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: C.blue,
                      height: 1.4)),
            ),
          ),
          const SizedBox(height: 18),
          StaggerIn(
            index: 3,
            child:
                GuessSlider(guess: lesson.guess!, onDone: (_) => _openGate(0)),
          ),
        ],
      ),
    );
  }

  Widget _conceptHeader(Lesson lesson) {
    if (lesson.guess != null) {
      // Hook-ul și-a avut deja pagina; conceptul se deschide cu eticheta lui.
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text('💡 IDEEA',
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: C.blue,
                letterSpacing: 12 * 0.12)),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
            child: Text(lesson.emoji, style: const TextStyle(fontSize: 46))),
        const SizedBox(height: 10),
        Center(
          child: Text(lesson.title,
              textAlign: TextAlign.center,
              style: T.display(
                  size: 26,
                  weight: FontWeight.w800,
                  color: C.text,
                  height: 1.1)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(lesson.hook,
              textAlign: TextAlign.center,
              style: T.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: C.blue,
                  height: 1.4)),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _conceptPage(Lesson lesson) {
    final pageIndex = lesson.guess != null ? 1 : 0;
    final check = lesson.check == null
        ? null
        : ConceptCheck(
            check: lesson.check!, onDone: (_) => _openGate(pageIndex));

    // Format 3: blocuri dezvăluite prin tap (segmenting), fără check,
    // gate-ul se deschide când ultimul bloc e vizibil.
    if (lesson.blocks != null) {
      return LessonBlocksPage(
        blocks: lesson.blocks!,
        header: _conceptHeader(lesson),
        trailing: check,
        onAllRevealed: () {
          if (lesson.check == null) _openGate(pageIndex);
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _conceptHeader(lesson),
          for (final paragraph in lesson.concept) ...[
            RichLessonText(paragraph,
                style: T.body(
                    size: 15.5,
                    weight: FontWeight.w400,
                    color: C.text2,
                    height: 1.55)),
            const SizedBox(height: 12),
          ],
          if (check != null) ...[
            const SizedBox(height: 6),
            check,
          ],
        ],
      ),
    );
  }

  Widget _scenarioPage(Lesson lesson) {
    final pageIndex = lesson.guess != null ? 2 : 1;
    return ScenarioDecision(
        scenario: lesson.scenario!, onDone: (_) => _openGate(pageIndex));
  }

  Widget _examplePage(Lesson lesson) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📌 EXEMPLU REAL',
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: C.amberDeep,
                letterSpacing: 12 * 0.12)),
        const SizedBox(height: 12),
        StaggerIn(
          child: ClayCard(
            radius: 22,
            padding: const EdgeInsets.all(20),
            child: RichLessonText(lesson.example,
                style: T.body(
                    size: 16,
                    weight: FontWeight.w500,
                    color: C.text,
                    height: 1.55)),
          ),
        ),
      ],
    );
  }

  Widget _interactivePage(Lesson lesson) {
    // Widget-urile specifice tipului sunt în interactives.dart; ele dețin
    // starea și deschid gate-ul prin callback.
    final pageIndex = lesson.guess != null ? 3 : 2;
    return buildInteractive(
      lesson.interactive,
      onDone: (_) => _openGate(pageIndex),
      onResult: (firstTryCorrect) {
        if (!firstTryCorrect) setState(() => _firstTryWrong = true);
      },
    );
  }

  Widget _recapPage(Lesson lesson) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('RECAPITULARE',
              style: T.display(
                  size: 12,
                  weight: FontWeight.w800,
                  color: C.green,
                  letterSpacing: 12 * 0.12)),
          const SizedBox(height: 12),
          for (var i = 0; i < lesson.recap.length; i++) ...[
            StaggerIn(
              index: i,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: C.green),
                    alignment: Alignment.center,
                    child: const SvgIcon(Ic.check,
                        size: 12, color: Colors.white, strokeWidth: 3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichLessonText(lesson.recap[i],
                        style: T.body(
                            size: 15,
                            weight: FontWeight.w600,
                            color: C.text,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          ClayCard(
            radius: R.md,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚀', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PASUL DE AZI',
                          style: T.display(
                              size: 11,
                              weight: FontWeight.w800,
                              color: C.blue,
                              letterSpacing: 11 * 0.12)),
                      const SizedBox(height: 5),
                      Text(lesson.action,
                          style: T.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: C.text,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Momentul de aur: o întrebare ratată mai primește o încercare, gratis.
          if (_firstTryWrong &&
              interactiveRetryable(lesson.interactive.kind)) ...[
            const SizedBox(height: 16),
            Text('🔁 PRINDE-O DE DATA ASTA',
                style: T.display(
                    size: 12,
                    weight: FontWeight.w800,
                    color: C.amberDeep,
                    letterSpacing: 12 * 0.12)),
            const SizedBox(height: 10),
            if (lesson.interactive.kind == 'cloze')
              ClozeInteractive(
                  it: lesson.interactive, compact: true, onDone: (_) {})
            else
              McqInteractive(
                  it: lesson.interactive, compact: true, onDone: (_) {}),
          ],
          if (lesson.teaser != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.violetSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.line, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ URMEAZĂ',
                      style: T.display(
                          size: 11,
                          weight: FontWeight.w800,
                          color: C.violetDeep,
                          letterSpacing: 11 * 0.12)),
                  const SizedBox(height: 4),
                  Text(lesson.teaser!,
                      style: T.body(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: C.text2,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _celebration(Lesson lesson) {
    return Container(
      color: C.bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CashySprite(asset: Cashy.cashyCelebrate, width: 200),
          const SizedBox(height: 12),
          Text(_earnedXp > 0 ? 'Lecție terminată!' : 'Deja o știai!',
              style:
                  T.display(size: 30, weight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 8),
          if (_earnedXp > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: C.amberSoft,
                borderRadius: BorderRadius.circular(R.pill),
                border: Border.all(color: C.line, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCount(
                      value: _earnedXp,
                      prefix: '+',
                      suffix: ' XP  ·  +5 ',
                      style: T.display(
                          size: 16, weight: FontWeight.w800, color: C.text)),
                  const AcornIcon(size: 18),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Cardurile lecției intră mâine în Recapitularea lui Cashy.',
              textAlign: TextAlign.center,
              style:
                  T.body(size: 13.5, weight: FontWeight.w500, color: C.text2)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClayButton(
              label: 'Continuă',
              gradient: Grad.blue,
              shadow: Sh.blue,
              height: 56,
              fontSize: 17,
              onTap: () {
                Juice.tick();
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
