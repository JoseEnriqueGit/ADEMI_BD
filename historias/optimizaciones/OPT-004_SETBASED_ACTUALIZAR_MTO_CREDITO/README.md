# OPT-004 - Convertir loop row-by-row a UPDATE set-based

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Seccion**: Loop Actualizar_Mto_Credito_Actual (lineas ~2704-2731 originales)
- **Entorno**: QA
- **Fecha**: 2026-03-24
- **Tipo**: Cambio estructural (eliminar cursor FOR loop)

## Problema
El cursor `Actualizar_Mto_Credito_Actual` seleccionaba todos los PR_REPRESTAMOS con ESTADO='RE'
y luego en un FOR loop ejecutaba 2 UPDATEs por cada fila:
1. UPDATE MTO_CREDITO_ACTUAL con subquery correlacionada a PA_DETALLADO_DE08 (monto_desembolsado)
2. UPDATE ESTADO='RSB' si CALIFICA_CLIENTE no cumple con la clasificacion SIB

Con N registros: N iteraciones x 2 UPDATEs = 2N sentencias SQL + N context switches PL/SQL-to-SQL.

## Cambio realizado
Reemplazar el FOR loop completo con 2 sentencias UPDATE directas (set-based):

### UPDATE 1: Actualizar monto credito actual
Actualiza MTO_CREDITO_ACTUAL para todos los represtamos en estado 'RE' de una sola vez,
usando subquery correlacionada para obtener el monto_desembolsado de la ultima fecha de corte.

### UPDATE 2: Marcar como RSB
Cambia ESTADO a 'RSB' para los que no cumplen clasificacion SIB,
usando EXISTS en vez del subquery escalar del cursor original.

Ver BEFORE.sql y AFTER.sql para el codigo exacto.

## Razonamiento
- ANTES: N iteraciones x 2 UPDATEs = 2N sentencias SQL + N context switches
- DESPUES: 2 sentencias SQL, 0 context switches, 1 COMMIT
- Oracle optimiza el UPDATE set-based internamente con batch processing
- El cursor Actualizar_Mto_Credito_Actual ya no se usa (codigo muerto eliminado)

## Como verificar
```sql
-- Contar antes de ejecutar
SELECT COUNT(*) FROM PR_REPRESTAMOS WHERE ESTADO = 'RE';
-- Ejecutar el procedure
-- Contar despues: debe ser igual o menor (los RSB se restaron)
SELECT COUNT(*) FROM PR_REPRESTAMOS WHERE ESTADO IN ('RE','RSB');
```

## Como revertir
Compilar rollback.sql en Toad (restaura el FOR loop original con cursor)
O en git: buscar el commit de OPT-004 y hacer `git revert <hash>`
