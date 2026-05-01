-- =============================================================================
-- Entorno: QA02
-- Schema: PA
-- Objeto: PA.BITACORA_REPORTES_AUTOMATICOS (PROCEDURE)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE PROCEDURE PA.Bitacora_Reportes_Automaticos (
    pCodigoReporte   IN NUMBER,
    pNombreArchivo   IN VARCHAR2,
    pEstado          IN VARCHAR2,
    pMensaje         IN VARCHAR2,
    pIdProceso       IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO PA.BITACORA_REP_AUTOMATICOS 
    (CODIGO_REPORTE, NOMBRE_ARCHIVO, ESTADO_REPORTE, IDPROCESO, MENSAJE)
    VALUES (pCodigoReporte, pNombreArchivo, pEstado, pIdProceso, pMensaje);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE ('Error: ' || SQLERRM);
        ROLLBACK;
END Bitacora_Reportes_Automaticos;
/

