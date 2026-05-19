  PROCEDURE P_Carga_Precalifica_Cancelado ( pMensaje IN OUT VARCHAR2) IS

    BEGIN
        DECLARE

        CURSOR CUR_REPRESTAMO IS
            SELECT ID_REPRESTAMO
            FROM PR_REPRESTAMOS
            WHERE ESTADO = 'RE';

         VMSG  VARCHAR2(4000);
         v_Id_Represtamo  VARCHAR2(400);
         v_conteo  NUMBER(10);
         v_ini DATE;
         v_fin DATE;
         v_seg NUMBER(10);
         VALOR VARCHAR(400);
         TYPE T_IDS_REPRESTAMO_FINAL IS TABLE OF PR_REPRESTAMOS.ID_REPRESTAMO%TYPE;
         V_IDS_REPRESTAMO_FINAL T_IDS_REPRESTAMO_FINAL := T_IDS_REPRESTAMO_FINAL();

                  BEGIN
                      -- Inicio del proceso de trazabilidad
                        --1
                        PR.PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo( pMensaje);
                        --2
                        PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo();
                        --3
                        PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores();
                        --4
                        PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores_hi();
                        --5
                        PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado();
                        --6
                        PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi();

                      BEGIN
                        SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
                      END;
                        --5
                        PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion();
                        --6
                        PR.PR_PKG_REPRESTAMOS.Actualiza_XCORE_CUSTOM();
                        --7
                        PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD();
                        --8
                        --CREANDO EL DETALLE TRAZABILIDAD VALIDA_XCORE

                      PR.PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE();
                      COMMIT;

                      PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE();
                      COMMIT;

                      OPEN CUR_REPRESTAMO;
                        FETCH CUR_REPRESTAMO BULK COLLECT INTO V_IDS_REPRESTAMO_FINAL;
                      CLOSE CUR_REPRESTAMO;

                      IF V_IDS_REPRESTAMO_FINAL.COUNT > 0 THEN
                      FOR I IN 1 .. V_IDS_REPRESTAMO_FINAL.COUNT LOOP
                      DBMS_OUTPUT.PUT_LINE ( 'Entra AL CURSOR CUR_REPRESTAMO = '|| V_IDS_REPRESTAMO_FINAL(I)  );
                        -- validar que tenga solicitud, que tenga canales
                        IF  PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(V_IDS_REPRESTAMO_FINAL(I)) AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(V_IDS_REPRESTAMO_FINAL(I))AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( V_IDS_REPRESTAMO_FINAL(I) ) THEN
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'NP', NULL, 'NotificaciÂ¿n Pendiente', USER);
                         ELSE
                            IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( V_IDS_REPRESTAMO_FINAL(I) ) = FALSE THEN
                             PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                            ELSE
                                IF F_Existe_Solicitudes(V_IDS_REPRESTAMO_FINAL(I)) AND F_Existe_Canales(V_IDS_REPRESTAMO_FINAL(I)) = FALSE AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( V_IDS_REPRESTAMO_FINAL(I) ) THEN
                                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                                ELSE
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                                END IF;
                        END IF;

                       END IF;

                      END LOOP;
                      END IF;
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='EJECUCIONES';
                COMMIT;
       COMMIT;
      EXCEPTION WHEN OTHERS THEN
          IF CUR_REPRESTAMO%ISOPEN THEN
             CLOSE CUR_REPRESTAMO;
          END IF;
          RAISE;
      END;
       EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN

              IA.LOGGER.ADDPARAMVALUEV('pMensaje', pMensaje);

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
