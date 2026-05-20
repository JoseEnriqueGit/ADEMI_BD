PROCEDURE P_Registra_Solicitud_Campana(
    pIdReprestamo     IN     VARCHAR2,
    pTipo_Credito     IN     NUMBER,
    pUsuario          IN     VARCHAR2,
    pMensaje          IN OUT VARCHAR2
) IS
    vCodCliente             CLIENTES_B2000.COD_CLIENTE%TYPE;
    vNombres                CLIENTES_B2000.NOMBRES%TYPE;
    vApellidos              CLIENTES_B2000.NOMBRES%TYPE;
    vIdentificacion         CLIENTES_B2000.NUMERO_IDENTIFICACION%TYPE;
    vSexo                   CLIENTES_B2000.SEXO%TYPE;
    vFec_Nacimiento         CLIENTES_B2000.FECHA_DE_NACIMIENTO%TYPE;
    vNacionalidad           PA.PERSONAS_FISICAS.NACIONALIDAD%TYPE;
    vEstadoCivil            CLIENTES_B2000.ESTADO_CIVIL%TYPE;
    vCorreo                 PA.PERSONAS_FISICAS.EMAIL_USUARIO%TYPE;
    vIdreprestamoSolicitud  PR.PR_SOLICITUD_REPRESTAMO.ID_REPRESTAMO%TYPE;
    vPersonaFisica          PA.PERSONAS_FISICAS_OBJ;
    vDirPersona             PA.DIR_PERSONAS_OBJ;
    vTelPersona             PA.TEL_PERSONAS_OBJ;
    vTelefonoCelular        VARCHAR2(15);
    v_Telefono_Celular      VARCHAR2(15);
    vTelefonoResidencia     VARCHAR2(15);
    vTelefonoTrabajo        VARCHAR2(15);
    vCodDireccion           PA.DIR_PERSONAS.COD_DIRECCION%TYPE;
    vTipDireccion           PA.DIR_PERSONAS.TIP_DIRECCION%TYPE;
    vDireccion              PA.DIR_PERSONAS.DETALLE%TYPE;
    vCodArea                VARCHAR2(3);
    vNumTel                 VARCHAR2(10);           
    NUEVO_TIPO              NUMBER;
    CREDITO                 NUMBER;
