# QA02 - Analisis RXT en lote de represtamos 10000

- **Entorno**: QA02
- **Schema/paquete**: PR.PR_PKG_REPRESTAMOS
- **Objeto revisado**: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
- **Caso**: Validacion de lote de represtamos que quedo en estado `RXT`
- **Fecha de documentacion**: 2026-05-13
- **Estado**: Diagnostico documentado, fix propuesto sin aplicar

## Resumen

Se investigaron 209 represtamos generados desde el 2026-05-11 que quedaron en estado `RXT`.

La evidencia revisada no confirma `ORA-01555: snapshot too old` en `IA.LOG_ERROR`. La causa observada en QA02 fue un `ORA-01407` durante `Actualiza_Precalificacion`, provocado por creditos que entraron al cursor inicial con un `CODIGO_CLIENTE` distinto al que existe en `PA.PA_DETALLADO_DE08`.

El efecto fue:

1. Se insertaron registros en `PR.PR_REPRESTAMOS`.
2. Se crearon solicitudes en `PR.PR_SOLICITUD_REPRESTAMO`.
3. Algunos canales se crearon; otros no, por telefono invalido.
4. `Actualiza_Precalificacion` aborto antes de calcular `MTO_PREAPROBADO`.
5. `TIPO_CREDITO` quedo nulo.
6. La validacion final marco los registros como `RXT`.

## Evidencia principal

### Resultado del lote

La validacion mostro:

| Estado | Total | Con solicitud | Con canal | Con tipo credito | Con opciones | Solicitud con credito nuevo | Existe en PR_CREDITOS |
|---|---:|---:|---:|---:|---:|---:|---:|
| RXT | 209 | 209 | 155 | 0 | 0 | 0 | 0 |

Esto indica que el flujo no llego a crear credito. El problema ocurrio antes, durante la precalificacion/calculo del tipo de credito.

### Log aplicativo

En `IA.LOG_ERROR` se observaron errores del paquete `PR_PKG_REPRESTAMOS` entre 2026-05-11 y 2026-05-14:

| ProgramUnit | Error | Total |
|---|---|---:|
| OBT_WORLD_COMPLIANCE | ORA-29273 | 209 |
| P_Registrar_Solicitud | ORA-00001 | 40 |
| Actualiza_Precalificacion | ORA-01407 | 3 |
| Precalifica_Represtamo | ORA-01407 | 2 |
| P_Desactivar_Activar_FrontEnd | ORA-29273 | 1478 |

La busqueda explicita por `ORA-01555` / `SNAPSHOT TOO OLD` no devolvio registros.

## Causa tecnica observada

### 1. El cursor inicial inserta `MTO_CREDITO_ACTUAL` por posicion

En `Precalifica_Represtamo`, el cursor `CREDITOS_PROCESAR` selecciona `b.monto_desembolsado` en la posicion que corresponde a `MTO_CREDITO_ACTUAL`:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:24`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:38`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:40`

Luego inserta el record completo sin lista de columnas:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:230`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:232`

La tabla `PR.PR_REPRESTAMOS` define `MTO_CREDITO_ACTUAL` como `NOT NULL`:

- `ENTORNOS_ORACLE/QA02/schemas/PR/tables/PR_REPRESTAMOS.sql:18`

### 2. El cursor inicial no valida el cliente de DE08

El cursor une `PR_CREDITOS a` con `PA_DETALLADO_DE08 b` por `NO_CREDITO`, `TIPO_CREDITO`, `FECHA_CORTE` y `FUENTE`, pero no valida `CODIGO_CLIENTE`.

Lineas relevantes:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:53`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:60`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:62`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:63`

Condiciones actuales:

```sql
AND b.tipo_credito = c.tipo_credito
AND b.fecha_corte = P_FECHA_CORTE
AND b.no_credito = a.no_credito
AND b.fuente = 'PR'
```

### 3. `Actualiza_Precalificacion` busca por credito y cliente

El procedimiento `Actualiza_Precalificacion` inicia en:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2587`

