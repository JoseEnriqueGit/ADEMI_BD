-- =====================================================================
-- Script de medicion DETALLADA: P_Carga_Precalifica_Cancelado
-- Mide cada sub-procedimiento individualmente con V$MYSTAT
-- Ejecutar con F5 en Toad con DBMS Output activado
-- Cadena basada en body.sql de DESARROLLO (linea 8012)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_mensaje    VARCHAR2(32767);
    v_t0         TIMESTAMP;
    v_t1         TIMESTAMP;
    v_ms         NUMBER;
    v_total_ms   NUMBER := 0;
    v_conteo     NUMBER;

    -- Variables V$MYSTAT para cada paso
    v_cpu0  NUMBER; v_cpu1  NUMBER;
    v_lio0  NUMBER; v_lio1  NUMBER;
    v_pio0  NUMBER; v_pio1  NUMBER;

    FUNCTION get_stat(p_name VARCHAR2) RETURN NUMBER IS
        v_val NUMBER;
    BEGIN
        SELECT ms.VALUE INTO v_val
        FROM V$MYSTAT ms
        JOIN V$STATNAME sn ON sn.STATISTIC# = ms.STATISTIC#
        WHERE sn.NAME = p_name;
        RETURN v_val;
    END;

    PROCEDURE marca_inicio IS
    BEGIN
        v_cpu0 := get_stat('CPU used by this session');
        v_lio0 := get_stat('consistent gets');
        v_pio0 := get_stat('physical reads');
        v_t0   := SYSTIMESTAMP;
    END;

    PROCEDURE marca_fin(p_paso VARCHAR2) IS
    BEGIN
        v_t1   := SYSTIMESTAMP;
        v_cpu1 := get_stat('CPU used by this session');
        v_lio1 := get_stat('consistent gets');
        v_pio1 := get_stat('physical reads');
        v_ms := EXTRACT(SECOND FROM (v_t1 - v_t0)) * 1000
               + EXTRACT(MINUTE FROM (v_t1 - v_t0)) * 60000
               + EXTRACT(HOUR   FROM (v_t1 - v_t0)) * 3600000;
        v_total_ms := v_total_ms + v_ms;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_paso, 40) || ' | ' ||
            LPAD(ROUND(v_ms/1000, 1), 8) || ' seg | cpu=' ||
            LPAD(v_cpu1 - v_cpu0, 6) || ' | lio=' ||
            LPAD(v_lio1 - v_lio0, 10) || ' | pio=' ||
            LPAD(v_pio1 - v_pio0, 8)
        );
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== MEDICION DETALLADA P_Carga_Precalifica_Cancelado ===');
    DBMS_OUTPUT.PUT_LINE('Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE(RPAD('-',90,'-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('PASO', 40) || ' | ' ||
        LPAD('TIEMPO', 8) || '     | ' ||
        LPAD('CPU', 6) || '   | ' ||
        LPAD('LIO', 10) || '   | ' ||
        LPAD('PIO', 8)
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-',90,'-'));

    -- 1. P_Actualizar_Anular_Represtamo
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo(v_mensaje);
    COMMIT;
    marca_fin('1. P_Actualizar_Anular_Represtamo');

    -- 2. Precalifica_Represtamo
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo();
    COMMIT;
    marca_fin('2. Precalifica_Represtamo');

    -- 3. Precalifica_Represtamo_fiadores
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores();
    COMMIT;
    marca_fin('3. Precalifica_Represtamo_fiadores');

    -- 4. Precalifica_Represtamo_fiadores_hi
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores_hi();
    COMMIT;
    marca_fin('4. Precalifica_Represtamo_fiadores_hi');

    -- 5. Precalifica_Repre_Cancelado
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado();
    COMMIT;
    marca_fin('5. Precalifica_Repre_Cancelado');

    -- 6. Precalifica_Repre_Cancelado_hi
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi();
    COMMIT;
    marca_fin('6. Precalifica_Repre_Cancelado_hi');

    -- COUNT RE
    marca_inicio;
    SELECT COUNT(*) INTO v_conteo FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';
    marca_fin('   COUNT(*) ESTADO=RE (v_conteo=' || v_conteo || ')');

    -- 7. Actualiza_Precalificacion
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion();
    COMMIT;
    marca_fin('7. Actualiza_Precalificacion');

    -- 8. Actualiza_XCORE_CUSTOM
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.Actualiza_XCORE_CUSTOM();
    COMMIT;
    marca_fin('8. Actualiza_XCORE_CUSTOM');

    -- 9. P_REGISTRO_SOLICITUD
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD();
    COMMIT;
    marca_fin('9. P_REGISTRO_SOLICITUD');

    -- 10. PVALIDA_WORLD_COMPLIANCE
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE();
    COMMIT;
    marca_fin('10. PVALIDA_WORLD_COMPLIANCE');

    -- 11. PVALIDA_XCORE
    marca_inicio;
    PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE();
    COMMIT;
    marca_fin('11. PVALIDA_XCORE');

    -- 12. Loop final: F_Existe_Solicitudes + F_Existe_Canales + F_EXISTE_CREDITO + Bitacora
    marca_inicio;
    FOR A IN (SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE') LOOP
        IF PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO)
           AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO)
           AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN
            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificacion Pendiente', USER);
        ELSE
            IF PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) = FALSE THEN
                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple: Tipo de Credito', USER);
            ELSE
                IF PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO)
                   AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO) = FALSE
                   AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                ELSE
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple: Solicitudes,Opciones', USER);
                END IF;
            END IF;
        END IF;
    END LOOP;
    COMMIT;
    marca_fin('12. Loop Bitacora+Validaciones');

    -- Resumen
    DBMS_OUTPUT.PUT_LINE(RPAD('-',90,'-'));
    DBMS_OUTPUT.PUT_LINE('TOTAL: ' || ROUND(v_total_ms/1000, 1) || ' seg (' || ROUND(v_total_ms/60000, 1) || ' min)');
    DBMS_OUTPUT.PUT_LINE('RE procesados: ' || v_conteo);
END;
/
