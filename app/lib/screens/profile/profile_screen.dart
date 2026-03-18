import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_profile.dart';
import '../id/widgets/ficha_popup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await FirebaseService.loadProfile();
    if (!mounted) return;
    setState(() { _profile = p; _loading = false; });
  }

  // ── FICHA ──────────────────────────────────────────────────────────────────
  Future<void> _openFicha() async {
    final result = await showDialog<UserProfile>(
      context: context,
      builder: (_) => FichaPopup(existing: _profile),
    );
    if (result == null || !mounted) return;
    final uid = FirebaseService.uid ?? '';
    final updated = UserProfile(
      uid: uid,
      injuries: result.injuries,
      goals: result.goals,
      schedule: result.schedule,
      aversions: result.aversions,
      availableMachines: result.availableMachines,
      fichaComplete: true,
      arComplete: _profile?.arComplete ?? false,
      anthropometric: _profile?.anthropometric,
    );
    await FirebaseService.saveProfile(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  // ── MÁQUINAS ───────────────────────────────────────────────────────────────
  Future<void> _openMachines() async {
    final current = List<String>.from(_profile?.availableMachines ?? []);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _MachinesDialog(selected: current),
    );
    if (result == null || !mounted) return;
    final updated = (_profile ?? UserProfile(uid: FirebaseService.uid ?? ''))
        .copyWith(availableMachines: result);
    await FirebaseService.saveProfile(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  // ── SEGUIMIENTO AR ─────────────────────────────────────────────────────────
  Future<void> _openTracking() async {
    final history = await FirebaseService.loadWeeklyMeshHistory();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _TrackingDialog(history: history),
    );
  }

  // ── PRIVACIDAD ─────────────────────────────────────────────────────────────
  Future<void> _openPrivacy() async {
    await showDialog(
      context: context,
      builder: (_) => _PrivacyDialog(
        onDeleteData: _deleteData,
        onDeleteAccount: _deleteAccount,
      ),
    );
  }

  Future<void> _deleteData() async {
    await FirebaseService.deleteActivePlan();
    await FirebaseService.saveProfile(UserProfile(
      uid: FirebaseService.uid ?? '',
      fichaComplete: false,
      arComplete: false,
    ));
    if (!mounted) return;
    setState(() => _profile = null);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    await FirebaseService.deleteActivePlan();
    await FirebaseService.signOut();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseService.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'ID',
          style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', letterSpacing: 4, fontSize: 14),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF444444)),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseService.signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text('SALIR', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11, letterSpacing: 2)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88), strokeWidth: 1.5))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, left: 4),
                    child: Text(email, style: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 11)),
                  ),
                _Section(
                  label: 'FICHA',
                  subtitle: _profile?.fichaComplete == true ? 'Completada' : 'Sin completar',
                  complete: _profile?.fichaComplete ?? false,
                  onTap: _openFicha,
                ),
                _Section(
                  label: 'MÁQUINAS DE MI GIMNASIO',
                  subtitle: _profile != null
                      ? '${_profile!.availableMachines.length} máquinas seleccionadas'
                      : '—',
                  onTap: _openMachines,
                ),
                _Section(
                  label: 'SEGUIMIENTO SEMANAL AR',
                  subtitle: _profile?.arComplete == true ? 'Ver historial' : 'Completa el análisis AR primero',
                  onTap: _profile?.arComplete == true ? _openTracking : null,
                ),
                _Section(
                  label: 'PRIVACIDAD Y DATOS',
                  subtitle: 'Gestionar o eliminar datos',
                  onTap: _openPrivacy,
                  danger: true,
                ),
              ],
            ),
    );
  }
}

