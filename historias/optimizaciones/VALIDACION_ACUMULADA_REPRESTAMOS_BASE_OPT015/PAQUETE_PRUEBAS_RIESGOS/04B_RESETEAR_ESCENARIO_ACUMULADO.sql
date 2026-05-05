-- =============================================================
-- ACUMULADO - Resetea un escenario contaminado de equivalencia
--
-- Uso:
--   1. Ejecutar cuando 03A/03 se relanzo sin limpiar antes y ya no se
--      puede confiar solo en OPTACUM_RUN_IDS del run previo.
--   2. Por defecto limpia solo residuos funcionales creados HOY por USER.
--   3. Si la corrida contaminada fue anterior, aumentar DIAS_ATRAS.
--   4. Luego reejecutar ANTES y DESPUES desde cero.
--
-- Alcance:
--   - Borra residuos funcionales del usuario actual en PR_*.
--   - Reinicia auxiliares de los RUN_LABEL base/test.
--   - No toca OPTACUM_PARAM_BACKUP ni parametros MVP.
-- =============================================================

DEFINE RUN_LABEL_BASE = ANTES
DEFINE RUN_LABEL_TEST = DESPUES
DEFINE DIAS_ATRAS = 0

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_run_label_base   VARCHAR2(30) := UPPER('&RUN_LABEL_BASE');
    v_run_label_test   VARCHAR2(30) := UPPER('&RUN_LABEL_TEST');
    v_dias_atras       NUMBER := TO_NUMBER(NVL(TRIM('&DIAS_ATRAS'), '0'));
    v_fecha_desde      DATE := TRUNC(SYSDATE) - v_dias_atras;

    v_re_scope         NUMBER := 0;
    v_sol_scope        NUMBER := 0;
    v_can_scope        NUMBER := 0;
    v_opc_scope        NUMBER := 0;
    v_bit_scope        NUMBER := 0;

    FUNCTION f_tabla_existe(p_table_name VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM USER_TABLES
         WHERE TABLE_NAME = UPPER(p_table_name);

        RETURN v_count > 0;
    END;

    PROCEDURE p_borrar_aux(p_table_name VARCHAR2) IS
    BEGIN
        IF f_tabla_existe(p_table_name) THEN
            EXECUTE IMMEDIATE
                'DELETE FROM ' || p_table_name ||
                ' WHERE RUN_LABEL IN (:run_label_base, :run_label_test)'
            USING v_run_label_base, v_run_label_test;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(p_table_name, 35) || ' -> ' || SQL%ROWCOUNT || ' filas'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                RPAD(p_table_name, 35) || ' -> tabla no existe, se omite'
            );
        END IF;
    END;
BEGIN
    SELECT COUNT(*)
      INTO v_re_scope
      FROM PR.PR_REPRESTAMOS R
     WHERE R.ADICIONADO_POR = USER
       AND R.FECHA_ADICION >= v_fecha_desde;

    SELECT COUNT(*)
      INTO v_sol_scope
      FROM PR.PR_SOLICITUD_REPRESTAMO S
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = S.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    SELECT COUNT(*)
      INTO v_can_scope
      FROM PR.PR_CANALES_REPRESTAMO C
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = C.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = C.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    SELECT COUNT(*)
      INTO v_opc_scope
      FROM PR.PR_OPCIONES_REPRESTAMO O
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = O.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = O.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    SELECT COUNT(*)
      INTO v_bit_scope
      FROM PR.PR_BITACORA_REPRESTAMO B
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = B.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = B.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('RESET ESCENARIO ACUMULADO');
    DBMS_OUTPUT.PUT_LINE('TEST_USER      : ' || USER);
    DBMS_OUTPUT.PUT_LINE('RUN_LABEL_BASE : ' || v_run_label_base);
    DBMS_OUTPUT.PUT_LINE('RUN_LABEL_TEST : ' || v_run_label_test);
    DBMS_OUTPUT.PUT_LINE('DIAS_ATRAS     : ' || v_dias_atras);
    DBMS_OUTPUT.PUT_LINE('FECHA_DESDE    : ' || TO_CHAR(v_fecha_desde, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('Scope funcional detectado:');
    DBMS_OUTPUT.PUT_LINE('  PR_REPRESTAMOS         : ' || v_re_scope);
    DBMS_OUTPUT.PUT_LINE('  PR_SOLICITUD_REPRESTAMO: ' || v_sol_scope);
    DBMS_OUTPUT.PUT_LINE('  PR_CANALES_REPRESTAMO  : ' || v_can_scope);
    DBMS_OUTPUT.PUT_LINE('  PR_OPCIONES_REPRESTAMO : ' || v_opc_scope);
    DBMS_OUTPUT.PUT_LINE('  PR_BITACORA_REPRESTAMO : ' || v_bit_scope);

    DELETE FROM PR.PR_BITACORA_REPRESTAMO B
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = B.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = B.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    DBMS_OUTPUT.PUT_LINE('Bitacora borrada         : ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_CANALES_REPRESTAMO C
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = C.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = C.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    DBMS_OUTPUT.PUT_LINE('Canales borrados         : ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_OPCIONES_REPRESTAMO O
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = O.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = O.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    DBMS_OUTPUT.PUT_LINE('Opciones borradas        : ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_SOLICITUD_REPRESTAMO S
     WHERE EXISTS (
         SELECT 1
           FROM PR.PR_REPRESTAMOS R
          WHERE R.CODIGO_EMPRESA = S.CODIGO_EMPRESA
            AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
            AND R.ADICIONADO_POR = USER
            AND R.FECHA_ADICION >= v_fecha_desde
     );

    DBMS_OUTPUT.PUT_LINE('Solicitudes borradas     : ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_REPRESTAMOS R
     WHERE R.ADICIONADO_POR = USER
       AND R.FECHA_ADICION >= v_fecha_desde;

    DBMS_OUTPUT.PUT_LINE('Represtamos borrados     : ' || SQL%ROWCOUNT);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Reset de auxiliares:');

    p_borrar_aux('OPTACUM_SNAP_ETAPAS_REPRESTAMOS');
    p_borrar_aux('OPTACUM_RUN_IDS');
    p_borrar_aux('OPTACUM_SNAP_REPRESTAMOS');
    p_borrar_aux('OPTACUM_SNAP_SOLICITUD');
    p_borrar_aux('OPTACUM_SNAP_CANALES');
    p_borrar_aux('OPTACUM_SNAP_OPCIONES');
    p_borrar_aux('OPTACUM_SNAP_BITACORA');
    p_borrar_aux('OPTACUM_RUN_CONTROL');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Escenario reiniciado. Reejecutar ANTES y DESPUES desde cero.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error reseteando escenario acumulado: ' || SQLERRM);
        RAISE;
END;
/
