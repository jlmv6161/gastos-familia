<#
  publicar.ps1
  Copia el index.html CIFRADO desde la carpeta de trabajo y lo sube a GitHub Pages.

  Uso:  clic derecho > Ejecutar con PowerShell
        o:  powershell -ExecutionPolicy Bypass -File publicar.ps1

  Antes de correr esto, genera la version web con:
        Documents\Claude\Gastos Familia Mariana y Jose Luis\actualizar-datos.ps1

  NOTA: archivo en ASCII a proposito (PowerShell 5.1 lee los .ps1 sin BOM como ANSI).
#>

$ErrorActionPreference = 'Stop'
$origen  = 'C:\Users\jlmv6\Documents\Claude\Gastos Familia Mariana y Jose Luis'
$destino = Split-Path -Parent $MyInvocation.MyCommand.Path
$CLAVE_DEFECTO = 'CAMBIA-ESTA-CLAVE'
$URL = 'https://jlmv6161.github.io/gastos-familia/'

function Abortar($msg) { Write-Host "`n$msg`n" -ForegroundColor Red; exit 1 }

# --- 1. La clave no puede ser la provisional ---
$credFile = Join-Path $origen 'credenciales.txt'
if (-not (Test-Path $credFile)) {
  Abortar "No existe credenciales.txt en la carpeta de trabajo. Corre actualizar-datos.ps1 primero."
}
$cred = @{}
Get-Content $credFile | ForEach-Object {
  if ($_ -match '^\s*([^=#]+)\s*=\s*(.+?)\s*$') { $cred[$Matches[1].Trim().ToLower()] = $Matches[2] }
}
if ($cred['clave'] -eq $CLAVE_DEFECTO) {
  Abortar @"
LA CONTRASENA SIGUE SIENDO LA PROVISIONAL. No se publica nada.

  1. Abre:  $credFile
  2. Cambia la linea 'clave=' por una contrasena real.
  3. Vuelve a correr actualizar-datos.ps1 (regenera el cifrado).
  4. Vuelve a correr este script.
"@
}
if ($cred['clave'].Length -lt 8) {
  Abortar "La contrasena tiene menos de 8 caracteres. Ponle una mas larga en $credFile y regenera."
}

# --- 2. Traer el index.html cifrado ---
$src = Join-Path $origen 'index.html'
if (-not (Test-Path $src)) { Abortar "No existe index.html en la carpeta de trabajo. Corre actualizar-datos.ps1." }

$dataJs = Join-Path $origen 'data.js'
if ((Test-Path $dataJs) -and (Get-Item $dataJs).LastWriteTime -gt (Get-Item $src).LastWriteTime) {
  Abortar "index.html es mas viejo que data.js: hay datos nuevos sin cifrar. Corre actualizar-datos.ps1 y reintenta."
}

Write-Host "Copiando index.html cifrado..." -ForegroundColor Cyan
Copy-Item $src (Join-Path $destino 'index.html') -Force
$kb = [math]::Round((Get-Item (Join-Path $destino 'index.html')).Length / 1KB)
Write-Host ("  OK index.html ({0} KB)" -f $kb) -ForegroundColor Green

# --- 3. Verificar que lo que se sube esta realmente cifrado ---
$idx = Get-Content (Join-Path $destino 'index.html') -Raw
foreach ($t in @('SALT=b64(', 'IV=b64(', 'CT=b64(')) {
  if ($idx.IndexOf($t) -lt 0) { Abortar "index.html no parece cifrado (falta $t). No se sube nada." }
}
foreach ($fuga in @('const GASTOS = [', '"categoria":', 'gastos_familia.csv')) {
  if ($idx.IndexOf($fuga) -ge 0) { Abortar "index.html contiene datos EN CLARO ('$fuga'). No se sube nada." }
}
Write-Host "  OK contenido verificado como cifrado" -ForegroundColor Green

# --- 4. Que no se cuele ningun archivo que no deberia publicarse ---
$sospechosos = Get-ChildItem $destino -File -Recurse |
  Where-Object { $_.FullName -notmatch '\\\.git\\' } |
  Where-Object { $_.Name -match '(?i)credencial|password|token|secret|\.env$|\.csv$|\.xlsx$|^data\.js$|^dashboard\.html$' }
if ($sospechosos) {
  Write-Host "`nATENCION: hay archivos que NO deberian publicarse:" -ForegroundColor Red
  $sospechosos | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor Red }
  Abortar "Sacalos de la carpeta y reintenta."
}

# --- 5. Commit y push ---
Set-Location $destino
git add -A
$cambios = git status --porcelain
if (-not $cambios) { Write-Host "`nNo hay cambios que subir." -ForegroundColor Yellow; exit }

Write-Host "`nSe va a subir:" -ForegroundColor Cyan
git status --short

$fecha = Get-Date -Format 'yyyy-MM-dd HH:mm'
git commit -m "Actualiza tablero de gastos familiares ($fecha)"
git push

Write-Host "`nListo. En 1-2 minutos estara actualizado en:" -ForegroundColor Green
Write-Host "  $URL" -ForegroundColor Cyan
Write-Host ("  usuario: {0}" -f $cred['usuario'].Trim()) -ForegroundColor DarkGray