// ── Sección ────────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool complete;
  final bool danger;
  final VoidCallback? onTap;

  const _Section({
    required this.label,
    required this.subtitle,
    this.complete = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: complete ? const Color(0xFF00FF88).withOpacity(0.4) : const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: disabled ? const Color(0xFF333333) : danger ? const Color(0xFF884444) : Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? const Color(0xFF222222) : const Color(0xFF444444),
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (complete)
              const Icon(Icons.check_circle_outline, color: Color(0xFF00FF88), size: 16)
            else if (!disabled)
              const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Máquinas ───────────────────────────────────────────────────────────────────
class _MachinesDialog extends StatefulWidget {
  final List<String> selected;
  const _MachinesDialog({required this.selected});

  @override
  State<_MachinesDialog> createState() => _MachinesDialogState();
}

class _MachinesDialogState extends State<_MachinesDialog> {
  late final List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  static const _catLabels = {
    'cardio': 'CARDIO', 'piernas': 'PIERNAS', 'gluteo': 'GLÚTEO',
    'espalda': 'ESPALDA', 'pecho': 'PECHO', 'hombros': 'HOMBROS',
    'brazos': 'BRAZOS', 'core': 'CORE', 'multiusos': 'MULTIUSOS',
  };

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, String>>>{};
    for (final m in AppConstants.machines) {
      grouped.putIfAbsent(m['category']!, () => []).add(m);
    }

    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  const Text('MÁQUINAS DISPONIBLES',
                      style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(_catLabels[entry.key] ?? entry.key.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3)),
                    ),
                    for (final m in entry.value)
                      InkWell(
                        onTap: () => setState(() {
                          _selected.contains(m['id'])
                              ? _selected.remove(m['id'])
                              : _selected.add(m['id']!);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          child: Row(
                            children: [
                              Icon(
                                _selected.contains(m['id']) ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                                color: _selected.contains(m['id']) ? const Color(0xFF00FF88) : const Color(0xFF333333),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(m['name']!, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    const Divider(color: Color(0xFF111111), height: 1, indent: 20),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Text(
                    'GUARDAR (${_selected.length})',
                    style: const TextStyle(color: Color(0xFF0A0A0A), fontFamily: 'monospace', letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 12),
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

// ── Seguimiento AR ─────────────────────────────────────────────────────────────
class _TrackingDialog extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _TrackingDialog({required this.history});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  const Text('SEGUIMIENTO AR',
                      style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text('Sin registros todavía.',
                          style: TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 12)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MÉTRICAS SEMANALES',
                              style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3)),
                          const SizedBox(height: 16),
                          // Header
                          _TableRow(cells: const ['SEMANA', 'FEM/TIB', 'TORSO', 'RODILLA°', 'HOMBRO°'], header: true),
                          const Divider(color: Color(0xFF1A1A1A), height: 8),
                          ...history.asMap().entries.map((entry) {
                            final i = entry.key;
                            final d = entry.value;
                            final rom = d['rom'] as Map<String, dynamic>? ?? {};
                            return Column(
                              children: [
                                _TableRow(cells: [
                                  'S-$i',
                                  (d['femur_tibia_ratio'] as num?)?.toStringAsFixed(2) ?? '—',
                                  (d['torso_height_ratio'] as num?)?.toStringAsFixed(2) ?? '—',
                                  (rom['knee_flexion'] as num?)?.toStringAsFixed(0) ?? '—',
                                  (rom['shoulder_flexion'] as num?)?.toStringAsFixed(0) ?? '—',
                                ]),
                                const Divider(color: Color(0xFF111111), height: 4),
                              ],
                            );
                          }),
                          const SizedBox(height: 24),
                          const Text('FEM/TIB = ratio fémur/tibia  ·  TORSO = ratio torso/altura',
                              style: TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 9, height: 1.6)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool header;
  const _TableRow({required this.cells, this.header = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cells.asMap().entries.map((e) => Expanded(
        flex: e.key == 0 ? 1 : 2,
        child: Text(
          e.value,
          textAlign: e.key == 0 ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: header ? const Color(0xFF444444) : Colors.white,
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: header ? 1 : 0,
          ),
        ),
      )).toList(),
    );
  }
}

// ── Privacidad ─────────────────────────────────────────────────────────────────
class _PrivacyDialog extends StatelessWidget {
  final Future<void> Function() onDeleteData;
  final Future<void> Function() onDeleteAccount;

  const _PrivacyDialog({required this.onDeleteData, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('PRIVACIDAD Y DATOS',
                    style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Tus datos se almacenan en Firestore bajo tu UID de Google. '
              'Solo tú tienes acceso a ellos. Ningún tercero los recibe.',
              style: TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 11, height: 1.6),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF1A1A1A)),
            const SizedBox(height: 20),
            _DangerButton(
              label: 'BORRAR MIS DATOS',
              subtitle: 'Elimina ficha, plan y mesh AR. La cuenta permanece.',
              onTap: () async {
                final confirm = await _confirm(context, '¿Borrar todos tus datos?');
                if (confirm == true) await onDeleteData();
              },
            ),
            const SizedBox(height: 12),
            _DangerButton(
              label: 'CERRAR CUENTA',
              subtitle: 'Cierra sesión y elimina todos los datos.',
              onTap: () async {
                final confirm = await _confirm(context, '¿Cerrar cuenta y eliminar todos los datos?');
                if (confirm == true) await onDeleteAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String message) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIRMAR', style: TextStyle(color: Colors.red, fontFamily: 'monospace')),
            ),
          ],
        ),
      );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3A1A1A)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF884444), fontFamily: 'monospace', fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
