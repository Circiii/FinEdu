/// Starea imutabilă a unui run din „30 de Zile", instantaneu complet și
/// serializabil (round-trip JSON pe fiecare câmp, pentru resume din snapshot).
/// Clasă scrisă de mână cu `copyWith` (fără freezed pe motoare).
///
/// Bani ca `Money` (int), niciodată double, determinismul same-seed nu
/// suportă erori de virgulă. Cash-ul poate fi negativ; fondul și obiectivul
/// se taie la 0; stat-urile la 0-100.
library;

import 'money.dart';
import 'life_sim_effects.dart' show LifeEffect;

// ---------------------------------------------------------------------------
// Sub-modele
// ---------------------------------------------------------------------------

/// Cele 4 stat-uri de viață, fiecare 0-100 (imutabile, mereu clampate).
class LifeStats {
  const LifeStats({
    required this.health,
    required this.energy,
    required this.stress,
    required this.relationships,
  });

  /// Baseline de start: sănătos, odihnit, stres mic, relații decente.
  factory LifeStats.initial() =>
      const LifeStats(health: 75, energy: 75, stress: 25, relationships: 70);

  factory LifeStats.fromJson(Map<String, dynamic> j) => LifeStats(
    health: j['health'] as int,
    energy: j['energy'] as int,
    stress: j['stress'] as int,
    relationships: j['relationships'] as int,
  );

  final int health;
  final int energy;
  final int stress;
  final int relationships;

  static int _clamp(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);

  /// Valoarea unui stat după nume (folosit de condiții/scoring).
  int get(String stat) => switch (stat) {
    'health' => health,
    'energy' => energy,
    'stress' => stress,
    'relationships' => relationships,
    _ => throw FormatException('stat necunoscut: $stat'),
  };

  /// Aplică un delta pe un stat, clampat 0-100.
  LifeStats withDelta(String stat, int delta) => switch (stat) {
    'health' => copyWith(health: _clamp(health + delta)),
    'energy' => copyWith(energy: _clamp(energy + delta)),
    'stress' => copyWith(stress: _clamp(stress + delta)),
    'relationships' => copyWith(relationships: _clamp(relationships + delta)),
    _ => throw FormatException('stat necunoscut: $stat'),
  };

  LifeStats copyWith({
    int? health,
    int? energy,
    int? stress,
    int? relationships,
  }) => LifeStats(
    health: health ?? this.health,
    energy: energy ?? this.energy,
    stress: stress ?? this.stress,
    relationships: relationships ?? this.relationships,
  );

  Map<String, dynamic> toJson() => {
    'health': health,
    'energy': energy,
    'stress': stress,
    'relationships': relationships,
  };

  @override
  bool operator ==(Object other) =>
      other is LifeStats &&
      other.health == health &&
      other.energy == energy &&
      other.stress == stress &&
      other.relationships == relationships;

  @override
  int get hashCode => Object.hash(health, energy, stress, relationships);
}

/// O datorie activă. [interestFreeUntil] = ziua până la care nu curge dobânda;
/// v1 nu auto-acumulează dobânda în motor, câmpul e pinuit pentru viitor.
class DebtState {
  const DebtState({
    required this.id,
    required this.principal,
    required this.monthly,
    required this.dueDay,
    this.interestFreeUntil,
  });

  factory DebtState.fromJson(Map<String, dynamic> j) => DebtState(
    id: j['id'] as String,
    principal: Money.fromJson(j['principal'] as int),
    monthly: Money.fromJson(j['monthly'] as int),
    dueDay: j['dueDay'] as int,
    interestFreeUntil: j['interestFreeUntil'] as int?,
  );

  final String id;
  final Money principal;
  final Money monthly;
  final int dueDay;
  final int? interestFreeUntil;

  DebtState copyWith({Money? principal, Money? monthly, int? dueDay}) =>
      DebtState(
        id: id,
        principal: principal ?? this.principal,
        monthly: monthly ?? this.monthly,
        dueDay: dueDay ?? this.dueDay,
        interestFreeUntil: interestFreeUntil,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'principal': principal.toJson(),
    'monthly': monthly.toJson(),
    'dueDay': dueDay,
    if (interestFreeUntil != null) 'interestFreeUntil': interestFreeUntil,
  };

  @override
  bool operator ==(Object other) =>
      other is DebtState &&
      other.id == id &&
      other.principal == principal &&
      other.monthly == monthly &&
      other.dueDay == dueDay &&
      other.interestFreeUntil == interestFreeUntil;

  @override
  int get hashCode =>
      Object.hash(id, principal, monthly, dueDay, interestFreeUntil);
}

