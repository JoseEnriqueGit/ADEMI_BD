-- =====================================================================
-- OPT-020 - Rollback de tracking persistente
-- Entorno objetivo: QA02
--
-- Uso:
--   1. Retirar del body los snippets aplicados desde
--      07_PATCH_TRACKING_PAQUETE_SNIPPETS.sql.
--   2. Compilar PR.PR_PKG_REPRESTAMOS.
--   3. Ejecutar este script solo si se desea eliminar la tabla historica.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_TRACK';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE PR.PR_JOB_PRECALIFICA_TRACK PURGE';
    END IF;
END;
/

PROMPT Tracking persistente eliminado: PR.PR_JOB_PRECALIFICA_TRACK
