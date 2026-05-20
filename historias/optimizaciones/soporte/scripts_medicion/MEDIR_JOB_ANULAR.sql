-- =====================================================================
-- Script de medicion precisa: JOB_ACTUALIZAR_ANULAR_RD
-- Mide: tiempo elapsed, CPU, I/O logico, I/O fisico, redo generado
-- Ejecutar en Toad con DBMS Output activado (F5 o Ctrl+Enter)
--
-- INSTRUCCIONES:
-- 1. Ejecutar ANTES de aplicar cambios (guardar resultados como ANTES)
-- 2. Aplicar cambios y recompilar paquete
-- 3. Ejecutar de nuevo (guardar resultados como DESPUES)
-- 4. Comparar ambas mediciones
--
-- IMPORTANTE: Ejecutar 2-3 veces cada medicion para descartar varianza
-- por cache (la primera ejecucion puede ser mas lenta por cold cache)
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_mensaje       VARCHAR2(32767);
    v_inicio        TIMESTAMP;
    v_fin           TIMESTAMP;
    v_elapsed_ms    NUMBER;

    -- Estadisticas de sesion
    v_cpu_antes     NUMBER;
    v_cpu_despues   NUMBER;
    v_lio_antes     NUMBER; -- Logical I/O (buffer gets)
    v_lio_despues   NUMBER;
    v_pio_antes     NUMBER; -- Physical I/O (disk reads)
    v_pio_despues   NUMBER;
    v_redo_antes    NUMBER;
    v_redo_despues  NUMBER;

    -- Para obtener estadisticas de V$MYSTAT
    FUNCTION get_stat(p_name VARCHAR2) RETURN NUMBER IS
        v_val NUMBER;
    BEGIN
        SELECT ms.VALUE INTO v_val
        FROM V$MYSTAT ms
        JOIN V$STATNAME sn ON sn.STATISTIC# = ms.STATISTIC#
        WHERE sn.NAME = p_name;
        RETURN v_val;
    EXCEPTION WHEN OTHERS THEN
        RETURN -1; -- Si no tiene permisos a V$MYSTAT
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=============================================================');
    DBMS_OUTPUT.PUT_LINE('MEDICION: JOB_ACTUALIZAR_ANULAR_RD');
    DBMS_OUTPUT.PUT_LINE('Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Sesion: ' || SYS_CONTEXT('USERENV','SID'));
    DBMS_OUTPUT.PUT_LINE('=============================================================');

    -- Capturar estadisticas ANTES
    v_cpu_antes  := get_stat('CPU used by this session');
    v_lio_antes  := get_stat('consistent gets');
    v_pio_antes  := get_stat('physical reads');
    v_redo_antes := get_stat('redo size');

    -- Marcar inicio
    v_inicio := SYSTIMESTAMP;

    -- ============================
    -- EJECUTAR EL PROCEDIMIENTO
    -- ============================
    v_mensaje := NULL;
    PR.PR_PKG_REPRESTAMOS.P_ACTUALIZAR_ANULAR_REPRESTAMO(v_mensaje);
    COMMIT;

    -- Marcar fin
    v_fin := SYSTIMESTAMP;

    -- Capturar estadisticas DESPUES
    v_cpu_despues  := get_stat('CPU used by this session');
    v_lio_despues  := get_stat('consistent gets');
    v_pio_despues  := get_stat('physical reads');
    v_redo_despues := get_stat('redo size');

    -- Calcular elapsed en milisegundos
    v_elapsed_ms := EXTRACT(SECOND FROM (v_fin - v_inicio)) * 1000
                  + EXTRACT(MINUTE FROM (v_fin - v_inicio)) * 60000
                  + EXTRACT(HOUR FROM (v_fin - v_inicio)) * 3600000;

    -- Mostrar resultados
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- RESULTADOS ---');
    DBMS_OUTPUT.PUT_LINE('Elapsed (ms)      : ' || ROUND(v_elapsed_ms, 2));
    DBMS_OUTPUT.PUT_LINE('Elapsed (seg)     : ' || ROUND(v_elapsed_ms / 1000, 3));
    DBMS_OUTPUT.PUT_LINE('CPU (centiseg)    : ' || (v_cpu_despues - v_cpu_antes));
    DBMS_OUTPUT.PUT_LINE('Logical I/O       : ' || (v_lio_despues - v_lio_antes));
    DBMS_OUTPUT.PUT_LINE('Physical I/O      : ' || (v_pio_despues - v_pio_antes));
    DBMS_OUTPUT.PUT_LINE('Redo generado (B) : ' || (v_redo_despues - v_redo_antes));
    DBMS_OUTPUT.PUT_LINE('Mensaje salida    : ' || NVL(v_mensaje, '(ninguno)'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- COPIAR ESTA LINEA PARA COMPARAR ---');
    DBMS_OUTPUT.PUT_LINE('RESULTADO|' || TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')
        || '|elapsed_ms=' || ROUND(v_elapsed_ms,2)
        || '|cpu_cs=' || (v_cpu_despues - v_cpu_antes)
        || '|lio=' || (v_lio_despues - v_lio_antes)
        || '|pio=' || (v_pio_despues - v_pio_antes)
        || '|redo=' || (v_redo_despues - v_redo_antes));
    DBMS_OUTPUT.PUT_LINE('=============================================================');

EXCEPTION WHEN OTHERS THEN
    v_fin := SYSTIMESTAMP;
    v_elapsed_ms := EXTRACT(SECOND FROM (v_fin - v_inicio)) * 1000
                  + EXTRACT(MINUTE FROM (v_fin - v_inicio)) * 60000;
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Elapsed hasta error (ms): ' || ROUND(v_elapsed_ms, 2));
END;
/
