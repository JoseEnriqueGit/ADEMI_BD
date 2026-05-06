# OPT-018 - Bulk collect final en P_Carga_Precalifica_Cancelado

## Resumen

OPT-018 complementa OPT-017 dentro del incidente `INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA`.

El cambio reduce el riesgo restante de `ORA-01555` en el tramo final de
`P_Carga_Precalifica_Cancelado`, donde el procedimiento volvia a recorrer
`PR_REPRESTAMOS WHERE ESTADO = 'RE'` y dentro del loop llamaba
`P_Generar_Bitacora`, que a su vez llama `P_Validar_Cambio_Estado`.

La optimizacion aplicada:

1. Reduce el cursor final `CUR_REPRESTAMO` a `ID_REPRESTAMO`.
2. Carga los IDs candidatos con `FETCH ... BULK COLLECT`.
3. Cierra el cursor antes de ejecutar la clasificacion `NP/RXT/CP/AN`.
4. Mantiene las mismas validaciones y llamadas a `P_Generar_Bitacora`.
5. Usa `V_IDS_REPRESTAMO_FINAL(I)` directamente, sin variable `%ROWTYPE`
   intermedia.

No se modifica `spec.sql`.
No se cambia la logica de negocio.
No se tocan `P_Generar_Bitacora` ni `P_Validar_Cambio_Estado`.

## Evidencia en DESARROLLO

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Firma publica sin cambios | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql` | 311 |
| Procedimiento modificado | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7960-8159 |
| Cursor final reducido a `ID_REPRESTAMO` | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 7984-7987 |
| Coleccion local de IDs | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8001-8002 |
| `OPEN/FETCH BULK COLLECT/CLOSE` antes de la clasificacion final | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8087-8089 |
| Loop posterior sobre la coleccion | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8091-8115 |
| Cierre defensivo del cursor en el handler interno | `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8133-8137 |

## Alcance

- Objeto: `PR.PR_PKG_REPRESTAMOS`
- Entorno: `DESARROLLO`
- Procedimiento tocado: `P_Carga_Precalifica_Cancelado`
- Flujo afectado: clasificacion final de candidatos `RE` a `NP`, `RXT`, `CP` o `AN`.

## Artefactos

| Archivo | Uso |
|---------|-----|
| `ANTES.sql` | Procedimiento completo antes de OPT-018, nombre en espanol |
| `DESPUES.sql` | Procedimiento completo despues de OPT-018, nombre en espanol |
| `BEFORE.sql` | Procedimiento completo antes de OPT-018, mantenido por consistencia con OPT-017 |
| `AFTER.sql` | Procedimiento completo despues de OPT-018, mantenido por consistencia con OPT-017 |
| `ROLLBACK.sql` | Procedimiento completo anterior para revertir OPT-018 |

## Riesgos residuales

- `P_Generar_Bitacora` y `P_Validar_Cambio_Estado` siguen siendo transacciones autonomas con commits internos.
- El cambio no intenta reproducir `ORA-01555`.
- Si el volumen de `ESTADO='RE'` escala a cientos de miles o millones, evaluar staging/GTT igual que en OPT-017.

## Validacion pendiente en Toad/QA

1. Compilar `PR.PR_PKG_REPRESTAMOS` en `DESARROLLO` o QA.
2. Confirmar `SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS` sin errores.
3. Ejecutar regresion basica de `PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO`.
4. Verificar conteos antes/despues para `RE`, `NP`, `RXT`, `CP`, `AN`.
5. Verificar que `PR_BITACORA_REPRESTAMO` conserve la secuencia esperada por `ID_REPRESTAMO`.
6. No intentar reproducir `ORA-01555`; la validacion sigue basada en compilacion, regresion y monitoreo posterior.
