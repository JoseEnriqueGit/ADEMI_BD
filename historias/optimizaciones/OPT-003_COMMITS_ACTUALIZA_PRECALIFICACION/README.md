# OPT-003 - COMMITs dentro de loops en Actualiza_Precalificacion

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Entorno**: QA
- **Fecha**: 2026-03-19

## Problema
Tres loops tenian COMMIT dentro de cada iteracion, causando un flush del redo log buffer por cada fila procesada.

## Cambios realizados

### Loop 1: Actualizar_Mto_Credito_Actual (lineas 2723, 2730)
- Dos COMMITs por iteracion eliminados
- Un solo COMMIT despues del END LOOP

### Loop 2: PRECALIFICADOS (linea 2744)
- COMMIT por iteracion eliminado
- Un solo COMMIT despues del END LOOP

### Loop 3: CUR_FIADOR (linea 2776)
- COMMIT por iteracion eliminado
- Un solo COMMIT despues del END LOOP

## Razonamiento
Cada COMMIT fuerza una escritura sincrona al disco (redo log flush). Con N registros, se generaban 4N+ escrituras. Ahora son 3 escrituras totales (una por loop).

## Como revertir
Compilar rollback.sql en Toad o: `git revert <commit>`
