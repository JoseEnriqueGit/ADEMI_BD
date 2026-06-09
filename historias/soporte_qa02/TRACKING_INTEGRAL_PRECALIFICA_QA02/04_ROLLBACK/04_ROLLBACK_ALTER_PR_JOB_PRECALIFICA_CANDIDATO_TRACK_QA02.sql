-- =====================================================================
-- Reversa del Incremento B (DDL) - quita las columnas agregadas a la Capa C
-- Entorno: QA02
-- Objeto: PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
-- Deshace: ../01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql
-- Idempotente. Ejecutar en Toad solo con aprobacion explicita.
-- NO borra la tabla, la PK, los indices ni las filas; solo las columnas
--   NO_CREDITO y CODIGO_CLIENTE (se pierde el dato de esas columnas).
-- Ejecutar ANTES el rollback del body B si el body con track_candidato
--   sigue compilado: el MERGE referencia estas columnas y el body
--   quedaria INVALID al eliminarlas.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tab_columns
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
       AND column_name = 'NO_CREDITO';

    IF v_count = 1 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK DROP COLUMN NO_CREDITO';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tab_columns
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
       AND column_name = 'CODIGO_CLIENTE';

    IF v_count = 1 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK DROP COLUMN CODIGO_CLIENTE';
    END IF;
END;
/

PROMPT Reversa Incremento B (DDL): columnas NO_CREDITO y CODIGO_CLIENTE eliminadas

SELECT column_name,
       data_type,
       data_precision,
       nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
 ORDER BY column_id;
