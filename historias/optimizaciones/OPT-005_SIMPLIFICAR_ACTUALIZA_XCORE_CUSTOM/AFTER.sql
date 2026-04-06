-- ============================================================
-- OPT-005 AFTER: Procedure Actualiza_XCORE_CUSTOM simplificado
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Linea ~3309
-- ============================================================
-- Cambio: Se elimina el loop doble (FOR i / FOR A IN CUR_UPDATE_XCORE)
-- con COMMIT por fila, y se reemplaza con un unico UPDATE set-based.
-- xcore=745 es constante (la llamada a DataCredito esta comentada).
-- ============================================================
-- NOTA: Si se reactiva la llamada a DataCredito (PA.PA_PKG_CONSULTA_DATACREDITO),
-- se debe revertir este cambio y restaurar el loop con la llamada real.
-- ============================================================

PROCEDURE Actualiza_XCORE_CUSTOM IS

      pMensaje      VARCHAR2(100);

  BEGIN

      -- Un solo UPDATE reemplaza el loop doble completo
      UPDATE PR_REPRESTAMOS
      SET XCORE_GLOBAL = 745, XCORE_CUSTOM = 745
      WHERE ESTADO = 'RE'
        AND XCORE_GLOBAL IS NULL;
      COMMIT;

      EXCEPTION WHEN OTHERS THEN
           DECLARE
               vIdError      PLS_INTEGER := 0;
           BEGIN
             pMensaje:='ERROR CON EL STORE PROCEDURE ACTUALIZA_XCORE_CUSTOM';
             setError(pProgramUnit => 'Actualiza_XCORE_CUSTOM',
                      pPieceCodeName => NULL,
                      pErrorDescription => SQLERRM ,
                      pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                      pEmailNotification => NULL,
                      pParamList => IA.LOGGER.vPARAMLIST,
                      pOutputLogger => FALSE,
                      pExecutionTime => NULL,
                      pIdError => vIdError);
                      DBMS_OUTPUT.PUT_LINE ( 'DBMS_UTILITY.FORMAT_ERROR_BACKTRACE 2 = ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
          END;

   END Actualiza_XCORE_CUSTOM;
