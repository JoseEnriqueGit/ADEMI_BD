-- ============================================================
-- OPT-006 BEFORE: COMMIT dentro del FOR loop
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Procedures: P_REGISTRO_SOLICITUD (~linea 8007)
--             P_Carga_Precalifica_Manual (~linea 8279)
-- ============================================================
-- Problema: COMMIT ejecutado en cada iteracion del loop,
-- generando overhead de redo log por cada fila procesada.
-- ============================================================

-- ======================
-- P_REGISTRO_SOLICITUD
-- ======================
PROCEDURE P_REGISTRO_SOLICITUD IS

      VMSG  VARCHAR2(4000);
      pMensaje      VARCHAR2(100);
      idCabeceraDet NUMBER;

      CURSOR CUR_REPRESTAMO IS
      SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
      FROM PR_REPRESTAMOS
      WHERE ESTADO = 'RE';

     BEGIN

               FOR A IN CUR_REPRESTAMO LOOP
               PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);

                       PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));

                   COMMIT;  -- <-- COMMIT por cada fila
               END LOOP ;

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
                    END;

 END P_REGISTRO_SOLICITUD;


-- ==============================
-- P_Carga_Precalifica_Manual
-- (seccion relevante del FOR loop con COMMIT interno)
-- ==============================
-- Dentro del procedure (~linea 8318):

                 FOR A IN CUR_REPRESTAMO LOOP
                 --DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                   PR.PR_PKG_REPRESTAMOS.P_Registra_Solicitud_Dirigida(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
                   COMMIT;  -- <-- COMMIT por cada fila
                 END LOOP;
