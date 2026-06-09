-- =====================================================================
-- Conciliacion del Incremento A despues de una ejecucion controlada
-- Entorno: QA02
-- Solo lectura. Ejecutar en Toad despues del job.
-- Esperado: 31 filas de Capa B para la ultima ejecucion con tracking.
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

PROMPT 2. Detalle de filtros de la ultima ejecucion

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
SELECT t.id_ejecucion,
       t.orden_filtro,
       t.flujo,
       t.fase,
       t.codigo_filtro,
       t.tipo_medicion,
       t.candidatos_antes,
       t.candidatos_pasan,
       t.candidatos_descartados,
       t.valor_lote,
       t.fecha_corte,
       t.parametros,
       t.fecha_registro
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
  JOIN ultima u
    ON u.id_ejecucion = t.id_ejecucion
 ORDER BY t.orden_filtro;

PROMPT 3. Cobertura esperada: 31 metricas y orden sin duplicados

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
       COUNT(DISTINCT orden_filtro) ordenes_distintos,
       MIN(orden_filtro) orden_minimo,
       MAX(orden_filtro) orden_maximo,
       CASE
           WHEN COUNT(*) = 31
            AND COUNT(DISTINCT orden_filtro) = 31
            AND MIN(orden_filtro) = 1
            AND MAX(orden_filtro) = 31
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
  JOIN ultima u
    ON u.id_ejecucion = t.id_ejecucion;

PROMPT 4. Conciliacion de precalificacion

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
metricas AS (
    SELECT MAX(CASE WHEN codigo_filtro = 'PRE_RE_ENTRADA'
                    THEN candidatos_antes END) entrada,
           MAX(CASE WHEN codigo_filtro = 'PRE_RSB'
                    THEN candidatos_descartados END) rsb,
           MAX(CASE WHEN codigo_filtro = 'PRE_CLS_RCS'
                    THEN candidatos_descartados END) cls_rcs,
           MAX(CASE WHEN codigo_filtro = 'PRE_BORRADOS'
                    THEN candidatos_descartados END) borrados,
           MAX(CASE WHEN codigo_filtro = 'PRE_RE_SALIDA'
                    THEN candidatos_pasan END) salida
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u
        ON u.id_ejecucion = t.id_ejecucion
)
SELECT entrada,
       rsb,
       cls_rcs,
       borrados,
       salida,
       NVL(rsb, 0) + NVL(cls_rcs, 0) + NVL(borrados, 0)
           + NVL(salida, 0) total_reconciliado,
       CASE
           WHEN entrada = NVL(rsb, 0) + NVL(cls_rcs, 0)
                        + NVL(borrados, 0) + NVL(salida, 0)
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM metricas;

PROMPT 5. Conciliacion del cierre

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
metricas AS (
    SELECT MAX(CASE WHEN codigo_filtro = 'FINAL_TOTAL'
                    THEN candidatos_antes END) total,
           MAX(CASE WHEN codigo_filtro = 'FINAL_NP'
                    THEN candidatos_pasan END) np,
           MAX(CASE WHEN codigo_filtro = 'FINAL_CP'
                    THEN candidatos_pasan END) cp,
           MAX(CASE WHEN codigo_filtro = 'FINAL_RXT'
                    THEN candidatos_descartados END) rxt,
           MAX(CASE WHEN codigo_filtro = 'FINAL_AN'
                    THEN candidatos_descartados END) an,
           MAX(CASE WHEN codigo_filtro = 'FINAL_OTRO'
                    THEN candidatos_descartados END) otro
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u
        ON u.id_ejecucion = t.id_ejecucion
)
SELECT total,
       np,
       cp,
       rxt,
       an,
       otro,
       NVL(np, 0) + NVL(cp, 0) + NVL(rxt, 0)
           + NVL(an, 0) + NVL(otro, 0) total_reconciliado,
       CASE
           WHEN total = NVL(np, 0) + NVL(cp, 0) + NVL(rxt, 0)
                      + NVL(an, 0) + NVL(otro, 0)
           THEN 'OK'
           ELSE 'REVISAR'
       END resultado
  FROM metricas;

PROMPT 6. Errores de compilacion o ejecucion

SELECT type,
       line,
       position,
       text
  FROM all_errors
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
 ORDER BY sequence;
