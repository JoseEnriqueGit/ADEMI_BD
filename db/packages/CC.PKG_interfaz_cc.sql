CREATE OR REPLACE PACKAGE BODY CC.PKG_interfaz_cc AS
    /******************************************************************************
       NAME:       pkg_interfaz_cc
       PURPOSE: crear cuentas de efectivo mediante un servicio o api

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        21/02/2024  fermin rodriguez 1. Package para el manejo de la
                                                  creacion de la cuenta efectivo Onboarding Digital.
       1.0        11/12/2024  JoseEsteban      #20241211 Change CONSULTA BUSCADOR DE GOOGLE CODE from 763 to 810
    ******************************************************************************/

    FUNCTION digito_verificador (pnumero   IN NUMBER,
                                 ptamano   IN NUMBER DEFAULT 11111111111111)
        RETURN NUMBER IS
        l_sum_digits   PLS_INTEGER := 0;
    BEGIN
        IF (LENGTH (TO_CHAR (pnumero)) > LENGTH (TO_CHAR (ptamano))) THEN
            raise_application_error ( -20111, 'Length of weight must be longer than ' || 'length of number');
        END IF;

        FOR i IN 1 .. (TRUNC (LOG (10, pnumero)) + 1) LOOP
            l_sum_digits := l_sum_digits + (  MOD (TRUNC (pnumero / POWER (10, (i - 1))), 10) * MOD (TRUNC (ptamano / POWER (10, (i - 1))), 10));
        END LOOP;

        RETURN (9 - MOD (l_sum_digits, 9));
    END;
    
    --Validacion de que el numero de cuenta no exista.
    FUNCTION validar_cuenta (pcuenta IN NUMBER)
        RETURN VARCHAR2 IS
        ncant      NUMBER := 0;
        cretorno   VARCHAR2 (1) := 'N';
    BEGIN
        BEGIN
            SELECT COUNT (*)
              INTO ncant
              FROM cuenta_efectivo
             WHERE num_cuenta = pcuenta;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ncant := 0;
        END;

        IF NVL (ncant, 0) = 0 THEN
            cretorno := 'S';
        ELSE
            cretorno := 'N';
        END IF;

        RETURN (cretorno);
    END;
    
    PROCEDURE crear_cuenta_efectivo_api (pSolicitudCuenta   IN CC.SOLICITUD_CUENTA_LIST, 
                                         pNumero_cuenta     IN OUT    VARCHAR2,
                                         pCodigoCliente     IN OUT    NUMBER,
                                         pErrornum          IN OUT    NUMBER,
                                         pMensaje_Error     IN OUT    VARCHAR2) IS
        vCanal       PA.CANAL_SOLICITUD_OBJ := PA.CANAL_SOLICITUD_OBJ(); 
        vEsCliente   NUMBER := 0;
        vTipoId      PA.ID_PERSONAS.COD_TIPO_ID%TYPE;
        vNumId       PA.ID_PERSONAS.NUM_ID%TYPE;
        vError       VARCHAR2(4000); 
    BEGIN
        FOR i IN 1 .. pSolicitudCuenta.COUNT LOOP
            CC.PKG_INTERFAZ_CC.crear_cuenta_efectivo (  pCodigo_empresa    => pSolicitudCuenta(i).codigo_empresa,
                                                        pCodigo_cliente    => pSolicitudCuenta(i).codigo_cliente,
                                                        pCodigo_producto   => pSolicitudCuenta(i).codigo_producto,
                                                        pcodigo_moneda     => pSolicitudCuenta(i).codigo_moneda,
                                                        pcodigo_agencia    => pSolicitudCuenta(i).codigo_agencia,                                     
                                                        pNumero_cuenta     => pNumero_cuenta,
                                                        pErrornum          => pErrornum,
                                                        pMensaje_Error     => pMensaje_Error);
                                                        
            DBMS_OUTPUT.PUT_LINE ( 'pNumero_cuenta = ' || pNumero_cuenta );                                            
            DBMS_OUTPUT.PUT_LINE ( 'pMensaje_Error = ' || pErrornum||'-'||pMensaje_Error );
            IF pNumero_cuenta IS NOT NULL AND  pMensaje_Error NOT LIKE 'Error%' THEN               
               pCodigoCliente := pSolicitudCuenta(i).codigo_cliente;
               
                IF pSolicitudCuenta(i).canal.COD_CANAL IS NOT NULL THEN
                   BEGIN
                       -- Guardar canal donde se origina la solicitud
                       vCanal := PA.CANAL_SOLICITUD_OBJ();  
                       vCanal := pSolicitudCuenta(i).canal;
                       vCanal.NUMERO_SOLICITUD := pNumero_cuenta;
                       vCanal.Crear();
                   EXCEPTION WHEN OTHERS THEN 
                       pErrornum := 404;
                       pMensaje_Error := 'Error determinando el canal de origen '||dbms_utility.format_error_backtrace;    
                       DBMS_OUTPUT.PUT_LINE ( 'Canal pMensaje_Error = ' || pMensaje_Error );  
                       RAISE_APPLICATION_ERROR(-20104, pMensaje_Error);
                   END; 
                END IF;
                
               
                DECLARE
                   vURL                 VARCHAR2(4000);
                   vIdAplication        PLS_INTEGER := 37; -- CUENTASDEAHORROS
                   vIdTipoDocumento     PLS_INTEGER := '618'; -- Formulario de Conozca
                   vCodigoReferencia    VARCHAR2(100) := pNumero_cuenta; --pCodigoCliente||':'||vSolicitudNumero;
                   vDocumento           VARCHAR2(30) := 'FCSCPF';               
                   vOrigenPkm           VARCHAR2(100) := 'Cuenta';
                   pCodigo_cliente      VARCHAR2(15) := pSolicitudCuenta(i).codigo_cliente;
                BEGIN
                     -- Detarmina el Origen PKM para el BGP
                    BEGIN
                         SELECT X.ORIGEN_PKM
                           INTO vOrigenPkm
                           from PA.CANAL_APLICACION X
                          where X.COD_SISTEMA = vCanal.COD_SISTEMA
                            and X.COD_CANAL = vCanal.COD_CANAL;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                       vOrigenPkm := 'Onboarding';
                    END;
                    
                    BEGIN
                        -- Verifica si el cliente existe
                        SELECT 1, C.CODIGO_TIPO_IDENTIFICACION, C.NUMERO_IDENTIFICACION 
                          INTO vEsCliente, vTipoId, vNumId              
                          FROM PA.CLIENTES_B2000 C
                         WHERE C.CODIGO_EMPRESA = '1'
                           AND C.CODIGO_CLIENTE = pCodigo_cliente;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vEsCliente := 0;
                    END;  
                
                   -- Generar Conozca Su Cliente para File Flow 
                   vDocumento       := 'FCSCPF';
                   vIdTipoDocumento := '618';
                   vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlConozcaSuCliente2(pCodCliente =>pCodigo_cliente, pEmpresa => '1');                   
                   PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => vOrigenPkm,  
                                                    pUrlReporte         => vUrl, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||pNumero_cuenta||'_'||pCodigo_cliente||'.pdf',   
                                                    pRespuesta          => vError
                                                   );
                    DBMS_OUTPUT.PUT_LINE ( 'FCSCPF vError = ' || vError );            
                                                                            
                    -- Generar Matriz Riesgo para File Flow 
                   vDocumento       := 'MRAVPF';
                   vIdTipoDocumento := '809';
                   vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlMatrizRiesgo(pCodCliente =>pCodigo_cliente);                   
                   PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => vOrigenPkm,  
                                                    pUrlReporte         => vUrl, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||pNumero_cuenta||'_'||pCodigo_cliente||'.pdf',   
                                                    pRespuesta          => vError
                                                   );
                    DBMS_OUTPUT.PUT_LINE ( 'MRAVPF vError = ' || vError );            
                    
                       
                    vIdTipoDocumento := '762';  -- CONSULTA BURO DE CREDITO PRIVADO 
                    vDocumento       := 'BURO';  
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||pNumero_cuenta||': :'||vDocumento||': '; 
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;                                                   
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => vOrigenPkm,  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||pNumero_cuenta||'_'||pCodigo_cliente||'.pdf',   
                                                    pEstado             => 'R',
                                                    pRespuesta          => vError
                                                   );
                    DBMS_OUTPUT.PUT_LINE ( 'BURO vError = ' || vError );
                    
                    vIdTipoDocumento := '810';  -- CONSULTA BUSCADOR DE GOOGLE  (previous 763 20241211)
                    vDocumento       := 'SIB';  
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||pNumero_cuenta||': :'||vDocumento;     
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;                                                                                                 
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => vOrigenPkm,  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||pNumero_cuenta||'_'||pCodigo_cliente||'.pdf',   
                                                    pEstado             => 'R',
                                                    pRespuesta          => vError
                                                   );
                    DBMS_OUTPUT.PUT_LINE ( 'SIB vError = ' || vError );
                    
                    -- Generar LEXISNEXIS para File Flow                                
                    vIdTipoDocumento := '621';
                    vDocumento := 'LEXISNEXIS';
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||pNumero_cuenta||': :'||vDocumento;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => vOrigenPkm,
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vDocumento||'_'||pNumero_cuenta||'_'||pCodigo_cliente||'.pdf',
                                pEstado             => 'R',
                                pRespuesta          => vError);                                                             
                    DBMS_OUTPUT.PUT_LINE ( 'LEXISNEXIS vError = ' || vError ); 
                EXCEPTION WHEN OTHERS THEN 
                   pErrornum := 404;
                   pMensaje_Error := 'Error '||vError||' '||dbms_utility.format_error_backtrace;      
                   RAISE_APPLICATION_ERROR(-20104, pMensaje_Error);
                END;
            ELSE
                RAISE_APPLICATION_ERROR(-20104, pMensaje_Error);
            END IF;
        END LOOP;
    END;

    --Creacion de la cuenta de Efectivo
    PROCEDURE crear_cuenta_efectivo (pCodigo_empresa    IN     varchar2,
                                     pCodigo_cliente    IN     number,
                                     pCodigo_producto   IN     varchar2,
                                     pcodigo_moneda     IN     varchar2,
                                     pcodigo_agencia    IN     varchar2,                                     
                                     pnumero_cuenta     IN OUT    varchar2,
                                     pErrornum          IN OUT    number,
                                     pMensaje_Error     IN OUT    varchar2) IS
                                     
        vcodsistctaman           VARCHAR2 (2) := param.parametro_x_empresa (pCodigo_empresa, 'PRSISTCTAMANC', 'PR');
        
        vcod_grupo_cierr         cuenta_efectivo.cod_grupo_cierr%TYPE   := param.parametro_x_empresa (pCodigo_empresa, 'CODGRPCIE_DEFAULTCTA', 'PR');
        vtip_correspond          cuenta_efectivo.tip_correspond%TYPE    := param.parametro_x_empresa (pCodigo_empresa, 'TIP_CORRESP_DEFAULT', 'PR');
        vcateg_cuenta            cuenta_efectivo.categ_cuenta%TYPE      := param.parametro_x_empresa (pCodigo_empresa, 'CATEG_CUENTA_DEFAULT', 'PR');
        vclase_cuenta            cuenta_efectivo.clase_cuenta%TYPE      := param.parametro_x_empresa (pCodigo_empresa, 'CLASE_CUENTA_DEFAULT', 'PR');
        vdigitover               VARCHAR2 (1) := '0';
        ptipo_relacion2          cuenta_cliente_relacion.tipo_relacion%TYPE;
        vsecuencia               VARCHAR2 (15);
        vprefijocuenta           VARCHAR2 (1) := '1';
        vcodoficial              VARCHAR2 (10);
        vesfisica                VARCHAR2 (1);
        v_sector                 pa.personas.cod_sec_contable%TYPE;
        vtipo_persona            clientes_b2000.tipo_de_persona%TYPE;
        vdesc_nombre             personas.nombre%TYPE;
        vnombre_chequera         cuenta_efectivo.nombre_chequera%TYPE;
        vtitulares               cuenta_efectivo.titulares%TYPE;
        vfircltcod_cliente       cuenta_cliente_relacion.codigo_cliente%TYPE;
        vfircltcod_cliente1      cuenta_cliente_relacion.codigo_cliente%TYPE;
        vfircltporcentaje        firmas_cliente.porcentaje%TYPE;
        vfircltnum_combinacion   firmas_cuentas.num_combinacion%TYPE;
        vfircltcod_categoria     firmas_cuentas.cod_categoria%TYPE;
        vfircltcantidad_firmas   firmas_cuentas.cantidad_firmas%TYPE;
        vfircltsigno             firmas_cuentas.signo%TYPE;
        vfircltmonto_max         firmas_cuentas.monto_max%TYPE;
        vfirclttippoder          firmas_cliente.tipo_poder%TYPE;
        vcod_ejecutivo           empleados.id_empleado%TYPE;
        vcod_agencia             empleados.cod_agencia_labora%TYPE;
        vobservacion_corta       cuenta_efectivo.observacion_corta%TYPE;
        vcod_direccion           cuenta_efectivo.cod_direccion%TYPE;
        vnum_cuenta              cuenta_efectivo.num_cuenta%TYPE;
        vfrec_calc_int           cuenta_efectivo.frec_calc_int%TYPE := 'D'; --'N';   --malmanzar
        vtip_asigna_tasa         cuenta_efectivo.tip_asigna_tasa%TYPE := 'G'; --'N'; --malmanzar
        vtip_asigna_carg         cuenta_efectivo.tip_asigna_carg%TYPE := 'G';
        vtip_car_adminis         cuenta_efectivo.tip_car_adminis%TYPE := 'N';
        vtip_capitalizac         cuenta_efectivo.tip_capitalizac%TYPE := 'M';
        vind_idioma              cuenta_efectivo.ind_idioma%TYPE := 'E';
        vind_solicitud           cuenta_efectivo.ind_solicitud%TYPE := 'N';
        vind_estado              cuenta_efectivo.ind_estado%TYPE := 1;
        vind_cta_alterna         cuenta_efectivo.ind_cta_alterna%TYPE := 'N';
        vind_trans_autom         cuenta_efectivo.ind_trans_autom%TYPE := 'N';
        vind_mancomunada         cuenta_efectivo.ind_mancomunada%TYPE := 'N';
        vind_impuesto            cuenta_efectivo.ind_impuesto%TYPE := 'S'; ---:= 'N'; --malmanzar 23-04-2018
        vind_pag_interes         cuenta_efectivo.ind_pag_interes%TYPE := 'N';
        vind_reserva_esp         cuenta_efectivo.ind_reserva_esp%TYPE := 'N';
        vcantidad_cheques        cuenta_efectivo.cantidad_cheques%TYPE := 0;
        vcant_cks_mes            cuenta_efectivo.cant_cks_mes%TYPE := 0;
        vcant_dep_mes            cuenta_efectivo.cant_dep_mes%TYPE := 0;
        vsal_total_cta           cuenta_efectivo.sal_total_cta%TYPE := 0;
        vsal_tot_dia_ant         cuenta_efectivo.sal_tot_dia_ant%TYPE := 0;
        vsal_reserva             cuenta_efectivo.sal_reserva%TYPE := 0;
        vsal_minimo              cuenta_efectivo.sal_minimo%TYPE := 0;
        vsal_consultado          cuenta_efectivo.sal_consultado%TYPE := 0;
        vsal_congelado           cuenta_efectivo.sal_congelado%TYPE := 0;
        vsal_embargado           cuenta_efectivo.sal_embargado%TYPE := 0;
        vsal_menor               cuenta_efectivo.sal_menor%TYPE := 0;
        vsal_promedio            cuenta_efectivo.sal_promedio%TYPE := 0;
        vsal_maximo              cuenta_efectivo.sal_maximo%TYPE := 0;
        vsal_al_cierre           cuenta_efectivo.sal_al_cierre%TYPE := 0;
        vsal_menor_mes           cuenta_efectivo.sal_menor_mes%TYPE := 0;
        vsal_promed_mes          cuenta_efectivo.sal_promed_mes%TYPE := 0;
        vsal_maximo_mes          cuenta_efectivo.sal_maximo_mes%TYPE := 0;
        vacumulad_imptos         cuenta_efectivo.acumulad_imptos%TYPE := 0;
        vmon_reserva_utl         cuenta_efectivo.mon_reserva_utl%TYPE := 0;
        vmon_sobgro_aut          cuenta_efectivo.mon_sobgro_aut%TYPE := 0;
        vmon_sob_no_aut          cuenta_efectivo.mon_sob_no_aut%TYPE := 0;
        vmon_sobgro_disp         cuenta_efectivo.mon_sobgro_disp%TYPE := 0;
        vmon_total_cargo         cuenta_efectivo.mon_total_cargo%TYPE := 0;
        vmonto_imptos            cuenta_efectivo.monto_imptos%TYPE := 0;
        vint_sobre_saldo         cuenta_efectivo.int_sobre_saldo%TYPE := 0;
        vint_cap_embargo         cuenta_efectivo.int_cap_embargo%TYPE := 0;
        vint_cap_congela         cuenta_efectivo.int_cap_congela%TYPE := 0;
        vint_cap_reserva         cuenta_efectivo.int_cap_reserva%TYPE := 0;
        vint_por_pagar           cuenta_efectivo.int_por_pagar%TYPE := 0;
        vint_sobgro_aut          cuenta_efectivo.int_sobgro_aut%TYPE := 0;
        vint_uso_sobgro          cuenta_efectivo.int_uso_sobgro%TYPE := 0;
        vsal_transito            cuenta_efectivo.sal_transito%TYPE := 0;
        vind_reserva_utl         cuenta_efectivo.ind_reserva_utl%TYPE := 'N';
        vint_sob_no_aut          cuenta_efectivo.int_sob_no_aut%TYPE := 0;
        vult_cke_entreg          cuenta_efectivo.ult_cke_entreg%TYPE := 0;
        vint_mes_actual          cuenta_efectivo.int_mes_actual%TYPE := 0;
        vind_sob_no_aut          cuenta_efectivo.ind_sob_no_aut%TYPE := 'S';
        vind_restringida         cuenta_efectivo.ind_restringida%TYPE := 'N';
        vcobra_cargo_inact       cuenta_efectivo.cobra_cargo_inact%TYPE := 'S';
        vcobra_cargo_sobgro      cuenta_efectivo.cobra_cargo_sobgro%TYPE := 'S';
        vcobra_cargo_chk_plaza   cuenta_efectivo.cobra_cargo_chk_plaza%TYPE := 'S';

        ---malmanzar 11-04-2018
        vind_sobgro              cuenta_efectivo.ind_sobgro%TYPE := 'N';
        vtas_interes             cuenta_efectivo.tas_interes%TYPE;
        vperiod_revisi           cuenta_efectivo.period_revisi%TYPE := 360;
        vfec_revision            cuenta_efectivo.fec_revision%TYPE := TRUNC (SYSDATE) + 360;
        vcod_tas_int             cuenta_efectivo.cod_tas_int%TYPE;
        vind_pag_int_reserva     cuenta_efectivo.ind_pag_int_reserva%TYPE := 'S';
        vind_tas_int_reserva     cuenta_efectivo.ind_tas_int_reserva%TYPE := 'P';
        vind_control_secuencia   cuenta_efectivo.ind_control_secuencia%TYPE := 'N';
        Vcod_grupo               cuenta_efectivo.cod_grupo%TYPE := '1';
        vExiste                  varchar2(1 byte):='';
        
        
    BEGIN
            
            pErrornum:=null;
            pMensaje_Error := NULL;
        Begin
        SELECT tip_tas_general,dias_base,tip_asigna_tasa
              Into vcod_tas_int,vperiod_revisi,vtip_asigna_tasa
              FROM  CC.RNG_CAL_INTERES  rng
             WHERE  rng.cod_producto=pcodigo_producto;
             exception
             when no_Data_found then
             pErrornum:=201;
             pMensaje_error:='Error Tasa no definida para este producto.';
             DBMS_OUTPUT.PUT_LINE ( 'pMensaje_error = ' || pMensaje_error );
             RAISE_APPLICATION_ERROR(-20101, pmensaje_error);
        End;
        --DBMS_OUTPUT.put_line ('Clientes: ' || pcodigo_cliente);
    if pErrornum is null then   
     Begin
        SELECT tip_capitalizac,ind_idioma,ind_cta_alterna,ind_impuesto,ind_pag_interes,ind_reserva_esp,frec_calc_int
              Into vtip_capitalizac,vind_idioma,vind_cta_alterna,vind_impuesto,vind_pag_interes,vind_reserva_esp,vfrec_calc_int
              FROM  CC.cara_x_producto  pro
               WHERE  pro.cod_producto=pcodigo_producto;
             exception
             when no_Data_found then
             vtip_capitalizac:='M';
             vind_idioma:='E';
             vind_cta_alterna:='N';
             vind_impuesto:='N';
             vind_reserva_esp:='N';
             vfrec_calc_int:='D';
             pErrornum:=202;
             pmensaje_error:='Error Producto no parametrizado en cara_x_producto.';
             DBMS_OUTPUT.PUT_LINE ( 'pmensaje_error = ' || pmensaje_error );
             RAISE_APPLICATION_ERROR(-20102, pmensaje_error);
        End;
      End if;
        
        IF INSTR (pcodigo_cliente, ',', 1) > 0 THEN
            vfircltcod_cliente := SUBSTR (pcodigo_cliente, 1, INSTR (pcodigo_cliente, ',', 1) - 1);
        ELSE
            vfircltcod_cliente := pcodigo_cliente;
        END IF;
        vfircltcod_cliente:=pcodigo_cliente;
        DBMS_OUTPUT.put_line ('Principal Cliente: ' || vfircltcod_cliente);
    DBMS_OUTPUT.PUT_LINE ( 'pErrornum = ' || pErrornum );
    if pErrornum is null then
        BEGIN
            SELECT b.nombre,
                   b.es_fisica,
                   nvl((select nvl(a.cod_oficial, gerente) from pa.agencia where cod_agencia=a.cod_agencia),a.cod_oficial) cod_oficial,
                   c.tipo_de_persona,
                   cod_sec_contable
              INTO vdesc_nombre,
                   vesfisica,
                   vcodoficial,
                   vtipo_persona,
                   v_sector
              FROM clientes_b2000 c, cliente a, personas b
             WHERE     (a.cod_empresa = pCodigo_empresa)
                   AND (a.cod_cliente = pcodigo_cliente)
                   AND (a.esta_activo = 'S')
                   AND (b.cod_persona = a.cod_cliente)
                   AND c.cod_cliente = a.cod_cliente
                   AND c.codigo_empresa = pCodigo_empresa;
        EXCEPTION
            WHEN no_data_found THEN
                DBMS_OUTPUT.put_line ('-20001,[CREA_CUENTA_EFECTIVO_AT]');
                pErrornum:=203;
                pMensaje_Error := 'Error buscando cliente ['||pcodigo_cliente||'] en la DB, favor verificar codigo de cliente';
                RAISE_APPLICATION_ERROR(-20103, pmensaje_error);
        END;
    end if;
        vnombre_chequera := SUBSTR (vdesc_nombre, 1, 200);
        --:bkctaefe.NOM_CLIENTE;
        vtitulares := vnombre_chequera;               --:bkctaefe.NOM_CLIENTE;
        vobservacion_corta := 'Cuenta Onboarding Digital';

        IF (vesfisica = 'S') THEN
            --vfircltcod_cliente := pCodigo_cliente;   --:bkctaefe.cod_cliente;
            vfircltporcentaje := 100;
            vfircltnum_combinacion := 1;
            vfircltcod_categoria := 'A';
            vfircltcantidad_firmas := 1;
            vfircltsigno := '>';
            vfircltmonto_max := 0.00;
            vfirclttippoder := param.parametro_x_empresa (pCodigo_empresa, 'TIPPODER_DEFAULTCTAN', 'PR');
        END IF;

        DBMS_OUTPUT.put_line ('vcodoficial: ' || vcodoficial);

        IF (vcodoficial IS NOT NULL) THEN
            BEGIN
                SELECT a.id_empleado                              --, b.nombre
                  INTO vcod_ejecutivo              --, :bkctaefe.nom_ejecutivo
                  FROM empleados a, personas b
                 WHERE     (a.cod_empresa = pCodigo_empresa)
                       AND (a.id_empleado = vcodoficial)
                       AND (b.cod_persona = a.cod_per_fisica);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.put_line ( '-20002,[CREA_CUENTA_EFECTIVO_AT] Cliente no tiene ejeciutivo asignado');
                    pErrornum:=204;
                    pMensaje_Error := 'Error buscando Ejecutivo del Cliente en la DB ('||vcodoficial||'), favor verificar codigo de cliente';
                    RAISE_APPLICATION_ERROR(-20104, pmensaje_error);
            END;

            -- HJORGE 19/02/2008 -- Agencia del Oficial
            BEGIN
                SELECT a.cod_agencia_labora                   --,b.descripcion
                  INTO vcod_agencia                            --,vdes_agencia
                  FROM empleados a, agencia b
                 WHERE     a.id_empleado = vcodoficial
                       AND a.cod_agencia_labora = b.cod_agencia;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.put_line ( '-20002,[CREA_CUENTA_EFECTIVO_AT] Buscando agencia ejecutivo');
                       pErrornum:=205;
                    pMensaje_Error := 'Error buscando codigo de empleado del Ejecutivo de Cuenta ('||vcodoficial||'), favor verificar codigo de cliente';
                    RAISE_APPLICATION_ERROR(-20105, pmensaje_error);
            END;
        END IF;

        --
        BEGIN
            SELECT cod_direccion                                   --, detalle
              INTO vcod_direccion                  --, :bkctaefe.des_direccion
              FROM dir_personas
             WHERE (cod_persona = pcodigo_cliente) --:bkctaefe.cod_cliente )
                                                      AND (ROWNUM = 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.put_line ( '-20002,[CREA_CUENTA_EFECTIVO_AT] Buscando direccion');
                pErrornum:=206;
                pMensaje_Error := 'Error buscando direccion del cliente en la DB, favor verificar codigo de cliente';
                RAISE_APPLICATION_ERROR(-20106, pmensaje_error);
        END;

        BEGIN
            SELECT prefijo_num_cuenta,
                   -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
                   NVL (ind_impuesto, 'N'),
                   NVL (IND_CTA_ALTERNA, 'N'),
                   NVL (IND_IDIOMA, 'E'),
                   NVL (IND_PAG_INTERES, 'N'),
                   NVL (IND_RESERVA_ESP, 'N'),
                   NVL (IND_SOLICITUD, 'N'),
                   NVL (IND_TRANS_AUTOM, 'N')
              -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
              INTO vprefijocuenta,
                   -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
                   vind_impuesto,
                   vind_cta_alterna,
                   vind_idioma,
                   vind_pag_interes,
                   vind_reserva_esp,
                   vind_solicitud,
                   vind_trans_autom
              -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
              FROM cara_x_producto
             WHERE     cod_empresa = pCodigo_empresa
                   AND cod_producto = pcodigo_producto;
        EXCEPTION
            WHEN OTHERS THEN
                vprefijocuenta := '1';
        END;

        LOOP
            vsecuencia := pcodigo_producto || vprefijocuenta || LPAD (pcodigo_cliente, 7, '0') || LPAD (TRUNC (DBMS_RANDOM.VALUE (0, 99)), 2, '0');
            DBMS_OUTPUT.put_line ('vsecuencia: ' || vsecuencia);
            vdigitover := digito_verificador (vsecuencia);
            DBMS_OUTPUT.put_line ('vdigitover: ' || vdigitover);
            vnum_cuenta := TO_NUMBER (vsecuencia || vdigitover);
            DBMS_OUTPUT.put_line ('Cuenta: ' || vnum_cuenta);
            EXIT WHEN validar_cuenta (vnum_cuenta) = 'S';
        -- AND LENGTH(vnum_cuenta) = 14;
        END LOOP;

        pNumero_cuenta := vnum_cuenta;

        BEGIN
            SELECT valor_actual
              INTO Vtas_interes
              FROM tasas_interes
             WHERE cod_empresa = 1 AND COD_TASA = Vcod_tas_int;
        EXCEPTION
            WHEN OTHERS THEN
                Vtas_interes := 0;
        END;


        BEGIN
            INSERT INTO cuenta_efectivo (cod_empresa,
                                         num_cuenta,
                                         cod_producto,
                                         cod_agencia,
                                         cod_cliente,
                                         cod_direccion,
                                         cod_grupo_cierr,
                                         cod_ejecutivo,
                                         clase_cuenta,
                                         categ_cuenta,
                                         frec_calc_int,
                                         tip_asigna_tasa,
                                         tip_asigna_carg,
                                         tip_car_adminis,
                                         tip_capitalizac,
                                         tip_correspond,
                                         ind_idioma,
                                         ind_solicitud,
                                         ind_estado,
                                         ind_cta_alterna,
                                         ind_trans_autom,
                                         ind_mancomunada,
                                         ind_impuesto,
                                         ind_pag_interes,
                                         ind_reserva_esp,
                                         cantidad_cheques,
                                         cant_cks_mes,
                                         cant_dep_mes,
                                         sal_total_cta,
                                         sal_tot_dia_ant,
                                         sal_reserva,
                                         sal_minimo,
                                         sal_consultado,
                                         sal_congelado,
                                         sal_embargado,
                                         sal_menor,
                                         sal_promedio,
                                         sal_maximo,
                                         sal_al_cierre,
                                         sal_menor_mes,
                                         sal_promed_mes,
                                         sal_maximo_mes,
                                         acumulad_imptos,
                                         mon_reserva_utl,
                                         mon_sobgro_aut,
                                         mon_sob_no_aut,
                                         mon_sobgro_disp,
                                         mon_total_cargo,
                                         monto_imptos,
                                         int_sobre_saldo,
                                         int_cap_embargo,
                                         int_cap_congela,
                                         int_cap_reserva,
                                         int_por_pagar,
                                         int_sobgro_aut,
                                         int_uso_sobgro,
                                         sal_transito,
                                         ind_reserva_utl,
                                         int_sob_no_aut,
                                         ult_cke_entreg,
                                         int_mes_actual,
                                         ind_sob_no_aut,
                                         ind_restringida,
                                         cobra_cargo_inact,
                                         cobra_cargo_sobgro,
                                         cobra_cargo_chk_plaza,
                                         observacion_corta,
                                         titulares,
                                         nombre_chequera,
                                         fec_apertura,
                                         ind_sobgro,
                                         tas_interes,
                                         period_revisi,
                                         fec_revision,
                                         cod_tas_int,
                                         ind_pag_int_reserva,
                                         ind_tas_int_reserva,
                                         ind_control_secuencia,
                                         cod_grupo)
                 VALUES (pCodigo_empresa,
                         vnum_cuenta,
                         pcodigo_producto,
                         pcodigo_agencia,
                         pcodigo_cliente,
                         vcod_direccion,
                         vcod_grupo_cierr,
                         vcod_ejecutivo,
                         vclase_cuenta,
                         vcateg_cuenta,
                         vfrec_calc_int,
                         vtip_asigna_tasa,
                         vtip_asigna_carg,
                         vtip_car_adminis,
                         vtip_capitalizac,
                         vtip_correspond,
                         vind_idioma,
                         vind_solicitud,
                         vind_estado,
                         vind_cta_alterna,
                         vind_trans_autom,
                         vind_mancomunada,
                         vind_impuesto,
                         vind_pag_interes,
                         vind_reserva_esp,
                         vcantidad_cheques,
                         vcant_cks_mes,
                         vcant_dep_mes,
                         vsal_total_cta,
                         vsal_tot_dia_ant,
                         vsal_reserva,
                         vsal_minimo,
                         vsal_consultado,
                         vsal_congelado,
                         vsal_embargado,
                         vsal_menor,
                         vsal_promedio,
                         vsal_maximo,
                         vsal_al_cierre,
                         vsal_menor_mes,
                         vsal_promed_mes,
                         vsal_maximo_mes,
                         vacumulad_imptos,
                         vmon_reserva_utl,
                         vmon_sobgro_aut,
                         vmon_sob_no_aut,
                         vmon_sobgro_disp,
                         vmon_total_cargo,
                         vmonto_imptos,
                         vint_sobre_saldo,
                         vint_cap_embargo,
                         vint_cap_congela,
                         vint_cap_reserva,
                         vint_por_pagar,
                         vint_sobgro_aut,
                         vint_uso_sobgro,
                         vsal_transito,
                         vind_reserva_utl,
                         vint_sob_no_aut,
                         vult_cke_entreg,
                         vint_mes_actual,
                         vind_sob_no_aut,
                         vind_restringida,
                         vcobra_cargo_inact,
                         vcobra_cargo_sobgro,
                         vcobra_cargo_chk_plaza,
                         vobservacion_corta,
                         vtitulares,
                         vnombre_chequera,
                         TRUNC (SYSDATE),
                         vind_sobgro,
                         vtas_interes,
                         vperiod_revisi,
                         vfec_revision,
                         vcod_tas_int,
                         vind_pag_int_reserva,
                         vind_tas_int_reserva,
                         vind_control_secuencia,
                         vcod_grupo);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.put_line ('error: ' || SQLERRM);
                pErrornum:=207;
                pMensaje_Error := 'Error creando Cuenta del cliente, favor verificar codigo de cliente '||SQLERRM ;
                RAISE_APPLICATION_ERROR(-20107, pmensaje_error);
        END;

        IF vnum_cuenta IS NOT NULL AND pMensaje_Error IS NULL THEN
            --update consec_agencia_prod set secuencia_cta = vnumero+1
            --where cod_agencia=vcodagencia2 and cod_producto=vcod_productof;
            pnumero_cuenta:=vnum_cuenta;
            begin
           
                INSERT INTO cuenta_cliente_relacion (num_cuenta,
                                                     codigo_cliente,
                                                     tipo_relacion,
                                                     principal,
                                                     cod_sistema,
                                                     estado,
                                                     numero_linea)
                     VALUES (vnum_cuenta,
                             vfircltcod_cliente,
                             NULL,
                             'S',
                             vcodsistctaman,
                             'A',
                             '1');
            
            end;
            
            Begin
                Select 'S' 
                into vExiste 
                from cc.cuenta_efectivo cta
                where num_cuenta=vnum_cuenta;
                exception
                when no_data_found then
                pErrornum:=210;
                pMensaje_Error := 'Error No se pudo crear  la cuenta, favor verificar parámetros.';
                vExiste:='N';
            end;
            If vExiste='S' then                
                crear_matriz_riesgos (pCodigo_empresa, pCodigo_cliente, pMensaje_Error);
                COMMIT;
                pErrornum:=200;
                pMensaje_Error := 'Cuenta creada satisfactoriamente.';
                
            else
                pErrornum:=210;
                pMensaje_Error := 'Error No se pudo crear  la cuenta, favor verificar parámetros.';
                rollback;
            End If;
        --vcod_productof;--vnumero, vcodagencia2
        END IF;
        
    COMMIT;
    --vnumcuentacreado := vnum_cuenta;
    EXCEPTION
    /*    WHEN NO_DATA_FOUND THEN
            pMumero_cuenta := NULL;
            pErrornum:=208;
            pMensaje_Error := '1-Error creando cuenta, favor verificar codigo';*/
        WHEN OTHERS THEN
            pnumero_cuenta := NULL;
            /*pErrornum:=209;
            pMensaje_Error := '2-Error creando cuenta, favor verificar codigo';*/
    END;
    
 PROCEDURE crear_matriz_riesgos (pCodigo_empresa         IN     VARCHAR2,
                                 pCodigo_cliente         IN     number,
                                 pMensaje_Error          OUT    VARCHAR2) is
                                
                                
      Begin
        insert into PA.EVALUACION_PERSONA 
                  (COD_PERSONA      ,
                  COD_PREGUNTA      ,
                  COD_RESPUESTA     ,
                  SCORING           ,
                  FECHA_EVALUACION  ,
                  INCLUIDO_POR      ,
                  FEC_INCLUSION     )
          select pcodigo_cliente,t1.cod_pregunta,t1.cod_respuesta,res.valor,trunc(sysdate),user,sysdate
          from PA.MATRIZ_RIESGO_ONBOARDING t1, PA.RESPUESTA_PREGUNTA_EVALUACION res
          where t1.cod_pregunta=res.cod_pregunta and
          t1.cod_respuesta=res.cod_respuesta
          and not exists
          (select 1 from  PA.EVALUACION_PERSONA mat
          where mat.cod_persona=pcodigo_cliente 
          and cod_pregunta=mat.cod_pregunta
          and cod_respuesta=mat.cod_respuesta);
          EXCEPTION
          WHEN OTHERS THEN
          pMensaje_Error:=('Ha ocurrido un eror inesperado' ||SQLERRM);
          
        End;
END pkg_interfaz_cc;
/