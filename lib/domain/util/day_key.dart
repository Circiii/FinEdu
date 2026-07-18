/// Formatează un [DateTime] ca day key `yyyy-MM-dd` (dată LOCALĂ).
///
/// Formatul canonic în toată aplicația (daily_activity, no-spend, streak).
/// Local, niciodată UTC, ca o lecție la 23:30 în București să conteze
/// pentru ziua corectă.
String dayKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
