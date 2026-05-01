-- =============================================================================
-- Entorno: QA02
-- Schema: PA
-- Objeto: PA.PKG_MANT_TBL_HELADO (PACKAGE SPEC)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE PACKAGE PA.pkg_mant_tbl_helado IS
    
    vDiasMigraHistHela NUMBER := OBT_PARAMETROS('1', 'PA', 'DIAS_MIGRA_HIST_HELA');
    IdError varchar2(2000);
    
    TYPE tRepAutoTyp IS TABLE OF PA.PA_REPORTES_AUTOMATICOS%ROWTYPE;
    vRepAutoTab tRepAutoTyp;
    
    TYPE tBitRepAutoTyp IS TABLE OF PA.BITACORA_REP_AUTOMATICOS%ROWTYPE;
    vBitRepAutoTab tBitRepAutoTyp;
    
    /*Migra data de la tabla PA_REPORTES_AUTOMATICOS a la tabla de historico (PA_REPORTES_AUTOMATICOS_HIST)*/
    PROCEDURE migra_data_rep_auto_hist;
    
    /*Migra data de la tabla PA.BITACORA_REP_AUTOMATICOS a la tabla de historico (PA.BITACORA_REP_AUTOMATICOS_HIST)*/
    PROCEDURE migra_data_bit_auto_hist(p_CodigoReporte      IN NUMBER);
    
    /*Ejecuta las opciones unificadas del paquete*/
    PROCEDURE migra_historico;
    
    /*Cambia el estado de los CREDITOS que fueron cancelados*/
    PROCEDURE cambio_estado_rep_auto;
end;
/

