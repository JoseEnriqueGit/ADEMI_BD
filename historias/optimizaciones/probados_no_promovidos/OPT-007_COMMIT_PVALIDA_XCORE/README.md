# OPT-007: Mover COMMIT fuera del loop en PVALIDA_XCORE

## Objeto
- **Paquete:** PR.PR_PKG_REPRESTAMOS
- **Procedimiento:** PVALIDA_XCORE
- **Entorno:** QA
- **Linea aproximada:** ~3734 (body.sql)
- **Git commit:** e13ee50

## Problema
El procedimiento `PVALIDA_XCORE` ejecuta un `COMMIT` dentro del `FOR cliente IN c_clientes LOOP` (linea 3734). Cada iteracion del cursor genera un flush de redo log al disco, lo cual:

1. **Multiplica las escrituras a disco** por la cantidad de registros en el cursor (N commits en lugar de 1).
2. **Rompe la atomicidad** de la operacion: si el proceso falla a mitad, quedan registros parcialmente procesados sin posibilidad de rollback completo.
3. **Genera contention en redo log** que afecta a otros procesos concurrentes.

## Solucion
Mover el `COMMIT` a despues del `END LOOP`, consolidando todas las operaciones DML en una sola transaccion.

## Impacto
- **Antes:** N commits (1 por cada fila del cursor `c_clientes` con ESTADO='RE')
- **Despues:** 1 commit al finalizar todo el loop
- **Reduccion estimada:** ~99% menos flushes de redo log
- **Atomicidad:** Si el proceso falla, se hace rollback completo de todos los cambios

## Riesgo
- Bajo. El volumen de DML dentro del loop es moderado (UPDATEs puntuales por NO_CREDITO).
- Si el volumen de registros fuera muy alto (>100k), se podria considerar commit cada N registros, pero para el caso actual no es necesario.

## Archivos
- `BEFORE.sql` - Codigo original con COMMIT dentro del loop
- `AFTER.sql` - Codigo optimizado con COMMIT despues del loop
- `rollback.sql` - Instrucciones para revertir al codigo original
