# Propuesta de tracking integral de precalificacion - QA02

Fecha: 2026-06-08.
Ambiente objetivo inicial: QA02.
Objeto principal: `PR.PR_PKG_REPRESTAMOS`.
Estado: Incremento A implementado y probado en QA02 el 2026-06-09.
Incrementos B/C y capa DIAGNOSTICA pendientes.

Ruta de implementacion y pruebas:
`historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/`.

## 1. Objetivo

Registrar el recorrido completo de una ejecucion de
`PR.JOB_CARGA_PRECALIFICA_RD`, desde la preparacion inicial hasta los estados
finales, para responder con evidencia:

- cuantos candidatos existian;
- cuantos pasaron cada filtro;
- cuantos fueron descartados y por que;
- cuantos entraron realmente al lote;
- cuantos sobrevivieron en `RE`;
- cuantos completaron precalificacion, XCORE, solicitud y canal;
- cuantos terminaron en `NP`, `CP`, `RXT`, `AN` u otro rechazo;
- cuanto tiempo tomo cada etapa;
- en que paso ocurrio un error.

La propuesta no cambia las reglas de negocio ni la `spec` publica. Cualquier
implementacion debe limitarse inicialmente a QA02.

## 2. Diagnostico actual

### 2.1 Lo que ya existe

El package ya genera un `ID_EJECUCION` y registra inicio, fin, duracion,
cantidad `RE` y errores en `PR.PR_JOB_PRECALIFICA_TRACK`:

- generacion del identificador: `body.sql` lineas 8067-8069;
- insercion de inicio: `body.sql` lineas 8071-8089;
- cierre y duracion: `body.sql` lineas 8111-8145;
- registro de errores: `body.sql` lineas 8160-8216;
- orquestacion medida: `body.sql` lineas 8232-8322.

La tabla actual esta orientada a un registro por paso porque su llave primaria
es `(ID_EJECUCION, ID_PASO)`. Sus columnas permiten tiempos, `REGISTROS_RE` y
errores, pero no permiten guardar varios filtros dentro del mismo paso.

Los cinco scripts de `trackers_precalifica_post_cursor_fast` reconstruyen:

- filtros secuenciales del cursor;
- limite `LOTE_DE_CARAGA_REPRESTAMO`;
- filtros posteriores `X3`, `X1`, `X2`, mancomunado y edad;
- limpieza de estados `X%` cuando aplica.

Ejemplo principal:
`01_PRECALIFICA_REPRESTAMO_POST_CURSOR_FAST_QA02.sql` lineas 293-425.

### 2.2 Lo que falta

Los scripts actuales no quedan asociados automaticamente al
`ID_EJECUCION` real y no cubren:

- limpieza inicial de represtamos anteriores;
- cantidad real insertada por cada uno de los cinco flujos;
- `RE` consolidado por origen;
- codigo y monto de precalificacion;
- eliminados sin codigo;
- rechazos `RSB` y `RCS`;
- XCORE procesado, pendiente o rechazado;
- solicitud creada o faltante;
- canal creado o faltante;
- estados finales `NP`, `CP`, `RXT` y `AN`.

Ademas, los scripts diagnosticos usan los datos y parametros disponibles al
momento de ejecutarlos. Por eso explican el embudo, pero no constituyen por si
solos evidencia historica inmutable de una corrida anterior.

## 3. Decision de diseno

Se propone una solucion hibrida de tres capas.

### Capa A. Tracking de pasos existente

Conservar `PR.PR_JOB_PRECALIFICA_TRACK` para:

- inicio y fin del job;
- duracion por procedimiento;
- estado `INICIADO`, `FINALIZADO` o `ERROR`;
- codigo y detalle del error;
- cantidad consolidada de `RE`.

No se recomienda sobrecargar esta tabla con una fila por filtro porque su llave
y su semantica actuales corresponden a pasos del job.

### Capa B. Tracking agregado por filtro

Crear una tabla complementaria propuesta:

`PR.PR_JOB_PRECALIFICA_FILTRO_TRACK`

Una fila representaria un filtro o resultado agregado dentro de una ejecucion.

Columnas minimas propuestas:

