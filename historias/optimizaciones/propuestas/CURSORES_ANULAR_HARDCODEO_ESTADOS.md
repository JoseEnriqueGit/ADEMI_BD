# Propuesta: Hardcodeo de estados en 3 cursores de P_Anular_Represtamos_Inactivos

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: P_Anular_Represtamos_Inactivos (linea 9368)
- **Job**: JOB_ACTUALIZAR_ANULAR_RD (mensual, dia 1 a las 00:00:01)
- **Entorno**: QA
- **Fecha analisis**: 2026-04-07

## Contexto

El job mensual JOB_ACTUALIZAR_ANULAR_RD ejecuta:
```
JOB_ACTUALIZAR_ANULAR_RD
└── P_ACTUALIZAR_ANULAR_REPRESTAMO
    └── P_ANULAR_REPRESTAMOS_INACTIVOS
        ├── CUR_Anular_creditos_cancelados  (SQL 371, propuesta separada)
        ├── CUR_Anular
        └── CUR_Anular_campana_especiales
```

Los 3 cursores usan `TABLE(F_Obt_Valor_Parametros(...))` para filtrar estados,
lo que fuerza TABLE ACCESS FULL sobre PR_REPRESTAMOS porque Oracle no puede
usar indices con colecciones PL/SQL.

## Resultados medidos (Explain Plan en Toad)

### CUR_Anular (linea 9372)
| Version | Cost | Plan |
|---------|------|------|
| ANTES (TABLE function) | **953** | HASH JOIN SEMI + TABLE ACCESS FULL PR_REPRESTAMOS (8,910 filas) |
| DESPUES (hardcodeo) | **18** | INLIST ITERATOR + INDEX RANGE SCAN IND02_PR_REPRESTAMOS |

### CUR_Anular_campana_especiales (linea 9383)
| Version | Cost | Plan |
|---------|------|------|
| ANTES (TABLE function) | **997** | HASH JOIN RIGHT SEMI + TABLE ACCESS FULL PR_REPRESTAMOS (8,090 filas) |
| DESPUES (hardcodeo) | **18** | INLIST ITERATOR + INDEX RANGE SCAN IND02_PR_REPRESTAMOS |

### CUR_Anular_creditos_cancelados (SQL 371, propuesta separada)
| Version | Cost | Plan |
|---------|------|------|
| ANTES (TABLE function) | **9,748** | Documentado en SQL371_HARDCODEO_ESTADOS.md |
| DESPUES (hardcodeo) | **26** | Documentado en SQL371_HARDCODEO_ESTADOS.md |

### Impacto total del job mensual
| Metrica | ANTES | DESPUES | Reduccion |
|---------|-------|---------|-----------|
| Cost combinado | **11,698** | **62** | **-99.5%** |

## Alternativas evaluadas (descartadas)

### 1. Subquery directa a PA_PARAMETROS_MVP con REGEXP_SUBSTR + CONNECT BY
```sql
AND ESTADO IN (
  SELECT TRIM(REGEXP_SUBSTR(p.VALOR, '[^,]+', 1, LEVEL))
  FROM PA.PA_PARAMETROS_MVP p
  WHERE p.CODIGO_MVP = 'REPRESTAMOS'
    AND p.CODIGO_PARAMETRO = 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO'
  CONNECT BY LEVEL <= REGEXP_COUNT(p.VALOR, ',') + 1
    AND PRIOR p.CODIGO_PARAMETRO = p.CODIGO_PARAMETRO
    AND PRIOR SYS_GUID() IS NOT NULL
)
```
**Resultado**: Cost **929**. Oracle estima cardinalidad 100 para el CONNECT BY y elige HASH JOIN + FULL TABLE SCAN. No mejora.

### 2. Hint CARDINALITY sobre TABLE(funcion)
```sql
AND ESTADO IN (SELECT /*+ CARDINALITY(t 17) */ COLUMN_VALUE
               FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')) t)
```
**Resultado**: Cost **952**. El hint corrige la cardinalidad de la collection a 17, pero Oracle sigue prefiriendo FULL TABLE SCAN porque con 17 estados estima demasiadas filas en PR_REPRESTAMOS.

