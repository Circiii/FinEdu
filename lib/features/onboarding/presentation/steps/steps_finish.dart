import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

import '../../../../core/ui/clay.dart';
import '../../../../core/ui/juice.dart';
import '../../../../core/ui/category_icon.dart';
import '../../../../core/ui/svg_icon.dart';
import '../../../../core/ui/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import 'onb_shared.dart';

// ---- Prima cheltuială ghidată ----

class _Cat {
  const _Cat(this.key, this.icon, this.tint, this.color);

  final String key;
  final String icon;
  final Color tint;
  final Color color;
}

class ExpenseStep extends StatefulWidget {
  const ExpenseStep({
    super.key,
    required this.onExpense,
    required this.onNoSpend,
  });

  final void Function(double amount, String category) onExpense;
  final VoidCallback onNoSpend;

  @override
  State<ExpenseStep> createState() => _ExpenseStepState();
}

class _ExpenseStepState extends State<ExpenseStep> {
  double? _amount;
  String? _category;

  static const _amounts = [5, 10, 20, 50];
  static const _cats = [
    _Cat('mancare', Ic.heart, Color(0x26FF7A59), C.catFood),
    _Cat('transport', Ic.bus, Color(0x242B86FF), C.blue),
    _Cat('distractie', Ic.film, Color(0x26A78BFA), C.violet),
    _Cat('altele', Ic.plus, Color(0x229AABC5), C.text2),
  ];

  String _catLabel(AppLocalizations l10n, String key) => switch (key) {
        'mancare' => l10n.onbCatFood,
        'transport' => l10n.onbCatTransport,
        'distractie' => l10n.onbCatFun,
        _ => l10n.onbCatOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready = _amount != null && _category != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: OnbHeader(
                      kicker: l10n.onbExpenseKicker,
                      title: l10n.onbExpenseTitle,
                      body: l10n.onbExpenseBody,
                      accent: C.blue),
                ),
                const SizedBox(height: 20),
                Text(l10n.onbExpenseAmountLabel,
                    style: T.display(
                        size: 13, weight: FontWeight.w700, color: C.text2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final a in _amounts) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_amount != a.toDouble()) Juice.tick();
                            setState(() => _amount = a.toDouble());
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            margin: EdgeInsets.only(
                                right: a != _amounts.last ? 8 : 0),
                            decoration: BoxDecoration(
                              color: _amount == a.toDouble()
                                  ? C.blueSoft
                                  : C.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _amount == a.toDouble()
                                      ? C.blue
                                      : C.line,
                                  width: 1.5),
                              boxShadow: Sh.raise,
                            ),
                            alignment: Alignment.center,
                            child: Text('$a',
                                style: T.display(
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: _amount == a.toDouble()
                                        ? C.blueInk
                                        : C.text)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.onbExpenseCategoryLabel,
                    style: T.display(
                        size: 13, weight: FontWeight.w700, color: C.text2)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.9,
                  children: [
                    for (final cat in _cats)
                      GestureDetector(
                        onTap: () {
                          if (_category != cat.key) Juice.tick();
                          setState(() => _category = cat.key);
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _category == cat.key
                                ? C.surface
                                : C.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _category == cat.key
                                    ? C.blue
                                    : Colors.transparent,
                                width: 2),
                            boxShadow: Sh.raise,
                          ),
                          child: Row(
                            children: [
                              CategoryTileIcon(
                                  category: cat.key,
                                  fallbackPath: cat.icon,
                                  tint: cat.tint,
                                  color: cat.color,
                                  size: 34,
                                  radius: 11,
                                  iconSize: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_catLabel(l10n, cat.key),
                                    style: T.display(
                                        size: 14.5,
                                        weight: FontWeight.w700,
                                        color: C.text)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: widget.onNoSpend,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l10n.onbExpenseNoSpend,
                          style: T.display(
                              size: 15,
                              weight: FontWeight.w700,
                              color: C.blue)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ClayButton(
          label: ready
              ? l10n.onbExpenseCta(_amount!.round())
              : l10n.onbExpenseCtaDisabled,
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 60,
          fontSize: 18,
          onTap: ready
              ? () {
                  Juice.tick();
                  widget.onExpense(_amount!, _category!);
                }
              : null,
        ),
      ],
    );
  }
}

// ---- Progres inițial ("Prima Săptămână") ----

class WeekStep extends StatelessWidget {
  const WeekStep({super.key, required this.cashyName, required this.onDone});

  final String cashyName;
  final VoidCallback onDone;

  static const _total = 12;
  static const _done = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                OnbHalo(
                  accent: C.green,
                  size: 170,
                  child: Image.asset(Cashy.cashyCelebrate,
                      width: 132, fit: BoxFit.contain),
                ),
                OnbHeader(
                    kicker: l10n.onbWeekKicker,
                    title: l10n.onbWeekTitle(cashyName),
                    body: l10n.onbWeekBody,
                    accent: C.green),
                const SizedBox(height: 18),
                ClayCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.onbWeekProgress(_done, _total),
                              style: T.display(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: C.text)),
                          Text('${(_done / _total * 100).round()}%',
                              style: T.display(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: C.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 12 celule de progres; primele 2 sunt pre-completate.
                      Row(
                        children: [
                          for (var i = 0; i < _total; i++) ...[
                            Expanded(
                              child: Container(
                                height: 12,
                                margin: EdgeInsets.only(
                                    right: i < _total - 1 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: i < _done ? C.green : C.inset,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow:
                                      i < _done ? null : Sh.insetSoft,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _doneRow(l10n.onbWeekDoneEgg),
                      const SizedBox(height: 8),
                      _doneRow(l10n.onbWeekDoneQuiz),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 2),
                          const SvgIcon(Ic.clock,
                              size: 16, color: C.text3, strokeWidth: 2.2),
                          const SizedBox(width: 9),
                          Text(l10n.onbWeekTodo(_total - _done),
                              style: T.body(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: C.text2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ClayButton(
          label: l10n.onbWeekCta,
          gradient: Grad.green,
          shadow: Sh.green,
          height: 60,
          fontSize: 18,
          onTap: () {
            Juice.tick();
            onDone();
          },
        ),
      ],
    );
  }

  Widget _doneRow(String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: C.green,
          ),
          alignment: Alignment.center,
          child: const SvgIcon(Ic.check,
              size: 12, color: Colors.white, strokeWidth: 3),
        ),
        const SizedBox(width: 9),
        Text(label,
            style: T.body(size: 13.5, weight: FontWeight.w600, color: C.text)),
      ],
    );
  }
}

// ---- Soft-ask notificări ----

class NotifStep extends StatelessWidget {
  const NotifStep({
    super.key,
    required this.onYes,
    required this.onLater,
  });

  final VoidCallback onYes;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnbHalo(
                accent: C.blue,
                child: Image.asset(Cashy.cashyPoint,
                    width: 180, fit: BoxFit.contain),
              ),
              OnbHeader(
                  kicker: l10n.onbNotifKicker,
                  title: l10n.onbNotifTitle,
                  body: l10n.onbNotifBody,
                  accent: C.blue),
            ],
          ),
        ),
        ClayButton(
          label: l10n.onbNotifYes,
          gradient: Grad.blue,
          shadow: Sh.blue,
          height: 60,
          fontSize: 18,
          onTap: () {
            Juice.tick();
            onYes();
          },
          leading: const SvgIcon(Ic.bell,
              size: 20, color: Colors.white, strokeWidth: 2.4),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onLater,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(l10n.onbNotifLater,
                style: T.display(
                    size: 15, weight: FontWeight.w700, color: C.text3)),
          ),
        ),
      ],
    );
  }
}
