# OPT-005 - Simplificar Actualiza_XCORE_CUSTOM (xcore hardcodeado a 745)

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_XCORE_CUSTOM
- **Entorno**: QA
- **Fecha**: 2026-03-19

## Problema
El procedure tenia un loop doble (FOR i IN 1..vCantidad_Procesar / FOR A IN CUR_UPDATE_XCORE) que:
1. Dividía la carga en lotes
2. Hacía COMMIT por cada fila
3. Asignaba xcore := 745 (hardcodeado, la llamada real a DataCredito está comentada)

El loop doble era completamente innecesario porque el valor es constante.

## Cambio realizado
Reemplazar el loop doble completo con un unico UPDATE:
```sql
UPDATE PR_REPRESTAMOS
SET XCORE_GLOBAL = 745, XCORE_CUSTOM = 745
WHERE ESTADO = 'RE' AND XCORE_GLOBAL IS NULL;
COMMIT;
```

## Razonamiento
- xcore=745 es constante (linea 3393, la llamada a DataCredito esta comentada)
- El loop doble generaba N*M iteraciones con COMMIT por cada una
- Un UPDATE set-based hace lo mismo en una sola operacion

## NOTA IMPORTANTE
Si se reactiva la llamada a DataCredito (PA.PA_PKG_CONSULTA_DATACREDITO),
se debe revertir este cambio y restaurar el loop con la llamada real.

## Como revertir
Compilar rollback.sql en Toad o: `git revert <commit>`
