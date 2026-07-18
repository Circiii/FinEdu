import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_db.dart';
import 'db_provider.dart';

final localProfileRepositoryProvider = Provider<LocalProfileRepository>((ref) {
  return LocalProfileRepository(ref.watch(appDbProvider));
});

/// Acces la profilul cu un singur rând (id = 0, creat la prima citire).
/// Onboarding-ul îl scrie pas cu pas; Home și guard-urile îl citesc/urmăresc.
class LocalProfileRepository {
  LocalProfileRepository(this._db);

  final AppDb _db;

  Future<LocalProfile> get() async {
    final row = await (_db.select(_db.localProfiles)
          ..where((p) => p.id.equals(0)))
        .getSingleOrNull();
    if (row != null) return row;
    await _db
        .into(_db.localProfiles)
        .insert(const LocalProfilesCompanion(id: Value(0)));
    return (_db.select(_db.localProfiles)..where((p) => p.id.equals(0)))
        .getSingle();
  }

  Stream<LocalProfile?> watch() {
    return (_db.select(_db.localProfiles)..where((p) => p.id.equals(0)))
        .watchSingleOrNull();
  }

  /// Update parțial; rândul e creat întâi dacă nu există încă.
  Future<void> update(LocalProfilesCompanion changes) async {
    await get();
    await (_db.update(_db.localProfiles)..where((p) => p.id.equals(0)))
        .write(changes);
  }

  /// Creditează (sau debitează, cu delta negativ) ghindele locale: scrie
  /// intrarea în ledger și actualizează balanța. Balanța nu scade sub zero.
  Future<int> addAcorns(int delta, {String reason = 'misc'}) async {
    final profile = await get();
    final next = (profile.acorns + delta).clamp(0, 1 << 31);
    await _db.into(_db.acornEntries).insert(AcornEntriesCompanion.insert(
          delta: delta,
          reason: reason,
          createdAt: DateTime.now(),
        ));
    await update(LocalProfilesCompanion(acorns: Value(next)));
    return next;
  }
}
