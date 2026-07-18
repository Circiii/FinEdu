import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

// ---------------------------------------------------------------------------
// Tabele
// ---------------------------------------------------------------------------

/// Oglinda locală a tabelului `transactions` de pe server; sursa de adevăr
/// offline. `id` e un uuid v4 client-generat care devine `client_id` pe
/// server (cheie de idempotență pentru sync).
class LocalTransactions extends Table {
  TextColumn get id => text()();
  // Idiom drift: self-reference în check(); lintul recursive_getters e fals pozitiv aici.
  // ignore: recursive_getters
  RealColumn get amount => real().check(amount.isBiggerThanValue(0))();
  TextColumn get category => text()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  /// Doar la saving: goalId-ul alimentat. Progresul e DERIVAT din aceste
  /// rânduri, nu ținut într-un contor separat.
  TextColumn get goalId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Șablon de tranzacție recurentă. Materializer-ul emite tranzacții reale
/// când `nextDueDate` e scadentă, avansând data; rulează client-side la
/// pornirea aplicației (fără cron pe server încă).
class LocalRecurring extends Table {
  TextColumn get id => text()(); // uuid v4
  TextColumn get merchant => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get frequency =>
      text().withDefault(const Constant('monthly'))(); // daily|weekly|monthly
  TextColumn get nextDueDate => text()(); // yyyy-MM-dd
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Obiectiv de economisire. `currentAmount` e derivat: suma tranzacțiilor
/// de saving nedeletate cu acest goalId.
class LocalGoals extends Table {
  TextColumn get id => text()(); // uuid v4
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  TextColumn get emoji => text().withDefault(const Constant('🎯'))();
  TextColumn get deadline => text().nullable()(); // yyyy-MM-dd
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// „Azi n-am cheltuit nimic", o zi fără cheltuieli e informație, nu absență.
/// Un rând pe zi (yyyy-MM-dd).
class NoSpendDays extends Table {
  TextColumn get date => text()();

  @override
  Set<Column> get primaryKey => {date};
}

/// Alimentează streak-ul. Un rând pe zi; `kinds` e o listă JSON cu tipurile
/// de activitate din ziua respectivă, ex. `["log","lesson"]`.
class DailyActivityRows extends Table {
  TextColumn get date => text()();
  TextColumn get kinds => text()(); // JSON-encoded List<String>

  @override
  Set<Column> get primaryKey => {date};
}

/// Outbox durabil: fiecare mutație pune o operație aici; sync engine le
/// consumă FIFO. `payload` e JSON specific operației.
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opType => text()();
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Profil local, un singur rând (id = 0); sincronizat cu `profiles` pe server.
class LocalProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get cashyName => text().withDefault(const Constant('Cashy'))();

  /// Una din: sky | mint | amber | violet (nuanțe din paleta clay).
  TextColumn get cashyColor => text().withDefault(const Constant('sky'))();

  /// Itemul echipat per slot din garderobă (id din wardrobe.json).
  TextColumn get equippedBackground => text().nullable()();
  TextColumn get equippedAccessory => text().nullable()();

  /// Una din: 14_15 | 16_17 | 18_25 (nu se stochează niciodată anul exact de naștere).
  TextColumn get ageBand => text().nullable()();

  /// Track curriculum: A (14-18) | B (19+).
  TextColumn get track => text().nullable()();
  RealColumn get monthlyBudget => real().nullable()();
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();

  /// Rezultat soft-ask: unset | accepted | later.
  TextColumn get notifChoice => text().withDefault(const Constant('unset'))();
  TextColumn get parentEmail => text().nullable()();

  /// not_required | pending | confirmed.
  TextColumn get parentalStatus =>
      text().withDefault(const Constant('not_required'))();

  /// Balanța locală de ghinde, până apare ledger-ul pe server.
  IntColumn get acorns => integer().withDefault(const Constant(0))();

  /// XP de învățare (300/nivel). Persistat, spre deosebire de contoarele
  /// efemere din prototipul web.
  IntColumn get xp => integer().withDefault(const Constant(0))();

  /// JSON cu răspunsurile la chestionarul de onboarding (seed Elo).
  TextColumn get quizSeed => text().nullable()();

