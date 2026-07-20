/// Micșorează imaginile din `assets/` la mărimea de care are nevoie ecranul
/// și le recomprimă. Desenele rămân la fel la privit, dar ocupă de câteva ori
/// mai puțin pe disc și, mai important, în memorie: Flutter decodează o
/// imagine la rezoluția ei reală, nu la cea la care o afișezi.
///
/// Rulare:
///   dart run tool/optimize_icons.dart --dry     doar raportul, nu scrie nimic
///   dart run tool/optimize_icons.dart           scrie peste fișierele din assets
///
/// Originalele de la desenator NU se pierd: prima rulare le copiază în
/// `assets_src/`, care rămâne în afara aplicației.
library;

import 'dart:io';

import 'package:image/image.dart' as img;

/// Latura maximă în pixeli pentru fiecare imagine, aleasă ca de trei ori
/// mărimea la care se vede pe ecran (ecranele de telefon au densitate mare).
const _targets = <String, int>{
  'assets/icons/acorn.png': 192,
  'assets/icons/flame.png': 96,
  'assets/icons/cat_abonamente.png': 128,
  'assets/icons/cat_altele.png': 128,
  'assets/icons/cat_distractie.png': 128,
  'assets/icons/cat_educatie.png': 128,
  'assets/icons/cat_mancare.png': 128,
  'assets/icons/cat_sanatate.png': 128,
  'assets/icons/cat_shopping.png': 128,
  'assets/icons/cat_transport.png': 128,
  'assets/mascot/squirrel_celebration.png': 600,
  'assets/mascot/squirrel_happy.png': 600,
  'assets/mascot/squirrel_learning.png': 600,
  'assets/mascot/squirrel_neutral.png': 600,
  'assets/mascot/squirrel_warning.png': 600,
};

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';

String _ram(int w, int h) =>
    '${(w * h * 4 / 1024 / 1024).toStringAsFixed(2)} MB';

void main(List<String> args) {
  final dryRun = args.contains('--dry');

  var beforeBytes = 0, afterBytes = 0;
  var beforeRam = 0, afterRam = 0;
  var touched = 0;

  stdout.writeln(dryRun ? 'RAPORT (nu se scrie nimic)\n' : 'OPTIMIZARE\n');
  stdout.writeln(
    '${'fisier'.padRight(38)}${'inainte'.padLeft(20)}${'dupa'.padLeft(20)}',
  );

  for (final entry in _targets.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      stdout.writeln('  lipseste: ${entry.key}');
      continue;
    }

    final raw = file.readAsBytesSync();
    final src = img.decodePng(raw);
    if (src == null) {
      stdout.writeln('  nu se poate citi: ${entry.key}');
      continue;
    }

    beforeBytes += raw.length;
    beforeRam += src.width * src.height * 4;

    final maxSide = src.width > src.height ? src.width : src.height;
    final target = entry.value;

    // Deja destul de mică: o lăsăm în pace, nu are rost s-o recomprimăm.
    if (maxSide <= target) {
      afterBytes += raw.length;
      afterRam += src.width * src.height * 4;
      stdout.writeln(
        '${entry.key.split('/').last.padRight(38)}'
        '${'${src.width}x${src.height} ${_kb(raw.length)}'.padLeft(20)}'
        '${'deja mica'.padLeft(20)}',
      );
      continue;
    }

    final scale = target / maxSide;
    final out = img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
    final encoded = img.encodePng(out, level: 9);

    afterBytes += encoded.length;
    afterRam += out.width * out.height * 4;
    touched++;

    stdout.writeln(
      '${entry.key.split('/').last.padRight(38)}'
      '${'${src.width}x${src.height} ${_kb(raw.length)}'.padLeft(20)}'
      '${'${out.width}x${out.height} ${_kb(encoded.length)}'.padLeft(20)}',
    );

    if (dryRun) continue;

    // Originalul se mută o singură dată în assets_src, ca să rămână de unde
    // se poate re-exporta oricând.
    final backup = File(entry.key.replaceFirst('assets/', 'assets_src/'));
    if (!backup.existsSync()) {
      backup.parent.createSync(recursive: true);
      backup.writeAsBytesSync(raw);
    }
    file.writeAsBytesSync(encoded);
  }

  stdout.writeln('\nPE DISC:  ${_kb(beforeBytes)}  ->  ${_kb(afterBytes)}');
  stdout.writeln(
    'IN RAM:   ${_ram(beforeRam ~/ 4, 1)}  ->  ${_ram(afterRam ~/ 4, 1)}',
  );
  if (!dryRun) {
    stdout.writeln(
      '\n$touched imagini rescrise, originalele sunt in assets_src/',
    );
  }
}
