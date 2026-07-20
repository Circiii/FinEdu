import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/daily_challenge.dart' show epochDays;
import '../../../domain/util/day_key.dart';

/// Garderoba lui Cashy, sink-ul principal al ghindelor. Prețuri fixe sau
/// condiții de merit, nimic random, zero avantaj funcțional, id-uri stabile pe viață.

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.slot,
    required this.tier,
    required this.emoji,
    required this.name,
    this.price,
    this.cond,
    this.condText,
    this.colors = const [],
    this.months = const [],
  });

  final String id;
  final String slot; // 'background' | 'accessory'
  final String tier; // comun | rar | epic | merit | prestigiu
  final String emoji;
  final String name;
  final int? price; // null la itemele de merit
  final String? cond; // streak30 | belt_black | unit5 | score80
  final String? condText;
  final List<int> colors; // ARGB pentru fundaluri
  final List<int> months; // sezonier: lunile în care se poate cumpăra

  bool get isMerit => cond != null;

  /// Sezonierele rămân VIZIBILE tot anul; doar cumpărarea e în sezon.
  bool availableIn(int month) => months.isEmpty || months.contains(month);
}

const shopVisitBonus = 12;
const showcaseDiscount = 0.2;

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;

final wardrobeCatalogProvider =
    FutureProvider.family<List<CosmeticItem>, String>((ref, locale) async {
      final json =
          jsonDecode(await loadAssetString('content/cashy/wardrobe.json'))
              as Map<String, dynamic>;
      return [
        for (final i in (json['items'] as List).cast<Map<String, dynamic>>())
          CosmeticItem(
            id: i['id'] as String,
            slot: i['slot'] as String,
            tier: i['tier'] as String,
            emoji: i['emoji'] as String,
            name: _t(i['name'] as Map<String, dynamic>, locale),
            price: i['price'] as int?,
            cond: i['cond'] as String?,
            condText: i['cond_text'] == null
                ? null
                : _t(i['cond_text'] as Map<String, dynamic>, locale),
            colors: [
              for (final c in (i['colors'] as List? ?? const []))
                int.parse(c as String, radix: 16),
            ],
            months: (i['luni_disponibile'] as List? ?? const []).cast<int>(),
          ),
      ];
    });

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(
    ref.watch(appDbProvider),
    ref.watch(localProfileRepositoryProvider),
  );
});

/// Id-urile itemelor deținute (cumpărate sau câștigate).
final ownedItemsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(wardrobeRepositoryProvider).watchOwned();
});

/// „Vitrina zilei": 3 iteme cumpărabile, -20%, alese determinist din dată,
/// identic pe orice device. Restul catalogului rămâne mereu cumpărabil.
List<String> dailyShowcase(List<CosmeticItem> catalog, String today) {
  final buyable = [
    for (final i in catalog)
      if (!i.isMerit) i.id,
  ]..sort();
  final rng = Random(epochDays(today));
  final pool = [...buyable]..shuffle(rng);
  return pool.take(3).toList();
}

int showcasePrice(int price) =>
    ((price * (1 - showcaseDiscount)) / 5).round() * 5;

class WardrobeRepository {
  WardrobeRepository(this._db, this._profiles);

  final AppDb _db;
  final LocalProfileRepository _profiles;

  Stream<Set<String>> watchOwned() {
    return _db
        .select(_db.wardrobeItems)
        .watch()
        .map((rows) => rows.map((r) => r.itemId).toSet());
  }

  /// Cumpără un item (idempotent). Întoarce false dacă e deja deținut,
  /// nu are preț, e în afara sezonului sau ghindele nu ajung.
  Future<bool> purchase(CosmeticItem item, {required bool showcased}) async {
    if (item.isMerit || item.price == null) return false;
    if (!item.availableIn(DateTime.now().month)) return false;
    final owned = await (_db.select(
      _db.wardrobeItems,
    )..where((r) => r.itemId.equals(item.id))).getSingleOrNull();
    if (owned != null) return false;

    final cost = showcased ? showcasePrice(item.price!) : item.price!;
    final profile = await _profiles.get();
    if (profile.acorns < cost) return false;

    await _profiles.addAcorns(-cost, reason: 'wardrobe_${item.id}');
    await _db
        .into(_db.wardrobeItems)
        .insert(
          WardrobeItemsCompanion.insert(
            itemId: item.id,
            acquiredAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }

  /// Revendică un item de merit a cărui condiție e îndeplinită (gratuit).
  Future<bool> claimMerit(CosmeticItem item) async {
    if (!item.isMerit) return false;
    await _db
        .into(_db.wardrobeItems)
        .insert(
          WardrobeItemsCompanion.insert(
            itemId: item.id,
            acquiredAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }

  /// Echipează (sau dezechipează cu null) un slot.
  Future<void> equip(String slot, String? itemId) {
    return _profiles.update(
      slot == 'background'
          ? LocalProfilesCompanion(equippedBackground: Value(itemId))
          : LocalProfilesCompanion(equippedAccessory: Value(itemId)),
    );
  }

  /// Bonusul zilnic de vizită. Sursa de adevăr e ledger-ul de ghinde, zero
  /// coloane noi. Întoarce ghindele acordate (0 dacă azi a fost deja revendicat).
  Future<int> visitBonus() async {
    final today = dayKey(DateTime.now());
    final entries =
        await (_db.select(_db.acornEntries)
              ..where((e) => e.reason.equals('shop_visit'))
              ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
              ..limit(1))
            .get();
    if (entries.isNotEmpty && dayKey(entries.first.createdAt) == today) {
      return 0;
    }
    await _profiles.addAcorns(shopVisitBonus, reason: 'shop_visit');
    return shopVisitBonus;
  }
}
