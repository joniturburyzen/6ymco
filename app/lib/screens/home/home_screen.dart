// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../widgets/common/generate_plan_popup.dart';
import '../../widgets/common/machine_info_popup.dart';

const _weekdays = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];

bool _characterViewRegistered = false;

void _registerCharacterView() {
  if (_characterViewRegistered) return;
  _characterViewRegistered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    'character-3d',
    (int id) => html.IFrameElement()
      ..src = 'character.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = 'transparent',
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _registerCharacterView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Icono perfil — esquina superior derecha
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: const Icon(Icons.person_outline, color: Color(0xFF444444), size: 24),
              ),
            ),

            // Layout principal
            Column(
              children: [
                const Spacer(),

                // GENERAR PLAN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _HomeButton(
                    label: 'GENERAR PLAN',
                    onTap: () async {
                      final plan = await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const GeneratePlanPopup(),
                      );
                      if (plan != null && context.mounted) {
                        context.push('/routine?day=${_weekdays[DateTime.now().weekday - 1]}');
                      }
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Personaje 3D
                const SizedBox(
                  width: 220,
                  height: 300,
                  child: HtmlElementView(viewType: 'character-3d'),
                ),

                const SizedBox(height: 32),

                // RUTINA HOY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _HomeButton(
                    label: 'RUTINA HOY',
                    onTap: () => context.push('/routine?day=${_weekdays[DateTime.now().weekday - 1]}'),
                  ),
                ),

                const Spacer(),
              ],
            ),

            // Botones de diálogo laterales
            const Positioned.fill(child: _DialogButtons()),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HomeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF222222)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 13,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _DialogButtons extends StatelessWidget {
  const _DialogButtons();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerY = constraints.maxHeight / 2;
        return Stack(
          children: [
            Positioned(
              left: 12,
              top: centerY - 40,
              child: _BubbleButton(
                label: 'EXPLI-\nCACIÓN',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const MachineInfoPopup(),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: centerY - 40,
              child: _BubbleButton(
                label: 'ANÁLISIS\nPOSTURAS',
                onTap: () async {
                  final machine = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (_) => const _MachinePickerDialog(),
                  );
                  if (machine != null && context.mounted) {
                    context.push('/form-analysis?machine=${machine['id']}');
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BubbleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BubbleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF00FF88)),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Selector de máquina para análisis de posturas ─────────────────────────────
class _MachinePickerDialog extends StatefulWidget {
  const _MachinePickerDialog();

  @override
  State<_MachinePickerDialog> createState() => _MachinePickerDialogState();
}

class _MachinePickerDialogState extends State<_MachinePickerDialog> {
  String _search = '';

  static const _catLabels = {
    'cardio': 'CARDIO', 'piernas': 'PIERNAS', 'gluteo': 'GLÚTEO',
    'espalda': 'ESPALDA', 'pecho': 'PECHO', 'hombros': 'HOMBROS',
    'brazos': 'BRAZOS', 'core': 'CORE', 'multiusos': 'MULTIUSOS',
  };

  Map<String, List<Map<String, String>>> _grouped() {
    final q = _search.toLowerCase();
    final result = <String, List<Map<String, String>>>{};
    for (final m in AppConstants.machines) {
      if (q.isEmpty || m['name']!.toLowerCase().contains(q)) {
        result.putIfAbsent(m['category']!, () => []).add(m);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.80,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'SELECCIONA EJERCICIO',
                    style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Buscar máquina...',
                  hintStyle: TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF333333), size: 16),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF222222))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF88))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in _grouped().entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        _catLabels[entry.key] ?? entry.key.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3),
                      ),
                    ),
                    for (final m in entry.value)
                      InkWell(
                        onTap: () => Navigator.pop(context, m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(m['name']!, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                              ),
                              const Icon(Icons.videocam_outlined, color: Color(0xFF333333), size: 16),
                            ],
                          ),
                        ),
                      ),
                    const Divider(color: Color(0xFF111111), height: 1, indent: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
