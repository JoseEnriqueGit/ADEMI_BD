# inc_snapshot_too_old_opt019

## Cuando usarlo
Cuando quieras continuar el incidente `INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO`
despues de OPT-017 y OPT-018, evaluando una posible OPT-019 enfocada en
staging/GTT o en una revision mas profunda de `P_Generar_Bitacora` y
`P_Validar_Cambio_Estado`.

## Prompt listo
```text
Estoy retomando el incidente INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO.

Trabaja en espanol y sigue AGENTS.md. Usa como fuente de verdad:

- docs/instrucciones_ai/BASE_OPERATIVA.md
- historias/incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/HANDOFF_SESION_NUEVA.md
- historias/incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/README.md
- historias/incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/bitacora_resolucion.md
- historias/incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/EXPLICACION_PROBLEMA_Y_SOLUCION.md
- historias/optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md
- historias/optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/BEFORE.sql
- historias/optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/AFTER.sql
- historias/optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/ROLLBACK.sql
- historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/README.md
- historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/BEFORE.sql
- historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/AFTER.sql
- historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/ROLLBACK.sql

Entorno objetivo: DESARROLLO.

Package objetivo:
ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/

Contexto:
- OPT-017 ya fue aplicada en `P_REGISTRO_SOLICITUD`.
- OPT-018 ya fue aplicada en `P_Carga_Precalifica_Cancelado`.
- Ambas correcciones cargan IDs con `BULK COLLECT`, cierran cursor y luego procesan la coleccion.
- El commit de cierre de OPT-018 es `ff86bbf optimiza cursor final de precalifica cancelado`.
- No quiero reproducir `ORA-01555`.
- No mezclar OPT-004/010/015 con este analisis.
- No modificar `spec.sql` salvo que sea estrictamente necesario y me consultes antes.
- Mantener la logica de negocio igual.

Nuevo objetivo:
Evaluar si conviene una OPT-019. La OPT-019 debe enfocarse solo en una de estas rutas, o concluir que no conviene tocar codigo todavia:

1. Staging/GTT para congelar IDs si el volumen de `PR_REPRESTAMOS WHERE ESTADO = 'RE'` escala mas alla de lo razonable para `BULK COLLECT` en memoria.
2. Revision profunda de `P_Generar_Bitacora` y `P_Validar_Cambio_Estado` para reducir riesgos de commits internos, transacciones autonomas o efectos colaterales sobre `PR_REPRESTAMOS`.
3. No implementar OPT-019 por ahora y limitarse a validacion/monitoreo si el riesgo residual no justifica mas cambios.

Reglas:
- Lee completo `spec.sql` y `body.sql` antes de concluir.
- Revisa especificamente `P_REGISTRO_SOLICITUD`, `P_Carga_Precalifica_Cancelado`, `P_Generar_Bitacora` y `P_Validar_Cambio_Estado`.
- Revisa tambien cualquier llamada relevante a `P_Generar_Bitacora` dentro del flujo de `JOB_PRECALIFICA_REPRESTAMO`.
- Primero diagnostica y propone; no apliques cambios sin mi aprobacion.
- Cita siempre archivo + lineas exactas.
- Si falta una dependencia, pidemela antes de asumir. Dependencias probables: DDL de tablas, indices, datos de volumen real, configuracion UNDO, definicion de estados en `PR_ESTADOS_REPRESTAMO`.
- No proponer `LIMIT` dentro de un cursor que mantenga el cursor abierto mientras haya commits internos, salvo que expliques como evitas reintroducir el patron riesgoso.
- Diferencia claramente entre hallazgos confirmados por codigo y supuestos que requieren validacion en base de datos.

Entregable esperado:
1. Diagnostico corto del riesgo residual despues de OPT-017/OPT-018.
2. Comparacion de alternativas para OPT-019: staging/GTT vs refactor de bitacora/estado vs solo monitoreo.
3. Recomendacion priorizada con impacto, riesgo, esfuerzo y prerequisitos.
4. Lista de dependencias faltantes, si aplica.
5. Plan de validacion en Toad/QA sin reproducir `ORA-01555`.
6. Si recomiendas implementar, propone los artefactos `ANTES.sql`, `DESPUES.sql`, `BEFORE.sql`, `AFTER.sql`, `ROLLBACK.sql` que deberian crearse, pero no los crees hasta que yo apruebe.
```
