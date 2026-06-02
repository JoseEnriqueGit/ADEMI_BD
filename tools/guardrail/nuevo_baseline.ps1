<#
.SYNOPSIS
  Crea el placeholder de baseline de un objeto en la carpeta espejo de un entorno.

.DESCRIPTION
  Mecanismo GRADUAL para poblar el baseline de PROD (u otro entorno) objeto por objeto, la
  primera vez que cada uno pasa por el runbook de promocion. NO toca la base: solo crea el
  archivo .sql con la cabecera de procedencia y el SQL de extraccion listo para que el operador
  pegue el DDL VIVO obtenido de Toad (DBMS_METADATA.GET_DDL).

  El archivo creado es un PLACEHOLDER NO EJECUTABLE (no contiene CREATE) para no envenenar el
  baseline con contenido inventado. Si el archivo ya existe, NO lo sobreescribe.

  ASCII puro a proposito (portable, sin depender de BOM/codepage).

.PARAMETER Entorno
  DESARROLLO | QA | QA02 | Produccion

.PARAMETER Schema
  PR | PA | CD | CC | IA | TC ...

.PARAMETER Tipo
  views | packages | procedures | functions | jobs | tables | triggers | sequences

.PARAMETER Objeto
  Nombre del objeto (sin schema).

.PARAMETER Paquete
  Si se indica, crea subcarpeta <Objeto>/ con spec.sql y body.sql (en vez de un solo .sql).

.EXAMPLE
  powershell -File tools\guardrail\nuevo_baseline.ps1 -Entorno Produccion -Schema PR -Tipo packages -Objeto PR_PKG_REPRESTAMOS -Paquete
.EXAMPLE
  powershell -File tools\guardrail\nuevo_baseline.ps1 -Entorno Produccion -Schema PR -Tipo jobs -Objeto JOB_CAMPANA_ESPECIALES
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Entorno,
    [Parameter(Mandatory = $true)][string]$Schema,
    [Parameter(Mandatory = $true)][string]$Tipo,
    [Parameter(Mandatory = $true)][string]$Objeto,
    [switch]$Paquete
)

# Raiz del repo = dos niveles arriba de tools/guardrail/
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$baseDir = Join-Path $repo ("ENTORNOS_ORACLE/{0}/schemas/{1}/{2}" -f $Entorno, $Schema, $Tipo)

function Get-ExtraccionSql {
    param([string]$TipoObj, [string]$Sch, [string]$Obj)
    switch ($TipoObj) {
        'PACKAGE'      { return "SELECT DBMS_METADATA.GET_DDL('PACKAGE','$Obj','$Sch') FROM dual;" }
        'PACKAGE_BODY' { return "SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY','$Obj','$Sch') FROM dual;" }
        'VIEW'         { return "SELECT DBMS_METADATA.GET_DDL('VIEW','$Obj','$Sch') FROM dual;" }
        'PROCEDURE'    { return "SELECT DBMS_METADATA.GET_DDL('PROCEDURE','$Obj','$Sch') FROM dual;" }
        'FUNCTION'     { return "SELECT DBMS_METADATA.GET_DDL('FUNCTION','$Obj','$Sch') FROM dual;" }
        'TRIGGER'      { return "SELECT DBMS_METADATA.GET_DDL('TRIGGER','$Obj','$Sch') FROM dual;" }
        'SEQUENCE'     { return "SELECT DBMS_METADATA.GET_DDL('SEQUENCE','$Obj','$Sch') FROM dual;" }
        'TABLE'        { return "SELECT DBMS_METADATA.GET_DDL('TABLE','$Obj','$Sch') FROM dual;" }
        'JOB'          { return "-- Job: DBMS_METADATA.GET_DDL('PROCOBJ','$Obj','$Sch') o exportar desde Toad (Scheduler)." }
        default        { return "SELECT DBMS_METADATA.GET_DDL('$TipoObj','$Obj','$Sch') FROM dual;" }
    }
}

function New-Placeholder {
    param([string]$Ruta, [string]$TipoObj)
    if (Test-Path -LiteralPath $Ruta) {
        Write-Host ("  [SKIP] ya existe: " + $Ruta) -ForegroundColor Yellow
        return
    }
    $dir = Split-Path -Parent $Ruta
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $sql = Get-ExtraccionSql -TipoObj $TipoObj -Sch $Schema -Obj $Objeto
    $lineas = @(
        "-- ============================================================================",
        "-- ENTORNO        : $Entorno",
        "-- OBJETO         : $Schema.$Objeto",
        "-- TIPO           : $TipoObj",
        "-- ESTADO         : *** BASELINE PENDIENTE - NO DESPLEGAR ESTE ARCHIVO ***",
        "-- MOTIVO         : Placeholder de baseline. Pegar aqui el DDL VIVO extraido de $Entorno.",
        "-- ============================================================================",
        "--",
        "-- ESTE ARCHIVO ES UN MARCADOR. No contiene DDL ejecutable a proposito.",
        "--",
        "-- COMO COMPLETARLO (en Toad, conectado a $Entorno):",
        "--   1. SET LONG 200000",
        "--   2. $sql",
        "--   3. Reemplazar TODO el contenido por el DDL obtenido.",
        "--   4. Agregar la cabecera de procedencia (docs/instrucciones_ai/PLANTILLA_CABECERA_PROCEDENCIA.sql).",
        "--   5. git add + commit.",
        "-- ============================================================================"
    )
    Set-Content -LiteralPath $Ruta -Value $lineas -Encoding ASCII
    Write-Host ("  [OK]   creado: " + $Ruta) -ForegroundColor Green
}

Write-Host ("Generando placeholder de baseline: {0}.{1} ({2}) en {3}" -f $Schema, $Objeto, $Tipo, $Entorno) -ForegroundColor White

if ($Paquete) {
    $dirPkg = Join-Path $baseDir $Objeto
    New-Placeholder -Ruta (Join-Path $dirPkg "spec.sql") -TipoObj 'PACKAGE'
    New-Placeholder -Ruta (Join-Path $dirPkg "body.sql") -TipoObj 'PACKAGE_BODY'
} else {
    $tipoObj = switch ($Tipo) {
        'views'      { 'VIEW' }
        'procedures' { 'PROCEDURE' }
        'functions'  { 'FUNCTION' }
        'jobs'       { 'JOB' }
        'tables'     { 'TABLE' }
        'triggers'   { 'TRIGGER' }
        'sequences'  { 'SEQUENCE' }
        default      { $Tipo.ToUpperInvariant() }
    }
    New-Placeholder -Ruta (Join-Path $baseDir ($Objeto + ".sql")) -TipoObj $tipoObj
}
Write-Host "Listo." -ForegroundColor White
