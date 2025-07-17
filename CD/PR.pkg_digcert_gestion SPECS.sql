CREATE OR REPLACE PACKAGE PR.pkg_digcert_gestion IS

    TYPE t_default_values IS RECORD (
        codigo_empresa VARCHAR2(1)  := '1',
        codigo_agencia VARCHAR2(5)  := '0',
        nombre_agencia VARCHAR2(80) := 'OFICINA PRINCIPAL'
    );

    TYPE t_cliente IS RECORD (
      client_id         VARCHAR2(15),
      cod_persona       VARCHAR2(15),
      nombre            VARCHAR2(240),
      cedula            VARCHAR2(30),
      cod_ejecutivo     VARCHAR2(30),
      cod_promotor      VARCHAR2(30),
      estado            CHAR(1),
      es_empleado       CHAR(1)
    );
    
    --Param de usuario selecciona
    --TYPE t_param_producto IS RECORD (
      --cod_producto      VARCHAR2(15),
      --monto_minimo      NUMBER(5),
      --plazo_dias        NUMBER(18,2)
    --);
    
    TYPE t_producto IS RECORD (
      --CD.PRODUCTO_X_EMPRESA
      cod_producto          VARCHAR2(15),
      pxe_monto_minimo      NUMBER(5),
      pxe_plazo_minimo      NUMBER(18,2),
      paga_renta            VARCHAR2(1),
      porcentaje_renta      NUMBER(8,4),
      base_calculo          NUMBER(3),
      base_plazo            NUMBER(3),
      ind_prd_emp           VARCHAR2(1), 
      ind_renovacion_auto   VARCHAR2(1),
      cod_cartera           VARCHAR2(10),
      forma_calculo_interes VARCHAR2(3),
      fre_capitaliza        VARCHAR2(1),
      cod_moneda            VARCHAR2(4),
      --DIA_DE_CAP_FRE_MES
      --CD_PRD_TASA_PLAZO_MONTO
      spread                NUMBER(8,4),
      operacion             VARCHAR2(1),
      ptpm_plazo_minimo     NUMBER(5),
      ptpm_plazo_maximo     NUMBER(5),
      ptpm_monto_minimo     NUMBER(17,2),
      ptpm_monto_maximo     NUMBER(17,2),
      cod_tasa              VARCHAR2(20),
      tasa_minima           NUMBER(10,6),
      tasa_maxima           NUMBER(10,6)
    );
    
    TYPE t_certificado_values IS RECORD (
      fecha_vencimiento     DATE,
      plazo_en_dias         NUMBER
    );
    TYPE t_tasas_calculadas IS RECORD (
        cod_tasa              VARCHAR2(20),
        spread                NUMBER(8,4),
        operacion             VARCHAR2(1),
        tasa_bruta_base       NUMBER,
        tasa_bruta_ajustada   NUMBER,
        tasa_neta_final       NUMBER
    );
    
    v_default_values  t_default_values;
    v_datos_cliente   t_cliente;
    v_producto t_producto;
    v_certificado_values t_certificado_values;
    v_tasas_calculadas     t_tasas_calculadas;

    PROCEDURE cargar_datos_cliente(p_client_id IN VARCHAR2, p_Error OUT VARCHAR2);
    PROCEDURE validar_lista_negra(p_client_id IN VARCHAR2, p_Error OUT VARCHAR2);
    PROCEDURE validar_lista_pep(p_client_id IN VARCHAR2, p_Error OUT VARCHAR2);
    PROCEDURE cargar_param_producto(p_cod_producto IN VARCHAR2, p_Error OUT VARCHAR2);
    PROCEDURE validar_param_producto(p_cod_producto IN VARCHAR2, p_plazo_dias IN NUMBER, p_monto IN NUMBER, p_Error OUT VARCHAR2);
    --CALCULA FECHA DE VENCIMIENTO
    PROCEDURE INICIAR_SIMULACION_CERTIFICADO (
        p_client_id       IN VARCHAR2,
        p_cod_producto    IN VARCHAR2,
        p_monto           IN NUMBER,
        p_plazo_dias      IN NUMBER,
        p_Error           OUT VARCHAR2);
    
    PROCEDURE CD_FECHA_EXACTA(
        p_fecha_inicial   IN DATE,
        p_calendario_base IN NUMBER,
        p_valor           IN NUMBER, 
        p_frecuencia      IN VARCHAR2,
        p_fecha_final     OUT DATE,
        p_total_dias      OUT NUMBER);
    
    PROCEDURE cd_calcula_dias(
        f_inicio         IN DATE,
        f_final          IN DATE,
        base_plazo       IN NUMBER,
        --p_frecuencia     IN VARCHAR2, 
        p_dias_resultado IN OUT NUMBER);
    --CALCULA FECHA DE VENCIMIENTO--
    
    PROCEDURE calcular_tasas_certificado(
        p_cod_empresa     IN VARCHAR2,
        p_cod_producto    IN VARCHAR2,
        p_plazo_dias      IN NUMBER,
        p_monto           IN NUMBER,
        p_fecha_calculo   IN DATE,
        p_Error            OUT VARCHAR2);

    PROCEDURE REGISTRAR_CERTIFICADO (
        p_client_id       IN VARCHAR2,
        p_cod_producto    IN VARCHAR2,
        p_monto           IN NUMBER,
        p_plazo_dias      IN NUMBER,
        p_cod_empresa     IN VARCHAR2,
        p_cuenta_debito   IN VARCHAR2, -- Cuenta de donde se debitarán los fondos
        p_usuario_solicitud IN VARCHAR2,

        -- Parámetros de SALIDA
        o_numero_certificado OUT VARCHAR2,
        o_estado_final       OUT VARCHAR2, -- 'ACTIVO' o 'ERROR'
        p_Error              OUT VARCHAR2
    );
    
END pkg_digcert_simulador;
/
