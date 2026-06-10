# Handoff - Tracking integral precalifica QA02

Ultima actualizacion: 2026-06-09 (Claude Code). Entorno: **QA02 = Oracle 19c** (`AJEREZ@QADEMI02_19C`).

## Estado actual

- **DDL auxiliar (Capas B y C): CREADO en QA02.** Tablas, secuencia, indices, parametros
  y columnas `NO_CREDITO`/`CODIGO_CLIENTE` del B ya existen.
- **Incremento A aplicado y PROBADO el 2026-06-09 AM:** `53D427AF4F597DB0E063140311AC14C5`,
  31/31 metricas.
- **Incremento B aplicado y PROBADO el 2026-06-09 PM:** `53D8BBE0BA0E44D9E063140311AC6BC6`,
  Capa C `1302/1302 == FINAL_*` (949 NP + 201 CP + 152 RXT + 0 AN), 0 nulos/duplicados,
  costo del MERGE ~0.2 ms/candidato (1.456 s el paso 13 completo). Evidencia en
  `05_RESULTADOS/RESULTADOS_QA02.md`.
- **La `spec.sql` no cambio.** Oracle se ejecuta manualmente desde Toad.
- Snapshots antes/despues disponibles en `02_PACKAGE/` (el body A probado quedo en
  `body_QA02_INCREMENTO_A_PROBADO_20260609.sql`, hash `D12032AD...`; el canonico con B
  tiene hash `0C07E500...`).
- **Decision operativa: `LOTE_DE_CARAGA_REPRESTAMO` queda en `1300` en QA02** (a proposito,
  para corridas de prueba cortas). Subirlo a `130000` solo para corridas representativas o
  comparables con PROD; cada corrida registra su lote en `VALOR_LOTE`.
- **Incremento C aplicado y PROBADO el 2026-06-09 (variante procedures):**
  `53DAC2820BDC0E55E063140311AC3EBA` — 1834 filas de pertenencia (4 flujos presentes;
  fiadores_hi aporto 0 = su NETO), cierre 1166 con **0 huerfanos**, 317 descartados
  intra-flujo visibles por primera vez, 0 nulos/repetidos, 31/31 metricas Capa B.
  Sin DDL nuevo. Reversa disponible: `04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`.
- Pendiente: capa DIAGNOSTICA.

## Lo validado en QA02 (script 00, evidencia en `05_RESULTADOS/RESULTADOS_QA02.md`)

- Version: Oracle 19c -> nombres largos validos (no hacen falta alias cortos).
- `PR_IDX` existe (286 indices) -> tablespace de indices OK.
- `PR_REPRESTAMOS.ID_REPRESTAMO` = `NUMBER(14)`.
- `PA_PARAMETROS_MVP` exige, ademas de `VALOR`: `DES_PARAMETRO`, `ADICIONADO_POR`, `FECHA_ADICION` (NOT NULL sin DEFAULT). Ya van en el script 03.
- Parametro modelo `LOTE_DE_CARAGA_REPRESTAMO` esta en `CODIGO_EMPRESA=1` (= constante `vCodigoEmpresa`); sin filas `TRACK_*` previas.

## Objetos creados en QA02 (no volver a crear)

| Objeto | Tipo |
|---|---|
| `PR.PR_JOB_PRECALIFICA_FILTRO_TRACK` | Tabla (Capa B) |
| `PR.SEQ_PR_JOB_PRECAL_FILTRO` | Secuencia (ID_DETALLE) |
| `PR.IX_PRECAL_FILTRO_CONSULTA`, `PR.IX_PRECAL_FILTRO_FECHA` | Indices |
| `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK` | Tabla (Capa C) |
| `PR.IX_PRECAL_CAND_FECHA` | Indice |
| `TRACK_PRECALIFICA_ACTIVO=S`, `_DETALLE_CURSOR=S`, `_RETENCION_DIAS=90` (empresa 1) | Parametros en `PA_PARAMETROS_MVP` |

## Instrumentacion implementada

Disenado contra el **codigo real** del body (no solo la propuesta). Todo vive en el bloque del job
`P_Carga_Precalifica_Cancelado` (junto a los `track_*` existentes ~body 8067-8230). Sin cambios a la spec.

- Helper autonomo implementado: `track_filtro` (Capa B, usa `SEQ.NEXTVAL`,
  `ROLLBACK` en handler). Guardado por `TRACK_PRECALIFICA_ACTIVO='S'`.
  Los conteos se calculan en la transaccion principal y se pasan como numeros.
