-- QA02 - Comparacion DE08 con FECHA_CORTE maxima vs sin filtro FECHA_CORTE
WITH params AS (
    SELECT MAX(p.fecha_corte) fecha_corte
      FROM PA.PA_DETALLADO_DE08 p
     WHERE p.fuente = 'PR'
),
periodos_param AS (
    SELECT DISTINCT subq.column_value codigo_periodo_cuota
      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
),
periodos_count AS (
    SELECT COUNT(*) total_periodos
      FROM periodos_param
),
base_creditos AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota
      FROM PR.PR_CREDITOS a
),
con_tipo_represtamo AS (
    SELECT a.*
      FROM base_creditos a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
),
periodo_cuota_ok AS (
    SELECT a.*
      FROM con_tipo_represtamo a
      CROSS JOIN periodos_count pc
      LEFT JOIN periodos_param pp
        ON pp.codigo_periodo_cuota = a.codigo_periodo_cuota
     WHERE pc.total_periodos = 0
        OR pp.codigo_periodo_cuota IS NOT NULL
),
base_keys AS (
    SELECT DISTINCT no_credito,
           tipo_credito
      FROM periodo_cuota_ok
),
de08_con_fecha AS (
    SELECT DISTINCT d.no_credito,
           d.tipo_credito
      FROM PA.PA_DETALLADO_DE08 d
      JOIN base_keys bk
        ON bk.no_credito = d.no_credito
       AND bk.tipo_credito = d.tipo_credito
      CROSS JOIN params p
     WHERE d.fuente = 'PR'
       AND d.fecha_corte = p.fecha_corte
),
de08_sin_fecha AS (
    SELECT DISTINCT d.no_credito,
           d.tipo_credito
      FROM PA.PA_DETALLADO_DE08 d
      JOIN base_keys bk
        ON bk.no_credito = d.no_credito
       AND bk.tipo_credito = d.tipo_credito
     WHERE d.fuente = 'PR'
),
detalle AS (
    SELECT b.codigo_empresa,
           b.codigo_cliente,
           b.no_credito,
           b.tipo_credito,
           b.codigo_periodo_cuota,
           CASE WHEN cf.no_credito IS NOT NULL THEN 1 ELSE 0 END pasa_con_fecha,
           CASE WHEN sf.no_credito IS NOT NULL THEN 1 ELSE 0 END pasa_sin_fecha
      FROM periodo_cuota_ok b
      LEFT JOIN de08_con_fecha cf
        ON cf.no_credito = b.no_credito
       AND cf.tipo_credito = b.tipo_credito
      LEFT JOIN de08_sin_fecha sf
        ON sf.no_credito = b.no_credito
       AND sf.tipo_credito = b.tipo_credito
),
conteos AS (
    SELECT (SELECT COUNT(*) FROM base_creditos) base_total,
           (SELECT COUNT(*) FROM con_tipo_represtamo) tipo_pasan,
           (SELECT COUNT(*) FROM periodo_cuota_ok) periodo_pasan,
           COUNT(*) de08_base,
           NVL(SUM(pasa_con_fecha), 0) pasan_con_fecha,
           NVL(SUM(pasa_sin_fecha), 0) pasan_sin_fecha,
           NVL(SUM(CASE WHEN pasa_con_fecha = 1 AND pasa_sin_fecha = 1 THEN 1 ELSE 0 END), 0) pasan_en_ambos,
           NVL(SUM(CASE WHEN pasa_con_fecha = 0 AND pasa_sin_fecha = 1 THEN 1 ELSE 0 END), 0) adicionales_sin_fecha,
           NVL(SUM(CASE WHEN pasa_con_fecha = 0 AND pasa_sin_fecha = 0 THEN 1 ELSE 0 END), 0) no_pasan_en_ninguno,
           NVL(SUM(CASE WHEN pasa_con_fecha = 1 AND pasa_sin_fecha = 0 THEN 1 ELSE 0 END), 0) inconsistencia_con_fecha_no_sin_fecha
      FROM detalle
)
SELECT filtro,
       resultado,
       cantidad
  FROM (
        SELECT 0 orden,
               '0. BASE: PR_CREDITOS' filtro,
               'TOTAL' resultado,
               base_total cantidad
          FROM conteos
        UNION ALL
        SELECT 10,
               '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
               'SI_PASA',
               tipo_pasan
          FROM conteos
        UNION ALL
        SELECT 11,
               '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
               'NO_PASA',
               base_total - tipo_pasan
          FROM conteos
        UNION ALL
        SELECT 20,
               '2. PERIODOS_CUOTA permitido o parametro vacio',
               'SI_PASA',
               periodo_pasan
          FROM conteos
        UNION ALL
        SELECT 21,
               '2. PERIODOS_CUOTA permitido o parametro vacio',
               'NO_PASA',
               tipo_pasan - periodo_pasan
          FROM conteos
        UNION ALL
        SELECT 30,
               '3. Base antes de PA_DETALLADO_DE08',
               'TOTAL',
               de08_base
          FROM conteos
        UNION ALL
        SELECT 40,
               '4. Filtro completo DE08 con FECHA_CORTE maxima PR',
               'SI_PASA',
               pasan_con_fecha
          FROM conteos
        UNION ALL
        SELECT 41,
               '4. Filtro completo DE08 con FECHA_CORTE maxima PR',
               'NO_PASA',
               de08_base - pasan_con_fecha
          FROM conteos
        UNION ALL
        SELECT 50,
               '5. Filtro completo DE08 sin FECHA_CORTE',
               'SI_PASA',
               pasan_sin_fecha
          FROM conteos
        UNION ALL
        SELECT 51,
               '5. Filtro completo DE08 sin FECHA_CORTE',
               'NO_PASA',
               de08_base - pasan_sin_fecha
          FROM conteos
        UNION ALL
        SELECT 60,
               '6. Comparacion 05 vs 07',
               'PASAN_EN_AMBOS',
               pasan_en_ambos
          FROM conteos
        UNION ALL
        SELECT 61,
               '6. Comparacion 05 vs 07',
               'ADICIONALES_AL_QUITAR_FECHA_CORTE',
               adicionales_sin_fecha
          FROM conteos
        UNION ALL
        SELECT 62,
               '6. Comparacion 05 vs 07',
               'NO_PASAN_EN_NINGUNO',
               no_pasan_en_ninguno
          FROM conteos
        UNION ALL
        SELECT 63,
               '6. Comparacion 05 vs 07',
               'INCONSISTENCIA_CON_FECHA_NO_SIN_FECHA',
               inconsistencia_con_fecha_no_sin_fecha
          FROM conteos
       )
 ORDER BY orden
