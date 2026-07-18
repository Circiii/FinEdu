/// Parsere de conținut pentru „30 de Zile", traduc JSON-ul bilingv în modele
/// tipizate. Textele se rezolvă o dată la un locale; după parsare motorul
/// lucrează doar cu String și `Money`, niciodată cu hărți bilingve. Motorul
/// nu atinge `rootBundle`, rămâne Dart pur, testabil offline.
library;

import 'dart:convert';

import 'money.dart';
import 'life_sim_conditions.dart';
import 'life_sim_effects.dart';
import 'life_sim_state.dart';

/// Rezolvă un nod de text bilingv la [locale] (fallback pe 'ro').
String _t(dynamic node, String locale) =>
    ((node as Map)[locale] ?? node['ro']) as String;

// ---------------------------------------------------------------------------
// Modele
// ---------------------------------------------------------------------------

/// Metadata de sursă pentru trasabilitatea cifrelor, implicit
/// `needsExpertReview: true` până la review uman.
class SourceMeta {
  const SourceMeta({
    required this.label,
    this.date,
    this.reviewedBy,
    this.needsExpertReview = true,
  });

  factory SourceMeta.fromJson(Map<String, dynamic>? j) => j == null
      ? const SourceMeta(label: '')
      : SourceMeta(
          label: (j['label'] ?? j['source_label'] ?? '') as String,
          date: (j['date'] ?? j['source_date']) as String?,
          reviewedBy: j['reviewed_by'] as String?,
          needsExpertReview: (j['needs_expert_review'] as bool?) ?? true,
        );

  final String label;
  final String? date;
  final String? reviewedBy;
  final bool needsExpertReview;
}

class LifeSimRole {
  const LifeSimRole({
    required this.id,
    required this.emoji,
    required this.name,
    required this.bio,
    required this.age,
    required this.scenarioNet,
    required this.salaryMin,
    required this.salaryMax,
    required this.payDay,
    required this.salaryVariability,
    required this.cityProfile,
    required this.housing,
    required this.transport,
    required this.initialCash,
    required this.initialFund,
    required this.debts,
    required this.bills,
    required this.benefitFlags,
    required this.risks,
    required this.goalDefault,
    required this.source,
  });

