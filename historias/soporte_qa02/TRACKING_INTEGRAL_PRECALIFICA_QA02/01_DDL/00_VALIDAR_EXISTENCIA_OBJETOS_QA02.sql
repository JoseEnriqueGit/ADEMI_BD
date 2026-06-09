-- =====================================================================
-- Validacion de existencia de objetos auxiliares - Tracking integral
-- Entorno: QA02
-- Objetos: PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
--          PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
-- Fecha: 2026-06-08
-- Solo lectura. Ejecutar en Toad ANTES de crear cualquier objeto.
-- Confirma: version, nombres libres, tipo de ID_REPRESTAMO, tablespace
-- de indices y columnas obligatorias de PA_PARAMETROS_MVP.
-- =====================================================================

PROMPT 1. Version de Oracle (limite de identificadores)
-- Los nombres PR_JOB_PRECALIFICA_FILTRO_TRACK (31) y
-- PR_JOB_PRECALIFICA_CANDIDATO_TRACK (34) superan el limite de 30 bytes
-- de Oracle <= 11.2. Requieren 12.2+ (limite 128). Si la BD es 11g,
-- usar los alias cortos descritos en ./README.md antes de crear.

SELECT banner FROM v$version;

PROMPT 2. Tablas de tracking (existente y propuestas)

SELECT t.table_name,
       CASE WHEN o.object_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado
  FROM (
        SELECT 'PR_JOB_PRECALIFICA_TRACK'           AS table_name FROM dual UNION ALL
        SELECT 'PR_JOB_PRECALIFICA_FILTRO_TRACK'                  FROM dual UNION ALL
        SELECT 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'              FROM dual
       ) t
  LEFT JOIN all_objects o
    ON o.owner = 'PR'
   AND o.object_name = t.table_name
   AND o.object_type = 'TABLE'
 ORDER BY t.table_name;

PROMPT 3. Secuencia, llaves e indices propuestos

SELECT e.object_name,
       e.object_type,
       CASE WHEN o.object_name IS NULL THEN 'NO EXISTE' ELSE 'EXISTE' END AS estado
  FROM (
        SELECT 'SEQ_PR_JOB_PRECAL_FILTRO'      AS object_name, 'SEQUENCE' AS object_type FROM dual UNION ALL
        SELECT 'PK_PR_JOB_PRECAL_FILTRO_TRACK',                'INDEX'                    FROM dual UNION ALL
        SELECT 'IX_PRECAL_FILTRO_CONSULTA',                    'INDEX'                    FROM dual UNION ALL
        SELECT 'IX_PRECAL_FILTRO_FECHA',                       'INDEX'                    FROM dual UNION ALL
        SELECT 'PK_PR_JOB_PRECAL_CAND_TRACK',                  'INDEX'                    FROM dual UNION ALL
        SELECT 'IX_PRECAL_CAND_FECHA',                         'INDEX'                    FROM dual
       ) e
  LEFT JOIN all_objects o
    ON o.owner = 'PR'
   AND o.object_name = e.object_name
   AND o.object_type = e.object_type
 ORDER BY e.object_type, e.object_name;

PROMPT 3b. Constraints nombrados - el CHECK no aparece en all_objects

SELECT e.constraint_name,
       CASE WHEN c.constraint_name IS NULL THEN 'NO EXISTE'
            ELSE 'EXISTE (' || c.table_name || ')' END AS estado
  FROM (
        SELECT 'PK_PR_JOB_PRECAL_FILTRO_TRACK' AS constraint_name FROM dual UNION ALL
        SELECT 'CK_PR_JOB_PRECAL_FIL_TIPMED'                      FROM dual UNION ALL
        SELECT 'PK_PR_JOB_PRECAL_CAND_TRACK'                      FROM dual
       ) e
  LEFT JOIN all_constraints c
    ON c.owner = 'PR'
   AND c.constraint_name = e.constraint_name
 ORDER BY e.constraint_name;

PROMPT 4. Tablespaces de indices usados por PR (confirmar que existe PR_IDX)

SELECT tablespace_name, COUNT(*) AS indices
  FROM all_indexes
 WHERE owner = 'PR'
   AND tablespace_name IS NOT NULL
 GROUP BY tablespace_name
 ORDER BY indices DESC;

PROMPT 5. Tipo real de PR.PR_REPRESTAMOS.ID_REPRESTAMO

SELECT column_name, data_type, data_length, data_precision, nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name = 'PR_REPRESTAMOS'
   AND column_name = 'ID_REPRESTAMO';
-- El DDL del repo (PR_REPRESTAMOS.sql:6) define NUMBER(14); la Capa C usa
-- NUMBER(14). Confirmar que el tipo vivo en QA02 coincide antes de crear.

PROMPT 6. Columnas de PA.PA_PARAMETROS_MVP (detectar NOT NULL sin DEFAULT)

SELECT column_id, column_name, data_type, nullable, data_default
  FROM all_tab_columns
 WHERE owner = 'PA'
   AND table_name = 'PA_PARAMETROS_MVP'
 ORDER BY column_id;
-- Resultado QA02 (2026-06-08): ademas de las 4 columnas base, son NOT NULL
-- sin DEFAULT: DES_PARAMETRO, ADICIONADO_POR y FECHA_ADICION. El script 03
-- ya las carga (descripcion / USER / SYSDATE).

PROMPT 7. Parametro modelo y parametros TRACK_* ya existentes

SELECT codigo_empresa, codigo_mvp, codigo_parametro, valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro IN (
       'LOTE_DE_CARAGA_REPRESTAMO',
       'TRACK_PRECALIFICA_ACTIVO',
       'TRACK_PRECALIFICA_DETALLE_CURSOR',
       'TRACK_PRECALIFICA_RETENCION_DIAS'
   )
 ORDER BY codigo_parametro;
