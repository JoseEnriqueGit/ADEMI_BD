# IRD-525 - Inclusion de trazabilidad en Gestion de Estados

## Objetivo

Agregar al reporte de la pagina 112 de APEX las columnas:

- Usuario que modifico
- Fecha de modificacion
- Comentario de la modificacion

## Fuente de datos

La trazabilidad se toma de `PR.PR_BITACORA_REPRESTAMO`:

- `ADICIONADO_POR` como usuario que modifico
- `FECHA_ADICION` como fecha de modificacion
- `OBSERVACIONES` como comentario de la modificacion

## Scripts

- `scripts/00_QUERY_APEX_ANTES_PEGAR_AQUI.sql`: respaldo del SQL actual del reporte APEX.
- `scripts/01_QUERY_APEX_DESPUES.sql`: SQL propuesto para el reporte con columnas de trazabilidad.
- `scripts/02_VALIDACION_QA.sql`: consulta de validacion para Toad/SQL Workshop.
- `RESULTADOS_QA.md`: resultado observado en Toad y APEX.

## Implementacion

El SQL del reporte mantiene la estructura original:

- `PA.OBT_NOMBRE_PERSONA(R.CODIGO_CLIENTE)` para mostrar el nombre.
- Link HTML de `ACTUALIZAR_ESTADO` con `APEX_PAGE.GET_URL` hacia pagina 130.
- Filtro por `LISTA_ESTADOS_REPRESTAMOS_VISUALIZAR`.
- Filtro `:P112_BUSQUEDA` por lista de `ID_REPRESTAMO`.

El cambio agrega un `LEFT JOIN` a la ultima bitacora del estado actual del represtamo usando `ROW_NUMBER()` sobre `PR.PR_BITACORA_REPRESTAMO`.

## Validacion

Validado en QA:

- En Toad, el SQL devuelve las columnas nuevas y ordena primero registros con `FECHA_MODIFICACION`.
- En APEX, el reporte muestra correctamente usuario, fecha y comentario.
- Para que el orden inicial respete los nulos al final, se removio el sort guardado del Interactive Report sobre `Fecha Modificacion` desde `Actions > Data > Sort`.

## Rollback

Para reversar en APEX Builder, volver a colocar el contenido respaldado en `scripts/00_QUERY_APEX_ANTES_PEGAR_AQUI.sql` como SQL Source del reporte.
