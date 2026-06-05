-- QA02 - Conteo PR_CREDITOS por estado con DE08 en FECHA_CORTE maxima PR
WITH params AS (
    SELECT MAX(p.fecha_corte) fecha_corte
      FROM PA.PA_DETALLADO_DE08 p
     WHERE p.fuente = 'PR'
)
SELECT a.estado,
       p.fecha_corte,
       COUNT(*) cantidad
  FROM PR.PR_CREDITOS a
  CROSS JOIN params p
 WHERE a.estado IN ('D', 'V', 'M', 'E', 'J')
   AND EXISTS (
          SELECT 1
            FROM PA.PA_DETALLADO_DE08 b
           WHERE b.no_credito = a.no_credito
             AND b.tipo_credito = a.tipo_credito
             AND b.fecha_corte = p.fecha_corte
             AND b.fuente = 'PR'
       )
 GROUP BY a.estado,
          p.fecha_corte
 ORDER BY a.estado
