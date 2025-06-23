WITH LatestBitacora AS (
    SELECT B.ID_REPRESTAMO, B.CODIGO_ESTADO, ROW_NUMBER() OVER(PARTITION BY B.ID_REPRESTAMO ORDER BY B.ID_BITACORA DESC, B.FECHA_ADICION DESC) as rn
    FROM PR.PR_BITACORA_REPRESTAMO B
),
HasCryStatus AS (
    SELECT DISTINCT ID_REPRESTAMO
    FROM PR.PR_BITACORA_REPRESTAMO
    WHERE CODIGO_ESTADO = 'CRY'
),
BaseData AS (
    SELECT
        S.ID_REPRESTAMO,
        R.MTO_PREAPROBADO,
        R.FECHA_PROCESO,
        C.MONTO_DESEMBOLSADO,
        C.F_PRIMER_DESEMBOLSO AS FechaDesembolso,
        LB.CODIGO_ESTADO AS CodigoEstadoActual,
        CASE WHEN LB.CODIGO_ESTADO = 'CRD' THEN
            CASE WHEN HCS.ID_REPRESTAMO IS NOT NULL THEN 'Digital (con firma)' ELSE 'Sucursal (tradicional)' END
             ELSE NULL
        END AS CanalDesembolsoDeterminado
    FROM PA.EMPLEADOS P
    JOIN PA.AGENCIA A ON TO_NUMBER(P.COD_EMPRESA) = A.COD_EMPRESA AND TO_NUMBER(P.COD_AGENCIA_LABORA) = A.COD_AGENCIA
    JOIN PR.PR_SOLICITUD_REPRESTAMO S ON TO_NUMBER(P.COD_AGENCIA_LABORA) = S.CODIGO_AGENCIA AND TO_NUMBER(P.COD_EMPRESA) = S.CODIGO_EMPRESA
    JOIN PR.PR_REPRESTAMOS R ON S.ID_REPRESTAMO = R.ID_REPRESTAMO AND S.CODIGO_EMPRESA = R.CODIGO_EMPRESA
    JOIN LatestBitacora LB ON S.ID_REPRESTAMO = LB.ID_REPRESTAMO AND LB.rn = 1
    LEFT JOIN HasCryStatus HCS ON S.ID_REPRESTAMO = HCS.ID_REPRESTAMO
    LEFT JOIN PR.PR_CREDITOS C ON S.NO_CREDITO = C.NO_CREDITO AND S.CODIGO_EMPRESA = C.CODIGO_EMPRESA
    WHERE
        SUBSTR(P.EMAIL1, 1, INSTR(P.EMAIL1, '@') - 1) = 'MAMATOS'
        AND P.ID_EMPLEADO = A.GERENTE
        AND P.ESTA_ACTIVO = 'S'
),
EfectividadData AS (
    SELECT
        (SELECT COUNT(DISTINCT ID_REPRESTAMO)
         FROM BaseData
         WHERE CodigoEstadoActual = 'CRD'
           AND FechaDesembolso >= TO_DATE('01/05/2025', 'DD/MM/YYYY')
           AND FechaDesembolso < ADD_MONTHS(TO_DATE('01/05/2025', 'DD/MM/YYYY'), 1)
        ) AS CantidadDesembolsados,
        (SELECT COUNT(DISTINCT ID_REPRESTAMO)
         FROM BaseData
         WHERE FECHA_PROCESO >= TO_DATE('01/05/2025', 'DD/MM/YYYY')
           AND FECHA_PROCESO < ADD_MONTHS(TO_DATE('01/05/2025', 'DD/MM/YYYY'), 1)
        ) AS CantidadPreaprobados
    FROM DUAL
)
SELECT
    'Total Preaprobados' AS CARD_TITLE, TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)) AS CARD_TEXT,
    'Monto: ' || TO_CHAR(NVL(SUM(MTO_PREAPROBADO),0), 'FM999,999,990.00') AS CARD_SUBTEXT,
    'fa-file-invoice-dollar' AS CARD_ICON, 'u-color-1' AS CARD_COLOR, 1 AS order_col
FROM BaseData
UNION ALL
SELECT
    'Total Desembolsados' AS CARD_TITLE, TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)) AS CARD_TEXT,
    'Monto: ' || TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0), 'FM999,999,990.00') AS CARD_SUBTEXT,
    'fa-check-circle' AS CARD_ICON, 'u-color-5' AS CARD_COLOR, 2 AS order_col
FROM BaseData WHERE CodigoEstadoActual = 'CRD'
UNION ALL
SELECT
    'Efectividad (Mes de Prueba)' AS CARD_TITLE, -- Título ajustado para claridad
    CASE
        WHEN CantidadPreaprobados = 0 THEN '0.00%'
        ELSE TO_CHAR(ROUND((CantidadDesembolsados / CantidadPreaprobados) * 100, 2), 'FM990.00') || '%'
    END AS CARD_TEXT,
    'Des: ' || CantidadDesembolsados || ' / Pre: ' || CantidadPreaprobados AS CARD_SUBTEXT,
    'fa-percent' AS CARD_ICON, 'u-color-10' AS CARD_COLOR, 3 AS order_col
FROM EfectividadData
UNION ALL
SELECT
    'Desembolsado Digital' AS CARD_TITLE, TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)) AS CARD_TEXT,
    'Monto: ' || TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0), 'FM999,999,990.00') AS CARD_SUBTEXT,
    'fa-mobile-alt' AS CARD_ICON, 'u-color-15' AS CARD_COLOR, 4 AS order_col
FROM BaseData WHERE CodigoEstadoActual = 'CRD' AND CanalDesembolsoDeterminado = 'Digital (con firma)'
UNION ALL
SELECT
    'Desembolsado Sucursal' AS CARD_TITLE, TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)) AS CARD_TEXT,
    'Monto: ' || TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0), 'FM999,999,990.00') AS CARD_SUBTEXT,
    'fa-building' AS CARD_ICON, 'u-color-16' AS CARD_COLOR, 5 AS order_col
FROM BaseData WHERE CodigoEstadoActual = 'CRD' AND CanalDesembolsoDeterminado = 'Sucursal (tradicional)'
UNION ALL
SELECT
    E.DES_ESTADO AS CARD_TITLE, TO_CHAR(NVL(AFS.Cantidad, 0)) AS CARD_TEXT,
    'Monto Preap: ' || TO_CHAR(NVL(AFS.MontoTotalPreaprobado, 0), 'FM999,999,990.00') AS CARD_SUBTEXT,
    NVL(E.ICONO, 'fa-exclamation-triangle') AS CARD_ICON, NVL(E.COLOR, 'u-color-2') AS CARD_COLOR,
    100 + NVL(E.ORDEN, 99) AS order_col
FROM PR.PR_ESTADOS_REPRESTAMO E
LEFT JOIN (
    SELECT BD.CodigoEstadoActual, COUNT(DISTINCT BD.ID_REPRESTAMO) AS Cantidad, NVL(SUM(BD.MTO_PREAPROBADO), 0) AS MontoTotalPreaprobado
    FROM BaseData BD
    WHERE BD.CodigoEstadoActual IN ('AN', 'LV', 'CC', 'CRN')
    GROUP BY BD.CodigoEstadoActual
) AFS ON E.CODIGO_ESTADO = AFS.CodigoEstadoActual
WHERE E.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo()
  AND E.CODIGO_ESTADO IN ('AN', 'LV', 'CC', 'CRN')
ORDER BY order_col;