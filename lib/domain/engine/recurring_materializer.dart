/// Avansează o dată scadentă `yyyy-MM-dd` cu o perioadă (pur). Lunar se
/// clamp-uiește la ultima zi a lunii țintă (31 ian → 28/29 feb).
library;

import '../util/day_key.dart';

String advanceDueDate(String dueKey, String frequency) {
  final d = DateTime.parse(dueKey);
  final next = switch (frequency) {
    'daily' => d.add(const Duration(days: 1)),
    'weekly' => d.add(const Duration(days: 7)),
    _ => _addMonthClamped(d),
  };
  return dayKey(next);
}

DateTime _addMonthClamped(DateTime d) {
  final targetMonth = d.month == 12 ? 1 : d.month + 1;
  final targetYear = d.month == 12 ? d.year + 1 : d.year;
  final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
  return DateTime(targetYear, targetMonth, d.day < lastDay ? d.day : lastDay);
}

/// O instanță scadentă de materializat: suma de postat la data dată.
class DueInstance {
  const DueInstance(this.dateKey);
  final String dateKey;
}

/// Toate aparițiile scadente la sau înainte de [today], plus noua dată de
/// scadență. Recuperează mai multe ocurențe ratate (ex. utilizatorul n-a
/// deschis aplicația 2 luni); mărginit ca să evite bucle nesfârșite pe date proaste.
({List<DueInstance> due, String nextDue}) collectDue({
  required String nextDueDate,
  required String frequency,
  required String today,
  int maxCatchUp = 366,
}) {
  final due = <DueInstance>[];
  var cursor = nextDueDate;
  var guard = 0;
  while (cursor.compareTo(today) <= 0 && guard < maxCatchUp) {
    due.add(DueInstance(cursor));
    cursor = advanceDueDate(cursor, frequency);
    guard++;
  }
  return (due: due, nextDue: cursor);
}
