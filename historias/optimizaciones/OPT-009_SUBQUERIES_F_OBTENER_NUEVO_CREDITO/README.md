# OPT-009 - Subqueries escalares en F_OBTENER_NUEVO_CREDITO

- **Paquete**: PR_PKG_REPRESTAMOS
- **Funcion**: F_Obtener_Nuevo_Credito (lineas 9678-9760)
- **Entorno**: QA
- **Fecha**: 2026-03-25
- **SQL Quest**: SQL 385/386/391/392 (cost ~17,235)

## Problema
La rama ELSE de la funcion (represtamos normales, no de campana) tenia un SELECT
con un scalar subquery que contenia 3 subqueries anidadas mas:

1. `IN (SELECT ... WHERE CREDITO_FMO = 'S')` — verificar si el origen es FMO
2. `NOT IN (SELECT ... WHERE CREDITO_FMO = 'S')` — excluir destinos FMO
3. `EXISTS (SELECT 1 ... WHERE OBSOLETO = 0 AND CREDITO_CAMPANA_ESPECIAL <> 'S')` — vigente sin campana

Las subqueries 1 y 2 consultaban la misma tabla con el mismo filtro.
Ademas, el scalar subquery se ejecuta por cada fila del query externo.

## Cambios realizados (3 fases)

### Fase 1 (ya aplicada): MIN/MAX -> JOIN con BETWEEN en rama IF
Reemplazado scalar subqueries MIN(MONTO_MIN)/MAX(MONTO_MAX) con JOIN directo.

### Fase 2 (ya aplicada): OR -> COALESCE en LEFT JOIN
```sql
-- ANTES: LEFT JOIN PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
-- DESPUES: LEFT JOIN PR_TIPO_CREDITO T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
```

### Fase 3 (nueva): Eliminar scalar subquery completo y 3 subqueries anidadas
Reemplazado el SELECT con scalar subquery por un SELECT directo con JOINs:

- Scalar subquery eliminado -> SELECT MIN(NT.TIPO_CREDITO) INTO directo
- Subquery 1 (FMO origen) -> LEFT JOIN a PR_TIPO_CREDITO_REPRESTAMO FMO
- Subquery 2 (excluir FMO destino) -> JOIN con condicion NVL(RV.CREDITO_FMO,'N') <> 'S'
- Subquery 3 (vigente sin campana) -> JOIN con condiciones OBSOLETO=0 y CAMPANA<>'S'

Ver BEFORE.sql y AFTER.sql para el codigo exacto.

## Razonamiento
- 3 subqueries IN/NOT IN/EXISTS reemplazadas con JOINs directos
- Oracle puede resolver todo en un solo plan de ejecucion sin scalar subquery re-execution
- La regla de FACILIDAD (si origen es FMO se ignora) se implementa con LEFT JOIN + IS NOT NULL

## Como revertir
Compilar rollback.sql en Toad o: `git revert <commit>`
