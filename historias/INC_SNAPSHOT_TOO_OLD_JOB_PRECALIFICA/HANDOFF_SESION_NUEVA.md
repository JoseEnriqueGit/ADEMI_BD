# Handoff para sesion nueva - INC SNAPSHOT TOO OLD

## Estado al cierre - 2026-05-06

OPT-017 quedo implementada en `DESARROLLO` sobre
`PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD`.

OPT-018 quedo implementada en `DESARROLLO` sobre
`PR.PR_PKG_REPRESTAMOS.P_Carga_Precalifica_Cancelado`.

La correccion de OPT-017 fue la variante minima:

1. Leer solo `ID_REPRESTAMO` de `PR_REPRESTAMOS WHERE ESTADO = 'RE'`.
2. Cargar los IDs con `FETCH ... BULK COLLECT`.
3. Cerrar el cursor inmediatamente.
4. Iterar la coleccion en memoria y mantener las llamadas existentes a
   `P_Registrar_Solicitud`, `P_GENERAR_BITACORA` y `COMMIT`.

No se modifico `spec.sql`.
No se crearon scripts para reproducir `ORA-01555`.
No se mezclo OPT-004/010/015 con estas correcciones.

La correccion de OPT-018 fue la variante minima:

1. Reducir el cursor final de clasificacion a `ID_REPRESTAMO`.
2. Cargar los candidatos finales con `FETCH ... BULK COLLECT`.
3. Cerrar el cursor antes de llamar `P_Generar_Bitacora`.
4. Mantener la misma logica `NP/RXT/CP/AN`.
5. Usar directamente `V_IDS_REPRESTAMO_FINAL(I)`, sin record `%ROWTYPE`
   intermedio.

## Cierre de sesion

- `spec.sql` no fue modificado.
- `body.sql` quedo con OPT-017 y OPT-018 aplicadas en `DESARROLLO`.
- `AFTER.sql` y `DESPUES.sql` de OPT-018 fueron regenerados desde el
  procedimiento actual.
- `git diff --check` queda sin errores; solo aparecen warnings esperados de
  normalizacion LF/CRLF en Windows.
- No se intento reproducir `ORA-01555`.
- La siguiente fase recomendada es validacion controlada en Toad/QA y monitoreo
  posterior de la primera corrida productiva.

## Archivos modificados relevantes

| Archivo | Estado |
|---------|--------|
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | OPT-017 aplicada en `P_REGISTRO_SOLICITUD` |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/CHANGELOG.md` | Entrada OPT-017 agregada |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md` | Documentacion de OPT-017 |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/BEFORE.sql` | Procedimiento completo antes |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/AFTER.sql` | Procedimiento completo despues, version limpia usada en Toad |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/ROLLBACK.sql` | Procedimiento completo anterior para rollback |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/README.md` | Documentacion de OPT-018 |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/ANTES.sql` | Procedimiento completo antes, nombre en espanol |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/DESPUES.sql` | Procedimiento completo despues, nombre en espanol |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/BEFORE.sql` | Procedimiento completo antes |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/AFTER.sql` | Procedimiento completo despues |
| `historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/ROLLBACK.sql` | Procedimiento completo anterior para rollback |

## Evidencia exacta en DESARROLLO

