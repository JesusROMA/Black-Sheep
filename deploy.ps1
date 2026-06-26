<#
.SYNOPSIS
  Despliega BLACKSHEEP a IONOS Hosting Business por SFTP.

.DESCRIPTION
  Sube el contenido de la carpeta public/ al webspace de IONOS (a las dos
  ubicaciones donde vive el sitio), verifica que https://black-sheep.net
  responda y, opcionalmente, hace commit + push a GitHub.

.PARAMETER Password
  Contraseña SFTP. Si no la pasas, el script la pedirá de forma segura (oculta).

.PARAMETER GitPush
  Si se indica, hace 'git add/commit/push' tras el despliegue.

.PARAMETER Message
  Mensaje de commit (solo con -GitPush). Por defecto uno genérico.

.EXAMPLE
  .\deploy.ps1
  (pide la contraseña y despliega)

.EXAMPLE
  .\deploy.ps1 -GitPush -Message "Actualiza textos del hero"
#>

param(
  [string]$Password,
  [switch]$GitPush,
  [string]$Message = "Despliegue a producción"
)

$ErrorActionPreference = 'Stop'

# ===================== CONFIGURACIÓN =====================
$SftpHost    = 'access-5020713403.webspace-host.com'
$SftpPort    = 22
$SftpUser    = 'a1558845'
$LocalDir    = Join-Path $PSScriptRoot 'public'
$RemotePaths = @('/', '/clickandbuilds/Blacksheep')   # se sincronizan ambas
$SiteUrl     = 'https://black-sheep.net/'
# Archivos/carpetas de public/ que se suben:
$Items       = @('index.html', 'support.js', '.htaccess', 'api', 'data')
# ========================================================

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# 1. Asegurar Posh-SSH
Write-Step "Verificando Posh-SSH..."
if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
  Write-Host "Instalando Posh-SSH (solo la primera vez)..."
  if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
  }
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
  Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
}
Import-Module Posh-SSH

# 2. Validar carpeta local
if (-not (Test-Path $LocalDir)) { throw "No se encuentra la carpeta: $LocalDir" }

# 3. Credenciales
if ([string]::IsNullOrWhiteSpace($Password)) {
  $secure = Read-Host "Contraseña SFTP de IONOS ($SftpUser)" -AsSecureString
} else {
  $secure = ConvertTo-SecureString $Password -AsPlainText -Force
}
$cred = New-Object System.Management.Automation.PSCredential($SftpUser, $secure)

# 4. Conectar
Write-Step "Conectando a $SftpHost..."
$session = New-SFTPSession -ComputerName $SftpHost -Port $SftpPort -Credential $cred -AcceptKey
$sid = $session.SessionId
Write-Host "Conectado (sesión $sid)." -ForegroundColor Green

# 5. Subir
try {
  foreach ($remote in $RemotePaths) {
    Write-Step "Subiendo a $remote"
    foreach ($item in $Items) {
      $localPath = Join-Path $LocalDir $item
      if (Test-Path $localPath) {
        Set-SFTPItem -SessionId $sid -Path $localPath -Destination $remote -Force
        Write-Host "   ✓ $item"
      } else {
        Write-Host "   - (omitido, no existe) $item" -ForegroundColor DarkYellow
      }
    }
  }
} finally {
  Remove-SFTPSession -SessionId $sid | Out-Null
}

# 6. Verificar
Write-Step "Verificando $SiteUrl ..."
Start-Sleep -Seconds 2
try {
  $r = Invoke-WebRequest $SiteUrl -MaximumRedirection 5 -TimeoutSec 30 -UseBasicParsing
  $ok = ($r.StatusCode -eq 200) -and ($r.Content -match 'BLACKSHEEP')
  if ($ok) {
    Write-Host "✅ Web OK — Status $($r.StatusCode), contenido BLACKSHEEP presente." -ForegroundColor Green
  } else {
    Write-Host "⚠️  Respondió $($r.StatusCode) pero no detecté el contenido esperado." -ForegroundColor Yellow
  }
} catch {
  Write-Host "⚠️  No se pudo verificar la web: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 7. Git (opcional)
if ($GitPush) {
  Write-Step "Publicando en GitHub..."
  Push-Location $PSScriptRoot
  try {
    git add .
    git commit -m $Message
    git push origin main
    Write-Host "✅ Cambios enviados a GitHub." -ForegroundColor Green
  } catch {
    Write-Host "⚠️  Git: $($_.Exception.Message)" -ForegroundColor Yellow
  } finally {
    Pop-Location
  }
}

Write-Step "Despliegue finalizado. 🐑"
