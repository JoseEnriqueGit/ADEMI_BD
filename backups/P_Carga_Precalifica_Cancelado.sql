PROCEDURE P_Carga_Precalifica_Cancelado ( pMensaje IN OUT VARCHAR2) IS
BEGIN
    --Crear bitacora Cabecera
    PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_CAB ( 'RD_CARGA_PRECALIFICACION', 'ACTIVO', Null,pMensaje);

    DECLARE
        CURSOR CUR_REPRESTAMO IS 
            SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
            FROM PR_REPRESTAMOS
            WHERE ESTADO = 'RE';
                         
        CURSOR CUR_REPRESTAMO_XCORE IS 
            SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
            FROM PR_REPRESTAMOS
            WHERE ESTADO = 'RE';
           
        VMSG  VARCHAR2(4000);
        v_Id_Represtamo  VARCHAR2(400);
        v_conteo  NUMBER(10);
        v_ini DATE;
        v_fin DATE;
        v_seg NUMBER(10);
        VALOR VARCHAR(400);
         
        --ESTO ES DE BITACORA
        VIDCABECERA NUMBER;
        pIDAPLICACION1 NUMBER;
        pIDAPLICACION2 NUMBER;
        pIDAPLICACION3 NUMBER;
        pIDAPLICACION4 NUMBER;
        pIDAPLICACION5 NUMBER;
        pIDAPLICACION6 NUMBER;
        pIDAPLICACION7 NUMBER;
        pIDAPLICACION8 NUMBER;
        pIDAPLICACION9 NUMBER;
        pIDAPLICACION10 NUMBER;
        pIDAPLICACION11 NUMBER;

        --Variable para el resultado del split
        v_error_split VARCHAR2(4000);
         
    BEGIN
        SELECT MAX(APC.ID_APLICACION_PASO_CAB) 
        INTO VIDCABECERA 
        FROM PR.PR_APLICACION_PASO_CAB APC 
        JOIN PR.PR_APLICACION A ON A.ID_APLICACION=APC.ID_APLICACION 
        WHERE CODIGO_APLICACION='RD_CARGA_PRECALIFICACION';
                            
        --INICIALIZO EL PROCESO
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_CAB ( VIDCABECERA, 'INICIADO',0, 'PROCESO INICIADO', PMENSAJE );
        
        --1  
        PR.PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo( pMensaje,pIDAPLICACION1);
        --2
        PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo(pIDAPLICACION2);
        --5
        PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado(pIDAPLICACION5);
        --6
        PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi(pIDAPLICACION6);

        
        BEGIN
            SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
        END;
        --7
        PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion(pIDAPLICACION7);
        --8
        PR.PR_PKG_REPRESTAMOS.Actualiza_XCORE_CUSTOM(pIDAPLICACION8);
        --9
        PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD(pIDAPLICACION9);
        --10     
        PR.PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE(pIDAPLICACION10);
        COMMIT;     
        --11
        PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE(pIDAPLICACION11);  
        COMMIT;

        ------------------------------------------------------------------------------------------
        -- ** MODIFICACIÓN 2: Reemplazar el bucle FOR con la llamada al nuevo procedimiento **
        ------------------------------------------------------------------------------------------
        -- PASO 12: Dividir la población elegible ('RE') en Champion ('NP') y Challenger ('CHCH')
        PR.PR_PKG_REPRESTAMOS.P_SPLIT_CHAMPION_CHALLENGER(
            p_nombre_campana => 'Campaña ' || TO_CHAR(SYSDATE, 'YYYY-MM'),
            pError           => v_error_split
        );
        ------------------------------------------------------------------------------------------
        -- ** FIN DE LA MODIFICACIÓN **
        ------------------------------------------------------------------------------------------
                                      
        --FINALIZO EL PROCESO DE LA CABECERA
        PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_CAB(VIDCABECERA);
        COMMIT;
                 
        UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
        WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='EJECUCIONES';
        COMMIT;

    END;
                
EXCEPTION 
    WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
            IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
            setError(pProgramUnit => 'P_Carga_Precalifica_Cancelado', 
                     pPieceCodeName => NULL, 
                     pErrorDescription => SQLERRM,                                                              
                     pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                     pEmailNotification => NULL, 
                     pParamList => IA.LOGGER.vPARAMLIST, 
                     pOutputLogger => FALSE, 
                     pExecutionTime => NULL, 
                     pIdError => vIdError); 
        END;          
END P_Carga_Precalifica_Cancelado;