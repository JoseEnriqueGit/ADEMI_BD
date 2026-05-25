-- =====================================================================
-- Validacion QA02 - JOB_CARGA_PRECALIFICA_RD completa
-- Entorno: QA02
-- Objeto: PR.PR_PKG_REPRESTAMOS / PR.JOB_CARGA_PRECALIFICA_RD
-- Fecha: 2026-05-25
-- =====================================================================

-- 1. Compilar body.
ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;

SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS;

-- 2. Confirmar que el job no esta corriendo antes de lanzarlo.
SELECT owner, job_name, session_id, running_instance
  FROM dba_scheduler_running_jobs
 WHERE owner = 'PR'
   AND job_name = 'JOB_CARGA_PRECALIFICA_RD';

-- 3. Ejecutar job manualmente.
BEGIN
  DBMS_SCHEDULER.RUN_JOB(
    job_name            => 'PR.JOB_CARGA_PRECALIFICA_RD',
    use_current_session => FALSE
  );
END;
/

-- 4. Revisar ultima ejecucion por tracking persistente.
WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion, MIN(fecha_inicio) inicio
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             GROUP BY id_ejecucion
             ORDER BY MIN(fecha_inicio) DESC
           )
     WHERE ROWNUM = 1
)
SELECT t.id_paso,
       t.proceso,
       t.estado,
       TO_CHAR(t.fecha_inicio, 'YYYY-MM-DD HH24:MI:SS') AS inicio,
       TO_CHAR(t.fecha_fin, 'YYYY-MM-DD HH24:MI:SS')    AS fin,
       t.duracion_segundos,
       t.duracion_minutos,
       t.registros_re,
       t.error_code,
       SUBSTR(t.error_message, 1, 300) AS error_message
  FROM PR.PR_JOB_PRECALIFICA_TRACK t
  JOIN ultima u
    ON u.id_ejecucion = t.id_ejecucion
 ORDER BY t.id_paso;

-- 5. Resultado esperado:
--    - Paso 0 TOTAL_JOB en FINALIZADO.
--    - Sin ORA-01407 por DIAS_ATRASO.
--    - Pasos principales con FECHA_FIN y duracion.

