import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'shared/providers/app_state_provider.dart';
import 'core/ui/app_keys.dart';

void main() {
  runApp(const ProviderScope(child: ForsaApp()));
}

class ForsaApp extends ConsumerStatefulWidget {
  const ForsaApp({super.key});

  @override
  ConsumerState<ForsaApp> createState() => _ForsaAppState();
}

class _ForsaAppState extends ConsumerState<ForsaApp> {
  // Show router immediately; SplashScreen will handle initialization/navigation.
  final bool _isReady = true;

  @override
  void initState() {
    super.initState();
    _initAppState();
  }

  Future<void> _initAppState() async {
    try {
      await ref.read(appStateProvider.notifier).loadInitialState();
    } catch (_) {}
    // No direct navigation here: SplashScreen performs navigation after init.
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(currentThemeModeProvider);

    // While initializing, show a minimal splash/loading UI to avoid blank screen
    if (!_isReady) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          title: 'فرصة - إعلانات مبوبة',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    // proceed normally to app router

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: 'فرصة - إعلانات مبوبة',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'SA'), // Arabic
          Locale('en', 'US'), // English
        ],
        locale: const Locale('ar', 'SA'),
      ),
    );
  }
}




