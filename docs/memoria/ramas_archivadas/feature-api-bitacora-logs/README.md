# Rama archivada — `feature/api-bitacora-logs`

> **Qué es esto.** Memoria del trabajo de la rama `feature/api-bitacora-logs`, que se **dejó de lado**.
> Se documenta aquí (objetivo, razones, diseño) y se preservan sus artefactos clave **antes de borrar
> la rama**, para no perder el conocimiento ni el código. Es zona fría: consultar solo si se va a
> retomar el componente.
>
> Esta rama tenía **historia NO relacionada** con `master` (sin ancestro común), por eso no se
> fusionó. Una vez confirmado este archivo, la rama remota puede borrarse sin pérdida.

## Identificación

| Campo | Valor |
|---|---|
| Rama | `feature/api-bitacora-logs` |
| Estado | **DESCARTADO / DEJADO DE LADO** (no promovido) |
| Tip (último commit) | `a3cedad` — "Add benchmark documentation for old vs new view in SQL Developer" |
| Rango de fechas | 2025-04-07 → 2025-11-24 |
| Autor principal | ogand / enriquemk51 |
| Commits únicos vs master | 102 (historia independiente) |
| Fecha de archivo | 2026-06-05 |

## Objetivo del cambio

Construir un **componente institucional de bitácora/logs para APIs REST de ORDS** en Oracle, de modo
que cualquier servicio expuesto vía ORDS registre sus invocaciones de forma homogénea (trazabilidad,
métricas y manejo de datos sensibles) **sin duplicar lógica** en cada proyecto.

## Razones / motivación

- Necesidad de **auditar y medir** las llamadas a las APIs (endpoint, método, usuario, IP, payload,
  código HTTP, duración) de manera consistente entre proyectos.
- Preservar la traza **incluso ante errores**: el logging usa **transacciones autónomas**, así el
  registro persiste aunque la transacción de negocio haga `ROLLBACK` (permite auditar operaciones
  fallidas).
- **Saneo de datos sensibles**: marcar payloads críticos (identificaciones, tarjetas) y guardar solo
  un placeholder/resumen, no el contenido real.
- Clasificación automática de resultados con un **catálogo de estados HTTP** (severidad/categoría).

## Diseño (qué se construyó)

- **`IA.IA_API_LOGS`** — tabla (particionada por `FECHA_HORA`) con endpoint, método, usuario, IP,
  payload saneado, resúmenes, `LOG_LEVEL`, `STATUS_CODE/CATEGORY`, `TIEMPO_MS`, etc.
- **`IA.IA_HTTP_STATUS_CATALOG`** — catálogo de códigos HTTP (categoría, descripción, severidad).
- **`IA.SEQ_API_LOGS`** — secuencia para `ID_LOG`.
- **Paquete de logging** con tres operaciones públicas + un record de contexto que viaja por el flujo:
  - `iniciar_log` / `iniciar_bitacora_api` — valida, normaliza, sanea, inserta el registro inicial y
    devuelve el contexto con `ID_LOG`.
  - `finalizar_log` / `finalizar_bitacora_api` — calcula duración, clasifica por el catálogo y
    actualiza el registro (early-return si no hay `ID_LOG`).
  - `registrar_error_y_propagar` — cierra el log como fallo y hace `RAISE_APPLICATION_ERROR` en el
    rango institucional (-20999..-20000).
- **Wrappers en `PR_PKG_REPRESTAMOS`** (`start_api_log` / `finish_api_log`) para instrumentar sin
  mezclar logging con la lógica de negocio.
- **Ejemplo ORDS** (`ords_handler_demo.sql`) que envuelve `PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT`.

Flujo resumido:
```
Request ORDS -> iniciar_log (IA) -> lógica de negocio -> finalizar_log -> Response ORDS
```

> **Nota de nomenclatura:** el paquete real en los scripts se llama **`IA_API_LOGGER`**
> (`iniciar_log`/`finalizar_log`), mientras la doc de flujo lo nombra **`IA_PKG_APIS`**
> (`iniciar_bitacora_api`/`finalizar_bitacora_api`). El componente se renombró durante la rama;
> ambos nombres se refieren al mismo diseño.

## Artefactos preservados (en `artefactos/`)

- `IA/packages/IA_API_LOGGER/IA_API_LOGGER_HEADER.sql` y `IA_API_LOGGER_BODY.sql`
- `IA/tables/IA_API_LOGS.sql`, `IA/tables/IA_HTTP_STATUS_CATALOG.sql`
- `IA/sequences/SEQ_API_LOGS.sql`
- `api_logging_flow.md` (flujo punta a punta)
- `ords_api_logging_example/README.md` y `ords_handler_demo.sql`

> Estos archivos son **copia de archivo histórico**, NO baseline vivo. No representan lo desplegado
> en ningún entorno; si se retoma el componente, incorporarlos por el flujo normal
> (`docs/instrucciones_ai/BASE_OPERATIVA.md` → incorporar objeto) a `ENTORNOS_ORACLE/...`.

## Si se quiere retomar (salvageable)

El componente está completo a nivel de diseño y código de DESARROLLO. Para revivirlo:
1. Validar el DDL de `IA_API_LOGS` / catálogo / secuencia en el entorno objetivo.
2. Compilar `IA_API_LOGGER` (header + body) y crear el sinónimo `PR.IA_API_LOGGER` si aplica.
3. Instrumentar los procedimientos ORDS deseados con `start_api_log`/`finish_api_log`.
4. Documentarlo como historia nueva y reconciliar el nombre (`IA_API_LOGGER` vs `IA_PKG_APIS`).

## Otro contenido de la rama (no preservado aquí)

La rama también traía iteraciones de la vista `PR.PR_V_ENVIO_REPRESTAMOS` (varios "New view" +
optimización + benchmark). Ese objeto **ya se trabaja en `master`** (ver
`ENTORNOS_ORACLE/Produccion/.../PR_V_ENVIO_REPRESTAMOS.sql`, el incidente de regresión y el borrador
del 419 en `Produccion/CHANGELOG.md`), por lo que esas iteraciones se consideran superadas y no se
archivan. Si hiciera falta, siguen accesibles vía el commit `a3cedad` mientras la rama exista.