BEGIN
    BEGIN
        SELECT R.CODIGO_CLIENTE
          INTO vCodCliente
          FROM PR.PR_REPRESTAMOS r
         WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND r.ID_REPRESTAMO = pIdReprestamo;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            pMensaje := 'Datos del Represtamo no encontrados';
            RAISE_APPLICATION_ERROR(-20100, pMensaje);
    END;    
    
    BEGIN
       SELECT CELULAR INTO v_Telefono_Celular
       FROM PR.PR_CAMPANA_ESPECIALES C
       JOIN PR.PR_REPRESTAMOS R ON C.NO_CREDITO = R.NO_CREDITO
       WHERE R.ID_REPRESTAMO = pIdReprestamo AND C.ESTADO='T' AND ROWNUM=1;
    END;
    
    BEGIN
        SELECT R.ID_REPRESTAMO
          INTO vIdreprestamoSolicitud
          FROM PR.PR_SOLICITUD_REPRESTAMO r
         WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND r.ID_REPRESTAMO = pIdReprestamo;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            vIdreprestamoSolicitud := 0;
    END;
    
    IF vCodCliente IS NOT NULL THEN
        p_datos_primarios(vCodCliente, vNombres, vApellidos, vIdentificacion, vSexo, vFec_Nacimiento, vNacionalidad, vEstadoCivil, pMensaje);
        p_datos_secundarios(vCodCliente, vTelefonoCelular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, vCodDireccion, vTipDireccion, vDireccion, pMensaje);                                     
      
        IF vIdreprestamoSolicitud = 0 THEN   
            BEGIN
                INSERT INTO PR.PR_SOLICITUD_REPRESTAMO
                  (CODIGO_EMPRESA, ID_REPRESTAMO, NOMBRES, APELLIDOS, IDENTIFICACION, FEC_NACIMIENTO, SEXO, NACIONALIDAD, ESTADO_CIVIL, TELEFONO_CELULAR, TELEFONO_RESIDENCIA, TELEFONO_TRABAJO, EMAIL, COD_DIRECCION, TIP_DIRECCION, DIRECCION, PLAZO, OPCION_RECHAZO, NO_CREDITO, ESTADO, ADICIONADO_POR, FECHA_ADICION, COD_PAIS, TIPO_CREDITO) 
                VALUES
                (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, vNombres, vApellidos, vIdentificacion, vFec_Nacimiento, vSexo, vNacionalidad, vEstadoCivil, v_Telefono_Celular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, NULL, NULL, vDireccion, NULL, NULL, NULL, 'A', pUsuario, SYSDATE, '1', pTipo_Credito);
            EXCEPTION 
                WHEN OTHERS THEN
                    pMensaje := 'Error Insertando los datos de la solicitud: '  || SQLERRM;
                    RAISE_APPLICATION_ERROR(-20100, pMensaje);
            END;
        END IF;
    END IF;

    BEGIN 
        CREDITO := PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO(pIdReprestamo);
        
        IF CREDITO = 1 THEN
            DBMS_OUTPUT.PUT_LINE('CREDITO1 = ' || CREDITO);
            DBMS_OUTPUT.PUT_LINE('pIdReprestamo1 = ' || pIdReprestamo);
            PR.PR_PKG_REPRESTAMOS.p_generar_bitacora(pIdReprestamo, NULL, 'AN', NULL, 'Represtamo anulado por salto de Tipo Credito', USER);
            UPDATE PR.PR_SOLICITUD_REPRESTAMO 
            SET ESTADO = 'AN' 
            WHERE ID_REPRESTAMO = pIdReprestamo;
            
            UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Represtamo anulado por salto de Tipo Credito',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
            WHERE ESTADO='T' AND NO_CREDITO = (SELECT NO_CREDITO FROM PR.PR_REPRESTAMOS WHERE ID_REPRESTAMO = pIdReprestamo );
        ELSE
            DBMS_OUTPUT.PUT_LINE('CREDITO = ' || CREDITO);
            DBMS_OUTPUT.PUT_LINE('pIdReprestamo = ' || pIdReprestamo);
            IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
                UPDATE PR.PR_SOLICITUD_REPRESTAMO 
                SET TIPO_CREDITO = CREDITO 
                WHERE ID_REPRESTAMO = pIdReprestamo;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontraron datos para la consulta.');
        WHEN OTHERS THEN
            DECLARE
                vIdError PLS_INTEGER := 0;
            BEGIN
                IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo', pIdReprestamo);
                IA.LOGGER.ADDPARAMVALUEV('pUsuario', pUsuario);        
                IA.LOGGER.ADDPARAMVALUEV('NUEVO_TIPO_CREDITO', NUEVO_TIPO);                          
                setError(pProgramUnit => 'P_Registra_Solicitud_Campana_Tipo_Credito', 
                         pPieceCodeName => NULL, 
                         pErrorDescription => SQLERRM,                                                              
                         pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                         pEmailNotification => NULL, 
                         pParamList => IA.LOGGER.vPARAMLIST, 
                         pOutputLogger => FALSE, 
                         pExecutionTime => NULL, 
                         pIdError => vIdError); 
            END;
    END;

    IF pIdReprestamo IS NOT NULL AND F_Validar_Telefono(v_Telefono_Celular) IS NOT NULL THEN
        INSERT INTO PR.PR_CANALES_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION)
        VALUES (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, 4, F_Validar_Telefono(v_Telefono_Celular), pUsuario, SYSDATE);
    END IF;

    COMMIT;
EXCEPTION 
    WHEN OTHERS THEN
        DECLARE
            vIdError PLS_INTEGER := 0;
        BEGIN
            IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo', pIdReprestamo);
            IA.LOGGER.ADDPARAMVALUEV('pUsuario', pUsuario);        
            IA.LOGGER.ADDPARAMVALUEV('NUEVO_TIPO_CREDITO', NUEVO_TIPO);    
            setError(pProgramUnit => 'P_Registra_Solicitud_Campana', 
                     pPieceCodeName => NULL, 
                     pErrorDescription => SQLERRM,                                                              
                     pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                     pEmailNotification => NULL, 
                     pParamList => IA.LOGGER.vPARAMLIST, 
                     pOutputLogger => FALSE, 
                     pExecutionTime => NULL, 
                     pIdError => vIdError); 
        END;
END P_Registra_Solicitud_Campana;