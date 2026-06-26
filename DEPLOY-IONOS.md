# 🚀 Desplegar BLACKSHEEP en IONOS Hosting Business

Tu plan de IONOS sirve archivos estáticos y ejecuta **PHP** (no Node.js), así que
publicamos el **frontend** tal cual y el formulario de demo funciona mediante un
script **PHP** (`api/demo.php`). No necesitas el servidor Node para esta opción.

## 📦 Qué se sube

Solo el contenido de la carpeta **`public/`**. Su estructura ya está lista:

```
public/
├── index.html        # La web
├── support.js        # Runtime que monta React
├── .htaccess         # Fuerza HTTPS + enruta /api/demo → api/demo.php
├── api/
│   └── demo.php      # Captura el formulario y envía correo
└── data/
    └── .htaccess     # Protege los leads (no accesibles por web)
```

> ⚠️ NO subas `node_modules`, `server.js`, `package.json` ni los `.dc.html`
> originales: no se usan en IONOS Hosting Business.

---

## 1. Configura el correo de avisos

Abre `public/api/demo.php` y revisa la parte superior:

```php
$TO_EMAIL   = 'jesus@reservi.ai';          // a dónde llegan las solicitudes
$FROM_EMAIL = 'noreply@black-sheep.net';   // debe ser de tu dominio
```

Cámbialo si quieres recibir los avisos en otro correo. El `FROM` debe ser de
**black-sheep.net** para que IONOS lo envíe sin problemas.

---

## 2. Obtén tus datos de acceso (SFTP)

En el panel de IONOS:
**Hosting → tu paquete → SFTP & SSH** (o *Datos de acceso / Webspace*). Anota:

- **Servidor (host):** algo como `home123456789.1and1-data.host`
- **Usuario:** `acc-xxxxxxx` o `u123456789`
- **Contraseña:** la que definiste (puedes restablecerla ahí mismo)
- **Puerto:** `22` (SFTP)

---

## 3. Sube los archivos

### Opción A — FileZilla (recomendado)
1. Descarga FileZilla → https://filezilla-project.org/
2. Conéctate con: Host `sftp://<servidor>`, Usuario, Contraseña, Puerto `22`.
3. En el lado remoto, entra a la carpeta raíz del sitio. En IONOS suele ser:
   - La raíz directamente, **o**
   - una carpeta tipo `/` donde van los archivos públicos.
4. Arrastra **todo el contenido de `public/`** (no la carpeta, sino lo de adentro:
   `index.html`, `support.js`, `.htaccess`, `api/`, `data/`) a esa raíz.
   - Activa "ver archivos ocultos" en FileZilla para que suba el `.htaccess`
     (menú *Servidor → Forzar mostrar archivos ocultos*).

### Opción B — Administrador de archivos de IONOS
Panel de IONOS → **Hosting → Administrador de archivos** → sube los mismos
archivos a la raíz del sitio.

---

## 4. Conecta tu dominio black-sheep.net

En IONOS: **Dominios → black-sheep.net → Destino / Conectar** y apúntalo a este
paquete de hosting (carpeta donde subiste los archivos). Si el dominio ya está en
la misma cuenta, normalmente solo eliges "Asignar a este webspace".

---

## 5. Activa SSL (HTTPS)

IONOS incluye **SSL gratis (Let's Encrypt)**: **Hosting → SSL** → actívalo para
black-sheep.net. El `.htaccess` ya fuerza HTTPS una vez esté activo.
(Puede tardar unos minutos/horas en emitirse.)

---

## 6. Prueba

1. Abre **https://black-sheep.net** → debe cargar la landing.
2. Pulsa **"Agenda una demo"**, llena el formulario y envíalo.
3. Deberías ver el mensaje de confirmación y recibir el correo en `$TO_EMAIL`.
   - Los leads también quedan en `data/leads.json` (no accesible por web).

### Si el formulario no envía correo
- Verifica que `$FROM_EMAIL` sea de tu dominio (`@black-sheep.net`).
- Revisa la carpeta de spam.
- En IONOS, confirma que el envío de correo PHP (`mail()`) esté habilitado; si no,
  configura SMTP. Avísame y te paso la versión con SMTP autenticado.

---

## Nota sobre el login

El botón "Iniciar sesión" muestra el aviso de *"panel en desarrollo"* (es lo
esperado por ahora). No requiere backend.

## ¿Y el backend Node.js?
Sigue en el repo (`server.js`) para cuando quieras un panel/API completos en un
VPS o en Render. Para IONOS Hosting Business, la versión PHP es la adecuada.
