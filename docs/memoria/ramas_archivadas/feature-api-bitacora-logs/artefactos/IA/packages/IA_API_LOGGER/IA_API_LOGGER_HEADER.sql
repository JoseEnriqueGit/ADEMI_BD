/*******************************************************************************
** Paquete: IA_API_LOGGER
** Autor: Área de Desarrollo - ADEMI
** Fecha: 2025-11-18
**
** Decisión de Diseño:
**   Utiliza TRANSACCIONES AUTÓNOMAS en todos los procedimientos para garantizar
**   que los logs se persistan incluso si la transacción principal hace ROLLBACK.
**   Esto permite auditar incluso las operaciones fallidas.
**
** Uso:
**   DECLARE
**     v_ctx IA_API_LOGGER.tipo_contexto_log;
**   BEGIN
**     IA_API_LOGGER.iniciar_log('/api/v1/usuarios', 'POST', 
**                               p_carga_util => '{"nombre":"Juan"}',
**                               p_contexto => v_ctx);
**     -- ... lógica de negocio ...
**     IA_API_LOGGER.finalizar_log(v_ctx, 200, 'Usuario creado');
**   END;
*******************************************************************************/

CREATE OR REPLACE PACKAGE IA.IA_API_LOGGER IS

    SUBTYPE t_metodo_http IS IA.IA_API_LOGS.METODO%TYPE;
    SUBTYPE t_ruta_endpoint IS IA.IA_API_LOGS.ENDPOINT%TYPE;
    SUBTYPE t_nivel_log IS IA.IA_API_LOGS.LOG_LEVEL%TYPE;

    TYPE tipo_contexto_log IS RECORD (
        id_log             IA.IA_API_LOGS.ID_LOG%TYPE,
        fecha_inicio       TIMESTAMP,
        ruta_endpoint      IA.IA_API_LOGS.ENDPOINT%TYPE,
        metodo_http        t_metodo_http,
        identificador_cli  IA.IA_API_LOGS.USUARIO%TYPE,
        ip_cliente         IA.IA_API_LOGS.IP_ORIGEN%TYPE,
        nombre_servicio    IA.IA_API_LOGS.SERVICE_NAME%TYPE,
        nivel_log          t_nivel_log,
        indicador_sensible IA.IA_API_LOGS.IS_SENSITIVE%TYPE
    );

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
    );

    PROCEDURE finalizar_log(
        p_contexto            IN OUT NOCOPY tipo_contexto_log,
        p_codigo_estado       IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_respuesta   IN IA.IA_API_LOGS.ERROR_MSG%TYPE DEFAULT NULL,
        p_carga_respuesta     IN CLOB DEFAULT NULL,
        p_respuesta_es_error  IN BOOLEAN DEFAULT NULL
    );

    PROCEDURE registrar_error_y_propagar(
        p_contexto          IN OUT NOCOPY tipo_contexto_log,
        p_codigo_estado     IN IA.IA_API_LOGS.STATUS_CODE%TYPE,
        p_mensaje_tecnico   IN IA.IA_API_LOGS.ERROR_MSG%TYPE,
        p_detalle_excepcion IN VARCHAR2 DEFAULT NULL
    );

END IA_API_LOGGER;
/
