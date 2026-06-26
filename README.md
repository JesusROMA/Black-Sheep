# 🐑 BLACKSHEEP — Agentes de IA para Call Center

Landing web de **BLACKSHEEP**, una plataforma de agentes de inteligencia
artificial que atienden llamadas y mensajes, agendan citas y dan seguimiento a
prospectos por **WhatsApp** — para que tu equipo se concentre en lo que ya tiene
enfrente.

La web presenta el producto (demo interactiva, funcionalidades, integraciones,
precios y "nosotros") y captura solicitudes de demo a través de un backend real.

---

## 🧱 Tecnologías

| Capa        | Tecnología                                                              |
|-------------|------------------------------------------------------------------------|
| Frontend    | **React 18** (montado en tiempo de ejecución por el runtime `dc-runtime` desde `support.js`), HTML, CSS-in-JS, SVG animado |
| Backend     | **Node.js + Express**                                                   |
| Almacenamiento | Archivo JSON (`data/leads.json`) — fácil de migrar a una base de datos |
| Despliegue  | Docker · Render · Railway / Heroku (Procfile)                           |

> El frontend es un artefacto autocontenido: `public/index.html` define la app y
> `public/support.js` (el runtime DC) carga React/ReactDOM desde CDN y monta el
> componente. No requiere build de frontend.

---

## 📁 Estructura del proyecto

```
.
├── public/
│   ├── index.html        # Landing (componente React vía dc-runtime)
│   └── support.js        # Runtime DC (monta React, interpreta el template)
├── data/
│   └── leads.json        # Solicitudes de demo capturadas (ignorado por git)
├── server.js             # Servidor Express + API
├── package.json
├── Dockerfile
├── render.yaml           # Despliegue en Render
├── Procfile              # Despliegue en Railway / Heroku
├── .env.example
└── README.md
```

Los archivos originales (`BLACKSHEEP.dc.html`, `Black-Sheep.dc.html`,
`BLACKSHEEP-landing-v1.dc.html`, `screenshots/`, `uploads/`) se conservan como
material fuente; la versión servida es `public/index.html`.

---

## 🚀 Puesta en marcha local

Requisitos: **Node.js 18+**.

```bash
# 1. Instalar dependencias
npm install

# 2. (Opcional) configurar variables de entorno
cp .env.example .env

# 3. Arrancar en desarrollo (recarga automática)
npm run dev

# o en producción
npm start
```

Abre **http://localhost:3000** en el navegador.

> ⚠️ El runtime carga React desde un CDN (unpkg), por lo que se necesita
> conexión a internet la primera vez que se abre la página.

---

## 🔌 API

| Método | Ruta            | Descripción                                                        |
|--------|-----------------|--------------------------------------------------------------------|
| `POST` | `/api/demo`     | Registra una solicitud de demo. Body: `{ nombre, correo, industria, empresa }` |
| `POST` | `/api/login`    | Login del panel (stub — devuelve `501`, en desarrollo)             |
| `GET`  | `/api/leads`    | Lista las solicitudes capturadas. Requiere `?token=ADMIN_TOKEN`   |
| `GET`  | `/api/health`   | Healthcheck (`{ ok: true, status: "up" }`)                        |

### Ejemplos

```bash
# Registrar una demo
curl -X POST http://localhost:3000/api/demo \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana López","correo":"ana@empresa.com","industria":"Restaurante","empresa":"La Tasca"}'

# Consultar leads (requiere ADMIN_TOKEN configurado)
curl "http://localhost:3000/api/leads?token=TU_TOKEN"
```

El formulario "Agenda una demo" de la web envía automáticamente los datos a
`POST /api/demo` y muestra la confirmación al usuario.

---

## ☁️ Despliegue

### Render
1. Sube el repositorio a GitHub.
2. En Render: **New → Blueprint** y selecciona el repo (usa `render.yaml`).
3. Render genera `ADMIN_TOKEN` automáticamente y publica la web.

### Railway / Heroku
Usa el `Procfile` incluido. La plataforma inyecta `PORT` automáticamente.

```bash
# Railway
railway up
```

### Docker
```bash
docker build -t blacksheep .
docker run -p 3000:3000 -e ADMIN_TOKEN=mi-token blacksheep
```

---

## 🔐 Variables de entorno

| Variable      | Descripción                                              | Por defecto |
|---------------|---------------------------------------------------------|-------------|
| `PORT`        | Puerto del servidor                                     | `3000`      |
| `ADMIN_TOKEN` | Token para consultar `/api/leads`                       | —           |

---

## 🗺️ Próximos pasos sugeridos

- Migrar el almacenamiento de leads a una base de datos (PostgreSQL, Supabase…).
- Enviar notificación por correo/Slack al recibir una nueva solicitud.
- Implementar el panel de administración (`/api/login` + autenticación real).
- Conectar el chat de la demo a un modelo de IA real.

---

© BLACKSHEEP — Intelligent Automation.
