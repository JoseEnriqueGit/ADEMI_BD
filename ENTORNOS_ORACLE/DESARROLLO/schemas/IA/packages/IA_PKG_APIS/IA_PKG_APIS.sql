CREATE OR REPLACE PACKAGE BODY IA.IA_PKG_APIS IS
    gc_ms_per_day           CONSTANT NUMBER       := 86400000;
    gc_longitud_resumen     CONSTANT PLS_INTEGER  := 1000;
    gc_placeholder_sensible CONSTANT VARCHAR2(64) := '[CONTENIDO_PROTEGIDO]';

    SUBTYPE t_bandera_sensible IS IA.IA_API_LOGS.IS_SENSITIVE%TYPE;

    TYPE t_metadatos_http IS RECORD (
        categoria IA.IA_API_LOGS.STATUS_CATEGORY%TYPE,
        nivel_log t_nivel_log
    );

    FUNCTION limitar_varchar(p_texto VARCHAR2, p_longitud PLS_INTEGER) RETURN VARCHAR2 IS
    BEGIN
        IF p_texto IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN SUBSTR(TRIM(p_texto), 1, p_longitud);
    END;

    FUNCTION normalizar_metodo(p_metodo VARCHAR2) RETURN t_metodo_http IS
        v_metodo t_metodo_http := UPPER(TRIM(p_metodo));
    BEGIN
        IF v_metodo IS NULL THEN
            RAISE_APPLICATION_ERROR(-20950, 'El método HTTP es obligatorio para registrar la bitácora.');
        END IF;
        RETURN v_metodo;
    END;

    FUNCTION normalizar_nivel(p_nivel t_nivel_log) RETURN t_nivel_log IS
        v_nivel t_nivel_log := UPPER(TRIM(NVL(p_nivel, 'INFO')));
    BEGIN
        IF v_nivel NOT IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL') THEN
            RETURN 'INFO';
        END IF;
        RETURN v_nivel;
    END;

    FUNCTION normalizar_bandera_sensible(p_bandera t_bandera_sensible) RETURN t_bandera_sensible IS
        v_flag t_bandera_sensible := UPPER(TRIM(NVL(p_bandera, 'N')));
    BEGIN
        IF v_flag NOT IN ('Y', 'N') THEN
            RETURN 'N';
        END IF;
        RETURN v_flag;
    END;

    FUNCTION sanitizar_payload(
        p_datos   IN CLOB,
        p_bandera IN t_bandera_sensible
    ) RETURN CLOB IS
    BEGIN
        IF p_datos IS NULL THEN
            RETURN NULL;
        END IF;
        IF p_bandera = 'Y' THEN
            RETURN TO_CLOB(gc_placeholder_sensible);
        END IF;
        RETURN REGEXP_REPLACE(p_datos, '[[:cntrl:]]', ' ');
    END;

    FUNCTION resumir_payload(p_datos CLOB) RETURN VARCHAR2 IS
    BEGIN
        IF p_datos IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN DBMS_LOB.SUBSTR(p_datos, gc_longitud_resumen, 1);
    END;

    FUNCTION calcular_duracion_ms(p_inicio TIMESTAMP) RETURN NUMBER IS
        v_interval INTERVAL DAY TO SECOND;
        v_total_ms NUMBER;
    BEGIN
        IF p_inicio IS NULL THEN
            RETURN NULL;
        END IF;
        v_interval := SYSTIMESTAMP - p_inicio;
        v_total_ms :=
              EXTRACT(DAY FROM v_interval) * gc_ms_per_day
            + EXTRACT(HOUR FROM v_interval) * 3600000
            + EXTRACT(MINUTE FROM v_interval) * 60000
            + EXTRACT(SECOND FROM v_interval) * 1000;
        RETURN ROUND(v_total_ms, 2);
    END;

    FUNCTION clasificar_por_rango(p_codigo NUMBER) RETURN IA.IA_API_LOGS.STATUS_CATEGORY%TYPE IS
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
    END;

    FUNCTION obtener_metadatos_http(
        p_codigo_estado      IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_respuesta_es_error IN BOOLEAN
    ) RETURN t_metadatos_http IS
        v_metadatos t_metadatos_http;
    BEGIN
        IF p_codigo_estado IS NULL THEN
            v_metadatos.categoria := 'UNKNOWN';
            v_metadatos.nivel_log := CASE WHEN p_respuesta_es_error THEN 'ERROR' ELSE 'INFO' END;
            RETURN v_metadatos;
        END IF;

        BEGIN
            SELECT STATUS_CATEGORY, SEVERITY_LEVEL
              INTO v_metadatos.categoria, v_metadatos.nivel_log
              FROM IA.IA_HTTP_STATUS_CATALOG
             WHERE STATUS_CODE = p_codigo_estado;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_metadatos.categoria := clasificar_por_rango(p_codigo_estado);
                v_metadatos.nivel_log :=
                    CASE
                        WHEN p_respuesta_es_error THEN 'ERROR'
                        WHEN v_metadatos.categoria IN ('CLIENT_ERROR', 'SERVER_ERROR') THEN 'WARN'
                        ELSE 'INFO'
                    END;
        END;

        IF p_respuesta_es_error = TRUE AND v_metadatos.nivel_log IN ('DEBUG', 'INFO') THEN
            v_metadatos.nivel_log := 'ERROR';
        END IF;
        RETURN v_metadatos;
    END;

    FUNCTION mapear_codigo_error(p_codigo NUMBER) RETURN NUMBER IS
        v_codigo NUMBER := NVL(p_codigo, -20001);
    BEGIN
        IF v_codigo BETWEEN -20999 AND -20000 THEN
            RETURN v_codigo;
        END IF;
        RETURN GREATEST(-20999, -20000 - ABS(v_codigo));
    END;

    PROCEDURE iniciar_bitacora_api(
        p_ruta_endpoint     IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo_http       IN IA.IA_API_LOGS.METODO%TYPE,
        p_identificador_cli IN IA.IA_API_LOGS.USUARIO%TYPE,
        p_ip_cliente        IN IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        p_nombre_servicio   IN IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        p_carga_util        IN CLOB,
        p_nivel_log         IN IA.IA_API_LOGS.LOG_LEVEL%TYPE DEFAULT 'INFO',
        p_marcar_sensible   IN IA.IA_API_LOGS.IS_SENSITIVE%TYPE DEFAULT 'N',
        p_contexto          OUT NOCOPY tipo_contexto_bitacora_api
    ) IS
        v_contexto   tipo_contexto_bitacora_api;
        v_metodo     t_metodo_http;
        v_nivel      t_nivel_log;
        v_bandera    t_bandera_sensible;
        v_payload    CLOB;
        v_usuario    VARCHAR2(100);
        v_servicio   VARCHAR2(200);
        v_endpoint   VARCHAR2(200);
        v_ip_normal  IA.IA_API_LOGS.IP_ORIGEN%TYPE;
        v_request_summary VARCHAR2(1000);
    BEGIN
        IF p_ruta_endpoint IS NULL THEN
            RAISE_APPLICATION_ERROR(-20949, 'La ruta del endpoint es obligatoria para registrar la bitácora.');
        END IF;

        v_metodo   := normalizar_metodo(p_metodo_http);
        v_nivel    := normalizar_nivel(p_nivel_log);
        v_bandera  := normalizar_bandera_sensible(p_marcar_sensible);
        v_usuario  := NVL(limitar_varchar(p_identificador_cli, 100), USER);
        v_servicio := NVL(limitar_varchar(p_nombre_servicio, 200), limitar_varchar(p_ruta_endpoint, 200));
        v_endpoint := limitar_varchar(p_ruta_endpoint, 200);
        v_ip_normal := limitar_varchar(p_ip_cliente, 50);
        v_payload  := sanitizar_payload(p_carga_util, v_bandera);
        v_request_summary := resumir_payload(v_payload);

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
            v_ip_normal,
            v_servicio,
            v_nivel,
            v_bandera,
            v_payload,
            v_request_summary
        ) RETURNING ID_LOG INTO v_contexto.id_bitacora;

        v_contexto.fecha_inicio       := SYSTIMESTAMP;
        v_contexto.ruta_endpoint      := v_endpoint;
        v_contexto.metodo_http        := v_metodo;
        v_contexto.identificador_cli  := v_usuario;
        v_contexto.ip_cliente         := v_ip_normal;
        v_contexto.nombre_servicio    := v_servicio;
        v_contexto.nivel_log          := v_nivel;
        v_contexto.indicador_sensible := v_bandera;

        p_contexto := v_contexto;
    EXCEPTION
        WHEN OTHERS THEN
            p_contexto.id_bitacora        := NULL;
            p_contexto.fecha_inicio       := SYSTIMESTAMP;
            p_contexto.ruta_endpoint      := v_endpoint;
            p_contexto.metodo_http        := v_metodo;
            p_contexto.identificador_cli  := v_usuario;
            p_contexto.ip_cliente         := v_ip_normal;
            p_contexto.nombre_servicio    := v_servicio;
            p_contexto.nivel_log          := v_nivel;
            p_contexto.indicador_sensible := v_bandera;
            RAISE;
    END iniciar_bitacora_api;

    PROCEDURE finalizar_bitacora_api(
        p_contexto            IN OUT NOCOPY tipo_contexto_bitacora_api,
        p_codigo_estado       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_respuesta   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_carga_respuesta     IN CLOB,
        p_respuesta_es_error  IN BOOLEAN DEFAULT NULL
    ) IS
        v_respuesta CLOB;
        v_metadatos t_metadatos_http;
        v_tiempo_ms NUMBER;
        v_resumen   VARCHAR2(1000);
        v_es_error  BOOLEAN;
        v_mensaje   VARCHAR2(4000);
    BEGIN
        IF p_contexto.id_bitacora IS NULL THEN
            RETURN;
        END IF;

        IF p_respuesta_es_error IS NULL THEN
            v_es_error := (p_codigo_estado BETWEEN 400 AND 599);
        ELSE
            v_es_error := p_respuesta_es_error;
        END IF;

        v_respuesta := sanitizar_payload(p_carga_respuesta, p_contexto.indicador_sensible);
        v_resumen   := resumir_payload(v_respuesta);
        v_metadatos := obtener_metadatos_http(p_codigo_estado, v_es_error);
        v_tiempo_ms := calcular_duracion_ms(p_contexto.fecha_inicio);
        v_mensaje   := limitar_varchar(p_mensaje_respuesta, 4000);

        UPDATE IA.IA_API_LOGS
           SET STATUS_CODE      = p_codigo_estado,
               STATUS_CATEGORY  = v_metadatos.categoria,
               LOG_LEVEL        = v_metadatos.nivel_log,
               ERROR_MSG        = v_mensaje,
               RESPONSE_MSG     = v_respuesta,
               RESPONSE_SUMMARY = v_resumen,
               TIEMPO_MS        = v_tiempo_ms
         WHERE ID_LOG = p_contexto.id_bitacora;

        p_contexto.nivel_log    := v_metadatos.nivel_log;
        p_contexto.fecha_inicio := NULL;
    END finalizar_bitacora_api;

    PROCEDURE registrar_error_y_propagar(
        p_contexto          IN OUT NOCOPY tipo_contexto_bitacora_api,
        p_codigo_estado     IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_tecnico   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_detalle_excepcion IN VARCHAR2 DEFAULT NULL
    ) IS
        v_mensaje VARCHAR2(2000);
    BEGIN
        finalizar_bitacora_api(
            p_contexto           => p_contexto,
            p_codigo_estado      => p_codigo_estado,
            p_mensaje_respuesta  => p_mensaje_tecnico,
            p_carga_respuesta    => NULL,
            p_respuesta_es_error => TRUE
        );

        v_mensaje := limitar_varchar(
            CASE
                WHEN p_detalle_excepcion IS NULL THEN p_mensaje_tecnico
                ELSE p_mensaje_tecnico || ' -> ' || p_detalle_excepcion
            END,
            2000
        );

        RAISE_APPLICATION_ERROR(
            num => mapear_codigo_error(p_codigo_estado),
            msg => v_mensaje
        );
    END registrar_error_y_propagar;
END IA_PKG_APIS;
/

GRANT EXECUTE ON IA.IA_PKG_APIS TO PR;
CREATE OR REPLACE SYNONYM PR.IA_PKG_APIS FOR IA.IA_PKG_APIS;
