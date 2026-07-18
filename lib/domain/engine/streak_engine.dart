/// Numărătoarea de streak pe day keys locale `yyyy-MM-dd`. Doar numărătoarea
/// de bază, freezes/earn-back vin peste, în streak_rules.dart.
///
/// Regula (semantica Duolingo): streak-ul curent e șirul de zile active
/// consecutive care se termină AZI sau IERI, ieri încă „ține" streak-ul
/// până la prima acțiune de azi. Un gol de 2+ zile îl rupe.
library;

({int current, int longest}) computeStreak(
  Set<String> activityDays,
  String today,
) {
  if (activityDays.isEmpty) return (current: 0, longest: 0);

  final days = activityDays.map(DateTime.parse).toList()..sort();

  // Cel mai lung: scanează șirurile peste zilele unice, sortate.
  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    run = gap == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  // Curent: mergem înapoi zi cu zi de la azi (sau ieri, dacă azi n-are încă activitate).
  final todayDate = DateTime.parse(today);
  var cursor = todayDate;
  if (!activityDays.contains(_key(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!activityDays.contains(_key(cursor))) {
      return (current: 0, longest: longest);
    }
  }
  var current = 0;
  while (activityDays.contains(_key(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return (current: current, longest: longest);
}

String _key(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}
