/// Generează iconițele aplicației din mascota Cashy.
///
/// Proiectul pornise cu iconițele implicite din șablonul Flutter (logo-ul
/// Flutter), care apăreau pe ecranul telefonului, în tabul browserului și în
/// ecranul de așteptare al versiunii web. Scriptul le înlocuiește cu o iconiță
/// proprie: Cashy pe fundalul albastru al aplicației.
///
/// Rulare:
///   dart run tool/make_icons.dart
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Sursa: mascota, pe fundal transparent.
const _source = 'assets/mascot/squirrel_happy.png';

/// Albastrul de accent al aplicației (C.blue din lib/core/ui/tokens.dart),
/// ca (r, g, b), plus varianta deschisă folosită în mijlocul degradeului.
const _bg = [43, 134, 255];
const _bgLight = [122, 178, 255];

/// Iconițele de Android, pe densități.
const _android = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

void main() {
  final src = decodePng(File(_source).readAsBytesSync());
  if (src == null) {
    stdout.writeln('Nu am putut citi $_source');
    exitCode = 1;
    return;
  }

  // Iconițe obișnuite: mascota ocupă mare parte din pătrat.
  for (final size in [192, 512]) {
    _write('web/icons/Icon-$size.png', _compose(src, size, 0.76));
  }

  // Iconițe „maskable": sistemul poate decupa un cerc din ele, așa că mascota
  // stă mai strânsă, în zona sigură din mijloc.
  for (final size in [192, 512]) {
    _write('web/icons/Icon-maskable-$size.png', _compose(src, size, 0.56));
  }

  _write('web/favicon.png', _compose(src, 64, 0.86));

  _android.forEach((density, size) {
    _write(
      'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      _compose(src, size, 0.76),
    );
  });

  stdout.writeln('Gata. Iconițele au fost regenerate din $_source.');
}

/// Desenează mascota peste un fundal cu degrade radial, într-un pătrat de
/// [size] pixeli. [scale] e cât din latură ocupă mascota.
Image _compose(Image src, int size, double scale) {
  final out = Image(width: size, height: size, numChannels: 4);

  // Degradeul radial: mai deschis la mijloc, ca iconița să nu pară plată.
  final center = size / 2;
  final maxDist = center * math.sqrt(2);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center, dy = y - center;
      final t = (math.sqrt(dx * dx + dy * dy) / maxDist).clamp(0.0, 1.0);
      out.setPixelRgba(
        x,
        y,
        _lerp(_bgLight[0], _bg[0], t),
        _lerp(_bgLight[1], _bg[1], t),
        _lerp(_bgLight[2], _bg[2], t),
        255,
      );
    }
  }

  // Mascota, redimensionată păstrând proporțiile și așezată în centru.
  final target = (size * scale).round();
  final ratio = src.width / src.height;
  final w = ratio >= 1 ? target : (target * ratio).round();
  final h = ratio >= 1 ? (target / ratio).round() : target;
  final mascot = copyResize(
    src,
    width: w,
    height: h,
    interpolation: Interpolation.cubic,
  );

  compositeImage(
    out,
    mascot,
    dstX: ((size - w) / 2).round(),
    dstY: ((size - h) / 2).round(),
  );
  return out;
}

int _lerp(num a, num b, double t) => (a + (b - a) * t).round().clamp(0, 255);

void _write(String path, Image img) {
  final file = File(path);
  if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(img, level: 9));
  stdout.writeln('  ${file.path}  ${img.width}x${img.height}');
}
