-- =====================================================================
-- Script de medicion: JOB_PRECALIFICA_REPRESTAMO
-- Mide: P_Carga_Precalifica_Represtamo
-- Ejecutar con boton Play en Toad (no F5) con DBMS Output activado
--
-- PROCESO COMPLETO:
-- 1. Ejecutar 01_DROP_INDICES_ROLLBACK.sql (quitar indices)
-- 2. Ejecutar ESTE script 3 veces (anotar resultados = ANTES)
-- 3. Ejecutar 03_CREATE_INDICES_RESTAURAR.sql (crear indices)
-- 4. Ejecutar ESTE script 3 veces (anotar resultados = DESPUES)
-- 5. Comparar ANTES vs DESPUES
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_mensaje       VARCHAR2(32767);
    v_inicio        TIMESTAMP;
    v_fin           TIMESTAMP;
    v_elapsed_ms    NUMBER;
    v_cpu_antes     NUMBER;
    v_cpu_despues   NUMBER;
    v_lio_antes     NUMBER;
    v_lio_despues   NUMBER;
    v_pio_antes     NUMBER;
    v_pio_despues   NUMBER;
    v_redo_antes    NUMBER;
    v_redo_despues  NUMBER;

    FUNCTION get_stat(p_name VARCHAR2) RETURN NUMBER IS
        v_val NUMBER;
    BEGIN
        SELECT ms.VALUE INTO v_val
        FROM V$MYSTAT ms
        JOIN V$STATNAME sn ON sn.STATISTIC# = ms.STATISTIC#
        WHERE sn.NAME = p_name;
        RETURN v_val;
    END;

BEGIN
    v_cpu_antes  := get_stat('CPU used by this session');
    v_lio_antes  := get_stat('consistent gets');
    v_pio_antes  := get_stat('physical reads');
    v_redo_antes := get_stat('redo size');

    v_inicio := SYSTIMESTAMP;

    v_mensaje := NULL;
    PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_REPRESTAMO(v_mensaje);
    COMMIT;

    v_fin := SYSTIMESTAMP;

    v_cpu_despues  := get_stat('CPU used by this session');
    v_lio_despues  := get_stat('consistent gets');
    v_pio_despues  := get_stat('physical reads');
    v_redo_despues := get_stat('redo size');

    v_elapsed_ms := EXTRACT(SECOND FROM (v_fin - v_inicio)) * 1000
                  + EXTRACT(MINUTE FROM (v_fin - v_inicio)) * 60000
                  + EXTRACT(HOUR FROM (v_fin - v_inicio)) * 3600000;

    DBMS_OUTPUT.PUT_LINE('=== MEDICION JOB_PRECALIFICA_REPRESTAMO ===');
    DBMS_OUTPUT.PUT_LINE('Elapsed (ms)      : ' || ROUND(v_elapsed_ms, 2));
    DBMS_OUTPUT.PUT_LINE('Elapsed (seg)     : ' || ROUND(v_elapsed_ms / 1000, 3));
    DBMS_OUTPUT.PUT_LINE('CPU (centiseg)    : ' || (v_cpu_despues - v_cpu_antes));
    DBMS_OUTPUT.PUT_LINE('Logical I/O       : ' || (v_lio_despues - v_lio_antes));
    DBMS_OUTPUT.PUT_LINE('Physical I/O      : ' || (v_pio_despues - v_pio_antes));
    DBMS_OUTPUT.PUT_LINE('Redo (bytes)      : ' || (v_redo_despues - v_redo_antes));
    DBMS_OUTPUT.PUT_LINE('Mensaje           : ' || NVL(v_mensaje, '(ninguno)'));
    DBMS_OUTPUT.PUT_LINE('RESULTADO|' || ROUND(v_elapsed_ms,2) || 'ms|cpu=' || (v_cpu_despues - v_cpu_antes) || '|lio=' || (v_lio_despues - v_lio_antes) || '|pio=' || (v_pio_despues - v_pio_antes) || '|redo=' || (v_redo_despues - v_redo_antes));
END;
/