  /// Personalizare inteligentă: opt-in explicit, DEFAULT OFF (AADC/GDPR,
  /// profilarea minorilor nu e niciodată default). Fără ea, totul cade pe
  /// regulile statice.
  BoolColumn get personalizationOn =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stare completă de streak, un singur rând (id=0); vezi
/// domain/engine/streak_rules.dart. Coloanele JSON țin seturi de string-uri.
class StreakStates extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get freezes => integer().withDefault(const Constant(2))();
  TextColumn get frozenDays => text().withDefault(const Constant('[]'))();
  IntColumn get earnbackValue => integer().withDefault(const Constant(0))();
  TextColumn get earnbackUntil => text().nullable()();
  TextColumn get earnbackGap => text().withDefault(const Constant('[]'))();
  TextColumn get claimedMilestones =>
      text().withDefault(const Constant('[]'))();
  TextColumn get lastEvaluated => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ledger local de ghinde: fiecare credit/debit cu un motiv (audit acum,
/// sync cu `acorn_ledger` pe server mai târziu). Snapshot-ul de balanță
/// stă pe LocalProfiles.acorns.
class AcornEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get delta => integer()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Un quest zilnic revendicat (finalizarea în sine e derivată, nu stocată).
class QuestClaims extends Table {
  TextColumn get date => text()();
  IntColumn get slot => integer()();
  DateTimeColumn get claimedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date, slot};
}

/// Starea cufărului zilnic (un rând): câștigat când toate cele 3 quest-uri
/// sunt revendicate, deschidere posibilă doar a doua zi.
class ChestStates extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get earnedDate => text().nullable()();
  TextColumn get openedDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// O lecție finalizată (conținutul stă în assets; se stochează doar progresul).
class LessonProgressRows extends Table {
  TextColumn get lessonId => text()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lessonId};
}

/// Coada de review pentru carduri. FSRS (domain/engine/fsrs.dart) programează
/// via `stability`/`difficulty`/`lastReview`; `box` rămâne doar un bucket
/// derivat pentru `dueCards()` și UI legacy. Cardurile vechi (stability NULL)
/// se migrează lazy din `box` la prima notare.
class ReviewCards extends Table {
  TextColumn get cardId => text()();
  TextColumn get lessonId => text()();
  IntColumn get box => integer().withDefault(const Constant(1))();
  TextColumn get nextDue => text()(); // yyyy-MM-dd
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// NULL = card moștenit, neatins încă de FSRS. `lastReview` e day-key `yyyy-MM-dd`.
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  TextColumn get lastReview => text().nullable()();

  @override
  Set<Column> get primaryKey => {cardId};
}

/// O rundă de Arcade jucată. Provocarea Zilei permite un singur rând pe zi
/// (verificat în repository); Turbo Buget/Dojo adaugă la fiecare rundă,
/// scorurile maxime și bonusurile de prima-rundă-a-zilei sunt derivate.
class ArcadeRounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get game => text()(); // 'dojo' | 'daily' | 'turbo'
  TextColumn get date => text()(); // yyyy-MM-dd
  IntColumn get score => integer()();
  TextColumn get meta => text().withDefault(const Constant('{}'))();
}

/// Ratingul Elo al jucătorului + contorul de runde (un singur rând).
class DojoStates extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get rating => integer().withDefault(const Constant(1000))();
  IntColumn get rounds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Statistici Elo per mesaj. Conținutul stă în asset-ul JSON; rândul ține
/// doar ratingul auto-calibrat și recența (pentru selecția rundelor).
class DojoItemStats extends Table {
  TextColumn get itemId => text()();
  IntColumn get rating => integer()();
  IntColumn get plays => integer().withDefault(const Constant(0))();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get lastSeenRound => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {itemId};
}

/// Itemele deținute din garderoba lui Cashy. Catalogul (prețuri, tier-uri)
/// e în content/cashy/wardrobe.json; cumpărarea inserează doar rândul de
/// proprietate, echiparea stă pe LocalProfiles.
class WardrobeItems extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get acquiredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}

/// Istoricul cardurilor „Pentru tine": cooldown-uri, raportul 2:1 și
/// suprimarea locală (3 dismiss-uri fără tap → tipul se suprimă).
class InsightEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get insightId => text()(); // id-ul candidatului (dedup/cooldown)
  TextColumn get ruleKey => text()(); // tipul regulii (suprimare)
  TextColumn get kind => text()(); // positive|corrective|utility
  TextColumn get event => text()(); // shown|tapped|dismissed
  DateTimeColumn get createdAt => dateTime()();

  /// Brațul de bandit ales pentru varianta afișată și propensity-ul asociat.
  /// Rămân NULL când personalizarea e oprită, istoricul vechi nu se atinge.
  IntColumn get arm => integer().nullable()();
  RealColumn get propensity => real().nullable()();
}

