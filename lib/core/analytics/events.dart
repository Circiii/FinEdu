/// Numele canonice ale evenimentelor de analytics, un singur loc pentru schemă,
/// folosite peste tot în loc de string-uri libere. Convenție: `snake_case`.
class AnalyticsEvents {
  AnalyticsEvents._();

  // --- Ciclu de viață & activare

  /// Deschiderea aplicației (cold/warm start). Date: {}.
  static const String appOpen = 'app_open';

  /// Un pas din funnel-ul de activare a fost atins. Date: {step}, ex.
  /// 'hatch' | 'first_lesson' | 'age_gate' | 'first_expense' | 'notif_softask'.
  static const String activationStep = 'activation_step';

  // --- Învățare & review

  /// O micro-lecție a fost terminată cap-coadă.
  /// Date: {lesson_id, unit, track}.
  static const String lessonComplete = 'lesson_complete';

  /// Un card din review deck-ul FSRS a fost revizuit.
  /// Date: {card_id, rating} (rating = again|hard|good|easy).
  static const String reviewDone = 'review_done';

  // --- Bani (nucleul; metrica de sănătate anti-gaming)

  /// O cheltuială a fost logată. Date: {source, category}
  /// source = manual | receipt | voice | recurring.
  static const String expenseLogged = 'expense_logged';

  /// Butonul „azi n-am cheltuit nimic" (zi fără cheltuieli = informație). Date: {}.
  static const String noSpendMarked = 'no_spend_marked';

  // --- Quest-uri & cufere

  /// Un quest zilnic a fost finalizat (revendicat). Date: {quest_id, slot}.
  static const String questComplete = 'quest_complete';

  /// Un cufăr a fost deschis. Date: {chest_type, acorns_awarded}.
  static const String chestOpened = 'chest_opened';

  // --- Arcade (jocuri)

  /// Un joc din Arcade a fost pornit. Date: {game}, ex. 'dojo' |
  /// 'daily_challenge' | 'turbo_budget' | 'life_month' | 'oak_tree' | 'duel'.
  static const String gamePlayed = 'game_played';

  /// Rezultatul unei runde de joc. Date: {game, score, won}.
  static const String gameResult = 'game_result';

  // --- „30 de Zile: Pe Cont Propriu" (simularea de lună)

  /// O lună a fost pornită. Date: {role, mode, replay} (fără date financiare).
  static const String lifeSimStarted = 'life_sim_started';

  /// O zi a fost avansată în simulare. Date: {day, had_event}.
  static const String lifeSimDayAdvanced = 'life_sim_day_advanced';

  /// O alegere a fost aplicată la un eveniment. Date: {event_id, choice_idx}.
  static const String lifeSimChoiceMade = 'life_sim_choice_made';

  /// Luna a fost terminată (ziua 30). Date: {score, ending}.
  static const String lifeSimCompleted = 'life_sim_completed';

  /// Raportul/debrief-ul a fost vizualizat. Date: {}.
  static const String lifeSimDebriefViewed = 'life_sim_debrief_viewed';

  /// „Reia aceeași lună" a fost pornit (același seed). Date: {role, mode}.
  static const String lifeSimReplayed = 'life_sim_replayed';

  // --- Streak

  /// Streak-ul a fost extins (o acțiune în ziua respectivă). Date: {current_streak}.
  static const String streakExtended = 'streak_extended';

  /// O Ghindă de Gheață a fost consumată silențios pentru a proteja streak-ul.
  /// Date: {current_streak}.
  static const String streakFrozen = 'streak_frozen';

  /// Streak-ul s-a rupt definitiv (earn-back expirat). Date: {longest_streak}.
  static const String streakBroken = 'streak_broken';

  /// Streak-ul a fost recuperat prin earn-back (efort dublu în 48h).
  /// Date: {current_streak}.
  static const String streakRepaired = 'streak_repaired';

  // --- Notificări (reward = conversie 2h, nu open rate)

  /// O notificare a fost trimisă. Date: {arm} (template/braț de bandit).
  static const String notifSent = 'notif_sent';

  /// O notificare a fost deschisă. Date: {arm}.
  static const String notifOpened = 'notif_opened';

  /// Notificarea a dus la o acțiune terminată în 2h (conversie reală). Date: {arm}.
  static const String notifConverted = 'notif_converted';

  // --- Social

  /// O invitație socială a fost trimisă. Date: {channel}, ex. 'link' | 'whatsapp'.
  static const String socialInviteSent = 'social_invite_sent';

  /// O invitație socială a fost acceptată (destinatarul s-a înscris). Date: {}.
  static const String socialInviteAccepted = 'social_invite_accepted';

  /// Un cadou (Ghinda Norocoasă) a fost trimis. Date: {to_friend_hash}.
  static const String giftSent = 'gift_sent';

  // --- Dueluri

  /// Un duel 1v1 a fost inițiat. Date: {duel_id}.
  static const String duelStarted = 'duel_started';

  /// Un duel s-a încheiat. Date: {duel_id, won}.
  static const String duelFinished = 'duel_finished';

  // --- Sezon & economie

  /// Progres în sezonul curent (obiectiv atins / track avansat). Date: {objective_id}.
  static const String seasonProgress = 'season_progress';

  /// Un item cosmetic a fost cumpărat cu ghinde. Date: {item_id, price}.
  static const String purchaseItem = 'purchase_item';

  // --- Monetizare

  /// Paywall-ul premium a fost afișat. Date: {source} (unde a fost declanșat).
  static const String paywallView = 'paywall_view';

  /// Un abonament a fost activat. Date: {plan}.
  static const String subscribe = 'subscribe';
}
