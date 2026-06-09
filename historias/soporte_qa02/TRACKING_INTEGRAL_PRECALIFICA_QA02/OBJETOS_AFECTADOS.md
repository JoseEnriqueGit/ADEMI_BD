# Objetos afectados

## Confirmados

| Objeto | Tipo | Entorno | Cambio esperado |
|---|---|---|---|
| `PR.PR_PKG_REPRESTAMOS` | Package body | QA02 | Helpers privados e instrumentacion por etapas. |
| `PR.PR_JOB_PRECALIFICA_TRACK` | Tabla existente | QA02 | Se conserva para tiempos y errores por paso. |

## DDL aplicado en QA02

Scripts en `01_DDL/`, reversa en `04_ROLLBACK/`. Aplicados en QA02 el
2026-06-08 mediante Toad.

| Objeto | Tipo | Uso |
|---|---|---|
| `PR.PR_JOB_PRECALIFICA_FILTRO_TRACK` | Tabla | Conteos agregados por filtro y ejecucion (Capa B). |
| `PR.SEQ_PR_JOB_PRECAL_FILTRO` | Secuencia | `ID_DETALLE` de la Capa B. |
| `PR.IX_PRECAL_FILTRO_CONSULTA` | Indice | Consulta por `(ID_EJECUCION,FLUJO,FASE,ORDEN_FILTRO)`. |
| `PR.IX_PRECAL_FILTRO_FECHA` | Indice | Soporte a purga por `FECHA_REGISTRO` (Capa B). |
| `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK` | Tabla | Pertenencia real de candidatos a flujo y lote (Capa C). |
| `PR.IX_PRECAL_CAND_FECHA` | Indice | Soporte a purga por `FECHA_REGISTRO`. |
| `TRACK_PRECALIFICA_ACTIVO` / `_DETALLE_CURSOR` / `_RETENCION_DIAS` | Parametros | Filas en `PA.PA_PARAMETROS_MVP` (`CODIGO_MVP='REPRESTAMOS'`). |

Validacion QA02 (2026-06-08) completa: Oracle 19c (nombres largos validos), `PR_IDX` existe,
`ID_REPRESTAMO` = `NUMBER(14)`, y `PA_PARAMETROS_MVP` exige `DES_PARAMETRO`/`ADICIONADO_POR`/`FECHA_ADICION`
(ya incluidas en el script 03). Ver detalle en `01_DDL/README.md`.

## Package body aplicado

El Incremento A del body fue compilado y probado en QA02 el 2026-06-09.
La `spec.sql` no cambio. La ejecucion controlada genero 31 metricas en
`PR.PR_JOB_PRECALIFICA_FILTRO_TRACK`.
