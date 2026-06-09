-- =====================================================================
-- Conciliacion del Incremento B despues de una ejecucion controlada
-- Entorno: QA02
-- Solo lectura. Ejecutar en Toad despues del job.
-- Esperado:
--   - La Capa C (PR_JOB_PRECALIFICA_CANDIDATO_TRACK) tiene una fila por
--     candidato evaluado en el cierre, todas con FLUJO='CIERRE'.
--   - COUNT(Capa C) = FINAL_TOTAL de la Capa B (misma ejecucion).
--   - El desglose por RESULTADO_ULTIMO coincide con FINAL_NP/CP/RXT/AN.
--   - NO_CREDITO y CODIGO_CLIENTE sin nulos.
--   - La Capa B sigue generando 31 metricas (B no agrega filas alli).
-- =====================================================================

PROMPT 1. Ultima ejecucion del job

SELECT *
  FROM (
        SELECT id_ejecucion,
               estado,
               fecha_inicio,
               fecha_fin,
               duracion_segundos,
               registros_re,
               error_code,
               error_message
          FROM PR.PR_JOB_PRECALIFICA_TRACK
         WHERE id_paso = 0
         ORDER BY fecha_inicio DESC
       )
 WHERE ROWNUM = 1;

PROMPT 2. Cohorte individual del cierre (Capa C) de la ultima ejecucion

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT c.flujo,
       c.resultado_ultimo,
       COUNT(*) AS candidatos,
       MIN(c.fecha_registro) AS primera_fila,
       MAX(c.fecha_registro) AS ultima_fila
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  JOIN ultima u
    ON u.id_ejecucion = c.id_ejecucion
 GROUP BY c.flujo, c.resultado_ultimo
 ORDER BY c.flujo, c.resultado_ultimo;

PROMPT 3. Conciliacion Capa C vs metricas FINAL_* de la Capa B

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
),
capa_b AS (
    SELECT MAX(CASE WHEN codigo_filtro = 'FINAL_TOTAL'
                    THEN candidatos_antes END) b_total,
           MAX(CASE WHEN codigo_filtro = 'FINAL_NP'
                    THEN candidatos_pasan END) b_np,
           MAX(CASE WHEN codigo_filtro = 'FINAL_CP'
                    THEN candidatos_pasan END) b_cp,
           MAX(CASE WHEN codigo_filtro = 'FINAL_RXT'
                    THEN candidatos_descartados END) b_rxt,
           MAX(CASE WHEN codigo_filtro = 'FINAL_AN'
                    THEN candidatos_descartados END) b_an,
           MAX(CASE WHEN codigo_filtro = 'FINAL_OTRO'
                    THEN candidatos_descartados END) b_otro
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u
        ON u.id_ejecucion = t.id_ejecucion
),
capa_c AS (
    SELECT COUNT(*) c_total,
           COUNT(CASE WHEN resultado_ultimo = 'NP'  THEN 1 END) c_np,
           COUNT(CASE WHEN resultado_ultimo = 'CP'  THEN 1 END) c_cp,
           COUNT(CASE WHEN resultado_ultimo = 'RXT' THEN 1 END) c_rxt,
           COUNT(CASE WHEN resultado_ultimo = 'AN'  THEN 1 END) c_an,
           COUNT(CASE WHEN resultado_ultimo NOT IN ('NP','CP','RXT','AN')
                       OR resultado_ultimo IS NULL THEN 1 END) c_otro
      FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
      JOIN ultima u
        ON u.id_ejecucion = c.id_ejecucion
)
SELECT b.b_total,
       c.c_total,
       b.b_total - c.c_total AS ids_sin_fila_capa_c,
       b.b_np,  c.c_np,
       b.b_cp,  c.c_cp,
       b.b_rxt, c.c_rxt,
       b.b_an,  c.c_an,
       b.b_otro, c.c_otro,
       CASE
           WHEN b.b_total = c.c_total
            AND NVL(b.b_np, 0)  = c.c_np
            AND NVL(b.b_cp, 0)  = c.c_cp
            AND NVL(b.b_rxt, 0) = c.c_rxt
            AND NVL(b.b_an, 0)  = c.c_an
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM capa_b b, capa_c c;

PROMPT 4. Calidad de datos de la Capa C (esperado: todo en 0)

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT COUNT(CASE WHEN c.no_credito IS NULL THEN 1 END) AS no_credito_nulos,
       COUNT(CASE WHEN c.codigo_cliente IS NULL THEN 1 END) AS codigo_cliente_nulos,
       COUNT(CASE WHEN c.resultado_ultimo IS NULL THEN 1 END) AS resultado_nulos,
       COUNT(CASE WHEN c.flujo <> 'CIERRE' THEN 1 END) AS flujo_distinto_cierre,
       COUNT(*) - COUNT(DISTINCT c.id_represtamo) AS ids_duplicados,
       CASE
           WHEN COUNT(CASE WHEN c.no_credito IS NULL THEN 1 END) = 0
            AND COUNT(CASE WHEN c.codigo_cliente IS NULL THEN 1 END) = 0
            AND COUNT(CASE WHEN c.resultado_ultimo IS NULL THEN 1 END) = 0
            AND COUNT(CASE WHEN c.flujo <> 'CIERRE' THEN 1 END) = 0
            AND COUNT(*) = COUNT(DISTINCT c.id_represtamo)
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  JOIN ultima u
    ON u.id_ejecucion = c.id_ejecucion;

PROMPT 5. Contraste informativo contra PR_REPRESTAMOS (puede divergir si el front cambio estados despues del job)

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT c.resultado_ultimo,
       r.estado AS estado_vivo,
       COUNT(*) AS candidatos
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  JOIN ultima u
    ON u.id_ejecucion = c.id_ejecucion
  LEFT JOIN PR.PR_REPRESTAMOS r
    ON r.id_represtamo = c.id_represtamo
 GROUP BY c.resultado_ultimo, r.estado
 ORDER BY c.resultado_ultimo, r.estado;

PROMPT 6. Muestra de la cohorte (20 filas)

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT *
  FROM (
        SELECT c.id_ejecucion,
               c.flujo,
               c.id_represtamo,
               c.no_credito,
               c.codigo_cliente,
               c.resultado_ultimo,
               c.fecha_registro
          FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
          JOIN ultima u
            ON u.id_ejecucion = c.id_ejecucion
         ORDER BY c.id_represtamo
       )
 WHERE ROWNUM <= 20;

PROMPT 7. La Capa B se mantiene en 31 metricas (el Incremento B no agrega filas alli)

WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT COUNT(*) total_metricas,
       CASE WHEN COUNT(*) = 31 THEN 'OK' ELSE 'REVISAR' END resultado
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
  JOIN ultima u
    ON u.id_ejecucion = t.id_ejecucion;

PROMPT 8. Errores de compilacion o ejecucion

SELECT type,
       line,
       position,
       text
  FROM all_errors
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
 ORDER BY sequence;
