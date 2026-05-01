import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/splash_screen.dart';

class AroundApp extends StatelessWidget {
  const AroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'around',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final stage = context.watch<AuthProvider>().stage;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (stage) {
        AuthStage.unknown => const SplashScreen(),
        AuthStage.signedOut => const WelcomeScreen(),
        AuthStage.needsProfile => const ProfileSetupScreen(),
        AuthStage.signedIn => const HomeShell(),
      },
    );
  }
}

