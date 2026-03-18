class AppConstants {
  static const String workerUrl = 'https://wild-wood-8f96.joniturbu.workers.dev';

  // Máquinas del catálogo
  static const List<Map<String, String>> machines = [
    // CARDIO
    {'id': 'cinta_correr',        'name': 'Cinta de correr',              'category': 'cardio'},
    {'id': 'bicicleta_estatica',  'name': 'Bicicleta estática',           'category': 'cardio'},
    {'id': 'eliptica',            'name': 'Elíptica',                     'category': 'cardio'},
    {'id': 'remo_ergometro',      'name': 'Remo ergómetro',               'category': 'cardio'},
    {'id': 'escaladora',          'name': 'Escaladora',                   'category': 'cardio'},
    // PIERNAS
    {'id': 'prensa_piernas',      'name': 'Prensa de piernas',            'category': 'piernas'},
    {'id': 'extension_cuadriceps','name': 'Extensión de cuádriceps',      'category': 'piernas'},
    {'id': 'curl_isq_tumbado',    'name': 'Curl isquiotibiales tumbado',  'category': 'piernas'},
    {'id': 'curl_isq_sentado',    'name': 'Curl isquiotibiales sentado',  'category': 'piernas'},
    {'id': 'abductor',            'name': 'Abductor',                     'category': 'piernas'},
    {'id': 'aductor',             'name': 'Aductor',                      'category': 'piernas'},
    {'id': 'pantorrillas_pie',    'name': 'Pantorrillas de pie',          'category': 'piernas'},
    {'id': 'hack_squat',          'name': 'Hack Squat',                   'category': 'piernas'},
    // GLÚTEO
    {'id': 'hip_thrust',          'name': 'Hip Thrust máquina',           'category': 'gluteo'},
    {'id': 'patada_trasera',      'name': 'Patada trasera en cable',      'category': 'gluteo'},
    // ESPALDA
    {'id': 'jalon_pecho',         'name': 'Jalón al pecho',               'category': 'espalda'},
    {'id': 'remo_polea_baja',     'name': 'Remo en polea baja',           'category': 'espalda'},
    {'id': 'remo_maquina',        'name': 'Remo en máquina',              'category': 'espalda'},
    {'id': 'pullover_maquina',    'name': 'Pull-over máquina',            'category': 'espalda'},
    // PECHO
    {'id': 'press_pecho',         'name': 'Press de pecho máquina',       'category': 'pecho'},
    {'id': 'press_inclinado',     'name': 'Press inclinado máquina',      'category': 'pecho'},
    {'id': 'pec_deck',            'name': 'Pec Deck / Aperturas',         'category': 'pecho'},
    // HOMBROS
    {'id': 'press_hombros',       'name': 'Press de hombros máquina',     'category': 'hombros'},
    {'id': 'elevaciones_lat',     'name': 'Elevaciones laterales máquina','category': 'hombros'},
    // BRAZOS
    {'id': 'curl_biceps',         'name': 'Curl de bíceps máquina',       'category': 'brazos'},
    {'id': 'extension_triceps',   'name': 'Extensión de tríceps polea',   'category': 'brazos'},
    {'id': 'fondos_asistidos',    'name': 'Fondos asistidos',             'category': 'brazos'},
    // CORE
    {'id': 'crunch_maquina',      'name': 'Crunch abdominal máquina',     'category': 'core'},
    {'id': 'rotacion_torso',      'name': 'Rotación de torso',            'category': 'core'},
    // MULTIUSOS
    {'id': 'smith_machine',       'name': 'Smith Machine',                'category': 'multiusos'},
    {'id': 'cable_crossover',     'name': 'Polea doble / Cable crossover','category': 'multiusos'},
  ];

  static const List<String> injuryOptions = [
    'Hernia discal L4-L5',
    'Hernia discal L5-S1',
    'Tendinitis patelar',
    'Tendinitis rotuliana',
    'Síndrome del manguito rotador',
    'Epicondilitis lateral (codo de tenista)',
    'Epicondilitis medial (codo de golfista)',
    'Condromalacia rotuliana',
    'Fascitis plantar',
    'Estenosis lumbar',
    'Hernia inguinal (operada)',
    'Hipertensión controlada',
    'Escoliosis',
    'Ninguna',
    'Prefiero no especificar',
  ];

  static const List<String> goalOptions = [
    'Aumentar fuerza',
    'Hipertrofia muscular',
    'Pérdida de grasa',
    'Resistencia cardiovascular',
    'Rehabilitación / recuperación',
    'Movilidad y flexibilidad',
    'Rendimiento deportivo',
  ];
}
