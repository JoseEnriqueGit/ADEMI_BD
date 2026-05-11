-- OPT-019 CREATE_INDEXES
-- Entorno objetivo: DESARROLLO / QA
-- Uso: ejecutar despues de ANTES.sql y antes de DESPUES.sql.
-- No modifica packages ni logica de negocio.
-- Requiere owner PA/PR o usuario DBA para crear indices en esos schemas.

SET SERVEROUTPUT ON

PROMPT ============================================================
PROMPT Creando indice firme: PA.IDX_PA_PARAM_MVP_01
PROMPT ============================================================

DECLARE
    e_index_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_index_exists, -955);
BEGIN
    EXECUTE IMMEDIATE '
        CREATE INDEX PA.IDX_PA_PARAM_MVP_01
        ON PA.PA_PARAMETROS_MVP (CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO)
    ';
    DBMS_OUTPUT.PUT_LINE('Creado PA.IDX_PA_PARAM_MVP_01');
EXCEPTION
    WHEN e_index_exists THEN
        DBMS_OUTPUT.PUT_LINE('PA.IDX_PA_PARAM_MVP_01 ya existe; se continua.');
END;
/

-- Indice opcional historico. No crear si Q00 muestra un indice existente que
-- empiece por (ESTADO, ID_REPRESTAMO), como IDX_REPRESTAMOS_ESTADO_COV.
-- En ese escenario el indice siguiente seria redundante y menos completo.
/*
PROMPT ============================================================
PROMPT Creando indice opcional: PR.IDX_REPRE_ESTADO_ID_01
PROMPT ============================================================

DECLARE
    e_index_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_index_exists, -955);
BEGIN
    EXECUTE IMMEDIATE '
        CREATE INDEX PR.IDX_REPRE_ESTADO_ID_01
        ON PR.PR_REPRESTAMOS (ESTADO, ID_REPRESTAMO)
    ';
    DBMS_OUTPUT.PUT_LINE('Creado PR.IDX_REPRE_ESTADO_ID_01');
EXCEPTION
    WHEN e_index_exists THEN
        DBMS_OUTPUT.PUT_LINE('PR.IDX_REPRE_ESTADO_ID_01 ya existe; se continua.');
END;
/
*/

PROMPT ============================================================
PROMPT Refrescar estadisticas de tablas evaluadas
PROMPT ============================================================

BEGIN
    BEGIN
        DBMS_STATS.GATHER_TABLE_STATS(
            ownname          => 'PA',
            tabname          => 'PA_PARAMETROS_MVP',
            cascade          => TRUE,
            estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
        );
        DBMS_OUTPUT.PUT_LINE('Estadisticas refrescadas para PA.PA_PARAMETROS_MVP');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('No se pudieron refrescar estadisticas de PA.PA_PARAMETROS_MVP: ' || SQLERRM);
    END;

    -- Si se descomenta el indice opcional historico, tambien conviene refrescar esta tabla.
    -- BEGIN
    --     DBMS_STATS.GATHER_TABLE_STATS(
    --         ownname          => 'PR',
    --         tabname          => 'PR_REPRESTAMOS',
    --         cascade          => TRUE,
    --         estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
    --     );
    --     DBMS_OUTPUT.PUT_LINE('Estadisticas refrescadas para PR.PR_REPRESTAMOS');
    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         DBMS_OUTPUT.PUT_LINE('No se pudieron refrescar estadisticas de PR.PR_REPRESTAMOS: ' || SQLERRM);
    -- END;
END;
/
