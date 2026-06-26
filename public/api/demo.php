<?php
// BLACKSHEEP — Captura de solicitudes de demo (versión PHP para IONOS Hosting Business)
// Recibe el formulario de la landing, guarda el lead y envía un correo de aviso.

// ===================== CONFIGURACIÓN =====================
$TO_EMAIL   = 'jesus@reservi.ai';            // ← a dónde llegan los avisos de demo
$FROM_EMAIL = 'noreply@black-sheep.net';     // ← debe ser de tu dominio (SPF/IONOS)
$SAVE_TO_FILE = true;                         // guardar también en data/leads.json
// ========================================================

header('Content-Type: application/json; charset=utf-8');

// Solo POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Método no permitido.']);
    exit;
}

// Acepta JSON o form-urlencoded
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = $_POST;
}

$nombre    = trim($data['nombre']    ?? '');
$correo    = trim($data['correo']    ?? '');
$industria = trim($data['industria'] ?? '');
$empresa   = trim($data['empresa']   ?? '');

// Validación
if ($nombre === '' || !filter_var($correo, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Nombre y correo válido son obligatorios.']);
    exit;
}

// Sanea para evitar inyección en cabeceras/correo
$clean = fn($s) => str_replace(["\r", "\n", "%0a", "%0d"], '', $s);
$nombre = $clean($nombre); $correo = $clean($correo);
$industria = $clean($industria); $empresa = $clean($empresa);

$lead = [
    'id'        => uniqid('lead_', true),
    'nombre'    => $nombre,
    'correo'    => $correo,
    'industria' => $industria ?: null,
    'empresa'   => $empresa ?: null,
    'fecha'     => date('c'),
    'ip'        => $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? null,
];

// Guardar en archivo (carpeta data/ protegida por .htaccess)
if ($SAVE_TO_FILE) {
    $dir = __DIR__ . '/../data';
    if (!is_dir($dir)) { @mkdir($dir, 0755, true); }
    $file = $dir . '/leads.json';
    $fp = @fopen($file, 'c+');
    if ($fp) {
        flock($fp, LOCK_EX);
        $content = stream_get_contents($fp);
        $leads = json_decode($content, true);
        if (!is_array($leads)) { $leads = []; }
        $leads[] = $lead;
        ftruncate($fp, 0);
        rewind($fp);
        fwrite($fp, json_encode($leads, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        flock($fp, LOCK_UN);
        fclose($fp);
    }
}

// Enviar correo de aviso
$asunto = "Nueva solicitud de demo — $nombre";
$cuerpo = "Se recibió una nueva solicitud de demo en BLACKSHEEP:\n\n"
        . "Nombre:    $nombre\n"
        . "Correo:    $correo\n"
        . "Empresa:   " . ($empresa ?: '—') . "\n"
        . "Industria: " . ($industria ?: '—') . "\n"
        . "Fecha:     {$lead['fecha']}\n"
        . "IP:        {$lead['ip']}\n";
$headers = "From: BLACKSHEEP <$FROM_EMAIL>\r\n"
         . "Reply-To: $nombre <$correo>\r\n"
         . "Content-Type: text/plain; charset=utf-8\r\n";

@mail($TO_EMAIL, $asunto, $cuerpo, $headers);

http_response_code(201);
echo json_encode(['ok' => true, 'message' => 'Solicitud recibida. Te contactaremos pronto.']);
