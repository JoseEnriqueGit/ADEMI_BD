-- =====================================================================
-- Conciliacion del Incremento C despues de una ejecucion controlada
-- Entorno: QA02. Solo lectura. Ejecutar DESPUES del job.
-- Uso: poner el cursor dentro de cada query y ejecutar con F9
--      (Execute Statement) para ver el resultado en el Data Grid.
-- Esperado:
--   - Query 1: RESULTADO = OK (sin nulos, sin ids repetidos entre flujos,
--     huerfanos del cierre <= RE de linea base INI_RE_DESPUES).
--   - Query 2: bruto por flujo >= neto de la Capa B del mismo flujo; la
--     diferencia son los descartados intra-flujo (X1/X2/X3/mancomunado/
--     edad), que el Incremento C hace visibles por primera vez.
--   - La Capa B sigue en 31 metricas (C no agrega filas alli).
-- =====================================================================

-- Query 1: resumen de la ultima ejecucion en UNA fila
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
cand AS (
    SELECT c.*
      FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
      JOIN ultima u ON u.id_ejecucion = c.id_ejecucion
),
flujos AS (
    SELECT COUNT(*) c_flujos,
           COUNT(DISTINCT flujo) flujos_presentes,
           COUNT(CASE WHEN no_credito IS NULL THEN 1 END) nc_nulos,
           COUNT(CASE WHEN codigo_cliente IS NULL THEN 1 END) cc_nulos,
           COUNT(*) - COUNT(DISTINCT id_represtamo) ids_repetidos
      FROM cand
     WHERE flujo <> 'CIERRE'
),
cierre AS (
    SELECT COUNT(*) c_cierre
      FROM cand
     WHERE flujo = 'CIERRE'
),
huerf AS (
    SELECT COUNT(*) huerfanos_cierre
      FROM cand c1
     WHERE c1.flujo = 'CIERRE'
       AND NOT EXISTS (
           SELECT 1
             FROM cand c2
            WHERE c2.id_represtamo = c1.id_represtamo
              AND c2.flujo <> 'CIERRE')
),
b AS (
    SELECT NVL(MAX(CASE WHEN t.codigo_filtro = 'INI_RE_DESPUES'
                        THEN t.candidatos_pasan END), 0) re_linea_base,
           COUNT(*) metricas_capa_b
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
)
SELECT u.id_ejecucion,
       f.c_flujos          AS filas_pertenencia,
       f.flujos_presentes,
       ci.c_cierre         AS filas_cierre,
       h.huerfanos_cierre,
       b.re_linea_base,
       f.nc_nulos,
       f.cc_nulos,
       f.ids_repetidos,
       b.metricas_capa_b,
       CASE
           WHEN f.nc_nulos = 0
            AND f.cc_nulos = 0
            AND f.ids_repetidos = 0
            AND h.huerfanos_cierre <= b.re_linea_base
            AND b.metricas_capa_b = 31
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM ultima u, flujos f, cierre ci, huerf h, b;

-- Query 2: bruto insertado por flujo (Capa C) vs neto del flujo (Capa B);
--          la diferencia aproxima los descartados intra-flujo
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
neto AS (
    SELECT t.flujo,
           TO_NUMBER(SUBSTR(t.parametros,
                            INSTR(t.parametros, 'NETO=') + 5)) neto_capa_b
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
     WHERE t.codigo_filtro = 'RE_ACUMULADO_TRAS_FLUJO'
)
SELECT c.flujo,
       COUNT(*) bruto_insertado,
       n.neto_capa_b,
       COUNT(*) - NVL(n.neto_capa_b, 0) descartados_aprox,
       MIN(c.fecha_registro) primera_fila,
       MAX(c.fecha_registro) ultima_fila
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  JOIN ultima u ON u.id_ejecucion = c.id_ejecucion
  LEFT JOIN neto n ON n.flujo = c.flujo
 WHERE c.flujo <> 'CIERRE'
 GROUP BY c.flujo, n.neto_capa_b
 ORDER BY c.flujo;

-- Query 3: recorrido individual - pertenencia + resultado del cierre
--          (muestra de 20; candidatos sin fila CIERRE = descartados antes)
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
        SELECT p.flujo        AS flujo_origen,
               p.id_represtamo,
               p.no_credito,
               p.codigo_cliente,
               ci.resultado_ultimo AS resultado_cierre,
               CASE WHEN ci.id_represtamo IS NULL
                    THEN 'DESCARTADO_ANTES_DEL_CIERRE' END nota
          FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK p
          JOIN ultima u ON u.id_ejecucion = p.id_ejecucion
          LEFT JOIN PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK ci
            ON ci.id_ejecucion = p.id_ejecucion
           AND ci.id_represtamo = p.id_represtamo
           AND ci.flujo = 'CIERRE'
         WHERE p.flujo <> 'CIERRE'
         ORDER BY p.id_represtamo
       )
 WHERE ROWNUM <= 20;

-- Query 4: duraciones - total (0), flujos (2-6) y cierre (13) para medir
--          el overhead del Incremento C contra corridas previas
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
       t.proceso,
       t.estado,
       t.duracion_segundos
  FROM PR.PR_JOB_PRECALIFICA_TRACK t
  JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
 WHERE t.id_paso IN (0, 2, 3, 4, 5, 6, 13)
 ORDER BY t.id_paso;
