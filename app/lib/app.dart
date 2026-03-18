import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/id/id_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/routine/routine_screen.dart';
import 'screens/form_analysis/form_analysis_screen.dart';
import 'screens/profile/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',         builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/id',       builder: (_, __) => const IdScreen()),
    GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/routine',
      builder: (_, state) => RoutineScreen(
        dayKey: state.uri.queryParameters['day'] ?? 'lunes',
      ),
    ),
    GoRoute(
      path: '/form-analysis',
      builder: (_, state) => FormAnalysisScreen(
        machineId: state.uri.queryParameters['machine'] ?? '',
      ),
    ),
    GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
  ],
);

class GymCoApp extends StatelessWidget {
  const GymCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '6YM.C0',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF88),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
    );
  }
}
