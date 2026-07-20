import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/features/wardrobe/data/wardrobe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('catalog (guvernanța din spec)', () {
    test(
      'every item has a fixed price XOR a merit condition; ids unique',
      () async {
        for (final locale in ['ro', 'en']) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final catalog = await container.read(
            wardrobeCatalogProvider(locale).future,
          );
          expect(catalog.length, greaterThanOrEqualTo(20));

          final ids = <String>{};
          var merit = 0;
          for (final i in catalog) {
            expect(ids.add(i.id), isTrue, reason: 'duplicate ${i.id}');
            expect(['background', 'accessory'], contains(i.slot), reason: i.id);
            // Preț fix SAU condiție, niciodată ambele, niciodată niciuna.
            expect((i.price != null) ^ (i.cond != null), isTrue, reason: i.id);
            if (i.isMerit) {
              merit++;
              expect(i.condText, isNotNull, reason: i.id);
            } else {
              expect(i.price, greaterThanOrEqualTo(100), reason: i.id);
            }
            if (i.slot == 'background') {
              expect(i.colors, hasLength(2), reason: i.id);
            }
            for (final m in i.months) {
              expect(m, inInclusiveRange(1, 12), reason: i.id);
            }
          }
          expect(
            merit,
            greaterThanOrEqualTo(3),
            reason: 'itemele câștigate prin merit sunt cârligul de retenție',
          );
        }
      },
    );

    test(
      'daily showcase: deterministic, 3 buyable items, rounded discount',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final catalog = await container.read(
          wardrobeCatalogProvider('ro').future,
        );

        final a = dailyShowcase(catalog, '2026-07-12');
        final b = dailyShowcase(catalog, '2026-07-12');
        expect(a, b, reason: 'aceeași zi → aceeași vitrină pe orice device');
        expect(a, hasLength(3));
        expect(
          a.toSet(),
          isNot(dailyShowcase(catalog, '2026-07-13').toSet()),
          reason: 'vitrina se schimbă zilnic',
        );
        final merits = catalog.where((i) => i.isMerit).map((i) => i.id).toSet();
        expect(a.where(merits.contains), isEmpty);

        expect(showcasePrice(150), 120);
        expect(showcasePrice(450), 360);
        expect(showcasePrice(1200), 960);
      },
    );
  });

  group('WardrobeRepository', () {
    late AppDb db;
    late LocalProfileRepository profiles;
    late WardrobeRepository repo;

    const hat = CosmeticItem(
      id: 'acc_test',
      slot: 'accessory',
      tier: 'comun',
      emoji: '🎩',
      name: 'Test',
      price: 200,
    );

    setUp(() async {
      db = AppDb(NativeDatabase.memory());
      profiles = LocalProfileRepository(db);
      repo = WardrobeRepository(db, profiles);
    });
    tearDown(() => db.close());

    test(
      'purchase: needs funds, pays through the ledger, is idempotent',
      () async {
        expect(
          await repo.purchase(hat, showcased: false),
          isFalse,
          reason: '0 ghinde, nu ajung',
        );

        await profiles.addAcorns(500, reason: 'test_seed');
        expect(await repo.purchase(hat, showcased: false), isTrue);
        expect((await profiles.get()).acorns, 300);

        final ledger = await db.select(db.acornEntries).get();
        expect(
          ledger.any((e) => e.reason == 'wardrobe_acc_test' && e.delta == -200),
          isTrue,
        );

        expect(
          await repo.purchase(hat, showcased: false),
          isFalse,
          reason: 'deja deținut',
        );
        expect((await profiles.get()).acorns, 300, reason: 'fără dublă taxare');
      },
    );

    test('showcase price applies; merit items cannot be bought', () async {
      await profiles.addAcorns(200, reason: 'test_seed');
      expect(await repo.purchase(hat, showcased: true), isTrue);
      expect((await profiles.get()).acorns, 200 - 160);

      const meritItem = CosmeticItem(
        id: 'acc_merit',
        slot: 'accessory',
        tier: 'merit',
        emoji: '🧣',
        name: 'M',
        cond: 'streak30',
      );
      expect(await repo.purchase(meritItem, showcased: false), isFalse);
      expect(await repo.claimMerit(meritItem), isTrue);
      expect(await repo.watchOwned().first, contains('acc_merit'));
    });

    test('seasonal items only sell in their months', () async {
      await profiles.addAcorns(1000, reason: 'test_seed');
      final thisMonth = DateTime.now().month;
      final offSeason = CosmeticItem(
        id: 'bg_sezon',
        slot: 'background',
        tier: 'rar',
        emoji: '🎄',
        name: 'S',
        price: 500,
        colors: const [0xFF000000, 0xFFFFFFFF],
        months: [thisMonth == 1 ? 2 : 1],
      );
      expect(await repo.purchase(offSeason, showcased: false), isFalse);
    });

    test(
      'equip writes the profile slot; visit bonus pays once a day',
      () async {
        await profiles.get(); // asigură rândul de profil
        await repo.equip('accessory', 'acc_test');
        expect((await profiles.get()).equippedAccessory, 'acc_test');
        await repo.equip('accessory', null);
        expect((await profiles.get()).equippedAccessory, isNull);

        expect(await repo.visitBonus(), shopVisitBonus);
        expect(await repo.visitBonus(), 0, reason: 'o singură dată pe zi');
        expect((await profiles.get()).acorns, shopVisitBonus);
      },
    );
  });
}