### 3. Otras alternativas investigadas (no probadas)
- **RESULT_CACHE**: No resuelve el problema de indices — solo cachea la ejecucion de la funcion
- **Global Temporary Table**: Sobredimensionado para este caso
- **Materialized View**: Requiere refresh manual, riesgo de desincronizacion
- **SQL Plan Baseline**: Fragil, se rompe si cambian estadisticas

### Conclusion de alternativas
**Ninguna alternativa iguala el rendimiento del hardcodeo.** Oracle solo puede hacer INLIST ITERATOR (el plan optimo) con valores literales en el IN clause. Con TABLE(), subqueries o hints, siempre elige HASH JOIN + FULL TABLE SCAN.

## Cambio propuesto

### CUR_Anular — ANTES:
```sql
CURSOR CUR_Anular IS
    SELECT id_represtamo
    FROM PR_REPRESTAMOS
    WHERE codigo_empresa = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
    AND id_represtamo = NVL(pIdReprestamo, id_represtamo)
    AND ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
    AND TRUNC(FECHA_proceso) <= TRUNC(SYSDATE)
    AND TRUNC(LAST_DAY(FECHA_proceso)) <= TRUNC(SYSDATE);
```

### CUR_Anular — DESPUES:
```sql
CURSOR CUR_Anular IS
    SELECT id_represtamo
    FROM PR_REPRESTAMOS
    WHERE codigo_empresa = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
    AND id_represtamo = NVL(pIdReprestamo, id_represtamo)
    AND ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','EP','AP','MS','AYN','AYS','BLI','BLP','CP','SC')
    -- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO
    -- Si cambian los parametros, actualizar esta lista manualmente
    AND TRUNC(FECHA_proceso) <= TRUNC(SYSDATE)
    AND TRUNC(LAST_DAY(FECHA_proceso)) <= TRUNC(SYSDATE);
```

### CUR_Anular_campana_especiales — ANTES:
```sql
CURSOR CUR_Anular_campana_especiales IS
    SELECT id_represtamo
    FROM PR_REPRESTAMOS
    WHERE codigo_empresa = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
    AND id_represtamo = NVL(pIdReprestamo, id_represtamo)
    AND ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
    AND TRUNC(FECHA_proceso) + PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK_CANCELADOS') <= TRUNC(SYSDATE);
```

### CUR_Anular_campana_especiales — DESPUES:
```sql
CURSOR CUR_Anular_campana_especiales IS
    SELECT id_represtamo
    FROM PR_REPRESTAMOS
    WHERE codigo_empresa = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
    AND id_represtamo = NVL(pIdReprestamo, id_represtamo)
    AND ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','EP','AP','MS','AYN','AYS','BLI','BLP','CP','SC')
    -- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO
    -- Si cambian los parametros, actualizar esta lista manualmente
    AND TRUNC(FECHA_proceso) + PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK_CANCELADOS') <= TRUNC(SYSDATE);
```

## Valores actuales del parametro
**ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO**: RE,NP,VR,MS,NR,LA,AEP,AYR,EP,AP,MS,AYN,AYS,BLI,BLP,CP,SC

## Trade-off

**Beneficio**: Reduccion del 98% en cost (953/997 → 18)

**Riesgo**: Si los valores del parametro cambian en PA_PARAMETROS_MVP,
hay que actualizar el codigo de los cursores manualmente. Con la version actual,
los cambios se reflejan automaticamente.

**Mitigacion**:
- Agregar comentarios en los cursores indicando el parametro de origen
- Documentar en el CHANGELOG del paquete que estos valores estan hardcodeados
- Cuando se modifique el parametro, incluir la recompilacion del paquete en el cambio

## Decision

**Pendiente de aprobacion.** Mismo trade-off que SQL 371.
Si SQL 371 se aprueba, estos 2 cursores deberian aprobarse tambien
(mismo parametro, mismo patron, mismo job).

## Rollback

Restaurar los cursores originales con TABLE(F_Obt_Valor_Parametros(...)).
No hay indices que eliminar.
