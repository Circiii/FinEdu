import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Inițializează Supabase doar dacă backend-ul e configurat
/// ([AppConfig.hasBackend]); dacă da și nu există sesiune, se autentifică
/// anonim (identitate pentru RLS). Totul e în try/catch: la eșec continuăm
/// offline pe drift local, sync engine reîncearcă mai târziu.
Future<void> initSupabaseIfConfigured() async {
  if (!AppConfig.hasBackend) {
    developer.log(
      'No backend configured; running offline-only.',
      name: 'supabase',
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // anonKey e deprecated în supabase_flutter 2.15+; se trimite ca publishableKey (aceeași valoare).
      publishableKey: AppConfig.supabaseAnonKey,
    );

    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
  } catch (error, stackTrace) {
    developer.log(
      'Supabase bootstrap failed; continuing offline.',
      name: 'supabase',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
