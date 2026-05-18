-- =====================================================================
-- OPT-020 - Consultas de tracking persistente del job
-- Entorno objetivo: QA02
--
-- Uso:
--   Ejecutar despues de correr PR.JOB_CARGA_PRECALIFICA_RD.
-- =====================================================================

SET LINESIZE 220
SET PAGESIZE 500

PROMPT
PROMPT Q01 - Ultimas ejecuciones del job
PROMPT

SELECT id_ejecucion,
       TO_CHAR(MIN(fecha_inicio), 'YYYY-MM-DD HH24:MI:SS') AS inicio,
       TO_CHAR(MAX(fecha_fin), 'YYYY-MM-DD HH24:MI:SS')    AS fin,
       MAX(CASE WHEN id_paso = 0 THEN estado END)          AS estado_total,
       MAX(CASE WHEN id_paso = 0 THEN duracion_segundos END) AS segundos_total,
       MAX(CASE WHEN id_paso = 0 THEN duracion_minutos END)  AS minutos_total,
       MAX(registros_re) AS registros_re
  FROM PR.PR_JOB_PRECALIFICA_TRACK
 GROUP BY id_ejecucion
 ORDER BY MIN(fecha_inicio) DESC
 FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT Q02 - Ranking de procesos de la ultima ejecucion
PROMPT

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
 WHERE t.id_paso <> 0
 ORDER BY t.duracion_segundos DESC NULLS LAST;

PROMPT
PROMPT Q03 - Detalle ordenado de la ultima ejecucion
PROMPT

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
       t.duracion_segundos,
       t.duracion_minutos,
       t.registros_re
  FROM PR.PR_JOB_PRECALIFICA_TRACK t
  JOIN ultima u
    ON u.id_ejecucion = t.id_ejecucion
 ORDER BY t.id_paso;

PROMPT
PROMPT Q04 - Historico por proceso
PROMPT

SELECT proceso,
       COUNT(*) AS ejecuciones,
       ROUND(AVG(duracion_segundos), 3) AS avg_segundos,
       ROUND(MIN(duracion_segundos), 3) AS min_segundos,
       ROUND(MAX(duracion_segundos), 3) AS max_segundos
  FROM PR.PR_JOB_PRECALIFICA_TRACK
 WHERE id_paso <> 0
   AND estado = 'FINALIZADO'
 GROUP BY proceso
 ORDER BY avg_segundos DESC;
