PROMPT === ORDS Handler Example: Represtamo Front Options ===
DECLARE
    v_ctx               IA_PKG_APIS.tipo_contexto_bitacora_api;
    v_endpoint CONSTANT VARCHAR2(200) := 'represtamos/opcion-front';
    v_metodo            VARCHAR2(10)  := NVL(
        ORDS.GET_PARAMETER(:request_headers, 'REQUEST_METHOD'),
        :method
    );
    v_ip_cliente        VARCHAR2(50)  := ORDS.GET_PARAMETER(:request_headers, 'X-Forwarded-For');
    v_usuario           VARCHAR2(100) := NVL(:pUsuario, USER);
    v_payload           CLOB          := :body;
BEGIN
    IA_PKG_APIS.iniciar_bitacora_api(
        p_ruta_endpoint     => v_endpoint,
        p_metodo_http       => v_metodo,
        p_identificador_cli => v_usuario,
        p_ip_cliente        => v_ip_cliente,
        p_nombre_servicio   => 'PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT',
        p_carga_util        => v_payload,
        p_contexto          => v_ctx
    );

    PR.PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_FRONT(
        P_ID_REPRESTAMO           => :PIDREPRESTAMO,
        P_MONTO                   => :PMONTO,
        P_PLAZO                   => :PPLAZO,
        P_CALCULA_SEGURO_MYPIME   => :PCALCULASEGUROMYPIME,
        P_CALCULA_SEGURO_DESEMP   => :PCALCULASEGURODESEMPLEO,
        P_MONTO_APROBADO          => :MONTOAPROBADO,
        P_MONTO_CANCELACION       => :MONTOCANCELACION,
        P_MONTO_DEPOSITAR         => :MONTODEPOSITAR,
        P_MONTO_CUOTA             => :MONTOCUOTA,
        P_MONTO_CARGO             => :MONTOCARGO,
        P_MONTO_SEGURO_VIDA       => :MONTOSEGUROVIDA,
        P_MONTO_SEGURO_DESEMPLEO  => :MONTODESEMPLEO,
        P_MONTO_MYPIME            => :MONTOMYPIME,
        P_MONTO_CUOTA_TOTAL       => :MONTOCUOTATOTAL,
        P_TASA                    => :TASA,
        P_PLAZO_RESP              => :PLAZO,
        P_MENSAJE_ERROR           => :PMENSAJEERROR
    );
    COMMIT;

    IA_PKG_APIS.finalizar_bitacora_api(
        p_contexto           => v_ctx,
        p_codigo_estado      => 200,
        p_mensaje_respuesta  => 'Respuesta generada exitosamente.',
        p_carga_respuesta    => NULL,
        p_respuesta_es_error => FALSE
    );

    :status      := 200;
    :message     := 'Operación exitosa';
    :response    := JSON_OBJECT(
        'montoAprobado'    VALUE :MONTOAPROBADO,
        'montoCuota'       VALUE :MONTOCUOTA,
        'mensajeTecnico'   VALUE :PMENSAJEERROR
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Guardamos la excepción sin volver a exponer datos sensibles al consumidor.
        IA_PKG_APIS.finalizar_bitacora_api(
            p_contexto           => v_ctx,
            p_codigo_estado      => 500,
            p_mensaje_respuesta  => SQLERRM,
            p_carga_respuesta    => NULL,
            p_respuesta_es_error => TRUE
        );

        :status  := 500;
        :message := 'Ha ocurrido un error consumiendo este recurso';
        :response := JSON_OBJECT('codigo' VALUE 500, 'detalle' VALUE :message);
END;
/
