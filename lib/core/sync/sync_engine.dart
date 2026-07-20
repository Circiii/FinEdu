// Câmpurile private se setează din parametri numiți publici, prin lista de
// inițializare (parametrii numiți nu pot fi privați).
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'sync_backend.dart';

/// Număr maxim de încercări înainte ca o intrare din outbox să fie sărită
/// până la următorul restart (backoff simplu).
const int kMaxSyncAttempts = 5;

/// Fereastra de debounce pentru sync-ul declanșat de scriere.
const Duration kSyncDebounce = Duration(seconds: 3);

/// Consumă outbox-ul local către server, FIFO. No-op dacă nu există backend
/// configurat SAU sesiune. Dependențele sunt injectate, testabil cu un DB in-memory.
class SyncEngine {
  SyncEngine({
    required AppDb db,
    required bool hasBackend,
    SyncBackend? backend,
  }) : _db = db,
       _hasBackend = hasBackend,
       _backend = backend;

  final AppDb _db;
  final bool _hasBackend;
  final SyncBackend? _backend;

  Timer? _debounce;
  bool _running = false;

  /// Dacă sync-ul e posibil chiar acum.
  bool get _canSync => _hasBackend && _backend != null && _backend.hasSession;

  /// Programează un [syncNow] cu debounce; se apelează după fiecare scriere locală.
  void scheduleSync() {
    if (!_hasBackend) return;
    _debounce?.cancel();
    _debounce = Timer(kSyncDebounce, syncNow);
  }

  /// Consumă outbox-ul o dată. Sigur de apelat oricând: iese imediat fără
  /// backend/sesiune, nu aruncă niciodată (eșecurile per-intrare sunt înregistrate).
  Future<void> syncNow() async {
    if (!_canSync || _running) return;
    _running = true;
    try {
      await _drain();
    } finally {
      _running = false;
    }
  }

  Future<void> _drain() async {
    final backend = _backend!;

    final entries =
        await (_db.select(_db.outboxEntries)
              ..where((e) => e.attempts.isSmallerThanValue(kMaxSyncAttempts))
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();

    for (final entry in entries) {
      try {
        await _dispatch(backend, entry);
        // Succes: șterge intrarea și flag-ul pending de pe rândul afectat.
        await (_db.delete(
          _db.outboxEntries,
        )..where((e) => e.id.equals(entry.id))).go();
        await _clearPending(entry);
      } catch (error, stackTrace) {
        // Eșec: incrementează attempts, înregistrează eroarea și oprește
        // drenarea (backoff simplu: restul așteaptă următorul trigger).
        await (_db.update(
          _db.outboxEntries,
        )..where((e) => e.id.equals(entry.id))).write(
          OutboxEntriesCompanion(
            attempts: Value(entry.attempts + 1),
            lastError: Value(error.toString()),
          ),
        );
        developer.log(
          'Sync failed for outbox #${entry.id} (${entry.opType}); '
          'stopping drain.',
          name: 'sync',
          error: error,
          stackTrace: stackTrace,
        );
        break;
      }
    }
  }

  Future<void> _dispatch(SyncBackend backend, OutboxEntry entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    switch (entry.opType) {
      case 'upsert_transaction':
        await backend.upsertTransaction(payload);
      case 'delete_transaction':
        await backend.deleteTransaction(payload['id'] as String);
      case 'mark_no_spend':
        await backend.markNoSpend(payload['date'] as String);
      case 'mark_activity':
        await backend.markActivity(
          payload['date'] as String,
          (payload['kinds'] as List).cast<String>(),
        );
      default:
        // opType necunoscut: se ignoră, ca să nu blocheze coada la nesfârșit.
        developer.log('Unknown outbox opType: ${entry.opType}', name: 'sync');
    }
  }

  /// Șterge `pendingSync` pe tranzacția sincronizată cu succes (no-op
  /// pentru operații non-tranzacție).
  Future<void> _clearPending(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final clientId = switch (entry.opType) {
      'upsert_transaction' => payload['client_id'] as String?,
      'delete_transaction' => payload['id'] as String?,
      _ => null,
    };
    if (clientId == null) return;
    await (_db.update(_db.localTransactions)
          ..where((t) => t.id.equals(clientId)))
        .write(const LocalTransactionsCompanion(pendingSync: Value(false)));
  }

  void dispose() => _debounce?.cancel();
}
