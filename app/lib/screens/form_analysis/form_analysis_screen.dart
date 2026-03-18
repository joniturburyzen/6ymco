// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/worker_service.dart';

bool _formCameraRegistered = false;

class FormAnalysisScreen extends StatefulWidget {
  final String machineId;
  const FormAnalysisScreen({super.key, required this.machineId});

  @override
  State<FormAnalysisScreen> createState() => _FormAnalysisScreenState();
}

class _FormAnalysisScreenState extends State<FormAnalysisScreen> {
  _Phase _phase = _Phase.instructions;
  Map<String, dynamic>? _result;
  String? _error;
  StreamSubscription<html.MessageEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _registerView();
    _sub = html.window.onMessage.listen(_onMessage);
  }

  void _registerView() {
    if (_formCameraRegistered) return;
    _formCameraRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      'form-analysis-camera',
      (int id) => html.IFrameElement()
        ..src = 'form_analysis.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  void _onMessage(html.MessageEvent event) {
    if (event.data is! String) return;
    try {
      final data = jsonDecode(event.data as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'frames_ready':
          _handleFrames(List<String>.from(data['frames'] as List));
        case 'form_close':
          if (mounted) context.pop();
      }
    } catch (_) {}
  }

  Future<void> _handleFrames(List<String> frames) async {
    setState(() { _phase = _Phase.analyzing; _error = null; });
    try {
      final profile = await FirebaseService.loadProfile();
      if (!mounted) return;
      if (profile?.anthropometric == null) {
        setState(() {
          _error = 'Completa el ANÁLISIS AR antes de analizar tu forma.';
          _phase = _Phase.instructions;
        });
        return;
      }
      final res = await WorkerService.analyzeForm(
        framesBase64: frames,
        exerciseId: widget.machineId,
        mesh: profile!.anthropometric!,
        injuries: profile.injuries,
      );
      if (!mounted) return;
      setState(() { _result = res; _phase = _Phase.result; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _phase = _Phase.instructions; });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.instructions => _InstructionsView(
              error: _error,
              onReady: () => setState(() { _phase = _Phase.camera; _error = null; }),
            ),
          _Phase.camera => const HtmlElementView(viewType: 'form-analysis-camera'),
          _Phase.analyzing => const _AnalyzingView(),
          _Phase.result => _ResultView(result: _result!),
        },
      ),
    );
  }
}

enum _Phase { instructions, camera, analyzing, result }

// ── Instrucciones ─────────────────────────────────────────────────────────────
class _InstructionsView extends StatelessWidget {
  final String? error;
  final VoidCallback onReady;
  const _InstructionsView({required this.onReady, this.error});

  static const _tips = [
    'Distancia: 2–3 metros de la cámara',
    'Luz: preferiblemente natural o frontal',
    'Ropa ajustada (facilita la detección)',
    'Fondo: liso si es posible',
    'Pide ayuda o apoya el teléfono en una superficie estable',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ANÁLISIS DE FORMA',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.close, color: Color(0xFF444444), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ..._tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('— ', style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace')),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontSize: 11),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onReady,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'ABRIR CÁMARA',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analizando ────────────────────────────────────────────────────────────────
class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF00FF88), strokeWidth: 1.5),
          SizedBox(height: 24),
          Text(
            'ANALIZANDO FORMA...',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Qwen analiza tu biomecánica personalizada',
            style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Resultado ─────────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final score       = result['score'] as int? ?? 0;
    final errors      = (result['errors'] as List? ?? []).cast<Map<String, dynamic>>();
    final corrections = List<String>.from(result['corrections'] ?? []);
    final positives   = List<String>.from(result['positives'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF444444), size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('SCORE ', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 12)),
              Text(
                '$score',
                style: const TextStyle(
                  color: Color(0xFF00FF88), fontFamily: 'monospace',
                  fontSize: 42, fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('/100', style: TextStyle(color: Color(0xFF444444), fontFamily: 'monospace', fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (errors.isNotEmpty) ...[
            const Text('ERRORES', style: TextStyle(color: Color(0xFFFF4444), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
            const SizedBox(height: 12),
            ...errors.map((e) {
              final sev = e['severity'] as String? ?? '';
              final sevColor = sev == 'alta' ? const Color(0xFFFF4444)
                  : sev == 'media' ? const Color(0xFFFF8844)
                  : const Color(0xFF888888);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('[$sev] ', style: TextStyle(color: sevColor, fontFamily: 'monospace', fontSize: 10)),
                        Expanded(
                          child: Text(
                            e['type'] as String? ?? '',
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e['detail'] as String? ?? '',
                      style: const TextStyle(color: Color(0xFF666666), fontFamily: 'monospace', fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          if (corrections.isNotEmpty) ...[
            const Text('CORRECCIONES', style: TextStyle(color: Color(0xFFFF8844), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
            const SizedBox(height: 12),
            ...corrections.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('— $c', style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 12, height: 1.5)),
            )),
            const SizedBox(height: 24),
          ],

          if (positives.isNotEmpty) ...[
            const Text('CORRECTO', style: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
            const SizedBox(height: 12),
            ...positives.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('— $p', style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 12, height: 1.5)),
            )),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                side: const BorderSide(color: Color(0xFF222222)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'VOLVER',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
