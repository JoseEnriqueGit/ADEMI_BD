-- QA02 - Diagnostico DE08 despues de TIPO_CREDITO y PERIODOS_CUOTA del cursor Precalifica_Represtamo
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte
      FROM dual
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
conteos AS (
    SELECT (SELECT COUNT(*) FROM base_creditos) base_total,
           (SELECT COUNT(*) FROM con_tipo_represtamo) tipo_pasan,
           (SELECT COUNT(*) FROM periodo_cuota_ok) periodo_pasan,
           COUNT(*) de08_base,
           NVL(SUM(CASE
                     WHEN EXISTS (
                            SELECT 1
                              FROM PA.PA_DETALLADO_DE08 d
                             WHERE d.no_credito = b.no_credito
                          ) THEN 1
                     ELSE 0
                   END), 0) existe_no_credito_pasan,
           NVL(SUM(CASE
                     WHEN EXISTS (
                            SELECT 1
                              FROM PA.PA_DETALLADO_DE08 d
                             WHERE d.no_credito = b.no_credito
                               AND d.fuente = 'PR'
                          ) THEN 1
                     ELSE 0
                   END), 0) fuente_pr_pasan,
           NVL(SUM(CASE
                     WHEN EXISTS (
                            SELECT 1
                              FROM PA.PA_DETALLADO_DE08 d
                             WHERE d.no_credito = b.no_credito
                               AND d.fuente = 'PR'
                               AND d.fecha_corte = p.fecha_corte
                          ) THEN 1
                     ELSE 0
                   END), 0) fecha_corte_pasan,
           NVL(SUM(CASE
                     WHEN EXISTS (
                            SELECT 1
                              FROM PA.PA_DETALLADO_DE08 d
                             WHERE d.no_credito = b.no_credito
                               AND d.fuente = 'PR'
                               AND d.fecha_corte = p.fecha_corte
                               AND d.tipo_credito = b.tipo_credito
                          ) THEN 1
                     ELSE 0
                   END), 0) tipo_credito_de08_pasan
      FROM periodo_cuota_ok b
      CROSS JOIN params p
)
SELECT filtro,
       resultado,
       cantidad
  FROM (
        SELECT '0. BASE: PR_CREDITOS' filtro,
               'TOTAL' resultado,
               base_total cantidad
          FROM conteos
        UNION ALL
        SELECT '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
               'SI_PASA',
               tipo_pasan
          FROM conteos
        UNION ALL
        SELECT '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
               'NO_PASA',
               base_total - tipo_pasan
          FROM conteos
        UNION ALL
        SELECT '2. PERIODOS_CUOTA permitido o parametro vacio',
               'SI_PASA',
               periodo_pasan
          FROM conteos
        UNION ALL
        SELECT '2. PERIODOS_CUOTA permitido o parametro vacio',
               'NO_PASA',
               tipo_pasan - periodo_pasan
          FROM conteos
        UNION ALL
        SELECT '3. Base antes de PA_DETALLADO_DE08',
               'TOTAL',
               de08_base
          FROM conteos
        UNION ALL
        SELECT '4. Existe NO_CREDITO en PA_DETALLADO_DE08',
               'SI_PASA',
               existe_no_credito_pasan
          FROM conteos
        UNION ALL
        SELECT '4. Existe NO_CREDITO en PA_DETALLADO_DE08',
               'NO_PASA',
               de08_base - existe_no_credito_pasan
          FROM conteos
        UNION ALL
        SELECT '5. Tiene FUENTE = PR',
               'SI_PASA',
               fuente_pr_pasan
          FROM conteos
        UNION ALL
        SELECT '5. Tiene FUENTE = PR',
               'NO_PASA',
               de08_base - fuente_pr_pasan
          FROM conteos
        UNION ALL
        SELECT '6. Tiene FECHA_CORTE maxima PR',
               'SI_PASA',
               fecha_corte_pasan
          FROM conteos
        UNION ALL
        SELECT '6. Tiene FECHA_CORTE maxima PR',
               'NO_PASA',
               de08_base - fecha_corte_pasan
          FROM conteos
        UNION ALL
        SELECT '7. Coincide TIPO_CREDITO',
               'SI_PASA',
               tipo_credito_de08_pasan
          FROM conteos
        UNION ALL
        SELECT '7. Coincide TIPO_CREDITO',
               'NO_PASA',
               de08_base - tipo_credito_de08_pasan
          FROM conteos
        UNION ALL
        SELECT '8. Filtro completo DE08',
               'SI_PASA_FILTRO_COMPLETO',
               tipo_credito_de08_pasan
          FROM conteos
        UNION ALL
        SELECT '8. Filtro completo DE08',
               'NO_PASA_FILTRO_COMPLETO',
               de08_base - tipo_credito_de08_pasan
          FROM conteos
       )
 ORDER BY filtro,
          resultado DESC
