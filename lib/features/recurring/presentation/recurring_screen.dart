import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_db.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/util/day_key.dart';
import '../data/recurring_repository.dart';

/// Abonamente / tranzacții recurente: listă + toggle + adăugare + ștergere;
/// materializarea se întâmplă la pornirea aplicației (main.dart).
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  static const _freqRo = {
    'daily': 'zilnic',
    'weekly': 'săptămânal',
    'monthly': 'lunar',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringListProvider).valueOrNull ?? const [];

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
                          child: const SvgIcon(
                            Ic.chevronLeft,
                            size: 18,
                            color: C.text2,
                            strokeWidth: 2.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Abonamente',
                        style: T.display(
                          size: 24,
                          weight: FontWeight.w800,
                          color: C.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Plățile care se repetă. Le adăugăm automat când vine scadența.',
                      style: T.body(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: C.text2,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _empty(context, ref)
                  else
                    for (final item in items) ...[
                      _recurringRow(context, ref, item),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 8),
                  ClayButton(
                    label: 'Adaugă un abonament',
                    gradient: Grad.blue,
                    shadow: Sh.blue,
                    height: 54,
                    fontSize: 16,
                    leading: const SvgIcon(
                      Ic.plus,
                      size: 19,
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
                    onTap: () {
                      Juice.tick();
                      _addSheet(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return ClayCard(
      radius: R.md,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SvgIcon(Ic.repeat, size: 26, color: C.text3, strokeWidth: 2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Niciun abonament încă. Netflix, sală, telefon, adaugă-le o dată și Cashy le ține minte.',
              style: T.body(
                size: 13.5,
                weight: FontWeight.w600,
                color: C.text2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recurringRow(
    BuildContext context,
    WidgetRef ref,
    LocalRecurringData item,
  ) {
    final saving = item.type == 'saving';
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          saving
              ? Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x2622C55E),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: const AcornIcon(size: 22),
                )
              : const ClayIcon(
                  path: Ic.repeat,
                  tint: C.blueSoft,
                  color: C.blue,
                  size: 42,
                  radius: 13,
                  iconSize: 20,
                  strokeWidth: 2,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.display(
                    size: 15,
                    weight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_freqRo[item.frequency]} · ${fmtThousands(item.amount.round())} lei · urm. ${_shortDate(item.nextDueDate)}',
                  style: T.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: C.text3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: item.active,
            activeThumbColor: C.blue,
            onChanged: (v) =>
                ref.read(recurringRepositoryProvider).setActive(item.id, v),
          ),
          GestureDetector(
            onTap: () => ref.read(recurringRepositoryProvider).remove(item.id),
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: SvgIcon(Ic.x, size: 16, color: C.text3, strokeWidth: 2.2),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String key) {
    final d = DateTime.parse(key);
    const m = [
      'ian',
      'feb',
      'mar',
      'apr',
      'mai',
      'iun',
      'iul',
      'aug',
      'sep',
      'oct',
      'noi',
      'dec',
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  Future<void> _addSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _RecurringSheet(),
    );
  }
}

class _RecurringSheet extends ConsumerStatefulWidget {
  const _RecurringSheet();

  @override
  ConsumerState<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends ConsumerState<_RecurringSheet> {
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  String _frequency = 'monthly';

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abonament nou',
            style: T.display(size: 21, weight: FontWeight.w800, color: C.text),
          ),
          const SizedBox(height: 14),
          _field(_merchant, 'Nume (ex. Netflix)'),
          const SizedBox(height: 10),
          _field(
            _amount,
            'Sumă (lei)',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final f in const ['daily', 'weekly', 'monthly'])
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_frequency != f) Juice.tick();
                      setState(() => _frequency = f);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: f != 'monthly' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _frequency == f ? C.blueSoft : C.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _frequency == f ? C.blue : C.line,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        RecurringScreen._freqRo[f]!,
                        style: T.display(
                          size: 13,
                          weight: FontWeight.w800,
                          color: _frequency == f ? C.blueInk : C.text2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClayButton(
            label: 'Salvează',
            gradient: Grad.blue,
            shadow: Sh.blue,
            height: 54,
            fontSize: 16,
            onTap: () async {
              final name = _merchant.text.trim();
              final value = double.tryParse(
                _amount.text.trim().replaceAll(',', '.'),
              );
              if (name.isEmpty || value == null || value <= 0) return;
              Juice.tick();
              await ref
                  .read(recurringRepositoryProvider)
                  .add(
                    merchant: name,
                    amount: value,
                    category: 'altele',
                    type: 'expense',
                    frequency: _frequency,
                    // Prima apariție în perioada următoare (nu retroactiv).
                    nextDueDate: _firstDue(_frequency),
                  );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _firstDue(String frequency) {
    final now = DateTime.now();
    final next = switch (frequency) {
      'daily' => now.add(const Duration(days: 1)),
      'weekly' => now.add(const Duration(days: 7)),
      _ => DateTime(now.year, now.month + 1, now.day),
    };
    return dayKey(next);
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.inset,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Sh.insetSoft,
      ),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: T.display(size: 16, weight: FontWeight.w700, color: C.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: T.display(
            size: 16,
            weight: FontWeight.w700,
            color: C.text3,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