/// Un pachet de efecte programat să se declanșeze într-o zi viitoare.
/// [sourceEventId] leagă efectul de decizia care l-a creat, pentru debrief.
class ScheduledEffect {
  const ScheduledEffect({
    required this.fireOnDay,
    required this.effects,
    required this.note,
    this.sourceEventId,
  });

  factory ScheduledEffect.fromJson(Map<String, dynamic> j) => ScheduledEffect(
    fireOnDay: j['fireOnDay'] as int,
    effects: [
      for (final e in (j['effects'] as List).cast<Map<String, dynamic>>())
        LifeEffect.fromJson(e),
    ],
    note: j['note'] as String,
    sourceEventId: j['sourceEventId'] as String?,
  );

  final int fireOnDay;
  final List<LifeEffect> effects;
  final String note;
  final String? sourceEventId;

  Map<String, dynamic> toJson() => {
    'fireOnDay': fireOnDay,
    'effects': [for (final e in effects) e.toJson()],
    'note': note,
    if (sourceEventId != null) 'sourceEventId': sourceEventId,
  };
}

/// O decizie luată de jucător (intrare în ledger-ul deciziilor).
class DecisionRecord {
  const DecisionRecord({
    required this.day,
    required this.eventId,
    required this.choiceIdx,
  });

  factory DecisionRecord.fromJson(Map<String, dynamic> j) => DecisionRecord(
    day: j['day'] as int,
    eventId: j['eventId'] as String,
    choiceIdx: j['choiceIdx'] as int,
  );

  final int day;
  final String eventId;
  final int choiceIdx;

  Map<String, dynamic> toJson() => {
    'day': day,
    'eventId': eventId,
    'choiceIdx': choiceIdx,
  };

  @override
  bool operator ==(Object other) =>
      other is DecisionRecord &&
      other.day == day &&
      other.eventId == eventId &&
      other.choiceIdx == choiceIdx;

  @override
  int get hashCode => Object.hash(day, eventId, choiceIdx);
}

/// Urma unui efect programat deja declanșat, ledger-ul consecințelor
/// materializate, folosit de debrief pentru a atribui rezultatul deciziei-sursă.
class FiredEffect {
  const FiredEffect({
    required this.day,
    required this.note,
    required this.cashDelta,
    required this.fundDelta,
    required this.goalDelta,
    this.sourceEventId,
  });

  factory FiredEffect.fromJson(Map<String, dynamic> j) => FiredEffect(
    day: j['day'] as int,
    note: j['note'] as String,
    cashDelta: Money.fromJson(j['cashDelta'] as int),
    fundDelta: Money.fromJson(j['fundDelta'] as int),
    goalDelta: Money.fromJson(j['goalDelta'] as int),
    sourceEventId: j['sourceEventId'] as String?,
  );

  final int day;
  final String note;
  final Money cashDelta;
  final Money fundDelta;
  final Money goalDelta;
  final String? sourceEventId;

  Map<String, dynamic> toJson() => {
    'day': day,
    'note': note,
    'cashDelta': cashDelta.toJson(),
    'fundDelta': fundDelta.toJson(),
    'goalDelta': goalDelta.toJson(),
    if (sourceEventId != null) 'sourceEventId': sourceEventId,
  };
}

// ---------------------------------------------------------------------------
// Starea principală
// ---------------------------------------------------------------------------

class LifeSimState {
  const LifeSimState({
    required this.day,
    required this.cash,
    required this.emergencyFund,
    required this.goalSavings,
    required this.debts,
    required this.bills,
    required this.stats,
    required this.jobStability,
    required this.flags,
    required this.scheduledEffects,
    required this.scheduledEvents,
    required this.completedEvents,
    required this.decisions,
    required this.categoryCounts,
    required this.missedBills,
    required this.paidBillsOnTime,
    required this.penaltiesPaid,
    required this.fundUsed,
    required this.eventLastSeen,
    required this.firedEffects,
    required this.daysCashNegative,
    required this.seed,
    required this.contentVersion,
    required this.mode,
    required this.roleId,
    required this.goalId,
    required this.goalTarget,
    this.lastEventDay,
    this.lastEventCategory,
    this.lastEventDifficulty,
    this.arrears = const [],
  });

  /// Ziua curentă (0 la crearea run-ului; [1..30] pe parcurs).
  final int day;

  final Money cash;
  final Money emergencyFund;
  final Money goalSavings;

  final List<DebtState> debts;

  /// Id-urile recurentelor active (chirie, utilități, abonamente...).
  final List<String> bills;

  final LifeStats stats;

