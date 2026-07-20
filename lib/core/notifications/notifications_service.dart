import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Strat subțire peste `flutter_local_notifications`. Merge doar pe Android,
/// unde cerem POST_NOTIFICATIONS și programăm un singur memento, a doua zi
/// la 19:00. Ora ocolește programul de școală și orele de somn, după
/// regulile AADC.
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

class NotificationsService {
  NotificationsService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'finedu_reminders';
  static const _channelName = 'Memento zilnic';
  static const _reminderId = 1001;

  /// Id-urile escaladării D1/D3/D7. Le anulăm mereu înainte de reprogramare;
  /// NU folosim cancelAll, id-ul 1001 e al onboarding-ului.
  static const _escalationIds = [2001, 2003, 2007];

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Cere permisiunea de notificări la runtime (Android 13+). Returnează
  /// dacă a fost acordată (versiunile mai vechi de Android întorc true).
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Programează un singur memento mâine la 19:00 cu [title]/[body].
  /// Best-effort: orice eroare de platformă/plugin e înghițită, ca
  /// onboarding-ul să nu depindă de o notificare.
  Future<void> scheduleTomorrowReminder({
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        19,
      );
      // Gardă pentru DST, care ar putea împinge ora în trecut.
      if (!scheduled.isAfter(now)) {
        scheduled = now.add(const Duration(hours: 1));
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Un memento blând, o dată pe zi.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      await _plugin.zonedSchedule(
        _reminderId,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Eroarea de memento nu trebuie să blocheze onboarding-ul.
      debugPrint('[notifications] schedule failed: $e');
    }
  }

  /// Dacă permisiunea de notificări e acordată acum (Android 13+).
  /// Best-effort: false pe non-Android / plugin null / orice eroare.
  Future<bool> areEnabled() async {
    try {
      await _ensureInitialized();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;
      return await android.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('[notifications] areEnabled failed: $e');
      return false;
    }
  }

  /// Reprogramează escaladarea „de absență": anulează întâi sloturile
  /// D1/D3/D7 (nu cancelAll, 1001 e al onboarding-ului), apoi le repune
  /// din [slots]. Best-effort: orice eroare e înghițită.
  Future<void> rescheduleEscalation(
    List<({int id, DateTime when, String title, String body})> slots,
  ) async {
    try {
      await _ensureInitialized();
      for (final id in _escalationIds) {
        await _plugin.cancel(id);
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Un memento blând, o dată pe zi.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      for (final slot in slots) {
        final w = slot.when;
        final scheduled = tz.TZDateTime(
          tz.local,
          w.year,
          w.month,
          w.day,
          w.hour,
          w.minute,
        );
        await _plugin.zonedSchedule(
          slot.id,
          slot.title,
          slot.body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('[notifications] reschedule failed: $e');
    }
  }
}
