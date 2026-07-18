import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../tracking/data/transactions_repository.dart';

/// Profilul local (rând unic) ca stream (nume, buget, ghinde...).
final localProfileStreamProvider = StreamProvider<LocalProfile?>((ref) {
  return ref.watch(localProfileRepositoryProvider).watch();
});

/// Ultimele 5 tranzacții (lista din Home).
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionsRepositoryProvider).watchRecent(5);
});

/// Toate tranzacțiile din luna calendaristică curentă (inelul de buget + segmente).
final monthTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref
      .watch(transactionsRepositoryProvider)
      .watchMonth(DateTime.now());
});

/// Fiecare zi cu activitate înregistrată, input pentru streak engine.
final activityDaysProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(transactionsRepositoryProvider).watchActivityDays();
});
