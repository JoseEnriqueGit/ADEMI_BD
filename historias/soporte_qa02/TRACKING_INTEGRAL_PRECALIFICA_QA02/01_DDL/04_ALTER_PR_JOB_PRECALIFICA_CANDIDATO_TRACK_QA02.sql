-- =====================================================================
-- Incremento B - Extension de la Capa C con identificadores del candidato
-- Entorno: QA02
-- Objeto: PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
-- Fecha: 2026-06-09
-- Idempotente. Ejecutar en Toad ("Execute as Script"). No ejecuta DML funcional.
-- Agrega columnas NO_CREDITO y CODIGO_CLIENTE (NUMBER(7), igual que
--   PR.PR_REPRESTAMOS segun el DDL del repo, lineas 7 y 9). Se dejan
--   NULLABLE para que el tracking nunca falle por falta de valor.
-- NO recrea la tabla ni toca la PK, indices o filas existentes.
-- Reversa: ../04_ROLLBACK/04_ROLLBACK_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tab_columns
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
       AND column_name = 'NO_CREDITO';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK ADD (NO_CREDITO NUMBER(7))';
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

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK ADD (CODIGO_CLIENTE NUMBER(7))';
    END IF;
END;
/

PROMPT Incremento B: columnas NO_CREDITO y CODIGO_CLIENTE agregadas/validadas

SELECT column_name,
       data_type,
       data_precision,
       nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
 ORDER BY column_id;
