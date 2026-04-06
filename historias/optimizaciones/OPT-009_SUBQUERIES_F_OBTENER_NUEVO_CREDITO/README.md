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
