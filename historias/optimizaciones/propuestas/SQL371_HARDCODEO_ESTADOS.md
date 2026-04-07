# Propuesta: SQL 371 - Hardcodeo de estados en CUR_Anular_creditos_cancelados

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: P_Actualizar_Anular_Represtamo
- **Cursor**: CUR_Anular_creditos_cancelados (linea ~9391)
- **Entorno**: QA
- **Fecha analisis**: 2026-04-07
- **SQL Quest**: SQL 371 (cost original 10,656)

## Situacion actual (sin hardcodeo)

El cursor usa `F_Obt_Valor_Parametros` para obtener los estados dinamicamente:
```sql
AND ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_CREDITOS_CANCELADOS')))
AND NOT EXISTS (SELECT 1 FROM pr_creditos
                WHERE no_credito = a.no_credito
                AND estado IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_CREDITOS'))))
```

**Cost actual**: 9,748 (con indices de OPT-009/010 ya creados)

Oracle no puede usar indices eficientemente porque los filtros de estado dependen de funciones TABLE que devuelven collections.

## Propuesta (con hardcodeo)

Reemplazar las funciones TABLE con los valores directos:
```sql
AND ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','CP')
AND NOT EXISTS (SELECT 1 FROM pr_creditos
                WHERE no_credito = a.no_credito
                AND estado IN ('D','V','M','E','J','C'))
```

**Cost propuesto**: 26

## Resultados verificados (Explain Plan en Toad)

| Metrica | Actual (funciones TABLE) | Propuesto (hardcodeado) | Mejora |
|---------|------------------------|------------------------|--------|
| Cost total | 9,748 | 26 | -99.7% |
| PR_REPRESTAMOS | IDX 192 | IDX RANGE 11 | -94.3% |
| PR_CREDITOS | IDX FFS 879 | IDX SKIP 3 | -99.7% |
| Tipo de JOIN | HASH JOIN ANTI | NESTED LOOPS ANTI | Optimo |

## Scripts para Explain Plan

### ACTUAL (con funciones TABLE):
```sql
SELECT /* SQL371-ACTUAL */ id_represtamo, no_credito
  FROM PR_REPRESTAMOS a
 WHERE codigo_empresa = 1
   AND ESTADO in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_CREDITOS_CANCELADOS')))
   AND not exists (select 1
                     from pr_creditos
                    where no_credito = a.no_credito
                      and estado in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ANULAR_CREDITOS'))))
   AND not exists (select 1
                     from pr_creditos_hi h
                    where h.no_credito = a.no_credito
                      and h.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                      and h.F_CANCELACION <= SYSDATE
                      and h.estado = 'C');
```

### PROPUESTO (con valores hardcodeados):
```sql
SELECT /* SQL371-PROPUESTO */ id_represtamo, no_credito
  FROM PR_REPRESTAMOS a
 WHERE codigo_empresa = 1
   AND ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','CP')
   AND NOT EXISTS (SELECT 1
                     FROM pr_creditos c
                    WHERE c.no_credito = a.no_credito
                      AND c.estado IN ('D','V','M','E','J','C'))
   AND NOT EXISTS (SELECT 1
                     FROM pr_creditos_hi h
                    WHERE h.no_credito = a.no_credito
                      AND h.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                      AND h.F_CANCELACION <= SYSDATE
                      AND h.estado = 'C');
```

## Valores actuales de los parametros

**ESTADOS_ANULAR_CREDITOS**: D, V, M, E, J, C
**ESTADOS_ANULAR_CREDITOS_CANCELADOS**: RE, NP, VR, MS, NR, LA, AEP, AYR, CP

## Trade-off

**Beneficio**: Reduccion de cost del 99.7% (9,748 a 26)

**Riesgo**: Si los valores de los parametros cambian en la tabla de configuracion,
hay que actualizar el codigo del cursor manualmente. Con la version actual (funciones TABLE),
los cambios en parametros se reflejan automaticamente.

**Mitigacion**: Agregar un comentario en el cursor indicando de donde vienen los valores
y que deben sincronizarse si cambian los parametros.

## Decision

**Pendiente de aprobacion.** Presentar a jefe para evaluar si el trade-off es aceptable.
