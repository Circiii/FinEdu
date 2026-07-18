import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:finedu_flutter/domain/engine/life_sim/life_sim_content.dart';

/// Validatorul pachetului de conținut „30 de Zile".
/// Citește DIRECT de pe disk (nu din bundle), rulează și fără pubspec.
void main() {
  final dir = Directory('content/life_sim');
  final eventsDir = Directory('content/life_sim/events');

  Map<String, String> loadBundle() {
    final bundle = <String, String>{};
    for (final f in dir.listSync().whereType<File>()) {
      bundle[f.path.replaceAll('\\', '/')] = f.readAsStringSync();
    }
    for (final f in eventsDir.listSync().whereType<File>()) {
      bundle[f.path.replaceAll('\\', '/')] = f.readAsStringSync();
    }
    return bundle;
  }

  test('bundle parses in both locales through the real engine parser', () {
    for (final locale in ['ro', 'en']) {
      final content = LifeSimContent.fromJsonBundle(loadBundle(), locale: locale);
      expect(content.roles, hasLength(9), reason: locale);
      expect(content.events.length, greaterThanOrEqualTo(150), reason: locale);
      expect(content.recurring.length, greaterThanOrEqualTo(16));
      expect(content.goals.length, greaterThanOrEqualTo(8));
      expect(content.endings, hasLength(12));
      expect(content.version, isNotEmpty);
    }
  });

  test('ids unique + references resolve (recurring, goals, events, chains)',
      () {
    final c = LifeSimContent.fromJsonBundle(loadBundle());
    final eventIds = <String>{};
    for (final e in c.events) {
      expect(eventIds.add(e.id), isTrue, reason: 'duplicate event ${e.id}');
    }
    final recurringIds = {for (final r in c.recurring) r.id};
    final goalIds = {for (final g in c.goals) g.id};
    final cityIds = {for (final ci in c.cities) ci.id};

    for (final r in c.roles) {
      for (final b in r.bills) {
        expect(recurringIds, contains(b), reason: '${r.id} bill $b');
      }
      expect(goalIds, contains(r.goalDefault), reason: r.id);
      expect(cityIds, contains(r.cityProfile), reason: r.id);
      expect(r.source.needsExpertReview, isTrue,
          reason: '${r.id}: salariile rămân marcate pentru review uman');
      expect(r.source.label, isNotEmpty, reason: r.id);
    }

    // scheduleEvent/prerequisites țintesc evenimente existente.
    final rawAll = StringBuffer();
    for (final e in loadBundle().entries) {
      if (e.key.contains('events/')) rawAll.write(e.value);
    }
    final raw = rawAll.toString();
    final scheduled = RegExp('"event_id"\\s*:\\s*"([^"]+)"')
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toSet();
    for (final id in scheduled) {
      expect(eventIds, contains(id), reason: 'scheduleEvent -> $id inexistent');
    }
    for (final e in c.events) {
      for (final p in e.prerequisites) {
        expect(eventIds, contains(p), reason: '${e.id} prerequisite $p');
      }
    }
  });

  test('volume + shape targets (choices, weights, difficulty, positives)', () {
    final c = LifeSimContent.fromJsonBundle(loadBundle());
    var chains = <String>{};
    for (final e in c.events) {
      expect(e.choices.length, inInclusiveRange(2, 4), reason: e.id);
      expect(e.weight, greaterThan(0), reason: e.id);
      expect(e.difficulty, inInclusiveRange(1, 3), reason: e.id);
      expect(e.minDay, inInclusiveRange(1, 30), reason: e.id);
      expect(e.maxDay, inInclusiveRange(e.minDay, 30), reason: e.id);
      if (e.chainId != null) chains.add(e.chainId!);
      for (final ch in e.choices) {
        expect(ch.label, isNotEmpty, reason: e.id);
        expect(ch.debrief, isNotEmpty,
            reason: '${e.id}: fiecare alegere explică trade-off-ul');
      }
    }
    expect(chains.length, greaterThanOrEqualTo(24),
        reason: 'lanțurile sunt inima consecințelor întârziate');
  });

  test('editorial lint: mojibake, shaming, gambling safety', () {
    final bundle = loadBundle();
    final all = bundle.values.join('\n');

    expect(RegExp('Ã|â€|Äƒ|È™').hasMatch(all), isFalse,
        reason: 'mojibake în conținut');

    final lower = all.toLowerCase();
    for (final banned in [
      'prea mult',
      'iar ai ',
      'ai eșuat',
      'ești sărac',
      'decizie proastă',
      'you failed',
      "you're poor",
    ]) {
      expect(lower.contains(banned), isFalse, reason: 'ton interzis: $banned');
    }

    // Loteria există DOAR în spatele biletului cumpărat explicit.
    if (lower.contains('loteri') || lower.contains('lottery')) {
      expect(all.contains('bilet_cumparat'), isTrue,
          reason: 'loteria cere flag de bilet cumpărat explicit');
    }
  });

  test('monetary values are ints (bani), never floats', () {
    for (final entry in loadBundle().entries) {
      final decoded = jsonDecode(entry.value);
      void walk(dynamic node, String path) {
        if (node is Map) {
          node.forEach((k, v) {
            if ((k == 'amount' || k == 'delta' && path.contains('cash') ||
                    k == 'principal' ||
                    k == 'monthly' ||
                    k == 'target_bani' ||
                    k == 'initial_cash' ||
                    k == 'initial_fund') &&
                v is double) {
              fail('${entry.key} $path.$k e float, banii sunt int bani');
            }
            walk(v, '$path.$k');
          });
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        }
      }

      walk(decoded, entry.key);
    }
  });

  test('lint: fără em dash, en dash sau bară orizontală în niciun string', () {
    // Regula dură de text: intervalele folosesc cratimă simplă, nu liniuțe lungi.
    // Caracterele interzise sunt scrise ca escape ca fișierul de test să rămână curat.
    const forbidden = {
      '\u2014': 'em dash',
      '\u2013': 'en dash',
      '\u2015': 'bară orizontală',
    };
    final problems = <String>[];
    loadBundle().forEach((path, raw) {
      void walk(dynamic node, String id) {
        if (node is String) {
          forbidden.forEach((ch, nume) {
            if (node.contains(ch)) {
              problems.add('$path [$id]: $nume în „$node"');
            }
          });
        } else if (node is Map) {
          final rawId = node['id'];
          final nextId = rawId is String ? rawId : id;
          node.forEach((_, v) => walk(v, nextId));
        } else if (node is List) {
          for (final v in node) {
            walk(v, id);
          }
        }
      }

      walk(jsonDecode(raw), '(rădăcină)');
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('lint: narative <= 200 și titluri <= 48 caractere (ro și en)', () {
    // Praguri cu marjă peste țintele redacționale (150/44), ca să nu fie fragile.
    final bundle = loadBundle();
    final problems = <String>[];
    for (final locale in ['ro', 'en']) {
      final c = LifeSimContent.fromJsonBundle(bundle, locale: locale);
      for (final e in c.events) {
        if (e.narrative.length > 200) {
          problems.add('[$locale] ${e.id}: narativ ${e.narrative.length} > 200');
        }
        if (e.title.length > 48) {
          problems.add('[$locale] ${e.id}: titlu ${e.title.length} > 48');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
