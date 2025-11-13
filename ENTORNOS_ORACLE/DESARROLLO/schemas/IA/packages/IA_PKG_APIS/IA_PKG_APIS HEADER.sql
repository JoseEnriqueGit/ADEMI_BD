CREATE OR REPLACE PACKAGE IA.IA_PKG_APIS IS
    /*
      Prototipo de componente para registrar invocaciones ORDS.
      Centraliza el acceso a IA_API_LOGS usando un contrato único para todos los módulos.
    */
    TYPE t_log_rec IS RECORD (
        id_log       IA.IA_API_LOGS.ID_LOG%TYPE,
        start_ts     TIMESTAMP,
        endpoint     IA.IA_API_LOGS.ENDPOINT%TYPE,
        metodo       IA.IA_API_LOGS.METODO%TYPE,
        usuario      IA.IA_API_LOGS.USUARIO%TYPE,
        ip_origen    IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        service_name IA.IA_API_LOGS.SERVICE_NAME%TYPE
    );

    PROCEDURE begin_call(
        p_endpoint      IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo        IN IA.IA_API_LOGS.METODO%TYPE,
        p_usuario       IN IA.IA_API_LOGS.USUARIO%TYPE,
        p_ip_origen     IN IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        p_service_name  IN IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        p_params        IN IA.IA_API_LOGS.PARAMETROS%TYPE,
        p_log_rec       OUT t_log_rec
    );

    PROCEDURE end_call(
        p_log_id        IN IA.IA_API_LOGS.ID_LOG%TYPE,
        p_status_code   IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_error_msg     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_response      IN IA.IA_API_LOGS.RESPONSE_MSG%TYPE,
        p_start_ts      IN TIMESTAMP DEFAULT NULL
    );

    PROCEDURE log_and_raise(
        p_log_rec     IN OUT NOCOPY t_log_rec,
        p_status_code IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_error_msg   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_raise_msg   IN VARCHAR2 DEFAULT NULL
    );
END IA_PKG_APIS;
/
