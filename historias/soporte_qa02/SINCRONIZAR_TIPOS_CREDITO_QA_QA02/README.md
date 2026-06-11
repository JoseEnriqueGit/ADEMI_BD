# Sincronizar tipos de credito de QA hacia QA02

## Objetivo

Identificar cuales de estos nueve registros de
`PR.PR_TIPO_CREDITO_REPRESTAMO` existen en QA y faltan en QA02:

`164, 857, 752, 753, 883, 972, 854, 855, 751`.

La carga conserva exactamente todos los valores mostrados en QA, incluidas las
columnas de auditoria y sus fechas.

No requieren database link. El origen se valida conectado a **QA** y el
diagnostico/cambio se ejecuta conectado a **QA02**.

## Parametros

- `CODIGO_EMPRESA`: fijo en `1`.
- `TIPOS_CREDITO`: fijos en `164,857,752,753,883,972,854,855,751`.
- `TIPOS_INSERTADOS`: lista reportada por el script de insercion que se usa
  solamente si hace falta ejecutar el rollback.

## Orden de ejecucion en Toad

1. Conectado a QA, ejecutar el `WITH` de
   `01_VALIDAR_VALORES_ORIGEN_QA.sql` con F9. Las
   nueve filas deben indicar `OK_IGUAL_CAPTURA`.
2. En una sesion dedicada conectada a QA02, ejecutar
   `00_VALIDAR_PRERREQUISITOS_QA02.sql` con F5.
3. En `02_VALIDAR_FALTANTES_QA02.sql`, colocar el cursor dentro de cada
   `SELECT` y ejecutar con F9. Revisar cuales filas indican `FALTA_EN_QA02` y
   detenerse ante `ERROR_DIFERENTE_QA`.
4. En `03_SINCRONIZAR_TIPOS_CREDITO_QA02.sql`, ejecutar cada paso por
   separado con F9 y en la misma sesion: deshabilitar trigger, bloquear tabla,
   actualizar el 164 e insertar los ocho faltantes.
5. Antes de confirmar, volver a ejecutar el primer `WITH` de
   `02_VALIDAR_FALTANTES_QA02.sql`; las nueve filas deben indicar
   `OK_IGUAL_QA`.
6. Si la validacion es correcta, ejecutar con F9 el `ALTER TRIGGER ... ENABLE`
   del paso 7. Ese DDL confirma implicitamente los cambios.

La version por bloque anonimo fue sustituida porque el Toad del entorno
procesaba los `PROMPT` pero no ejecutaba el bloque completo.

## Comportamiento del cambio

- La clave comparada es `(CODIGO_EMPRESA, TIPO_CREDITO)`.
- Se insertan las ocho claves ausentes.
- El tipo `164` se actualiza solamente si conserva exactamente el estado
  observado el 2026-06-11. Sus diferencias son `FECHA_MODIFICACION`
  (`2026-06-11 09:25:22` en QA02) y `CREDITO_CAMPANA_ESPECIAL` (`NULL` en
  QA02); se llevaran a `2025-09-30 22:48:31` y `'N'`, respectivamente.
- Si aparece cualquier diferencia adicional, el script se detiene.
- Se conservan las once columnas, incluidas `ADICIONADO_POR`,
  `FECHA_ADICION`, `MODIFICADO_POR` y `FECHA_MODIFICACION`.
- El trigger `PR.TRG_BUI_TIPO_CRED_REPRESTAMO` normalmente reemplaza
  `FECHA_ADICION` por `SYSDATE`. Para preservar los valores exactos, el script
  verifica que el trigger este habilitado, lo deshabilita, bloquea la tabla,
  inserta, valida y vuelve a habilitarlo aun cuando ocurra un error.
- `ALTER TRIGGER` ejecuta commits implicitos en Oracle. Por eso una ejecucion
  exitosa queda confirmada al reactivar el trigger y no admite validacion
  previa al commit.
- Ejecutar la carga en una sesion dedicada y sin transacciones pendientes,
  porque el primer `ALTER TRIGGER` tambien confirma cualquier DML previo de
  esa misma sesion.
- Si el primer intento de reactivar el trigger falla despues de validar la
  carga, el script reintenta el `ENABLE` y reporta que el DML ya fue
  confirmado por el commit implicito previo al DDL.
- Si falta la fila padre en `PR.PR_TIPO_CREDITO`, la insercion se detiene.

## Rollback

`04_ROLLBACK_SINCRONIZACION_QA02.sql` exige pegar las listas exactas
`TIPOS_INSERTADOS` y `TIPOS_ACTUALIZADOS` reportadas por la carga. El rollback
elimina solamente los insertados y restaura en el `164` la fecha previa
observada (`2026-06-11 09:25:22`) y
`CREDITO_CAMPANA_ESPECIAL = NULL`.
