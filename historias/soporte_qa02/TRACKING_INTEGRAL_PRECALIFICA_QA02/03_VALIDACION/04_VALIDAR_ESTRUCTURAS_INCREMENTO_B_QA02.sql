-- =====================================================================
-- Validacion de estructuras del Incremento B
-- Entorno: QA02
-- Solo lectura. Ejecutar en Toad DESPUES del script
--   ../01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql
--   y ANTES de compilar el body con el Incremento B.
-- Esperado: las 2 columnas nuevas existen, la PK y el indice de fecha
--   siguen intactos y el parametro TRACK_PRECALIFICA_ACTIVO esta en 'S'.
-- =====================================================================

PROMPT 1. Columnas de PR_JOB_PRECALIFICA_CANDIDATO_TRACK (esperado: NO_CREDITO y CODIGO_CLIENTE presentes, NUMBER(7), nullable)

SELECT column_id,
       column_name,
       data_type,
       data_precision,
       data_length,
       nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
 ORDER BY column_id;

PROMPT 2. Verificacion puntual de las columnas del Incremento B (esperado: 2 filas)

SELECT column_name,
       data_type,
       data_precision,
       nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
   AND column_name IN ('NO_CREDITO', 'CODIGO_CLIENTE')
 ORDER BY column_name;

PROMPT 3. PK e indices intactos (esperado: PK_PR_JOB_PRECAL_CAND_TRACK + IX_PRECAL_CAND_FECHA, ambos VALID)

SELECT i.index_name,
       i.uniqueness,
       i.status,
       i.tablespace_name
  FROM all_indexes i
 WHERE i.owner = 'PR'
   AND i.table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
 ORDER BY i.index_name;

SELECT c.constraint_name,
       c.constraint_type,
       c.status
  FROM all_constraints c
 WHERE c.owner = 'PR'
   AND c.table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
   AND c.constraint_type = 'P';

PROMPT 4. Filas previas en la Capa C (referencia; el Incremento B escribe por ID_EJECUCION nuevo)

SELECT COUNT(*) AS filas_previas
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK;

PROMPT 5. Parametro de activacion (esperado: TRACK_PRECALIFICA_ACTIVO = S para la prueba)

SELECT codigo_parametro,
       valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro IN ('TRACK_PRECALIFICA_ACTIVO',
                            'TRACK_PRECALIFICA_DETALLE_CURSOR',
                            'TRACK_PRECALIFICA_RETENCION_DIAS')
 ORDER BY codigo_parametro;
