# QA02 - Bug auto-indexado en documentos de Represtamos

- **Paquete afectado**: PA.PKG_TIPO_DOCUMENTO_PKM
- **Procedimiento**: InsertUrlReporte
- **Paquete relacionado**: PR.PR_PKG_REPRESTAMOS (p_Procesa_Fec)
- **Entorno**: QA02
- **Fecha**: 2026-03-25

## Problema

Al generar documentos del auto-indexado para represtamos, los campos nombre, apellido, cedula/identificacion, agencia, nacionalidad quedaban **nulos**. Los documentos se insertaban en `PA_REPORTES_AUTOMATICOS` y `PA_AUTO_INDEXADO` pero sin datos de persona.

## Causa raiz

### Nivel 1: 'Represtamo' faltante en el IN()

La version de QA02 de `InsertUrlReporte` tenia en el SELECT interno:

```sql
-- QA02 (buggy)
CASE WHEN r.ORIGEN_PKM IN ('Normal') THEN ...

-- QA (tiene 'Represtamo')
CASE WHEN r.ORIGEN_PKM IN ('Normal','Represtamo') THEN ...
```

Cuando `ORIGEN_PKM = 'Represtamo'`, ninguna rama del CASE matcheaba, todos los campos caian a NULL.

### Nivel 2: Agregar 'Represtamo' no es solucion — rompe p_Procesa_Fec

Agregar `'Represtamo'` al IN() **corrigio los NULLs para documentos estado 'R'** pero causo que **FileFlow/PKM no pudiera procesar los documentos estado 'P'** (FEC, FUD, FCSCPF).

La razon es que `p_Procesa_Fec` llama a `InsertUrlReporte` con **dos formatos distintos de `codigo_referencia`** dependiendo del tipo de documento:

#### Documentos con estado = 'P' (FEC, FUD, FCSCPF — tienen URL):
```
vCodigoReferencia := vRow.CREDITO_NUEVO||': '
-- Resultado: "2505328375: "
-- Partes: [1]="2505328375" (credito)  [2]=" " (espacio)
```

#### Documentos con estado = 'R' (DEPONENTE, APOLIZA, SMIPYME, SDESEMPLEO — sin URL):
```
vCodigoReferencia := 1||':'||vRow.IDENTIFICACION||':'||vRow.CREDITO_NUEVO||':'||' '||':'||vDocumento||':'||vRow.CREDITO_ANTERIOR
-- Resultado: "1:002-0012345-6:2505328375: :DEPONENTE:2505328370"
-- Partes: [1]="1" (tipo_id)  [2]="cedula"  [3]=credito  [4]=" "  [5]=doc  [6]=anterior
```

Con `ORIGEN_PKM IN ('Normal','Represtamo')`, el SELECT **siempre** parsea la referencia como si fuera formato largo:

| Campo | parte() usada | Valor con estado 'P' | Valor con estado 'R' |
|---|---|---|---|
| tipo_identificacion | parte(1) | `"2505328375"` (no. credito — **INCORRECTO**) | `"1"` (correcto) |
| identificacion | formatear(parte(2),...) | `" "` (espacio — **BASURA**) | cedula formateada (correcto) |
| f_num_prestamo | parte(3) | `NULL` (no existe parte 3) | no. credito (correcto) |
| f_prest_anterior | parte(4) | `NULL` | `" "` |
| id_tempfud | parte(6) | `NULL` | credito anterior |

### Mecanismo de fallo (verificado con codigo fuente)

**No se produce excepcion PL/SQL.** Se verifico cada componente de la cadena:

| Componente | Comportamiento con input invalido | Lanza excepcion? |
|---|---|---|
| `PA.FORMATEAR_IDENTIFICACION` | Si `pFormato = NULL`, retorna `pIdentificacion` tal cual (ej: `" "`) | **No** |
| `IA.PKG_API_PKM.obtienepartereferencia` | Si la parte no existe, retorna `NULL` | **No** |
| `InsertAutoIndexado` | `PRAGMA AUTONOMOUS_TRANSACTION`. Tabla `PA_AUTO_INDEXADO` sin constraints NOT NULL. INSERT siempre exitoso | **No** |
| Scalar subqueries de personas | `i.cod_tipo_id = '2505328375'` no matchea → retorna `NULL` | **No** |
| `PKG_SOLICITUD_CREDITO.crea_fec_solicitud` | Se ejecuta ANTES de los documentos. No interactua con InsertUrlReporte | N/A |
| Triggers en PA_REPORTES_AUTOMATICOS | Solo `TRG_PA_REPORTES_SUPERVISION` (auditoria: Usuario_Crea, Fec_Inclusion). Los otros 3 triggers son sobre tablas distintas (PA_REPORTE_FD02*) | N/A |

**Lo que realmente ocurre**: `p_Procesa_Fec` termina "exitosamente" en Oracle, pero inserta en `PA_AUTO_INDEXADO` registros con **datos basura** para documentos estado 'P':

- `TIPO_IDENTIFICACION = '2505328375'` (numero de credito, no un cod_tipo_id valido)
- `IDENTIFICACION = ' '` (espacio)
- `F_NUM_PRESTAMO = NULL`
- `PRIMER_NOMBRE, SEGUNDO_NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO, NACIONALIDAD = NULL`

El sistema downstream **FileFlow/PKM** lee estos registros de `PA_AUTO_INDEXADO` y al encontrar metadata invalida (tipo de identificacion inexistente, identificacion vacia), **no puede procesar los documentos**, dejandolos en estado pendiente. Esto es lo que se manifesto como "los documentos no terminaban de procesar".

