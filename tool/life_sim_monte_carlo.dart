/// Monte Carlo pentru „30 de Zile". Rulează N run-uri headless pe pachetul
/// REAL de conținut, cu politici sintetice de decizie, și scoate raportul de
/// echilibrare. Determinist: seed = indexul run-ului.
///
///   dart run tool/life_sim_monte_carlo.dart [N]
library;

import 'dart:io';

import 'package:finedu_flutter/domain/engine/life_sim/life_sim_content.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_effects.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_engine.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_rng.dart';
import 'package:finedu_flutter/domain/engine/life_sim/life_sim_scoring.dart';
import 'package:finedu_flutter/domain/engine/life_sim/money.dart';

const _policies = ['random', 'avar', 'echilibrat', 'generos'];
const _modes = ['ghidat', 'realist'];

void main(List<String> args) {
  final n = args.isEmpty ? 10000 : int.parse(args.first);

  final bundle = <String, String>{};
  for (final f in Directory('content/life_sim').listSync().whereType<File>()) {
    bundle[f.path.replaceAll('\\', '/')] = f.readAsStringSync();
  }
  for (final f in Directory(
    'content/life_sim/events',
  ).listSync().whereType<File>()) {
    bundle[f.path.replaceAll('\\', '/')] = f.readAsStringSync();
  }
  final c = LifeSimContent.fromJsonBundle(bundle);
  final roles = c.roles.map((r) => r.id).toList()..sort();

  var failures = 0;
  var cashNegativeEver = 0;
  var recovered = 0;
  final eventCounts = <String, int>{};
  final eventCountsByRole = <String, Map<String, int>>{};
  final finalCashByRole = <String, List<int>>{};
  final finalDebt = <int>[];
  final finalFund = <int>[];
  final scoreByPolicy = <String, List<LifeSimScore>>{};
  final scoreByRole = <String, List<int>>{};
  final runsDominated = <String, int>{};

  for (var i = 0; i < n; i++) {
    final role = roles[i % roles.length];
    final mode = _modes[(i ~/ roles.length) % _modes.length];
    final policy =
        _policies[(i ~/ (roles.length * _modes.length)) % _policies.length];
    try {
      final roleDef = c.roleById(role)!;
      var s = createRun(
        c: c,
        roleId: role,
        goalId: roleDef.goalDefault,
        mode: mode,
        seed: i,
      );
      final policyRng = LifeSimRng(i).fork(999);
      final seenThisRun = <String>{};
      var wasNegative = false;

      while (s.day < 30) {
        final r = advanceDay(s, c);
        s = r.state;

        // Alocarea pe plicuri, în ziua salariului (politici diferite).
        if (r.salaryReceived != null && policy != 'random') {
          final cashBani = s.cash.toJson();
          if (cashBani > 0 && policy != 'avar') {
            final toFund = Money((cashBani * 0.2).floor());
            final toGoal = Money((cashBani * 0.1).floor());
            s = allocateSalary(s, toFund: toFund, toGoal: toGoal);
          }
        }

        final e = r.event;
        if (e != null) {
          final idx = _pick(policy, e.choices, policyRng);
          s = applyChoice(s, e, idx, c);
          seenThisRun.add(e.id);
          eventCounts[e.id] = (eventCounts[e.id] ?? 0) + 1;
          (eventCountsByRole[role] ??= {})[e.id] =
              ((eventCountsByRole[role]!)[e.id] ?? 0) + 1;
        }
        if (s.cash.isNegative) wasNegative = true;
      }

      final sc = score(s, c);
      if (wasNegative) {
        cashNegativeEver++;
        if (sc.total > 50) recovered++;
      }
      (finalCashByRole[role] ??= []).add(s.cash.toJson() ~/ 100);
      finalDebt.add(
        s.debts.fold<int>(0, (a, d) => a + d.principal.toJson()) ~/ 100,
      );
      finalFund.add(s.emergencyFund.toJson() ~/ 100);
      (scoreByPolicy[policy] ??= []).add(sc);
      (scoreByRole[role] ??= []).add(sc.total);
      for (final id in seenThisRun) {
        runsDominated[id] = (runsDominated[id] ?? 0) + 1;
      }
    } catch (err) {
      failures++;
      if (failures <= 5) {
        stderr.writeln('RUN $i ($role/$mode/$policy) a crăpat: $err');
      }
    }
  }

  int pct(List<int> xs, double p) {
    if (xs.isEmpty) return 0;
    final sorted = [...xs]..sort();
    return sorted[((sorted.length - 1) * p).round()];
  }

  final buf = StringBuffer()
    ..writeln('# Raport de echilibrare „30 de Zile" (Monte Carlo)')
    ..writeln()
    ..writeln(
      '> Generat determinist de tool/life_sim_monte_carlo.dart, '
      'N=$n run-uri, ${roles.length} roluri × ${_modes.length} moduri × '
      '${_policies.length} politici, contentVersion ${c.version}.',
    )
    ..writeln()
    ..writeln('## Sinteză')
    ..writeln()
    ..writeln(
      '- Run-uri terminate fără excepții: ${n - failures}/$n '
      '(${(100 * (n - failures) / n).toStringAsFixed(2)}%)',
    )
    ..writeln(
      '- Run-uri cu cash negativ la un moment dat: $cashNegativeEver '
      '(${(100 * cashNegativeEver / n).toStringAsFixed(1)}%)',
    )
    ..writeln(
      '- Dintre ele, recuperate (scor final >50): $recovered '
      '(${cashNegativeEver == 0 ? 0 : (100 * recovered / cashNegativeEver).toStringAsFixed(1)}%)',
    )
    ..writeln()
    ..writeln('## Scor pe politici (media / p10 / p90 total)')
    ..writeln();
  for (final p in _policies) {
    final scores = scoreByPolicy[p] ?? [];
    if (scores.isEmpty) continue;
    final totals = scores.map((s) => s.total).toList();
    final mean = totals.reduce((a, b) => a + b) / totals.length;
    buf.writeln(
      '- **$p**: medie ${mean.toStringAsFixed(1)} · '
      'p10 ${pct(totals, 0.1)} · p90 ${pct(totals, 0.9)} '
      '(control ${_dimMean(scores, (s) => s.control)} / '
      'rezil ${_dimMean(scores, (s) => s.rezilienta)} / '
      'obiect ${_dimMean(scores, (s) => s.obiective)} / '
      'echilib ${_dimMean(scores, (s) => s.echilibru)})',
    );
  }
  buf
    ..writeln()
    ..writeln(
      '## Dificultate pe roluri (media scorului total + cash final p50)',
    )
    ..writeln();
  final globalMean =
      scoreByRole.values.expand((x) => x).fold<int>(0, (a, b) => a + b) /
      scoreByRole.values.expand((x) => x).length;
  for (final r in roles) {
    final totals = scoreByRole[r] ?? [];
    if (totals.isEmpty) continue;
    final mean = totals.reduce((a, b) => a + b) / totals.length;
    final flag = (mean - globalMean).abs() > 15 ? ' ⚠️ OUTLIER' : '';
    buf.writeln(
      '- **$r**: scor mediu ${mean.toStringAsFixed(1)} · cash final '
      'p10/p50/p90: ${pct(finalCashByRole[r]!, 0.1)}/'
      '${pct(finalCashByRole[r]!, 0.5)}/${pct(finalCashByRole[r]!, 0.9)} lei$flag',
    );
  }
  buf
    ..writeln()
    ..writeln('- Media globală: ${globalMean.toStringAsFixed(1)}')
    ..writeln(
      '- Datorie finală p50: ${pct(finalDebt, 0.5)} lei · '
      'Fond final p50: ${pct(finalFund, 0.5)} lei',
    )
    ..writeln()
    ..writeln('## Top 20 evenimente (frecvență globală)')
    ..writeln();
  final top = eventCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in top.take(20)) {
    final domPct = 100 * (runsDominated[e.key] ?? 0) / n;
    buf.writeln(
      '- ${e.key}: ${e.value} apariții · în '
      '${domPct.toStringAsFixed(1)}% din run-uri',
    );
  }
  final dominant = top.where((e) => (runsDominated[e.key] ?? 0) / n > 0.8);
  buf
    ..writeln()
    ..writeln('## Semnale')
    ..writeln()
    ..writeln(
      dominant.isEmpty
          ? '- Niciun eveniment nu domină >80% din run-uri. ✔'
          : '- ⚠️ Evenimente cvasi-omniprezente: '
                '${dominant.map((e) => e.key).join(', ')}',
    )
    ..writeln(
      failures == 0
          ? '- Zero run-uri imposibile (excepții). ✔'
          : '- ⚠️ $failures run-uri au crăpat, de investigat.',
    );

  stdout.writeln(buf);
  File(
    'docs/research/life-month-balance-report.md',
  ).writeAsStringSync(buf.toString());
  stdout.writeln('scris: docs/research/life-month-balance-report.md');
}

