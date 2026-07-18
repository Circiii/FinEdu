import 'dart:math' as math;
import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/events.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/acorn.dart';
import '../../../core/ui/category_icon.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../domain/engine/money_intel.dart';
import '../../../domain/models/categories.dart';
import '../../goals/data/goals_repository.dart';
import '../../home/data/home_providers.dart';
import '../../wardrobe/presentation/cashy_avatar.dart';
import '../data/transactions_repository.dart';

/// Id-uri de grilă UI → chei canonice de categorie (domain/models/categories.dart).
/// 'shopping' și 'abonamente' sunt grupări de afișare; se persistă ca 'haine' / 'distractie'.
const _catKeyMap = {'shopping': 'haine', 'abonamente': 'distractie'};

class _Mode {
  final String id, label, path;
  const _Mode(this.id, this.label, this.path);
}

class _Cat {
  final String id, label, path;
  final Color color, tint;
  const _Cat(this.id, this.label, this.path, this.color, this.tint);
}

const _modes = <_Mode>[
  _Mode('manual', 'Manual', Ic.edit),
  _Mode('foto', 'Foto bon', Ic.camera),
  _Mode('voce', 'Voce', Ic.mic),
];

const _cats = <_Cat>[
  _Cat('mancare', 'Mâncare', Ic.heart, Color(0xFFFF7A59), Color(0x26FF7A59)),
  _Cat('transport', 'Transport', Ic.bus, C.blue, Color(0x242B86FF)),
  _Cat('distractie', 'Distracție', Ic.film, C.violet, Color(0x268B7BFF)),
  _Cat('shopping', 'Shopping', Ic.bag, C.amber, Color(0x29FFB020)),
  _Cat('abonamente', 'Abonamente', Ic.repeat, C.green, Color(0x2622C55E)),
  _Cat('sanatate', 'Sănătate', Ic.plus, C.danger, Color(0x24FF5D6C)),
  _Cat('educatie', 'Educație', Ic.book, C.sky, Color(0x2633B6E6)),
  _Cat('altele', 'Altele', Ic.more, Color(0xFF8AA0BF), Color(0x298AA0BF)),
];

/// Destinații de economisire (chei canonice, domain/models/categories.dart).
const _savCats = <_Cat>[
  _Cat('fond_urgenta', 'Fond urgență', Ic.shield, C.green, Color(0x2622C55E)),
  _Cat('obiectiv', 'Obiectiv', Ic.target, C.blue, Color(0x242B86FF)),
  _Cat('investitii', 'Investiții', Ic.trending, C.violet, Color(0x268B7BFF)),
  _Cat('pensie', 'Pe termen lung', Ic.clock, C.sky, Color(0x2633B6E6)),
  _Cat('depozit', 'Depozit', Ic.wallet, C.amber, Color(0x29FFB020)),
  _Cat('altele_economii', 'Altele', Ic.coins, Color(0xFF8AA0BF), Color(0x298AA0BF)),
];

