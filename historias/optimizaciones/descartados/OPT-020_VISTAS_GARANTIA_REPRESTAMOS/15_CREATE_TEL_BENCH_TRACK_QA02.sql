-- =====================================================================
-- OPT-020 - Tabla persistente para medicion de telefonos PA o PR por corrida
-- Entorno objetivo: QA02
--
-- Objetivo:
--   Guardar cada llamada medida durante P_REGISTRO_SOLICITUD del job
--   PR.JOB_CARGA_PRECALIFICA_RD. El proveedor se etiqueta en el body
--   instrumentado segun la llamada compilada: PA o PR.
--
-- Uso:
--   1. Ejecutar una sola vez en QA02.
--   2. Compilar el body instrumentado de PR.PR_PKG_REPRESTAMOS.
--   3. Ejecutar PR.JOB_CARGA_PRECALIFICA_RD.
--   4. Consultar 08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_TEL_PERSONA_BENCH_TRACK';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE PR.PR_TEL_PERSONA_BENCH_TRACK
            (
                ID_MEDICION       VARCHAR2(32 BYTE)   NOT NULL,
                ID_EJECUCION      VARCHAR2(32 BYTE),
                JOB_NAME          VARCHAR2(128 BYTE)  NOT NULL,
                PROCESO           VARCHAR2(120 BYTE)  NOT NULL,
                PROVEEDOR         VARCHAR2(2 BYTE)    NOT NULL,
                COD_PERSONA       VARCHAR2(30 BYTE)   NOT NULL,
                TIPO_TELEFONO     VARCHAR2(1 BYTE)    NOT NULL,
                VALOR_TELEFONO    VARCHAR2(4000 BYTE),
                DURACION_MS       NUMBER(18,3),
                ERROR_CODE        NUMBER,
                ERROR_MESSAGE     VARCHAR2(4000 BYTE),
                SID               NUMBER,
                MODULE            VARCHAR2(64 BYTE),
                ACTION            VARCHAR2(64 BYTE),
                ADICIONADO_POR    VARCHAR2(30 BYTE)   DEFAULT USER NOT NULL,
                FECHA_MEDICION    TIMESTAMP(6)        DEFAULT SYSTIMESTAMP NOT NULL,
                CONSTRAINT PK_PR_TEL_PERSONA_BENCH_TRACK
                    PRIMARY KEY (ID_MEDICION),
                CONSTRAINT CK_PR_TEL_TRACK_PROVEEDOR
                    CHECK (PROVEEDOR IN ('PA', 'PR'))
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
       AND index_name = 'IX_TEL_BENCH_EJECUCION';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_TEL_BENCH_EJECUCION ON PR.PR_TEL_PERSONA_BENCH_TRACK (ID_EJECUCION, PROVEEDOR, TIPO_TELEFONO)';
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
       AND index_name = 'IX_TEL_BENCH_FECHA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_TEL_BENCH_FECHA ON PR.PR_TEL_PERSONA_BENCH_TRACK (FECHA_MEDICION)';
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
       AND index_name = 'IX_TEL_BENCH_PERSONA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_TEL_BENCH_PERSONA ON PR.PR_TEL_PERSONA_BENCH_TRACK (COD_PERSONA, TIPO_TELEFONO)';
    END IF;
END;
/

PROMPT ================================================================
PROMPT OPT-020 TEL Q01 - Validacion de tabla de medicion PA o PR
PROMPT ================================================================

SELECT 'PR' AS owner,
       'PR_TEL_PERSONA_BENCH_TRACK' AS table_name,
       CASE WHEN t.table_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado,
       t.tablespace_name AS tablespace
  FROM dual e
  LEFT JOIN all_tables t
   ON t.owner = 'PR'
   AND t.table_name = 'PR_TEL_PERSONA_BENCH_TRACK';

PROMPT ================================================================
PROMPT OPT-020 TEL Q02 - Validacion de indices de medicion PA o PR
PROMPT ================================================================

SELECT e.index_name AS indice,
       e.table_name AS tabla,
       CASE WHEN i.index_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado,
       i.tablespace_name AS tablespace
  FROM (
        SELECT 'IX_TEL_BENCH_EJECUCION' AS index_name, 'PR_TEL_PERSONA_BENCH_TRACK' AS table_name FROM dual UNION ALL
        SELECT 'IX_TEL_BENCH_FECHA',                 'PR_TEL_PERSONA_BENCH_TRACK'                 FROM dual UNION ALL
        SELECT 'IX_TEL_BENCH_PERSONA',               'PR_TEL_PERSONA_BENCH_TRACK'                 FROM dual UNION ALL
        SELECT 'PK_PR_TEL_PERSONA_BENCH_TRACK',      'PR_TEL_PERSONA_BENCH_TRACK'                 FROM dual
       ) e
  LEFT JOIN all_indexes i
    ON i.owner = 'PR'
   AND i.index_name = e.index_name
 ORDER BY e.index_name;

PROMPT Tracking de telefonos creado/validado: PR.PR_TEL_PERSONA_BENCH_TRACK
