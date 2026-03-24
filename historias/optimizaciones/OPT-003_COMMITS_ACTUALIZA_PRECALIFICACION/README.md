# OPT-003 - COMMITs dentro de loops en Actualiza_Precalificacion

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Entorno**: QA
- **Fecha**: 2026-03-19
- **Tipo**: Cambio estructural (redo log I/O, no cost SQL)
- **Git commit**: 837fa2b

## Problema
Tres loops tenian COMMIT dentro de cada iteracion, causando un flush del redo log buffer por cada fila procesada. Con un lote de 200 registros, eran 800+ escrituras sincronas al disco.

## Cambios realizados

| Loop | COMMITs antes | COMMITs despues | Lineas afectadas |
|------|--------------|-----------------|------------------|
| Actualizar_Mto_Credito_Actual | 2 por iteracion | 1 al final | 2723, 2730 |
| PRECALIFICADOS | 1 por iteracion | 1 al final | 2744 |
| CUR_FIADOR | 1 por iteracion | 1 al final | 2776 |

Ver BEFORE.sql y AFTER.sql para el codigo exacto.

## Razonamiento
Cada COMMIT fuerza una escritura sincrona al disco (redo log flush).
- ANTES: 4N escrituras por ejecucion (N = filas en estado 'RE')
- DESPUES: 3 escrituras por ejecucion (1 por loop)

El unico trade-off es que si el proceso falla a mitad de un loop, se hace rollback del loop completo en vez de conservar las filas ya procesadas. Pero el procedure tiene EXCEPTION con logging, asi que las filas fallidas se registran y el lote se puede reprocesar.

## Como verificar
No se puede medir con Explain Plan. Se valida comparando:
- Tiempo de ejecucion del procedure completo (ANTES vs DESPUES)
- Cantidad de redo log generado (V$MYSTAT con statistic# = redo size)

## Como revertir
Compilar rollback.sql en Toad (restaura COMMITs dentro de loops)
O en git: `git revert 837fa2b`
