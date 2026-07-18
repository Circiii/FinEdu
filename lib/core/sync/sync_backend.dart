import 'package:supabase_flutter/supabase_flutter.dart';

/// Interfața restrânsă prin care [SyncEngine] vorbește cu serverul.
/// Abstractizată ca engine-ul să poată fi testat cu un backend fals, fără rețea reală.
abstract interface class SyncBackend {
  /// Dacă există o sesiune autentificată acum (necesară pentru RLS).
  bool get hasSession;

  /// Upsert pe o tranzacție, cheie (user_id, client_id) pentru idempotență.
  Future<void> upsertTransaction(Map<String, dynamic> payload);

  /// Marchează o tranzacție ca ștearsă pe server (soft delete).
  Future<void> deleteTransaction(String clientId);

  /// Înregistrează o zi fără cheltuieli, cheie (user_id, date).
  Future<void> markNoSpend(String date);

  /// Upsert pe tipurile de activitate ale zilei, cheie (user_id, date).
  Future<void> markActivity(String date, List<String> kinds);
}

/// [SyncBackend] susținut de un [SupabaseClient] live. `user_id` vine din
/// JWT via RLS/column defaults; payload-urile duc doar `client_id` și conținutul.
class SupabaseSyncBackend implements SyncBackend {
  SupabaseSyncBackend(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Future<void> upsertTransaction(Map<String, dynamic> payload) async {
    await _client.from('transactions').upsert(
      {...payload, 'user_id': _userId},
      onConflict: 'user_id,client_id',
    );
  }

  @override
  Future<void> deleteTransaction(String clientId) async {
    await _client
        .from('transactions')
        .update({'deleted': true})
        .eq('user_id', _userId)
        .eq('client_id', clientId);
  }

  @override
  Future<void> markNoSpend(String date) async {
    await _client.from('no_spend_days').upsert(
      {'user_id': _userId, 'date': date},
      onConflict: 'user_id,date',
    );
  }

  @override
  Future<void> markActivity(String date, List<String> kinds) async {
    await _client.from('daily_activity').upsert(
      {'user_id': _userId, 'date': date, 'kinds': kinds},
      onConflict: 'user_id,date',
    );
  }
}
