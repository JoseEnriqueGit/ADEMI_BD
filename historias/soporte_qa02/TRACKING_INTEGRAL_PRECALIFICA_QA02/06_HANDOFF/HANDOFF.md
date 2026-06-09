# Handoff - Tracking integral precalifica QA02

Ultima actualizacion: 2026-06-09 (Codex). Entorno: **QA02 = Oracle 19c** (`AJEREZ@QADEMI02_19C`).

## Estado actual

- **DDL auxiliar (Capas B y C): CREADO en QA02.** Tablas, secuencia, indices y parametros ya existen.
- **Incremento A implementado en el body canonico del repo.**
- Helpers privados y 31 metricas Capa B agregados en `P_Carga_Precalifica_Cancelado`.
- **Incremento A aplicado y probado en QA02 el 2026-06-09.**
- Ejecucion validada: `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas.
- **La `spec.sql` no cambio.** Oracle se ejecuto manualmente desde Toad.
- Snapshots antes/despues disponibles en `02_PACKAGE/`.
- Pendiente: Incrementos B/C y capa DIAGNOSTICA.

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
- `track_candidato` pertenece al diseno de Incrementos B/C y aun no esta
  implementado en el body.
- Incrementos: **A** = conteos REALES de orquestacion (arranque, 5 flujos neto, RE consolidado,
  precalificacion, XCORE, solicitud, cierre). **B** = cohorte final + `RESULTADO_ULTIMO`. **C** (diferido) =
  pertenencia por flujo en el `FETCH` (toca las 5 procedures, propuesta separada). + DIAGNOSTICA (5 scripts externos).

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

1. Implementar Incremento B si se aprueba el detalle individual del cierre.
2. Implementar Incremento C si se aprueba capturar pertenencia por flujo.
3. Integrar o asociar la capa DIAGNOSTICA para igualar el desglose de
   `trackers_precalifica_cursor`.
4. Medir una corrida con `TRACK_PRECALIFICA_ACTIVO='N'` si se necesita
   cuantificar formalmente el costo del tracking.

## Proximos pasos (orden sugerido)

1. Conservar la evidencia del Incremento A.
2. Decidir alcance y volumen aceptable para Incrementos B/C.
3. Diseñar la capa DIAGNOSTICA contra los scripts existentes.
4. Mantener la historia en QA02; no promover a PROD sin propuesta separada.

## Reglas duras (no negociables)

- Idioma espanol; no traducir nombres Oracle. No tocar la `spec`. No reactivar OPT-020.
- No ejecutar DDL/DML desde el repo: todo en Toad/QA02. No promover a PROD desde esta historia.
- Un fallo de tracking NUNCA interrumpe la precalificacion ni hace COMMIT funcional.
- `git status --short` antes de tocar; un commit por cambio logico; no `git add .`.

## Archivos clave

- Propuesta de diseno: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/PROPUESTA_TRACKING_INTEGRAL_PRECALIFICA_QA02.md`
- Diseno e historial: `02_PACKAGE/PROPUESTA_INSTRUMENTACION_BODY_QA02.md`
- Body canonico instrumentado: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
- DDL creado: `01_DDL/00..03`  ·  Rollbacks: `04_ROLLBACK/01..03` + body baseline
- Baseline body/spec: `00_ANTES/`  ·  Evidencia: `05_RESULTADOS/RESULTADOS_QA02.md`  ·  Estado: `ESTADO.md`
