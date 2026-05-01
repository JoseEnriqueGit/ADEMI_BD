-- =============================================================================
-- Entorno: QA02
-- Schema: PA
-- Objeto: PA.PKG_MANT_TBL_HELADO (PACKAGE BODY)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE PACKAGE BODY PA.pkg_mant_tbl_helado IS

    /*Migra data de la tabla PA_REPORTES_AUTOMATICOS a la tabla de historico (PA_REPORTES_AUTOMATICOS_HIST)*/
    PROCEDURE migra_data_rep_auto_hist IS
   
        CURSOR cDatos IS
            SELECT A.*
              FROM PA.PA_REPORTES_AUTOMATICOS A
             WHERE A.CODIGO_REPORTE = A.CODIGO_REPORTE||''
               AND SYSDATE - A.FECHA_REPORTE >= vDiasMigraHistHela
               AND estado_reporte in ('S','X','E')
               AND NOT EXISTS (SELECT 1
                                 FROM PA.PA_REPORTES_AUTOMATICOS_HIST R
                                WHERE R.CODIGO_REPORTE = A.CODIGO_REPORTE);
    BEGIN
        
        OPEN cDatos;
        LOOP
            FETCH cDatos BULK COLLECT INTO vRepAutoTab LIMIT 500;
            EXIT WHEN vRepAutoTab.COUNT = 0;

            FOR i IN 1 .. vRepAutoTab.COUNT LOOP
                migra_data_bit_auto_hist(vRepAutoTab(i).CODIGO_REPORTE);
            END LOOP;

            BEGIN
                FORALL i IN 1..vRepAutoTab.COUNT SAVE EXCEPTIONS
                    INSERT INTO PA.PA_REPORTES_AUTOMATICOS_HIST VALUES vRepAutoTab(i);
                    
                FORALL i IN 1..vRepAutoTab.COUNT SAVE EXCEPTIONS
                    DELETE FROM PA.PA_REPORTES_AUTOMATICOS WHERE CODIGO_REPORTE = vRepAutoTab(i).CODIGO_REPORTE;
                    
                COMMIT;
                
            EXCEPTION
                WHEN OTHERS
                THEN

                    FOR e IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
                    LOOP
                        BEGIN
                            IA.LOGGER.LOG(INOWNER => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 
                                        INPACKAGENAME => 'PA.PKG_MANT_TBL_HELADO', 
                                        INPROGRAMUNIT => 'MIGRA_DATA_REP_AUTO_HIST', 
                                        INPIECECODENAME => null, 
                                        INERRORDESCRIPTION => 'Error Insertando PA_REPORTES_AUTOMATICOS_HIST CODIGO_REPORTE='
                                            || vRepAutoTab (
                                                   SQL%BULK_EXCEPTIONS (e).ERROR_INDEX).CODIGO_REPORTE
                                            || ' '
                                            || SQLERRM (
                                                   -SQL%BULK_EXCEPTIONS (e).ERROR_CODE), 
                                        INERRORTRACE => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                                        INEMAILNOTIFICATION => NULL, 
                                        INPARAMLIST => IA.LOGGER.VPARAMLIST, 
                                        INOUTPUTLOGGER => false, 
                                        INEXECUTIONTIME => null, 
                                        outIdError => IdError);
                    
                            DBMS_OUTPUT.PUT_LINE (SQLERRM || ' Log:' || IdError);
                        END;
                    END LOOP;
            END;
        END LOOP;
        CLOSE cDatos;
                                            
    END migra_data_rep_auto_hist;
    
    /*Migra data de la tabla PA.BITACORA_REP_AUTOMATICOS a la tabla de historico (PA.BITACORA_REP_AUTOMATICOS_HIST)*/
    PROCEDURE migra_data_bit_auto_hist(p_CodigoReporte      IN NUMBER) IS
    
         CURSOR cDatos IS
            SELECT A.*
              FROM PA.BITACORA_REP_AUTOMATICOS A
             WHERE A.CODIGO_REPORTE = p_CodigoReporte
               AND SYSDATE - A.FECHA_BITACORA >= vDiasMigraHistHela               
               AND NOT EXISTS (SELECT 1
                                 FROM PA.BITACORA_REP_AUTOMATICOS_HIST R
                                WHERE R.CODIGO_BITACORA = A.CODIGO_BITACORA
                                  AND R.CODIGO_REPORTE = A.CODIGO_REPORTE
                                  AND R.ESTADO_REPORTE IS NOT NULL);
    BEGIN
        
        OPEN cDatos;
        LOOP
            FETCH cDatos BULK COLLECT INTO vBitRepAutoTab LIMIT 500;
            EXIT WHEN vBitRepAutoTab.COUNT = 0;

            BEGIN
            
                FORALL i IN 1..vBitRepAutoTab.COUNT SAVE EXCEPTIONS
                    INSERT INTO PA.BITACORA_REP_AUTOMATICOS_HIST VALUES vBitRepAutoTab(i);
                    
                FORALL i IN 1..vBitRepAutoTab.COUNT SAVE EXCEPTIONS
                    DELETE FROM PA.BITACORA_REP_AUTOMATICOS WHERE CODIGO_BITACORA = vBitRepAutoTab(i).CODIGO_BITACORA;

                COMMIT;
            
            EXCEPTION
                WHEN OTHERS
                THEN

                    FOR e IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
                    LOOP
                        BEGIN
                            IA.LOGGER.LOG(INOWNER => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 
                                        INPACKAGENAME => 'PA.PKG_MANT_TBL_HELADO', 
                                        INPROGRAMUNIT => 'MIGRA_DATA_BIT_AUTO_HIST', 
                                        INPIECECODENAME => null, 
                                        INERRORDESCRIPTION => 'Error Insertando BITACORA_REP_AUTOMATICOS_HIST CODIGO_BITACORA='
                                            || vBitRepAutoTab (
                                                   SQL%BULK_EXCEPTIONS (e).ERROR_INDEX).CODIGO_BITACORA
                                            || ' '
                                            || SQLERRM (
                                                   -SQL%BULK_EXCEPTIONS (e).ERROR_CODE), 
                                        INERRORTRACE => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                                        INEMAILNOTIFICATION => NULL, 
                                        INPARAMLIST => IA.LOGGER.VPARAMLIST, 
                                        INOUTPUTLOGGER => false, 
                                        INEXECUTIONTIME => null, 
                                        outIdError => IdError);
                    
                            DBMS_OUTPUT.PUT_LINE (SQLERRM || ' Log:' || IdError);
                        END;
                    END LOOP;
            END;
        END LOOP;
        CLOSE cDatos;
                            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE ('Error insetando registros: ' || SQLERRM);
    END migra_data_bit_auto_hist;

    /*Ejecuta las opciones unificadas del paquete*/
    PROCEDURE migra_historico IS
    BEGIN
        cambio_estado_rep_auto;
        --
        --migra_data_bit_auto_hist;
        migra_data_rep_auto_hist;
        
    END migra_historico;
    
    /*Cambia el estado de los prestamos que fueron cancelados*/
    PROCEDURE cambio_estado_rep_auto IS
    
        CURSOR cDatos is
         SELECT R.CODIGO_REPORTE, R.ESTADO_REPORTE, R.IDPROCESO
          FROM PA.PA_REPORTES_AUTOMATICOS R
         WHERE CODIGO_REPORTE = CODIGO_REPORTE||''
           AND SYSDATE - FECHA_REPORTE >= vDiasMigraHistHela
           AND estado_reporte != 'X'
           AND NOT EXISTS (SELECT 1
                             FROM PR.PR_CREDITOS C
                            WHERE C.NO_CREDITO = to_number(nvl(trim(CASE WHEN R.URL_REPORTE IS NULL THEN
                                                        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
                                                    ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 1) END),0)))
            AND EXISTS (SELECT 1 
                        FROM PR.PR_CREDITOS_HI 
                        WHERE NO_CREDITO = to_number(nvl(trim(CASE WHEN R.URL_REPORTE IS NULL THEN
                                                        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
                                                    ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 1) END),0)));
    BEGIN
         FOR reg IN cDatos LOOP
                
            BEGIN
                PA.Cambiar_Estado_Rep_Auto (reg.CODIGO_REPORTE,
                                            'X',
                                            reg.ESTADO_REPORTE,
                                            'CREDITO ANULADO',
                                            reg.IDPROCESO);

                COMMIT;
            
            EXCEPTION
            WHEN OTHERS THEN
                IA.LOGGER.LOG(INOWNER => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 
                        INPACKAGENAME => 'PA.PKG_MANT_TBL_HELADO', 
                        INPROGRAMUNIT => 'CAMBIO_ESTADO_TBL_HELADO', 
                        INPIECECODENAME => null, 
                        INERRORDESCRIPTION => 'Error borrando BITACORA_REP_AUTOMATICOS: '|| SQLERRM, 
                        INERRORTRACE => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                        INEMAILNOTIFICATION => NULL, 
                        INPARAMLIST => IA.LOGGER.VPARAMLIST, 
                        INOUTPUTLOGGER => false, 
                        INEXECUTIONTIME => null, 
                        outIdError => IdError);

                DBMS_OUTPUT.PUT_LINE (SQLERRM || ' Log:' || IdError);
                
            END;
        
        END LOOP;
                
    END cambio_estado_rep_auto;
end;
/

