# QA02 - Bug auto-indexado en documentos de Represtamos

- **Paquete afectado**: PA.PKG_TIPO_DOCUMENTO_PKM
- **Procedimiento**: InsertUrlReporte
- **Paquete relacionado**: PR.PR_PKG_REPRESTAMOS (p_Procesa_Fec)
- **Entorno**: QA02
- **Fecha**: 2026-03-25
- **Estado**: Fix aplicado y validado (2026-03-26)

## Problema

Al generar documentos del auto-indexado para represtamos, los campos nombre, apellido, cedula/identificacion, agencia, nacionalidad quedaban **nulos** en `PA_AUTO_INDEXADO`. PKM no podia procesar los documentos → ESTADO_REPORTE = 'X'.

## Causa raiz

### Nivel 1: 'Represtamo' faltante en el IN()

`InsertUrlReporte` tiene un SELECT interno que usa `ORIGEN_PKM IN ('Normal')` para decidir si extraer datos de persona del `codigo_referencia`. Cuando `p_Procesa_Fec` llama con `pOrigenPkm = 'Represtamo'`, el CASE no matchea → NULL en todos los campos.

```sql
-- QA02 original (buggy)
CASE WHEN r.ORIGEN_PKM IN ('Normal') THEN ...   -- 'Represtamo' no entra aqui
```

### Nivel 2: Agregar 'Represtamo' al IN() sin mas rompe p_Procesa_Fec

`p_Procesa_Fec` construye `codigo_referencia` en **dos formatos** segun el tipo de documento:

**Estado P (FEC, FUD, FCSCPF — con URL):**
```
vCodigoReferencia := vRow.CREDITO_NUEVO||': '
-- Resultado: "1814321: "
-- Partes: [1]="1814321" (credito)  [2]=" " (espacio)
```

**Estado R (DEPONENTE, SMIPYME, SDESEMPLEO — sin URL):**
```
vCodigoReferencia := 1||':'||vRow.IDENTIFICACION||':'||vRow.CREDITO_NUEVO||':'||' '||':'||vDocumento||':'||vRow.CREDITO_ANTERIOR
-- Resultado: "1:4024041515:1814321: :DEPONENTE:1629145"
-- Partes: [1]="1" (tipo_id)  [2]="cedula"  [3]=credito  [4]=" "  [5]=doc  [6]=anterior
```

Al agregar solo `'Represtamo'` al IN(), el SELECT parsea **todos** los documentos como formato largo. Para estado P (formato corto), `parte(1)` devuelve el numero de credito donde espera un tipo de identificacion → datos basura → FEC no se procesa.

### Nivel 3: url_reporte y estado_reporte NO sirven como discriminador

Se analizaron estas alternativas y se descartaron:

- **`url_reporte IS NULL`**: No funciona porque `Generar_Reportes_Prestamo` envia FUD y FCSCPF con URL pero referencia **larga**. Usar `url_reporte` devolveria NULL para esos documentos incorrectamente.
- **`estado_reporte = 'R'`** (solucion de produccion): No funciona universalmente porque `Generar_Reportes_Prestamo` envia FEC Normal con estado P pero referencia **larga**. Ademas, la version de produccion no soporta tarjetas.

### Discriminador correcto: parte(3) IS NOT NULL

El unico discriminador que funciona para **todos** los callers es verificar si la referencia tiene 3+ partes:
- Formato largo (`1:cedula:credito:...`): `parte(3)` = credito → **IS NOT NULL** → parsear
- Formato corto (`credito: `): `parte(3)` = NULL → **IS NULL** → no parsear

## Solucion implementada (v2)

### Que se cambio

En `PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte`, dentro del SELECT interno (subquery), se modificaron **4 campos**:

#### 1. tipo_identificacion (linea ~588)

```sql
-- ANTES:
case when r.ORIGEN_PKM in ('Normal') then
    nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')

-- DESPUES:
case when r.ORIGEN_PKM in ('Normal','Represtamo') then
    case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then
        nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
    else null end
```

#### 2. identificacion (linea ~600)

```sql
-- ANTES:
case when r.ORIGEN_PKM in ('Normal') then
    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2), ...)

-- DESPUES:
case when r.ORIGEN_PKM in ('Normal','Represtamo') then
    case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then
        pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2), ...)
    else null end
```

