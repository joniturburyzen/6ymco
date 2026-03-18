import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/worker_service.dart';
import '../../../models/user_profile.dart';

class GeneratePlanPopup extends StatefulWidget {
  const GeneratePlanPopup({super.key});

  @override
  State<GeneratePlanPopup> createState() => _GeneratePlanPopupState();
}

class _GeneratePlanPopupState extends State<GeneratePlanPopup> {
  UserProfile? _profile;
  bool _loadingProfile = true;
  bool _generating = false;
  String? _error;

  // Ajustes opcionales antes de generar
  String _focusOverride = '';  // vacío = Qwen decide según objetivos del perfil
  int _weeksOverride = 0;      // 0 = usar los del primer objetivo

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await FirebaseService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loadingProfile = false;
      if (p != null && p.goals.isNotEmpty) {
        // Redondea al valor más cercano disponible en el dropdown
        const opts = [4, 6, 8, 10, 12];
        final w = p.goals.first.weeks;
        _weeksOverride = opts.reduce((a, b) => (a - w).abs() <= (b - w).abs() ? a : b);
      } else {
        _weeksOverride = 8;
      }
    });
  }

  Future<void> _generate() async {
    if (_profile == null) return;
    setState(() { _generating = true; _error = null; });

    try {
      // Inyecta los ajustes opcionales en el perfil antes de enviarlo
      final profileToSend = _buildProfileForWorker(_profile!);
      final plan = await WorkerService.generatePlan(profileToSend);
      await FirebaseService.saveActivePlan(plan);
      if (!mounted) return;
      Navigator.pop(context, plan);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _generating = false; });
    }
  }

  UserProfile _buildProfileForWorker(UserProfile p) {
    // Si el usuario ajustó el foco, lo añadimos como primer objetivo extra
    final goals = List<GoalEntry>.from(p.goals);
    if (_focusOverride.isNotEmpty) {
      goals.insert(0, GoalEntry(
        description: 'FOCO SELECCIONADO: $_focusOverride',
        weeks: _weeksOverride > 0 ? _weeksOverride : 8,
        createdAt: DateTime.now(),
      ));
    } else if (_weeksOverride > 0 && goals.isNotEmpty) {
      // Reemplaza semanas del primer objetivo
      goals[0] = GoalEntry(
        description: goals[0].description,
        weeks: _weeksOverride,
        createdAt: goals[0].createdAt,
      );
    }
    return p.copyWith(goals: goals);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: double.infinity,
        child: _loadingProfile
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00FF88))),
              )
            : _profile == null
                ? _NoProfile(onClose: () => Navigator.pop(context))
                : _generating
                    ? const _GeneratingView()
                    : _FormView(
                        profile: _profile!,
                        focusOverride: _focusOverride,
                        weeksOverride: _weeksOverride,
                        error: _error,
                        onFocusChanged: (v) => setState(() => _focusOverride = v),
                        onWeeksChanged: (v) => setState(() => _weeksOverride = v),
                        onGenerate: _generate,
                        onCancel: () => Navigator.pop(context),
                      ),
      ),
    );
  }
}

// ── Sin perfil ─────────────────────────────────────────────────────────────────
class _NoProfile extends StatelessWidget {
  final VoidCallback onClose;
  const _NoProfile({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Completa tu FICHA primero.',
            style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onClose,
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

// ── Generando (spinner) ────────────────────────────────────────────────────────
class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF00FF88), strokeWidth: 1.5),
          SizedBox(height: 24),
          Text(
            'GENERANDO PLAN...',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Qwen analiza tu perfil y tus objetivos',
            style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Formulario principal ───────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final UserProfile profile;
  final String focusOverride;
  final int weeksOverride;
  final String? error;
  final ValueChanged<String> onFocusChanged;
  final ValueChanged<int> onWeeksChanged;
  final VoidCallback onGenerate;
  final VoidCallback onCancel;

  const _FormView({
    required this.profile,
    required this.focusOverride,
    required this.weeksOverride,
    required this.error,
    required this.onFocusChanged,
    required this.onWeeksChanged,
    required this.onGenerate,
    required this.onCancel,
  });

  static const _focusOptions = [
    '',
    'Fuerza',
    'Hipertrofia',
    'Pérdida de grasa',
    'Resistencia cardiovascular',
    'Movilidad y rehabilitación',
  ];

  static const _weekOptions = [4, 6, 8, 10, 12];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'GENERAR PLAN',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCancel,
                child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Resumen del perfil
          _Section(label: 'LESIONES', child: _Tags(
            items: profile.injuries.isEmpty ? ['Ninguna'] : profile.injuries,
          )),
          const SizedBox(height: 16),
          _Section(label: 'OBJETIVOS', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: profile.goals.isEmpty
                ? [_dim('Sin objetivos definidos')]
                : profile.goals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '— ${g.description}  (${g.weeks} sem)',
                      style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 11, height: 1.5),
                    ),
                  )).toList(),
          )),
          const SizedBox(height: 16),
          _Section(label: 'DÍAS DISPONIBLES', child: _Tags(
            items: profile.schedule.isEmpty
                ? ['No definido']
                : profile.schedule.map((s) => '${s.day} ${s.start}').toList(),
          )),
          const SizedBox(height: 16),
          _Section(label: 'MÁQUINAS', child: Text(
            '${profile.availableMachines.length} máquinas disponibles',
            style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 11),
          )),

          const SizedBox(height: 28),
          const Divider(color: Color(0xFF1A1A1A)),
          const SizedBox(height: 20),

          // Ajustes opcionales
          const Text(
            'AJUSTES OPCIONALES',
            style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3),
          ),
          const SizedBox(height: 16),

          // Foco
          const Text(
            'Foco del plan',
            style: TextStyle(color: Color(0xFF666666), fontFamily: 'monospace', fontSize: 11),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: focusOverride,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            underline: Container(height: 1, color: const Color(0xFF333333)),
            items: _focusOptions.map((f) => DropdownMenuItem(
              value: f,
              child: Text(f.isEmpty ? 'Según mis objetivos (recomendado)' : f),
            )).toList(),
            onChanged: (v) => onFocusChanged(v ?? ''),
          ),

          const SizedBox(height: 16),

          // Duración
          const Text(
            'Duración del plan',
            style: TextStyle(color: Color(0xFF666666), fontFamily: 'monospace', fontSize: 11),
          ),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: _weekOptions.contains(weeksOverride) ? weeksOverride : 8,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            underline: Container(height: 1, color: const Color(0xFF333333)),
            items: _weekOptions.map((w) => DropdownMenuItem(
              value: w,
              child: Text('$w semanas'),
            )).toList(),
            onChanged: (v) => onWeeksChanged(v ?? 8),
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontSize: 11),
            ),
          ],

          const SizedBox(height: 28),

          // Botón generar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onGenerate,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'GENERAR PLAN',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dim(String text) => Text(
    text,
    style: const TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11),
  );
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _Tags extends StatelessWidget {
  final List<String> items;
  const _Tags({required this.items});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: items.map((item) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF222222)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(item, style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 10)),
    )).toList(),
  );
}
