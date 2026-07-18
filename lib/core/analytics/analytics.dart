import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interfața de analytics. Codul de feature nu vorbește direct cu PostHog,
/// trece prin acest contract; numele evenimentelor vin din `AnalyticsEvents`.
abstract interface class Analytics {
  /// Emite un eveniment cu proprietăți opționale.
  void track(String event, [Map<String, Object?> props]);
}

/// Scrie evenimentele în consolă doar în debug; în release nu face nimic.
class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void track(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${props.isEmpty ? '' : props}');
    }
  }
}

/// Nu emite nimic. Folosită în release până conectăm PostHog.
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void track(String event, [Map<String, Object?> props = const {}]) {}
}

/// Debug în debug, Noop în release.
/// TODO: înlocuiește cu implementarea PostHog când există contul EU.
final analyticsProvider = Provider<Analytics>((ref) {
  return kDebugMode ? const DebugAnalytics() : const NoopAnalytics();
});
