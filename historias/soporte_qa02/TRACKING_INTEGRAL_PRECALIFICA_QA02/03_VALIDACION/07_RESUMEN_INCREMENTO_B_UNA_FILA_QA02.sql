-- =====================================================================
-- Resumen del Incremento B en UNA fila (alternativa al script 06 cuando
-- Toad no vuelca los SELECT al Script Output).
-- Entorno: QA02. Solo lectura.
-- Uso: poner el cursor dentro de cada query y ejecutar con F9
--      (Execute Statement) para ver el resultado en el Data Grid.
-- Esperado: RESULTADO = OK en la query 1.
-- =====================================================================

-- Query 1: conciliacion + calidad + metricas de la ultima ejecucion
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
b AS (
    SELECT MAX(CASE WHEN codigo_filtro = 'FINAL_TOTAL' THEN candidatos_antes END) b_total,
           MAX(CASE WHEN codigo_filtro = 'FINAL_NP'  THEN candidatos_pasan END) b_np,
           MAX(CASE WHEN codigo_filtro = 'FINAL_CP'  THEN candidatos_pasan END) b_cp,
           MAX(CASE WHEN codigo_filtro = 'FINAL_RXT' THEN candidatos_descartados END) b_rxt,
           MAX(CASE WHEN codigo_filtro = 'FINAL_AN'  THEN candidatos_descartados END) b_an,
           COUNT(*) metricas_capa_b
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
),
c AS (
    SELECT COUNT(*) c_total,
           COUNT(CASE WHEN resultado_ultimo = 'NP'  THEN 1 END) c_np,
           COUNT(CASE WHEN resultado_ultimo = 'CP'  THEN 1 END) c_cp,
           COUNT(CASE WHEN resultado_ultimo = 'RXT' THEN 1 END) c_rxt,
           COUNT(CASE WHEN resultado_ultimo = 'AN'  THEN 1 END) c_an,
           COUNT(CASE WHEN no_credito IS NULL THEN 1 END) nc_nulos,
           COUNT(CASE WHEN codigo_cliente IS NULL THEN 1 END) cc_nulos,
           COUNT(CASE WHEN resultado_ultimo IS NULL THEN 1 END) res_nulos,
           COUNT(CASE WHEN flujo <> 'CIERRE' THEN 1 END) flujo_no_cierre,
           COUNT(*) - COUNT(DISTINCT id_represtamo) duplicados
      FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
)
SELECT u.id_ejecucion,
       b.b_total, c.c_total,
       b.b_np,  c.c_np,
       b.b_cp,  c.c_cp,
       b.b_rxt, c.c_rxt,
       b.b_an,  c.c_an,
       b.metricas_capa_b,
       c.nc_nulos, c.cc_nulos, c.res_nulos,
       c.flujo_no_cierre, c.duplicados,
       CASE
           WHEN b.b_total = c.c_total
            AND NVL(b.b_np, 0)  = c.c_np
            AND NVL(b.b_cp, 0)  = c.c_cp
            AND NVL(b.b_rxt, 0) = c.c_rxt
            AND NVL(b.b_an, 0)  = c.c_an
            AND b.metricas_capa_b = 31
            AND c.nc_nulos = 0
            AND c.cc_nulos = 0
            AND c.res_nulos = 0
            AND c.flujo_no_cierre = 0
            AND c.duplicados = 0
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM ultima u, b, c;

-- Query 2: total del job (paso 0) y loop de cierre (paso 13, donde
--          escribe track_candidato) de la ultima ejecucion
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
SELECT t.id_paso,
       t.estado,
       t.duracion_segundos,
       t.duracion_minutos
  FROM PR.PR_JOB_PRECALIFICA_TRACK t
  JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
 WHERE t.id_paso IN (0, 13)
 ORDER BY t.id_paso;

-- Query 3: costo del cierre por candidato - corrida nueva (Incremento B)
--          vs corrida del Incremento A (53D427AF4F597DB0E063140311AC14C5,
--          5169 candidatos, sin track_candidato)
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
corridas AS (
    SELECT u.id_ejecucion, 'B (nueva)' corrida FROM ultima u
    UNION ALL
    SELECT '53D427AF4F597DB0E063140311AC14C5', 'A (baseline)' FROM DUAL
)
SELECT c.corrida,
       t.id_ejecucion,
       t.duracion_segundos seg_paso13,
       f.candidatos,
       ROUND(t.duracion_segundos / NULLIF(f.candidatos, 0), 4) seg_por_candidato
  FROM corridas c
  JOIN PR.PR_JOB_PRECALIFICA_TRACK t
    ON t.id_ejecucion = c.id_ejecucion
   AND t.id_paso = 13
  LEFT JOIN (
        SELECT id_ejecucion,
               MAX(CASE WHEN codigo_filtro = 'FINAL_TOTAL'
                        THEN candidatos_antes END) candidatos
          FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
         GROUP BY id_ejecucion
       ) f
    ON f.id_ejecucion = c.id_ejecucion
 ORDER BY c.corrida;
