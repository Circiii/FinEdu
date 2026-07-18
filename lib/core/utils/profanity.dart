/// Filtru minimal de cuvinte licențioase pentru numele alese de utilizator
/// (numele lui Cashy): listă scurtă RO/EN, verificare pe substring, fără diacritice.
library;

/// Intrări lowercase, fără diacritice, ca să se compare direct cu inputul foldat.
const List<String> _denylist = <String>[
  // --- RO ---
  // 'cur'/'bou' lipsesc intenționat: ca substring ar bloca nume nevinovate
  // ("Curcubeu"); 'curva' de mai jos acoperă cazurile reale.
  'pula', 'pizda', 'muie', 'cacat', 'fut', 'futu', 'coaie', 'sugi',
  'proasta', 'prost', 'jegos', 'curva', 'tarfa', 'pizd', 'muist',
  'labagiu', 'pisat', 'dracu', 'nesimtit', 'idiot', 'handicapat',
  // --- EN ---
  'fuck', 'shit', 'bitch', 'cunt', 'dick', 'cock', 'pussy', 'asshole',
  'bastard', 'slut', 'whore', 'nigger', 'faggot', 'retard', 'nazi', 'rape',
  'sex', 'porn',
];

/// Normalizează [input]: lowercase + diacritice românești eliminate +
/// non-litere scoase (ca `p.u.l.a` / `p u l a` să tot fie prinse).
String _fold(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final folded = _diacritics[ch];
    final out = folded ?? ch;
    // Păstrează doar a-z după folding; elimină spații, puncte, cifre, simboluri.
    if (out.codeUnitAt(0) >= 0x61 && out.codeUnitAt(0) <= 0x7A) {
      buffer.write(out);
    }
  }
  return buffer.toString();
}

const Map<String, String> _diacritics = {
  'ă': 'a', 'â': 'a', 'î': 'i', 'ș': 's', 'ş': 's', 'ț': 't', 'ţ': 't',
};

/// Dacă [name] conține un fragment din denylist (după folding). Substring
/// matching supra-blochează intenționat: pentru un nickname de 12 caractere,
/// mai bine un fals "încearcă alt nume" decât o insultă pe mascotă. Numele
/// goale sunt considerate curate (emptiness se tratează la apelant).
bool isProfane(String name) {
  final folded = _fold(name);
  if (folded.isEmpty) return false;
  for (final bad in _denylist) {
    if (folded.contains(bad)) return true;
  }
  return false;
}
