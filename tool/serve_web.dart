/// Servește build-ul de web pe http://localhost:8080.
///
/// De ce nu merge deschis direct fișierul `build/web/index.html`: browserele
/// blochează cererile din pagini `file://`, iar aplicația are nevoie să încarce
/// motorul grafic, fonturile și baza de date SQLite. Deci trebuie un server.
///
/// Serverul trimite și cele două antete de izolare (`Cross-Origin-Opener-Policy`
/// și `Cross-Origin-Embedder-Policy`). Fără ele browserul nu-i dă bazei de date
/// acces la stocarea rapidă și persistentă (OPFS), iar progresul s-ar pierde la
/// reîncărcarea paginii.
///
/// Rulare:
///   flutter build web --release --no-web-resources-cdn
///   dart run tool/serve_web.dart
library;

import 'dart:io';

const _port = 8080;
const _root = 'build/web';

const _mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.ico': 'image/x-icon',
  '.bin': 'application/octet-stream',
  '.symbols': 'text/plain; charset=utf-8',
};

Future<void> main() async {
  final root = Directory(_root);
  if (!root.existsSync()) {
    stdout.writeln('Nu există $_root. Rulează întâi:');
    stdout.writeln('  flutter build web --release --no-web-resources-cdn');
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
  stdout.writeln('FinEdu rulează pe http://localhost:$_port');
  stdout.writeln('Oprire: Ctrl+C');

  await for (final req in server) {
    final res = req.response;
    res.headers
      ..set('Cross-Origin-Opener-Policy', 'same-origin')
      ..set('Cross-Origin-Embedder-Policy', 'require-corp');

    var path = Uri.decodeComponent(req.uri.path);
    if (path.endsWith('/')) path += 'index.html';

    // Nu lăsăm cererea să iasă din folderul build/web.
    final file = File('$_root$path');
    final safe = file.absolute.path.startsWith(root.absolute.path);

    if (!safe || !file.existsSync()) {
      // Rutele aplicației (de exemplu /arcade) nu au fișier pe disc, le
      // servim index.html și lasă go_router să decidă ce afișează.
      final fallback = File('$_root/index.html');
      res.headers.contentType = ContentType.html;
      await res.addStream(fallback.openRead());
      await res.close();
      continue;
    }

    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot);
    res.headers.set('Content-Type', _mime[ext] ?? 'application/octet-stream');
    await res.addStream(file.openRead());
    await res.close();
  }
}
