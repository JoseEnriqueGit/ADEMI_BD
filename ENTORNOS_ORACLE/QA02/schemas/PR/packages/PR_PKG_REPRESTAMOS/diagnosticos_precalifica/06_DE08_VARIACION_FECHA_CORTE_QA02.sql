-- QA02 - Diagnostico de variacion de PA_DETALLADO_DE08 entre fechas de corte PR
WITH cortes AS (
    SELECT p.fecha_corte,
           COUNT(*) total_filas,
           COUNT(DISTINCT p.no_credito) total_creditos
      FROM PA.PA_DETALLADO_DE08 p
     WHERE p.fuente = 'PR'
     GROUP BY p.fecha_corte
),
cortes_variacion AS (
    SELECT c.fecha_corte,
           c.total_filas,
           c.total_creditos,
           c.total_filas - LAG(c.total_filas) OVER (ORDER BY c.fecha_corte) variacion_filas_vs_corte_anterior,
           c.total_creditos - LAG(c.total_creditos) OVER (ORDER BY c.fecha_corte) variacion_creditos_vs_corte_anterior
      FROM cortes c
),
cortes_top AS (
    SELECT cv.*,
           ROW_NUMBER() OVER (ORDER BY cv.fecha_corte DESC) rn
      FROM cortes_variacion cv
),
corte_actual AS (
    SELECT MAX(p.fecha_corte) fecha_corte_actual
      FROM PA.PA_DETALLADO_DE08 p
     WHERE p.fuente = 'PR'
),
cortes_actual_anterior AS (
    SELECT ca.fecha_corte_actual,
           MAX(p.fecha_corte) fecha_corte_anterior
      FROM corte_actual ca
      LEFT JOIN PA.PA_DETALLADO_DE08 p
        ON p.fuente = 'PR'
       AND p.fecha_corte < ca.fecha_corte_actual
     GROUP BY ca.fecha_corte_actual
),
actual AS (
    SELECT d.no_credito,
           d.tipo_credito,
           COUNT(*) filas_actual
      FROM PA.PA_DETALLADO_DE08 d
      JOIN cortes_actual_anterior c
        ON c.fecha_corte_actual = d.fecha_corte
     WHERE d.fuente = 'PR'
     GROUP BY d.no_credito,
              d.tipo_credito
),
anterior AS (
    SELECT d.no_credito,
           d.tipo_credito,
           COUNT(*) filas_anterior
      FROM PA.PA_DETALLADO_DE08 d
      JOIN cortes_actual_anterior c
        ON c.fecha_corte_anterior = d.fecha_corte
     WHERE d.fuente = 'PR'
     GROUP BY d.no_credito,
              d.tipo_credito
),
comparacion AS (
    SELECT NVL(a.no_credito, b.no_credito) no_credito,
           NVL(a.tipo_credito, b.tipo_credito) tipo_credito,
           a.filas_actual,
           b.filas_anterior,
           CASE
             WHEN a.no_credito IS NOT NULL AND b.no_credito IS NOT NULL THEN 'SE_MANTIENE_EN_CORTE_ACTUAL'
             WHEN a.no_credito IS NOT NULL THEN 'ENTRA_EN_CORTE_ACTUAL'
             ELSE 'SALE_DEL_CORTE_ACTUAL'
           END movimiento
      FROM actual a
      FULL OUTER JOIN anterior b
        ON b.no_credito = a.no_credito
       AND b.tipo_credito = a.tipo_credito
),
movimiento_resumen AS (
    SELECT movimiento,
           COUNT(*) creditos_tipo,
           SUM(NVL(filas_actual, 0)) filas_actual,
           SUM(NVL(filas_anterior, 0)) filas_anterior
      FROM comparacion
     GROUP BY movimiento
),
params AS (
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
de08_actual AS (
    SELECT d.no_credito,
           d.tipo_credito,
           COUNT(*) filas_de08
      FROM PA.PA_DETALLADO_DE08 d
      JOIN params p
        ON p.fecha_corte = d.fecha_corte
     WHERE d.fuente = 'PR'
     GROUP BY d.no_credito,
              d.tipo_credito
),
clasificacion AS (
    SELECT d.no_credito,
           d.tipo_credito,
           d.filas_de08,
           CASE
             WHEN a.no_credito IS NULL THEN 'NO_PASA: no existe en PR_CREDITOS'
             WHEN a.tipo_credito != d.tipo_credito THEN 'NO_PASA: tipo_credito DE08 no coincide con PR_CREDITOS'
             WHEN c.tipo_credito IS NULL THEN 'NO_PASA: tipo_credito no existe en PR_TIPO_CREDITO_REPRESTAMO'
             WHEN pc.total_periodos > 0 AND pp.codigo_periodo_cuota IS NULL THEN 'NO_PASA: PERIODOS_CUOTA no permitido'
             ELSE 'SI_PASA: cumple condiciones base del cursor'
           END resultado
      FROM de08_actual d
      CROSS JOIN periodos_count pc
      LEFT JOIN PR.PR_CREDITOS a
        ON a.no_credito = d.no_credito
      LEFT JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
      LEFT JOIN periodos_param pp
        ON pp.codigo_periodo_cuota = a.codigo_periodo_cuota
),
clasificacion_resumen AS (
    SELECT resultado,
           COUNT(*) creditos_tipo,
           SUM(filas_de08) filas_de08
      FROM clasificacion
     GROUP BY resultado
),
salida AS (
    SELECT 100 + (rn * 10) orden,
           '1. Fecha corte ' || TO_CHAR(fecha_corte, 'DD/MM/YYYY') filtro,
           'TOTAL_FILAS' resultado,
           total_filas cantidad
      FROM cortes_top
     WHERE rn <= 10
    UNION ALL
    SELECT 101 + (rn * 10),
           '1. Fecha corte ' || TO_CHAR(fecha_corte, 'DD/MM/YYYY'),
           'TOTAL_CREDITOS',
           total_creditos
      FROM cortes_top
     WHERE rn <= 10
    UNION ALL
    SELECT 102 + (rn * 10),
           '1. Fecha corte ' || TO_CHAR(fecha_corte, 'DD/MM/YYYY'),
           'VARIACION_FILAS_VS_CORTE_ANTERIOR',
           NVL(variacion_filas_vs_corte_anterior, 0)
      FROM cortes_top
     WHERE rn <= 10
    UNION ALL
    SELECT 103 + (rn * 10),
           '1. Fecha corte ' || TO_CHAR(fecha_corte, 'DD/MM/YYYY'),
           'VARIACION_CREDITOS_VS_CORTE_ANTERIOR',
           NVL(variacion_creditos_vs_corte_anterior, 0)
      FROM cortes_top
     WHERE rn <= 10
    UNION ALL
    SELECT 300,
           '2. Movimiento entre corte actual y anterior',
           movimiento || ' - CREDITOS_TIPO',
           creditos_tipo
      FROM movimiento_resumen
    UNION ALL
    SELECT 301,
           '2. Movimiento entre corte actual y anterior',
           movimiento || ' - FILAS_ACTUAL',
           filas_actual
      FROM movimiento_resumen
    UNION ALL
    SELECT 302,
           '2. Movimiento entre corte actual y anterior',
           movimiento || ' - FILAS_ANTERIOR',
           filas_anterior
      FROM movimiento_resumen
    UNION ALL
    SELECT 400,
           '3. Corte actual contra condiciones base del cursor',
           resultado || ' - CREDITOS_TIPO',
           creditos_tipo
      FROM clasificacion_resumen
    UNION ALL
    SELECT 401,
           '3. Corte actual contra condiciones base del cursor',
           resultado || ' - FILAS_DE08',
           filas_de08
      FROM clasificacion_resumen
)
SELECT filtro,
       resultado,
       cantidad
  FROM salida
 ORDER BY orden,
          resultado DESC
