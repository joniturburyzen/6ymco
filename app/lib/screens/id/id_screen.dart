import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_profile.dart';
import 'widgets/ficha_popup.dart';
import 'widgets/ar_analysis_popup.dart';

class IdScreen extends StatefulWidget {
  const IdScreen({super.key});

  @override
  State<IdScreen> createState() => _IdScreenState();
}

class _IdScreenState extends State<IdScreen> {
  bool _fichaComplete = false;
  bool _arComplete = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final profile = await FirebaseService.loadProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _fichaComplete = profile.fichaComplete;
      _arComplete = profile.arComplete;
    });
  }

  void _onBothComplete() {
    if (_fichaComplete && _arComplete) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '6YM.C0',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 20,
                  fontFamily: 'monospace',
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CONFIGURACIÓN INICIAL',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 60),
              Expanded(
                child: Row(
                  children: [
                    // BLOQUE FICHA
                    Expanded(
                      child: _IdBlock(
                        label: 'FICHA',
                        subtitle: 'Lesiones · Objetivos\nAversiones · Horario',
                        icon: Icons.person_outline,
                        complete: _fichaComplete,
                        onTap: () async {
                          final profile = await FirebaseService.loadProfile();
                          if (!mounted) return;
                          final result = await showDialog<UserProfile>(
                            context: context,
                            builder: (_) => FichaPopup(existing: profile),
                          );
                          if (result == null || !mounted) return;
                          final uid = FirebaseService.uid ?? '';
                          await FirebaseService.saveProfile(
                            UserProfile(
                              uid: uid,
                              injuries: result.injuries,
                              goals: result.goals,
                              schedule: result.schedule,
                              aversions: result.aversions,
                              availableMachines: result.availableMachines,
                              fichaComplete: true,
                              arComplete: _arComplete, // usa estado local, no Firebase
                            ),
                          );
                          setState(() => _fichaComplete = true);
                          _onBothComplete();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // BLOQUE ANÁLISIS AR
                    Expanded(
                      child: _IdBlock(
                        label: 'ANÁLISIS AR',
                        subtitle: '3 fotos de referencia\nMesh personalizado',
                        icon: Icons.accessibility_new_outlined,
                        complete: _arComplete,
                        onTap: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const ARAnalysisPopup(),
                          );
                          if (result == true && mounted) {
                            setState(() => _arComplete = true);
                            _onBothComplete();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_fichaComplete && _arComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/home'),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _IdBlock extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool complete;
  final VoidCallback onTap;

  const _IdBlock({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.complete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(
            color: complete ? const Color(0xFF00FF88) : const Color(0xFF222222),
            width: complete ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              complete ? Icons.check_circle_outline : icon,
              color: complete ? const Color(0xFF00FF88) : const Color(0xFF444444),
              size: 40,
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: TextStyle(
                color: complete ? const Color(0xFF00FF88) : Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