/// Expedițiile lui Cashy: al doilea faucet de ghinde, o expediție pe zi
/// (PK = ziua). Recompensa e ÎNGHEȚATĂ la plecare (determinist din streak
/// + zi), culesul doar o citește.
class ExpeditionRows extends Table {
  TextColumn get day => text()(); // yyyy-MM-dd
  DateTimeColumn get departedAt => dateTime()();
  DateTimeColumn get collectedAt => dateTime().nullable()();
  IntColumn get reward => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Un run al simulării „30 de Zile: Pe Cont Propriu". Motorul
/// (domain/engine/life_sim/*) e sursa de adevăr; aici persistăm doar
/// instantaneul serializat ([stateJson]), ca resume-ul să reconstituie luna
/// bit-cu-bit. Runda e activă cât timp [completedAt] e NULL.
class LifeSimRuns extends Table {
  TextColumn get id => text()(); // uuid v4
  IntColumn get seed => integer()();
  TextColumn get roleId => text()();
  TextColumn get goalId => text()();
  TextColumn get mode => text()(); // 'ghidat' | 'realist'
  TextColumn get contentVersion => text()();
  IntColumn get day => integer().withDefault(const Constant(0))();
  TextColumn get stateJson => text()(); // LifeSimState.toJson snapshot
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get resultJson => text().nullable()(); // LifeSimScore.toJson

  @override
  Set<Column> get primaryKey => {id};
}

/// Ledger-ul deciziilor unui run (o intrare per alegere). Redundant cu
/// `state.decisions` din snapshot, dar util pentru analytics fără a
/// desface JSON-ul de stare.
class LifeSimDecisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get runId => text()();
  IntColumn get day => integer()();
  TextColumn get eventId => text()();
  IntColumn get choiceIdx => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    LocalTransactions,
    NoSpendDays,
    DailyActivityRows,
    OutboxEntries,
    LocalProfiles,
    StreakStates,
    AcornEntries,
    QuestClaims,
    ChestStates,
    LocalGoals,
    LocalRecurring,
    LessonProgressRows,
    ReviewCards,
    ArcadeRounds,
    DojoStates,
    DojoItemStats,
    WardrobeItems,
    InsightEvents,
    ExpeditionRows,
    LifeSimRuns,
    LifeSimDecisions,
  ],
)
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'finedu'));

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(localProfiles);
          if (from < 3) {
            await m.createTable(streakStates);
            await m.createTable(acornEntries);
            await m.createTable(questClaims);
            await m.createTable(chestStates);
          }
          if (from < 4) {
            await m.createTable(localGoals);
            await m.addColumn(localTransactions, localTransactions.goalId);
          }
          if (from < 5) await m.createTable(localRecurring);
          if (from < 6) {
            await m.addColumn(localProfiles, localProfiles.xp);
            await m.createTable(lessonProgressRows);
            await m.createTable(reviewCards);
          }
          if (from < 7) await m.createTable(arcadeRounds);
          if (from < 8) {
            await m.createTable(dojoStates);
            await m.createTable(dojoItemStats);
          }
          if (from < 9) {
            await m.createTable(wardrobeItems);
            await m.addColumn(localProfiles, localProfiles.equippedBackground);
            await m.addColumn(localProfiles, localProfiles.equippedAccessory);
          }
          if (from < 10) await m.createTable(insightEvents);
          if (from < 11) await m.createTable(expeditionRows);
          if (from < 12) {
            await m.addColumn(insightEvents, insightEvents.arm);
            await m.addColumn(insightEvents, insightEvents.propensity);
            await m.addColumn(localProfiles, localProfiles.personalizationOn);
          }
          if (from < 13) {
            // Coloane FSRS; rămân NULL pe cardurile existente → migrare
            // lazy din `box` la prima notare.
            await m.addColumn(reviewCards, reviewCards.stability);
            await m.addColumn(reviewCards, reviewCards.difficulty);
            await m.addColumn(reviewCards, reviewCards.lastReview);
          }
          if (from < 14) {
            // Tabele noi, nimic de migrat.
            await m.createTable(lifeSimRuns);
            await m.createTable(lifeSimDecisions);
          }
        },
      );
}
