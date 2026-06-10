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

## DDL aplicado en QA02 (Incremento B, 2026-06-09)

| Objeto | Tipo | Cambio | Script |
|---|---|---|---|
| `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK` | Tabla existente | `ALTER ADD` columnas `NO_CREDITO NUMBER(7)` y `CODIGO_CLIENTE NUMBER(7)` (nullable). | `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` |

## Package body aplicado

- **Incremento A** (2026-06-09 AM): 31 metricas en `PR_JOB_PRECALIFICA_FILTRO_TRACK`.
  Ejecucion `53D427AF4F597DB0E063140311AC14C5`.
- **Incremento B** (2026-06-09 PM): helper `track_candidato` + cohorte individual del
  cierre en `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (`FLUJO='CIERRE'`). Ejecucion
  `53D8BBE0BA0E44D9E063140311AC6BC6`, 1302/1302 conciliado.
- La `spec.sql` no cambio en ningun incremento.

- **Incremento C** (2026-06-09, variante procedures): estado package-private
  `g_track_*` + helper `track_candidatos_flujo` + captura del bruto insertado tras
  el `FORALL INSERT` de las 5 procedures de flujo (Carga_Dirigida y
  Campana_Especiales NO se instrumentan). Sin DDL nuevo. Ejecucion
  `53DAC2820BDC0E55E063140311AC3EBA`: 1834 filas de pertenencia, 0 huerfanos.
