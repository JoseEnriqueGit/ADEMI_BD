-- OPT-007 AFTER: PVALIDA_XCORE con COMMIT movido fuera del FOR LOOP
-- Aplicado en commit e13ee50
-- El COMMIT ahora se ejecuta UNA sola vez despues de END LOOP

PROCEDURE PVALIDA_XCORE IS --SROBLES

            CURSOR c_clientes IS
                SELECT S.TIPO_CREDITO, C.GRUPO_TIPO_CREDITO,R.XCORE_GLOBAL,R.ID_REPRESTAMO,R.NO_CREDITO
                FROM PR.PR_SOLICITUD_REPRESTAMO S
                JOIN pr_tipo_credito C ON C.TIPO_CREDITO = S.TIPO_CREDITO
                JOIN PR.PR_REPRESTAMOS R ON R.ID_REPRESTAMO = S.ID_REPRESTAMO
                WHERE C.GRUPO_TIPO_CREDITO IN ('C', 'P') AND R.ESTADO = 'RE';

            v_tipo_credito VARCHAR2(200);
            v_grupo_tipo_credito VARCHAR2(200);
            pMensaje      VARCHAR2(100);
        BEGIN

        DBMS_OUTPUT.PUT_LINE ( 'Entro en Validar XCore');

            FOR cliente IN c_clientes LOOP
                v_tipo_credito := cliente.TIPO_CREDITO;
                v_grupo_tipo_credito := cliente.GRUPO_TIPO_CREDITO;

                -- Realizar la validacion especifica para cada tipo de credito
                IF v_grupo_tipo_credito = 'C' AND NVL(CLIENTE.XCORE_GLOBAL,0) <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('XCORE_CREDITO_COMERCIAL')) OR CLIENTE.XCORE_GLOBAL IS NULL THEN
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(CLIENTE.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Rechazado por Xcore inferior para Credito Comercial', USER);
                    DBMS_OUTPUT.PUT_LINE('Validacion para clientes con tipo de credito C');
                    IF PR.PR_PKG_REPRESTAMOS.F_VALIDAR_TIPO_REPRESTAMO(CLIENTE.ID_REPRESTAMO) THEN
                        UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Descartado por Xcore',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
                        WHERE NO_CREDITO = CLIENTE.NO_CREDITO  AND ESTADO='T';
                        CONTINUE;
                    ELSIF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo_Carga(CLIENTE.ID_REPRESTAMO) THEN
                          UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Descartado por Xcore',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
                          WHERE NO_CREDITO = CLIENTE.NO_CREDITO  AND ESTADO='T';
                          CONTINUE;
                    END IF;

                ELSIF v_grupo_tipo_credito = 'P' AND NVL(CLIENTE.XCORE_GLOBAL,0) <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('XCORE_CREDITO_CONSUMO')) OR CLIENTE.XCORE_GLOBAL IS NULL  THEN

                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(CLIENTE.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Rechazado por Xcore inferior para Credito de Consumo', USER);
                    DBMS_OUTPUT.PUT_LINE('Validacion para clientes con tipo de credito P');
                    IF PR.PR_PKG_REPRESTAMOS.F_VALIDAR_TIPO_REPRESTAMO(CLIENTE.ID_REPRESTAMO) THEN
                        UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Descartado por Xcore',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
                        WHERE NO_CREDITO = CLIENTE.NO_CREDITO  AND ESTADO='T';
                        CONTINUE;
                    ELSIF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo_Carga(CLIENTE.ID_REPRESTAMO) THEN
                          UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Descartado por Xcore',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
                          WHERE NO_CREDITO = CLIENTE.NO_CREDITO  AND ESTADO='T';
                          CONTINUE;
                    END IF;

                END IF;
                -- COMMIT removido de aqui
            END LOOP;

            COMMIT;  -- <<< OPTIMIZACION: Un solo COMMIT despues del loop completo

        EXCEPTION WHEN OTHERS THEN
                DECLARE
                    vIdError      PLS_INTEGER := 0;
                BEGIN
                  pMensaje:='ERROR CON EL STORE PROCEDURE PVALIDA_XCORE';
                  setError(pProgramUnit => 'PVALIDA_XCORE',
                           pPieceCodeName => NULL,
                           pErrorDescription => SQLERRM ,
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                           pEmailNotification => NULL,
                           pParamList => IA.LOGGER.vPARAMLIST,
                           pOutputLogger => FALSE,
                           pExecutionTime => NULL,
                           pIdError => vIdError);
                END;

     END PVALIDA_XCORE;
