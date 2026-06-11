# Resultados

## 2026-06-11 - Validacion del origen QA

- Entorno: QA (`JOOGANDO@QAORACEL19C`, segun evidencia de Toad).
- Script: `01_VALIDAR_VALORES_ORIGEN_QA.sql`.
- Resultado: los nueve tipos de credito devolvieron `OK_IGUAL_CAPTURA`.
- Tipos validados: `164, 857, 752, 753, 883, 972, 854, 855, 751`.
- Conclusion: el baseline incorporado en los scripts coincide con QA.

## QA02

- Entorno: QA02 (`AJEREZ@QADEMI02_19C`, segun evidencia de Toad).
- Resultado de registros:
  - `164`: `ERROR_DIFERENTE_QA`; difiere en:
    - `FECHA_MODIFICACION`: `2026-06-11 09:25:22` en QA02 frente a
      `2025-09-30 22:48:31` en QA.
    - `CREDITO_CAMPANA_ESPECIAL`: `NULL` en QA02 frente a `'N'` en QA.
  - `857, 752, 753, 883, 972, 854, 855, 751`: `FALTA_EN_QA02`.
- Padres en `PR.PR_TIPO_CREDITO`: 0 faltantes.
- Trigger `PR.TRG_BUI_TIPO_CRED_REPRESTAMO`: `ENABLED`.
- Pendiente: ejecutar `03_SINCRONIZAR_TIPOS_CREDITO_QA02.sql`.

## Intento de sincronizacion

- La evidencia recibida solo muestra las variables internas de Toad
  (`_CONNECT_IDENTIFIER`, `_USER`, `_O_VERSION`, `_O_RELEASE`).
- No aparecen los `PROMPT` del archivo, los totales ni errores Oracle.
- Conclusion: el bloque anonimo no fue ejecutado; probablemente se ejecuto
  solamente la sentencia donde estaba el cursor.
- Accion: el script `03` se reemplazo por una secuencia SQL directa que se
  ejecuta por pasos con F9 y permite ver inmediatamente las filas afectadas.

## 2026-06-11 - Sincronizacion ejecutada y confirmada en QA02

- Entorno: QA02 (`AJEREZ@QADEMI02_19C`), evidencia de Toad (Data tab).
- INSERT de los 8 faltantes: aplicado. Los tipos `857, 752, 753, 883, 972,
  854, 855, 751` quedaron con las 11 columnas iguales a QA, incluida
  `FECHA_ADICION` con fechas de 2025 (confirma que el trigger estuvo
  deshabilitado y no las reemplazo por SYSDATE).
- UPDATE del 164 (PASO 4): devolvio `0 rows updated` porque su `WHERE` exigia
  `CREDITO_CAMPANA_ESPECIAL IS NULL`, pero la columna ya estaba en `'N'` (la
  captura previa que la reportaba `NULL` quedo desactualizada). Solo restaba
  corregir `FECHA_MODIFICACION`.
- Correccion del 164: se reejecuto con trigger deshabilitado un UPDATE puntual
  por PK (`CODIGO_EMPRESA = 1 AND TIPO_CREDITO = 164`) con guarda sobre la
  `FECHA_MODIFICACION` anterior (`2026-06-11 09:25:22`). Dejo
  `FECHA_MODIFICACION = 2025-09-30 22:48:31` y `CREDITO_CAMPANA_ESPECIAL = 'N'`.
- Estado final del 164 verificado en la grilla:
  `FECHA_MODIFICACION = 30/9/2025 10:48:31 p.m.`, `CAMPANA = N`, `FMO = N`.
- Trigger `PR.TRG_BUI_TIPO_CRED_REPRESTAMO`: reactivado (`Last DDL 11:03:55`).
- Resultado: las nueve claves quedan `OK_IGUAL_QA`; 0 padres faltantes.