  /// Stabilitatea jobului 0-100 (concedierile/bonusurile o mișcă).
  final int jobStability;

  final Set<String> flags;

  final List<ScheduledEffect> scheduledEffects;

  /// Evenimente-consecință programate: (ziua declanșării, id eveniment).
  final List<(int, String)> scheduledEvents;

  final Set<String> completedEvents;

  // --- Bookkeeping pentru director
  final int? lastEventDay;
  final String? lastEventCategory;

  /// Dificultatea ultimului eveniment, regula anti-hammer are nevoie de
  /// intensitate, nu doar de categorie.
  final int? lastEventDifficulty;

  final List<DecisionRecord> decisions;

  /// Câte evenimente per categorie au apărut (echilibrul directorului).
  final Map<String, int> categoryCounts;

  // --- Ledger financiar (hrănește scorul + debrief)
  /// Facturi ratate: (id, ziua scadenței).
  final List<(String, int)> missedBills;

  /// Restanțe active: facturi ratate care se sting automat când intră cash
  /// (id recurentă, ziua scadenței ratate). Cheie opțională la fromJson.
  final List<(String, int)> arrears;
  final int paidBillsOnTime;
  final Money penaltiesPaid;
  final Money fundUsed;

  /// Ultima zi în care a apărut fiecare eveniment (cooldown-ul directorului).
  final Map<String, int> eventLastSeen;

  /// Consecințele întârziate deja materializate (lineage pentru debrief).
  final List<FiredEffect> firedEffects;

  /// Câte zile s-au încheiat cu cash < 0 (ponderea „cash≥0" din scor).
  final int daysCashNegative;

  // --- Pinuri de run (nu se schimbă după createRun)
  final int seed;
  final String contentVersion;
  final String mode; // 'ghidat' | 'realist'
  final String roleId;
  final String goalId;
  final Money goalTarget;

  /// Datoria totală curentă (suma principalelor).
  Money get totalDebt => debts.fold(Money.zero, (sum, d) => sum + d.principal);

  LifeSimState copyWith({
    int? day,
    Money? cash,
    Money? emergencyFund,
    Money? goalSavings,
    List<DebtState>? debts,
    List<String>? bills,
    LifeStats? stats,
    int? jobStability,
    Set<String>? flags,
    List<ScheduledEffect>? scheduledEffects,
    List<(int, String)>? scheduledEvents,
    Set<String>? completedEvents,
    int? lastEventDay,
    String? lastEventCategory,
    int? lastEventDifficulty,
    List<DecisionRecord>? decisions,
    Map<String, int>? categoryCounts,
    List<(String, int)>? missedBills,
    List<(String, int)>? arrears,
    int? paidBillsOnTime,
    Money? penaltiesPaid,
    Money? fundUsed,
    Map<String, int>? eventLastSeen,
    List<FiredEffect>? firedEffects,
    int? daysCashNegative,
    int? seed,
    String? contentVersion,
    String? mode,
    String? roleId,
    String? goalId,
    Money? goalTarget,
  }) => LifeSimState(
    day: day ?? this.day,
    cash: cash ?? this.cash,
    emergencyFund: emergencyFund ?? this.emergencyFund,
    goalSavings: goalSavings ?? this.goalSavings,
    debts: debts ?? this.debts,
    bills: bills ?? this.bills,
    stats: stats ?? this.stats,
    jobStability: jobStability ?? this.jobStability,
    flags: flags ?? this.flags,
    scheduledEffects: scheduledEffects ?? this.scheduledEffects,
    scheduledEvents: scheduledEvents ?? this.scheduledEvents,
    completedEvents: completedEvents ?? this.completedEvents,
    lastEventDay: lastEventDay ?? this.lastEventDay,
    lastEventCategory: lastEventCategory ?? this.lastEventCategory,
    lastEventDifficulty: lastEventDifficulty ?? this.lastEventDifficulty,
    decisions: decisions ?? this.decisions,
    categoryCounts: categoryCounts ?? this.categoryCounts,
    missedBills: missedBills ?? this.missedBills,
    arrears: arrears ?? this.arrears,
    paidBillsOnTime: paidBillsOnTime ?? this.paidBillsOnTime,
    penaltiesPaid: penaltiesPaid ?? this.penaltiesPaid,
    fundUsed: fundUsed ?? this.fundUsed,
    eventLastSeen: eventLastSeen ?? this.eventLastSeen,
    firedEffects: firedEffects ?? this.firedEffects,
    daysCashNegative: daysCashNegative ?? this.daysCashNegative,
    seed: seed ?? this.seed,
    contentVersion: contentVersion ?? this.contentVersion,
    mode: mode ?? this.mode,
    roleId: roleId ?? this.roleId,
    goalId: goalId ?? this.goalId,
    goalTarget: goalTarget ?? this.goalTarget,
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'cash': cash.toJson(),
    'emergencyFund': emergencyFund.toJson(),
    'goalSavings': goalSavings.toJson(),
    'debts': [for (final d in debts) d.toJson()],
    'bills': bills,
    'stats': stats.toJson(),
    'jobStability': jobStability,
    'flags': flags.toList(),
    'scheduledEffects': [for (final e in scheduledEffects) e.toJson()],
    'scheduledEvents': [
      for (final e in scheduledEvents) {'day': e.$1, 'eventId': e.$2},
    ],
    'completedEvents': completedEvents.toList(),
    if (lastEventDay != null) 'lastEventDay': lastEventDay,
    if (lastEventCategory != null) 'lastEventCategory': lastEventCategory,
    if (lastEventDifficulty != null) 'lastEventDifficulty': lastEventDifficulty,
    'decisions': [for (final d in decisions) d.toJson()],
    'categoryCounts': categoryCounts,
    'missedBills': [
      for (final m in missedBills) {'id': m.$1, 'day': m.$2},
    ],
    'arrears': [
      for (final a in arrears) {'id': a.$1, 'day': a.$2},
    ],
    'paidBillsOnTime': paidBillsOnTime,
    'penaltiesPaid': penaltiesPaid.toJson(),
    'fundUsed': fundUsed.toJson(),
    'eventLastSeen': eventLastSeen,
    'firedEffects': [for (final f in firedEffects) f.toJson()],
    'daysCashNegative': daysCashNegative,
    'seed': seed,
    'contentVersion': contentVersion,
    'mode': mode,
    'roleId': roleId,
    'goalId': goalId,
    'goalTarget': goalTarget.toJson(),
  };

