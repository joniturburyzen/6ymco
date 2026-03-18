// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/user_profile.dart';

bool _arViewRegistered = false;

class ARAnalysisPopup extends StatefulWidget {
  const ARAnalysisPopup({super.key});

  @override
  State<ARAnalysisPopup> createState() => _ARAnalysisPopupState();
}

class _ARAnalysisPopupState extends State<ARAnalysisPopup> {
  StreamSubscription<html.MessageEvent>? _sub;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _registerView();
    _sub = html.window.onMessage.listen(_onMessage);
  }

  void _registerView() {
    if (_arViewRegistered) return;
    _arViewRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      'ar-analysis',
      (int id) => html.IFrameElement()
        ..src = 'ar_analysis.html'
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
        case 'ar_result':
          _handleResult(data['mesh'] as Map<String, dynamic>);
        case 'ar_close':
          if (mounted) Navigator.pop(context, false);
        case 'ar_error':
          if (mounted) setState(() => _error = data['error'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _handleResult(Map<String, dynamic> meshMap) async {
    setState(() => _saving = true);
    try {
      final mesh = AnthropometricData.fromMap(meshMap);
      final profile = await FirebaseService.loadProfile();
      if (profile == null || !mounted) return;
      await FirebaseService.saveProfile(
        profile.copyWith(anthropometric: mesh, arComplete: true),
      );
      await FirebaseService.saveWeeklyMesh(mesh);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Stack(
        children: [
          const HtmlElementView(viewType: 'ar-analysis'),
          if (_saving)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00FF88), strokeWidth: 1.5),
                  SizedBox(height: 16),
                  Text(
                    'GUARDANDO MESH...',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0000),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
