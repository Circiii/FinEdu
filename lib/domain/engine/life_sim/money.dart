/// Bani ca `int` pentru „30 de Zile" (1 leu = 100 bani), niciodată `double`
/// în aritmetică: erorile de rotunjire ar rupe determinismul same-seed.
///
/// Singura punte spre `double` e [Money.fromLeiDouble], care rotunjește o
/// singură dată, apoi rămânem în lumea întregilor.
library;

class Money implements Comparable<Money> {
  const Money(this.bani);

  /// Din lei întregi (fără subdiviziune), 3 lei = 300 bani.
  factory Money.fromLei(int lei) => Money(lei * 100);

  /// Din JSON: valoarea persistată E numărul de bani (int), fără ambiguitate.
  factory Money.fromJson(int bani) => Money(bani);

  /// Zero, expus ca const pentru inițializări.
  static const zero = Money(0);

  /// Singura conversie din `double`: multiplică lei×100 și rotunjește o dată
  /// (ex. chirie 900 lei × 1,15 profil oraș = 1035 lei → 103500 bani). După
  /// acest punct nu mai atingem double.
  static Money fromLeiDouble(double lei) => Money((lei * 100).round());

  /// Cantitatea în bani (int). Sursa unică de adevăr.
  final int bani;

  Money operator +(Money other) => Money(bani + other.bani);
  Money operator -(Money other) => Money(bani - other.bani);

  /// Negare unară (`-fond`), utilă pentru a inversa un delta.
  Money operator -() => Money(-bani);

  /// Scalare cu un întreg (ex. 3 rate egale), factorul e int, nu double,
  /// ca să nu reintroducem erori de virgulă.
  Money operator *(int factor) => Money(bani * factor);

  bool operator <(Money other) => bani < other.bani;
  bool operator <=(Money other) => bani <= other.bani;
  bool operator >(Money other) => bani > other.bani;
  bool operator >=(Money other) => bani >= other.bani;

  @override
  int compareTo(Money other) => bani.compareTo(other.bani);

  bool get isNegative => bani < 0;
  bool get isZero => bani == 0;

  /// Taie la ≥0 (fond/obiectiv nu pot coborî sub zero, cash-ul, în schimb,
  /// POATE fi negativ: descoperitul e o stare urmărită, nu una interzisă).
  Money clampAtZero() => bani < 0 ? zero : this;

  int toJson() => bani;

  /// Formatare RO: '1.234 lei' (punct pe mii), banii cazuți când sunt zero,
  /// ',50' când sunt nenuli. Negativul își păstrează semnul: '-850 lei'.
  String get lei {
    final negative = bani < 0;
    final abs = bani.abs();
    final whole = abs ~/ 100;
    final cents = abs % 100;
    final buf = StringBuffer();
    if (negative) buf.write('-');
    buf.write(_thousands(whole));
    if (cents != 0) {
      buf.write(',');
      buf.write(cents.toString().padLeft(2, '0'));
    }
    buf.write(' lei');
    return buf.toString();
  }

  /// Grupează cifrele pe câte 3 de la dreapta cu punct (1234567 → '1.234.567').
  static String _thousands(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  bool operator ==(Object other) => other is Money && other.bani == bani;

  @override
  int get hashCode => bani.hashCode;

  @override
  String toString() => 'Money(${bani}b = $lei)';
}
