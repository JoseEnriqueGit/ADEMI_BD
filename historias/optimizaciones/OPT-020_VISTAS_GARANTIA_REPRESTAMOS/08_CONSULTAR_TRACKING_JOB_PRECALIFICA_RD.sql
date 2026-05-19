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

PROMPT
PROMPT Q05 - Comparacion automatica de las 2 ultimas ejecuciones
PROMPT   seg_ant  = penultima ejecucion   |   seg_ult = ultima ejecucion
PROMPT   delta_seg negativo = la ultima fue mas rapida
PROMPT

WITH ranked AS (
    SELECT id_ejecucion,
           ROW_NUMBER() OVER (ORDER BY MIN(fecha_inicio) DESC) rn
      FROM PR.PR_JOB_PRECALIFICA_TRACK
     GROUP BY id_ejecucion
),
eje_ant AS (SELECT id_ejecucion FROM ranked WHERE rn = 2),
eje_ult AS (SELECT id_ejecucion FROM ranked WHERE rn = 1)
SELECT NVL(a.id_paso, b.id_paso)                          AS id_paso,
       NVL(a.proceso, b.proceso)                          AS proceso,
       a.duracion_segundos                                AS seg_ant,
       b.duracion_segundos                                AS seg_ult,
       b.duracion_segundos - a.duracion_segundos          AS delta_seg,
       CASE WHEN NVL(a.duracion_segundos, 0) > 0
            THEN ROUND((b.duracion_segundos - a.duracion_segundos)
                       / a.duracion_segundos * 100, 1)
       END                                                AS delta_pct,
       a.registros_re                                     AS re_ant,
       b.registros_re                                     AS re_ult,
       a.estado                                           AS estado_ant,
       b.estado                                           AS estado_ult
  FROM (SELECT t.* FROM PR.PR_JOB_PRECALIFICA_TRACK t
         JOIN eje_ant e ON e.id_ejecucion = t.id_ejecucion) a
  FULL OUTER JOIN
       (SELECT t.* FROM PR.PR_JOB_PRECALIFICA_TRACK t
         JOIN eje_ult e ON e.id_ejecucion = t.id_ejecucion) b
    ON a.id_paso = b.id_paso
 ORDER BY id_paso;

PROMPT
PROMPT Q06 - Comparacion de 2 ejecuciones por ID
PROMPT   Copiar los id_ejecucion desde Q01 y pegarlos abajo.
PROMPT   P_EJECUCION_A = ejecucion base    |   P_EJECUCION_B = ejecucion a comparar
PROMPT   delta_seg negativo = B fue mas rapida que A
PROMPT

DEFINE P_EJECUCION_A = 'PEGAR_ID_EJECUCION_A';
DEFINE P_EJECUCION_B = 'PEGAR_ID_EJECUCION_B';

SELECT NVL(a.id_paso, b.id_paso)                          AS id_paso,
       NVL(a.proceso, b.proceso)                          AS proceso,
       a.duracion_segundos                                AS seg_a,
       b.duracion_segundos                                AS seg_b,
       b.duracion_segundos - a.duracion_segundos          AS delta_seg,
       CASE WHEN NVL(a.duracion_segundos, 0) > 0
            THEN ROUND((b.duracion_segundos - a.duracion_segundos)
                       / a.duracion_segundos * 100, 1)
       END                                                AS delta_pct,
       a.registros_re                                     AS re_a,
       b.registros_re                                     AS re_b,
       a.estado                                           AS estado_a,
       b.estado                                           AS estado_b
  FROM (SELECT * FROM PR.PR_JOB_PRECALIFICA_TRACK
         WHERE id_ejecucion = '&P_EJECUCION_A') a
  FULL OUTER JOIN
       (SELECT * FROM PR.PR_JOB_PRECALIFICA_TRACK
         WHERE id_ejecucion = '&P_EJECUCION_B') b
    ON a.id_paso = b.id_paso
 ORDER BY id_paso;