| Columna | Uso |
|---|---|
| `ID_EJECUCION` | Une el detalle con `PR_JOB_PRECALIFICA_TRACK`. |
| `ID_DETALLE` | Secuencia unica del registro. |
| `FLUJO` | Procedimiento o proceso medido. |
| `FASE` | `CURSOR`, `LOTE`, `POST_CURSOR`, `PRECALIFICACION`, `XCORE`, `SOLICITUD`, `CIERRE`. |
| `ORDEN_FILTRO` | Orden funcional dentro de la fase. |
| `CODIGO_FILTRO` | Codigo estable, por ejemplo `CUR_DE08`, `POST_X3`, `FINAL_NP`. |
| `DESCRIPCION` | Nombre legible del filtro. |
| `TIPO_MEDICION` | `REAL` o `DIAGNOSTICA`. |
| `CANDIDATOS_ANTES` | Cantidad antes del filtro. |
| `CANDIDATOS_PASAN` | Cantidad que continua. |
| `CANDIDATOS_DESCARTADOS` | Diferencia o cantidad afectada. |
| `CREDITOS_DESCARTADOS` | Distintos `NO_CREDITO`, cuando aplique. |
| `CLIENTES_DESCARTADOS` | Distintos `CODIGO_CLIENTE`, cuando aplique. |
| `VALOR_LOTE` | Valor usado por la corrida. |
| `FECHA_CORTE` | Corte DE08 utilizado. |
| `PARAMETROS` | Copia textual de parametros relevantes. |
| `FECHA_REGISTRO` | Momento de la medicion. |

Llave sugerida:

```text
(ID_EJECUCION, ID_DETALLE)
```

Indice de consulta sugerido:

```text
(ID_EJECUCION, FLUJO, FASE, ORDEN_FILTRO)
```

No se propone guardar nombres, identificaciones, telefonos ni otra informacion
personal en esta tabla.

### Capa C. Registro de pertenencia al lote

Para atribuir correctamente los resultados a cada flujo se necesita conservar
que `ID_REPRESTAMO` fue creado por cual procedimiento y ejecucion.

Se propone una tabla tecnica:

`PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK`

Columnas minimas:

```text
ID_EJECUCION
FLUJO
ID_REPRESTAMO
FECHA_REGISTRO
RESULTADO_ULTIMO
```

Esta tabla evita reconstruir posteriormente el lote mediante `ROWNUM`, cuyo
resultado no es deterministico sin `ORDER BY`. Tambien conserva la pertenencia
aunque el registro sea eliminado despues de `PR_REPRESTAMOS`.

La retencion debe ser limitada. Propuesta inicial QA02: conservar entre 30 y
90 dias y purgar por `FECHA_REGISTRO`.

## 4. Dos tipos de medicion

### 4.1 Medicion real

Proviene de la ejecucion del package y se registra inmediatamente.

Ejemplos:

- cantidad realmente recuperada por `FETCH`;
- cantidad insertada en `PR_REPRESTAMOS`;
- filas actualizadas a `X3`, `X1` o `X2`;
- filas eliminadas por mancomunado o edad;
- candidatos que siguen en `RE`;
- solicitudes y canales realmente creados;
- estados finales realmente generados.

Debe identificarse con `TIPO_MEDICION = 'REAL'`.

### 4.2 Medicion diagnostica

Los filtros iniciales estan combinados dentro de cada cursor. `SQL%ROWCOUNT`
solo informa el resultado final del cursor o DML; no explica cuantos quedaron
fuera por cada condicion interna.

Para ese desglose se mantendran los cinco SQL secuenciales existentes,
ejecutados en modo diagnostico y asociados al mismo `ID_EJECUCION` cuando se
requiera una investigacion detallada.

Debe identificarse con `TIPO_MEDICION = 'DIAGNOSTICA'`.

La salida debe guardar tambien:

- fecha y hora del diagnostico;
- fecha de corte usada;
- valor del lote;
- parametros relevantes;
- advertencia si no se ejecuto simultaneamente con el job.

Nunca debe mostrarse una medicion diagnostica posterior como si fuera un
contador capturado por la corrida real.

## 5. Cobertura funcional propuesta

### 5.1 Arranque