El loop critico actualiza `MTO_CREDITO_ACTUAL` buscando `PA_DETALLADO_DE08` por `NO_CREDITO` y `CODIGO_CLIENTE`:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2703`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2704`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2707`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2708`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2713`

Si la subconsulta no encuentra fila, devuelve `NULL` e intenta actualizar `MTO_CREDITO_ACTUAL = NULL`, lo cual dispara `ORA-01407`.

El `EXCEPTION` es general del procedimiento:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2865`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2872`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2891`

Por eso un solo registro malo puede cortar el procedimiento completo y evitar el calculo posterior.

### 4. El calculo de `MTO_PREAPROBADO` no llega a ejecutarse

El bloque que actualiza `CODIGO_PRECALIFICACION` y `MTO_PREAPROBADO` esta despues del loop que falla:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2737`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2740`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:2741`

Por eso los 209 quedaron con `MTO_PREAPROBADO = 0`.

### 5. `RXT` se produce por tipo de credito nulo

La funcion `F_Existe_Credito` no valida un credito real en `PR_CREDITOS`; valida que la solicitud tenga `TIPO_CREDITO IS NOT NULL`:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:9513`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:9519`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:9523`

El flujo marca `RXT` cuando `F_Existe_Credito` devuelve falso:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:8140`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:8146`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:8147`

## Registros que probaron la causa

Se identificaron cuatro `ID_REPRESTAMO` que disparaban la condicion de `NULL`:

| ID_REPRESTAMO | NO_CREDITO | CODIGO_CLIENTE en PR_REPRESTAMOS |
|---:|---:|---:|
| 2605339956 | 1493368 | 1293274 |
| 2605340224 | 1493368 | 1293274 |
| 2605339970 | 1716452 | 1293274 |
| 2605340225 | 1716452 | 1293274 |

Pero en `PA.PA_DETALLADO_DE08` esos creditos existen con otros clientes:

| NO_CREDITO | CODIGO_CLIENTE en DE08 | Fuente | Min fecha | Max fecha | Monto |
|---:|---:|---|---|---|---:|
| 1493368 | 49836 | PR | 2023-12-20 | 2025-11-12 | 120000 |
| 1716452 | 34335 | PR | 2025-03-15 | 2025-11-12 | 120000 |

Esto prueba que los registros entraron por `NO_CREDITO`, pero no correspondian al mismo `CODIGO_CLIENTE`.

## Por que el registro queda en PR_REPRESTAMOS si luego se aborta

El insert inicial ocurre en `Precalifica_Represtamo` y se confirma con `COMMIT` antes de ejecutar `Actualiza_Precalificacion`:

- Insert: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:230`
- Commit: `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:357`

Por eso, aunque `Actualiza_Precalificacion` aborte despues, los registros ya quedan en `PR.PR_REPRESTAMOS`.

## Propuesta de correccion

### Fix minimo preventivo

Agregar validacion de empresa y cliente en el cursor `CREDITOS_PROCESAR` de `Precalifica_Represtamo`:

```sql
AND b.codigo_empresa = a.codigo_empresa
AND b.codigo_cliente = a.codigo_cliente
```

Ubicacion sugerida:

```sql
AND b.tipo_credito = c.tipo_credito
AND b.fecha_corte = P_FECHA_CORTE
AND b.no_credito = a.no_credito
AND b.codigo_empresa = a.codigo_empresa
AND b.codigo_cliente = a.codigo_cliente
AND b.fuente = 'PR'
```

Esto evita que entren registros cuyo `PA_DETALLADO_DE08` pertenece a otro cliente.

### Alcance adicional recomendado

Revisar el mismo patron en `Precalifica_Represtamo_fiadores`, que tambien usa `PA_DETALLADO_DE08 b` sin validar cliente:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:1169`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:1176`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:1178`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:1179`

### Defensa adicional, no sustituto del fix

Se puede proteger el update de `MTO_CREDITO_ACTUAL` para no intentar asignar `NULL`, pero eso no debe sustituir el fix del cursor. Usar `NVL` en el bloque de `MTO_PREAPROBADO` no corrige esta causa, porque el procedimiento aborta antes de llegar a ese bloque.

## Consultas de validacion

Las consultas usadas y sugeridas quedaron en:

- `scripts/validacion_RXT_DE08.sql`

