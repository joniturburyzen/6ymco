class AnthropometricData {
  final double femurTibiaRatio;
  final double torsoHeightRatio;
  final double pelvisAngle;
  final Map<String, List<double>> rom; // e.g. {"knee_flexion": [0, 115]}
  final List<Map<String, dynamic>> landmarks; // landmarks neutrales
  final List<Map<String, double>> contourPoints; // silueta corporal

  AnthropometricData({
    required this.femurTibiaRatio,
    required this.torsoHeightRatio,
    required this.pelvisAngle,
    required this.rom,
    required this.landmarks,
    required this.contourPoints,
  });

  Map<String, dynamic> toMap() => {
    'femur_tibia_ratio': femurTibiaRatio,
    'torso_height_ratio': torsoHeightRatio,
    'pelvis_angle': pelvisAngle,
    'rom': rom,
    'landmarks': landmarks,
    'contour_points': contourPoints,
  };

  factory AnthropometricData.fromMap(Map<String, dynamic> m) => AnthropometricData(
    femurTibiaRatio: (m['femur_tibia_ratio'] ?? 1.0).toDouble(),
    torsoHeightRatio: (m['torso_height_ratio'] ?? 0.5).toDouble(),
    pelvisAngle: (m['pelvis_angle'] ?? 0.0).toDouble(),
    rom: Map<String, List<double>>.from(
      (m['rom'] ?? {}).map((k, v) => MapEntry(k, List<double>.from(v))),
    ),
    landmarks: List<Map<String, dynamic>>.from(m['landmarks'] ?? []),
    contourPoints: List<Map<String, double>>.from(
      (m['contour_points'] ?? []).map((p) => Map<String, double>.from(p)),
    ),
  );
}

class GoalEntry {
  final String description;
  final int weeks;
  final DateTime createdAt;

  GoalEntry({
    required this.description,
    required this.weeks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'description': description,
    'weeks': weeks,
    'created_at': createdAt.toIso8601String(),
  };

  factory GoalEntry.fromMap(Map<String, dynamic> m) => GoalEntry(
    description: m['description'] ?? '',
    weeks: m['weeks'] ?? 8,
    createdAt: DateTime.parse(m['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

class AversionEntry {
  final String machineId;
  final String? reason;

  AversionEntry({required this.machineId, this.reason});

  Map<String, dynamic> toMap() => {'machine_id': machineId, 'reason': reason};

  factory AversionEntry.fromMap(Map<String, dynamic> m) =>
      AversionEntry(machineId: m['machine_id'] ?? '', reason: m['reason']);
}

class ScheduleBlock {
  final String day; // "lunes", "martes", etc.
  final String start; // "18:00"
  final int durationMin;

  ScheduleBlock({required this.day, required this.start, required this.durationMin});

  Map<String, dynamic> toMap() => {'day': day, 'start': start, 'duration_min': durationMin};

  factory ScheduleBlock.fromMap(Map<String, dynamic> m) => ScheduleBlock(
    day: m['day'] ?? '',
    start: m['start'] ?? '08:00',
    durationMin: m['duration_min'] ?? 60,
  );
}

class UserProfile {
  final String uid;
  final List<String> injuries;
  final List<GoalEntry> goals;
  final List<AversionEntry> aversions;
  final List<ScheduleBlock> schedule;
  final List<String> availableMachines;
  AnthropometricData? anthropometric;
  final bool fichaComplete;
  final bool arComplete;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    this.injuries = const [],
    this.goals = const [],
    this.aversions = const [],
    this.schedule = const [],
    this.availableMachines = const [],
    this.anthropometric,
    this.fichaComplete = false,
    this.arComplete = false,
    this.createdAt,
  });

  bool get isComplete => fichaComplete && arComplete;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'injuries': injuries,
    'goals': goals.map((g) => g.toMap()).toList(),
    'aversions': aversions.map((a) => a.toMap()).toList(),
    'schedule': schedule.map((s) => s.toMap()).toList(),
    'available_machines': availableMachines,
    'anthropometric': anthropometric?.toMap(),
    'ficha_complete': fichaComplete,
    'ar_complete': arComplete,
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] ?? '',
    injuries: List<String>.from(m['injuries'] ?? []),
    goals: (m['goals'] as List? ?? []).map((g) => GoalEntry.fromMap(g)).toList(),
    aversions: (m['aversions'] as List? ?? []).map((a) => AversionEntry.fromMap(a)).toList(),
    schedule: (m['schedule'] as List? ?? []).map((s) => ScheduleBlock.fromMap(s)).toList(),
    availableMachines: List<String>.from(m['available_machines'] ?? []),
    anthropometric: m['anthropometric'] != null
        ? AnthropometricData.fromMap(m['anthropometric'])
        : null,
    fichaComplete: m['ficha_complete'] ?? false,
    arComplete: m['ar_complete'] ?? false,
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : null,
  );

  UserProfile copyWith({
    List<String>? injuries,
    List<GoalEntry>? goals,
    List<AversionEntry>? aversions,
    List<ScheduleBlock>? schedule,
    List<String>? availableMachines,
    AnthropometricData? anthropometric,
    bool? fichaComplete,
    bool? arComplete,
  }) =>
      UserProfile(
        uid: uid,
        injuries: injuries ?? this.injuries,
        goals: goals ?? this.goals,
        aversions: aversions ?? this.aversions,
        schedule: schedule ?? this.schedule,
        availableMachines: availableMachines ?? this.availableMachines,
        anthropometric: anthropometric ?? this.anthropometric,
        fichaComplete: fichaComplete ?? this.fichaComplete,
        arComplete: arComplete ?? this.arComplete,
        createdAt: createdAt,
      );
}