  factory LifeSimState.fromJson(Map<String, dynamic> j) => LifeSimState(
    day: j['day'] as int,
    cash: Money.fromJson(j['cash'] as int),
    emergencyFund: Money.fromJson(j['emergencyFund'] as int),
    goalSavings: Money.fromJson(j['goalSavings'] as int),
    debts: [
      for (final d in (j['debts'] as List).cast<Map<String, dynamic>>())
        DebtState.fromJson(d),
    ],
    bills: (j['bills'] as List).cast<String>(),
    stats: LifeStats.fromJson(j['stats'] as Map<String, dynamic>),
    jobStability: j['jobStability'] as int,
    flags: (j['flags'] as List).cast<String>().toSet(),
    scheduledEffects: [
      for (final e
          in (j['scheduledEffects'] as List).cast<Map<String, dynamic>>())
        ScheduledEffect.fromJson(e),
    ],
    scheduledEvents: [
      for (final e
          in (j['scheduledEvents'] as List).cast<Map<String, dynamic>>())
        (e['day'] as int, e['eventId'] as String),
    ],
    completedEvents: (j['completedEvents'] as List).cast<String>().toSet(),
    lastEventDay: j['lastEventDay'] as int?,
    lastEventCategory: j['lastEventCategory'] as String?,
    lastEventDifficulty: j['lastEventDifficulty'] as int?,
    decisions: [
      for (final d in (j['decisions'] as List).cast<Map<String, dynamic>>())
        DecisionRecord.fromJson(d),
    ],
    categoryCounts: (j['categoryCounts'] as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    ),
    missedBills: [
      for (final m in (j['missedBills'] as List).cast<Map<String, dynamic>>())
        (m['id'] as String, m['day'] as int),
    ],
    arrears: j['arrears'] == null
        ? const []
        : [
            for (final a in (j['arrears'] as List).cast<Map<String, dynamic>>())
              (a['id'] as String, a['day'] as int),
          ],
    paidBillsOnTime: j['paidBillsOnTime'] as int,
    penaltiesPaid: Money.fromJson(j['penaltiesPaid'] as int),
    fundUsed: Money.fromJson(j['fundUsed'] as int),
    eventLastSeen: (j['eventLastSeen'] as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    ),
    firedEffects: [
      for (final f in (j['firedEffects'] as List).cast<Map<String, dynamic>>())
        FiredEffect.fromJson(f),
    ],
    daysCashNegative: j['daysCashNegative'] as int,
    seed: j['seed'] as int,
    contentVersion: j['contentVersion'] as String,
    mode: j['mode'] as String,
    roleId: j['roleId'] as String,
    goalId: j['goalId'] as String,
    goalTarget: Money.fromJson(j['goalTarget'] as int),
  );
}
