CREATE OR REPLACE PACKAGE BODY IA.IA_PKG_APIS IS
    gc_ms_per_day CONSTANT NUMBER := 86400000; -- 24h * 60m * 60s * 1000ms

    PROCEDURE begin_call(
        p_endpoint      IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo        IN IA.IA_API_LOGS.METODO%TYPE,
        p_usuario       IN IA.IA_API_LOGS.USUARIO%TYPE,
        p_ip_origen     IN IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        p_service_name  IN IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        p_params        IN IA.IA_API_LOGS.PARAMETROS%TYPE,
        p_log_rec       OUT t_log_rec
    ) IS
    BEGIN
        INSERT INTO IA.IA_API_LOGS (
            ID_LOG,
            ENDPOINT,
            METODO,
            USUARIO,
            IP_ORIGEN,
            SERVICE_NAME,
            PARAMETROS
        ) VALUES (
            IA.SEQ_API_LOGS.NEXTVAL,
            p_endpoint,
            UPPER(p_metodo),
            p_usuario,
            p_ip_origen,
            p_service_name,
            p_params
        ) RETURNING ID_LOG INTO p_log_rec.id_log;

        p_log_rec.start_ts := SYSTIMESTAMP;
        p_log_rec.endpoint := p_endpoint;
        p_log_rec.metodo   := UPPER(p_metodo);
        p_log_rec.usuario  := p_usuario;
        p_log_rec.ip_origen := p_ip_origen;
        p_log_rec.service_name := p_service_name;
    EXCEPTION
        WHEN OTHERS THEN
            p_log_rec.id_log := NULL;
            p_log_rec.start_ts := SYSTIMESTAMP;
            RAISE;
    END begin_call;

    PROCEDURE end_call(
        p_log_id        IN IA.IA_API_LOGS.ID_LOG%TYPE,
        p_status_code   IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_error_msg     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_response      IN IA.IA_API_LOGS.RESPONSE_MSG%TYPE,
        p_start_ts      IN TIMESTAMP DEFAULT NULL
    ) IS
        v_start TIMESTAMP := NVL(p_start_ts, SYSTIMESTAMP);
    BEGIN
        IF p_log_id IS NULL THEN
            RETURN; -- logging inicial falló
        END IF;

        UPDATE IA.IA_API_LOGS
           SET STATUS_CODE = p_status_code,
               ERROR_MSG   = p_error_msg,
               RESPONSE_MSG = p_response,
               TIEMPO_MS   = ROUND((SYSTIMESTAMP - v_start) * gc_ms_per_day, 2)
         WHERE ID_LOG = p_log_id;
    END end_call;

    PROCEDURE log_and_raise(
        p_log_rec     IN OUT NOCOPY t_log_rec,
        p_status_code IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_error_msg   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_raise_msg   IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        end_call(
            p_log_id      => p_log_rec.id_log,
            p_status_code => p_status_code,
            p_error_msg   => p_error_msg,
            p_response    => NULL,
            p_start_ts    => p_log_rec.start_ts
        );
        RAISE_APPLICATION_ERROR(
            num => NVL(p_status_code, -20001),
            msg => NVL(p_raise_msg, p_error_msg)
        );
    END log_and_raise;
END IA_PKG_APIS;
/

GRANT EXECUTE ON IA.IA_PKG_APIS TO PR;
CREATE OR REPLACE SYNONYM PR.IA_PKG_APIS FOR IA.IA_PKG_APIS;
