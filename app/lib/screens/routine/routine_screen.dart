import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../models/workout_plan.dart';
import '../../core/constants.dart';
import '../../widgets/common/generate_plan_popup.dart';

class RoutineScreen extends StatefulWidget {
  final String dayKey;
  const RoutineScreen({super.key, required this.dayKey});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  DayPlan? _plan;
  bool _loading = true;
  bool _hasPlan = false; // distingue "no hay plan" de "hoy es descanso"

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final activePlan = await FirebaseService.loadActivePlan();
    if (!mounted) return;
    setState(() {
      _hasPlan = activePlan != null;
      _plan = activePlan?.todayPlan();
      _loading = false;
    });
  }

  Future<void> _openGeneratePlan() async {
    final plan = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GeneratePlanPopup(),
    );
    if (plan != null && mounted) {
      await _load(); // recarga la rutina sin salir de la pantalla
    }
  }

  String _machineName(String id) {
    try {
      return AppConstants.machines.firstWhere((m) => m['id'] == id)['name']!;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          widget.dayKey.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontFamily: 'monospace',
            letterSpacing: 4,
            fontSize: 14,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF444444)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)))
          : !_hasPlan
              ? _NoPlanView(onGenerate: () => _openGeneratePlan())
              : _plan == null
                  ? const Center(
                      child: Text(
                        'HOY ES DÍA DE DESCANSO.',
                        style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', letterSpacing: 2),
                      ),
                    )
                  : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plan!.exercises.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF1A1A1A), height: 1),
                  itemBuilder: (_, i) {
                    final ex = _plan!.exercises[i];
                    return _ExerciseTile(
                      exercise: ex,
                      machineName: _machineName(ex.machineId),
                      onToggle: () => setState(() => ex.completed = !ex.completed),
                    );
                  },
                ),
    );
  }
}

class _NoPlanView extends StatelessWidget {
  final VoidCallback onGenerate;
  const _NoPlanView({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aún no tienes un plan activo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onGenerate,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text(
                  'GENERAR PLAN',
                  style: TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseEntry exercise;
  final String machineName;
  final VoidCallback onToggle;

  const _ExerciseTile({
    required this.exercise,
    required this.machineName,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: exercise.completed ? const Color(0xFF00FF88) : const Color(0xFF222222),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: exercise.completed
              ? const Icon(Icons.check, color: Color(0xFF00FF88), size: 20)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    'assets/machines/${exercise.machineId}.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    color: const Color(0xFF888888),
                    colorBlendMode: BlendMode.modulate,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF333333),
                      size: 20,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        machineName,
        style: TextStyle(
          color: exercise.completed ? const Color(0xFF444444) : Colors.white,
          fontFamily: 'monospace',
          fontSize: 13,
          decoration: exercise.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${exercise.sets} series · ${exercise.reps} reps · tempo ${exercise.tempo} · ${exercise.restSec}s descanso',
        style: const TextStyle(
          color: Color(0xFF555555),
          fontFamily: 'monospace',
          fontSize: 11,
        ),
      ),
      trailing: exercise.machineSetup != null
          ? const Icon(Icons.tune, color: Color(0xFF333333), size: 16)
          : null,
    );
  }
}