#### 3. f_num_prestamo (linea ~616)

```sql
-- ANTES:
case when r.ORIGEN_PKM in ('Normal') then
    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)

-- DESPUES:
case when r.ORIGEN_PKM in ('Normal','Represtamo') then
    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':',
        case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end)
```

#### 4. codigo_agencia (linea ~625)

```sql
-- ANTES:
case when r.origen_pkm in ('Normal') then
    (select cr.codigo_agencia from pr.pr_creditos cr
     where cr.codigo_empresa = '1'
       and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':',
           case when r.url_reporte is null then 3 else 1 end))

-- DESPUES:
case when r.origen_pkm in ('Normal','Represtamo') then
    (select cr.codigo_agencia from pr.pr_creditos cr
     where cr.codigo_empresa = '1'
       and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':',
           case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end))
```

### Que NO se cambio

- Ramas de tarjetas (`Onboarding`, `TarjetaPC`, `Tarjeta`) — intactas
- `f_prest_anterior`, `id_tempfud`, `tipo_archivo`, `nombre_archivo` — no dependen de ORIGEN_PKM
- Outer query (nombres, apellidos, nacionalidad) — usa tipo_identificacion e identificacion ya calculados
- `InsertAutoIndexado` — sin cambios
- Ningun otro paquete o procedimiento fue modificado

### Por que funciona

| Caller | Estado | Formato ref | parte(3) | Resultado |
|---|---|---|---|---|
| p_Procesa_Fec | R (DEPONENTE, etc.) | largo | existe | Parsea datos de persona ✅ |
| p_Procesa_Fec | P (FEC, FUD, FCSCPF) | corto | NULL | NULL limpio ✅ |
| Generar_Reportes_Prestamo | R (BURO, SIB, etc.) | largo | existe | Parsea datos de persona ✅ |
| Generar_Reportes_Prestamo | P (FEC Normal, FUD) | largo | existe | Parsea datos de persona ✅ |

### Flujos de ejecucion analizados

1. **`p_Procesa_Fec`** (PR.PR_PKG_REPRESTAMOS): llama a `InsertUrlReporte` **directamente** (~14 veces). NO pasa por `Generar_Reportes_Prestamo`.
2. **`Generar_Reportes_Prestamo`** (PR standalone): todos los callers conocidos pasan `pValidaReprestamo = FALSE`, lo que significa que **nunca procesa represtamos** — solo Normal. Para Normal, todos los documentos usan formato largo → `parte(3)` siempre existe → parseo correcto.
3. **Tarjetas**: entran por la rama `ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta')` que no fue modificada.

## Soluciones anteriores (descartadas)

### Solucion 1: Agregar 'Represtamo' al IN() sin discriminador
- **Problema**: rompe FEC en p_Procesa_Fec (datos basura en estado P)

### Solucion 2: Script de produccion (estado_reporte = 'R')
- **Problema**: no soporta tarjetas, cambia toda la estructura del SELECT
- **Archivos**: `scripts/ANTES.sql`, `scripts/DESPUES.sql`

### Solucion 3: Agregar 'Represtamo' + CASE url_reporte IS NULL (DESPUES_MINIMO.sql)
- **Problema**: `url_reporte IS NULL` no sirve como discriminador. FUD y FCSCPF de `Generar_Reportes_Prestamo` tienen URL pero referencia larga → devolveria NULL incorrectamente
- **Archivos**: `scripts/DESPUES_MINIMO.sql`

## Pruebas realizadas

### Datos de prueba
- **Represtamo**: ID_REPRESTAMO=2507866069, CREDITO_ANTERIOR=1629145, CREDITO_NUEVO=1814321
- **Persona**: RUTH KATHERINE MARTE DE UCETA, cedula 402-4041515-4, tipo_id=1, Dominicana
- **Agencia**: 72 (VILLA RIVAS) — verificado que credito 1814321 existe en PR.PR_CREDITOS

### Test 1: Generar_Reportes_Prestamo (pValidaReprestamo = TRUE)