String _dimMean(List<LifeSimScore> xs, int Function(LifeSimScore) f) =>
    (xs.map(f).reduce((a, b) => a + b) / xs.length).toStringAsFixed(0);

/// Politicile sintetice: cum alege un „jucător" simulat dintre opțiuni.
int _pick(String policy, List<LifeChoice> choices, LifeSimRng rng) {
  int cashOf(LifeChoice ch) => ch.effects.whereType<CashDelta>().fold<int>(
    0,
    (a, e) => a + e.delta.toJson(),
  );
  int statsOf(LifeChoice ch, {Set<String>? only}) =>
      ch.effects
          .whereType<StatDelta>()
          .where(
            (e) =>
                e.stat != 'stress' && (only == null || only.contains(e.stat)),
          )
          .fold<int>(0, (a, e) => a + e.delta) -
      ch.effects
          .whereType<StatDelta>()
          .where((e) => e.stat == 'stress')
          .fold<int>(0, (a, e) => a + e.delta);

  switch (policy) {
    case 'avar':
      var best = 0;
      for (var i = 1; i < choices.length; i++) {
        if (cashOf(choices[i]) > cashOf(choices[best])) best = i;
      }
      return best;
    case 'echilibrat':
      var best = 0;
      double sc(LifeChoice ch) => statsOf(ch) + cashOf(ch) / 10000;
      for (var i = 1; i < choices.length; i++) {
        if (sc(choices[i]) > sc(choices[best])) best = i;
      }
      return best;
    case 'generos':
      var best = 0;
      const social = {'relationships', 'health'};
      for (var i = 1; i < choices.length; i++) {
        if (statsOf(choices[i], only: social) >
            statsOf(choices[best], only: social)) {
          best = i;
        }
      }
      return best;
    default:
      return rng.nextInt(choices.length);
  }
}
