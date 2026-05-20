# OPT-017 - Bulk collect en P_REGISTRO_SOLICITUD

## Resumen

OPT-017 aplica la correccion directa del incidente `INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO` sobre `PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD` en `DESARROLLO`.

El cambio elimina el cursor `FOR` abierto sobre `PR_REPRESTAMOS` durante el procesamiento por fila. Ahora el procedimiento:

1. Abre el cursor solo para leer `ID_REPRESTAMO`.
2. Hace `FETCH ... BULK COLLECT` hacia una coleccion local.
3. Cierra el cursor inmediatamente.
4. Itera la coleccion y mantiene las mismas llamadas a `P_Registrar_Solicitud`, `P_GENERAR_BITACORA` y `COMMIT`.

No se modifica `spec.sql` ni se cambia la logica de negocio.

## Evidencia en DESARROLLO

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Firma publica sin cambios | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql` | 509 |
| Procedimiento modificado | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7907-7958 |
| Cursor reducido a `ID_REPRESTAMO` y coleccion local | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7913-7919 |
| `OPEN/FETCH BULK COLLECT/CLOSE` antes del procesamiento por fila | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7923-7925 |
| Iteracion posterior sobre la coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7927-7935 |
| Cierre defensivo del cursor en el handler | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7937-7940 |

## Alcance

- Objeto: `PR.PR_PKG_REPRESTAMOS`
- Entorno del archivo modificado: `DESARROLLO`
- Procedimiento tocado: `P_REGISTRO_SOLICITUD`
- Columnas usadas para el bulk: solo `ID_REPRESTAMO`, porque el loop original no usaba `ESTADO` ni `XCORE_GLOBAL`.

## Artefactos

| Archivo | Uso |
|---------|-----|
| `BEFORE.sql` | Procedimiento completo antes de OPT-017 |
| `AFTER.sql` | Procedimiento completo despues de OPT-017 |
| `ROLLBACK.sql` | Procedimiento completo anterior para revertir OPT-017 |

## Nota sobre warning de Toad

Toad puede marcar `FETCH ... BULK COLLECT` sin `LIMIT` como aviso de eficiencia/memoria.
En OPT-017 se acepta porque la coleccion carga solo `ID_REPRESTAMO` y el volumen
esperado informado es de 5,000 a 10,000 IDs. Lo importante de esta correccion es
que el cursor se cierre antes de ejecutar `P_Registrar_Solicitud`,
`P_GENERAR_BITACORA` y `COMMIT`.

Si el volumen creciera a cientos de miles o millones de IDs, la siguiente
revision deberia evaluar una tabla staging/GTT para congelar los IDs y procesar
desde ahi, sin volver al patron de cursor abierto con commits dentro del loop.

## Cierre de sesion

- OPT-017 quedo aplicada en `body.sql` de `DESARROLLO` y documentada con
  procedimiento completo antes/despues/rollback.
- La version final del `AFTER.sql` refleja el procedimiento limpio colocado en
  Toad, sin el bloque comentado de trazabilidad antigua.
- El warning de Toad por `BULK COLLECT` sin `LIMIT` queda aceptado para el
  volumen actual informado de 5,000 a 10,000 IDs.
- Pendiente para una nueva sesion: analizar `P_Generar_Bitacora` y
  `P_Validar_Cambio_Estado` para evaluar si conviene otra refactorizacion sin
  mezclarla con OPT-017.

## Validacion pendiente en Toad/QA

1. Compilar `PR.PR_PKG_REPRESTAMOS` en `DESARROLLO` o QA.
2. Confirmar `SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS` sin errores.
3. Ejecutar regresion basica de `PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO`.
4. Verificar conteos antes/despues de registros `RE`, solicitudes creadas y estados finales `NP`, `RXT`, `CP`, `AN`.
5. No intentar reproducir `ORA-01555`; esa ruta fue descartada por decision operativa del incidente.
