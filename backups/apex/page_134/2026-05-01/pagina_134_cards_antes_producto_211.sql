WITH CuentasBase AS (
    SELECT
        ce.NUM_CUENTA,
        ce.SAL_TOTAL_CTA,
        ce.FEC_CANCELAC,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM PA.EMPLEADOS emp
            WHERE emp.COD_PER_FISICA = ce.COD_CLIENTE
              AND emp.COD_EMPRESA = ce.COD_EMPRESA
              AND emp.ESTA_ACTIVO = 'S'
          ) THEN 'Empleado (Interno)'
          ELSE 'Cliente Externo'
        END AS TIPO_CLIENTE
    FROM CC.CUENTA_EFECTIVO ce
    WHERE ce.COD_PRODUCTO = '210'
      AND (
          (:P134_LOGICA_FECHA = 'AND'
            AND TRUNC(ce.FEC_APERTURA) BETWEEN TO_DATE(:P134_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_DATE, 'DD-MM-YYYY')
            AND TRUNC(ce.FEC_CANCELAC) BETWEEN TO_DATE(:P134_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_CANC, 'DD-MM-YYYY')
          )
          OR
          (:P134_LOGICA_FECHA = 'OR'
            AND (
                TRUNC(ce.FEC_APERTURA) BETWEEN TO_DATE(:P134_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_DATE, 'DD-MM-YYYY')
                OR
                (ce.FEC_CANCELAC IS NOT NULL AND TRUNC(ce.FEC_CANCELAC) BETWEEN TO_DATE(:P134_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_CANC, 'DD-MM-YYYY'))
            )
          )
      )
),
CuentasFiltradas AS (
    SELECT * FROM CuentasBase
    WHERE (
          :P134_FILTRO_CARD IS NULL
          OR (:P134_FILTRO_CARD = 'Total cuentas activas' AND FEC_CANCELAC IS NULL)
          OR (:P134_FILTRO_CARD = 'Total cuentas activas empleados' AND FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Empleado (Interno)')
          OR (:P134_FILTRO_CARD = 'Total cuentas activas cliente' AND FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Cliente Externo')
          OR (:P134_FILTRO_CARD = 'Total Cuentas Canceladas' AND FEC_CANCELAC IS NOT NULL)
    )
)
SELECT 'Total cuentas activas' AS CARD_TITLE, TO_CHAR(COUNT(*), 'FM999,999,999,990') AS CARD_TEXT, 'Vigentes' AS CARD_SUBTEXT, 'fa-calculator' AS CARD_ICON, 'u-color-1' AS CARD_COLOR, 1 AS ORDER_COL FROM CuentasBase WHERE FEC_CANCELAC IS NULL
UNION ALL
SELECT 'Total cuentas activas empleados', TO_CHAR(COUNT(*), 'FM999,999,999,990'), 'Personal interno', 'fa-briefcase', 'u-color-4', 2 AS ORDER_COL FROM CuentasBase WHERE FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Empleado (Interno)'
UNION ALL
SELECT 'Total cuentas activas cliente', TO_CHAR(COUNT(*), 'FM999,999,999,990'), 'Clientes externos', 'fa-users', 'u-color-6', 3 AS ORDER_COL FROM CuentasBase WHERE FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Cliente Externo'
UNION ALL
SELECT 'Saldo Ctas. Empleados', TO_CHAR(NVL(SUM(SAL_TOTAL_CTA), 0), 'FM999,999,999,990.00'), 'Saldos actuales', 'fa-money', 'u-color-8', 4 AS ORDER_COL FROM CuentasFiltradas WHERE FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Empleado (Interno)'
UNION ALL
SELECT 'Saldo Ctas. Clientes', TO_CHAR(NVL(SUM(SAL_TOTAL_CTA), 0), 'FM999,999,999,990.00'), 'Saldos actuales', 'fa-usd', 'u-color-9', 5 AS ORDER_COL FROM CuentasFiltradas WHERE FEC_CANCELAC IS NULL AND TIPO_CLIENTE = 'Cliente Externo'
UNION ALL
SELECT 'Total Cuentas Canceladas', TO_CHAR(COUNT(*), 'FM999,999,999,990'), 'Canceladas segun filtros', 'fa-ban', 'u-color-21', 6 AS ORDER_COL FROM CuentasBase WHERE FEC_CANCELAC IS NOT NULL
ORDER BY ORDER_COL;
