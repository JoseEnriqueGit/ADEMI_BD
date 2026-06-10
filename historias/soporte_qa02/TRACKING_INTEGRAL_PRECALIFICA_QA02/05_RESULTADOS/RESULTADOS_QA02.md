# Resultados QA02

Estado: DDL auxiliar e Incrementos A, B y C aplicados y probados en QA02.

## Validacion base (script 00)

- Fecha: 2026-06-08
- Usuario / conexion: `AJEREZ@QADEMI02_19C`
- Version: Oracle Database 19c Standard Edition 2 (19.0.0.0.0) -> nombres largos validos
- Nombres nuevos: los 6 objetos NO EXISTIAN (libres)
- Tablespace indices: `PR_IDX` existe (286 indices de PR)
- `PR_REPRESTAMOS.ID_REPRESTAMO`: `NUMBER(14)`
- `PA_PARAMETROS_MVP`: columnas NOT NULL sin DEFAULT adicionales = `DES_PARAMETRO`, `ADICIONADO_POR`, `FECHA_ADICION` (incorporadas al script 03)
- Parametro modelo: `LOTE_DE_CARAGA_REPRESTAMO` en `CODIGO_EMPRESA=1` (VALOR=130000); sin filas `TRACK_*` previas
- Incidencia corregida: `;` dentro del `PROMPT 3b` rompia el script en modo "execute as script" (ORA-00900). Resuelto.

## Implementacion - DDL auxiliar

- DDL aplicado: 2026-06-08, `AJEREZ@QADEMI02_19C`, modo "Execute as Script" (F5).

