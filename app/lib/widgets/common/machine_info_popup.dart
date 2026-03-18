import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/worker_service.dart';

class MachineInfoPopup extends StatefulWidget {
  const MachineInfoPopup({super.key});

  @override
  State<MachineInfoPopup> createState() => _MachineInfoPopupState();
}

class _MachineInfoPopupState extends State<MachineInfoPopup> {
  _View _view = _View.browse;
  List<String> _injuries = [];
  String _search = '';
  Map<String, dynamic>? _info;
  String? _loadingName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInjuries();
  }

  Future<void> _loadInjuries() async {
    final profile = await FirebaseService.loadProfile();
    if (mounted && profile != null) {
      setState(() => _injuries = profile.injuries);
    }
  }

  Future<void> _fetchInfo(String id, String name) async {
    setState(() { _view = _View.loading; _loadingName = name; _error = null; });
    try {
      final info = await WorkerService.machineInfo(
        machineId: id,
        injuries: _injuries,
      );
      if (!mounted) return;
      setState(() { _info = info; _view = _View.info; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _view = _View.browse; });
    }
  }

  static const _catLabels = {
    'cardio':    'CARDIO',
    'piernas':   'PIERNAS',
    'gluteo':    'GLÚTEO',
    'espalda':   'ESPALDA',
    'pecho':     'PECHO',
    'hombros':   'HOMBROS',
    'brazos':    'BRAZOS',
    'core':      'CORE',
    'multiusos': 'MULTIUSOS',
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
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.82,
        child: switch (_view) {
          _View.browse => _BrowseView(
              grouped: _grouped(),
              catLabels: _catLabels,
              search: _search,
              error: _error,
              onSearch: (v) => setState(() => _search = v),
              onSelect: _fetchInfo,
              onClose: () => Navigator.pop(context),
            ),
          _View.loading => _LoadingView(name: _loadingName ?? ''),
          _View.info    => _InfoView(
              info: _info!,
              hasInjuries: _injuries.isNotEmpty,
              onBack: () => setState(() { _view = _View.browse; _info = null; }),
              onClose: () => Navigator.pop(context),
            ),
        },
      ),
    );
  }
}

enum _View { browse, loading, info }

// ── Browse ─────────────────────────────────────────────────────────────────────
class _BrowseView extends StatelessWidget {
  final Map<String, List<Map<String, String>>> grouped;
  final Map<String, String> catLabels;
  final String search;
  final String? error;
  final ValueChanged<String> onSearch;
  final void Function(String id, String name) onSelect;
  final VoidCallback onClose;

  const _BrowseView({
    required this.grouped,
    required this.catLabels,
    required this.search,
    required this.error,
    required this.onSearch,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(
            children: [
              const Text(
                'INFO MÁQUINA',
                style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 12, letterSpacing: 4),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
              ),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: TextField(
            onChanged: onSearch,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Buscar máquina...',
              hintStyle: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF333333), size: 16),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF222222))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF88))),
            ),
          ),
        ),

        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(error!, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontSize: 11)),
          ),

        const SizedBox(height: 8),
        const Divider(color: Color(0xFF1A1A1A), height: 1),

        // List
        Expanded(
          child: grouped.isEmpty
              ? const Center(
                  child: Text('Sin resultados', style: TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 12)),
                )
              : ListView(
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                        child: Text(
                          catLabels[entry.key] ?? entry.key.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF333333), fontFamily: 'monospace', fontSize: 10, letterSpacing: 3),
                        ),
                      ),
                      for (final m in entry.value)
                        InkWell(
                          onTap: () => onSelect(m['id']!, m['name']!),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m['name']!,
                                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 16),
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
    );
  }
}

// ── Loading ────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final String name;
  const _LoadingView({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00FF88), strokeWidth: 1.5),
          const SizedBox(height: 24),
          Text(
            name.toUpperCase(),
            style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3),
          ),
          const SizedBox(height: 8),
          const Text('Consultando a Qwen...', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Info ───────────────────────────────────────────────────────────────────────
class _InfoView extends StatelessWidget {
  final Map<String, dynamic> info;
  final bool hasInjuries;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _InfoView({
    required this.info,
    required this.hasInjuries,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name          = info['name'] as String? ?? '';
    final primary       = List<String>.from(info['muscles_primary'] ?? []);
    final secondary     = List<String>.from(info['muscles_secondary'] ?? []);
    final setup         = List<String>.from(info['setup_steps'] ?? []);
    final tips          = List<String>.from(info['tips'] ?? []);
    final contra        = List<String>.from(info['contraindications'] ?? []);
    final adaptations   = List<String>.from(info['injury_adaptations'] ?? []);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF444444), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF1A1A1A), height: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muscles
                if (primary.isNotEmpty) ...[
                  _Label('MÚSCULOS PRINCIPALES'),
                  const SizedBox(height: 8),
                  _Chips(items: primary, color: const Color(0xFF00FF88)),
                  const SizedBox(height: 16),
                ],
                if (secondary.isNotEmpty) ...[
                  _Label('MÚSCULOS SECUNDARIOS'),
                  const SizedBox(height: 8),
                  _Chips(items: secondary, color: const Color(0xFF444444)),
                  const SizedBox(height: 24),
                ],

                // Setup
                if (setup.isNotEmpty) ...[
                  _Label('AJUSTE EN MÁQUINA'),
                  const SizedBox(height: 10),
                  ...setup.asMap().entries.map((e) => _Numbered(index: e.key + 1, text: e.value)),
                  const SizedBox(height: 24),
                ],

                // Tips
                if (tips.isNotEmpty) ...[
                  _Label('CONSEJOS TÉCNICOS'),
                  const SizedBox(height: 10),
                  ..._bullets(tips, const Color(0xFF888888)),
                  const SizedBox(height: 24),
                ],

                // Contraindications
                if (contra.isNotEmpty) ...[
                  _Label('CONTRAINDICACIONES', color: const Color(0xFF555555)),
                  const SizedBox(height: 10),
                  ..._bullets(contra, const Color(0xFF555555)),
                  const SizedBox(height: 24),
                ],

                // Injury adaptations (only shown if user has injuries)
                if (hasInjuries && adaptations.isNotEmpty) ...[
                  _Label('ADAPTACIONES PARA TI', color: const Color(0xFFFF8844)),
                  const SizedBox(height: 10),
                  ..._bullets(adaptations, const Color(0xFFAA6633)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<Widget> _bullets(List<String> items, Color color) => items
      .map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('— ', style: TextStyle(color: color, fontFamily: 'monospace')),
                Expanded(child: Text(t, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12, height: 1.5))),
              ],
            ),
          ))
      .toList();
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, {this.color = const Color(0xFF444444)});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10, letterSpacing: 3),
      );
}

class _Chips extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _Chips({required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(t, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10)),
            )).toList(),
      );
}

class _Numbered extends StatelessWidget {
  final int index;
  final String text;
  const _Numbered({required this.index, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$index.',
                style: const TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
}
