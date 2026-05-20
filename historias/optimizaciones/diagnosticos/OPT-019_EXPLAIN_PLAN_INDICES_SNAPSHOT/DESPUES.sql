-- OPT-019 DESPUES
-- Entorno objetivo: DESARROLLO / QA
-- Caso: INC SNAPSHOT TOO OLD - JOB_PRECALIFICA_REPRESTAMO
-- Uso: ejecutar despues de CREATE_INDEXES.sql.
-- Nota: usar los mismos DEFINE que en ANTES.sql.

SET DEFINE ON
SET LINESIZE 220
SET PAGESIZE 200

DEFINE CODIGO_EMPRESA = 1
DEFINE ID_REPRESTAMO = 0
DEFINE CODIGO_MVP = 'REPRESTAMOS'
DEFINE CODIGO_PARAMETRO = 'ESTADOS_DESACTIVAR_ACCESO_FRONTEND'
DEFINE ESTADO_RE = 'RE'
DEFINE ESTADO_FINAL = 'NP'

DELETE FROM PLAN_TABLE WHERE STATEMENT_ID LIKE 'OPT019_%_AFTER';

PROMPT ============================================================
PROMPT Q00 - Indices existentes relevantes despues
PROMPT ============================================================

SELECT ui.owner,
       ui.index_name,
       ui.table_name,
       ui.uniqueness,
       ui.status,
       LISTAGG(uic.column_name, ', ') WITHIN GROUP (ORDER BY uic.column_position) AS columns_list
  FROM all_indexes ui
  JOIN all_ind_columns uic
    ON uic.index_owner = ui.owner
   AND uic.index_name = ui.index_name
 WHERE (ui.owner = 'PA' AND ui.table_name = 'PA_PARAMETROS_MVP')
    OR (ui.owner = 'PR' AND ui.table_name IN ('PR_REPRESTAMOS',
                                              'PR_ESTADOS_REPRESTAMO',
                                              'PR_BITACORA_REPRESTAMO'))
 GROUP BY ui.owner, ui.index_name, ui.table_name, ui.uniqueness, ui.status
 ORDER BY ui.owner, ui.table_name, ui.index_name;

PROMPT ============================================================
PROMPT Q00A - Volumen y ejemplo de ID_REPRESTAMO
PROMPT ============================================================

SELECT COUNT(*) AS total_re
  FROM PR.PR_REPRESTAMOS
 WHERE estado = '&ESTADO_RE';

SELECT MIN(id_represtamo) AS id_represtamo_sugerido
  FROM PR.PR_REPRESTAMOS
 WHERE estado = '&ESTADO_RE';

PROMPT ============================================================
PROMPT Q01 - Parametros MVP directo
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q01_PARAM_AFTER' FOR
SELECT valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = &CODIGO_EMPRESA
   AND codigo_mvp = '&CODIGO_MVP'
   AND codigo_parametro = '&CODIGO_PARAMETRO';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q01_PARAM_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q02A - Query original del trace
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q02A_TRACE_AFTER' FOR
SELECT id_represtamo,
       estado,
       xcore_global
  FROM PR.PR_REPRESTAMOS
 WHERE estado = '&ESTADO_RE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q02A_TRACE_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q02B - Bulk collect IDs RE
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q02B_RE_IDS_AFTER' FOR
SELECT id_represtamo
  FROM PR.PR_REPRESTAMOS
 WHERE estado = '&ESTADO_RE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q02B_RE_IDS_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q03 - Catalogo estado represtamo
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q03_ESTADO_AFTER' FOR
SELECT NVL(b.ind_cambia_estado_original, 'N') estado_original,
       b.ind_notifica_cliente,
       b.ind_cambia_estado_repre
  FROM PR.PR_ESTADOS_REPRESTAMO b
 WHERE b.codigo_empresa = &CODIGO_EMPRESA
   AND b.codigo_estado = '&ESTADO_FINAL';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q03_ESTADO_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q04 - SELECT seguro equivalente al update estado PR_REPRESTAMOS
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q04_SEL_EST_AFTER' FOR
SELECT ROWID
  FROM PR.PR_REPRESTAMOS
 WHERE codigo_empresa = &CODIGO_EMPRESA
   AND id_represtamo = &ID_REPRESTAMO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q04_SEL_EST_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q05 - SELECT seguro equivalente al update fecha proceso PR_REPRESTAMOS
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q05_SEL_FECHA_AFTER' FOR
SELECT fecha_proceso,
       ROWID
  FROM PR.PR_REPRESTAMOS
 WHERE codigo_empresa = &CODIGO_EMPRESA
   AND id_represtamo = &ID_REPRESTAMO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q05_SEL_FECHA_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q06 - Secuencia bitacora por empresa + id
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q06_BIT_SEQ_AFTER' FOR
SELECT COUNT(1) + 1
  FROM PR.PR_BITACORA_REPRESTAMO
 WHERE codigo_empresa = &CODIGO_EMPRESA
   AND id_represtamo = &ID_REPRESTAMO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q06_BIT_SEQ_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));

PROMPT ============================================================
PROMPT Q07 - Bitacora NR por estado + id
PROMPT ============================================================

EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q07_BIT_NR_AFTER' FOR
SELECT COUNT(1) codigo_estado
  FROM PR.PR_BITACORA_REPRESTAMO
 WHERE codigo_estado = 'NR'
   AND id_represtamo = &ID_REPRESTAMO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE',
                                       'OPT019_Q07_BIT_NR_AFTER',
                                       'TYPICAL +PREDICATE +ALIAS'));
