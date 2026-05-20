# INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO

**Fecha apertura**: 2026-05-01
**Actualizado**: 2026-05-06
**Reportado por**: equipo de Base de Datos
**Job afectado**: `PR.JOB_PRECALIFICA_REPRESTAMO`
**Procedimiento orquestador**: `PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO`
**Estado**: OPT-017 y OPT-018 implementadas en `DESARROLLO`; pendiente compilacion/regresion en Toad/QA.

## Resumen

El job mensual termina con estado `SUCCEEDED`, pero el trace de produccion reporto
`ORA-01555: snapshot too old` sobre esta consulta:

```sql
SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL
FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
```

La duracion del cursor fue de aproximadamente 3,632 segundos (~60 min), mientras
que el `UNDO_RETENTION` observado en el trace fue de ~1,500 segundos (~25 min).

El equipo backend decidio tratar como principal sospechoso el patron verificado en
codigo: cursor abierto largo tiempo sobre `PR_REPRESTAMOS`, commits dentro del
loop y llamadas a transacciones autonomas que actualizan la misma tabla.

## Decision actual

No se van a crear scripts para reproducir el `ORA-01555` en QA/DEV.

Motivo: el equipo consulto la posibilidad de replicarlo y la respuesta fue que no
es viable en esos entornos. Por tanto, el plan se basa en:

- evidencia del trace de PROD;
- lectura completa del package en QA02;
- revision tecnica del patron Oracle;
- validaciones puntuales no destructivas;
- monitoreo de la siguiente corrida productiva despues del pase.

## Causa raiz propuesta

La causa raiz tecnica sigue siendo el patron `FETCH across COMMIT` en
`P_REGISTRO_SOLICITUD`.

Evidencia de codigo:

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Cursor sobre `PR_REPRESTAMOS WHERE ESTADO='RE'` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7968-7971 |
| Loop por fila con `P_Registrar_Solicitud`, `P_GENERAR_BITACORA` y `COMMIT` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8014-8020 |
| `P_Generar_Bitacora` es transaccion autonoma | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 6001-6009 |
| `P_Generar_Bitacora` llama `P_Validar_Cambio_Estado` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 6023-6026 |
| `P_Validar_Cambio_Estado` es transaccion autonoma | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 5879-5882 |
| `P_Validar_Cambio_Estado` actualiza `PR_REPRESTAMOS` y hace `COMMIT` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 5902-5914 |
| El orquestador llama `P_REGISTRO_SOLICITUD` y luego sigue clasificando estados | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8126, 8171-8186 |
| `RXT` se asigna cuando no existe solicitud con `TIPO_CREDITO` informado | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8180-8181, 9547-9557 |

## Relacion probable con RXT

Si `P_REGISTRO_SOLICITUD` falla por `ORA-01555` y el error queda registrado sin
detener el job, el orquestador puede continuar hacia la validacion final. En esa
validacion, los represtamos sin solicitud completa o sin `TIPO_CREDITO` informado
pueden caer en `RXT`.

Esto no prueba por si solo todos los casos de `RXT`, pero si conecta el error de
PROD con el sintoma observado: registros que debian pasar por la creacion de
solicitud quedan incompletos y luego son clasificados como rechazados por tipo de
credito.

## Solucion implementada en DESARROLLO

Se creo OPT-017 para refactorizar `P_REGISTRO_SOLICITUD`:

1. Hacer `BULK COLLECT` de los `ID_REPRESTAMO` candidatos.
2. Cerrar el cursor inmediatamente.
3. Iterar la coleccion en memoria.
4. Mantener las llamadas actuales a `P_Registrar_Solicitud` y `P_GENERAR_BITACORA`.

Esto elimina el cursor abierto durante una hora mientras se hacen commits y
transacciones autonomas sobre la misma tabla.

La implementacion final quedo en:

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Procedimiento `P_REGISTRO_SOLICITUD` con OPT-017 | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7907-7958 |
| `BULK COLLECT` y cierre inmediato del cursor | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7923-7925 |
| Loop posterior sobre la coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7927-7935 |
| Documentacion OPT-017 | `historias/optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md` | 1-60 |

## Optimizacion adicional implementada en DESARROLLO

Se creo OPT-018 para reducir el riesgo restante detectado despues de OPT-017:
el cursor final de `P_Carga_Precalifica_Cancelado` volvia a leer
`PR_REPRESTAMOS WHERE ESTADO='RE'` y dentro del loop ejecutaba
`P_Generar_Bitacora`, que puede actualizar `PR_REPRESTAMOS` por medio de
`P_Validar_Cambio_Estado`.

La solucion aplicada mantiene la logica de clasificacion `NP/RXT/CP/AN`, pero
carga los candidatos finales con `BULK COLLECT`, cierra el cursor y luego procesa
la coleccion.

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Procedimiento `P_Carga_Precalifica_Cancelado` con OPT-018 | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7960-8159 |
| `OPEN/FETCH BULK COLLECT/CLOSE` final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8087-8089 |
| Loop posterior sobre la coleccion final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8091-8115 |
| Documentacion OPT-018 | `historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/README.md` | 1-67 |
| Antes/despues OPT-018 | `historias/optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/ANTES.sql`, `DESPUES.sql` | Procedimiento completo |

## Aclaracion importante

Los archivos `body_ANTES.sql` y `body_DESPUES.sql` de esta carpeta son snapshots
de trabajo previo. No deben tratarse como solucion final del incidente.

En especial, mover el `COMMIT` principal fuera del loop no elimina por completo el
riesgo, porque `P_Generar_Bitacora` y `P_Validar_Cambio_Estado` siguen siendo
transacciones autonomas y siguen haciendo commits internos.

## Archivos

| Archivo | Estado |
|---------|--------|
| `README.md` | Indice actualizado del incidente |
| `EXPLICACION_PROBLEMA_Y_SOLUCION.md` | Documento tecnico narrativo, actualizado sin plan de reproduccion |
| `bitacora_resolucion.md` | Registro de decisiones y pendientes |
| `HANDOFF_SESION_NUEVA.md` | Resumen listo para continuar en una sesion nueva |
| `body_ANTES.sql` | Snapshot de referencia, no solucion final |
| `body_DESPUES.sql` | Snapshot de referencia, no solucion final |

## Pendientes

- Confirmar en PROD el `UNDO_RETENTION` real, presion de UNDO y volumen de
  `PR_REPRESTAMOS WHERE ESTADO='RE'`.
- Confirmar el flag `PR_ESTADOS_REPRESTAMO.IND_CAMBIA_ESTADO_REPRE` para
  `CODIGO_ESTADO='RE'`.
- Coordinar validacion en QA como compilacion/regresion basica, no como
  reproduccion del `ORA-01555`.
- Monitorear que OPT-017 y OPT-018 reduzcan el riesgo observado sin reproducir
  `ORA-01555`.
- Dejar para una fase separada cualquier refactor directo de
  `P_Generar_Bitacora` y `P_Validar_Cambio_Estado`, porque siguen usando
  transacciones autonomas y commits internos.