Registrar alrededor de `P_Actualizar_Anular_Represtamo`:

| Codigo | Medicion |
|---|---|
| `INI_RE_ANTES` | Represtamos abiertos antes de limpiar. |
| `INI_ANULADOS` | Registros anulados o actualizados. |
| `INI_RE_DESPUES` | Represtamos que permanecen abiertos. |

El llamado ocurre en `body.sql` lineas 8236-8238.

### 5.2 Cinco flujos de candidatos

Aplicar el mismo modelo a:

1. `Precalifica_Represtamo`
2. `Precalifica_Represtamo_fiadores`
3. `Precalifica_Represtamo_fiadores_hi`
4. `Precalifica_Repre_Cancelado`
5. `Precalifica_Repre_Cancelado_hi`

Por cada flujo registrar:

| Fase | Medicion |
|---|---|
| `CURSOR` | Desglose diagnostico de cada filtro inicial. |
| `LOTE` | Elegibles antes del lote, valor del lote y cantidad realmente recuperada. |
| `POST_CURSOR` | `X3`, `X1`, `X2`, mancomunado y edad. |
| `SALIDA` | Cantidad del flujo que permanece en `RE`. |

El cursor principal aplica el lote en `body.sql` linea 56; inserta en
`PR_REPRESTAMOS` en la linea 232 y ejecuta los descartes en las lineas
266-349.

### 5.3 Consolidado `RE`

Registrar:

- `RE` antes de iniciar los cinco flujos;
- insertados por cada flujo;
- descartados por cada flujo;
- `RE` consolidado luego de los cinco procedimientos.

El job ya realiza un conteo global en `body.sql` lineas 8260-8264. Debe
conservarse y complementarse con el desglose por flujo.

### 5.4 Precalificacion

Antes y despues de `Actualiza_Precalificacion`, registrar:

| Codigo | Medicion |
|---|---|
| `PRE_RE_ENTRADA` | Candidatos `RE` recibidos. |
| `PRE_CON_CODIGO` | Registros con `CODIGO_PRECALIFICACION`. |
| `PRE_SIN_CODIGO` | Registros que no obtuvieron codigo. |
| `PRE_ELIMINADOS` | Eliminados por ausencia de codigo u OFAC. |
| `PRE_RSB` | Rechazados por clasificacion o regla de fiador. |
| `PRE_CLS` | Clasificacion SIB registrada. |
| `PRE_RCS` | Rechazados por castigo DE05. |
| `PRE_RE_SALIDA` | Candidatos que continuan en `RE`. |

El llamado ocurre en `body.sql` lineas 8266-8268.

### 5.5 XCORE

Registrar alrededor de `Actualiza_XCORE_CUSTOM`:

| Codigo | Medicion |
|---|---|
| `XCORE_ENTRADA` | `RE` pendientes de XCORE. |
| `XCORE_PROCESADOS` | Registros actualizados con XCORE. |
| `XCORE_CERO_NULO` | Casos con resultado cero o no disponible. |
| `XCORE_ERROR` | Errores capturados durante la consulta. |
| `XCORE_RECHAZADOS` | Rechazos por XCORE, solo si `PVALIDA_XCORE` esta activo. |
| `XCORE_SALIDA` | `RE` que continuan. |

`Actualiza_XCORE_CUSTOM` se llama en `body.sql` lineas 8270-8272.
`PVALIDA_XCORE` esta comentado en QA02 en las lineas 8283-8286; el reporte
debe distinguir `NO_EJECUTADO` de cero rechazos.

### 5.6 Solicitud y canal

Registrar alrededor de `P_REGISTRO_SOLICITUD`:

| Codigo | Medicion |
|---|---|
| `SOL_ENTRADA` | Candidatos `RE` recibidos. |
| `SOL_EXISTENTE` | Ya tenian solicitud. |
| `SOL_CREADA` | Solicitud creada en la corrida. |
| `SOL_ERROR` | No pudo crearse la solicitud. |
| `CANAL_EXISTENTE` | Ya tenia canal valido. |
| `CANAL_CREADO` | Canal creado en la corrida. |
| `CANAL_FALTANTE` | Continua sin canal. |

