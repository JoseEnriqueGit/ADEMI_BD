-- =====================================================================
-- ROLLBACK Capa B - PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
-- Entorno: QA02
-- Fecha: 2026-06-08
-- Elimina tabla y secuencia de la Capa B (la PK y los indices caen con la
-- tabla).
-- ATENCION: ejecutar SOLO con aprobacion explicita. Conserva evidencia
--           del diagnostico. No usa PURGE: permite FLASHBACK de la TABLA
--           solo si el parametro RECYCLEBIN esta en ON (verificar antes).
--           La SECUENCIA no entra a la papelera: su DROP es irreversible.
--           Si se recupera la tabla con FLASHBACK, recrear la secuencia con
--           START WITH = NVL(MAX(ID_DETALLE),0)+1 antes de reinsertar, para
--           no colisionar la PK (ID_EJECUCION, ID_DETALLE).
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_FILTRO_TRACK';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE PR.PR_JOB_PRECALIFICA_FILTRO_TRACK';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_sequences
     WHERE sequence_owner = 'PR'
       AND sequence_name = 'SEQ_PR_JOB_PRECAL_FILTRO';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE PR.SEQ_PR_JOB_PRECAL_FILTRO';
    END IF;
END;
/

PROMPT Rollback Capa B ejecutado: tabla + secuencia eliminadas (indice cae con la tabla).
