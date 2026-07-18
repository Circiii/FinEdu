import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../db/db_provider.dart';
import 'sync_backend.dart';
import 'sync_engine.dart';

/// [SyncEngine] la nivel de aplicație. No-op fără backend configurat și
/// sesiune Supabase. Declanșează sync și la schimbări de conectivitate.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDbProvider);

  final SyncBackend? backend = AppConfig.hasBackend
      ? SupabaseSyncBackend(Supabase.instance.client)
      : null;

  final engine = SyncEngine(
    db: db,
    hasBackend: AppConfig.hasBackend,
    backend: backend,
  );

  // Reîncearcă sync-ul de fiecare dată când apare conectivitate.
  StreamSubscription<List<ConnectivityResult>>? sub;
  if (AppConfig.hasBackend) {
    sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) engine.syncNow();
    });
  }

  ref.onDispose(() {
    sub?.cancel();
    engine.dispose();
  });

  return engine;
});
