-- =====================================================================
-- OPT-020 - Rollback de tracking persistente de telefonos PA o PR
-- Entorno objetivo: QA02
--
-- Uso:
--   Ejecutar solo si se retira la instrumentacion del body o si se desea
--   borrar la evidencia de medicion de PR.PR_TEL_PERSONA_BENCH_TRACK.
--
-- Nota:
--   La reversa del body es recompilar el respaldo previo a esta medicion.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_TEL_PERSONA_BENCH_TRACK';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE PR.PR_TEL_PERSONA_BENCH_TRACK PURGE';
    END IF;
END;
/

PROMPT Tracking de telefonos eliminado: PR.PR_TEL_PERSONA_BENCH_TRACK
