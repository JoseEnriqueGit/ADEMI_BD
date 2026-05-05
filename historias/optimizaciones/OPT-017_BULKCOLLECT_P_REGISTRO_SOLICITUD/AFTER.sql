-- OPT-017 AFTER
-- Entorno: DESARROLLO
-- Objeto: PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD
-- Procedimiento completo despues de OPT-017.

   PROCEDURE P_REGISTRO_SOLICITUD IS

       VMSG  VARCHAR2(4000);
       pMensaje      VARCHAR2(100);
       idCabeceraDet NUMBER;

       CURSOR CUR_REPRESTAMO IS
       SELECT ID_REPRESTAMO
       FROM PR_REPRESTAMOS
       WHERE ESTADO = 'RE';

       TYPE T_IDS_REPRESTAMO IS TABLE OF PR_REPRESTAMOS.ID_REPRESTAMO%TYPE;
       V_IDS_REPRESTAMO T_IDS_REPRESTAMO := T_IDS_REPRESTAMO();

      BEGIN

        OPEN CUR_REPRESTAMO;
        FETCH CUR_REPRESTAMO BULK COLLECT INTO V_IDS_REPRESTAMO;
        CLOSE CUR_REPRESTAMO;

        IF V_IDS_REPRESTAMO.COUNT > 0 THEN
            FOR I IN 1 .. V_IDS_REPRESTAMO.COUNT LOOP
                PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(V_IDS_REPRESTAMO(I),NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);

                PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(V_IDS_REPRESTAMO(I), NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));

                COMMIT;
            END LOOP ;
        END IF;

        EXCEPTION WHEN OTHERS THEN
            IF CUR_REPRESTAMO%ISOPEN THEN
                CLOSE CUR_REPRESTAMO;
            END IF;

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
  END P_REGISTRO_SOLICITUD;

