/// Configurare de aplicație la compile-time. Credențialele Supabase vin din
/// `--dart-define` (SUPABASE_URL, SUPABASE_ANON_KEY); fără ele, aplicația
/// rulează 100% offline pe drift local: cazul curent, proiectul Supabase
/// real nu există încă.
abstract final class AppConfig {
  const AppConfig._();

  /// URL proiect Supabase; string gol dacă nu e setat la build.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Cheia API publică Supabase; string gol dacă nu e setată.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Adevărat doar dacă ambele valori sunt setate. Orice cod de rețea
  /// (Supabase, sync) trebuie să verifice acest flag și să degradeze la offline.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
