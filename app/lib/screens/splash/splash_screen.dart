import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/firebase_service.dart' show FirebaseService;
import '../../widgets/common/consent_popup.dart';
import '../../widgets/common/signin_popup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) => _onLoadComplete());
  }

  Future<void> _onLoadComplete() async {
    if (!mounted) return;

    // Si ya tiene sesión activa, va directo al destino correcto
    final user = FirebaseService.currentUser;
    if (user != null) {
      final profile = await FirebaseService.loadProfile();
      if (!mounted) return;
      if (profile != null && profile.isComplete) {
        context.go('/home');
      } else {
        context.go('/id');
      }
      return;
    }

    // Primera vez: consentimientos → login
    if (!mounted) return;
    final consented = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentPopup(),
    );

    if (consented != true || !mounted) return;

    final user2 = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SignInPopup(),
    );

    if (user2 != null && mounted) {
      context.go('/id');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / nombre
              FadeTransition(
                opacity: _fadeIn,
                child: const Text(
                  '6YM.C0',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 48,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Barra de progreso
              FadeTransition(
                opacity: _fadeIn,
                child: SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    backgroundColor: const Color(0xFF1A1A1A),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00FF88)),
                    minHeight: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
