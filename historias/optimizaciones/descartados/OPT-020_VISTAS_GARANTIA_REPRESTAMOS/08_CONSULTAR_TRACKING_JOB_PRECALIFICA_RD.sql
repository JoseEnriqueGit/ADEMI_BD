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

PROMPT
PROMPT Q07 - Resumen telefonos de la ultima ejecucion
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
SELECT b.proveedor,
       b.tipo_telefono,
       COUNT(*) AS llamadas,
       ROUND(SUM(b.duracion_ms), 3) AS total_ms,
       ROUND(AVG(b.duracion_ms), 3) AS avg_ms,
       ROUND(MIN(b.duracion_ms), 3) AS min_ms,
       ROUND(MAX(b.duracion_ms), 3) AS max_ms,
       SUM(CASE WHEN b.error_code IS NOT NULL OR b.error_message IS NOT NULL THEN 1 ELSE 0 END) AS errores
  FROM PR.PR_TEL_PERSONA_BENCH_TRACK b
  JOIN ultima u
    ON u.id_ejecucion = b.id_ejecucion
 GROUP BY b.proveedor, b.tipo_telefono
 ORDER BY b.proveedor, b.tipo_telefono;

PROMPT
PROMPT Q08 - Top 50 llamadas mas lentas de la ultima ejecucion
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
SELECT *
  FROM (
        SELECT TO_CHAR(b.fecha_medicion, 'YYYY-MM-DD HH24:MI:SS') AS fecha_medicion,
               b.proveedor,
               b.cod_persona,
               b.tipo_telefono,
               b.duracion_ms,
               SUBSTR(b.valor_telefono, 1, 40) AS valor_telefono,
               b.error_code,
               SUBSTR(b.error_message, 1, 120) AS error_message
          FROM PR.PR_TEL_PERSONA_BENCH_TRACK b
          JOIN ultima u
            ON u.id_ejecucion = b.id_ejecucion
         ORDER BY b.duracion_ms DESC NULLS LAST
       )
 WHERE ROWNUM <= 50;

PROMPT
PROMPT Q09 - Errores de telefonos de la ultima ejecucion
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
SELECT TO_CHAR(b.fecha_medicion, 'YYYY-MM-DD HH24:MI:SS') AS fecha_medicion,
       b.proveedor,
       b.cod_persona,
       b.tipo_telefono,
       b.duracion_ms,
       SUBSTR(b.valor_telefono, 1, 80) AS valor_telefono,
       b.error_code,
       SUBSTR(b.error_message, 1, 200) AS error_message
  FROM PR.PR_TEL_PERSONA_BENCH_TRACK b
  JOIN ultima u
    ON u.id_ejecucion = b.id_ejecucion
 WHERE b.error_code IS NOT NULL
    OR b.error_message IS NOT NULL
 ORDER BY b.fecha_medicion;

PROMPT
PROMPT Q10 - Comparacion telefonos PA vs PR por 2 ejecuciones
PROMPT   Usar los mismos IDs definidos en Q06.
PROMPT

SELECT NVL(a.tipo_telefono, b.tipo_telefono) AS tipo_telefono,
       a.proveedor AS proveedor_a,
       b.proveedor AS proveedor_b,
       a.llamadas AS llamadas_a,
       b.llamadas AS llamadas_b,
       a.total_ms AS total_ms_a,
       b.total_ms AS total_ms_b,
       b.total_ms - a.total_ms AS delta_ms,
       a.avg_ms AS avg_ms_a,
       b.avg_ms AS avg_ms_b,
       a.errores AS errores_a,
       b.errores AS errores_b
  FROM (
        SELECT proveedor,
               tipo_telefono,
               COUNT(*) AS llamadas,
               ROUND(SUM(duracion_ms), 3) AS total_ms,
               ROUND(AVG(duracion_ms), 3) AS avg_ms,
               SUM(CASE WHEN error_code IS NOT NULL OR error_message IS NOT NULL THEN 1 ELSE 0 END) AS errores
          FROM PR.PR_TEL_PERSONA_BENCH_TRACK
         WHERE id_ejecucion = '&P_EJECUCION_A'
         GROUP BY proveedor, tipo_telefono
       ) a
  FULL OUTER JOIN (
        SELECT proveedor,
               tipo_telefono,
               COUNT(*) AS llamadas,
               ROUND(SUM(duracion_ms), 3) AS total_ms,
               ROUND(AVG(duracion_ms), 3) AS avg_ms,
               SUM(CASE WHEN error_code IS NOT NULL OR error_message IS NOT NULL THEN 1 ELSE 0 END) AS errores
          FROM PR.PR_TEL_PERSONA_BENCH_TRACK
         WHERE id_ejecucion = '&P_EJECUCION_B'
         GROUP BY proveedor, tipo_telefono
       ) b
    ON b.tipo_telefono = a.tipo_telefono
 ORDER BY tipo_telefono;
