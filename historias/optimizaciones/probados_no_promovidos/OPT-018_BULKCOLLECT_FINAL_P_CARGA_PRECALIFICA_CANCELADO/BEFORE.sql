-- OPT-018 BEFORE
-- Entorno: DESARROLLO
-- Objeto: PR.PR_PKG_REPRESTAMOS.P_Carga_Precalifica_Cancelado
-- Procedimiento completo antes de OPT-018.

  PROCEDURE P_Carga_Precalifica_Cancelado ( pMensaje IN OUT VARCHAR2) IS


    BEGIN

          --Crear bitacora Cabecera
        /*PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_CAB ( 'RD_CARGA_PRECALIFICACION', 'ACTIVO', Null,pMensaje);

        DECLARE
        VIDCABECERA NUMBER;
        BEGIN
        SELECT MAX(APC.ID_APLICACION_PASO_CAB)
            INTO VIDCABECERA
            FROM PR.PR_APLICACION_PASO_CAB APC
            JOIN PR.PR_APLICACION A ON A.ID_APLICACION=APC.ID_APLICACION
            WHERE CODIGO_APLICACION='RD_CARGA_PRECALIFICACION';

             --INICIALIZO EL PROCESO
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_CAB ( VIDCABECERA, 'INICIADO',0, 'PROCESO INICIADO', PMENSAJE );

        END;*/

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
         /*pIDAPLICACION1 NUMBER;
         pIDAPLICACION2 NUMBER;
         pIDAPLICACION3 NUMBER;
         pIDAPLICACION4 NUMBER;
         pIDAPLICACION5 NUMBER;
         pIDAPLICACION6 NUMBER;
         pIDAPLICACION7 NUMBER;
         pIDAPLICACION8 NUMBER;
         pIDAPLICACION9 NUMBER;*/

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
                     /*BEGIN
                      PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.REGISTRAR_SOLICITUD', 'INICIADO', pMensaje );
                      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( 'ENPROCESO', 50, 'SE ACTUALIZO', pMensaje );
                      FOR A IN CUR_REPRESTAMO LOOP
                        PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);

                        p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));

                        COMMIT;
                      END LOOP ;
                      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );
                      --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( 'FINALIZADO', 'SE FINALIZO', pMensaje );

                      EXCEPTION WHEN OTHERS THEN
                        DECLARE
                        vIdError      PLS_INTEGER := 0;
                            BEGIN
                        pMensaje:='ERROR CON EL STORE PROCEDURE REGISTRAR_SOLICITUD';
                        setError(pProgramUnit => 'P_Carga_Precalifica_Cancelado',
                           pPieceCodeName => NULL,
                           pErrorDescription => SQLERRM ,
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                           pEmailNotification => NULL,
                           pParamList => IA.LOGGER.vPARAMLIST,
                           pOutputLogger => FALSE,
                           pExecutionTime => NULL,
                           pIdError => vIdError);
                           --Capturo el error del detalle de la bitacora
                            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( 'ERROR', 100, SQLERRM, pMensaje );
                        END;
                      END;*/

                      --8
                      --CREANDO EL DETALLE TRAZABILIDAD VALIDA_XCORE

                      PR.PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE();
                      COMMIT;


                      PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE();
                      COMMIT;



                      FOR A IN CUR_REPRESTAMO LOOP
                      DBMS_OUTPUT.PUT_LINE ( 'Entra AL CURSOR CUR_REPRESTAMO = '|| A.ID_REPRESTAMO  );

                        -- validar que tenga solicitud, que tenga canales
                        IF  PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO) AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO)AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN
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
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='EJECUCIONES';
                COMMIT;

        --FINALIZO EL PROCESO DE LA CABECERA
        /*DECLARE
        VIDCABECERA NUMBER;
        BEGIN
        SELECT MAX(APC.ID_APLICACION_PASO_CAB)
            INTO VIDCABECERA
            FROM PR.PR_APLICACION_PASO_CAB APC
            JOIN PR.PR_APLICACION A ON A.ID_APLICACION=APC.ID_APLICACION
            WHERE CODIGO_APLICACION='RD_CARGA_PRECALIFICACION';
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_CAB (VIDCABECERA, 'FINALIZADO',9, 'PROCESO FINALIZADO', PMENSAJE );
        END;
        */
       COMMIT;
      END;



       EXCEPTION WHEN OTHERS THEN
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
