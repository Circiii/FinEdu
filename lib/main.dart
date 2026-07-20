import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/db/local_profile_repository.dart';
import 'core/router/app_router.dart';
import 'core/router/onboarding_gate.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/ui/tokens.dart';
import 'features/recurring/data/recurring_repository.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  await initSupabaseIfConfigured();

  // Setează gate ul de onboarding din profilul local înainte să existe routerul.
  final container = ProviderContainer();
  final profile = await container.read(localProfileRepositoryProvider).get();
  OnboardingGate.done = profile.onboarded;

  // Generează tranzacțiile recurente scadente de la ultima deschidere.
  if (profile.onboarded) {
    try {
      await container.read(recurringRepositoryProvider).materializeDue();
    } catch (_) {
      /* nu blocăm pornirea aplicației */
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FinEduApp(
        router: buildRouter(
          initialLocation: profile.onboarded ? '/home' : '/onboarding',
        ),
      ),
    ),
  );
}

class FinEduApp extends StatelessWidget {
  const FinEduApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinEdu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: C.bg, useMaterial3: true),
      scrollBehavior: const _BouncyScroll(),
      builder: kIsWeb ? _webFrame : null,
      routerConfig: router,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ro'), Locale('en')],
      locale: const Locale('ro'),
    );
  }
}

/// Lățimea maximă a aplicației în browser. Interfața e gândită pentru telefon,
/// iar întinsă pe un monitor lat ar arăta gol și dezechilibrat, așa că pe web o
/// ținem într-un cadru centrat de lățimea unui telefon.
const double _webFrameWidth = 460;

/// Cadrul pentru browser: fundal mai închis în jur, aplicația centrată la
/// mijloc. Pe ecrane înguste (telefon sau fereastră mică) cadrul dispare de la
/// sine, fiindcă lățimea disponibilă e sub prag.
Widget _webFrame(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  final width = MediaQuery.sizeOf(context).width;
  if (width <= _webFrameWidth) return child;

  return ColoredBox(
    color: C.text.withValues(alpha: 0.10),
    child: Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(width: _webFrameWidth, child: child),
      ),
    ),
  );
}

/// Scroll cu arc la capete pe toate listele, se simte mai moale decât
/// glow-ul standard Android.
class _BouncyScroll extends MaterialScrollBehavior {
  const _BouncyScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
