# Diagnostico PROD: RSB sin estados previos por clasificacion SIB

## Pregunta

Por que los represtamos aparecen en la bitacora directamente en `RSB`, con
observacion `Cliente sin clasificacion`, sin registrar los estados anteriores, y por
que el volumen comenzo a crecer desde marzo de 2026.

Hipotesis operativa recibida: esos clientes no existen en `PA.PA_DE08_SIB` para el
corte del **1 de junio de 2026**.

## Hallazgo del codigo

La hipotesis es compatible con el flujo, pero la ausencia en DE08 no genera `RSB`
directamente:

1. Carga dirigida y campana insertan `PR_REPRESTAMOS` con estado tecnico `RE`, sin
   crear bitacora en ese momento:
   `body.sql:1875-1903` y `body.sql:2234-2262`.
2. Los cursores `CUR_DE08_SIB` usan un `INNER JOIN` con `PA_DE08_SIB`. Si el cliente
   no existe en el ultimo corte, no pasa por el cursor y no recibe `CLS`:
   `body.sql:2922-2930` y `body.sql:3123-3130`.
3. `ACTUALIZA_XCORE_DIRIGIDA` busca todo registro `RE` que no tenga bitacora `CLS`;
   no filtra por `ID_CARGA_DIRIGIDA`. A cada fila le genera `RSB` con
   `Cliente sin clasificacion`: `body.sql:3474-3506`.
4. `ACTUALIZA_XCORE_CAMPANA_ESPECIAL` repite el patron, tambien sin limitar el
   origen: `body.sql:3544-3576`.
5. En carga dirigida, XCORE se ejecuta antes de registrar la bitacora `RE`:
   `body.sql:8181-8183` frente a `body.sql:8202-8204`.
6. En campana ocurre lo mismo:
   `body.sql:8295-8298` frente a `body.sql:8314-8318`.
7. `P_Generar_Bitacora` primero cambia el estado principal y despues inserta la
   fila de bitacora: `body.sql:5993-6005`.

Resultado: un cliente ausente de DE08 no obtiene `CLS`; la rutina XCORE lo toma
antes del cierre, lo cambia a `RSB` y lo saca de los cursores posteriores
`WHERE ESTADO = 'RE'`. Por eso `RSB` puede quedar como primera y unica bitacora.

## Riesgo adicional

Los cursores `VALIDACION_CLASIFICACION` de las dos rutinas XCORE no filtran por
origen. Una ejecucion de carga dirigida o campana puede marcar como `RSB` registros
`RE` creados por otro flujo concurrente, siempre que aun no tengan `CLS`.

Tambien existen dos mecanismos SIB distintos:

- `UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB'` sin bitacora:
  `body.sql:2980-2988` y `body.sql:3179-3186`.
- `P_Generar_Bitacora(..., 'RSB', ...)` con bitacora:
  `body.sql:3031-3064`, `body.sql:3227-3269`,
  `body.sql:3504-3506` y `body.sql:3574-3576`.

Esto puede producir trazabilidades diferentes para condiciones relacionadas.

## Lectura temporal

La misma llamada `P_Generar_Bitacora(..., 'RSB', ..., 'Cliente sin
clasificacion', ...)` ya aparece en snapshots versionados del 26 de marzo de
2026. Con la evidencia disponible, el crecimiento mensual no debe atribuirse
todavia a una linea agregada en mayo. Las causas temporales a contrastar son:

- cambio en la cobertura del corte mensual de `PA_DE08_SIB`;
- activacion/cambio de parametros SIB o XCORE;
- mayor frecuencia o nuevo horario de carga dirigida/campana;
- solapamiento entre esos procesos y el flujo regular.

## Script

`01_DIAGNOSTICO_RSB_SIB_D08_PROD.sql` es solo lectura y debe ejecutarse por query
con F9 en PROD.

| Query | Respuesta |
|---|---|
| 1 | Confirma el codigo realmente compilado en PROD mediante `ALL_SOURCE`. |
| 2 | Muestra parametros SIB/XCORE y fechas de corte vigentes. |
| 2A | Muestra las ultimas 10 fechas de corte de `PA_DE08_SIB`, con filas, deudores y clasificaciones nulas. |
| 3 | Mide la evolucion mensual de `RSB` por observacion desde noviembre de 2025. |
| 4 | Confirma si `RSB` fue primera bitacora, si faltan `RE`/`CLS` previos y el origen. |
| 5 | Prueba cuantos clientes existen o no en DE08 al `2026-06-01`. |
| 6 | Entrega detalle individual de hasta 200 casos. |
| 7 | Distingue clientes que desaparecieron en junio de los que nunca estuvieron. |
| 8 | Mide el universo `RE` actualmente expuesto al mismo salto. |

