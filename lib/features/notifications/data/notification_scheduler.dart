import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications_service.dart';
import '../../../core/utils/bundle.dart';
import '../../../domain/engine/notification_planner.dart';
import '../../tracking/data/transactions_repository.dart';

/// Reprogramarea escaladării D1/D3/D7, o dată pe sesiune. Fiecare deschidere
/// anulează + repune sloturile; o eroare de notificare nu atinge aplicația.
final notificationsRescheduleProvider = FutureProvider<void>((ref) async {
  try {
    final service = ref.read(notificationsServiceProvider);
    // Soft-ask încă neacceptat: nu programăm nimic.
    if (!await service.areEnabled()) return;

    // Semnalul pentru ora preferată: când a deschis chiar utilizatorul aplicația.
    final repo = ref.read(transactionsRepositoryProvider);
    final timestamps = await repo.recentTimestamps(60);
    final hour = preferredHour(timestamps);
    final plan = planEscalation(now: DateTime.now(), hour: hour);

    // Copy-ul, ca la ceilalți loaderi de conținut: locală 'ro' (app-ul e RO).
    const locale = 'ro';
    final content = jsonDecode(await loadAssetString('content/notifications.json'))
        as Map<String, dynamic>;

    final slots = <({int id, DateTime when, String title, String body})>[];
    for (final p in plan) {
      final variants = (content[p.kind] as List).cast<Map<String, dynamic>>();
      final v = variants[
          variantIndex(dayKey: dayKey(p.when), count: variants.length)];
      slots.add((
        id: p.id,
        when: p.when,
        title: _t(v['title'] as Map<String, dynamic>, locale),
        body: _t(v['body'] as Map<String, dynamic>, locale),
      ));
    }

    await service.rescheduleEscalation(slots);
  } catch (e) {
    // Niciodată nu lăsăm o replanificare să afecteze aplicația.
    debugPrint('[notifications] reschedule provider failed: $e');
  }
});

String _t(Map<String, dynamic> node, String locale) =>
    (node[locale] ?? node['ro']) as String;
