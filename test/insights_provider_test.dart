import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/db_provider.dart';
import 'package:finedu_flutter/domain/engine/insight_rules.dart';
import 'package:finedu_flutter/features/insights/data/insights_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('insight cards resolve end-to-end from a seeded db', () async {
    final db = AppDb(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await db
        .into(db.localProfiles)
        .insert(LocalProfilesCompanion.insert(monthlyBudget: const Value(800)));
    final now = DateTime.now();
    for (var i = 0; i < 6; i++) {
      await db
          .into(db.localTransactions)
          .insert(
            LocalTransactionsCompanion.insert(
              id: 'tx$i',
              amount: 10.0 + i,
              category: 'mancare',
              transactionDate: now.subtract(Duration(days: i)),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    // Un listener real ține provider-ul viu peste rebuild-urile declanșate
    // de stream-urile pe care le veghează (profil, luna curentă), exact
    // ca ref.watch din widget.
    final settled = Completer<List<InsightCard>>();
    container.listen<AsyncValue<List<InsightCard>>>(
      insightCardsProvider('ro'),
      (_, next) {
        final cards = next.valueOrNull;
        if (cards != null && !settled.isCompleted) settled.complete(cards);
        if (next.hasError && !settled.isCompleted) {
          settled.completeError(next.error!);
        }
      },
      fireImmediately: true,
    );
    final cards = await settled.future.timeout(const Duration(seconds: 15));

    // Cu buget + 6 tranzacții sub ritm, pacing-ul pozitiv trebuie să apară.
    expect(cards, isNotEmpty);
    final pace = cards.firstWhere(
      (c) => c.ruleKey == 'pace_under',
      orElse: () => cards.first,
    );
    expect(pace.kind, isNot(InsightKind.corrective));
    expect(
      pace.body,
      isNot(contains('{')),
      reason: 'toate placeholder-ele trebuie umplute',
    );
    expect(pace.ctaRoute, startsWith('/'));

    // Afișarea s-a înregistrat (cooldown-ul de mâine depinde de asta).
    final events = await db.select(db.insightEvents).get();
    expect(events.where((e) => e.event == 'shown'), isNotEmpty);

    // Anti-regresie „auto-cooldown": o re-evaluare în ACEEAȘI zi întoarce
    // același card, cooldown-ul pentru `shown` începe abia de mâine.
    container.invalidate(insightCardsProvider('ro'));
    final settled2 = Completer<List<InsightCard>>();
    container.listen<AsyncValue<List<InsightCard>>>(
      insightCardsProvider('ro'),
      (_, next) {
        final c = next.valueOrNull;
        if (c != null && !settled2.isCompleted) settled2.complete(c);
      },
      fireImmediately: true,
    );
    final again = await settled2.future.timeout(const Duration(seconds: 15));
    expect(
      again.map((c) => c.id),
      contains(pace.id),
      reason: 'cardul de azi nu se auto-suprimă',
    );
  });
}
