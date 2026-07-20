import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Încarcă un asset text din bundle, cu decodare utf8 inline.
///
/// `rootBundle.loadString` trece pe un isolate (`compute`) pentru asset-uri
/// peste ~50KB: cale care nu se termină niciodată sub FakeAsync în widget
/// teste, deci un ecran cu JSON mare ar rămâne blocat în AsyncLoading.
/// Fișierele noastre sunt mici, deci decodarea inline e sigură.
Future<String> loadAssetString(String key) async {
  final data = await rootBundle.load(key);
  return utf8.decode(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}