| Evidencia | Archivo | Lineas |
|-----------|---------|--------|
| Firma publica sin cambios | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql` | 509 |
| Procedimiento `P_REGISTRO_SOLICITUD` final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7907-7958 |
| Cursor solo de IDs y coleccion local | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7913-7919 |
| `OPEN/FETCH BULK COLLECT/CLOSE` | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7923-7925 |
| Loop posterior sobre coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7927-7935 |
| Cierre defensivo del cursor en `EXCEPTION` | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7937-7940 |
| Procedimiento `P_Carga_Precalifica_Cancelado` con OPT-018 | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7960-8159 |
| Cursor final reducido a `ID_REPRESTAMO` y coleccion local | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7984-8002 |
| `OPEN/FETCH BULK COLLECT/CLOSE` final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8087-8089 |
| Loop final posterior sobre coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8091-8115 |

## Decision sobre warning de Toad

Toad mostro un warning por `FETCH ... BULK COLLECT` sin `LIMIT`.
Se acepta para OPT-017 porque:

- la coleccion carga solo `ID_REPRESTAMO`;
- el volumen esperado actual informado es de 5,000 a 10,000 IDs;
- usar `LIMIT` procesando lotes antes de cerrar el cursor reintroduciria el
  patron riesgoso de cursor abierto con commits dentro del loop.

Si el volumen crece a cientos de miles o millones, evaluar staging/GTT para
congelar IDs y procesarlos sin depender de una coleccion grande en memoria.

## Pendiente inmediato

1. Compilar `PR.PR_PKG_REPRESTAMOS` en Toad.
2. Revisar `SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS`.
3. Ejecutar regresion basica de `P_CARGA_PRECALIFICA_CANCELADO`.
4. No intentar reproducir `ORA-01555`; esa ruta sigue descartada.
5. Dejar cualquier refactor directo de `P_Generar_Bitacora` y
   `P_Validar_Cambio_Estado` para una fase separada.

## Contexto para la proxima sesion

`P_Generar_Bitacora` sigue siendo relevante porque:

- declara `PRAGMA AUTONOMOUS_TRANSACTION`;
- llama a `P_Validar_Cambio_Estado`;
- inserta en `PR_BITACORA_REPRESTAMO`;
- hace commits internos.

`P_Validar_Cambio_Estado` tambien es relevante porque:

- declara `PRAGMA AUTONOMOUS_TRANSACTION`;
- actualiza `PR_REPRESTAMOS`;
- ejecuta varios `COMMIT`;
- es la ruta que hacia especialmente peligrosos el cursor padre abierto de
  `P_REGISTRO_SOLICITUD` y el cursor final de clasificacion en
  `P_Carga_Precalifica_Cancelado`.

## Prompt sugerido para validacion posterior

```text
Estoy retomando el incidente INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO.

Trabaja en espanol y sigue AGENTS.md. Usa como fuente de verdad:

- docs/instrucciones_ai/BASE_OPERATIVA.md
- historias/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/HANDOFF_SESION_NUEVA.md
- historias/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/README.md
- historias/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/bitacora_resolucion.md
- historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md
- historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/BEFORE.sql
- historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/AFTER.sql
- historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/ROLLBACK.sql
- historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/README.md
- historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/BEFORE.sql
- historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/AFTER.sql
- historias/optimizaciones/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/ROLLBACK.sql

Entorno objetivo: DESARROLLO.
Package objetivo:
ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/

Contexto:
- OPT-017 ya fue aplicada en `P_REGISTRO_SOLICITUD`.
- La correccion carga los `ID_REPRESTAMO` con `BULK COLLECT`, cierra el cursor y luego procesa la coleccion.
- OPT-018 ya fue aplicada en `P_Carga_Precalifica_Cancelado`.
- La correccion carga los candidatos finales con `BULK COLLECT`, cierra el cursor y luego ejecuta la clasificacion `NP/RXT/CP/AN`.
- No quiero reproducir `ORA-01555`.
- No mezclar OPT-004/010/015 con esta validacion.
- No modificar `spec.sql` salvo que sea estrictamente necesario y me consultes antes.

Nuevo objetivo:
Preparar o revisar la validacion de OPT-017 y OPT-018 en Toad/QA, sin reproducir `ORA-01555`.

Reglas:
- Lee completo `spec.sql` y `body.sql` antes de concluir.
- Revisa `P_REGISTRO_SOLICITUD`, `P_Carga_Precalifica_Cancelado`, `P_Generar_Bitacora` y `P_Validar_Cambio_Estado`.
- Primero diagnostica y propone; no apliques nuevos cambios sin aprobacion.
- Mantener la logica de negocio igual.
- Cita siempre archivo + lineas exactas.
- Si falta una dependencia, pidemela.
```
