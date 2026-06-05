-- QA02 - Diagnostico: conteo y detalle del filtro PA_DETALLADO_DE08 por fecha corte, fuente PR y tipo credito
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte
      FROM dual
),
base AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito
      FROM PR.PR_CREDITOS a
),
detalle AS (
    SELECT b.codigo_empresa,
           b.codigo_cliente,
           b.no_credito,
           b.tipo_credito,
           p.fecha_corte,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_existe_no_credito_de08,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_fuente_pr,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                       AND d.fecha_corte = p.fecha_corte
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_fecha_corte_pr,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                       AND d.fecha_corte = p.fecha_corte
                       AND d.tipo_credito = b.tipo_credito
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_tipo_credito_de08,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                       AND d.fecha_corte = p.fecha_corte
                       AND d.tipo_credito = b.tipo_credito
                  ) THEN 'SI_PASA_FILTRO_COMPLETO'
             ELSE 'NO_PASA_FILTRO_COMPLETO'
           END resultado_final
      FROM base b
      CROSS JOIN params p
)
SELECT filtro,
       resultado,
       COUNT(*) cantidad
  FROM (
        SELECT '1. Existe NO_CREDITO en PA_DETALLADO_DE08' filtro,
               f_existe_no_credito_de08 resultado
          FROM detalle
        UNION ALL
        SELECT '2. Tiene FUENTE = PR',
               f_fuente_pr
          FROM detalle
        UNION ALL
        SELECT '3. Tiene FECHA_CORTE maxima PR',
               f_fecha_corte_pr
          FROM detalle
        UNION ALL
        SELECT '4. Coincide TIPO_CREDITO',
               f_tipo_credito_de08
          FROM detalle
        UNION ALL
        SELECT '5. Filtro completo DE08',
               resultado_final
          FROM detalle
       )
 GROUP BY filtro,
          resultado
 ORDER BY filtro,
          resultado DESC;

WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte
      FROM dual
),
base AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito
      FROM PR.PR_CREDITOS a
),
detalle AS (
    SELECT b.codigo_empresa,
           b.codigo_cliente,
           b.no_credito,
           b.tipo_credito,
           p.fecha_corte,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_existe_no_credito_de08,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_fuente_pr,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                       AND d.fecha_corte = p.fecha_corte
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_fecha_corte_pr,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.no_credito = b.no_credito
                       AND d.fuente = 'PR'
                       AND d.fecha_corte = p.fecha_corte
                       AND d.tipo_credito = b.tipo_credito
                  ) THEN 'SI_PASA'
             ELSE 'NO_PASA'
           END f_tipo_credito_de08
      FROM base b
      CROSS JOIN params p
)
SELECT codigo_empresa,
       codigo_cliente,
       no_credito,
       tipo_credito,
       fecha_corte,
       f_existe_no_credito_de08,
       f_fuente_pr,
       f_fecha_corte_pr,
       f_tipo_credito_de08,
       CASE
         WHEN f_tipo_credito_de08 = 'SI_PASA' THEN 'SI_PASA_FILTRO_COMPLETO'
         ELSE 'NO_PASA_FILTRO_COMPLETO'
       END resultado_final
  FROM detalle
 ORDER BY resultado_final,
          codigo_cliente,
          no_credito
