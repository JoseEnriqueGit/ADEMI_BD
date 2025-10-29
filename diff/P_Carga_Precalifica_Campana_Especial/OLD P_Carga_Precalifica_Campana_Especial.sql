 PROCEDURE P_Carga_Precalifica_Campana_Especial(pMensaje             IN OUT VARCHAR2)IS
   
     BEGIN
          DECLARE
          CURSOR CUR_REPRESTAMO IS 
          SELECT R.ID_REPRESTAMO,C.TIPO_CREDITO,R.ESTADO,R.XCORE_GLOBAL,R.NO_CREDITO
          FROM PR_REPRESTAMOS R
          LEFT JOIN PR_CAMPANA_ESPECIALES C ON C.NO_CREDITO = R.NO_CREDITO AND C.ID_CAMPANA_ESPECIALES =R.ID_REPRE_CAMPANA_ESPECIALES
          WHERE R.ESTADO = 'RE';

          VMSG  VARCHAR2(4000);
          v_Id_Represtamo  VARCHAR2(400);
          v_conteo  NUMBER(10);
          v_ini DATE;
          v_fin DATE;
          v_seg NUMBER(10);
          v_proceso_activo VARCHAR2(4000);
          BEGIN
          
            v_proceso_activo:= PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CAMPANA_ESPECIAL_PROCESO_ACTIVO');
            IF  v_proceso_activo='S' THEN 
            
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='S' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_PROCESO_ACTIVO';
                COMMIT;
                
            
                  --1
                  PR.PR_PKG_REPRESTAMOS.Precalifica_Campana_Especiales;
                  
                     
                    BEGIN
                      SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
                   DBMS_OUTPUT.PUT_LINE ( 'v_conteo = ' || v_conteo );
                   END;
                  --2
                  PR.PR_PKG_REPRESTAMOS.Actualiza_Preca_Campana_Especiale;
                 
                  --3
                  PR_PKG_REPRESTAMOS.ACTUALIZA_XCORE_CAMPANA_ESPECIAL;
                   

                                 
                  FOR A IN CUR_REPRESTAMO LOOP
                    PR.PR_PKG_REPRESTAMOS.P_Registra_Solicitud_Campana(A.ID_REPRESTAMO,A.TIPO_CREDITO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
                    COMMIT;
                  END LOOP;
                  
                   --5
                  IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_XCORE_CAMPANA') = 'S' THEN
                  PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE();
                    DBMS_OUTPUT.PUT_LINE ( 'VALIDO EL XCORE' );
                    COMMIT;
                  END IF;
                    
                 FOR A IN CUR_REPRESTAMO LOOP
                  -- IF A.ESTADO = 'RE' THEN
                   
                    p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                    UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
                    COMMIT;
                   -- END IF;

                       
                    -- validar que tenga solicitud, que tenga canales
                    IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO)AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN 
                     PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
                         
                     ELSE
                         
                        IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) = FALSE THEN
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                        ELSE
                            IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                            ELSE
                            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                            END IF;
                
                    END IF; 
                       
                   END IF;
                       
                  END LOOP;
                  
                  
                  
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_EJECUCIONES';
                COMMIT;
                
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_PROCESO_ACTIVO';
                COMMIT;
                
          END IF;

          END;
                
           
   
            EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              
              setError(pProgramUnit => 'P_Carga_Precalifica_Campana_Especial', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END; 
    
    
    END P_Carga_Precalifica_Campana_Especial;   