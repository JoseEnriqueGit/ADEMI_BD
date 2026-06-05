-- QA02 - Conteo PR_CREDITOS por estado con DE08 sin filtrar FECHA_CORTE
SELECT a.estado,
       COUNT(*) cantidad
  FROM PR.PR_CREDITOS a
 WHERE a.estado IN ('D', 'V', 'M', 'E', 'J')
   AND EXISTS (
          SELECT 1
            FROM PA.PA_DETALLADO_DE08 b
           WHERE b.no_credito = a.no_credito
             AND b.tipo_credito = a.tipo_credito
             AND b.fuente = 'PR'
       )
 GROUP BY a.estado
 ORDER BY a.estado
