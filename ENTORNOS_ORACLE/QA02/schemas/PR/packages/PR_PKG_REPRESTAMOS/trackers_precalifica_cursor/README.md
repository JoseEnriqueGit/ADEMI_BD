# Trackers de Precalificacion QA02

Scripts read-only para medir cuantos candidatos descarta cada filtro de los cursores de `PR.PR_PKG_REPRESTAMOS`.

## Ejecucion

- Ejecutar un archivo a la vez.
- Recomendado en Toad: colocar el cursor en la linea `WITH params AS` o seleccionar todo el SQL del archivo y ejecutar con `F9 / Execute Statement`.
- No ejecutar con el cursor dentro del `SELECT` interno de `params`, porque algunos clientes intentan ejecutar solo esa subconsulta y devuelven `ORA-00911`.
- Los archivos no tienen terminador final para evitar `ORA-00911: invalid character` en clientes que envian el terminador directamente a Oracle.
- Si se ejecutan como script SQLPlus/Toad F5 y el cliente requiere terminador, agregar el terminador manualmente al final.

## Archivos

- `01_PRECALIFICA_REPRESTAMO_CURSOR_QA02.sql`: filtros del cursor de `Precalifica_Represtamo`.
- `02_PRECALIFICA_REPRE_CANCELADO_CURSOR_QA02.sql`: filtros del cursor de `Precalifica_Repre_Cancelado`.
- `03_PRECALIFICA_REPRE_CANCELADO_HI_CURSOR_QA02.sql`: filtros del cursor de `Precalifica_Repre_Cancelado_hi`.
- `04_PRECALIFICA_REPRESTAMO_FIADORES_CURSOR_QA02.sql`: filtros del cursor de `Precalifica_Represtamo_fiadores`.
- `05_PRECALIFICA_REPRESTAMO_FIADORES_HI_CURSOR_QA02.sql`: filtros del cursor de `Precalifica_Represtamo_fiadores_hi`.

## Alcance

Estos scripts no insertan, actualizan ni eliminan datos. Solo cuentan candidatos por filtro observable del cursor.
