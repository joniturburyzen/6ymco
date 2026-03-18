// 6YM.C0 — Cloudflare Worker
// URL: wild-wood-8f96.joniturbu.workers.dev
// Secrets: QWEN_KEY (NVIDIA NIM)

const NIM_BASE = 'https://integrate.api.nvidia.com/v1';
const QWEN_VLM  = 'qwen/qwen3.5-397b-a17b';   // vision + texto
const QWEN_TEXT = 'qwen/qwen3.5-397b-a17b';   // mismo modelo, prompts solo texto

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ─── ROUTER ──────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });

    const url = new URL(request.url);

    try {
      let body;
      switch (url.pathname) {
        case '/generate-plan':
          body = await request.json();
          return respond(await generatePlan(body, env));

        case '/analyze-form':
          body = await request.json();
          return respond(await analyzeForm(body, env));

        case '/machine-info':
          body = await request.json();
          return respond(await machineInfo(body, env));

        case '/chat':
          body = await request.json();
          return respond(await chat(body, env));

        default:
          return new Response('Not found', { status: 404, headers: CORS });
      }
    } catch (err) {
      return respond({ error: err.message }, 500);
    }
  }
};

// ─── HELPERS ─────────────────────────────────────────────────────────────────

function respond(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

async function callQwen(messages, env, opts = {}) {
  const res = await fetch(`${NIM_BASE}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.QWEN_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: opts.vision ? QWEN_VLM : QWEN_TEXT,
      messages,
      max_tokens: opts.max_tokens || 2048,
      temperature: opts.temperature ?? 0.3,
      stream: false,
    }),
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`NIM ${res.status}: ${txt}`);
  }

  const data = await res.json();
  return data.choices[0].message.content;
}

function parseJSON(raw) {
  // Extrae JSON aunque Qwen ponga texto antes o después
  const match = raw.match(/\{[\s\S]*\}|\[[\s\S]*\]/);
  if (!match) throw new Error('No JSON en respuesta de Qwen');
  return JSON.parse(match[0]);
}

// ─── /generate-plan ──────────────────────────────────────────────────────────
// Input:
// {
//   profile: {
//     injuries: ["hernia_l4l5"],
//     goals: [{ description: "press banca +8kg", weeks: 10 }],
//     aversions: [{ machine: "sentadilla_libre", reason: "dolor rodilla" }],
//     schedule: [{ day: "lunes", start: "18:00", duration_min: 60 }],
//     available_machines: ["prensa_piernas", "jalon_pecho", ...],
//     anthropometric: { femur_tibia_ratio: 1.21, torso_height_ratio: 0.32, pelvis_angle: 5.2 },
//     rom: { knee_flexion_active: [0, 115], hip_flexion_active: [0, 95] }
//   }
// }
// Output: { plan: { weeks: N, days: [ { day, exercises: [ { machine, sets, reps, tempo, rest_sec, notes } ] } ] } }

async function generatePlan(body, env) {
  const { profile } = body;

  const system = `Eres un prescritor de ejercicio clínico.
Generas planes de entrenamiento personalizados basados en biomecánica individual, lesiones y objetivos medibles.
NUNCA usas frases motivacionales ni juicios estéticos.
SIEMPRE devuelves JSON puro, sin texto adicional.
NUNCA prescribes ejercicios contraindicados para las lesiones indicadas.`;

  const user = `Genera un plan de entrenamiento semanal basado en este perfil:

LESIONES/CONDICIONES: ${JSON.stringify(profile.injuries)}
OBJETIVOS MEDIBLES: ${JSON.stringify(profile.goals)}
AVERSIONES/EXCLUSIONES: ${JSON.stringify(profile.aversions)}
HORARIO DISPONIBLE: ${JSON.stringify(profile.schedule)}
MÁQUINAS DISPONIBLES: ${JSON.stringify(profile.available_machines)}
DATOS ANTROPOMÉTRICOS: ${JSON.stringify(profile.anthropometric)}
RANGOS DE MOVIMIENTO ACTIVOS: ${JSON.stringify(profile.rom)}

Devuelve SOLO este JSON:
{
  "plan": {
    "weeks": 8,
    "days": [
      {
        "day": "lunes",
        "focus": "piernas/empuje/tracción/etc",
        "duration_min": 60,
        "exercises": [
          {
            "machine": "nombre_exacto_de_la_lista",
            "sets": 3,
            "reps": "10-12",
            "tempo": "3-0-1",
            "rest_sec": 90,
            "machine_setup": "ajuste específico (ej: asiento posición 3)",
            "notes": "indicación técnica breve si aplica por lesión o antropometría"
          }
        ]
      }
    ]
  }
}`;

  const raw = await callQwen([
    { role: 'system', content: system },
    { role: 'user', content: user },
  ], env, { max_tokens: 3000, temperature: 0.2 });

  return parseJSON(raw);
}

// ─── /analyze-form ───────────────────────────────────────────────────────────
// Input:
// {
//   frames: ["data:image/jpeg;base64,...", ...],  // 4-8 frames del ejercicio
//   exercise: "prensa_piernas",
//   user_mesh: {
//     femur_tibia_ratio: 1.21,
//     pelvis_angle: 5.2,
//     safe_ranges: { knee_flexion: [0, 115], hip_flexion: [0, 95] },
//     landmarks_neutral: { ... }
//   },
//   injuries: ["hernia_l4l5"]
// }
// Output: { score, errors, corrections, positives, key_frame_index }

async function analyzeForm(body, env) {
  const { frames, exercise, user_mesh, injuries } = body;

  if (!frames || frames.length === 0) throw new Error('No hay frames');

  // Construimos el contenido multimodal: frames + texto
  const imageContent = frames.map(f => ({
    type: 'image_url',
    image_url: { url: f },
  }));

  const system = `Eres un analista de biomecánica deportiva con acceso al perfil antropométrico personalizado del usuario.
Analizas secuencias de frames de un ejercicio y detectas errores de ejecución específicos a la estructura corporal del usuario.
NUNCA haces comparaciones con estándares genéricos. Solo comparas con los rangos seguros personales del usuario.
Devuelves JSON puro, sin texto adicional.`;

  const analysisPrompt = `Analiza la ejecución de: ${exercise}

PERFIL ANTROPOMÉTRICO DEL USUARIO:
${JSON.stringify(user_mesh)}

LESIONES/CONDICIONES A CONSIDERAR:
${JSON.stringify(injuries)}

Los frames muestran entre 3-5 repeticiones completas del ejercicio.

Devuelve SOLO este JSON:
{
  "score": 0-100,
  "errors": [
    {
      "type": "descripcion_breve",
      "severity": "alta|media|baja",
      "frame_index": 0,
      "detail": "explicacion_tecnica_concreta_personalizada"
    }
  ],
  "corrections": [
    "instruccion_correctiva_concreta_y_personalizada"
  ],
  "positives": [
    "aspecto_bien_ejecutado"
  ],
  "key_frame_index": 0
}`;

  const messages = [
    { role: 'system', content: system },
    {
      role: 'user',
      content: [
        ...imageContent,
        { type: 'text', text: analysisPrompt },
      ],
    },
  ];

  const raw = await callQwen(messages, env, { vision: true, max_tokens: 1500, temperature: 0.2 });
  return parseJSON(raw);
}

// ─── /machine-info ───────────────────────────────────────────────────────────
// Input: { machine: "prensa_piernas", user_injuries: [...] }
// Output: { name, muscles_primary, muscles_secondary, setup_steps, tips, contraindications }

async function machineInfo(body, env) {
  const { machine, user_injuries = [] } = body;

  const system = `Eres un especialista en equipamiento de gimnasio y biomecánica.
Explicas cómo usar máquinas de forma precisa y segura.
Si el usuario tiene lesiones relevantes, adaptas los consejos.
Devuelves JSON puro.`;

  const user = `Información completa sobre la máquina: ${machine}
Lesiones del usuario a considerar: ${JSON.stringify(user_injuries)}

Devuelve SOLO este JSON:
{
  "name": "nombre_completo",
  "muscles_primary": ["músculo1", "músculo2"],
  "muscles_secondary": ["músculo3"],
  "setup_steps": [
    "paso 1: ajuste específico",
    "paso 2: ..."
  ],
  "tips": [
    "consejo técnico preciso"
  ],
  "contraindications": [
    "condición que contraindica o requiere modificación"
  ],
  "injury_adaptations": [
    "adaptación específica para las lesiones del usuario si aplica"
  ]
}`;

  const raw = await callQwen([
    { role: 'system', content: system },
    { role: 'user', content: user },
  ], env, { max_tokens: 1000, temperature: 0.2 });

  return parseJSON(raw);
}

// ─── /chat ───────────────────────────────────────────────────────────────────
// Input:
// {
//   message: "¿cómo ajusto el asiento de la prensa?",
//   context: {
//     current_exercise: "prensa_piernas",
//     current_plan_day: "lunes",
//     user_injuries: [...],
//     user_goals: [...]
//   }
// }
// Output: { response }

async function chat(body, env) {
  const { message, context = {} } = body;

  const system = `Eres el asistente de entrenamiento integrado en 6YM.C0.
Respondes preguntas sobre ejercicios, máquinas, técnica y plan de entrenamiento.
Conoces el perfil del usuario y su contexto actual de entrenamiento.
Eres directo, técnico y conciso. Sin frases motivacionales ni juicios estéticos.
Máximo 3 oraciones por respuesta salvo que el usuario pida más detalle.`;

  const contextStr = Object.keys(context).length > 0
    ? `\nCONTEXTO ACTUAL: ${JSON.stringify(context)}`
    : '';

  const raw = await callQwen([
    { role: 'system', content: system + contextStr },
    { role: 'user', content: message },
  ], env, { max_tokens: 512, temperature: 0.4 });

  return { response: raw };
}
