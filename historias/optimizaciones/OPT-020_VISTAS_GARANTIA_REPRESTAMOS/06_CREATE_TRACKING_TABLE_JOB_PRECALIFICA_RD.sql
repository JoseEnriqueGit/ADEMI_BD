-- =====================================================================
-- OPT-020 - Tabla persistente de tracking del job
-- Entorno objetivo: QA02
--
-- Objetivo:
--   Dejar una tabla donde el job PR.JOB_CARGA_PRECALIFICA_RD registre cada
--   paso cuando se ejecute normalmente desde Oracle Scheduler.
--
-- Uso:
--   1. Ejecutar una sola vez en QA02.
--   2. Aplicar el patch del paquete en 07_PATCH_TRACKING_PAQUETE_SNIPPETS.sql.
--   3. Ejecutar el job normal.
--   4. Consultar 08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_TRACK';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE PR.PR_JOB_PRECALIFICA_TRACK
            (
                ID_EJECUCION      VARCHAR2(32 BYTE)   NOT NULL,
                ID_PASO           NUMBER(3)           NOT NULL,
                JOB_NAME          VARCHAR2(128 BYTE)  NOT NULL,
                PROCESO           VARCHAR2(120 BYTE)  NOT NULL,
                ESTADO            VARCHAR2(20 BYTE)   NOT NULL,
                FECHA_INICIO      TIMESTAMP(6)        NOT NULL,
                FECHA_FIN         TIMESTAMP(6),
                DURACION_SEGUNDOS NUMBER(18,3),
                DURACION_MINUTOS  NUMBER(18,3),
                REGISTROS_RE      NUMBER,
                ERROR_CODE        NUMBER,
                ERROR_MESSAGE     VARCHAR2(4000 BYTE),
                SID               NUMBER,
                MODULE            VARCHAR2(64 BYTE),
                ACTION            VARCHAR2(64 BYTE),
                ADICIONADO_POR    VARCHAR2(30 BYTE)   DEFAULT USER NOT NULL,
                FECHA_ADICION     DATE                DEFAULT SYSDATE NOT NULL,
                CONSTRAINT PK_PR_JOB_PRECALIFICA_TRACK
                    PRIMARY KEY (ID_EJECUCION, ID_PASO)
            )
        ]';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_indexes
     WHERE owner = 'PR'
       AND index_name = 'IX_PRECAL_TRACK_FECHA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_PRECAL_TRACK_FECHA ON PR.PR_JOB_PRECALIFICA_TRACK (FECHA_INICIO)';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_indexes
     WHERE owner = 'PR'
       AND index_name = 'IX_PRECAL_TRACK_PROCESO';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_PRECAL_TRACK_PROCESO ON PR.PR_JOB_PRECALIFICA_TRACK (PROCESO, FECHA_INICIO)';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_indexes
     WHERE owner = 'PA'
       AND index_name = 'IDX_PARAM_MVP_COD_PARAM';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PA.IDX_PARAM_MVP_COD_PARAM ON PA.PA_PARAMETROS_MVP (CODIGO_MVP, CODIGO_PARAMETRO)';
    END IF;
END;
/

PROMPT ================================================================
PROMPT OPT-020 Q01 - Validacion de tabla de tracking
PROMPT ================================================================

SELECT 'PR' AS owner,
       'PR_JOB_PRECALIFICA_TRACK' AS table_name,
       CASE WHEN t.table_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado,
       t.tablespace_name AS tablespace
  FROM dual e
  LEFT JOIN all_tables t
    ON t.owner = 'PR'
   AND t.table_name = 'PR_JOB_PRECALIFICA_TRACK';

PROMPT ================================================================
PROMPT OPT-020 Q02 - Validacion de indices esperados
PROMPT ================================================================

SELECT  e.owner       AS esquema,
        e.index_name  AS indice,
        e.table_name  AS tabla,
        CASE WHEN i.index_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado,
        i.tablespace_name AS tablespace
FROM (
    SELECT 'PA' AS owner, 'IDX_DE08_SIB_FECHA_DEUDOR'     AS index_name, 'PA_DE08_SIB'             AS table_name FROM dual UNION ALL
    SELECT 'PR', 'IDX_CREDITOS_HI_NOCREDITO',             'PR_CREDITOS_HI'                                       FROM dual UNION ALL
    SELECT 'PR', 'IDX_REPRESTAMOS_EMP_EST_NOCRED',        'PR_REPRESTAMOS'                                       FROM dual UNION ALL
    SELECT 'PA', 'IDX_DE05_SIB_CASTIGO_CEDULA',           'PA_DE05_SIB'                                          FROM dual UNION ALL
    SELECT 'PA', 'IDX_DE08_NOCRED_CALIF_FECHA',           'PA_DETALLADO_DE08'                                    FROM dual UNION ALL
    SELECT 'PR', 'IDX_GARANTIAS_TIPO_SB',                 'PR_GARANTIAS'                                         FROM dual UNION ALL
    SELECT 'PR', 'IDX_REPRESTAMOS_ESTADO_COV',            'PR_REPRESTAMOS'                                       FROM dual UNION ALL
    SELECT 'PR', 'IDX_SOLREPRE_IDREPRE_TIPCRED',          'PR_SOLICITUD_REPRESTAMO'                              FROM dual UNION ALL
    SELECT 'PR', 'PK_PR_JOB_PRECALIFICA_TRACK',           'PR_JOB_PRECALIFICA_TRACK'                             FROM dual UNION ALL
    SELECT 'PR', 'IX_PRECAL_TRACK_FECHA',                 'PR_JOB_PRECALIFICA_TRACK'                             FROM dual UNION ALL
    SELECT 'PR', 'IX_PRECAL_TRACK_PROCESO',               'PR_JOB_PRECALIFICA_TRACK'                             FROM dual UNION ALL
    SELECT 'PA', 'IDX_PARAM_MVP_COD_PARAM',               'PA_PARAMETROS_MVP'                                    FROM dual
) e
LEFT JOIN all_indexes i
       ON i.owner      = e.owner
      AND i.index_name = e.index_name
ORDER BY e.owner, e.index_name;

PROMPT Tracking persistente creado/validado: PR.PR_JOB_PRECALIFICA_TRACK
