import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../models/user_profile.dart';

class FichaPopup extends StatefulWidget {
  final UserProfile? existing;
  const FichaPopup({super.key, this.existing});

  @override
  State<FichaPopup> createState() => _FichaPopupState();
}

class _FichaPopupState extends State<FichaPopup> {
  int _step = 0;
  static const _totalSteps = 5;

  // Datos recogidos
  final List<String> _injuries = [];
  final List<GoalEntry> _goals = [];
  final List<ScheduleBlock> _schedule = [];
  final List<AversionEntry> _aversions = [];
  final List<String> _machines = [];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _injuries.addAll(p.injuries);
      _goals.addAll(p.goals);
      _schedule.addAll(p.schedule);
      _aversions.addAll(p.aversions);
      _machines.addAll(p.availableMachines);
    }
  }

  bool get _canContinue {
    switch (_step) {
      case 0: return _injuries.isNotEmpty;
      case 1: return _goals.isNotEmpty;
      case 2: return _schedule.isNotEmpty;
      case 3: return true; // aversiones opcional
      case 4: return _machines.isNotEmpty;
      default: return false;
    }
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
    else Navigator.pop(context);
  }

  void _save() {
    Navigator.pop(context, UserProfile(
      uid: widget.existing?.uid ?? '',
      injuries: _injuries,
      goals: _goals,
      schedule: _schedule,
      aversions: _aversions,
      availableMachines: _machines,
      fichaComplete: true,
      arComplete: widget.existing?.arComplete ?? false,
    ));
  }

  static const _stepLabels = ['LESIONES', 'OBJETIVOS', 'HORARIO', 'AVERSIONES', 'MÁQUINAS'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _back,
                    child: const Icon(Icons.arrow_back, color: Color(0xFF444444), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _stepLabels[_step],
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_step + 1}/$_totalSteps',
                    style: const TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
            ),
            // Barra de progreso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00FF88)),
                minHeight: 1,
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStep(),
              ),
            ),
            // Botón continuar
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _canContinue ? _next : null,
                  style: TextButton.styleFrom(
                    backgroundColor: _canContinue ? const Color(0xFF00FF88) : const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Text(
                    _step == _totalSteps - 1 ? 'GUARDAR' : 'CONTINUAR',
                    style: TextStyle(
                      color: _canContinue ? const Color(0xFF0A0A0A) : const Color(0xFF333333),
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepLesiones(selected: _injuries, onChange: () => setState(() {}));
      case 1: return _StepObjetivos(goals: _goals, onChange: () => setState(() {}));
      case 2: return _StepHorario(schedule: _schedule, onChange: () => setState(() {}));
      case 3: return _StepAversiones(aversions: _aversions, onChange: () => setState(() {}));
      case 4: return _StepMaquinas(selected: _machines, onChange: () => setState(() {}));
      default: return const SizedBox();
    }
  }
}

// ── STEP 0: Lesiones ──────────────────────────────────────────────────────────
class _StepLesiones extends StatefulWidget {
  final List<String> selected;
  final VoidCallback onChange;

  const _StepLesiones({required this.selected, required this.onChange});

  @override
  State<_StepLesiones> createState() => _StepLesionesState();
}

class _StepLesionesState extends State<_StepLesiones> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHint('Selecciona todas las que apliquen. Afecta a qué ejercicios se prescriben.'),
        const SizedBox(height: 16),
        ...AppConstants.injuryOptions.map((injury) {
          final isSelected = widget.selected.contains(injury);
          return GestureDetector(
            onTap: () {
              if (injury == 'Ninguna' || injury == 'Prefiero no especificar') {
                widget.selected.clear();
                widget.selected.add(injury);
              } else {
                widget.selected.remove('Ninguna');
                widget.selected.remove('Prefiero no especificar');
                if (isSelected) widget.selected.remove(injury);
                else widget.selected.add(injury);
              }
              setState(() {});
              widget.onChange();
            },
            child: _SelectRow(label: injury, selected: isSelected),
          );
        }),
      ],
    );
  }
}

// ── STEP 1: Objetivos ─────────────────────────────────────────────────────────
class _StepObjetivos extends StatefulWidget {
  final List<GoalEntry> goals;
  final VoidCallback onChange;

