# Ejemplo ORDS + IA_PKG_APIS

Este directorio muestra cómo envolver un handler PL/SQL de ORDS con el paquete `IA_PKG_APIS` para obtener trazabilidad completa en la tabla `IA_API_LOGS`. Está pensado para alguien que se inicia en PL/SQL y necesita entender el flujo end-to-end: desde que llega la petición HTTP hasta que los datos quedan almacenados en la bitácora.

## Archivos incluidos

- `ords_handler_demo.sql`: bloque PL/SQL listo para pegar en el módulo **API REST** de ORDS (handler tipo PL/SQL). Invoca `PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT` y utiliza las tres operaciones públicas de `IA_PKG_APIS`.

## Requisitos previos

1. El esquema `IA` debe tener creados la tabla `IA_API_LOGS`, el catálogo `IA_HTTP_STATUS_CATALOG` y el paquete `IA_PKG_APIS` (se incluyen en el árbol `ENTORNOS_ORACLE/DESARROLLO/schemas/IA`).  
2. El módulo ORDS debe exponer un recurso que entregue a este handler los parámetros nombrados (ej. `:PIDREPRESTAMO`, `:PMONTO`, `:body`, `:request_headers`).  
3. El esquema `PR` debe tener permisos de ejecución sobre `IA_PKG_APIS` y el sinónimo `PR.IA_PKG_APIS` ya creado (lo hace el script del paquete).

## Flujo de datos (end-to-end)

1. **ORDS recibe la petición HTTP.** Los encabezados y el cuerpo quedan disponibles vía `:request_headers` y `:body`. Estos valores se inyectan en variables locales (`v_metodo`, `v_ip_cliente`, `v_payload`).  
2. **`IA_PKG_APIS.iniciar_bitacora_api`.**  
   - Verifica que `p_ruta_endpoint` y `p_metodo_http` no estén vacíos (guard clauses).  
   - Normaliza método/nivel/IP, limpia el cuerpo (`sanitizar_payload`) y genera un resumen (`resumir_payload`).  
   - Inserta en `IA_API_LOGS` y devuelve un `tipo_contexto_bitacora_api` con el `ID_LOG`, fecha de inicio, endpoint, método, usuario e indicador de sensibilidad.  
3. **Llamada al procedimiento funcional.** `PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT` calcula las cuotas/montos usando los binds provenientes de la URL o del cuerpo JSON que ORDS transforma. El handler no altera la lógica: solo se asegura de que todo ocurra entre la apertura y el cierre de la bitácora.  
4. **`COMMIT` intermedio.** Se confirma la operación de negocio y el insert de la bitácora para mantener consistencia. Si necesitas transacciones más finas, podrías mover el commit al consumidor, pero el ejemplo mantiene la semántica original.  
5. **`IA_PKG_APIS.finalizar_bitacora_api`.**  
   - Calcula la duración en ms usando `p_contexto.fecha_inicio`.  
   - Sanitiza la respuesta (si existiera) con la misma bandera sensible del request.  
   - Determina la categoría y el nivel de log mediante `IA_HTTP_STATUS_CATALOG` o, en su defecto, por rangos (lookup table pattern).  
   - Actualiza el registro inicial con `STATUS_CODE`, `STATUS_CATEGORY`, `ERROR_MSG`, `RESPONSE_MSG`, `RESPONSE_SUMMARY` y `TIEMPO_MS`.  
6. **Construcción de la respuesta HTTP.** El bloque asigna `:status := 200`, `:message := 'Operación exitosa'` y un JSON con los montos para que ORDS entregue la respuesta al cliente.  
7. **Bloque `EXCEPTION`.**  
   - Si ocurre un error, se vuelve a llamar a `finalizar_bitacora_api` con `p_respuesta_es_error => TRUE` e información de `SQLERRM`.  
   - Se devuelven `:status := 500` y un payload controlado; evitamos exponer trazas internas.  
   - Si en lugar de manejar el HTTP manualmente querés propagar la excepción, podés invocar `IA_PKG_APIS.registrar_error_y_propagar(...)` para que el propio paquete haga el `RAISE_APPLICATION_ERROR`.

### Paso a paso del archivo `ords_handler_demo.sql`

1. **Declaración de contexto (`v_ctx`).** Reserva el record público del paquete; almacenará `ID_LOG` y metadata.  
2. **Lectura de headers y cuerpo.**  
   - `v_metodo` usa `ORDS.GET_PARAMETER` y, como fallback, `:method`.  
   - `v_ip_cliente` intenta capturar `X-Forwarded-For`.  
   - `v_usuario` prioriza un parámetro del request y luego `USER`.  
   - `v_payload` obtiene `:body`.  
3. **`IA_PKG_APIS.iniciar_bitacora_api`.** Se pasa toda la metadata anterior y el nombre del servicio PL/SQL que atiende la solicitud. El paquete ya sanitiza y limita los textos antes de insertar.  
4. **Llamada a `P_CARGAR_OPCION_FRONT`.** Se alimenta con los bind variables enumerados en el template ORDS (prefijo `:`). Todos los OUT/IN OUT se actualizan automáticamente en el engine de ORDS.  
5. **`COMMIT`.** Garantiza que el movimiento de negocio queda persistido antes de construir la respuesta.  
6. **`IA_PKG_APIS.finalizar_bitacora_api`.** Registra estado 200, mensaje exitoso y (opcionalmente) un cuerpo de respuesta si quisieras guardarlo.  
7. **Asignación de respuesta.**  
   - `:status` y `:message` definen el HTTP y la frase.  
   - `:response` crea un JSON con `JSON_OBJECT`, lo que simplifica el consumo desde front-ends.  
8. **`EXCEPTION`.**  
   - Captura cualquier error y vuelve a llamar a `finalizar_bitacora_api` para dejar constancia del fallo.  
   - Devuelve un mensaje genérico al consumidor, manteniendo la confidencialidad del detalle técnico.  
   - Si necesitás auditar la traza, `IA_API_LOGS` tendrá `ERROR_MSG`, `STATUS_CODE`, `STATUS_CATEGORY` y `TIEMPO_MS` para correlacionar el incidente.

## Consejos para principiantes

- **Variables previstas por ORDS:** `:body`, `:request_headers`, `:method`, `:status`, `:message` y los binds definidos en el template (`:PIDREPRESTAMO`, etc.). No es necesario declararlas, basta con usarlas en el bloque.  
- **Mantén el endpoint como constante.** La columna `ENDPOINT` permite agrupar métricas; define una convención (por ejemplo `modulo/recurso/version`).  
- **IPs detrás de balanceadores:** Usa encabezados como `X-Forwarded-For`; si no existen, `IA_PKG_APIS` guardará `NULL`.  
- **Datos sensibles:** Marca `p_marcar_sensible => 'Y'` cuando el cuerpo contenga identificaciones, tarjetas o payload crítico; el paquete guardará solo un placeholder y los resúmenes se mantendrán vacíos.  
- **Pruebas:** Ejecuta el handler desde ORDS (o `curl`) y consulta `SELECT * FROM IA_API_LOGS ORDER BY ID_LOG DESC FETCH FIRST 5 ROWS ONLY;` para validar que fechas, endpoint, método y tiempos se registran correctamente.

Con este patrón, cualquier API ORDS puede adoptar el componente de logging sin duplicar código, garantizando trazabilidad y métricas consistentes en todos los proyectos.
