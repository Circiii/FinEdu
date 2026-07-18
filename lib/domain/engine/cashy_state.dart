/// Starea emoțională a lui Cashy, derivată din situația financiară a
/// utilizatorului. Pure Dart, maparea mood → asset trăiește în UI
/// (`core/ui/cashy_mood.dart`).
library;

enum CashyMood { happy, alert, worried }

/// Mood bazat pe buget: >=100% cheltuit → worried, >=80% → alert, altfel
/// happy. Fără buget valid → happy (nimic de îngrijorat încă).
CashyMood moodFor({
  required double spentThisMonth,
  required double? monthlyBudget,
}) {
  if (monthlyBudget == null || monthlyBudget <= 0) return CashyMood.happy;
  final ratio = spentThisMonth / monthlyBudget;
  if (ratio >= 1.0) return CashyMood.worried;
  if (ratio >= 0.8) return CashyMood.alert;
  return CashyMood.happy;
}