| Script | Resultado en Toad | Objetos |
|---|---|---|
| `01_CREATE_PR_JOB_PRECALIFICA_FILTRO_TRACK_QA02.sql` | 4x `PL/SQL procedure successfully completed` + `Capa B creada/validada` | Tabla `PR_JOB_PRECALIFICA_FILTRO_TRACK` + `SEQ_PR_JOB_PRECAL_FILTRO` + `IX_PRECAL_FILTRO_CONSULTA` + `IX_PRECAL_FILTRO_FECHA` |
| `02_CREATE_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | 2x `PL/SQL procedure successfully completed` + `Capa C creada/validada` | Tabla `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` + `IX_PRECAL_CAND_FECHA` |
| `03_PARAMETROS_TRACK_PRECALIFICA_QA02.sql` | `3 rows created` + `Commit complete` | Parametros `TRACK_PRECALIFICA_ACTIVO=S`, `_DETALLE_CURSOR=S`, `_RETENCION_DIAS=90` (empresa 1) |

- Body preparado: 2026-06-09.
- Hash body Incremento A probado:
  `D12032ADE3845CDC1F64C3121665878B0B8679A7988CD1699D1E176796A78397`.
- Body compilado en QA02: 2026-06-09.
- `spec.sql`: sin cambios; hash igual al baseline
  `73C2432FC0C42808C288A70DF90A7B3380B8EB3726498921A265AAE4743B0AB5`.
- Errores: ninguno en la creacion del DDL.

## Prueba funcional

- Fecha: 2026-06-09.
- Job: `PR.JOB_CARGA_PRECALIFICA_RD`.
- ID de ejecucion: `53D427AF4F597DB0E063140311AC14C5`.
- Tracking activo: `TRACK_PRECALIFICA_ACTIVO = S`.
- Fecha de corte capturada: `2026-05-29`.
- Valor de lote capturado: `130000`.
- Cobertura: `31` metricas, `31` ordenes distintos, rango `1..31`,
  resultado `OK`.
- Ventana observada entre la primera y la ultima fila Capa B:
  `10:43:53.793` a `12:18:07.908`, aproximadamente `1:34:14`.
  Esta ventana no sustituye la duracion oficial del encabezado del job.

### Construccion de candidatos

| Flujo | RE antes | RE despues | Neto |
|---|---:|---:|---:|
| `Precalifica_Represtamo` | 0 | 6188 | +6188 |
| `Precalifica_Represtamo_fiadores` | 6188 | 6509 | +321 |
| `Precalifica_Represtamo_fiadores_hi` | 6509 | 6509 | 0 |
| `Precalifica_Repre_Cancelado` | 6509 | 6609 | +100 |
| `Precalifica_Repre_Cancelado_hi` | 6609 | 6654 | +45 |

RE consolidado tras los cinco flujos: `6654`.

### Precalificacion

| Resultado | Cantidad |
|---|---:|
| Entrada `RE` | 6654 |
| `RSB` clasificacion/fiador | 88 |
| `CLS/RCS` clasificacion o castigo | 232 |
| Borrados sin codigo / OFAC | 1165 |
| Salida `RE` con codigo | 5169 |

Conciliacion manual confirmada:

```text
88 + 232 + 1165 + 5169 = 6654
```

### XCORE, solicitud y canal

| Medicion | Cantidad |
|---|---:|
| XCORE entrada | 5169 |
| XCORE procesados | 5169 |
| XCORE salida | 5169 |
| Solicitudes nuevas | 5153 |
| Canales nuevos | 3625 |

`XCORE_RECHAZADOS` quedo como `NO_EJECUTADO`, porque `PVALIDA_XCORE`
permanece comentado en QA02.

### Cierre

| Estado | Cantidad |
|---|---:|
| `NP` | 3481 |
| `CP` | 1455 |
| `RXT` | 233 |
| `AN` | 0 |
| Otro | 0 |

Conciliacion manual confirmada:

```text
3481 + 1455 + 233 + 0 + 0 = 5169
```

## Incremento B - APLICADO Y PROBADO en QA02 (2026-06-09)

- Cambios aplicados:
  - Body canonico: helper `track_candidato` (MERGE autonomo a
    `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK`) + captura de la cohorte individual
    en el loop de cierre (`FLUJO='CIERRE'`, `RESULTADO_ULTIMO` = estado observado,
    `NO_CREDITO`, `CODIGO_CLIENTE`). Hash body Incremento B:
    `0C07E500BB10F564B7495B79AE9B41921B2F21692083988D9D073FD88BA499CD`.
  - DDL: `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql`
    (agrega `NO_CREDITO NUMBER(7)` y `CODIGO_CLIENTE NUMBER(7)`, idempotente).
  - La Capa B no cambia: la corrida debe seguir dando 31 metricas.

### Pasos exactos para probar en Toad (`AJEREZ@QADEMI02_19C`)

1. Ejecutar como script (F5): `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql`.
   Esperado: `Incremento B: columnas NO_CREDITO y CODIGO_CLIENTE agregadas/validadas`.
2. Ejecutar `03_VALIDACION/04_VALIDAR_ESTRUCTURAS_INCREMENTO_B_QA02.sql`.
   Esperado: 2 columnas nuevas `NUMBER(7)` nullable, PK e indice intactos,
   `TRACK_PRECALIFICA_ACTIVO='S'`.
3. Ejecutar como script (F5) el body canonico:
   `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.
   No tocar la `spec.sql`.
4. Ejecutar `03_VALIDACION/05_VALIDAR_COMPILACION_INCREMENTO_B_QA02.sql`.
   Esperado: BODY `VALID`, cero errores, `lineas_track_candidato > 0`,
   `LAST_DDL_TIME` de la spec sin cambios.
5. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`.
6. Ejecutar `03_VALIDACION/06_VALIDAR_RESULTADO_INCREMENTO_B_QA02.sql`.
   Esperado: paso 3 `OK` (Capa C == FINAL_* de Capa B), paso 4 `OK`
   (sin nulos, sin duplicados, todo `FLUJO='CIERRE'`), paso 7 `OK` (31 metricas).
7. Comparar la duracion del paso 13 (`LOOP_FINAL_VALIDACIONES_BITACORA`) contra la
   corrida `53D427AF4F597DB0E063140311AC14C5` para medir el costo del MERGE por candidato.
8. Pegar aqui: ID de ejecucion, salidas de los pasos 3/4/7 del script 06 y duraciones.
9. Si algo falla: `04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql` (vuelve al body A
   probado); la reversa del ALTER solo con aprobacion explicita.

### Resultados de la prueba (2026-06-09, `AJEREZ@QADEMI02_19C`)

- Secuencia ejecutada: ALTER 04 -> script 04 (estructuras OK: 9 columnas,
  `NO_CREDITO`/`CODIGO_CLIENTE` `NUMBER(7)` nullable, PK/indice intactos) ->
  body compilado -> script 05 (BODY `VALID`, spec `LAST_DDL_TIME` 21-MAY-26 sin
  cambios, 0 errores, 3 lineas con `track_candidato`) -> job -> conciliacion.
- **Para acortar la prueba se redujo `LOTE_DE_CARAGA_REPRESTAMO` de `130000` a
  `1300`** (queda autodocumentado en `VALOR_LOTE` de la Capa B).
  **DECISION 2026-06-09: el lote QUEDA en `1300` en QA02 a proposito**, para que
  las corridas de prueba duren menos. Subirlo a `130000` solo si se necesita una
  corrida representativa o comparable con PROD (cada corrida registra su lote en
  `VALOR_LOTE`, asi que el valor vigente siempre es auditable).
- ID de ejecucion: `53D8BBE0BA0E44D9E063140311AC6BC6`.
- Duracion total del job: `1665.743 s` (27.762 min); `REGISTROS_RE = 1633`.
- Capa B (31/31 metricas): flujos netos `1167 + 321 + 0 + 100 + 45 = 1633` RE;
  precalificacion `88 RSB + 50 CLS/RCS + 193 borrados + 1302 salida = 1633`;
  XCORE 1302/1302; `SOL_CREADA = 1299`, `CANAL_CREADO = 1073`.
- **Conciliacion Capa C vs FINAL_\*: `OK`.** `1302 == 1302` filas; desglose
  exacto `949 NP + 201 CP + 152 RXT + 0 AN + 0 OTRO = 1302`.
- **Calidad de datos: `OK`.** 0 nulos en `NO_CREDITO`/`CODIGO_CLIENTE`/
  `RESULTADO_ULTIMO`, 0 filas con `FLUJO <> 'CIERRE'`, 0 duplicados.
- **Costo del MERGE por candidato (paso 13):** corrida B `1.456 s / 1302` =
  `0.0011 s/cand` vs corrida A baseline `4.757 s / 5169` = `0.0009 s/cand`
  -> sobrecosto de `track_candidato` ~`0.2 ms` por candidato (~1 s extra en una
  corrida full de 5169). Aceptado; no se requiere la variante bulk.
- Incidencias: (1) `;` dentro del PROMPT 2 del script 05 rompia el modo
  "execute as script" (ORA-00900, misma incidencia que el script 00); corregido.
  (2) Toad no volcaba los SELECT del script 06 al Script Output; se agrego
  `03_VALIDACION/07_RESUMEN_INCREMENTO_B_UNA_FILA_QA02.sql` (resumen en una
  fila + duraciones + comparativa de costo, para F9/Data Grid).

## Incremento C - APLICADO Y PROBADO en QA02 (2026-06-09)

- Variante elegida: **procedures (diseno original)** — captura el BRUTO insertado
  por cada flujo en el `FORALL INSERT`, no solo los sobrevivientes.
- Cambios preparados (solo body; **sin DDL nuevo**):
  - Estado package-private `g_track_cand_activo`/`g_track_id_ejecucion` + tipo
    `t_track_ids` + helper autonomo `track_candidatos_flujo` (tope del body).
  - Llamada tras el `FORALL INSERT` en las 5 procedures de flujo, con el nombre
    de flujo identico al de la Capa B. Carga_Dirigida y Campana_Especiales NO
    se instrumentan.
  - Set/clear del estado en el job (init, fin OK y `WHEN OTHERS`).
  - Hash body Incremento C:
    `2254380E9C4D0CB81D139DD47860F9BD030258C415A0F8A9694FB4759531B7FA`.

### Pasos exactos para probar en Toad (`AJEREZ@QADEMI02_19C`)

1. Ejecutar como script (F5) el body canonico:
   `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.
   No tocar la `spec.sql`.