## Solucion aplicada

Se reemplazo el SELECT completo de `InsertUrlReporte` con la version de **Produccion**, que usa `estado_reporte` como discriminador en vez de `ORIGEN_PKM`:

```sql
-- Produccion: discrimina por estado_reporte
CASE WHEN r.estado_reporte = 'R' THEN
    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
ELSE NULL END  -- estado 'P' no parsea referencia → NULL limpio
```

Esto es semanticamente correcto porque:
- **estado = 'R'**: el `codigo_referencia` tiene el formato largo (`tipo_id:cedula:credito:...`), necesita extraer datos de persona para generar el reporte
- **estado = 'P'**: el `codigo_referencia` es corto (solo credito), ya tiene URL del reporte generado; no necesita datos de persona. FileFlow/PKM sabe manejar NULLs en estos campos

### Diferencias clave entre versiones

| Aspecto | QA / QA02 original | Produccion (aplicada) |
|---|---|---|
| Discriminador | `ORIGEN_PKM` (Normal, Represtamo, Tarjeta...) | `estado_reporte = 'R'` |
| Estructura | Subquery con columnas calculadas | Query directo sobre `pa_reportes_automaticos`, calculos inline |
| Soporte Tarjetas | Si (Onboarding, TarjetaPC, Tarjeta via `TC_SOLICITUD_TARJETA`) | **No** |
| nombre_agencia | Solo `pa.agencia` por cod_agencia | JOIN `pr.pr_creditos` + `pa.agencia` (mas robusto) |
| Manejo estado 'P' vs 'R' | No distingue — parsea siempre igual | Distingue correctamente — solo parsea en estado 'R' |

## Alcance del cambio

- **Corregido**: Represtamos con datos nulos en auto-indexado (documentos estado 'R')
- **Corregido**: Documentos estado 'P' (FEC, FUD, FCSCPF) ahora insertan NULLs limpios en lugar de datos basura, permitiendo que FileFlow/PKM los procese correctamente
- **Riesgo pendiente**: la version de produccion **no maneja tarjetas** (Onboarding/TarjetaPC/Tarjeta). Si QA02 procesa auto-indexado para tarjetas, podrian presentarse NULLs en ese flujo

## Nota sobre QA

La version de QA tiene `'Represtamo'` en el IN(), asi que NO tiene el problema de NULLs para documentos estado 'R'. Sin embargo, tiene el **mismo bug latente de formato de referencia**: si se ejecuta `p_Procesa_Fec` en QA, los documentos con estado 'P' insertarian datos basura en `PA_AUTO_INDEXADO` y FileFlow/PKM no los procesaria.

## Solucion ideal (futura, si se obtiene permiso)

Combinar ambos enfoques en un solo SELECT:
- Para Normal/Represtamo: usar `estado_reporte` como discriminador (como produccion)
- Para Tarjeta: mantener la logica de `TC_SOLICITUD_TARJETA` existente en QA

## Restricciones

No se tiene permiso de editar `PA.PKG_TIPO_DOCUMENTO_PKM` en QA02. El cambio se aplico directamente en la base de datos reemplazando con el script de produccion.

## Paquetes y objetos analizados

| Objeto | Schema | Tipo | Proposito en el analisis |
|---|---|---|---|
| PKG_TIPO_DOCUMENTO_PKM | PA | Package | Contiene InsertUrlReporte e InsertAutoIndexado |
| PR_PKG_REPRESTAMOS | PR | Package | Contiene p_Procesa_Fec que invoca InsertUrlReporte |
| PKG_SOLICITUD_CREDITO | PR | Package | Contiene crea_fec_solicitud (genera FEC antes de documentos) |
| PKG_API_PKM | IA | Package | Contiene obtienepartereferencia (split de codigo_referencia) |
| FORMATEAR_IDENTIFICACION | PA | Function | Formatea cedula con mascara de tipos_id |
| PARAM | PA | Package | Parametros de empresa (no factor) |
| PA_AUTO_INDEXADO | PA | Table | Destino de InsertAutoIndexado — sin constraints NOT NULL |
| PA_REPORTES_AUTOMATICOS | PA | Table | Tabla intermedia de reportes |
| TRG_PA_REPORTES_SUPERVISION | PA | Trigger | Auditoria (Incluido_Por, Fec_Inclusion) — no factor |
| TRG_PA_REPORTE_FD02* | PA | Triggers (3) | Sobre tablas PA_REPORTE_FD02* — no relacionados |

## Archivos de referencia en el repo

- QA body: `ENTORNOS_ORACLE/QA/schemas/PA/packages/PKG_TIPO_DOCUMENTO_PKM/body.sql`
- QA02 body: `ENTORNOS_ORACLE/QA02/schemas/PA/packages/PA.PKG_TIPO_DOCUMENTO_PKM/body.sql` (version pre-fix)
- Produccion: `ENTORNOS_ORACLE/Produccion/PKG_TIPO_DOCUMENTO_PKM.sql`
- PR_PKG_REPRESTAMOS QA02: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS.sql`
- PKG_SOLICITUD_CREDITO QA02: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR.pkg_solicitud_credito/body.SQL`
- PKG_API_PKM QA02: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/IA.PKG_API_PKM/body.sql`
- FORMATEAR_IDENTIFICACION QA02: `ENTORNOS_ORACLE/QA02/schemas/PR/Functions/FORMATEAR_IDENTIFICACION.sql`
- PA_AUTO_INDEXADO QA02: `ENTORNOS_ORACLE/QA02/schemas/PA/tables/PA.PA_AUTO_INDEXADO.sql`
