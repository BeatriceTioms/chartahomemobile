import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, Supabase;

import 'backend/config.dart';
import 'backend/mock_backend.dart';
import 'backend/supabase_backend.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/notifications_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Like the SaaS: English only when the phone asks for it, French otherwise.
  final device = PlatformDispatcher.instance.locale.languageCode;
  final state = AppState(
    lang: device == 'en' ? 'en' : 'fr',
    // The real backend when env values are provided (env/example.json),
    // the demo otherwise.
    backend: BackendConfig.isConfigured ? SupabaseBackend() : MockBackend(),
  );
  runApp(ChartaHomeApp(state: state));
}

class ChartaHomeApp extends StatefulWidget {
  const ChartaHomeApp({super.key, required this.state});
  final AppState state;

  @override
  State<ChartaHomeApp> createState() => _ChartaHomeAppState();
}

class _ChartaHomeAppState extends State<ChartaHomeApp> {
  late final Future<void> _ready = _boot();

  Future<void> _boot() async {
    final state = widget.state;
    await state.bootstrap();
    // `flutter run --dart-define=SKIP_AUTH=true` opens straight on the app.
    if (const bool.fromEnvironment('SKIP_AUTH')) {
      state
        ..onboarded = true
        ..notificationsAsked = true
        ..signedIn = true;
    }
    if (!state.backend.isDemo) {
      // Social sign-in and email confirmation come back through the
      // chartahome:// deep link; Supabase turns it into a session here.
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) state.onSessionRestored();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Charta Home',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: Locale(state.lang),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FutureBuilder<void>(
            future: _ready,
            builder: (_, snap) => snap.connectionState == ConnectionState.done ? const _Root() : const _Splash(),
          ),
        ),
      ),
    );
  }
}

/// Onboarding → notifications → sign in → app, with a soft cross-fade.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final Widget child;
    if (!app.onboarded) {
      child = const OnboardingScreen(key: ValueKey('onb'));
    } else if (!app.notificationsAsked) {
      child = const NotificationsPermissionScreen(key: ValueKey('notif'));
    } else if (!app.signedIn) {
      child = const LoginScreen(key: ValueKey('auth'));
    } else {
      child = const Shell(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: child);
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.white,
    body: Center(child: LogoMark(size: 72)),
  );
}
