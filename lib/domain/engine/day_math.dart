/// Funcții pure peste day keys `yyyy-MM-dd` (vezi `domain/util/day_key.dart`).
library;

import '../util/day_key.dart';

/// Comparație lexicografică validă pentru day keys ISO: <0 dacă [a] e înainte de [b].
int compareDayKeys(String a, String b) => a.compareTo(b);

/// Cheia [days] zile după [key] (negativ permis).
String addDaysToKey(String key, int days) {
  return dayKey(DateTime.parse(key).add(Duration(days: days)));
}

/// Toate day keys strict între [from] și [to] (ambele exclusive).
Set<String> dayKeysBetween(String from, String to) {
  final result = <String>{};
  var cursor = DateTime.parse(from).add(const Duration(days: 1));
  final end = DateTime.parse(to);
  while (cursor.isBefore(end)) {
    result.add(dayKey(cursor));
    cursor = cursor.add(const Duration(days: 1));
  }
  return result;
}
