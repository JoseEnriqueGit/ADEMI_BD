-- QA02 - Diagnostico DE08 sin filtro FECHA_CORTE despues de TIPO_CREDITO y PERIODOS_CUOTA
WITH base_creditos AS (
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
     WHERE EXISTS (
              SELECT 1
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
               WHERE subq.column_value = a.codigo_periodo_cuota
           )
        OR NOT EXISTS (
              SELECT 1
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
           )
),
base_keys AS (
    SELECT DISTINCT no_credito
      FROM periodo_cuota_ok
),
de08_credito AS (
    SELECT d.no_credito,
           MAX(1) existe_no_credito,
           MAX(CASE WHEN d.fuente = 'PR' THEN 1 ELSE 0 END) tiene_fuente_pr
      FROM PA.PA_DETALLADO_DE08 d
      JOIN base_keys bk
        ON bk.no_credito = d.no_credito
     GROUP BY d.no_credito
),
de08_tipo_credito AS (
    SELECT DISTINCT d.no_credito,
           d.tipo_credito
      FROM PA.PA_DETALLADO_DE08 d
      JOIN base_keys bk
        ON bk.no_credito = d.no_credito
     WHERE d.fuente = 'PR'
),
detalle AS (
    SELECT b.codigo_empresa,
           b.codigo_cliente,
           b.no_credito,
           b.tipo_credito,
           b.codigo_periodo_cuota,
           CASE WHEN NVL(dc.existe_no_credito, 0) = 1 THEN 'SI_PASA' ELSE 'NO_PASA' END f_existe_no_credito_de08,
           CASE WHEN NVL(dc.tiene_fuente_pr, 0) = 1 THEN 'SI_PASA' ELSE 'NO_PASA' END f_fuente_pr,
           CASE WHEN dt.no_credito IS NOT NULL THEN 'SI_PASA' ELSE 'NO_PASA' END f_tipo_credito_de08,
           CASE WHEN dt.no_credito IS NOT NULL THEN 'SI_PASA_FILTRO_COMPLETO' ELSE 'NO_PASA_FILTRO_COMPLETO' END resultado_final
      FROM periodo_cuota_ok b
      LEFT JOIN de08_credito dc
        ON dc.no_credito = b.no_credito
      LEFT JOIN de08_tipo_credito dt
        ON dt.no_credito = b.no_credito
       AND dt.tipo_credito = b.tipo_credito
),
resumen AS (
    SELECT '0. BASE: PR_CREDITOS' filtro,
           'TOTAL' resultado,
           COUNT(*) cantidad
      FROM base_creditos
    UNION ALL
    SELECT '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
           'SI_PASA',
           COUNT(*)
      FROM con_tipo_represtamo
    UNION ALL
    SELECT '1. TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO',
           'NO_PASA',
           (SELECT COUNT(*) FROM base_creditos) - (SELECT COUNT(*) FROM con_tipo_represtamo)
      FROM dual
    UNION ALL
    SELECT '2. PERIODOS_CUOTA permitido o parametro vacio',
           'SI_PASA',
           COUNT(*)
      FROM periodo_cuota_ok
    UNION ALL
    SELECT '2. PERIODOS_CUOTA permitido o parametro vacio',
           'NO_PASA',
           (SELECT COUNT(*) FROM con_tipo_represtamo) - (SELECT COUNT(*) FROM periodo_cuota_ok)
      FROM dual
    UNION ALL
    SELECT '3. Base antes de PA_DETALLADO_DE08',
           'TOTAL',
           COUNT(*)
      FROM detalle
    UNION ALL
    SELECT filtro,
           resultado,
           COUNT(*)
      FROM (
            SELECT '4. Existe NO_CREDITO en PA_DETALLADO_DE08' filtro,
                   f_existe_no_credito_de08 resultado
              FROM detalle
            UNION ALL
            SELECT '5. Tiene FUENTE = PR',
                   f_fuente_pr
              FROM detalle
            UNION ALL
            SELECT '7. Coincide TIPO_CREDITO',
                   f_tipo_credito_de08
              FROM detalle
            UNION ALL
            SELECT '8. Filtro completo DE08',
                   resultado_final
              FROM detalle
           )
     GROUP BY filtro,
              resultado
)
SELECT filtro,
       resultado,
       cantidad
  FROM resumen
 ORDER BY filtro,
          resultado DESC
