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
  final profile =
      await container.read(localProfileRepositoryProvider).get();
  OnboardingGate.done = profile.onboarded;

  // Generează tranzacțiile recurente scadente de la ultima deschidere.
  if (profile.onboarded) {
    try {
      await container.read(recurringRepositoryProvider).materializeDue();
    } catch (_) {/* nu blocăm pornirea aplicației */}
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: FinEduApp(
      router:
          buildRouter(initialLocation: profile.onboarded ? '/home' : '/onboarding'),
    ),
  ));
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
