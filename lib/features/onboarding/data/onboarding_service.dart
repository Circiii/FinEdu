import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/db/local_profile_repository.dart';
import '../../tracking/data/transactions_repository.dart';

/// Pașii wizard-ului de onboarding, în ordine; `parent` apare doar pe ruta under-16.
enum OnbStep { egg, ceremony, quiz, age, parent, budget, expense, week, notif }

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(
    ref.watch(localProfileRepositoryProvider),
    ref.watch(transactionsRepositoryProvider),
    ref.watch(appDbProvider),
  );
});

/// Persistare pas-cu-pas pentru fluxul de activare. Fiecare pas scrie imediat
/// în profilul local, deci un restart la mijloc reia la primul pas cu date lipsă.
class OnboardingService {
  OnboardingService(this._profiles, this._transactions, this._db);

  final LocalProfileRepository _profiles;
  final TransactionsRepository _transactions;
  final AppDb _db;

  /// Primul pas cu date lipsă (punctul de reluare după restart). Egg/ceremony
  /// se reiau cu quiz-ul, același intro de 60s, fără marker de sub-pas.
  Future<OnbStep> resumeStep() async {
    final p = await _profiles.get();
    if (p.quizSeed == null) return OnbStep.egg;
    if (p.ageBand == null) return OnbStep.age;
    if (p.ageBand == '14_15' &&
        p.parentalStatus == 'pending' &&
        (p.parentEmail == null || p.parentEmail!.isEmpty)) {
      return OnbStep.parent;
    }
    if (p.monthlyBudget == null) return OnbStep.budget;
    if (!await _hasAnyActivity()) return OnbStep.expense;
    return OnbStep.week;
  }

  Future<bool> _hasAnyActivity() async {
    final row = await (_db.select(
      _db.dailyActivityRows,
    )..limit(1)).getSingleOrNull();
    return row != null;
  }

  Future<void> saveCeremony({required String name, required String color}) {
    return _profiles.update(
      LocalProfilesCompanion(cashyName: Value(name), cashyColor: Value(color)),
    );
  }

  /// Persistă răspunsurile la quiz (seed Elo) și creditează +5 ghinde.
  Future<void> saveQuiz(List<int> answers) async {
    await _profiles.update(
      LocalProfilesCompanion(quizSeed: Value(jsonEncode(answers))),
    );
    await _profiles.addAcorns(5);
  }

  /// Derivă banda + track-ul din anul nașterii; stochează doar pe astea,
  /// niciodată anul (AADC). Întoarce banda, sau null sub 14 ani.
  Future<String?> saveAge(int birthYear) async {
    final age = DateTime.now().year - birthYear;
    if (age < 14) return null;
    final band = age <= 15 ? '14_15' : (age <= 17 ? '16_17' : '18_25');
    final track = age <= 18 ? 'A' : 'B';
    await _profiles.update(
      LocalProfilesCompanion(
        ageBand: Value(band),
        track: Value(track),
        parentalStatus: Value(band == '14_15' ? 'pending' : 'not_required'),
      ),
    );
    return band;
  }

  Future<void> saveParentEmail(String email) {
    return _profiles.update(
      LocalProfilesCompanion(
        parentEmail: Value(email),
        parentalStatus: const Value('pending'),
      ),
    );
  }

  Future<void> saveBudget(double budget) {
    return _profiles.update(
      LocalProfilesCompanion(monthlyBudget: Value(budget)),
    );
  }

  /// Loghează prima cheltuială ghidată (+2 ghinde, ca orice log).
  Future<void> logFirstExpense({
    required double amount,
    required String category,
  }) async {
    await _transactions.addExpense(amount: amount, category: category);
    await _profiles.addAcorns(2);
  }

  /// Alternativă: azi a fost o zi fără cheltuieli (tot +2 ghinde, contează
  /// obiceiul, nu cheltuiala).
  Future<void> markNoSpend() async {
    await _transactions.markNoSpendToday();
    await _profiles.addAcorns(2);
  }

  /// Poarta se deschide, userul e onboarded.
  Future<void> completeWeekStep() {
    return _profiles.update(
      const LocalProfilesCompanion(onboarded: Value(true)),
    );
  }

  /// 'accepted' | 'later'.
  Future<void> saveNotifChoice(String choice) {
    return _profiles.update(LocalProfilesCompanion(notifChoice: Value(choice)));
  }
}
