import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/router/onboarding_gate.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_service.dart';
import 'steps/steps_finish.dart';
import 'steps/steps_intro.dart';
import 'steps/steps_profile.dart';

/// Wizard-ul de activare. Fiecare pas se persistă imediat prin [OnboardingService];
/// închiderea aplicației reia la primul pas incomplet.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnbStep? _step; // null până se încarcă pasul salvat
  String _cashyName = 'Cashy';
  String? _ageBand;

  OnboardingService get _service => ref.read(onboardingServiceProvider);

  @override
  void initState() {
    super.initState();
    _resume();
  }

  Future<void> _resume() async {
    final step = await _service.resumeStep();
    if (mounted) setState(() => _step = step);
  }

  void _track(String stepId, [Map<String, Object?> extra = const {}]) {
    ref.read(analyticsProvider).track(AnalyticsEvents.activationStep, {
      'step_id': stepId,
      ...extra,
    });
  }

  /// Secvența de pași vizibili, `parent` există doar pe ruta under-16.
  List<OnbStep> get _sequence => [
    OnbStep.egg,
    OnbStep.ceremony,
    OnbStep.quiz,
    OnbStep.age,
    if (_ageBand == '14_15') OnbStep.parent,
    OnbStep.budget,
    OnbStep.expense,
    OnbStep.week,
    OnbStep.notif,
  ];

  void _go(OnbStep step) => setState(() => _step = step);

  void _back() {
    final seq = _sequence;
    final i = seq.indexOf(_step!);
    if (i > 0) _go(seq[i - 1]);
  }

  Future<void> _finish() async {
    _track('done');
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: step == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 26),
                    child: Column(
                      children: [
                        _topRow(step),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            child: KeyedSubtree(
                              key: ValueKey(step),
                              child: _buildStep(step),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topRow(OnbStep step) {
    final seq = _sequence;
    final index = seq.indexOf(step);
    // Fără back după pașii gate (de la expense încolo se scriu date reale).
    final canGoBack =
        index > 0 && step != OnbStep.week && step != OnbStep.notif;

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: canGoBack
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _back,
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
                        child: const SvgIcon(
                          Ic.chevronLeft,
                          size: 18,
                          color: C.text2,
                          strokeWidth: 2.4,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < seq.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= index ? C.blue : C.line2,
                      borderRadius: BorderRadius.circular(R.pill),
                      // lerp-ul din flutter_inset_shadow are nevoie de listă non-null cât timp animă.
                      boxShadow: const [],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildStep(OnbStep step) {
    final l10n = AppLocalizations.of(context)!;
    switch (step) {
      case OnbStep.egg:
        return EggStep(
          onHatched: () {
            _track('egg_hatched');
            _go(OnbStep.ceremony);
          },
        );

      case OnbStep.ceremony:
        return CeremonyStep(
          onDone: (name, color) async {
            await _service.saveCeremony(name: name, color: color);
            _cashyName = name;
            _track('ceremony_done');
            _go(OnbStep.quiz);
          },
        );

      case OnbStep.quiz:
        return QuizStep(
          onDone: (answers, correct) async {
            await _service.saveQuiz(answers);
            _track('quiz_done', {'correct_n': correct});
            _go(OnbStep.age);
          },
        );

      case OnbStep.age:
        return AgeStep(
          onDone: (birthYear) async {
            final band = await _service.saveAge(birthYear);
            if (band == null) return; // panoul „prea tânăr" e intern pasului
            _ageBand = band;
            _track('age_set', {'band': band});
            _go(band == '14_15' ? OnbStep.parent : OnbStep.budget);
          },
        );

      case OnbStep.parent:
        return ParentStep(
          onDone: (email) async {
            await _service.saveParentEmail(email);
            _track('parent_email_set');
            _go(OnbStep.budget);
          },
        );

      case OnbStep.budget:
        return BudgetStep(
          onDone: (value) async {
            await _service.saveBudget(value);
            _track('budget_set', {'bucket': _budgetBucket(value)});
            _go(OnbStep.expense);
          },
        );

      case OnbStep.expense:
        return ExpenseStep(
          onExpense: (amount, category) async {
            await _service.logFirstExpense(amount: amount, category: category);
            _track('first_expense');
            ref.read(analyticsProvider).track(AnalyticsEvents.expenseLogged, {
              'source': 'onboarding',
              'category': category,
            });
            _go(OnbStep.week);
          },
          onNoSpend: () async {
            await _service.markNoSpend();
            _track('first_expense', {'no_spend': true});
            ref.read(analyticsProvider).track(AnalyticsEvents.noSpendMarked, {
              'source': 'onboarding',
            });
            _go(OnbStep.week);
          },
        );

      case OnbStep.week:
        return WeekStep(
          cashyName: _cashyName,
          onDone: () async {
            await _service.completeWeekStep();
            OnboardingGate.done = true;
            _track('endowed_shown');
            _go(OnbStep.notif);
          },
        );

      case OnbStep.notif:
        return NotifStep(
          onYes: () async {
            await _service.saveNotifChoice('accepted');
            _track('notif_choice', {'choice': 'accepted'});
            final notifications = ref.read(notificationsServiceProvider);
            final granted = await notifications.requestPermission();
            if (granted) {
              await notifications.scheduleTomorrowReminder(
                title: l10n.onbNotifReminderTitle(_cashyName),
                body: l10n.onbNotifReminderBody,
              );
            }
            await _finish();
          },
          onLater: () async {
            await _service.saveNotifChoice('later');
            _track('notif_choice', {'choice': 'later'});
            await _finish();
          },
        );
    }
  }

  /// Bucket aproximativ pentru analytics, niciodată suma exactă (AADC/minori).
  String _budgetBucket(double v) {
    if (v < 500) return '<500';
    if (v < 1000) return '500-999';
    if (v < 2000) return '1000-1999';
    return '2000+';
  }
}