  const _StepObjetivos({required this.goals, required this.onChange});

  @override
  State<_StepObjetivos> createState() => _StepObjetivosState();
}

class _StepObjetivosState extends State<_StepObjetivos> {
  final _descCtrl = TextEditingController();
  final _weeksCtrl = TextEditingController(text: '8');

  void _add() {
    final desc = _descCtrl.text.trim();
    final weeks = int.tryParse(_weeksCtrl.text.trim()) ?? 8;
    if (desc.isEmpty) return;
    widget.goals.add(GoalEntry(description: desc, weeks: weeks, createdAt: DateTime.now()));
    _descCtrl.clear();
    widget.onChange();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _weeksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHint('Máximo 2 objetivos. Deben ser medibles y con fecha límite.'),
        const SizedBox(height: 16),
        // Lista de objetivos añadidos
        ...widget.goals.map((g) => _GoalChip(
          goal: g,
          onDelete: () { widget.goals.remove(g); widget.onChange(); },
        )),
        if (widget.goals.length < 2) ...[
          _Input(controller: _descCtrl, hint: 'ej: Press banca +8kg en 10 semanas'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Plazo: ', style: TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 12)),
              SizedBox(
                width: 50,
                child: _Input(controller: _weeksCtrl, hint: '8', number: true),
              ),
              const Text(' semanas', style: TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _add,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FF88)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text('+ AÑADIR', style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 2)),
            ),
          ),
        ],
      ],
    );
  }
}

// ── STEP 2: Horario ───────────────────────────────────────────────────────────
class _StepHorario extends StatefulWidget {
  final List<ScheduleBlock> schedule;
  final VoidCallback onChange;

  const _StepHorario({required this.schedule, required this.onChange});

  @override
  State<_StepHorario> createState() => _StepHorarioState();
}

class _StepHorarioState extends State<_StepHorario> {
  String _day = 'lunes';
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _duration = 60;

  static const _days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  void _add() {
    widget.schedule.add(ScheduleBlock(
      day: _day,
      start: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      durationMin: _duration,
    ));
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHint('¿Cuándo puedes entrenar? Añade todos los bloques disponibles.'),
        const SizedBox(height: 16),
        ...widget.schedule.map((s) => _ScheduleChip(
          block: s,
          onDelete: () { widget.schedule.remove(s); widget.onChange(); },
        )),
        const SizedBox(height: 8),
        // Selector día
        DropdownButton<String>(
          value: _day,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
          underline: Container(height: 1, color: const Color(0xFF333333)),
          items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _day = v!),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              child: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 16),
              ),
            ),
            const SizedBox(width: 24),
            DropdownButton<int>(
              value: _duration,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              underline: Container(height: 1, color: const Color(0xFF333333)),
              items: [45, 60, 75, 90].map((d) => DropdownMenuItem(value: d, child: Text('${d}min'))).toList(),
              onChanged: (v) => setState(() => _duration = v!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _add,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00FF88)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text('+ AÑADIR BLOQUE', style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }
}

// ── STEP 3: Aversiones ────────────────────────────────────────────────────────
class _StepAversiones extends StatefulWidget {
  final List<AversionEntry> aversions;
  final VoidCallback onChange;

  const _StepAversiones({required this.aversions, required this.onChange});

  @override
  State<_StepAversiones> createState() => _StepAversionesState();
}

class _StepAversionesState extends State<_StepAversiones> {
  String? _selectedMachine;
  final _reasonCtrl = TextEditingController();

