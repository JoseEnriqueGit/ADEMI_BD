CREATE OR REPLACE PACKAGE BODY IA.IA_PKG_REGISTRO_SOLICITUD_API IS
    gc_ms_por_dia        CONSTANT NUMBER := 86400000; -- 24h * 60m * 60s * 1000ms
    gc_codigo_http_min   CONSTANT PLS_INTEGER := 100;
    gc_codigo_http_max   CONSTANT PLS_INTEGER := 599;
    gc_longitud_resumen  CONSTANT PLS_INTEGER := 1000;

    FUNCTION sanear_carga_util(
        p_carga_util   IN CLOB,
        p_es_sensible  IN IA.IA_API_LOGS.IS_SENSITIVE%TYPE
    ) RETURN CLOB IS
        v_resultado CLOB := p_carga_util;
    BEGIN
        IF p_es_sensible = 'Y' THEN
            RETURN '***REDACTED***';
        END IF;

        IF v_resultado IS NULL THEN
            RETURN NULL;
        END IF;

        v_resultado := REGEXP_REPLACE(v_resultado, '(?i)"password"\s*:\s*"[^"]*"', '"password":"***"');
        v_resultado := REGEXP_REPLACE(v_resultado, '(?i)"token"\s*:\s*"[^"]*"', '"token":"***"');
        v_resultado := REGEXP_REPLACE(v_resultado, '(?i)"api_key"\s*:\s*"[^"]*"', '"api_key":"***"');
        v_resultado := REGEXP_REPLACE(v_resultado, '\\d{16}', '****-****-****-****');
        RETURN v_resultado;
    END sanear_carga_util;

    FUNCTION construir_resumen(p_carga_util IN CLOB) RETURN VARCHAR2 IS
    BEGIN
        IF p_carga_util IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN SUBSTR(p_carga_util, 1, gc_longitud_resumen);
    END construir_resumen;

    FUNCTION normalizar_nivel_log(p_nivel_log IN IA.IA_API_LOGS.LOG_LEVEL%TYPE)
        RETURN IA.IA_API_LOGS.LOG_LEVEL%TYPE IS
        v_nivel IA.IA_API_LOGS.LOG_LEVEL%TYPE := UPPER(NVL(TRIM(p_nivel_log), 'INFO'));
    BEGIN
        IF v_nivel NOT IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL') THEN
            RAISE_APPLICATION_ERROR(-20013, 'Nivel de log inválido: ' || p_nivel_log);
        END IF;
        RETURN v_nivel;
    END normalizar_nivel_log;

    FUNCTION normalizar_metodo_http(p_metodo_http IN IA.IA_API_LOGS.METODO%TYPE)
        RETURN IA.IA_API_LOGS.METODO%TYPE IS
        v_metodo IA.IA_API_LOGS.METODO%TYPE := UPPER(NVL(TRIM(p_metodo_http), ''));
    BEGIN
        IF v_metodo NOT IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD') THEN
            RAISE_APPLICATION_ERROR(-20012, 'Método HTTP no soportado: ' || p_metodo_http);
        END IF;
        RETURN v_metodo;
    END normalizar_metodo_http;

    PROCEDURE validar_codigo_http(p_codigo_http IN IA.IA_API_LOGS.STATUS_CODE%TYPE) IS
    BEGIN
        IF p_codigo_http IS NULL THEN
            RAISE_APPLICATION_ERROR(-20021, 'El código HTTP no puede ser nulo');
        ELSIF p_codigo_http < gc_codigo_http_min OR p_codigo_http > gc_codigo_http_max THEN
            RAISE_APPLICATION_ERROR(-20022, 'Código HTTP fuera de rango: ' || p_codigo_http);
        END IF;
    END validar_codigo_http;

    FUNCTION prioridad_nivel(p_nivel IN VARCHAR2) RETURN PLS_INTEGER IS
    BEGIN
        CASE UPPER(NVL(TRIM(p_nivel), 'INFO'))
            WHEN 'DEBUG' THEN RETURN 1;
            WHEN 'INFO' THEN RETURN 2;
            WHEN 'WARN' THEN RETURN 3;
            WHEN 'ERROR' THEN RETURN 4;
            WHEN 'FATAL' THEN RETURN 5;
            ELSE RETURN 2;
        END CASE;
    END prioridad_nivel;

    FUNCTION elevar_nivel_log(
        p_nivel_actual    IN IA.IA_API_LOGS.LOG_LEVEL%TYPE,
        p_nivel_candidato IN IA.IA_API_LOGS.LOG_LEVEL%TYPE
    ) RETURN IA.IA_API_LOGS.LOG_LEVEL%TYPE IS
    BEGIN
        IF prioridad_nivel(p_nivel_candidato) > prioridad_nivel(p_nivel_actual) THEN
            RETURN UPPER(TRIM(p_nivel_candidato));
        END IF;
        RETURN UPPER(TRIM(p_nivel_actual));
    END elevar_nivel_log;

    PROCEDURE obtener_metadatos_estado(
        p_codigo_http IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_categoria   OUT VARCHAR2,
        p_severidad   OUT IA.IA_API_LOGS.LOG_LEVEL%TYPE
    ) IS
    BEGIN
        SELECT status_category, severity_level
          INTO p_categoria, p_severidad
          FROM IA.IA_HTTP_STATUS_CATALOG
         WHERE status_code = p_codigo_http;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_categoria := 'UNKNOWN';
            p_severidad := 'WARN';
    END obtener_metadatos_estado;

    PROCEDURE iniciar_registro_solicitud(
        p_ruta_endpoint     IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo_http       IN IA.IA_API_LOGS.METODO%TYPE,
        p_identificador_cli IN IA.IA_API_LOGS.USUARIO%TYPE,
        p_ip_cliente        IN IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        p_nombre_servicio   IN IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        p_carga_util        IN CLOB,
        p_nivel_log         IN IA.IA_API_LOGS.LOG_LEVEL%TYPE,
        p_marcar_sensible   IN IA.IA_API_LOGS.IS_SENSITIVE%TYPE,
        p_contexto          OUT tipo_contexto_solicitud_api
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_metodo        IA.IA_API_LOGS.METODO%TYPE;
        v_nivel_log     IA.IA_API_LOGS.LOG_LEVEL%TYPE;
        v_es_sensible   IA.IA_API_LOGS.IS_SENSITIVE%TYPE := NVL(p_marcar_sensible, 'N');
        v_carga_saneada CLOB;
        v_resumen       VARCHAR2(gc_longitud_resumen);
        v_fecha_actual  TIMESTAMP;
    BEGIN
        IF p_ruta_endpoint IS NULL OR LENGTH(TRIM(p_ruta_endpoint)) = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'La ruta del endpoint es obligatoria');
        END IF;

        v_metodo := normalizar_metodo_http(p_metodo_http);
        v_nivel_log := normalizar_nivel_log(p_nivel_log);

        v_es_sensible := CASE UPPER(TRIM(v_es_sensible)) WHEN 'Y' THEN 'Y' ELSE 'N' END;
        v_carga_saneada := sanear_carga_util(p_carga_util, v_es_sensible);
        v_resumen := construir_resumen(v_carga_saneada);
        v_fecha_actual := SYSTIMESTAMP;

        INSERT INTO IA.IA_API_LOGS (
            ID_LOG,
            FECHA_HORA,
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
            IA.SEQ_API_LOGS.NEXTVAL,
            v_fecha_actual,
            p_ruta_endpoint,
            v_metodo,
            p_identificador_cli,
            p_ip_cliente,
            p_nombre_servicio,
            v_nivel_log,
            v_es_sensible,
            v_carga_saneada,
            v_resumen
        ) RETURNING ID_LOG INTO p_contexto.id_registro;

        p_contexto.fecha_inicio := v_fecha_actual;
        p_contexto.ruta_endpoint := p_ruta_endpoint;
        p_contexto.metodo_http := v_metodo;
        p_contexto.identificador_cli := p_identificador_cli;
        p_contexto.ip_cliente := p_ip_cliente;
        p_contexto.nombre_servicio := p_nombre_servicio;
        p_contexto.nivel_log := v_nivel_log;
        p_contexto.es_sensible := v_es_sensible;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_contexto.id_registro := NULL;
            p_contexto.fecha_inicio := v_fecha_actual;
            p_contexto.nivel_log := v_nivel_log;
            p_contexto.es_sensible := v_es_sensible;
            RAISE;
    END iniciar_registro_solicitud;

    PROCEDURE finalizar_solicitud_con_metricas(
        p_contexto          IN OUT NOCOPY tipo_contexto_solicitud_api,
        p_codigo_http       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_error     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_carga_respuesta   IN CLOB
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_respuesta        CLOB;
        v_resumen_resp     VARCHAR2(gc_longitud_resumen);
        v_inicio           TIMESTAMP := NVL(p_contexto.fecha_inicio, SYSTIMESTAMP);
        v_categoria        VARCHAR2(20);
        v_nivel_catalogo   IA.IA_API_LOGS.LOG_LEVEL%TYPE;
        v_nivel_efectivo   IA.IA_API_LOGS.LOG_LEVEL%TYPE;
    BEGIN
        IF p_contexto.id_registro IS NULL THEN
            RETURN;
        END IF;

        validar_codigo_http(p_codigo_http);
        obtener_metadatos_estado(p_codigo_http, v_categoria, v_nivel_catalogo);

        v_nivel_efectivo := elevar_nivel_log(p_contexto.nivel_log, v_nivel_catalogo);
        p_contexto.nivel_log := v_nivel_efectivo;

        v_respuesta := sanear_carga_util(p_carga_respuesta, p_contexto.es_sensible);
        v_resumen_resp := construir_resumen(v_respuesta);

        UPDATE IA.IA_API_LOGS
           SET STATUS_CODE        = p_codigo_http,
               STATUS_CATEGORY    = v_categoria,
               LOG_LEVEL          = v_nivel_efectivo,
               ERROR_MSG          = p_mensaje_error,
               RESPONSE_MSG       = v_respuesta,
               RESPONSE_SUMMARY   = v_resumen_resp,
               TIEMPO_MS          = ROUND((SYSTIMESTAMP - v_inicio) * gc_ms_por_dia, 2)
         WHERE ID_LOG = p_contexto.id_registro;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'No se encontró registro de API para el id ' || p_contexto.id_registro);
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END finalizar_solicitud_con_metricas;

    PROCEDURE registrar_error_y_propagar(
        p_contexto          IN OUT NOCOPY tipo_contexto_solicitud_api,
        p_codigo_http       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_error     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_mensaje_excepcion IN VARCHAR2
    ) IS
    BEGIN
        finalizar_solicitud_con_metricas(
            p_contexto        => p_contexto,
            p_codigo_http     => p_codigo_http,
            p_mensaje_error   => p_mensaje_error,
            p_carga_respuesta => NULL
        );

        RAISE_APPLICATION_ERROR(
            num => NVL(p_codigo_http, -20001),
            msg => NVL(p_mensaje_excepcion, p_mensaje_error)
        );
    END registrar_error_y_propagar;
END IA_PKG_REGISTRO_SOLICITUD_API;

GRANT EXECUTE ON IA.IA_PKG_REGISTRO_SOLICITUD_API TO PR;
CREATE OR REPLACE SYNONYM PR.IA_PKG_REGISTRO_SOLICITUD_API FOR IA.IA_PKG_REGISTRO_SOLICITUD_API;