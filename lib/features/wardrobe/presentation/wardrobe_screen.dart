import 'package:flutter/material.dart' hide BoxShadow, BoxDecoration;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/acorn.dart';
import '../../../core/ui/clay.dart';
import '../../../core/ui/fmt.dart';
import '../../../core/ui/juice.dart';
import '../../../core/ui/svg_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../domain/engine/dojo_elo.dart';
import '../../../domain/util/day_key.dart';
import '../../arcade/data/dojo_repository.dart';
import '../../gamification/data/gamification_service.dart';
import '../../gamification/data/score_providers.dart';
import '../../home/data/home_providers.dart';
import '../../learning/data/lessons_repository.dart';
import '../data/wardrobe_repository.dart';
import 'cashy_avatar.dart';

const _monthsRo = [
  'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
  'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie',
];

/// Condițiile de merit îndeplinite ACUM, din datele reale ale aplicației.
/// Cheile oglindesc `cond` din catalog: streak30|belt_black|unit5|score80.
final meritUnlocksProvider = Provider<Set<String>>((ref) {
  final unlocked = <String>{};

  final streak = ref.watch(streakViewProvider).valueOrNull;
  if ((streak?.longest ?? 0) >= 30) unlocked.add('streak30');

  final dojo = ref.watch(dojoStateProvider).valueOrNull;
  if (dojo != null &&
      dojo.rounds > 0 &&
      dojo.beltIndex == dojoBelts.length - 1) {
    unlocked.add('belt_black');
  }

  final done = ref.watch(completedLessonsProvider).valueOrNull ?? const {};
  final units = ref.watch(unitsProvider('ro')).valueOrNull ?? const [];
  for (final u in units) {
    if (u.id == 'u5' &&
        u.lessons.isNotEmpty &&
        u.lessons.every((l) => done.contains(l.id))) {
      unlocked.add('unit5');
    }
  }

  final score = ref.watch(scoreProvider).valueOrNull;
  if ((score?.total ?? 0) >= 80) unlocked.add('score80');

  return unlocked;
});

