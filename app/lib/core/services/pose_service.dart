import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/user_profile.dart';

class PoseService {
  static final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  // ── Detecta pose en imagen y devuelve landmarks ───────────────────────────
  static Future<List<PoseLandmark>?> detectFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final poses = await _detector.processImage(inputImage);
    if (poses.isEmpty) return null;
    return poses.first.landmarks.values.toList();
  }

  static Future<List<PoseLandmark>?> detectFromBytes(Uint8List bytes, {
    required int width,
    required int height,
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: ui.Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: width * 4,
      ),
    );
    final poses = await _detector.processImage(inputImage);
    if (poses.isEmpty) return null;
    return poses.first.landmarks.values.toList();
  }

  // ── Calcula vector antropométrico desde las 3 fotos de referencia ─────────
  static AnthropometricData? computeAnthropometric({
    required List<PoseLandmark> neutralLandmarks,
    required List<PoseLandmark> squatLandmarks,
    required List<PoseLandmark> overheadLandmarks,
    required double scaleFactorPixelsPerCm, // de la botella de referencia
  }) {
    try {
      // Landmarks clave en postura neutral
      final leftHip    = _get(neutralLandmarks, PoseLandmarkType.leftHip);
      final rightHip   = _get(neutralLandmarks, PoseLandmarkType.rightHip);
      final leftKnee   = _get(neutralLandmarks, PoseLandmarkType.leftKnee);
      final rightKnee  = _get(neutralLandmarks, PoseLandmarkType.rightKnee);
      final leftAnkle  = _get(neutralLandmarks, PoseLandmarkType.leftAnkle);
      final rightAnkle = _get(neutralLandmarks, PoseLandmarkType.rightAnkle);
      final leftShoulder  = _get(neutralLandmarks, PoseLandmarkType.leftShoulder);
      final rightShoulder = _get(neutralLandmarks, PoseLandmarkType.rightShoulder);
      final nose = _get(neutralLandmarks, PoseLandmarkType.nose);

      if ([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle,
           leftShoulder, rightShoulder, nose].any((l) => l == null)) return null;

      // Longitudes segmentarias (promedio izq+der)
      final femurL = _dist(leftHip!, leftKnee!) / scaleFactorPixelsPerCm;
      final femurR = _dist(rightHip!, rightKnee!) / scaleFactorPixelsPerCm;
      final tibiaL = _dist(leftKnee, leftAnkle!) / scaleFactorPixelsPerCm;
      final tibiaR = _dist(rightKnee, rightAnkle!) / scaleFactorPixelsPerCm;
      final femur = (femurL + femurR) / 2;
      final tibia = (tibiaL + tibiaR) / 2;

      final hipY = ((leftHip.y + rightHip.y) / 2);
      final shoulderY = ((leftShoulder!.y + rightShoulder!.y) / 2);
      final torso = (hipY - shoulderY).abs() / scaleFactorPixelsPerCm;
      final totalHeight = (nose!.y - ((leftAnkle.y + rightAnkle.y) / 2)).abs() / scaleFactorPixelsPerCm;

      // Ángulo de pelvis (inclinación del eje cadera en postura neutral)
      final hipAngle = _angleDeg(leftHip, rightHip);

      // ROM desde foto sentadilla (flexión rodilla)
      double kneeFlexion = 0;
      final sqLeftKnee = _get(squatLandmarks, PoseLandmarkType.leftKnee);
      final sqLeftHip  = _get(squatLandmarks, PoseLandmarkType.leftHip);
      final sqLeftAnkle = _get(squatLandmarks, PoseLandmarkType.leftAnkle);
      if (sqLeftKnee != null && sqLeftHip != null && sqLeftAnkle != null) {
        kneeFlexion = _angle3Points(sqLeftHip, sqLeftKnee, sqLeftAnkle);
      }

      // ROM desde foto overhead (flexión hombro)
      double shoulderFlexion = 0;
      final ovLeftShoulder = _get(overheadLandmarks, PoseLandmarkType.leftShoulder);
      final ovLeftElbow    = _get(overheadLandmarks, PoseLandmarkType.leftElbow);
      final ovLeftHip2     = _get(overheadLandmarks, PoseLandmarkType.leftHip);
      if (ovLeftShoulder != null && ovLeftElbow != null && ovLeftHip2 != null) {
        shoulderFlexion = _angle3Points(ovLeftHip2, ovLeftShoulder, ovLeftElbow);
      }

      // Puntos de contorno (simplificados: bounding box del cuerpo en puntos clave)
      final contourPoints = _extractContour(neutralLandmarks, scaleFactorPixelsPerCm);

      return AnthropometricData(
        femurTibiaRatio: tibia > 0 ? femur / tibia : 1.0,
        torsoHeightRatio: totalHeight > 0 ? torso / totalHeight : 0.5,
        pelvisAngle: hipAngle,
        rom: {
          'knee_flexion': [0, kneeFlexion],
          'shoulder_flexion': [0, shoulderFlexion],
        },
        landmarks: neutralLandmarks
            .map((l) => {
                  'type': l.type.name,
                  'x': l.x,
                  'y': l.y,
                  'z': l.z,
                  'likelihood': l.likelihood,
                })
            .toList(),
        contourPoints: contourPoints,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Valida que una pose tiene suficiente confianza para guardar ───────────
  static bool isValidPose(List<PoseLandmark> landmarks, {double minLikelihood = 0.6}) {
    final keyPoints = [
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    ];

    return keyPoints.every((type) {
      final lm = _get(landmarks, type);
      return lm != null && lm.likelihood >= minLikelihood;
    });
  }

  // ── Utilidades privadas ───────────────────────────────────────────────────
  static PoseLandmark? _get(List<PoseLandmark> list, PoseLandmarkType type) {
    try {
      return list.firstWhere((l) => l.type == type);
    } catch (_) {
      return null;
    }
  }

  static double _dist(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  // Ángulo de la línea A→B respecto al eje horizontal, en grados
  static double _angleDeg(PoseLandmark a, PoseLandmark b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    if (dx == 0 && dy == 0) return 0;
    return math.atan2(dy, dx) * (180 / math.pi);
  }

  static double _angle3Points(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Ángulo en B formado por A-B-C
    final abx = a.x - b.x;
    final aby = a.y - b.y;
    final cbx = c.x - b.x;
    final cby = c.y - b.y;
    final dot = abx * cbx + aby * cby;
    final magAB = math.sqrt(abx * abx + aby * aby);
    final magCB = math.sqrt(cbx * cbx + cby * cby);
    if (magAB == 0 || magCB == 0) return 0;
    final cosAngle = dot / (magAB * magCB);
    return math.acos(cosAngle.clamp(-1.0, 1.0)) * (180 / math.pi);
  }

  static List<Map<String, double>> _extractContour(
    List<PoseLandmark> landmarks,
    double scale,
  ) {
    // Extrae puntos de contorno aproximado del cuerpo desde landmarks
    final bodyTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightShoulder,
    ];

    return bodyTypes
        .map((t) => _get(landmarks, t))
        .where((l) => l != null)
        .map((l) => {'x': l!.x / scale, 'y': l.y / scale})
        .toList();
  }

  static void dispose() => _detector.close();
}
