# Notas sobre el lote de représtamos

## ¿Quién llama a quién?

El job `P_CARGA_PRECALIFICA_CANCELADO` ejecuta varias rutinas una tras otra:

1. `Precalifica_Represtamo`
2. `Precalifica_Represtamo_fiadores`
3. `Precalifica_Represtamo_fiadores_hi`
4. `Precalifica_Repre_Cancelado`
5. Otras tareas de actualización y registro

## ¿Dónde se usa el parámetro?

Cada rutina abre su propio cursor con `ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO`. Esto ocurre en:

- `PR_PKG_REPRESTAMOS.sql:56`
- `PR_PKG_REPRESTAMOS.sql:415`
- `PR_PKG_REPRESTAMOS.sql:797`
- `PR_PKG_REPRESTAMOS.sql:1172`
- `PR_PKG_REPRESTAMOS.sql:1523`

Por eso cada etapa procesa, como máximo, ese número de registros.

## ¿Por qué el total supera el límite?

El límite se respeta por etapa, pero no existe un tope global. Si cada rutina trae 10 registros, el job completo puede terminar con 40, 50 o más (suma de todas las etapas).

## ¿Cómo imponer un tope global?

Agregar un contador compartido:

- Inicializar `g_cupo_disponible` con el valor del parámetro al iniciar el job.
- Antes de cada `FETCH`, limitar con `LEAST(g_cupo_disponible, ...)`.
- Restar el número de filas insertadas y salir cuando el contador llegue a cero.

## ¿Cómo reducir la duración?

Basta con bajar el valor de `LOTE_DE_CARAGA_REPRESTAMO`. Cada etapa repetirá menos operaciones y, en general, la ejecución será más corta (aunque harán falta más corridas para procesar el mismo volumen).