/// Garderoba lui Cashy, sink-ul principal de ghinde. Vitrina zilei (-20%),
/// merit-uri cu siluetă gri până la deblocare, sezoniere care revin, bonus zilnic de vizită.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  int _visitBonus = 0;

  @override
  void initState() {
    super.initState();
    // Bonusul de vizită se acordă la deschidere, o dată pe zi, fără acțiune cerută.
    Future.microtask(() async {
      final granted =
          await ref.read(wardrobeRepositoryProvider).visitBonus();
      if (granted > 0 && mounted) setState(() => _visitBonus = granted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog =
        ref.watch(wardrobeCatalogProvider('ro')).valueOrNull ?? const [];
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? const <String>{};
    final profile = ref.watch(localProfileStreamProvider).valueOrNull;
    final unlocked = ref.watch(meritUnlocksProvider);
    final acorns = profile?.acorns ?? 0;

    final today = dayKey(DateTime.now());
    final showcaseIds = dailyShowcase(catalog, today).toSet();
    final backgrounds =
        catalog.where((i) => i.slot == 'background').toList();
    final accessories =
        catalog.where((i) => i.slot == 'accessory').toList();

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
                  _header(context, acorns),
                  if (_visitBonus > 0) ...[
                    const SizedBox(height: 10),
                    _visitBonusBanner(),
                  ],
                  const SizedBox(height: 14),
                  _preview(profile, catalog, owned),
                  const SizedBox(height: 16),
                  if (showcaseIds.isNotEmpty) ...[
                    _sectionLabel('VITRINA ZILEI · -20%'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final item in catalog
                            .where((i) => showcaseIds.contains(i.id))) ...[
                          Expanded(
                            child: _tile(context, item,
                                owned: owned.contains(item.id),
                                equipped: _isEquipped(profile, item),
                                unlocked: unlocked,
                                showcased: true,
                                acorns: acorns),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ]..removeLast(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionLabel('FUNDALURI'),
                  const SizedBox(height: 10),
                  _grid(context, backgrounds, profile, owned, unlocked,
                      showcaseIds, acorns),
                  const SizedBox(height: 16),
                  _sectionLabel('ACCESORII'),
                  const SizedBox(height: 10),
                  _grid(context, accessories, profile, owned, unlocked,
                      showcaseIds, acorns),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isEquipped(dynamic profile, CosmeticItem item) {
    if (profile == null) return false;
    return item.slot == 'background'
        ? profile.equippedBackground == item.id
        : profile.equippedAccessory == item.id;
  }

  // ---- header + banners ------------------------------------------------------

  Widget _header(BuildContext context, int acorns) {
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
            child: const SvgIcon(Ic.chevronLeft,
                size: 18, color: C.text2, strokeWidth: 2.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Garderoba',
              style:
                  T.display(size: 24, weight: FontWeight.w800, color: C.text)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              Text(fmtThousands(acorns),
                  style: T.display(
                      size: 14, weight: FontWeight.w800, color: C.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _visitBonusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.greenSoft,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Text('🎁  +$_visitBonus ghinde pentru vizita de azi!',
          style: T.body(size: 13, weight: FontWeight.w700, color: C.greenDeep)),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: T.display(
          size: 11.5,
          weight: FontWeight.w800,
          color: C.text3,
          letterSpacing: 11.5 * 0.12));

  // ---- preview ---------------------------------------------------------------

  Widget _preview(
      dynamic profile, List<CosmeticItem> catalog, Set<String> owned) {
    return ClayCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CashyAvatar(asset: Cashy.cashyDefault, size: 96),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?.cashyName ?? 'Cashy',
                    style: T.display(
                        size: 20, weight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 4),
                Text('Atinge un item deținut ca să-l echipezi sau să-l dai jos.',
                    style: T.body(
                        size: 12, weight: FontWeight.w500, color: C.text3)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: C.violetSoft,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                  child: Text('${owned.length}/${catalog.length} în colecție',
                      style: T.display(
                          size: 12, weight: FontWeight.w800, color: C.violet)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- grid + tiles ----------------------------------------------------------

  Widget _grid(
      BuildContext context,
      List<CosmeticItem> items,
      dynamic profile,
      Set<String> owned,
      Set<String> unlocked,
      Set<String> showcaseIds,
      int acorns) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: [
        for (final item in items)
          _tile(context, item,
              owned: owned.contains(item.id),
              equipped: _isEquipped(profile, item),
              unlocked: unlocked,
              showcased: showcaseIds.contains(item.id),
              acorns: acorns),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    CosmeticItem item, {
    required bool owned,
    required bool equipped,
    required Set<String> unlocked,
    required bool showcased,
    required int acorns,
  }) {
    final meritLocked = item.isMerit && !owned && !unlocked.contains(item.cond);
    final month = DateTime.now().month;
    final offSeason = !owned && !item.availableIn(month);

    Widget visual = item.slot == 'background'
        ? Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [for (final c in item.colors) Color(c)],
              ),
              borderRadius: BorderRadius.circular(R.sm),
            ),
            alignment: Alignment.center,
            child:
                Text(item.emoji, style: const TextStyle(fontSize: 20)),
          )
        : Text(item.emoji, style: const TextStyle(fontSize: 34));
    if (meritLocked) {
      // Silueta gri, se vede CE e, nu și cum arată în glorie.
      visual = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 60,
          0.2126, 0.7152, 0.0722, 0, 60,
          0.2126, 0.7152, 0.0722, 0, 60,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(opacity: 0.55, child: visual),
      );
    }

    return GestureDetector(
      onTap: () {
        Juice.tick();
        _openItemSheet(context, item,
            owned: owned,
            equipped: equipped,
            meritUnlocked: !item.isMerit || unlocked.contains(item.cond),
            showcased: showcased,
            acorns: acorns);
      },
      child: Container(
        foregroundDecoration: equipped
            ? BoxDecoration(
                border: Border.all(color: C.green, width: 2),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: ClayCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 48, child: Center(child: visual)),
              const SizedBox(height: 6),
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: T.display(
                      size: 11.5, weight: FontWeight.w800, color: C.text)),
              const SizedBox(height: 5),
              _tileBadge(item,
                  owned: owned,
                  equipped: equipped,
                  meritLocked: meritLocked,
                  offSeason: offSeason,
                  showcased: showcased),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileBadge(
    CosmeticItem item, {
    required bool owned,
    required bool equipped,
    required bool meritLocked,
    required bool offSeason,
    required bool showcased,
  }) {
    if (equipped) return _badge('Echipat', C.greenSoft, C.greenDeep);
    if (owned) return _badge('Deținut', C.blueSoft, C.blueDeep);
    if (item.isMerit) {
      return meritLocked
          ? const SvgIcon(Ic.lock, size: 13, color: C.text3, strokeWidth: 2)
          : _badge('Revendică!', C.violetSoft, C.violetDeep);
    }
    if (offSeason) {
      return _badge(
          'Revine în ${_monthsRo[item.months.first - 1]}', C.inset, C.text3);
    }
    final price = showcased ? showcasePrice(item.price!) : item.price!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showcased) ...[
          Text('${item.price}',
              style: T
                  .body(size: 10.5, weight: FontWeight.w600, color: C.text3)
                  .copyWith(decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 4),
        ],
        const AcornIcon(size: 12),
        const SizedBox(width: 3),
        Text(fmtThousands(price),
            style: T.display(
                size: 12,
                weight: FontWeight.w800,
                color: showcased ? C.greenDeep : C.text)),
      ],
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: T.display(size: 10.5, weight: FontWeight.w800, color: fg)),
    );
  }

  // ---- item sheet ------------------------------------------------------------

  void _openItemSheet(
    BuildContext context,
    CosmeticItem item, {
    required bool owned,
    required bool equipped,
    required bool meritUnlocked,
    required bool showcased,
    required int acorns,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemSheet(
        item: item,
        owned: owned,
        equipped: equipped,
        meritUnlocked: meritUnlocked,
        showcased: showcased,
        acorns: acorns,
      ),
    );
  }
}

/// Foaia unui item: preview mare + acțiunea potrivită stării. La cumpărare
/// arată costul de oportunitate, decizia rămâne informată, nu impulsivă.
class _ItemSheet extends ConsumerWidget {
  const _ItemSheet({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.meritUnlocked,
    required this.showcased,
    required this.acorns,
  });

  final CosmeticItem item;
  final bool owned;
  final bool equipped;
  final bool meritUnlocked;
  final bool showcased;
  final int acorns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(wardrobeRepositoryProvider);
    final month = DateTime.now().month;
    final offSeason = !owned && !item.availableIn(month);
    final price =
        item.price == null ? null : (showcased ? showcasePrice(item.price!) : item.price!);
    final affordable = price != null && acorns >= price;

    Future<void> equipAndClose() async {
      Juice.tick();
      await repo.equip(item.slot, equipped ? null : item.id);
      if (context.mounted) Navigator.pop(context);
    }

    Future<void> buy() async {
      final ok = await repo.purchase(item, showcased: showcased);
      if (ok) {
        await repo.equip(item.slot, item.id);
        Juice.correct();
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? '${item.emoji} E al tău! L-am și echipat pe Cashy.'
                : 'Nu s-a putut cumpăra. Mai încearcă o dată.')));
      }
    }

    Future<void> claim() async {
      final ok = await repo.claimMerit(item);
      if (ok) {
        await repo.equip(item.slot, item.id);
        Juice.major();
      }
      if (context.mounted) Navigator.pop(context);
    }

    return Container(
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
              item.slot == 'background'
                  ? Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [for (final c in item.colors) Color(c)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: Sh.raise,
                      ),
                      alignment: Alignment.center,
                      child: Text(item.emoji,
                          style: const TextStyle(fontSize: 26)),
                    )
                  : Text(item.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: T.display(
                            size: 19, weight: FontWeight.w800, color: C.text)),
                    if (item.condText != null)
                      Text(item.condText!,
                          style: T.body(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: C.violet)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (owned)
            ClayButton(
              label: equipped ? 'Dă-l jos' : 'Echipează',
              gradient: Grad.green,
              shadow: Sh.green,
              height: 54,
              fontSize: 16,
              onTap: equipAndClose,
            )
          else if (item.isMerit)
            meritUnlocked
                ? ClayButton(
                    label: 'Revendică-l',
                    gradient: Grad.green,
                    shadow: Sh.green,
                    height: 54,
                    fontSize: 16,
                    onTap: claim,
                  )
                : _note('🔒 Nu se poate cumpăra cu ghinde, se câștigă. '
                    'Când îndeplinești condiția, îl revendici gratuit de aici.')
          else if (offSeason)
            _note('🗓️ Item de sezon. Revine în '
                '${_monthsRo[item.months.first - 1]}, nicio grabă, '
                'nu dispare nimic definitiv.')
          else ...[
            // Costul de oportunitate, negru pe alb, înainte de decizie.
            _note(affordable
                ? 'Ai ${fmtThousands(acorns)} ghinde. După cumpărare îți '
                    'rămân ${fmtThousands(acorns - price)}. '
                    'Un îngheț de streak costă 200.'
                : 'Ai ${fmtThousands(acorns)} ghinde, îți mai trebuie '
                    '${fmtThousands(price! - acorns)}. Lecțiile și Arcade '
                    'te duc acolo.'),
            const SizedBox(height: 12),
            if (affordable)
              ClayButton(
                label: showcased
                    ? 'Cumpără cu $price (în loc de ${item.price})'
                    : 'Cumpără cu $price ghinde',
                gradient: Grad.green,
                shadow: Sh.green,
                height: 54,
                fontSize: 16,
                onTap: buy,
              ),
          ],
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.inset,
        borderRadius: BorderRadius.circular(R.sm),
      ),
      child: Text(text,
          style: T.body(
              size: 13, weight: FontWeight.w600, color: C.text2, height: 1.4)),
    );
  }
}
