# OPT-009: Eliminar scalar subqueries en F_Obtener_Nuevo_Credito

## Objeto
- **Paquete:** PR.PR_PKG_REPRESTAMOS
- **Funcion:** F_Obtener_Nuevo_Credito (~linea 9688 del body.sql)
- **Seccion:** Rama ELSE (represtamo normal, no campana especial)
- **Entorno:** QA
- **Fecha:** 2026-03-25

## Estado
**APLICADO.** Indice creado en QA + cambio en body.sql aplicado.

## Problema
La rama ELSE de la funcion (represtamos normales, no de campana) tenia un SELECT
con un scalar subquery que contenia 3 subqueries anidadas:

1. `IN (SELECT ... WHERE CREDITO_FMO = 'S')` -- verificar si el origen es FMO
2. `NOT IN (SELECT ... WHERE CREDITO_FMO = 'S')` -- excluir destinos FMO
3. `EXISTS (SELECT 1 ... WHERE OBSOLETO = 0 AND CREDITO_CAMPANA_ESPECIAL <> 'S')` -- vigente sin campana

Las subqueries 1 y 2 consultaban la misma tabla con el mismo filtro.
Ademas, el scalar subquery se ejecuta por cada fila del query externo.

La tabla `PR_CREDITOS_HI` se accedia con `LEFT JOIN` sin indice en `NO_CREDITO`, forzando Full Table Scan.

**Cost original: 17,232**

## Solucion

### Fase 1: Crear indice (ya aplicado)
```sql
CREATE INDEX PR.IDX_CREDITOS_HI_NOCREDITO ON PR.PR_CREDITOS_HI(NO_CREDITO);
```

### Fase 2: Reescribir query con JOINs directos (aplicado)
- Scalar subquery eliminado -> SELECT MIN(NT.TIPO_CREDITO) INTO directo
- Subquery 1 (FMO origen) -> LEFT JOIN a PR_TIPO_CREDITO_REPRESTAMO FMO
- Subquery 2 (excluir FMO destino) -> JOIN con condicion NVL(RV.CREDITO_FMO,'N') <> 'S'
- Subquery 3 (vigente sin campana) -> JOIN con condiciones OBSOLETO=0 y CAMPANA<>'S'

## Impacto
- **Cost antes:** 17,232
- **Cost despues:** 909
- **Reduccion:** ~95%
- **Indice creado:** `PR.IDX_CREDITOS_HI_NOCREDITO ON PR.PR_CREDITOS_HI(NO_CREDITO)`

## Scripts para Explain Plan (ejecutar en Toad)

### ANTES (scalar subqueries):
```sql
SELECT (
    SELECT MIN(NT.TIPO_CREDITO)
    FROM   PR_TIPO_CREDITO                NT
    JOIN   PR_PLAZO_CREDITO_REPRESTAMO    P
         ON  P.TIPO_CREDITO = NT.TIPO_CREDITO
    WHERE R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
      AND NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
      AND NT.GRUPO_TIPO_CREDITO    = T.GRUPO_TIPO_CREDITO
      AND ( T.TIPO_CREDITO IN (SELECT TIPO_CREDITO
                               FROM   PR_TIPO_CREDITO_REPRESTAMO
                               WHERE  CREDITO_FMO = 'S')
            OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC )
      AND NT.TIPO_CREDITO NOT IN (SELECT TIPO_CREDITO
                                  FROM   PR_TIPO_CREDITO_REPRESTAMO
                                  WHERE  CREDITO_FMO = 'S')
      AND EXISTS ( SELECT 1
            FROM   PR_TIPO_CREDITO_REPRESTAMO R
            WHERE  R.TIPO_CREDITO = NT.TIPO_CREDITO
              AND  R.OBSOLETO = 0
              AND  NVL(R.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
      )
)
FROM PR_REPRESTAMOS   R
LEFT JOIN PR_CREDITOS      C ON C.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_CREDITOS_HI   H ON H.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_TIPO_CREDITO  T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
WHERE R.ID_REPRESTAMO = 1;
```

### DESPUES (JOINs directos):
```sql
SELECT MIN(NT.TIPO_CREDITO)
FROM PR_REPRESTAMOS   R
LEFT JOIN PR_CREDITOS      C ON C.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_CREDITOS_HI   H ON H.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_TIPO_CREDITO  T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
JOIN PR_TIPO_CREDITO             NT ON NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
                                    AND NT.GRUPO_TIPO_CREDITO    = T.GRUPO_TIPO_CREDITO
JOIN PR_PLAZO_CREDITO_REPRESTAMO P  ON P.TIPO_CREDITO = NT.TIPO_CREDITO
JOIN PR_TIPO_CREDITO_REPRESTAMO  RV ON RV.TIPO_CREDITO = NT.TIPO_CREDITO
                                    AND RV.OBSOLETO = 0
                                    AND NVL(RV.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
                                    AND NVL(RV.CREDITO_FMO,'N') <> 'S'
LEFT JOIN PR_TIPO_CREDITO_REPRESTAMO FMO ON FMO.TIPO_CREDITO = T.TIPO_CREDITO
                                         AND FMO.CREDITO_FMO = 'S'
WHERE R.ID_REPRESTAMO = 1
  AND R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
  AND (FMO.TIPO_CREDITO IS NOT NULL OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC);
```

---

## Riesgo
- Bajo. La query optimizada produce los mismos resultados (misma logica, solo reestructurada).
- El indice nuevo ocupa espacio adicional pero PR_CREDITOS_HI es tabla historica con inserciones infrecuentes.

## Como revertir
1. DROP INDEX PR.IDX_CREDITOS_HI_NOCREDITO;
2. Si la fase 2 fue aplicada: restaurar la funcion desde BEFORE.sql
3. Recompilar el package body

## Archivos
- `BEFORE.sql` - Funcion completa original con scalar subqueries
- `AFTER.sql` - Funcion completa optimizada con JOINs directos
- `rollback.sql` - DROP del indice e instrucciones para restaurar la funcion original