- Helper autonomo `track_candidato` (Incremento B) **ya codificado** junto a `track_filtro`:
  `MERGE` idempotente a `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` con
  `(p_flujo, p_id_represtamo, p_no_credito, p_codigo_cliente, p_resultado)`, guard por flag,
  `COMMIT` propio y `ROLLBACK; NULL;` en el handler. Se invoca en el bloque de tracking por ID
  del cierre (el del `SELECT` de estado observado, extendido a `ESTADO, NO_CREDITO,
  CODIGO_CLIENTE`), con `FLUJO='CIERRE'`. El `IF` funcional del cierre NO se toco.
- Incrementos: **A** = conteos REALES de orquestacion (arranque, 5 flujos neto, RE consolidado,
  precalificacion, XCORE, solicitud, cierre) — PROBADO. **B** = cohorte final individual +
  `RESULTADO_ULTIMO` (estado observado) — PROBADO. **C** = pertenencia por flujo capturada
  tras el `FORALL INSERT` de las 5 procedures (helper package-private `track_candidatos_flujo`,
  seccion 4.9) — PROBADO. + DIAGNOSTICA (5 scripts externos, pendiente).

### Correcciones de la revision adversarial ya incorporadas (importantes)

1. **Gating de los `COUNT` por flag**: envolver cada `SELECT COUNT(*)` en `IF v_track_activo='S' THEN ... END IF`.
   Sin esto, `TRACK=N` no es linea base real. (Base de comparacion real = body de `04_ROLLBACK/`.)
2. `FECHA_CORTE` se llena con `SELECT MAX(FECHA_CORTE) FROM PA_DETALLADO_DE08 WHERE FUENTE='PR'`.
3. Precalificacion: el delta `entrada-salida` mezcla borrados + RSB/CLS/RCS -> desglosado en `PRE_RSB`,
   `PRE_CLS_RCS` y `PRE_BORRADOS` (derivado). Se quito `PRE_CON_CODIGO` (tautologico: los sin-codigo se borran).
4. `FLUJO_RE_NETO` -> `RE_ACUMULADO_TRAS_FLUJO`: la columna es el RE global acumulado, el neto va en `PARAMETROS`.
5. Cierre: se conservo el `IF` funcional existente y, con tracking activo,
   se consulta el estado resultante de cada ID para contabilizar la cohorte.
6. Notas de `ORDEN_FILTRO` (correlativo global) y paso 14 (omision deliberada).

Validado en QA02: delta de `SOL_CREADA`, manejo de XCORE y conciliacion del cierre.

## Pendientes / decisiones abiertas

1. Integrar o asociar la capa DIAGNOSTICA para igualar el desglose de
   `trackers_precalifica_cursor` (unico incremento restante).
2. Medir una corrida con `TRACK_PRECALIFICA_ACTIVO='N'` si se necesita
   cuantificar formalmente el costo del tracking.
3. Capturar (opcional) las queries 2 y 4 del script 09 para la corrida
   `53DAC2820BDC0E55E063140311AC3EBA` (bruto/neto por flujo y duraciones).

> Resueltas: A, B y C probados y conciliados al 100%. Costo MERGE ~0.2 ms/candidato
> (sin variante bulk). Lote en `1300` por decision (corridas cortas en QA02).

## Proximos pasos (orden sugerido)

1. Diseñar la capa DIAGNOSTICA contra los scripts existentes (propuesta separada).
2. Mantener la historia en QA02; no promover a PROD sin propuesta separada.

## Reglas duras (no negociables)

- Idioma espanol; no traducir nombres Oracle. No tocar la `spec`. No reactivar OPT-020.
- No ejecutar DDL/DML desde el repo: todo en Toad/QA02. No promover a PROD desde esta historia.
- Un fallo de tracking NUNCA interrumpe la precalificacion ni hace COMMIT funcional.
- `git status --short` antes de tocar; un commit por cambio logico; no `git add .`.

## Archivos clave

- Propuesta de diseno: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/PROPUESTA_TRACKING_INTEGRAL_PRECALIFICA_QA02.md`
- Diseno e historial: `02_PACKAGE/PROPUESTA_INSTRUMENTACION_BODY_QA02.md`
- Body canonico instrumentado: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
- DDL creado: `01_DDL/00..04` (todos aplicados; el C no requiere DDL)
- Rollbacks de body: `ROLLBACK_INCREMENTO_C_BODY_QA02.sql` (C -> B probado),
  `ROLLBACK_INCREMENTO_B_BODY_QA02.sql` (-> A probado), body baseline. DDL: `01..04_ROLLBACK_*`
- Validacion B: `03_VALIDACION/04..07`  ·  Validacion C: `03_VALIDACION/08..09`
- Baseline body/spec: `00_ANTES/`  ·  Evidencia: `05_RESULTADOS/RESULTADOS_QA02.md`  ·  Estado: `ESTADO.md`
