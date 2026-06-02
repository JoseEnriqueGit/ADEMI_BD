<#
.SYNOPSIS
  Asesor de inventario semantico: compara dos archivos .sql (baseline vs propuesto) y
  reporta los TOKENS DE NEGOCIO que estaban en el baseline y NO aparecen en el propuesto.

.DESCRIPTION
  El diff linea-a-linea es inutil cuando un objeto se reescribe entero (CTE vs comma-joins).
  Este script NO compara texto: extrae conjuntos de tokens (literales entre comillas, llamadas a
  funcion tipo f_*, e identificadores id_*/canal*) de ambos archivos, ignora orden y estilo, y
  lista lo que DESAPARECIO. Es exactamente el patron del incidente PR_V_ENVIO_REPRESTAMOS
  (desaparecieron los literales 'CANAL_CARGA_DIRIGIDA' / 'CANAL_CAMPANA_ESPECIAL').

  IMPORTANTE: es ASESOR, NO bloqueante. Siempre sale con codigo 0. Sirve para PRE-RELLENAR
  el inventario semantico que un humano revisa y firma. Un regex sobre SQL puede dar falsos
  positivos (alias renombrado) y falsos negativos (logica sutil dentro de una rama conservada).

  NOTA DE CODIFICACION: este archivo se mantiene en ASCII puro a proposito, para que corra
  igual en cualquier PowerShell de Windows sin depender de BOM ni de la codepage de la consola.

.PARAMETER Origen
  Ruta al .sql baseline (lo VIVO en el entorno destino).

.PARAMETER Destino
  Ruta al .sql propuesto (lo que se va a desplegar).

.EXAMPLE
  powershell -File tools\guardrail\inventario_semantico.ps1 -Origen baseline.sql -Destino propuesto.sql
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Origen,
    [Parameter(Mandatory = $true)][string]$Destino
)

function Get-Tokens {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "No existe el archivo: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw

    # Quitar comentarios de bloque y de linea, luego pasar a minusculas
    $noBlock = [regex]::Replace($raw, '(?s)/\*.*?\*/', ' ')
    $clean   = [regex]::Replace($noBlock, '--[^\r\n]*', ' ')
    $lower   = $clean.ToLowerInvariant()

    $literales = New-Object System.Collections.Generic.HashSet[string]
    $funciones = New-Object System.Collections.Generic.HashSet[string]
    $columnas  = New-Object System.Collections.Generic.HashSet[string]

    # 1) Literales entre comillas simples: capturan ramas/parametros de negocio
    foreach ($m in [regex]::Matches($lower, "'([^']*)'")) {
        $v = $m.Groups[1].Value.Trim()
        if ($v.Length -gt 0) { [void]$literales.Add($v) }
    }
    # 2) Llamadas a funcion: paquete.funcion(  y  f_xxx(
    foreach ($m in [regex]::Matches($lower, '([a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+)\s*\(')) {
        [void]$funciones.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($lower, '\b(f_[a-z0-9_]+)\s*\(')) {
        [void]$funciones.Add($m.Groups[1].Value)
    }
    # 3) Identificadores de negocio sensibles: id_*, *_especiales, canal*
    foreach ($m in [regex]::Matches($lower, '\b(id_[a-z0-9_]+|[a-z0-9_]*_especiales|canal[a-z0-9_]*)\b')) {
        [void]$columnas.Add($m.Groups[1].Value)
    }

    return [pscustomobject]@{
        Literales = $literales
        Funciones = $funciones
        Columnas  = $columnas
    }
}

function Show-Diff {
    param(
        [string]$Titulo,
        [System.Collections.Generic.HashSet[string]]$Viejo,
        [System.Collections.Generic.HashSet[string]]$Nuevo
    )

    $perdidos  = @($Viejo | Where-Object { -not $Nuevo.Contains($_) } | Sort-Object)
    $agregados = @($Nuevo | Where-Object { -not $Viejo.Contains($_) } | Sort-Object)

    Write-Host ""
    Write-Host ("== " + $Titulo + " ==") -ForegroundColor Cyan
    if ($perdidos.Count -gt 0) {
        Write-Host "  POSIBLE PERDIDA (estaba en baseline, falta en propuesto):" -ForegroundColor Red
        $perdidos | ForEach-Object { Write-Host ("    - " + $_) -ForegroundColor Red }
    } else {
        Write-Host "  Sin perdidas." -ForegroundColor Green
    }
    if ($agregados.Count -gt 0) {
        Write-Host "  Agregado (informativo):" -ForegroundColor Yellow
        $agregados | ForEach-Object { Write-Host ("    + " + $_) -ForegroundColor Yellow }
    }
    return $perdidos.Count
}

try {
    $o = Get-Tokens -Path $Origen
    $d = Get-Tokens -Path $Destino
} catch {
    Write-Host ("ERROR: " + $_) -ForegroundColor Red
    exit 0   # asesor: nunca bloquea
}

Write-Host "Inventario semantico (ASESOR - no bloqueante)" -ForegroundColor White
Write-Host ("  Baseline : " + $Origen)
Write-Host ("  Propuesto: " + $Destino)

$totalPerdidos = 0
$totalPerdidos += Show-Diff -Titulo "Literales / ramas de negocio" -Viejo $o.Literales -Nuevo $d.Literales
$totalPerdidos += Show-Diff -Titulo "Funciones / packages"         -Viejo $o.Funciones -Nuevo $d.Funciones
$totalPerdidos += Show-Diff -Titulo "Columnas / identificadores"   -Viejo $o.Columnas  -Nuevo $d.Columnas

Write-Host ""
if ($totalPerdidos -gt 0) {
    Write-Host ("[!] " + $totalPerdidos + " token(s) del baseline NO aparecen en el propuesto.") -ForegroundColor Red
    Write-Host "    Revisa cada uno en el inventario semantico y justifica si la eliminacion es intencional." -ForegroundColor Red
} else {
    Write-Host "[OK] Ningun token de negocio del baseline desaparecio. Aun asi, completa el inventario a mano." -ForegroundColor Green
}
Write-Host "    (Recordatorio: este script asesora; no sustituye leer y entender el objeto.)" -ForegroundColor DarkGray
exit 0