  factory LifeSimRole.fromJson(Map<String, dynamic> j, String locale) {
    final salary = j['salary'] as Map<String, dynamic>;
    return LifeSimRole(
      id: j['id'] as String,
      emoji: (j['emoji'] as String?) ?? '',
      name: _t(j['name'], locale),
      bio: j['bio'] == null ? '' : _t(j['bio'], locale),
      age: (j['age'] as int?) ?? 0,
      scenarioNet: Money.fromLei(salary['scenario_net'] as int),
      salaryMin: Money.fromLei((salary['net_min'] as int?) ?? 0),
      salaryMax: Money.fromLei((salary['net_max'] as int?) ?? 0),
      payDay: (j['pay_day'] as int?) ?? 1,
      salaryVariability:
          ((j['salary_variability'] as num?) ?? 0).toDouble(),
      cityProfile: (j['city_profile'] as String?) ?? 'oras_mare',
      housing: (j['housing'] as String?) ?? '',
      transport: (j['transport'] as String?) ?? '',
      initialCash: Money(j['initial_cash'] as int),
      initialFund: Money(j['initial_fund'] as int),
      debts: [
        for (final d
            in ((j['debts'] as List?) ?? const []).cast<Map<String, dynamic>>())
          DebtState(
            id: d['id'] as String,
            principal: Money(d['principal'] as int),
            monthly: Money(d['monthly'] as int),
            dueDay: d['due_day'] as int,
            interestFreeUntil: d['interest_free_until'] as int?,
          ),
      ],
      bills: ((j['bills'] as List?) ?? const []).cast<String>(),
      benefitFlags: {
        for (final b in ((j['benefits'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
          if (b['kind'] == 'flag') b['id'] as String,
      },
      risks: j['risks'] == null ? '' : _t(j['risks'], locale),
      goalDefault: (j['goal_default'] as String?) ?? '',
      source: SourceMeta.fromJson(salary),
    );
  }

  final String id;
  final String emoji;
  final String name;
  final String bio;
  final int age;

  /// Salariul-scenariu (valoarea de referință a rolului), în `Money`.
  final Money scenarioNet;
  final Money salaryMin;
  final Money salaryMax;
  final int payDay;

  /// Amplitudinea variabilității (0..1), freelancerul are 0,3, salariatul 0.
  final double salaryVariability;

  final String cityProfile;
  final String housing;
  final String transport;
  final Money initialCash;
  final Money initialFund;
  final List<DebtState> debts;
  final List<String> bills;
  final Set<String> benefitFlags;
  final String risks;
  final String goalDefault;
  final SourceMeta source;
}

/// Profil de cost de oraș, multiplicatori pe chirie/utilități/transport.
/// Informativ în v1: rolul poartă deja sumele rezolvate.
class LifeSimCity {
  const LifeSimCity({
    required this.id,
    required this.rentMult,
    required this.utilitiesMult,
    required this.transportMult,
    this.note,
  });

  factory LifeSimCity.fromJson(Map<String, dynamic> j, String locale) =>
      LifeSimCity(
        id: j['id'] as String,
        rentMult: ((j['rent_mult'] as num?) ?? 1).toDouble(),
        utilitiesMult: ((j['utilities_mult'] as num?) ?? 1).toDouble(),
        transportMult: ((j['transport_mult'] as num?) ?? 1).toDouble(),
        note: j['note'] == null ? null : _t(j['note'], locale),
      );

  final String id;
  final double rentMult;
  final double utilitiesMult;
  final double transportMult;
  final String? note;
}

/// Definiție de recurentă (factură/abonament/rată). [missEffects] se aplică
/// atunci când cash-ul nu acoperă scadența.
class RecurringDef {
  const RecurringDef({
    required this.id,
    required this.kind,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.flexible,
    required this.category,
    required this.missEffects,
  });

  factory RecurringDef.fromJson(Map<String, dynamic> j, String locale) =>
      RecurringDef(
        id: j['id'] as String,
        kind: (j['kind'] as String?) ?? 'bill',
        name: _t(j['name'], locale),
        amount: Money(j['amount'] as int),
        dueDay: j['due_day'] as int,
        flexible: (j['flexible'] as bool?) ?? false,
        category: (j['category'] as String?) ?? 'other',
        missEffects: [
          for (final e in ((j['miss_effects'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            LifeEffect.fromJson(e, locale: locale),
        ],
      );

  final String id;
  final String kind;
  final String name;
  final Money amount;
  final int dueDay;
  final bool flexible;
  final String category;
  final List<LifeEffect> missEffects;
}

class LifeChoice {
  const LifeChoice({
    required this.label,
    required this.effects,
    required this.debrief,
  });

  factory LifeChoice.fromJson(Map<String, dynamic> j, String locale) =>
      LifeChoice(
        label: _t(j['label'], locale),
        effects: [
          for (final e in ((j['effects'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            LifeEffect.fromJson(e, locale: locale),
        ],
        debrief: j['debrief'] == null ? '' : _t(j['debrief'], locale),
      );

  final String label;
  final List<LifeEffect> effects;
  final String debrief;
}

class LifeSimEvent {
  const LifeSimEvent({
    required this.id,
    required this.category,
    required this.rarity,
    required this.weight,
    required this.cooldownDays,
    required this.minDay,
    required this.maxDay,
    required this.roleTags,
    required this.difficulty,
    required this.conditions,
    required this.exclusions,
    required this.prerequisites,
    required this.chainId,
    required this.skillTags,
    required this.title,
    required this.narrative,
    required this.illustration,
    required this.choices,
    required this.source,
  });

  factory LifeSimEvent.fromJson(Map<String, dynamic> j, String locale) =>
      LifeSimEvent(
        id: j['id'] as String,
        category: j['category'] as String,
        rarity: (j['rarity'] as String?) ?? 'common',
        weight: (j['weight'] as int?) ?? 1,
        cooldownDays: (j['cooldown_days'] as int?) ?? 0,
        minDay: (j['min_day'] as int?) ?? 1,
        maxDay: (j['max_day'] as int?) ?? 30,
        roleTags: ((j['role_tags'] as List?) ?? const []).cast<String>(),
        difficulty: (j['difficulty'] as int?) ?? 1,
        conditions: [
          for (final c in ((j['conditions'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            LifeCondition.fromJson(c),
        ],
        exclusions: [
          for (final c in ((j['exclusions'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            LifeCondition.fromJson(c),
        ],
        prerequisites:
            ((j['prerequisites'] as List?) ?? const []).cast<String>(),
        chainId: j['chain_id'] as String?,
        skillTags: ((j['skill_tags'] as List?) ?? const []).cast<String>(),
        title: _t(j['title'], locale),
        narrative: j['narrative'] == null ? '' : _t(j['narrative'], locale),
        illustration: (j['illustration'] as String?) ?? '',
        choices: [
          for (final c in ((j['choices'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            LifeChoice.fromJson(c, locale),
        ],
        source: SourceMeta.fromJson(j['source'] as Map<String, dynamic>?),
      );

  final String id;
  final String category;
  final String rarity;
  final int weight;
  final int cooldownDays;
  final int minDay;
  final int maxDay;
  final List<String> roleTags;

  /// 1 = neutru/pozitiv, 2 = negativ moderat, ≥3 = negativ intens (modul
  /// ghidat le înmoaie; anti-hammer nu le lasă să lovească de 2 ori la rând).
  final int difficulty;
  final List<LifeCondition> conditions;
  final List<LifeCondition> exclusions;
  final List<String> prerequisites;
  final String? chainId;
  final List<String> skillTags;
  final String title;
  final String narrative;
  final String illustration;
  final List<LifeChoice> choices;
  final SourceMeta source;

  /// Repetabil = doar categoria „daily_living" (cu cooldown); restul one-shot.
  bool get repeatable => category == 'daily_living';
}

class LifeSimGoal {
  const LifeSimGoal({
    required this.id,
    required this.name,
    required this.target,
    required this.why,
  });

  factory LifeSimGoal.fromJson(Map<String, dynamic> j, String locale) =>
      LifeSimGoal(
        id: j['id'] as String,
        name: _t(j['name'], locale),
        target: Money(j['target_bani'] as int),
        why: j['why'] == null ? '' : _t(j['why'], locale),
      );

  final String id;
  final String name;
  final Money target;
  final String why;
}

/// Un final: praguri minime pe cele 4 dimensiuni (+ opțional total). Primul
/// din listă ale cărui praguri sunt toate atinse câștigă, ordinea din
/// endings.json contează.
class LifeSimEnding {
  const LifeSimEnding({
    required this.id,
    required this.title,
    required this.description,
    required this.minControl,
    required this.minRezilienta,
    required this.minObiective,
    required this.minEchilibru,
    required this.minTotal,
  });

  factory LifeSimEnding.fromJson(Map<String, dynamic> j, String locale) {
    final t = (j['thresholds'] as Map<String, dynamic>?) ?? const {};
    return LifeSimEnding(
      id: j['id'] as String,
      title: _t(j['title'], locale),
      description: j['description'] == null ? '' : _t(j['description'], locale),
      minControl: (t['control'] as int?) ?? 0,
      minRezilienta: (t['rezilienta'] as int?) ?? 0,
      minObiective: (t['obiective'] as int?) ?? 0,
      minEchilibru: (t['echilibru'] as int?) ?? 0,
      minTotal: (t['total'] as int?) ?? 0,
    );
  }

  final String id;
  final String title;
  final String description;
  final int minControl;
  final int minRezilienta;
  final int minObiective;
  final int minEchilibru;
  final int minTotal;
}

// ---------------------------------------------------------------------------
// Agregat
// ---------------------------------------------------------------------------

class LifeSimContent {
  LifeSimContent({
    required this.version,
    required this.roles,
    required this.cities,
    required this.recurring,
    required this.events,
    required this.goals,
    required this.endings,
  })  : _rolesById = {for (final r in roles) r.id: r},
        _recurringById = {for (final r in recurring) r.id: r},
        _eventsById = {for (final e in events) e.id: e},
        _goalsById = {for (final g in goals) g.id: g},
        _citiesById = {for (final c in cities) c.id: c};

  final String version;
  final List<LifeSimRole> roles;
  final List<LifeSimCity> cities;
  final List<RecurringDef> recurring;
  final List<LifeSimEvent> events;
  final List<LifeSimGoal> goals;
  final List<LifeSimEnding> endings;

  final Map<String, LifeSimRole> _rolesById;
  final Map<String, RecurringDef> _recurringById;
  final Map<String, LifeSimEvent> _eventsById;
  final Map<String, LifeSimGoal> _goalsById;
  final Map<String, LifeSimCity> _citiesById;

  LifeSimRole? roleById(String id) => _rolesById[id];
  RecurringDef? recurringById(String id) => _recurringById[id];
  LifeSimEvent? eventById(String id) => _eventsById[id];
  LifeSimGoal? goalById(String id) => _goalsById[id];
  LifeSimCity? cityById(String id) => _citiesById[id];

  /// Construiește pachetul din `{cale asset: string JSON}`. Recunoaște fișierele
  /// după cale (manifest/roles/cities/recurring/goals/endings; orice sub
  /// `events/` intră în deck-ul de evenimente).
  factory LifeSimContent.fromJsonBundle(
    Map<String, String> rawJsonByPath, {
    String locale = 'ro',
  }) {
    String version = '0.0.0';
    final roles = <LifeSimRole>[];
    final cities = <LifeSimCity>[];
    final recurring = <RecurringDef>[];
    final events = <LifeSimEvent>[];
    final goals = <LifeSimGoal>[];
    final endings = <LifeSimEnding>[];

    rawJsonByPath.forEach((path, raw) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final p = path.replaceAll('\\', '/');
      if (p.contains('manifest')) {
        version = (json['contentVersion'] ?? json['version'] ?? version)
            as String;
      } else if (p.contains('roles')) {
        version = (json['version'] as String?) ?? version;
        for (final r in (json['roles'] as List).cast<Map<String, dynamic>>()) {
          roles.add(LifeSimRole.fromJson(r, locale));
        }
      } else if (p.contains('cities')) {
        for (final c
            in (json['cities'] as List).cast<Map<String, dynamic>>()) {
          cities.add(LifeSimCity.fromJson(c, locale));
        }
      } else if (p.contains('recurring')) {
        for (final r
            in (json['recurring'] as List).cast<Map<String, dynamic>>()) {
          recurring.add(RecurringDef.fromJson(r, locale));
        }
      } else if (p.contains('goals')) {
        for (final g in (json['goals'] as List).cast<Map<String, dynamic>>()) {
          goals.add(LifeSimGoal.fromJson(g, locale));
        }
      } else if (p.contains('endings')) {
        for (final e
            in (json['endings'] as List).cast<Map<String, dynamic>>()) {
          endings.add(LifeSimEnding.fromJson(e, locale));
        }
      } else if (p.contains('events')) {
        for (final e
            in (json['events'] as List).cast<Map<String, dynamic>>()) {
          events.add(LifeSimEvent.fromJson(e, locale));
        }
      }
    });

    return LifeSimContent(
      version: version,
      roles: roles,
      cities: cities,
      recurring: recurring,
      events: events,
      goals: goals,
      endings: endings,
    );
  }
}
