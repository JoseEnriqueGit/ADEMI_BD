# Handoff para sesion nueva - INC SNAPSHOT TOO OLD

## Estado al cierre - 2026-05-05

OPT-017 quedo implementada en `DESARROLLO` sobre
`PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD`.

La correccion aplicada fue la variante minima:

1. Leer solo `ID_REPRESTAMO` de `PR_REPRESTAMOS WHERE ESTADO = 'RE'`.
2. Cargar los IDs con `FETCH ... BULK COLLECT`.
3. Cerrar el cursor inmediatamente.
4. Iterar la coleccion en memoria y mantener las llamadas existentes a
   `P_Registrar_Solicitud`, `P_GENERAR_BITACORA` y `COMMIT`.

No se modifico `spec.sql`.
No se crearon scripts para reproducir `ORA-01555`.
No se mezclo OPT-004/010/015 con esta correccion.

## Archivos modificados relevantes

| Archivo | Estado |
|---------|--------|
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | OPT-017 aplicada en `P_REGISTRO_SOLICITUD` |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/CHANGELOG.md` | Entrada OPT-017 agregada |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md` | Documentacion de OPT-017 |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/BEFORE.sql` | Procedimiento completo antes |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/AFTER.sql` | Procedimiento completo despues, version limpia usada en Toad |
| `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/ROLLBACK.sql` | Procedimiento completo anterior para rollback |

## Evidencia exacta en DESARROLLO

| Evidencia | Archivo | Lineas |
|-----------|---------|--------|
| Firma publica sin cambios | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql` | 509 |
| Procedimiento `P_REGISTRO_SOLICITUD` final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7907-7958 |
| Cursor solo de IDs y coleccion local | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7913-7919 |
| `OPEN/FETCH BULK COLLECT/CLOSE` | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7923-7925 |
| Loop posterior sobre coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7927-7935 |
| Cierre defensivo del cursor en `EXCEPTION` | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7937-7940 |

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
5. En nueva sesion, analizar `P_Generar_Bitacora` y `P_Validar_Cambio_Estado`
   para ver si conviene una refactorizacion adicional.

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
- es la ruta que hacia especialmente peligroso el cursor padre abierto de
  `P_REGISTRO_SOLICITUD`.

## Prompt sugerido para nueva sesion

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

Entorno objetivo: DESARROLLO.
Package objetivo:
ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/

Contexto:
- OPT-017 ya fue aplicada en `P_REGISTRO_SOLICITUD`.
- La correccion carga los `ID_REPRESTAMO` con `BULK COLLECT`, cierra el cursor y luego procesa la coleccion.
- No quiero reproducir `ORA-01555`.
- No mezclar OPT-004/010/015 con este analisis.
- No modificar `spec.sql` salvo que sea estrictamente necesario y me consultes antes.

Nuevo objetivo:
Analizar `P_Generar_Bitacora` y su relacion con `P_Validar_Cambio_Estado` para determinar si conviene una nueva optimizacion/refactorizacion que reduzca riesgos de `ORA-01555`, commits internos, transacciones autonomas o efectos colaterales.

Reglas:
- Lee completo `spec.sql` y `body.sql` antes de concluir.
- Para analizar `P_Generar_Bitacora`, revisa tambien `P_Validar_Cambio_Estado` y llamadas relevantes desde `P_REGISTRO_SOLICITUD`.
- Primero diagnostica y propone; no apliques cambios sin que yo los apruebe.
- Mantener la logica de negocio igual.
- Cita siempre archivo + lineas exactas.
- Si falta una dependencia, pidemela.
```