## Criterio de confirmacion

La hipotesis queda confirmada si las Queries 4 y 5 muestran simultaneamente:

- `RSB_ES_PRIMERA_BITACORA > 0`;
- `SIN_RE_PREVIO > 0`;
- `SIN_CLS_PREVIO > 0`;
- mayoria o volumen relevante en `1_NO_EXISTE_EN_DE08_2026_06_01`.

La Query 1 es obligatoria: si el package compilado en PROD no contiene las mismas
lineas, primero debe extraerse el body vivo antes de proponer una correccion.

## Evidencia APEX de la carga dirigida del 2026-06-10

El reporte APEX de la carga ejecutada el 2026-06-10 confirma la hipotesis en vivo
con tres patrones:

1. `CREADO` + `Cliente en clasificacion: A` + XCORE 0 — presente en DE08 con
   clasificacion permitida (ruta sana).
2. `CREADO` + `Cliente sin clasificacion, pero parametro deshabilitado` — presente
   en DE08 con clasificacion NULA/no permitida; prueba que
   `VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA = 'N'` en PROD.
3. `RECHAZO POR CLIENTE NO EN A,B EN SB` (RSB) + `Cliente sin clasificacion` +
   XCORE vacio — ausente del corte DE08; el loop sin compuerta de
   `ACTUALIZA_XCORE_DIRIGIDA` lo marco RSB antes de consultar el XCORE (por eso
   no recibio ni el 0).

Inconsistencia de negocio visible: con la validacion SIB apagada por parametro,
un cliente con clasificacion mala pasa, pero uno ausente de DE08 se rechaza,
porque el loop RSB de XCORE_DIRIGIDA no consulta ese parametro.

`02_RESULTADO_CARGA_DIRIGIDA_20260610.sql` cuantifica la carga completa:

| Query | Respuesta |
|---|---|
| 1 | Resumen de la carga por estado y texto SIB de bitacora. |
| 2 | Cruce estado vs existencia en DE08, clasificacion, fiador y XCORE. |
| 3 | Detalle individual de los RSB de la carga (evidencia). |
| 4 | Contraste: ausentes de DE08 rechazados vs clasificacion mala que paso. |

## Reproduccion en QA02

El body de QA02 tiene el mismo patron que PROD: loop RSB activo en
`ACTUALIZA_XCORE_DIRIGIDA` (body QA02 3642-3643) y campana (3712-3713), comentado
en `Actualiza_XCORE_CUSTOM` (3518-3519).

`03_DIAGNOSTICO_RSB_SIB_QA02.sql` reproduce el salto de forma controlada:

| Momento | Query | Respuesta |
|---|---|---|
| Antes | 1 | Codigo compilado en QA02 (loop activo/comentado). |
| Antes | 2 | Parametros QA02, ultimo corte DE08 y pendientes `T` en carga. |
| Antes | 3 | PREDICCION: pendientes cruzados con DE08 (grupo 1 caera RSB). |
| — | — | Correr la carga dirigida en QA02. |
| Despues | 4 | Resumen de la corrida por estado y texto SIB. |
| Despues | 5 | Firma del salto por RSB: primera bitacora, sin CLS, sin XCORE, ausente DE08 (o fiador). |
| Despues | 6 | Contraste de negocio: ausentes rechazados vs clasificacion mala que paso. |

La reproduccion queda confirmada si la prediccion (Query 3, grupo 1) coincide con
los RSB observados (Queries 4 y 5).

## Estado

- 2026-06-10: diagnostico creado. Pendiente ejecutar en PROD y registrar resultados.
- 2026-06-10: evidencia APEX de la carga del dia confirma la hipotesis; se agrego
  `02_RESULTADO_CARGA_DIRIGIDA_20260610.sql` para cuantificarla en Toad.
- 2026-06-10: se agrego `03_DIAGNOSTICO_RSB_SIB_QA02.sql` para reproducir el salto
  en QA02 con prediccion previa y validacion posterior. Pendiente de ejecutar.
- No se modifico el package ni se propuso aun un cambio de logica de negocio.
