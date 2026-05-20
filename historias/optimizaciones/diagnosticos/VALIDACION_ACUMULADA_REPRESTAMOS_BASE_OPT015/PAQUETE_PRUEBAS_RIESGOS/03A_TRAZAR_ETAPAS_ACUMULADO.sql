-- =============================================================
-- ACUMULADO - Traza por etapas de la cadena de equivalencia
-- Uso:
--   1. Compilar el body deseado (ANTES o DESPUES)
--   2. Limpiar datos funcionales previos del usuario
--      Si el escenario quedo contaminado y ya no confias en OPTACUM_RUN_IDS,
--      ejecutar 04B_RESETEAR_ESCENARIO_ACUMULADO.sql antes de reiniciar.
--   3. Ejecutar este script con RUN_LABEL = ANTES
--   4. Repetir con RUN_LABEL = DESPUES
--   5. Comparar con 06B_COMPARAR_ETAPAS_ACUMULADO.sql
--
-- Objetivo:
--   Aislar en cual de las 5 precalificaciones aparece el desfase
--   del universo de PR_REPRESTAMOS antes de capturar OPTACUM_RUN_IDS.
-- =============================================================

DEFINE RUN_LABEL = ANTES

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_run_label   VARCHAR2(30) := UPPER('&RUN_LABEL');
    v_start_ts    TIMESTAMP := SYSTIMESTAMP;
    v_exists      NUMBER;
    v_re_insert   NUMBER := 0;

    PROCEDURE ensure_table(p_name VARCHAR2, p_sql CLOB) IS
    BEGIN
        SELECT COUNT(*)
          INTO v_exists
          FROM USER_TABLES
         WHERE TABLE_NAME = UPPER(p_name);

        IF v_exists = 0 THEN
            EXECUTE IMMEDIATE p_sql;
            DBMS_OUTPUT.PUT_LINE('Creada tabla auxiliar: ' || UPPER(p_name));
        END IF;
    END;

    PROCEDURE capture_stage(p_stage_name VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        EXECUTE IMMEDIATE q'[
            INSERT INTO OPTACUM_SNAP_ETAPAS_REPRESTAMOS
            SELECT :run_label,
                   :stage_name,
                   SYSTIMESTAMP,
                   R.*
              FROM PR.PR_REPRESTAMOS R
             WHERE R.ADICIONADO_POR = USER
               AND R.FECHA_ADICION >= CAST(:start_ts AS DATE)
        ]'
        USING v_run_label, p_stage_name, v_start_ts;

        v_count := SQL%ROWCOUNT;
        COMMIT;

        DBMS_OUTPUT.PUT_LINE(
            RPAD('ETAPA ' || p_stage_name, 45) || ' -> ' || v_count || ' filas'
        );
    END;
BEGIN
    ensure_table(
        'OPTACUM_RUN_IDS',
        q'[
            CREATE TABLE OPTACUM_RUN_IDS (
                RUN_LABEL        VARCHAR2(30),
                CODIGO_EMPRESA   NUMBER(4),
                ID_REPRESTAMO    NUMBER(14),
                CODIGO_CLIENTE   NUMBER(7),
                NO_CREDITO       NUMBER(7),
                FECHA_CORTE      DATE,
                ESTADO_CAPTURA   VARCHAR2(5),
                FECHA_ADICION    DATE
            )
        ]'
    );

    ensure_table(
        'OPTACUM_SNAP_ETAPAS_REPRESTAMOS',
        q'[
            CREATE TABLE OPTACUM_SNAP_ETAPAS_REPRESTAMOS AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS VARCHAR2(60)) STAGE_NAME,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                R.*
            FROM PR.PR_REPRESTAMOS R
            WHERE 1 = 0
        ]'
    );

    EXECUTE IMMEDIATE
        'DELETE FROM OPTACUM_RUN_IDS WHERE RUN_LABEL = :run_label'
        USING v_run_label;

    EXECUTE IMMEDIATE
        'DELETE FROM OPTACUM_SNAP_ETAPAS_REPRESTAMOS WHERE RUN_LABEL = :run_label'
        USING v_run_label;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('RUN_LABEL   : ' || v_run_label);
    DBMS_OUTPUT.PUT_LINE('TEST_USER   : ' || USER);
    DBMS_OUTPUT.PUT_LINE('START_TS    : ' || TO_CHAR(v_start_ts, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('OBJETIVO    : detectar la etapa donde cambia el universo');
    DBMS_OUTPUT.PUT_LINE('==============================================');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo();
    COMMIT;
    capture_stage('01_PRECALIFICA_REPRESTAMO');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores();
    COMMIT;
    capture_stage('02_PRECALIFICA_REPRESTAMO_FIADORES');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores_hi();
    COMMIT;
    capture_stage('03_PRECALIFICA_REPRESTAMO_FIADORES_HI');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado();
    COMMIT;
    capture_stage('04_PRECALIFICA_REPRE_CANCELADO');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi();
    COMMIT;
    capture_stage('05_PRECALIFICA_REPRE_CANCELADO_HI');

    PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion();
    COMMIT;
    capture_stage('06_POST_ACTUALIZA_PRECALIFICACION');

    EXECUTE IMMEDIATE q'[
        INSERT INTO OPTACUM_RUN_IDS (
            RUN_LABEL,
            CODIGO_EMPRESA,
            ID_REPRESTAMO,
            CODIGO_CLIENTE,
            NO_CREDITO,
            FECHA_CORTE,
            ESTADO_CAPTURA,
            FECHA_ADICION
        )
        SELECT :run_label,
               R.CODIGO_EMPRESA,
               R.ID_REPRESTAMO,
               R.CODIGO_CLIENTE,
               R.NO_CREDITO,
               R.FECHA_CORTE,
               R.ESTADO,
               R.FECHA_ADICION
          FROM PR.PR_REPRESTAMOS R
         WHERE R.ADICIONADO_POR = USER
           AND R.FECHA_ADICION >= CAST(:start_ts AS DATE)
    ]'
    USING v_run_label, v_start_ts;

    v_re_insert := SQL%ROWCOUNT;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('RUN_IDS guardados para limpieza posterior: ' || v_re_insert);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en traza por etapas ' || v_run_label || ': ' || SQLERRM);
        RAISE;
END;
/

PROMPT
PROMPT === RESUMEN DE ETAPAS DEL RUN ===
SELECT STAGE_NAME,
       COUNT(*) AS RE_EN_ETAPA
  FROM OPTACUM_SNAP_ETAPAS_REPRESTAMOS
 WHERE RUN_LABEL = UPPER('&RUN_LABEL')
 GROUP BY STAGE_NAME
 ORDER BY STAGE_NAME;
