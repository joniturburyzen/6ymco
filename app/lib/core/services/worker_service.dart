import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../../models/user_profile.dart';
import '../../models/workout_plan.dart';

class WorkerService {
  static const _base = AppConstants.workerUrl;

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Worker error ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Genera plan de entrenamiento ──────────────────────────────────────────
  static Future<WorkoutPlan> generatePlan(UserProfile profile) async {
    final data = await _post('/generate-plan', {'profile': profile.toMap()});
    final planMap = data['plan'] as Map<String, dynamic>;
    return WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weeks: planMap['weeks'] ?? 8,
      days: (planMap['days'] as List).map((d) => DayPlan.fromMap(d)).toList(),
      createdAt: DateTime.now(),
    );
  }

  // ── Analiza forma del ejercicio desde frames ───────────────────────────────
  static Future<Map<String, dynamic>> analyzeForm({
    required List<String> framesBase64,
    required String exerciseId,
    required AnthropometricData mesh,
    required List<String> injuries,
  }) async {
    return _post('/analyze-form', {
      'frames': framesBase64,
      'exercise': exerciseId,
      'user_mesh': mesh.toMap(),
      'injuries': injuries,
    });
  }

  // ── Info de máquina ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> machineInfo({
    required String machineId,
    List<String> injuries = const [],
  }) async {
    return _post('/machine-info', {
      'machine': machineId,
      'user_injuries': injuries,
    });
  }

  // ── Chat con Qwen (personaje) ─────────────────────────────────────────────
  static Future<String> chat({
    required String message,
    Map<String, dynamic> context = const {},
  }) async {
    final data = await _post('/chat', {
      'message': message,
      'context': context,
    });
    return data['response'] as String? ?? '';
  }
}
