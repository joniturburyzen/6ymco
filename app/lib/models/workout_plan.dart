class ExerciseEntry {
  final String machineId;
  final int sets;
  final String reps;
  final String tempo;
  final int restSec;
  final String? machineSetup;
  final String? notes;
  bool completed;

  ExerciseEntry({
    required this.machineId,
    required this.sets,
    required this.reps,
    required this.tempo,
    required this.restSec,
    this.machineSetup,
    this.notes,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
    'machine_id': machineId,
    'sets': sets,
    'reps': reps,
    'tempo': tempo,
    'rest_sec': restSec,
    'machine_setup': machineSetup,
    'notes': notes,
    'completed': completed,
  };

  factory ExerciseEntry.fromMap(Map<String, dynamic> m) => ExerciseEntry(
    machineId: m['machine'] ?? m['machine_id'] ?? '',
    sets: m['sets'] ?? 3,
    reps: m['reps']?.toString() ?? '10',
    tempo: m['tempo'] ?? '3-0-1',
    restSec: m['rest_sec'] ?? 90,
    machineSetup: m['machine_setup'],
    notes: m['notes'],
    completed: m['completed'] ?? false,
  );
}

class DayPlan {
  final String day;
  final String focus;
  final int durationMin;
  final List<ExerciseEntry> exercises;

  DayPlan({
    required this.day,
    required this.focus,
    required this.durationMin,
    required this.exercises,
  });

  Map<String, dynamic> toMap() => {
    'day': day,
    'focus': focus,
    'duration_min': durationMin,
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };

  factory DayPlan.fromMap(Map<String, dynamic> m) => DayPlan(
    day: m['day'] ?? '',
    focus: m['focus'] ?? '',
    durationMin: m['duration_min'] ?? 60,
    exercises: (m['exercises'] as List? ?? [])
        .map((e) => ExerciseEntry.fromMap(e))
        .toList(),
  );
}

class WorkoutPlan {
  final String id;
  final int weeks;
  final List<DayPlan> days;
  final DateTime createdAt;

  WorkoutPlan({
    required this.id,
    required this.weeks,
    required this.days,
    required this.createdAt,
  });

  // Devuelve el plan del día de la semana actual
  DayPlan? todayPlan() {
    const weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final today = weekdays[DateTime.now().weekday - 1];
    try {
      return days.firstWhere((d) => d.day.toLowerCase() == today);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'weeks': weeks,
    'days': days.map((d) => d.toMap()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  factory WorkoutPlan.fromMap(Map<String, dynamic> m) => WorkoutPlan(
    id: m['id'] ?? '',
    weeks: m['weeks'] ?? 8,
    days: (m['days'] as List? ?? []).map((d) => DayPlan.fromMap(d)).toList(),
    createdAt: DateTime.parse(m['created_at'] ?? DateTime.now().toIso8601String()),
  );
}
