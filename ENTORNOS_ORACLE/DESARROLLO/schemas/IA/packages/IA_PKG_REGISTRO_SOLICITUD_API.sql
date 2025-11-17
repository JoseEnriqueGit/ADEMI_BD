CREATE OR REPLACE PACKAGE IA.IA_PKG_REGISTRO_SOLICITUD_API IS
    /*
      Servicio de logging para invocaciones ORDS.
      Aporta un contrato con nomenclatura descriptiva, validaciones tempranas
      y control explícito del nivel de detalle almacenado en IA_API_LOGS.
    */
    SUBTYPE t_metodo_http IS IA.IA_API_LOGS.METODO%TYPE;
    SUBTYPE t_ruta_endpoint IS IA.IA_API_LOGS.ENDPOINT%TYPE;

    TYPE tipo_contexto_solicitud_api IS RECORD (
        id_registro        IA.IA_API_LOGS.ID_LOG%TYPE,
        fecha_inicio       TIMESTAMP,
        ruta_endpoint      IA.IA_API_LOGS.ENDPOINT%TYPE,
        metodo_http        t_metodo_http,
        identificador_cli  IA.IA_API_LOGS.USUARIO%TYPE,
        ip_cliente         IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        nombre_servicio    IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        nivel_log          IA.IA_API_LOGS.LOG_LEVEL%TYPE,
        es_sensible        IA.IA_API_LOGS.IS_SENSITIVE%TYPE
    );

    PROCEDURE iniciar_registro_solicitud(
        p_ruta_endpoint     IN IA.IA_API_LOGS.ENDPOINT%TYPE,
        p_metodo_http       IN IA.IA_API_LOGS.METODO%TYPE,
        p_identificador_cli IN IA.IA_API_LOGS.USUARIO%TYPE,
        p_ip_cliente        IN IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        p_nombre_servicio   IN IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        p_carga_util        IN CLOB,
        p_nivel_log         IN IA.IA_API_LOGS.LOG_LEVEL%TYPE DEFAULT 'INFO',
        p_marcar_sensible   IN IA.IA_API_LOGS.IS_SENSITIVE%TYPE DEFAULT 'N',
        p_contexto          OUT tipo_contexto_solicitud_api
    );

    PROCEDURE finalizar_solicitud_con_metricas(
        p_contexto          IN OUT NOCOPY tipo_contexto_solicitud_api,
        p_codigo_http       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_error     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_carga_respuesta   IN CLOB
    );

    PROCEDURE registrar_error_y_propagar(
        p_contexto          IN OUT NOCOPY tipo_contexto_solicitud_api,
        p_codigo_http       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_error     IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_mensaje_excepcion IN VARCHAR2 DEFAULT NULL
    );
END IA_PKG_REGISTRO_SOLICITUD_API;
/