  void _add() {
    if (_selectedMachine == null) return;
    widget.aversions.add(AversionEntry(
      machineId: _selectedMachine!,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    ));
    _selectedMachine = null;
    _reasonCtrl.clear();
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHint('Opcional. Ejercicios o máquinas que evitas activamente.'),
        const SizedBox(height: 16),
        ...widget.aversions.map((a) {
          final name = AppConstants.machines.firstWhere((m) => m['id'] == a.machineId, orElse: () => {'name': a.machineId})['name']!;
          return _AversionChip(
            name: name,
            reason: a.reason,
            onDelete: () { widget.aversions.remove(a); widget.onChange(); },
          );
        }),
        DropdownButton<String>(
          value: _selectedMachine,
          hint: const Text('Selecciona máquina', style: TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 12)),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
          underline: Container(height: 1, color: const Color(0xFF333333)),
          isExpanded: true,
          items: AppConstants.machines
              .where((m) => !widget.aversions.any((a) => a.machineId == m['id']))
              .map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!)))
              .toList(),
          onChanged: (v) => setState(() => _selectedMachine = v),
        ),
        const SizedBox(height: 8),
        _Input(controller: _reasonCtrl, hint: 'Razón (opcional): dolor en hombro, falta de equipo...'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectedMachine != null ? _add : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: _selectedMachine != null ? const Color(0xFF00FF88) : const Color(0xFF333333)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text('+ AÑADIR', style: TextStyle(
              color: _selectedMachine != null ? const Color(0xFF00FF88) : const Color(0xFF333333),
              fontFamily: 'monospace', fontSize: 11, letterSpacing: 2,
            )),
          ),
        ),
      ],
    );
  }
}

// ── STEP 4: Máquinas disponibles ──────────────────────────────────────────────
class _StepMaquinas extends StatefulWidget {
  final List<String> selected;
  final VoidCallback onChange;

  const _StepMaquinas({required this.selected, required this.onChange});

  @override
  State<_StepMaquinas> createState() => _StepMaquinasState();
}

class _StepMaquinasState extends State<_StepMaquinas> {

  @override
  Widget build(BuildContext context) {
    // Agrupar por categoría
    final categories = <String, List<Map<String, String>>>{};
    for (final m in AppConstants.machines) {
      categories.putIfAbsent(m['category']!, () => []).add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHint('Marca las máquinas disponibles en tu gimnasio habitual.'),
        const SizedBox(height: 16),
        ...categories.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key.toUpperCase(),
              style: const TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            ...entry.value.map((m) {
              final isSelected = widget.selected.contains(m['id']);
              return GestureDetector(
                onTap: () {
                  if (isSelected) widget.selected.remove(m['id']);
                  else widget.selected.add(m['id']!);
                  setState(() {});
                  widget.onChange();
                },
                child: _SelectRow(label: m['name']!, selected: isSelected),
              );
            }),
            const SizedBox(height: 12),
          ],
        )),
      ],
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────────────────

class _StepHint extends StatelessWidget {
  final String text;
  const _StepHint(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 11, height: 1.5),
  );
}

class _SelectRow extends StatelessWidget {
  final String label;
  final bool selected;
  const _SelectRow({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF0D2D1A) : const Color(0xFF0A0A0A),
      border: Border.all(color: selected ? const Color(0xFF00FF88) : const Color(0xFF1A1A1A)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFF00FF88) : const Color(0xFF888888),
          fontFamily: 'monospace', fontSize: 12,
        ))),
        if (selected) const Icon(Icons.check, color: Color(0xFF00FF88), size: 14),
      ],
    ),
  );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool number;
  const _Input({required this.controller, required this.hint, this.number = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 12),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF222222))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF88))),
    ),
  );
}

class _GoalChip extends StatelessWidget {
  final GoalEntry goal;
  final VoidCallback onDelete;
  const _GoalChip({required this.goal, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF00FF88)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
            Text('${goal.weeks} semanas', style: const TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 11)),
          ],
        )),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close, color: Color(0xFF444444), size: 16)),
      ],
    ),
  );
}

class _ScheduleChip extends StatelessWidget {
  final ScheduleBlock block;
  final VoidCallback onDelete;
  const _ScheduleChip({required this.block, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF00FF88)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      children: [
        Text('${block.day}  ${block.start}  ${block.durationMin}min',
          style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 12)),
        const Spacer(),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close, color: Color(0xFF444444), size: 16)),
      ],
    ),
  );
}

class _AversionChip extends StatelessWidget {
  final String name;
  final String? reason;
  final VoidCallback onDelete;
  const _AversionChip({required this.name, this.reason, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF333333)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
            if (reason != null)
              Text(reason!, style: const TextStyle(color: Color(0xFF555555), fontFamily: 'monospace', fontSize: 11)),
          ],
        )),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close, color: Color(0xFF444444), size: 16)),
      ],
    ),
  );
}
