/*******************************************************************************
** IA_API_LOGGER - Body
**
** DECISIÓN DE DISEÑO CRÍTICA:
** Todos los procedimientos públicos usan PRAGMA AUTONOMOUS_TRANSACTION.
** Esto garantiza que los logs persistan INCLUSO si la transacción principal
** hace ROLLBACK, permitiendo auditar operaciones fallidas.
**
** Cada procedimiento con AUTONOMOUS_TRANSACTION DEBE hacer COMMIT explícito.
*******************************************************************************/

CREATE OR REPLACE PACKAGE BODY IA.IA_API_LOGGER IS

    gc_milisegundos_por_dia CONSTANT NUMBER := 86400000;
    gc_longitud_resumen CONSTANT PLS_INTEGER := 1000;
    gc_texto_sensible CONSTANT VARCHAR2(30) := '[DATO_PROTEGIDO]';
    
    gc_error_endpoint_nulo  CONSTANT NUMBER := -20949;
    gc_error_metodo_nulo    CONSTANT NUMBER := -20950;
    gc_error_base_codigo    CONSTANT NUMBER := -20000;
    gc_error_rango_minimo   CONSTANT NUMBER := -20999;

    FUNCTION limitar_texto(
        p_texto    IN VARCHAR2,
        p_longitud IN PLS_INTEGER
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_texto IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN SUBSTR(TRIM(p_texto), 1, p_longitud);
    END limitar_texto;

    FUNCTION normalizar_metodo_http(p_metodo IN VARCHAR2) RETURN VARCHAR2 IS
        v_metodo VARCHAR2(10) := UPPER(TRIM(p_metodo));
    BEGIN
        IF v_metodo IS NULL THEN
            RAISE_APPLICATION_ERROR(
                gc_error_metodo_nulo,
                'El método HTTP es obligatorio (GET, POST, PUT, DELETE, etc.)'
            );
        END IF;
        RETURN v_metodo;
    END normalizar_metodo_http;

    FUNCTION normalizar_nivel_log(p_nivel IN VARCHAR2) RETURN VARCHAR2 IS
        v_nivel VARCHAR2(10) := UPPER(TRIM(NVL(p_nivel, 'INFO')));
    BEGIN
        IF v_nivel NOT IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL') THEN
            RETURN 'INFO';
        END IF;
        RETURN v_nivel;
    END normalizar_nivel_log;

    FUNCTION normalizar_bandera_sensible(p_bandera IN CHAR) RETURN CHAR IS
        v_bandera CHAR(1) := UPPER(TRIM(NVL(p_bandera, 'N')));
    BEGIN
        IF v_bandera NOT IN ('Y', 'N') THEN
            RETURN 'N';
        END IF;
        RETURN v_bandera;
    END normalizar_bandera_sensible;

    FUNCTION sanitizar_payload(
        p_datos       IN CLOB,
        p_es_sensible IN CHAR
    ) RETURN CLOB IS
    BEGIN
        IF p_datos IS NULL THEN
            RETURN NULL;
        END IF;
        
        IF p_es_sensible = 'Y' THEN
            RETURN TO_CLOB(gc_texto_sensible);
        END IF;
        
        RETURN REGEXP_REPLACE(p_datos, '[[:cntrl:]]', ' ');
    END sanitizar_payload;

    FUNCTION resumir_payload(p_datos IN CLOB) RETURN VARCHAR2 IS
    BEGIN
        IF p_datos IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN DBMS_LOB.SUBSTR(p_datos, gc_longitud_resumen, 1);
    END resumir_payload;

    FUNCTION calcular_duracion_milisegundos(p_inicio IN TIMESTAMP) RETURN NUMBER IS
        v_intervalo    INTERVAL DAY TO SECOND;
        v_total_ms     NUMBER;
    BEGIN
        IF p_inicio IS NULL THEN
            RETURN NULL;
        END IF;
        
        v_intervalo := SYSTIMESTAMP - p_inicio;
        
        v_total_ms :=
              EXTRACT(DAY FROM v_intervalo) * gc_milisegundos_por_dia
            + EXTRACT(HOUR FROM v_intervalo) * 3600000
            + EXTRACT(MINUTE FROM v_intervalo) * 60000
            + EXTRACT(SECOND FROM v_intervalo) * 1000;
            
        RETURN ROUND(v_total_ms, 2);
    END calcular_duracion_milisegundos;

    FUNCTION clasificar_codigo_por_rango(p_codigo IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF p_codigo BETWEEN 100 AND 199 THEN
            RETURN 'INFORMATIONAL';
        ELSIF p_codigo BETWEEN 200 AND 299 THEN
            RETURN 'SUCCESS';
        ELSIF p_codigo BETWEEN 300 AND 399 THEN
            RETURN 'REDIRECTION';
        ELSIF p_codigo BETWEEN 400 AND 499 THEN
            RETURN 'CLIENT_ERROR';
        ELSIF p_codigo >= 500 THEN
            RETURN 'SERVER_ERROR';
        END IF;
        RETURN 'UNKNOWN';
    END clasificar_codigo_por_rango;

    FUNCTION obtener_categoria_y_severidad(
        p_codigo_estado      IN NUMBER,
        p_respuesta_es_error IN BOOLEAN
    ) RETURN IA_PKG_APIS.t_metadatos_http IS
        v_resultado IA_PKG_APIS.t_metadatos_http;
    BEGIN
        IF p_codigo_estado IS NULL THEN
            v_resultado.categoria := 'UNKNOWN';
            v_resultado.nivel_log := CASE WHEN p_respuesta_es_error THEN 'ERROR' ELSE 'INFO' END;
            RETURN v_resultado;
        END IF;

        BEGIN
            SELECT STATUS_CATEGORY, SEVERITY_LEVEL
              INTO v_resultado.categoria, v_resultado.nivel_log
              FROM IA.IA_HTTP_STATUS_CATALOG
             WHERE STATUS_CODE = p_codigo_estado;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado.categoria := clasificar_codigo_por_rango(p_codigo_estado);
                
                v_resultado.nivel_log :=
                    CASE
                        WHEN p_respuesta_es_error THEN 'ERROR'
                        WHEN v_resultado.categoria IN ('CLIENT_ERROR', 'SERVER_ERROR') THEN 'WARN'
                        ELSE 'INFO'
                    END;
        END;

        IF p_respuesta_es_error = TRUE AND v_resultado.nivel_log IN ('DEBUG', 'INFO') THEN
            v_resultado.nivel_log := 'ERROR';
        END IF;

        RETURN v_resultado;
    END obtener_categoria_y_severidad;

    FUNCTION mapear_codigo_error_oracle(p_codigo IN NUMBER) RETURN NUMBER IS
        v_codigo NUMBER := NVL(p_codigo, gc_error_base_codigo - 1);
    BEGIN
        IF v_codigo BETWEEN gc_error_rango_minimo AND gc_error_base_codigo THEN
            RETURN v_codigo;
        END IF;
        
        RETURN GREATEST(gc_error_rango_minimo, gc_error_base_codigo - ABS(v_codigo));
    END mapear_codigo_error_oracle;

    PROCEDURE iniciar_log(
        p_ruta_endpoint     IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo_http       IN IA.IA_API_LOGS.METODO%TYPE,
        p_identificador_cli IN IA.IA_API_LOGS.USUARIO%TYPE DEFAULT NULL,
        p_ip_cliente        IN IA.IA_API_LOGS.IP_ORIGEN%TYPE DEFAULT NULL,
        p_nombre_servicio   IN IA.IA_API_LOGS.SERVICE_NAME%TYPE DEFAULT NULL,
        p_carga_util        IN CLOB DEFAULT NULL,
        p_nivel_log         IN IA.IA_API_LOGS.LOG_LEVEL%TYPE DEFAULT 'INFO',
        p_marcar_sensible   IN IA.IA_API_LOGS.IS_SENSITIVE%TYPE DEFAULT 'N',
        p_contexto          OUT NOCOPY tipo_contexto_log
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        
        v_contexto        tipo_contexto_log;
        v_metodo          VARCHAR2(10);
        v_nivel           VARCHAR2(10);
        v_bandera         CHAR(1);
        v_payload         CLOB;
        v_usuario         VARCHAR2(100);
        v_servicio        VARCHAR2(200);
        v_endpoint        VARCHAR2(200);
        v_ip              VARCHAR2(50);
        v_resumen_request VARCHAR2(1000);
    BEGIN
        IF p_ruta_endpoint IS NULL THEN
            RAISE_APPLICATION_ERROR(
                gc_error_endpoint_nulo,
                'La ruta del endpoint es obligatoria para iniciar el log'
            );
        END IF;

        v_metodo   := normalizar_metodo_http(p_metodo_http);
        v_nivel    := normalizar_nivel_log(p_nivel_log);
        v_bandera  := normalizar_bandera_sensible(p_marcar_sensible);
        v_usuario  := NVL(limitar_texto(p_identificador_cli, 100), USER);
        v_servicio := NVL(limitar_texto(p_nombre_servicio, 200), limitar_texto(p_ruta_endpoint, 200));
        v_endpoint := limitar_texto(p_ruta_endpoint, 200);
        v_ip       := limitar_texto(p_ip_cliente, 50);
        
        v_payload         := sanitizar_payload(p_carga_util, v_bandera);
        v_resumen_request := resumir_payload(v_payload);

        INSERT INTO IA.IA_API_LOGS (
            ENDPOINT,
            METODO,
            USUARIO,
            IP_ORIGEN,
            SERVICE_NAME,
            LOG_LEVEL,
            IS_SENSITIVE,
            PARAMETROS,
            REQUEST_BODY_SUMMARY
        ) VALUES (
            v_endpoint,
            v_metodo,
            v_usuario,
            v_ip,
            v_servicio,
            v_nivel,
            v_bandera,
            v_payload,
            v_resumen_request
        ) RETURNING ID_LOG INTO v_contexto.id_log;

        v_contexto.fecha_inicio       := SYSTIMESTAMP;
        v_contexto.ruta_endpoint      := v_endpoint;
        v_contexto.metodo_http        := v_metodo;
        v_contexto.identificador_cli  := v_usuario;
        v_contexto.ip_cliente         := v_ip;
        v_contexto.nombre_servicio    := v_servicio;
        v_contexto.nivel_log          := v_nivel;
        v_contexto.indicador_sensible := v_bandera;

        -- COMMIT requerido por PRAGMA AUTONOMOUS_TRANSACTION
        COMMIT;

        p_contexto := v_contexto;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            
            p_contexto.id_log             := NULL;
            p_contexto.fecha_inicio       := SYSTIMESTAMP;
            p_contexto.ruta_endpoint      := v_endpoint;
            p_contexto.metodo_http        := v_metodo;
            p_contexto.identificador_cli  := v_usuario;
            p_contexto.ip_cliente         := v_ip;
            p_contexto.nombre_servicio    := v_servicio;
            p_contexto.nivel_log          := v_nivel;
            p_contexto.indicador_sensible := v_bandera;
            
            RAISE;
    END iniciar_log;

    PROCEDURE finalizar_log(
        p_contexto            IN OUT NOCOPY tipo_contexto_log,
        p_codigo_estado       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_respuesta   IN IA.IA_API_LOGS.ERROR_MSG%TYPE DEFAULT NULL,
        p_carga_respuesta     IN CLOB DEFAULT NULL,
        p_respuesta_es_error  IN BOOLEAN DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        
        v_respuesta    CLOB;
        v_metadatos    IA_PKG_APIS.t_metadatos_http;
        v_tiempo_ms    NUMBER;
        v_resumen_resp VARCHAR2(1000);
        v_es_error     BOOLEAN;
        v_mensaje      VARCHAR2(4000);
    BEGIN
        IF p_contexto.id_log IS NULL THEN
            RETURN;
        END IF;

        IF p_respuesta_es_error IS NULL THEN
            v_es_error := (p_codigo_estado BETWEEN 400 AND 599);
        ELSE
            v_es_error := p_respuesta_es_error;
        END IF;

        v_respuesta    := sanitizar_payload(p_carga_respuesta, p_contexto.indicador_sensible);
        v_resumen_resp := resumir_payload(v_respuesta);
        
        v_metadatos := obtener_categoria_y_severidad(p_codigo_estado, v_es_error);
        
        v_tiempo_ms := calcular_duracion_milisegundos(p_contexto.fecha_inicio);
        
        v_mensaje := limitar_texto(p_mensaje_respuesta, 4000);

        UPDATE IA.IA_API_LOGS
           SET STATUS_CODE      = p_codigo_estado,
               STATUS_CATEGORY  = v_metadatos.categoria,
               LOG_LEVEL        = v_metadatos.nivel_log,
               ERROR_MSG        = v_mensaje,
               RESPONSE_MSG     = v_respuesta,
               RESPONSE_SUMMARY = v_resumen_resp,
               TIEMPO_MS        = v_tiempo_ms
         WHERE ID_LOG = p_contexto.id_log;

        -- COMMIT requerido por PRAGMA AUTONOMOUS_TRANSACTION
        COMMIT;

        p_contexto.nivel_log    := v_metadatos.nivel_log;
        p_contexto.fecha_inicio := NULL;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END finalizar_log;

    PROCEDURE registrar_error_y_propagar(
        p_contexto          IN OUT NOCOPY tipo_contexto_log,
        p_codigo_estado     IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_tecnico   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_detalle_excepcion IN VARCHAR2 DEFAULT NULL
    ) IS
        v_mensaje_completo VARCHAR2(2000);
    BEGIN
        finalizar_log(
            p_contexto           => p_contexto,
            p_codigo_estado      => p_codigo_estado,
            p_mensaje_respuesta  => p_mensaje_tecnico,
            p_carga_respuesta    => NULL,
            p_respuesta_es_error => TRUE
        );

        v_mensaje_completo := limitar_texto(
            CASE
                WHEN p_detalle_excepcion IS NULL THEN p_mensaje_tecnico
                ELSE p_mensaje_tecnico || ' -> ' || p_detalle_excepcion
            END,
            2000
        );

        RAISE_APPLICATION_ERROR(
            num => mapear_codigo_error_oracle(p_codigo_estado),
            msg => v_mensaje_completo
        );
    END registrar_error_y_propagar;

END IA_API_LOGGER;
/

GRANT EXECUTE ON IA.IA_API_LOGGER TO PR;
CREATE OR REPLACE SYNONYM PR.IA_API_LOGGER FOR IA.IA_API_LOGGER;