```sql
DECLARE
    vError VARCHAR2(4000);
BEGIN
    PR.Generar_Reportes_Prestamo(
        pCodigoEmpresa    => '1',
        pCreditoNuevo     => '1814321',
        pCreditoAnterior  => '1629145',
        pValidaReprestamo => TRUE,
        pError            => vError
    );
    DBMS_OUTPUT.PUT_LINE('Error: ' || NVL(vError, 'NINGUNO'));
    COMMIT;
END;
/
```

**Resultado**: 8 documentos generados (BURO, SIB, LEXISNEXIS, FUD, FCSCPF, APOLIZA, SVIDA, DEPONENTE). Todos con F_ORIGEN='Represtamo', estado R, datos de persona completos y correctos.

| Campo | Valor | Validado contra |
|---|---|---|
| TIPO_IDENTIFICACION | 1 | id_personas.cod_tipo_id ✅ |
| IDENTIFICACION | 402-4041515-4 | id_personas.num_id ✅ |
| F_NUM_PRESTAMO | 1814321 | pr_creditos.no_credito ✅ |
| CODIGO_AGENCIA | 72 | pr_creditos.codigo_agencia ✅ |
| NOMBRE_AGENCIA | VILLA RIVAS | pa.agencia.descripcion ✅ |
| PRIMER_NOMBRE | RUTH | personas_fisicas ✅ |
| PRIMER_APELLIDO | MARTE | personas_fisicas ✅ |
| NACIONALIDAD | Dominicana | id_personas.nacionalidad ✅ |

### Test 2: p_Procesa_Fec (genera FEC + otros documentos)

```sql
DECLARE
    pNum_Represtamo        NUMBER := 2507866069;
    pCOD_AGENCIA           VARCHAR2(32767) := '72';
    pCOD_OFICIAL           VARCHAR2(32767) := '7691';
    pCODIGO_ACTIVIDAD      VARCHAR2(32767) := '11413';
    pMARGEN_BRUTO_STD      NUMBER := 0;
    pGASTOS_OPERATIVOS_STD NUMBER := 0;
    pVENTAS_MENSUAL        NUMBER := 0;
    pCOSTO_VENTAS          NUMBER := 0;
    pGASTOS_OPERATIVO      NUMBER := 0;
    pOTROS_INGRESOS        NUMBER := 0;
    pGASTOS_FAMILIARES     NUMBER := 0;
    pEXCEDENTE_FAMILIAR    NUMBER := 0;
    pREL_CUOTA_EXCED_FAM   NUMBER := 0;
    pError                 VARCHAR2(32767);
BEGIN
    PR.PR_PKG_REPRESTAMOS.p_Procesa_Fec(
        pNum_Represtamo, pCOD_AGENCIA, pCOD_OFICIAL,
        pCODIGO_ACTIVIDAD, pMARGEN_BRUTO_STD, pGASTOS_OPERATIVOS_STD,
        pVENTAS_MENSUAL, pCOSTO_VENTAS, pGASTOS_OPERATIVO,
        pOTROS_INGRESOS, pGASTOS_FAMILIARES, pEXCEDENTE_FAMILIAR,
        pREL_CUOTA_EXCED_FAM, pError);
    DBMS_OUTPUT.PUT_LINE('Error: ' || NVL(pError, 'NINGUNO'));
    COMMIT;
END;
/
```

**Resultado**: 6 documentos generados. FEC se genero sin error.

| Doc | Estado | TIPO_ID | IDENTIFICACION | F_NUM_PRESTAMO | CODIGO_AGENCIA | NOMBRE_AGENCIA | PRIMER_NOMBRE | URL_REPORTE |
|---|---|---|---|---|---|---|---|---|
| FEC | P | | | | 72 | VILLA RIVAS | | ✅ tiene URL |
| FUD | P | | | | | | | ✅ tiene URL |
| FCSCPF | P | | | 1814321 | 72 | VILLA RIVAS | | ✅ tiene URL |
| DEPONENTE | R | 1 | 402-4041515-4 | 1814321 | 72 | VILLA RIVAS | RUTH | |
| SMIPYME | R | 1 | 402-4041515-4 | 1814321 | 72 | VILLA RIVAS | RUTH | |
| SDESEMPLEO | R | 1 | 402-4041515-4 | 1814321 | 72 | VILLA RIVAS | RUTH | |

