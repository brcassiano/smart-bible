import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/ai_chat/ai_chat_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/reader/reader_screen.dart';
import 'presentation/screens/setup/setup_screen.dart';
import 'presentation/screens/word_study/word_study_screen.dart';
import 'presentation/widgets/persistent_chat_bar.dart';

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final setupDone = prefs.getBool('setup_completed') ?? false;
    final isSetupRoute = state.matchedLocation == '/setup';

    if (!setupDone && !isSetupRoute) return '/setup';
    if (setupDone && isSetupRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/reader',
      builder: (context, state) => const ReaderScreen(),
    ),
    GoRoute(
      path: '/word-study',
      builder: (context, state) => const WordStudyScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
  ],
);

class SmartBibleApp extends StatelessWidget {
  const SmartBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Bible',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => PersistentChatBar(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
