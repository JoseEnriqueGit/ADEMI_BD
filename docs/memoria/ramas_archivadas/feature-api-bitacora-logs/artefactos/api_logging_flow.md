# Flujo del componente de bitácoras para API ORDS

Este documento resume cómo funciona el mecanismo de logging institucional basado en la tabla `IA_API_LOGS` y el paquete `IA_PKG_APIS`. Se describe el proceso de punta a punta para comprender cómo se registran las invocaciones de un servicio REST ORDS dentro del ecosistema ADEMI.

## 1. Estructura de almacenamiento

- **`IA_API_LOGS`**: tabla particionada por `FECHA_HORA` que guarda los datos relevantes de cada invocación (endpoint, método HTTP, usuario, IP, payload sanitizado, código/estado, duración y mensajes). Incluye columnas auxiliares como `REQUEST_BODY_SUMMARY`, `RESPONSE_SUMMARY`, `LOG_LEVEL` e indicadores de sensibilidad.
- **`IA_HTTP_STATUS_CATALOG`**: catálogo de códigos HTTP con su categoría (`SUCCESS`, `CLIENT_ERROR`, etc.), descripción y severidad sugerida. El paquete de logging consulta esta tabla para clasificar automáticamente cada registro y mantener criterios homogéneos entre proyectos.

## 2. Paquete institucional `IA_PKG_APIS`

Este paquete centraliza la lógica de instrumentación siguiendo clean code y guard clauses. Expone tres operaciones públicas y un tipo de contexto:

- **`tipo_contexto_bitacora_api`**: record con el `ID_LOG`, hora de inicio, endpoint, método, usuario, IP, nombre del servicio, nivel de log y bandera de sensibilidad. Este contexto viaja por todo el flujo y permite actualizar el registro sin reconsultar la tabla.
- **`iniciar_bitacora_api`**: valida que ruta y método existan, normaliza textos, sanitiza payloads (aplicando placeholder si `p_marcar_sensible = 'Y'`) e inserta el registro inicial en `IA_API_LOGS`. Devuelve el `tipo_contexto_bitacora_api` con el identificador de la bitácora y la metadata capturada.
- **`finalizar_bitacora_api`**: recibe el contexto y los datos finales de la operación (código HTTP, mensaje, payload de respuesta). Calcula la duración en milisegundos, obtiene categoría/nivel desde `IA_HTTP_STATUS_CATALOG` (o por rangos si no hay match) y actualiza el registro. Si el contexto no tiene `ID_LOG`, retorna de inmediato (early return) para no afectar el flujo del servicio.
- **`registrar_error_y_propagar`**: helper para escenarios de error. Cierra la bitácora marcándola como fallo y después levanta un `RAISE_APPLICATION_ERROR` en el rango institucional (-20999 a -20000), preservando la traza en base de datos.

## 3. Wrappers en `PR_PKG_REPRESTAMOS`

El paquete de negocio `PR_PKG_REPRESTAMOS` utiliza dos procedimientos utilitarios para no mezclar la lógica de logging con la funcional:

- **`start_api_log`**: obtiene el usuario e IP del request (`SYS_CONTEXT`), arma la metadata del endpoint y delega en `IA_PKG_APIS.iniciar_bitacora_api`. Devuelve el `tipo_contexto_bitacora_api` listo para ser usado en cada procedimiento de negocio.
- **`finish_api_log`**: recibe el contexto, el código de estado y los mensajes del servicio, y llama a `IA_PKG_APIS.finalizar_bitacora_api`. Así, cualquier procedimiento del paquete puede instrumentarse sin repetir sanitización ni cálculos de métricas.

## 4. Consumo desde ORDS

Un handler PL/SQL de ORDS (ver `docs/ords_api_logging_example/ords_handler_demo.sql`) aplica este patrón de la siguiente manera:

1. Lee los encabezados (`:request_headers`) y el cuerpo (`:body`) para determinar método, IP y payload.
2. Llama a `IA_PKG_APIS.iniciar_bitacora_api` antes de ejecutar la lógica del negocio.
3. Ejecuta el procedimiento funcional (`PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT`) y realiza `COMMIT`.
4. Invoca `IA_PKG_APIS.finalizar_bitacora_api` para registrar código HTTP, mensajes y duración.
5. Construye la respuesta HTTP (`:status`, `:message`, `:response`).
6. En caso de excepción, vuelve a cerrar la bitácora marcando error y devuelve un mensaje seguro al consumidor. Si se desea propagar el error original, se puede utilizar `IA_PKG_APIS.registrar_error_y_propagar`.

## Resumen

El flujo se puede visualizar así:

```
Request ORDS --> start_api_log --> iniciar_bitacora_api (IA) --> lógica de negocio --> finish_api_log --> finalizar_bitacora_api --> Response ORDS
```

De esta forma, cualquier servicio ORDS obtiene trazabilidad consistente, métricas comparables y manejo centralizado de payloads sensibles sin duplicar lógica en cada proyecto.