- **Estado P** (FEC, FUD, FCSCPF): datos de persona NULL, URL poblada → **correcto** (formato corto, no necesita datos)
- **Estado R** (DEPONENTE, SMIPYME, SDESEMPLEO): datos de persona completos → **correcto** (formato largo, parseado bien)

### Script de verificacion

```sql
-- Obtener MAX antes de ejecutar la prueba
SELECT MAX(codigo_reporte) as max_antes FROM PA.PA_REPORTES_AUTOMATICOS;

-- Despues de ejecutar, verificar registros nuevos
SELECT codigo_reporte, f_document_type, tipo_identificacion, identificacion,
       f_num_prestamo, codigo_agencia, nombre_agencia, estado_reporte,
       primer_nombre, primer_apellido, tipo_archivo, f_origen, url_reporte
FROM PA.PA_AUTO_INDEXADO
WHERE codigo_reporte > :max_antes
ORDER BY codigo_reporte;

-- Validar datos de persona contra la fuente
SELECT pf.primer_nombre, pf.segundo_nombre, pf.primer_apellido, pf.segundo_apellido,
       i.cod_tipo_id, i.num_id, i.nacionalidad
FROM pa.personas_fisicas pf
JOIN pa.id_personas i ON pf.cod_per_fisica = i.cod_persona
WHERE i.cod_tipo_id = '1'
  AND i.num_id = '402-4041515-4';
```

## Nota sobre CODIGO_AGENCIA

Si `CODIGO_AGENCIA` queda NULL para un registro Represtamo con estado R, no es bug del fix. Es porque el credito no existe en `PR.PR_CREDITOS` del ambiente QA02. Se verifico con credito 1557286 (no existe) vs 1814321 (si existe, agencia 72).

## Rollback

Si es necesario revertir:
1. Compilar `rollback/PKG_TIPO_DOCUMENTO_PKM_body_ORIGINAL.sql` en Toad (schema PA, QA02)
2. Compilar `rollback/PKG_TIPO_DOCUMENTO_PKM_spec_ORIGINAL.sql`
3. O via git: `git revert 2e19e98`

## Archivos en esta historia

```
historias/QA02_BUG_AUTOINDEXADO_REPRESTAMOS/
├── README.md                          ← este archivo
├── scripts/
│   ├── v2_ANTES.sql                   ← SELECT original de QA02 (fix definitivo - ANTES)
│   ├── v2_DESPUES.sql                 ← SELECT con fix parte(3) (fix definitivo - DESPUES)
│   ├── ANTES.sql                      ← SELECT original (solucion produccion - descartada)
│   ├── DESPUES.sql                    ← SELECT produccion (solucion produccion - descartada)
│   ├── DESPUES_MINIMO.sql             ← SELECT con url_reporte (solucion v1 - descartada)
│   ├── ANTES_DESPUES_InsertUrlReporte.sql
│   └── SELECT_InsertUrlReporte_combinado.sql
└── rollback/
    ├── PKG_TIPO_DOCUMENTO_PKM_body_ORIGINAL.sql
    └── PKG_TIPO_DOCUMENTO_PKM_spec_ORIGINAL.sql
```

## Archivos del entorno QA02 (post-reorganizacion)

```
ENTORNOS_ORACLE/QA02/schemas/
├── IA/packages/PKG_API_PKM/           ← spec.sql, body.sql
├── PA/
│   ├── functions/FORMATEAR_IDENTIFICACION.sql
│   ├── packages/
│   │   ├── PARAM/                     ← spec.sql, body.sql
│   │   └── PKG_TIPO_DOCUMENTO_PKM/   ← spec.sql, body.sql (MODIFICADO)
│   └── tables/
│       ├── PA_AUTO_INDEXADO.sql
│       ├── PA_REPORTES_AUTOMATICOS.sql
│       └── PA_REPORTES_AUTOMATICOS_HIST.sql
├── PR/
│   ├── packages/
│   │   ├── PR_PKG_REPRESTAMOS/        ← spec.sql, body.sql
│   │   └── pkg_solicitud_credito/     ← spec.sql, body.sql
│   └── procedures/
│       ├── GENERAR_REPORTES_PRESTAMO.sql
│       └── GENERAR_REPORTES_PENDIENTES.sql
└── Produccion/PKG_TIPO_DOCUMENTO_PKM.sql  ← referencia produccion
```
