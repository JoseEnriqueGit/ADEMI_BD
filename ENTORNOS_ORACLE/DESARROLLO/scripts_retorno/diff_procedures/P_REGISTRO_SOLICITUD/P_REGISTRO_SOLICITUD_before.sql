-- PROCEDURE P_REGISTRO_SOLICITUD (before)
   PROCEDURE P_REGISTRO_SOLICITUD IS
        
       VMSG          VARCHAR2(4000);
       pMensaje      VARCHAR2(100);  
       idCabeceraDet NUMBER; 
       CURSOR CUR_REPRESTAMO IS 
         SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL
           FROM PR_REPRESTAMOS
          WHERE ESTADO = 'RE';
            
      BEGIN
         
             --VERIFICAR SI EXISTE EL REGISTRO
            /*BEGIN
                SELECT ID_APLICACION_PASO_DET
                INTO idCabeceraDet
                FROM PR.PR_APLICACION_PASO_DET
                WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
                
                DBMS_OUTPUT.PUT_LINE ( 'qUE PASO AQUI = ' || idCabeceraDet );
                
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    --SI NO SE ENCUENTRA NINGUN REGISTRO CREARA UNO NUEVO
                  PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.REGISTRAR_SOLICITUD', 'INICIADO', pMensaje ); 
                        
                        
                     --OBTENER EL ID DEL NUEVO REGISTRO
                     SELECT PR.SEQ_PR_APLICACION_PASO_DET.CURRVAL
                     INTO idCabeceraDet
                     FROM DUAL;  
                     
                     DBMS_OUTPUT.PUT_LINE ( 'idCabeceraDet = ' || idCabeceraDet );
                     
                     --ACTUALIZAR EL PARAMETRO DE ENTRADA CON EL NUEVO ID
                     pIDAPLICACION := idCabeceraDet;
                     
                     DBMS_OUTPUT.PUT_LINE ( 'pIDAPLICACION PARA EL OTRO PASO = ' || pIDAPLICACION );
                     DBMS_OUTPUT.PUT_LINE ('SE CREO EL REGISTRO CON ID: ' || idCabeceraDet);
                                      
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error inesperado al verificar o crear el registro: ' || SQLERRM);
                    RETURN;                     
            END;
                
                --ACTUALIZAR BITACORA SI YA EXISTE
                IF idCabeceraDet IS NOT NULL THEN
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
                END IF;           
                */
                
                FOR A IN CUR_REPRESTAMO LOOP
                    VMSG := NULL;
                    PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(
                        A.ID_REPRESTAMO,
                        NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),
                        VMSG);
                        
                    PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(
                        A.ID_REPRESTAMO,
                        NULL,
                        'RE',
                        NULL,
                        '',
                        NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                        
                    COMMIT;
                END LOOP ;
                /*PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );
                PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );*/
                      
                EXCEPTION WHEN OTHERS THEN   
                    DECLARE
                       vIdError      PLS_INTEGER := 0;
                     BEGIN                                    
                        pMensaje:='ERROR CON EL STORE PROCEDURE REGISTRAR_SOLICITUD';
                        setError(pProgramUnit => 'P_REGISTRO_SOLICITUD', 
                           pPieceCodeName => NULL, 
                           pErrorDescription => SQLERRM ,                                                              
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                           pEmailNotification => NULL, 
                           pParamList => IA.LOGGER.vPARAMLIST, 
                           pOutputLogger => FALSE, 
                           pExecutionTime => NULL, 
                           pIdError => vIdError); 
                           --Capturo el error del detalle de la bitacora
                           --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM, pMensaje );
                     END;    
            --END;     
       
                 
  END P_REGISTRO_SOLICITUD;
