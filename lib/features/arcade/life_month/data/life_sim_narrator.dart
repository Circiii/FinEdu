import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Poarta (opțională) spre un LLM care ar putea „lustrui" linia lui Cashy.
/// Determinist și offline by design: [polish] întoarce null și UI-ul rămâne
/// pe varianta compusă, fallback permanent, nu temporar.
abstract class CashyNarrator {
  /// [aggregates] trebuie să fie doar valori derivate (mood, delta-uri, zile),
  /// niciodată id-uri brute de eveniment/decizie.
  Future<String?> polish(String composedLine, Map<String, dynamic> aggregates);
}

/// Implementarea offline: mereu null.
class OfflineNarrator implements CashyNarrator {
  const OfflineNarrator();

  @override
  Future<String?> polish(
    String composedLine,
    Map<String, dynamic> aggregates,
  ) async => null;
}

/// Aici ar intra un edge function remote, dacă apare vreodată un backend;
/// primește doar agregate derivate, nu calculează nimic.
final cashyNarratorProvider = Provider<CashyNarrator>(
  (ref) => const OfflineNarrator(),
);
