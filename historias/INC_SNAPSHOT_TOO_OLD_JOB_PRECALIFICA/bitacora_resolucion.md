# Bitacora de resolucion - INC SNAPSHOT TOO OLD

| Fecha | Accion | Responsable | Resultado |
|-------|--------|-------------|-----------|
| 2026-05-01 | Equipo de BD reporta `ORA-01555` en el job `PR.JOB_PRECALIFICA_REPRESTAMO` | DBA | Incidente abierto |
| 2026-05-01 | Se revisa el trace: SQL sobre `PR_REPRESTAMOS WHERE ESTADO='RE'`, duracion ~3,632 seg, `UNDO_RETENTION` reportado ~1,500 seg | DBA / Desarrollo | Evidencia productiva recibida |
| 2026-05-01 | Se identifica inicialmente un plan asociado a OPT-004/010/015/016 | Desarrollo | Plan descartado como causa directa del incidente |
| 2026-05-05 | Se verifica en codigo que `P_REGISTRO_SOLICITUD` mantiene cursor abierto y dentro llama procesos con commits/transacciones autonomas | Desarrollo | Diagnostico tecnico corregido |
| 2026-05-05 | Se confirma que `P_Generar_Bitacora` llama `P_Validar_Cambio_Estado`, que actualiza `PR_REPRESTAMOS` en transaccion autonoma | Desarrollo | Principal sospechoso aceptado por el equipo backend |
| 2026-05-05 | Se descarta preparar scripts para replicar el error en QA/DEV | Desarrollo | La validacion se basara en evidencia PROD, lectura de codigo y monitoreo posterior |
| 2026-05-05 | Se actualiza la documentacion del incidente y se crea handoff para una sesion limpia | Desarrollo | Documentado |
| 2026-05-05 | Se implementa OPT-017 en `DESARROLLO` con variante minima: `BULK COLLECT` solo de `ID_REPRESTAMO`, cierre del cursor y loop posterior sobre coleccion | Desarrollo | Implementado en repo y colocado en Toad |
| 2026-05-05 | Se documenta OPT-017 con procedimiento completo antes, despues y rollback | Desarrollo | Documentado en `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/` |
| 2026-05-05 | Se evalua warning de Toad por `BULK COLLECT` sin `LIMIT` | Desarrollo | Aceptado para volumen actual de 5,000 a 10,000 IDs; si escala mucho, evaluar staging/GTT |
| Pendiente | Validar en PROD `UNDO_RETENTION`, presion/tamano de UNDO y volumen real de `ESTADO='RE'` | DBA | Pendiente |
| Pendiente | Confirmar `IND_CAMBIA_ESTADO_REPRE='S'` para `CODIGO_ESTADO='RE'` | DBA / Desarrollo | Pendiente |
| Pendiente | Compilar y validar en QA como regresion basica, no como reproduccion del `ORA-01555` | Desarrollo / DBA | Pendiente |
| Pendiente | Analizar `P_Generar_Bitacora` y `P_Validar_Cambio_Estado` en una sesion separada para evaluar refactorizacion adicional | Desarrollo | Pendiente |
| Pendiente | Coordinar pase a PROD y monitorear la corrida del 2026-06-01 | Desarrollo / DBA | Pendiente |

## Notas

- El `SUCCEEDED` del scheduler no contradice el incidente: el error interno se
  registra/captura y el job puede continuar.
- La reproduccion en QA/DEV queda fuera del alcance por decision operativa.
- OPT-004/010/015 pueden seguir siendo mejoras generales del job, pero no son la
  correccion directa para este `ORA-01555`.
- La propuesta directa del incidente es OPT-017: `BULK COLLECT` de IDs, cierre
  inmediato del cursor y loop posterior sobre la coleccion.
