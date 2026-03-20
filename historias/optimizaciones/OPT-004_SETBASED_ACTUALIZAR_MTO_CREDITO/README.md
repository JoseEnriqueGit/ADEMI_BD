# OPT-004 - Convertir loop row-by-row a UPDATE set-based

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Seccion**: Loop Actualizar_Mto_Credito_Actual (lineas ~2704-2731)
- **Entorno**: QA
- **Fecha**: 2026-03-19

## Problema
El loop FOR recorria cada represtamo en estado 'RE' y ejecutaba 2 UPDATEs por fila:
1. UPDATE MTO_CREDITO_ACTUAL con subquery a PA_DETALLADO_DE08
2. UPDATE ESTADO = 'RSB' si CALIFICA_CLIENTE no cumple

Con N registros: N iteraciones * 2 UPDATEs = 2N sentencias SQL + context switches.

## Cambio realizado
Reemplazar el loop completo con 2 UPDATEs set-based directos:

```sql
-- UPDATE 1: Actualizar MTO_CREDITO_ACTUAL para TODOS los RE de una vez
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado FROM PA_DETALLADO_DE08 D ...)
WHERE R.ESTADO = 'RE';

-- UPDATE 2: Marcar RSB los que no cumplen clasificacion
UPDATE PR_REPRESTAMOS R SET R.ESTADO = 'RSB'
WHERE R.ESTADO = 'RE' AND EXISTS (SELECT 1 FROM PA_DETALLADO_DE08 D WHERE ...);
```

## Razonamiento
- Un UPDATE set-based se ejecuta como una sola operacion SQL optimizada por Oracle
- Elimina N context switches PL/SQL-to-SQL
- Oracle puede optimizar el plan de ejecucion para procesar todas las filas de una vez
- El segundo UPDATE usa EXISTS en vez de subquery escalar (= del cursor) para mejor semantica

## Como revertir
`git revert <commit>`
