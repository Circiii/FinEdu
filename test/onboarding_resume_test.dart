import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/core/db/app_db.dart';
import 'package:finedu_flutter/core/db/local_profile_repository.dart';
import 'package:finedu_flutter/features/onboarding/data/onboarding_service.dart';
import 'package:finedu_flutter/features/tracking/data/transactions_repository.dart';

void main() {
  late AppDb db;
  late OnboardingService service;
  late LocalProfileRepository profiles;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    profiles = LocalProfileRepository(db);
    service = OnboardingService(profiles, TransactionsRepository(db), db);
  });

  tearDown(() => db.close());

  test('fresh install resumes at the egg', () async {
    expect(await service.resumeStep(), OnbStep.egg);
  });

  test('ceremony without quiz still resumes at the egg (intro redoes)',
      () async {
    await service.saveCeremony(name: 'Ronți', color: 'mint');
    expect(await service.resumeStep(), OnbStep.egg);
  });

  test('after quiz → age', () async {
    await service.saveCeremony(name: 'Ronți', color: 'mint');
    await service.saveQuiz([0, 2, 1]);
    expect(await service.resumeStep(), OnbStep.age);
  });

  test('under-16 without parent email → parent; with it → budget', () async {
    await service.saveQuiz([0, 2, 1]);
    final band = await service.saveAge(DateTime.now().year - 15);
    expect(band, '14_15');
    expect(await service.resumeStep(), OnbStep.parent);

    await service.saveParentEmail('mama@exemplu.ro');
    expect(await service.resumeStep(), OnbStep.budget);
  });

  test('under 14 is rejected and nothing is stored', () async {
    final band = await service.saveAge(DateTime.now().year - 12);
    expect(band, isNull);
    expect((await profiles.get()).ageBand, isNull);
  });

  test('the exact birth year is never persisted, only band + track',
      () async {
    await service.saveAge(DateTime.now().year - 17);
    final p = await profiles.get();
    expect(p.ageBand, '16_17');
    expect(p.track, 'A');
    // The LocalProfiles schema has no birth-year column; this asserts the
    // service derives an adult band correctly too.
    await service.saveAge(DateTime.now().year - 22);
    expect((await profiles.get()).track, 'B');
  });

  test('after budget → expense; after any activity → week', () async {
    await service.saveQuiz([0, 2, 1]);
    await service.saveAge(DateTime.now().year - 19);
    await service.saveBudget(800);
    expect(await service.resumeStep(), OnbStep.expense);

    await service.markNoSpend();
    expect(await service.resumeStep(), OnbStep.week);
  });

  test('quiz credits +5 acorns; first expense credits +2 more', () async {
    await service.saveQuiz([0, 2, 1]);
    expect((await profiles.get()).acorns, 5);

    await service.logFirstExpense(amount: 12, category: 'mancare');
    expect((await profiles.get()).acorns, 7);
  });
}