const _backspace = 'M20 6H10l-6 6 6 6h10a1.5 1.5 0 0 0 1.5-1.5v-9A1.5 1.5 0 0 0 20 6ZM17 9.5l-5 5M12 9.5l5 5';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialType, this.initialGoalId});

  /// 'saving' deschide direct modul economisire (ex. din cardul de obiectiv).
  final String? initialType;
  final String? initialGoalId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String mode = 'manual';
  late String entryType =
      widget.initialType == 'saving' ? 'saving' : 'expense';
  late String catId = entryType == 'saving'
      ? (widget.initialGoalId != null ? 'obiectiv' : 'fond_urgenta')
      : 'mancare';
  late String? goalId = widget.initialGoalId;
  String amount = '';
  bool saved = false;
  bool _saving = false;

  /// Featurile (categorie, sumă, zi) din ultimele ~120 cheltuieli, încărcate
  /// o dată per sesiune. Null până se încarcă sau la eroare, fără chip.
  List<({String category, double amount, int weekday})>? _features;

  /// Userul a ales categoria singur → sugestia tace pentru sesiunea asta.
  bool _catTouched = false;

  /// X-ul de pe chip: respins pentru sesiunea asta de ecran.
  bool _suggestionDismissed = false;

  bool get isSavingEntry => entryType == 'saving';
  List<_Cat> get activeCats => isSavingEntry ? _savCats : _cats;

  _Cat get selCat => activeCats.firstWhere((c) => c.id == catId);
  String get amountDisplay => amount.isEmpty ? '0' : amount;

  @override
  void initState() {
    super.initState();
    // Defensiv: dacă query-ul dă eroare, _features rămâne null și chip-ul nu apare.
    Future(() async {
      try {
        final f = await ref
            .read(transactionsRepositoryProvider)
            .recentExpenseFeatures();
        if (mounted) setState(() => _features = f);
      } catch (_) {/* fără chip */}
    });
  }

  /// Categoria sugerată pentru sumă, sau null (abținere). Necesită opt-in
  /// (personalizationOn); tace după alegere/respingere manuală.
  _Cat? _suggestedCat() {
    try {
      if (isSavingEntry || saved || _catTouched || _suggestionDismissed) {
        return null;
      }
      final profile = ref.watch(localProfileStreamProvider).valueOrNull;
      if (!(profile?.personalizationOn ?? false)) return null;
      final features = _features;
      if (features == null) return null;
      final value = double.tryParse(amount.replaceAll(',', '.'));
      if (value == null || value <= 0) return null;

      final idx = categorySuggestion(
        amount: value,
        weekday: DateTime.now().weekday,
        history: features,
        categories: Categories.expense,
      );
      if (idx < 0) return null; // abținere: sub prag nu sugerăm nimic
      final key = Categories.expense[idx];
      // Deja pe categoria sugerată (prin cheia canonică) → nimic de spus.
      if ((_catKeyMap[catId] ?? catId) == key) return null;
      // Cheia are căsuță în grilă ('haine' = Shopping); fără căsuță (ex. 'chirie') nu apare chip
      final gridId = key == 'haine' ? 'shopping' : key;
      for (final c in _cats) {
        if (c.id == gridId) return c;
      }
      return null;
    } catch (_) {
      return null; // defensiv: orice eroare → fără chip
    }
  }

  /// Persistă intrarea manuală (cheltuială sau economie): DB local + outbox,
  /// +2 ghinde, analytics, apoi overlay-ul de succes.
  Future<void> _save() async {
    final value = double.tryParse(amount.replaceAll(',', '.'));
    if (value == null || value <= 0 || _saving) return;
    setState(() => _saving = true);
    // Obiectiv atins e moment „major", verificăm traversarea țintei cu
    // starea de dinainte de scriere, ca să sară o singură dată.
    GoalProgress? goalBefore;
    if (isSavingEntry && goalId != null) {
      final goals =
          ref.read(goalsWithProgressProvider).valueOrNull ?? const [];
      for (final g in goals) {
        if (g.goal.id == goalId) {
          goalBefore = g;
          break;
        }
      }
    }
    final repo = ref.read(transactionsRepositoryProvider);
    final category = _catKeyMap[catId] ?? catId;
    if (isSavingEntry) {
      await repo.addSaving(amount: value, category: category, goalId: goalId);
    } else {
      await repo.addExpense(amount: value, category: category);
    }
    await ref
        .read(localProfileRepositoryProvider)
        .addAcorns(2, reason: 'log_$entryType');
    ref.read(analyticsProvider).track(AnalyticsEvents.expenseLogged,
        {'source': 'manual', 'category': category, 'type': entryType});
    final goalReachedNow = goalBefore != null &&
        !goalBefore.reached &&
        goalBefore.saved + value >= goalBefore.goal.targetAmount;
    // Un moment = un nivel: obiectivul atins (major) absoarbe log-ul (minor).
    goalReachedNow ? Juice.major() : Juice.correct();
    if (mounted) setState(() => saved = true);
  }

  void _press(String k) {
    setState(() {
      if (k == 'back') {
        if (amount.isNotEmpty) amount = amount.substring(0, amount.length - 1);
      } else if (k == ',') {
        if (amount.isNotEmpty && !amount.contains(',')) amount += ',';
      } else {
        if (amount.length < 6) amount += k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      _entryTypeToggle(),
                      if (!isSavingEntry) _modeTabs(),
                      if (isSavingEntry) ...[
                        _goalPicker(),
                        _manual(),
                      ] else if (mode == 'manual')
                        _manual()
                      else if (mode == 'foto')
                        _foto()
                      else
                        _voce(),
                    ],
                  ),
                ),
                if (saved) _success(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0x00EAF1FB), C.bg], stops: [0.0, 0.42],
              ),
            ),
            child: BottomNav(
              active: -1,
              fabGlow: true,
              onTap: (i) => context.go(_tabRoutes[i]),
              // Deja suntem pe fluxul de adăugare; FAB-ul e doar decorativ aici.
              onFab: () {},
            ),
          ),
        ],
      ),
    );
  }

  static const _tabRoutes = ['/home', '/learn', '/arcade', '/profil'];

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isSavingEntry ? 'Pune deoparte' : 'Adaugă cheltuială',
              style: T.display(size: 24, weight: FontWeight.w800, color: C.text)),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.line, width: 1),
                boxShadow: Sh.raise,
              ),
              alignment: Alignment.center,
              child: const SvgIcon(Ic.x, size: 18, color: C.text2, strokeWidth: 2.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle Cheltuială/Economie. Schimbarea resetează categoria la prima din
  /// listă (și golește obiectivul pentru cheltuieli).
  Widget _entryTypeToggle() {
    Widget segment(String type, String label, String icon) {
      final sel = entryType == type;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (entryType == type) return;
            Juice.tick();
            setState(() {
              entryType = type;
              catId = type == 'saving' ? 'fond_urgenta' : 'mancare';
              goalId = null;
              mode = 'manual';
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: sel
                  ? (type == 'saving' ? Grad.green : Grad.navFab)
                  : null,
              borderRadius: BorderRadius.circular(R.sm),
              boxShadow: sel ? (type == 'saving' ? Sh.green : Sh.blue) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon == Ic.acorn
                    ? Opacity(
                        opacity: sel ? 1 : 0.7,
                        child: const AcornIcon(size: 16))
                    : SvgIcon(icon,
                        size: 16,
                        color: sel ? Colors.white : C.text2,
                        strokeWidth: 2.2),
                const SizedBox(width: 7),
                Text(label,
                    style: T.display(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: sel ? Colors.white : C.text2)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: C.inset,
        borderRadius: BorderRadius.circular(17),
        boxShadow: Sh.insetSoft,
      ),
      child: Row(children: [
        segment('expense', 'Cheltuială', Ic.wallet),
        const SizedBox(width: 5),
        segment('saving', 'Economie', Ic.acorn),
      ]),
    );
  }

  /// Chipuri de obiectiv (mod economisire): leagă contribuția de un obiectiv.
  Widget _goalPicker() {
    final goals = ref.watch(goalsWithProgressProvider).valueOrNull ?? const [];
    if (goals.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CĂTRE OBIECTIVUL',
              style: T.display(
                  size: 11,
                  weight: FontWeight.w700,
                  color: C.text3,
                  letterSpacing: 11 * 0.12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in goals)
                GestureDetector(
                  onTap: () {
                    Juice.tick();
                    setState(() {
                      goalId = goalId == g.goal.id ? null : g.goal.id;
                      if (goalId != null) catId = 'obiectiv';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: goalId == g.goal.id ? C.blueSoft : C.surface,
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(
                          color:
                              goalId == g.goal.id ? C.blue : C.line,
                          width: 1.5),
                      boxShadow: Sh.raise,
                    ),
                    child: Text('${g.goal.emoji} ${g.goal.name}',
                        style: T.display(
                            size: 13,
                            weight: FontWeight.w700,
                            color: goalId == g.goal.id
                                ? C.blueInk
                                : C.text)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeTabs() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: C.inset,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Sh.insetSoft,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _modes.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _modeTab(_modes[i])),
          ],
        ],
      ),
    );
  }

  /// Chipuri de sumă rapidă: sumele rotunde cele mai frecvente din istoric,
  /// cu fallback la valori implicite pentru cont nou.
  Widget _quickAmounts() {
    final frequent =
        ref.watch(frequentAmountsProvider).valueOrNull ?? const <int>[];
    final defaults = isSavingEntry ? [20, 50, 100, 200] : [5, 10, 20, 50];
    final amounts = <int>{...frequent, ...defaults}.take(4).toList()..sort();
    return Row(
      children: [
        for (final a in amounts) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                Juice.tick();
                setState(() => amount = '$a');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                margin: EdgeInsets.only(right: a != amounts.last ? 8 : 0),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(R.sm),
                  border: Border.all(color: C.line, width: 1),
                  boxShadow: Sh.raise,
                ),
                alignment: Alignment.center,
                child: Text('$a',
                    style: T.display(
                        size: 15, weight: FontWeight.w800, color: C.text2)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _modeTab(_Mode m) {
    final sel = m.id == mode;
    return GestureDetector(
      onTap: () {
        if (mode == m.id) return;
        Juice.tick();
        setState(() => mode = m.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          gradient: sel ? Grad.navFab : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: sel ? Sh.blue : null,
        ),
        child: Column(
          children: [
            SvgIcon(m.path, size: 20, color: sel ? C.blueInk : C.text2, strokeWidth: 2),
            const SizedBox(height: 6),
            Text(m.label,
                style: T.display(size: 12.5, weight: sel ? FontWeight.w800 : FontWeight.w700, color: sel ? C.blueInk : C.text2)),
          ],
        ),
      ),
    );
  }

  // ---- MANUAL ----
  Widget _manual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  style: T.display(size: 54, weight: FontWeight.w800, color: C.text, height: 1.0),
                  children: [
                    TextSpan(text: amountDisplay),
                    TextSpan(text: ' lei', style: T.display(size: 22, weight: FontWeight.w800, color: C.text3)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(color: selCat.tint, borderRadius: BorderRadius.circular(R.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    categoryIconAsset(selCat.id) == null
                        ? SvgIcon(selCat.path,
                            size: 16, color: selCat.color, strokeWidth: 2)
                        : Image.asset(categoryIconAsset(selCat.id)!,
                            width: 17, height: 17,
                            filterQuality: FilterQuality.medium),
                    const SizedBox(width: 6),
                    Text(selCat.label, style: T.display(size: 13.5, weight: FontWeight.w700, color: selCat.color)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!isSavingEntry) _suggestionChip(),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82,
          children: [for (final c in activeCats) _catTile(c)],
        ),
        const SizedBox(height: 14),
        _quickAmounts(),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 108 / 52,
          children: [
            for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', 'back']) _key(k),
          ],
        ),
        const SizedBox(height: 16),
        ClayButton(
          label: isSavingEntry ? 'Pune deoparte' : 'Adaugă cheltuiala',
          gradient: isSavingEntry ? Grad.green : Grad.blue,
          shadow: isSavingEntry ? Sh.green : Sh.blue,
          height: 58,
          fontSize: 17,
          leading: isSavingEntry
              ? const AcornIcon(size: 20)
              : const SvgIcon(Ic.plus,
                  size: 20, color: Colors.white, strokeWidth: 2.6),
          onTap: amount.isEmpty ? null : _save,
        ),
      ],
    );
  }

  /// Chip de sugestie deasupra grilei. Tap = alege categoria; X = respins
  /// pentru sesiune. Apare doar cu personalizarea pornită.
  Widget _suggestionChip() {
    final target = _suggestedCat();
    if (target == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClayCard(
        radius: R.sm,
        color: C.violetSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Juice.tick();
                  setState(() {
                    catId = target.id;
                    _catTouched = true; // alegerea făcută, sugestia tace
                  });
                },
                child: Text(
                  '🧠 Pare a fi ${target.label}, atinge ca să alegi',
                  style: T.body(
                      size: 13, weight: FontWeight.w700, color: C.violet),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _suggestionDismissed = true),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SvgIcon(Ic.x, size: 14, color: C.violet, strokeWidth: 2.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catTile(_Cat c) {
    final sel = c.id == catId;
    return GestureDetector(
      onTap: () {
        if (catId != c.id) Juice.tick();
        setState(() {
          catId = c.id;
          _catTouched = true; // alegere manuală → sugestia nu mai insistă
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? C.surface : C.surface2,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: sel ? c.color : Colors.transparent, width: 2),
          boxShadow: sel
              ? [
                  BoxShadow(color: c.color.withValues(alpha: 0.33), offset: const Offset(0, 12), blurRadius: 20, spreadRadius: -8),
                  const BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.55), offset: Offset(0, 2), blurRadius: 2, inset: true),
                ]
              : Sh.raise,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryTileIcon(
              category: c.id,
              fallbackPath: c.path,
              tint: c.tint,
              color: c.color,
              size: 46,
              radius: 15,
              iconSize: 24,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(c.label, maxLines: 1, style: T.body(size: 11, weight: FontWeight.w700, color: C.text2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _key(String k) {
    return GestureDetector(
      onTap: () {
        Juice.tick();
        _press(k);
      },
      child: Container(
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line, width: 1),
          boxShadow: Sh.raise,
        ),
        alignment: Alignment.center,
        child: k == 'back'
            ? const SvgIcon(_backspace, size: 24, color: C.text2, strokeWidth: 2.1)
            : Text(k, style: T.display(size: 24, weight: FontWeight.w800, color: C.text)),
      ),
    );
  }

  // ---- FOTO ----
  Widget _foto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 230,
          decoration: BoxDecoration(color: C.inset, borderRadius: BorderRadius.circular(24), boxShadow: Sh.insetSoft),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              _corner(top: 14, left: 14, tl: true),
              _corner(top: 14, right: 14, tr: true),
              _corner(bottom: 14, left: 14, bl: true),
              _corner(bottom: 14, right: 14, br: true),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(gradient: Grad.navFab, borderRadius: BorderRadius.circular(22), boxShadow: Sh.blue),
                      alignment: Alignment.center,
                      child: const SvgIcon(Ic.camera, size: 34, color: Colors.white, strokeWidth: 2),
                    ),
                    const SizedBox(height: 12),
                    Text('Îndreaptă camera spre bon', style: T.display(size: 15, weight: FontWeight.w700, color: C.text)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ClayCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SvgIcon(Ic.check, size: 17, color: C.green, strokeWidth: 2.4),
                  const SizedBox(width: 7),
                  Text('Detectat automat', style: T.display(size: 13, weight: FontWeight.w800, color: C.greenDeep, letterSpacing: 13 * 0.02)),
                ],
              ),
              const SizedBox(height: 12),
              _detRow('Sumă', valueBig: '48,50 lei'),
              const SizedBox(height: 10),
              _detRow('Comerciant', valueMed: 'Mega Image'),
              const SizedBox(height: 10),
              _detRowCat('Categorie'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mock până vine OCR-ul de bonuri, dezactivat, nu scrie date false.
        ClayButton(label: 'În curând, scanare bon (F5)', gradient: Grad.blue, shadow: Sh.blue, height: 58, fontSize: 17,
            onTap: null),
      ],
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right, bool tl = false, bool tr = false, bool bl = false, bool br = false}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: (tl || tr) ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
            bottom: (bl || br) ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
            left: (tl || bl) ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
            right: (tr || br) ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: tl ? const Radius.circular(8) : Radius.zero,
            topRight: tr ? const Radius.circular(8) : Radius.zero,
            bottomLeft: bl ? const Radius.circular(8) : Radius.zero,
            bottomRight: br ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _detRow(String label, {String? valueBig, String? valueMed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: T.body(size: 13.5, weight: FontWeight.w600, color: C.text2)),
        if (valueBig != null) Text(valueBig, style: T.display(size: 18, weight: FontWeight.w800, color: C.text)),
        if (valueMed != null) Text(valueMed, style: T.body(size: 14, weight: FontWeight.w700, color: C.text)),
      ],
    );
  }

  Widget _detRowCat(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: T.body(size: 13.5, weight: FontWeight.w600, color: C.text2)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0x26FF7A59), borderRadius: BorderRadius.circular(R.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SvgIcon(Ic.heart, size: 13, color: Color(0xFFFF7A59), strokeWidth: 2),
              const SizedBox(width: 5),
              Text('Mâncare', style: T.display(size: 12, weight: FontWeight.w700, color: const Color(0xFFFF7A59))),
            ],
          ),
        ),
      ],
    );
  }

  // ---- VOCE ----
  Widget _voce() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          SizedBox(
            width: 120, height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: C.blueSoft)),
                Container(margin: const EdgeInsets.all(14), decoration: const BoxDecoration(shape: BoxShape.circle, color: C.blueSoft)),
                Container(
                  width: 82, height: 82,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: Grad.navFab, boxShadow: Sh.blue),
                  alignment: Alignment.center,
                  child: const SvgIcon(Ic.mic, size: 36, color: Colors.white, strokeWidth: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 26; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 8 + 34 * (0.5 + 0.5 * math.sin(i * 0.9)).abs(),
                    decoration: BoxDecoration(color: C.blue.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(R.pill)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('TE ASCULT…',
              style: T.display(size: 12, weight: FontWeight.w700, color: C.blue, letterSpacing: 12 * 0.14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.line, width: 1),
              boxShadow: Sh.raise,
            ),
            child: RichText(
              text: TextSpan(
                style: T.body(size: 17, weight: FontWeight.w600, color: C.text),
                children: [
                  const TextSpan(text: '„Am dat '),
                  TextSpan(text: '25 lei', style: T.body(size: 17, weight: FontWeight.w700, color: C.text)),
                  const TextSpan(text: ' pe cafea"'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: C.blueSoft, borderRadius: BorderRadius.circular(R.pill)),
                child: Text('25 lei', style: T.display(size: 13, weight: FontWeight.w800, color: C.blue)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0x26FF7A59), borderRadius: BorderRadius.circular(R.pill)),
                child: Text('Mâncare', style: T.display(size: 13, weight: FontWeight.w700, color: const Color(0xFFFF7A59))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mock până vine dictarea vocală, dezactivat, nu scrie date false.
          ClayButton(label: 'În curând, dictare vocală (F5)', gradient: Grad.blue, shadow: Sh.blue, height: 58, fontSize: 17,
              onTap: null),
        ],
      ),
    );
  }

  // ---- SUCCESS ----
  Widget _success() {
    return Container(
      color: C.bg,
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CashySprite(asset: Cashy.cashyCelebrate, width: 210),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(isSavingEntry ? 'Pusă deoparte!' : 'Adăugat!',
                style: T.display(size: 34, weight: FontWeight.w800, color: C.text)),
          ),
          Text(
              isSavingEntry
                  ? 'Ghinda e în scorbură. Viitorul tău îți mulțumește deja.'
                  : 'Cheltuiala e notată. Constanța ta crește, asta contează cel mai mult.',
              textAlign: TextAlign.center,
              style: T.body(size: 16, weight: FontWeight.w400, color: C.text2, height: 1.5)),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 18, 0, 22),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: C.amberSoft,
              borderRadius: BorderRadius.circular(R.pill),
              border: Border.all(color: C.line, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AcornIcon(size: 22),
                const SizedBox(width: 8),
                Text('+2 ghinde', style: T.display(size: 18, weight: FontWeight.w800, color: C.text)),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ClayButton(label: 'Gata', gradient: Grad.blue, shadow: Sh.blue, height: 56, fontSize: 17,
                onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}
