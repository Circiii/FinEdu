// Planificatorul de notificări „de absență", Dart pur, zero Flutter.
//
// Motor mic și determinist: din tiparul real de folosire scoate ora sigură și
// cele trei momente de escaladare (D1/D3/D7). Nu atinge pluginul și nu știe de
// fusuri orare, doar calculează. Programarea efectivă e treaba serviciului.

/// Un slot planificat: id stabil de notificare + momentul + felul mesajului.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.kind,
  });
  final int id; // 2001 (d1) / 2003 (d3) / 2007 (d7)
  final DateTime when;
  final String kind; // 'd1' | 'd3' | 'd7'
}

/// Fereastra sigură AADC: școala (8-15) și noaptea (21-8) sunt interzise, așa
/// că orice notificare se strânge între 16:00 și 20:00.
const int _safeHourMin = 16;
const int _safeHourMax = 20;

/// Ora implicită, folosită când n-avem încă destule date reale.
const int _defaultHour = 19;

int _clampToSafeWindow(int hour) => hour < _safeHourMin
    ? _safeHourMin
    : (hour > _safeHourMax ? _safeHourMax : hour);

/// Ora la care utilizatorul chiar folosește aplicația, adusă în fereastra
/// sigură AADC (16-20; școala 8-15 și noaptea 21-8 sunt interzise).
///
/// Ia mediana orei din marcajele de activitate. Sub 5 mostre nu avem un semnal
/// de încredere, deci cădem pe ora implicită de 19.
int preferredHour(Iterable<DateTime> activity) {
  final hours = activity.map((d) => d.hour).toList();
  if (hours.length < 5) return _defaultHour;
  hours.sort();
  final mid = hours.length ~/ 2;
  final median = hours.length.isOdd
      ? hours[mid]
      : ((hours[mid - 1] + hours[mid]) / 2).round();
  return _clampToSafeWindow(median);
}

/// Cele trei sloturi de escaladare la now+1 / now+3 / now+7 zile, toate la
/// `hour`:00 local. Deoarece fiecare deschidere a aplicației le reprogramează,
/// D1/D3/D7 se declanșează doar dacă utilizatorul chiar lipsește atât.
///
/// `hour` e adus defensiv în fereastra sigură [16, 20]. Dacă un slot calculat
/// nu iese după `now` (o margine de DST), îl împingem încă o zi.
List<PlannedNotification> planEscalation({
  required DateTime now,
  required int hour,
}) {
  final h = _clampToSafeWindow(hour);
  const spec = [
    (offset: 1, id: 2001, kind: 'd1'),
    (offset: 3, id: 2003, kind: 'd3'),
    (offset: 7, id: 2007, kind: 'd7'),
  ];
  return [
    for (final s in spec)
      _slotFor(now: now, offsetDays: s.offset, hour: h, id: s.id, kind: s.kind),
  ];
}

PlannedNotification _slotFor({
  required DateTime now,
  required int offsetDays,
  required int hour,
  required int id,
  required String kind,
}) {
  // Construim data deplasată prin constructorul DateTime (rezolvă singur
  // depășirea de lună) și abia apoi fixăm ora.
  final shifted = DateTime(now.year, now.month, now.day + offsetDays);
  var when = DateTime(shifted.year, shifted.month, shifted.day, hour);
  if (!when.isAfter(now)) {
    when = DateTime(shifted.year, shifted.month, shifted.day + 1, hour);
  }
  return PlannedNotification(id: id, when: when, kind: kind);
}

/// Alegere deterministă a variantei de mesaj din pool: aceeași zi → aceeași
/// variantă (rotația e stabilă peste re-rulările provider-ului).
int variantIndex({required String dayKey, required int count}) {
  return dayKey.hashCode.abs() % count;
}
