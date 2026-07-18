/// Quest-uri zilnice: exact 3 pe zi. Slot 1 e mereu tracking, slot 2 e mereu
/// o acțiune din bucla de învățare (Dojo), slot 3 rotește între două
/// provocări oneste, verificabile din date.
///
/// Domeniu pur: finalizarea e DERIVATĂ din datele zilei, doar revendicarea
/// se persistă. Fără contoare farmabile (AADC/anti-gaming: recompensează
/// obiceiul, nu volumul).
library;

enum QuestId { logToday, dojoRound, noFunSpend, keepFlame }

class QuestDef {
  const QuestDef(this.id, this.slot, this.reward);
  final QuestId id;
  final int slot; // 1..3
  final int reward; // acorns on claim
}

/// Cele 3 quest-uri pentru [today] (`yyyy-MM-dd`). Slot 3 alternează după paritatea datei.
List<QuestDef> questsFor(String today) {
  final parity = DateTime.parse(today).day.isEven;
  return [
    const QuestDef(QuestId.logToday, 1, 3),
    const QuestDef(QuestId.dojoRound, 2, 3),
    QuestDef(parity ? QuestId.noFunSpend : QuestId.keepFlame, 3, 4),
  ];
}

/// Dacă un quest e finalizat, derivat din datele zilei.
///
/// [todayKinds], tipurile de activitate de azi ('log' | 'game' | ...);
/// [todayExpenseCategories], categoriile cheltuielilor de azi;
/// [streakCurrent], streak-ul curent (după evaluarea de azi).
bool questDone(
  QuestId id, {
  required Set<String> todayKinds,
  required Set<String> todayExpenseCategories,
  required int streakCurrent,
}) {
  return switch (id) {
    QuestId.logToday => todayKinds.contains('log'),
    QuestId.dojoRound => todayKinds.contains('game'),
    // O zi (până acum) fără cheltuieli de distracție, are sens ca revendicare
    // doar dacă ziua are altă activitate; onest, verificat pe date reale.
    QuestId.noFunSpend =>
      todayKinds.contains('log') &&
          !todayExpenseCategories.contains('distractie'),
    QuestId.keepFlame => streakCurrent >= 1 && todayKinds.isNotEmpty,
  };
}

/// Cufăr zilnic: câștigat când toate cele 3 quest-uri sunt revendicate;
/// se deschide la sesiunea URMĂTOARE (motiv să revii azi).
///
/// Valoarea e determinist per (date, streak): prag transparent care crește
/// cu streak-ul, spread mărginit, fără aleatoriu de tip loot-box la deschidere.
int chestValue(String date, int streak) {
  final floor = 5 + (streak < 20 ? streak : 20);
  final spread = date.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0xffff);
  return floor + spread % 16; // floor .. floor+15
}
