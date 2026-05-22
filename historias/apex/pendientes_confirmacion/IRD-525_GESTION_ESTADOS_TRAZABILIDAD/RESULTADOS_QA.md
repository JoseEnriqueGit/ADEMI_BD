# Resultados QA - IRD-525

## Entorno

- Entorno: QA
- Aplicacion APEX: 106
- Pagina APEX: 112
- Fecha: 2026-05-22

## Validacion ejecutada

1. Se confirmo en QA que al modificar un represtamo desde APEX el comentario queda registrado en `PR.PR_BITACORA_REPRESTAMO.OBSERVACIONES`.
2. Se ejecuto el SQL nuevo en Toad y retorno correctamente:
   - `USUARIO_QUE_MODIFICO`
   - `FECHA_MODIFICACION`
   - `COMENTARIO_MODIFICACION`
3. Se aplico el SQL en APEX y se verifico que el link de `ACTUALIZAR_ESTADO` siguiera renderizando el icono de lapiz.
4. Se identifico que APEX mostraba nulos arriba porque el Interactive Report tenia un sort guardado sobre `Fecha Modificacion`.
5. Se removio el sort guardado desde `Actions > Data > Sort`, y el reporte quedo mostrando los registros con trazabilidad primero.

## Resultado

Validacion satisfactoria en QA.

## Riesgo residual

Si un usuario vuelve a guardar un sort descendente directo sobre `Fecha Modificacion`, APEX puede volver a colocar nulos arriba. Para mantener el comportamiento esperado, el reporte default debe quedar sin ese sort guardado o con una configuracion equivalente a nulos al final si la version de APEX lo permite.

## Rollback

Restaurar el SQL anterior desde `scripts/00_QUERY_APEX_ANTES_PEGAR_AQUI.sql` en el Source del reporte APEX.
