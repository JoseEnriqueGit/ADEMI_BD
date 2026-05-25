# JOB_CARGA_PRECALIFICA_RD completa en QA02

## Contexto

El job `PR.JOB_CARGA_PRECALIFICA_RD` se detenia durante la carga de
precalificacion de represtamos en QA02. La traza persistente dejaba la ultima
ejecucion en el paso `Precalifica_Represtamo`, y el log funcional mostraba:

```text
ORA-01407: cannot update ("PR"."HP_REPRESTAMOS"."DIAS_ATRASO") to NULL
```

En QA02, `PR.PR_REPRESTAMOS.DIAS_ATRASO` es `NOT NULL`. El body probado evita
que los calculos `MAX(D.DIAS_ATRASO)` escriban `NULL` cuando no hay detalle en
`PA.PA_DETALLADO_DE08`.

## Body aplicado

- Objeto: `PR.PR_PKG_REPRESTAMOS` body.
- Entorno probado: QA02.
- Fuente de trabajo validada por el usuario: `PR_PKG_REPRESTAMOS.pkb`.
- Ruta versionada para reimplementar: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.
- La spec no se modifico.

## Cambios que deben preservarse

1. `DIAS_ATRASO` protegido contra `NULL`.

   Se cambiaron las 7 asignaciones:

   ```sql
   SET Y.DIAS_ATRASO = (SELECT MAX(D.DIAS_ATRASO) ...)
   ```

   por:

   ```sql
   SET Y.DIAS_ATRASO = NVL((SELECT MAX(D.DIAS_ATRASO) ...), 0)
   ```

   Esto permite que el job continue cuando no existe detalle para el maximo de
   atraso. Mantiene el valor operativo de carga inicial, que ya insertaba
   `DIAS_ATRASO = 0`.

2. Tracking persistente del job.

   El body conserva `track_inicio`, `track_fin` y `track_error` sobre
   `PR.PR_JOB_PRECALIFICA_TRACK`, con transacciones autonomas y medicion por
   pasos. Esto deja evidencia de tiempos y del ultimo paso antes de cualquier
   falla.

3. Orquestacion medida por pasos.

   `P_Carga_Precalifica_Cancelado` ejecuta la cadena con pasos numerados para:
   `P_Actualizar_Anular_Represtamo`, `Precalifica_Represtamo`,
   `Precalifica_Represtamo_fiadores`, `Precalifica_Represtamo_fiadores_hi`,
   `Precalifica_Repre_Cancelado`, `Precalifica_Repre_Cancelado_hi`, conteo
   `RE`, actualizaciones, registro de solicitud y validaciones finales.

4. `PVALIDA_WORLD_COMPLIANCE` y `PVALIDA_XCORE` quedan comentados en la cadena
   principal del job segun el body validado en QA02.

5. Se conserva el ajuste de `P_REGISTRO_SOLICITUD` con `BULK COLLECT` de ids y
   usuario `NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER)`.

6. Se conserva la actualizacion de `MTO_CREDITO_ACTUAL` en
   `Actualiza_Precalificacion` con `EXISTS`, para evitar actualizar con dato
   inexistente en `PA.PA_DETALLADO_DE08`.

7. Se conserva el uso de `OBT_TELEFONO_PERSONA` para telefonos en el armado de
   informacion de envio.

## Resultado observado

El usuario confirmo en QA02 que, con este body, `PR.JOB_CARGA_PRECALIFICA_RD`
culmino por completo.

Codex no ejecuto Oracle localmente; la validacion funcional proviene de Toad en
QA02.

