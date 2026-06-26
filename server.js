// BLACKSHEEP — servidor Node.js + Express
// Sirve la landing (React vía dc-runtime) y expone una API para capturar
// solicitudes de demo y un endpoint de login (stub, panel en desarrollo).

const path = require('path');
const fs = require('fs');
const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

const PUBLIC_DIR = path.join(__dirname, 'public');
const DATA_DIR = path.join(__dirname, 'data');
const LEADS_FILE = path.join(DATA_DIR, 'leads.json');

// --- Middleware ---------------------------------------------------------
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- Utilidades de almacenamiento --------------------------------------
function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(LEADS_FILE)) fs.writeFileSync(LEADS_FILE, '[]', 'utf8');
}

function readLeads() {
  ensureStore();
  try {
    return JSON.parse(fs.readFileSync(LEADS_FILE, 'utf8'));
  } catch {
    return [];
  }
}

function writeLeads(leads) {
  ensureStore();
  fs.writeFileSync(LEADS_FILE, JSON.stringify(leads, null, 2), 'utf8');
}

// --- API ----------------------------------------------------------------

// Captura una solicitud de demo desde el formulario de la landing.
app.post('/api/demo', (req, res) => {
  const { nombre, correo, industria, empresa } = req.body || {};

  if (!nombre || !correo) {
    return res.status(400).json({ ok: false, error: 'Nombre y correo son obligatorios.' });
  }

  const lead = {
    id: Date.now().toString(36) + Math.round(Math.random() * 1e6).toString(36),
    nombre,
    correo,
    industria: industria || null,
    empresa: empresa || null,
    fecha: new Date().toISOString(),
    ip: req.headers['x-forwarded-for'] || req.socket.remoteAddress || null
  };

  const leads = readLeads();
  leads.push(lead);
  writeLeads(leads);

  console.log(`[demo] Nueva solicitud: ${nombre} <${correo}> (${empresa || 's/empresa'})`);
  return res.status(201).json({ ok: true, message: 'Solicitud recibida. Te contactaremos pronto.' });
});

// Login del panel — aún en desarrollo. Devuelve 501 con un mensaje claro.
app.post('/api/login', (req, res) => {
  return res.status(501).json({
    ok: false,
    message: 'El panel de administración está en desarrollo. Pronto disponible.'
  });
});

// Listado de leads protegido por token simple (para uso interno/admin).
// Configura ADMIN_TOKEN en el entorno y llama: GET /api/leads?token=XXXX
app.get('/api/leads', (req, res) => {
  const token = req.query.token || req.headers['x-admin-token'];
  if (!process.env.ADMIN_TOKEN || token !== process.env.ADMIN_TOKEN) {
    return res.status(401).json({ ok: false, error: 'No autorizado.' });
  }
  return res.json({ ok: true, leads: readLeads() });
});

// Healthcheck para plataformas de despliegue.
app.get('/api/health', (_req, res) => res.json({ ok: true, status: 'up' }));

// --- Archivos estáticos + fallback SPA ---------------------------------
app.use(express.static(PUBLIC_DIR));

// Cualquier otra ruta devuelve la landing (la navegación es client-side).
app.get('*', (_req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🐑 BLACKSHEEP corriendo en http://localhost:${PORT}`);
});