El procedimiento se llama en `body.sql` lineas 8274-8276.

### 5.7 Cierre

Contabilizar el estado resultante del ciclo final:

| Codigo | Estado |
|---|---|
| `FINAL_NP` | Solicitud, canal y credito validos. |
| `FINAL_CP` | Solicitud existente, pero falta canal. |
| `FINAL_RXT` | No existe credito valido. |
| `FINAL_AN` | No cumple solicitud/opciones. |
| `FINAL_OTRO` | Cualquier estado adicional observado. |

La decision final se encuentra en `body.sql` lineas 8288-8307.

## 6. Instrumentacion propuesta

### 6.1 Sin modificar la spec

Agregar solamente en el package body:

- variable privada de ejecucion activa;
- procedimiento privado para insertar detalle de filtro;
- procedimiento privado para registrar candidatos del lote;
- procedimiento privado para finalizar una medicion;
- manejo de errores interno que nunca interrumpa la logica principal.

La variable debe establecerse al iniciar el job y limpiarse al finalizar.
El estado de package es independiente por sesion, por lo que no se comparte
entre ejecuciones concurrentes.

### 6.2 Transacciones

El tracking debe usar transaccion autonoma, como el tracking actual, para
preservar evidencia incluso cuando el proceso principal falle.

Restricciones:

- el tracking no puede modificar tablas funcionales;
- un error de tracking no puede detener la precalificacion;
- no debe hacer `COMMIT` sobre la transaccion funcional;
- debe evitar consultar desde la transaccion autonoma filas no confirmadas de
  la transaccion principal.

Los conteos deben calcularse en la transaccion principal y enviarse como
numeros al procedimiento autonomo.

### 6.3 Activacion controlada

Parametros propuestos:

| Parametro | Funcion |
|---|---|
| `TRACK_PRECALIFICA_ACTIVO` | Activa el tracking agregado real. |
| `TRACK_PRECALIFICA_DETALLE_CURSOR` | Activa los diagnosticos pesados de filtros internos. |
| `TRACK_PRECALIFICA_RETENCION_DIAS` | Define retencion de evidencias. |

En QA02:

```text
TRACK_PRECALIFICA_ACTIVO = S
TRACK_PRECALIFICA_DETALLE_CURSOR = S
```

Para una eventual evaluacion en produccion, el detalle de cursor debe iniciar
en `N` hasta medir su costo.

## 7. Correcciones previas de los trackers diagnosticos

Antes de considerarlos fuente diagnostica oficial:

1. Corregir `POST_CLEANUP` del tracker principal.

   `01_PRECALIFICA_REPRESTAMO_POST_CURSOR_FAST_QA02.sql` lineas 394-405
   incluye en `candidatos_antes` casos de mancomunado y edad. En el package
   esos registros ya fueron eliminados antes del `DELETE ESTADO LIKE 'X%'`
   (`body.sql` lineas 327-349).

2. Documentar la diferencia del denominador de capital.

   Los trackers de activos agregan una proteccion para evitar denominador cero
   (`01...sql` lineas 84-92 y `04...sql` lineas 83-91) que no aparece de la
   misma forma en el cursor real (`body.sql` lineas 68-71). Debe alinearse o
   marcarse expresamente como desviacion protectora.

3. Mantener la limpieza segun cada procedimiento real.

   En `Precalifica_Repre_Cancelado` el `DELETE ESTADO LIKE 'X%'` esta
   comentado (`body.sql` lineas 736-737), por lo que no debe agregarse una
   limpieza diagnostica inexistente.

4. Identificar que el lote reconstruido no es deterministico.

   Los trackers aplican `ROWNUM` sin `ORDER BY`, igual que el cursor actual.
   El conteo del lote es valido, pero no garantiza seleccionar los mismos
   creditos en una ejecucion posterior. La pertenencia real debe capturarse
   durante el `FETCH`.

## 8. Salidas de consulta

Preparar consultas para:

1. embudo completo de una ejecucion;
2. comparacion entre dos ejecuciones;
3. descartes por flujo y filtro;
4. parametros y fecha de corte usados;
5. duracion por etapa;
6. estados finales;
7. errores;
8. conciliacion:

```text
entrada = descartados + sobrevivientes
```

