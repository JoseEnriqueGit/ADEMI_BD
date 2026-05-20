-- Validacion de saldos por moneda - Pagina 134 APEX
-- Entorno: <reemplazar antes de ejecutar>
-- Fecha: 2026-05-07
-- Objetivo: cuadrar las cards "Saldo Total en Pesos" y "Saldo Total en Dolares"
--           contra la suma directa por producto en CC.CUENTA_EFECTIVO.
-- Notas:
--   * Reemplazar las variables de bind por valores reales antes de correr.
--   * El producto 210 es DOP y el producto 211 es USD segun confirmacion de negocio.

-- 1. Saldo total de cuentas activas en DOP (producto 210)
SELECT
    'DOP (210)' AS MONEDA,
    COUNT(*)                       AS CUENTAS_ACTIVAS,
    NVL(SUM(ce.SAL_TOTAL_CTA), 0)  AS SALDO_TOTAL
FROM CC.CUENTA_EFECTIVO ce
WHERE ce.COD_PRODUCTO = '210'
  AND ce.FEC_CANCELAC IS NULL;

-- 2. Saldo total de cuentas activas en USD (producto 211)
SELECT
    'USD (211)' AS MONEDA,
    COUNT(*)                       AS CUENTAS_ACTIVAS,
    NVL(SUM(ce.SAL_TOTAL_CTA), 0)  AS SALDO_TOTAL
FROM CC.CUENTA_EFECTIVO ce
WHERE ce.COD_PRODUCTO = '211'
  AND ce.FEC_CANCELAC IS NULL;

-- 3. Conciliacion: total de saldo mezclado vs suma por moneda
--    Debe cumplirse: SALDO_MEZCLADO = SALDO_DOP + SALDO_USD
SELECT
    NVL(SUM(CASE WHEN ce.COD_PRODUCTO = '210' THEN ce.SAL_TOTAL_CTA END), 0) AS SALDO_DOP,
    NVL(SUM(CASE WHEN ce.COD_PRODUCTO = '211' THEN ce.SAL_TOTAL_CTA END), 0) AS SALDO_USD,
    NVL(SUM(ce.SAL_TOTAL_CTA), 0)                                            AS SALDO_MEZCLADO
FROM CC.CUENTA_EFECTIVO ce
WHERE ce.COD_PRODUCTO IN ('210', '211')
  AND ce.FEC_CANCELAC IS NULL;

-- 4. Validacion con los mismos filtros de fecha de la pagina (logica AND)
--    Usar este SELECT cuando :P134_LOGICA_FECHA = 'AND'
--    Reemplazar las fechas de bind antes de ejecutar
SELECT
    ce.COD_PRODUCTO,
    COUNT(*)                       AS CUENTAS,
    NVL(SUM(ce.SAL_TOTAL_CTA), 0)  AS SALDO_TOTAL
FROM CC.CUENTA_EFECTIVO ce
WHERE ce.COD_PRODUCTO IN ('210', '211')
  AND ce.FEC_CANCELAC IS NULL
  AND TRUNC(ce.FEC_APERTURA) BETWEEN TO_DATE(:P134_FROM_DATE, 'DD-MM-YYYY')
                                 AND TO_DATE(:P134_TO_DATE, 'DD-MM-YYYY')
GROUP BY ce.COD_PRODUCTO
ORDER BY ce.COD_PRODUCTO;
