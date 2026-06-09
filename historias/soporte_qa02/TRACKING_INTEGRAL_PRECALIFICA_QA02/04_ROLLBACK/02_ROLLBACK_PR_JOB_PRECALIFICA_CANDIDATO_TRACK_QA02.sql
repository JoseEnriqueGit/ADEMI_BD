-- =====================================================================
-- ROLLBACK Capa C - PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
-- Entorno: QA02
-- Fecha: 2026-06-08
-- Elimina la tabla de pertenencia al lote (la PK y el indice de fecha
-- caen con la tabla).
-- ATENCION: ejecutar SOLO con aprobacion explicita. Conserva evidencia
--           del diagnostico. No usa PURGE: permite FLASHBACK solo si el
--           parametro RECYCLEBIN esta en ON (verificar antes de ejecutar).
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK';
    END IF;
END;
/

PROMPT Rollback Capa C ejecutado: tabla eliminada (indices caen con la tabla).