2. Ejecutar `03_VALIDACION/08_VALIDAR_COMPILACION_INCREMENTO_C_QA02.sql` (F5).
   Esperado: BODY `VALID`, 0 errores, `lineas_helper = 7`, `lineas_flag = 10`.
3. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`.
4. Ejecutar `03_VALIDACION/09_VALIDAR_RESULTADO_INCREMENTO_C_QA02.sql` con
   **F9 por query**: Query 1 debe dar `RESULTADO = OK`; Query 2 muestra bruto
   vs neto por flujo (los descartados intra-flujo, visibles por primera vez);
   Query 4 las duraciones para medir overhead.
5. Pegar aqui: ID de ejecucion y salidas de las queries 1, 2 y 4.
6. Si algo falla: `04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql` (vuelve al
   body B probado).

### Resultados de la prueba (corrida 2026-06-09, evidencia registrada 2026-06-10)

- Compilacion (script 08): BODY `VALID`, spec intacta (21-MAY-26), 0 errores,
  `lineas_helper = 7`, `lineas_flag = 10`.
- ID de ejecucion: `53DAC2820BDC0E55E063140311AC3EBA` (lote `1300`, corte `29/5/2026`).
- **Query 1 (resumen): `OK`.**
  - Pertenencia: `1834` filas en `4` flujos presentes (fiadores_hi aporto 0,
    coherente con su `NETO=0` en Capa B).
  - Cierre: `1166` filas, `0` huerfanos (todo candidato del cierre tiene fila de
    pertenencia), linea base `INI_RE_DESPUES = 0`.
  - Calidad: `0` nulos en NO_CREDITO/CODIGO_CLIENTE, `0` ids repetidos entre
    flujos, `31/31` metricas Capa B.
- Conciliacion con Capa B de la misma corrida:
  - Netos por flujo `1051 + 321 + 0 + 100 + 45 = 1517` = `RE_CONSOLIDADO`.
  - **Bruto C `1834` - neto `1517` = `317` descartados intra-flujo**, visibles
    a nivel REAL por primera vez (antes solo estimables via DIAGNOSTICA).
  - Precalificacion `87 RSB + 46 CLS/RCS + 218 borrados + 1166 salida = 1517`.
  - Cierre `792 NP + 225 CP + 149 RXT + 0 AN + 0 OTRO = 1166 = FINAL_TOTAL`.
- Queries 2 y 4 (detalle bruto/neto por flujo y duraciones): no capturadas en
  esta evidencia; opcionales, re-ejecutables en cualquier momento por
  `ID_EJECUCION` con el script 09.

## Alcance validado y pendiente

- **Incremento A:** aplicado y probado (2026-06-09,
  `53D427AF4F597DB0E063140311AC14C5`).
- **Incremento B:** aplicado y probado (2026-06-09,
  `53D8BBE0BA0E44D9E063140311AC6BC6`); cohorte individual del cierre
  conciliada al 100% con la Capa B.
- **Incremento C:** aplicado y probado (2026-06-09,
  `53DAC2820BDC0E55E063140311AC3EBA`); pertenencia por flujo conciliada,
  0 huerfanos en el cierre, 317 descartados intra-flujo visibles.
- **DIAGNOSTICA:** pendiente; desglose de filtros internos comparable con
  `trackers_precalifica_cursor`.
- **Decision operativa (2026-06-09):** `LOTE_DE_CARAGA_REPRESTAMO` queda en
  `1300` en QA02 a proposito (corridas de prueba mas cortas). Subirlo a
  `130000` solo para corridas representativas o comparables con PROD.

## Rollback

- Ejecutado: no.
- Resultado: N/A (los rollbacks de DDL en `04_ROLLBACK/` solo se usan con aprobacion explicita).
- Evidencia: N/A.
