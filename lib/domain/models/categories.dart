/// Categoriile canonice de tranzacție, sursă unică de adevăr pentru drift
/// local și (eventual) CHECK-urile de pe server. Cheile sunt locale-
/// independente, stocate ca atare; etichetele se rezolvă separat în UI.
abstract final class Categories {
  const Categories._();

  /// Categorii de cheltuieli (`type == 'expense'`).
  static const List<String> expense = <String>[
    'mancare',
    'transport',
    'distractie',
    'educatie',
    'haine',
    'sanatate',
    'chirie',
    'altele',
  ];

  /// Categorii de economisire (`type == 'saving'`).
  static const List<String> saving = <String>[
    'fond_urgenta',
    'obiectiv',
    'investitii',
    'pensie',
    'depozit',
    'altele_economii',
  ];

  /// Toate cele 14 chei canonice de categorie (expense + saving).
  static const List<String> all = <String>[...expense, ...saving];

  /// Dacă [category] e o cheie validă pentru [type]-ul dat.
  static bool isValidFor(String type, String category) => switch (type) {
        'expense' => expense.contains(category),
        'saving' => saving.contains(category),
        _ => false,
      };
}