El reporte debe mostrar por separado filas `REAL` y `DIAGNOSTICA`.

## 9. Validacion QA02

### Fase 1. Validacion tecnica

1. Capturar DDL vivo de tablas y package antes de cualquier cambio.
2. Crear tablas auxiliares solo en QA02.
3. Compilar package body y revisar `SHOW ERRORS`.
4. Confirmar que la `spec` no cambio.
5. Ejecutar el job con tracking detallado desactivado.
6. Comparar duracion contra una ejecucion base.

### Fase 2. Conciliacion operacional

1. Activar tracking real.
2. Ejecutar una corrida controlada.
3. Verificar que todos los pasos compartan el mismo `ID_EJECUCION`.
4. Conciliar insertados, descartados y `RE`.
5. Conciliar solicitudes, canales y estados finales.
6. Forzar o capturar un caso de error y confirmar evidencia persistente.

### Fase 3. Diagnostico detallado

1. Activar `TRACK_PRECALIFICA_DETALLE_CURSOR`.
2. Ejecutar una corrida controlada sin procesos paralelos de carga.
3. Comparar los conteos de los cinco trackers con los lotes reales.
4. Medir duracion y consumo.
5. Desactivar el detalle si el costo no es aceptable.

### Criterios de aceptacion

- `TOTAL_JOB` termina en `FINALIZADO`.
- No cambia la cantidad funcional de candidatos respecto a una corrida
  equivalente sin tracking.
- Toda fila de detalle tiene un encabezado de ejecucion existente.
- Todos los filtros cumplen la conciliacion numerica.
- Los estados finales coinciden con `PR_BITACORA_REPRESTAMO`.
- El tracking no genera errores funcionales ni commits adicionales.
- El incremento de tiempo queda medido y aceptado.

## 10. Rollback

El rollback debe prepararse antes de implementar:

1. restaurar el body anterior completo;
2. compilar y validar el package;
3. desactivar los parametros de tracking;
4. conservar temporalmente las tablas de evidencia para analisis;
5. eliminar tablas e indices auxiliares solo con aprobacion explicita;
6. confirmar que el job vuelve a la duracion y comportamiento base.

No se recomienda usar `DROP TABLE ... PURGE` como primera accion de reversa,
porque destruiria evidencia util para explicar una falla.

## 11. Impacto, riesgo y esfuerzo

| Componente | Impacto | Riesgo | Esfuerzo |
|---|---|---|---|
| Tracking de pasos existente | Bajo | Bajo | Bajo |
| Tabla agregada por filtro | Medio | Bajo | Medio |
| Registro de pertenencia al lote | Medio | Medio por volumen | Medio |
| Conteos reales posteriores al cursor | Alto valor | Bajo/medio | Medio |
| Diagnostico secuencial de cursores dentro de la corrida | Alto costo potencial | Alto en rendimiento | Alto |
| Precalificacion, XCORE, solicitud y cierre | Alto valor | Medio | Medio/alto |

## 12. Orden recomendado de implementacion

1. Corregir y validar los cinco trackers externos.
2. Crear tabla agregada y consultas de reporte.
3. Instrumentar arranque, pasos y `RE` consolidado.
4. Instrumentar resultados reales posteriores al cursor.
5. Instrumentar precalificacion, XCORE, solicitud, canal y cierre.
6. Agregar registro de pertenencia al lote.
7. Evaluar el diagnostico detallado opcional dentro de QA02.
8. Ejecutar pruebas comparativas y documentar resultados.
9. Decidir si alguna parte merece propuesta separada para produccion.

## 13. Resultado esperado

La propuesta completa permitira distinguir claramente:

- no habia suficientes candidatos;
- habia candidatos, pero el cursor los descarto;
- el lote limito la cantidad;
- los candidatos entraron al lote y fueron descartados despues;
- sobrevivieron en `RE`, pero fallaron en precalificacion o riesgo;
- llegaron a solicitud, pero no obtuvieron canal;
- terminaron disponibles para notificacion o con una causa concreta.

Con este modelo, los scripts externos siguen siendo utiles para explicar los
filtros y el tracking interno aporta la evidencia real de cada ejecucion.
