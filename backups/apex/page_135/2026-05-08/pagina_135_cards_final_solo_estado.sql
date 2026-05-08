-- Backup APEX pagina 135
-- Region: cards de certificados
-- Estado: FINAL con vigencia evaluada SOLO por ESTADO (sin FEC_VENCIMIENTO < SYSDATE)
-- Fecha: 2026-05-08
-- Cambio respecto a 2026-05-01: vigencia evaluada solo por ESTADO
-- y card "Total Certificados Abiertos" clickeable.
-- Detalle del cambio: ver historias/PAGINA_135_CARDS_VIGENCIA_POR_ESTADO/README.md.

WITH CertificadosBase AS (
    SELECT
        cd.NUM_CERTIFICADO,
        cd.MONTO,
        cd.COD_MONEDA,
        cd.ESTADO,
        cd.FEC_VENCIMIENTO,
        CASE
          WHEN EXISTS (
            SELECT 1
            FROM PA.EMPLEADOS emp
            WHERE emp.COD_PER_FISICA = cd.CLIENTE
              AND emp.COD_EMPRESA = cd.COD_EMPRESA
              AND emp.ESTA_ACTIVO = 'S'
          ) THEN 'Empleado'
          ELSE 'Externo'
        END AS TIPO_CLIENTE
    FROM CD.CD_CERTIFICADO cd
    WHERE cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')

      -- Filtro agregado: solo certificados digitales
      AND cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)

      AND (
          (:P135_LOGICA_FECHA = 'AND'
            AND TRUNC(cd.FEC_EMISION) BETWEEN TO_DATE(:P135_FROM_DATE, 'DD-MM-YYYY')
                                          AND TO_DATE(:P135_TO_DATE, 'DD-MM-YYYY')
            AND NVL(cd.FEC_VENCIMIENTO, TRUNC(SYSDATE) + 365) BETWEEN TO_DATE(:P135_FROM_CANC, 'DD-MM-YYYY')
                                                                  AND TO_DATE(:P135_TO_CANC, 'DD-MM-YYYY')
          )
          OR
          (:P135_LOGICA_FECHA = 'OR'
            AND (
                TRUNC(cd.FEC_EMISION) BETWEEN TO_DATE(:P135_FROM_DATE, 'DD-MM-YYYY')
                                          AND TO_DATE(:P135_TO_DATE, 'DD-MM-YYYY')
                OR
                NVL(cd.FEC_VENCIMIENTO, TRUNC(SYSDATE) + 365) BETWEEN TO_DATE(:P135_FROM_CANC, 'DD-MM-YYYY')
                                                                  AND TO_DATE(:P135_TO_CANC, 'DD-MM-YYYY')
            )
          )
      )
),
CertificadosFiltrados AS (
    SELECT *
    FROM CertificadosBase
    WHERE (
        :P135_FILTRO_CARD IS NULL
        OR :P135_FILTRO_CARD = 'Total Certificados Abiertos'
        OR (:P135_FILTRO_CARD = 'Certificados Vigentes' AND ESTADO IN ('A', 'R'))
        OR (:P135_FILTRO_CARD = 'Certificados Vencidos' AND ESTADO IN ('C', 'P', 'N', 'I'))
        OR (:P135_FILTRO_CARD = 'Clientes Externos' AND TIPO_CLIENTE = 'Externo')
        OR (:P135_FILTRO_CARD = 'Empleados' AND TIPO_CLIENTE = 'Empleado')
        OR :P135_FILTRO_CARD IN (
            'Monto en Pesos',
            'Monto en Dólares',
            'Monto Cancelados (Pesos)',
            'Monto Cancelados (Dólares)'
        )
    )
),
Tarjetas AS (
    -- BLOQUE 1: TOTAL GENERAL
    SELECT
        'Total Certificados Abiertos' AS CARD_TITLE,
        TO_CHAR(COUNT(*), 'FM999,999,999,990') AS CARD_TEXT,
        'Histórico Periodo' AS CARD_SUBTEXT,
        'fa-file-text-o' AS CARD_ICON,
        'u-color-1' AS CARD_COLOR,
        1 AS ORDER_COL,
        'TOTAL' AS VALOR_FILTRO
    FROM CertificadosBase

    UNION ALL

    -- BLOQUE 2: VIGENTES (solo por ESTADO)
    SELECT
        'Certificados Vigentes',
        TO_CHAR(COUNT(*), 'FM999,999,999,990'),
        'Activos o Retenidos',
        'fa-check-circle',
        'u-color-4',
        2 AS ORDER_COL,
        'VIGENTES' AS VALOR_FILTRO
    FROM CertificadosBase
    WHERE ESTADO IN ('A', 'R')

    UNION ALL

    -- BLOQUE 3: VENCIDOS / CERRADOS (solo por ESTADO)
    SELECT
        'Certificados Vencidos',
        TO_CHAR(COUNT(*), 'FM999,999,999,990'),
        'Vencidos, Pagados o Cancelados',
        'fa-times-circle',
        'u-color-21',
        3 AS ORDER_COL,
        'VENCIDOS' AS VALOR_FILTRO
    FROM CertificadosBase
    WHERE ESTADO IN ('C', 'P', 'N', 'I')

    UNION ALL

    -- BLOQUE 4: MONTOS VIGENTES PESOS (solo por ESTADO)
    SELECT
        'Monto en Pesos',
        'RD$ ' || TO_CHAR(NVL(SUM(MONTO), 0), 'FM999,999,999,990.00'),
        'Certificados Vigentes',
        'fa-money',
        'u-color-8',
        4 AS ORDER_COL,
        NULL AS VALOR_FILTRO
    FROM CertificadosFiltrados
    WHERE COD_MONEDA = '1'
      AND ESTADO IN ('A', 'R')

    UNION ALL

    -- BLOQUE 5: MONTOS VIGENTES DOLARES (solo por ESTADO)
    SELECT
        'Monto en Dólares',
        'US$ ' || TO_CHAR(NVL(SUM(MONTO), 0), 'FM999,999,999,990.00'),
        'Certificados Vigentes',
        'fa-usd',
        'u-color-9',
        5 AS ORDER_COL,
        NULL AS VALOR_FILTRO
    FROM CertificadosFiltrados
    WHERE COD_MONEDA = '2'
      AND ESTADO IN ('A', 'R')

    UNION ALL

    -- BLOQUE 6: CLIENTES EXTERNOS
    SELECT
        'Clientes Externos',
        TO_CHAR(COUNT(*), 'FM999,999,999,990'),
        'Cantidad Certificados',
        'fa-users',
        'u-color-6',
        6 AS ORDER_COL,
        'EXTERNOS' AS VALOR_FILTRO
    FROM CertificadosBase
    WHERE TIPO_CLIENTE = 'Externo'

    UNION ALL

    -- BLOQUE 7: EMPLEADOS
    SELECT
        'Empleados',
        TO_CHAR(COUNT(*), 'FM999,999,999,990'),
        'Cantidad Certificados',
        'fa-briefcase',
        'u-color-12',
        7 AS ORDER_COL,
        'EMPLEADOS' AS VALOR_FILTRO
    FROM CertificadosBase
    WHERE TIPO_CLIENTE = 'Empleado'

    UNION ALL

    -- BLOQUE 8: MONTO CANCELADOS PESOS (solo por ESTADO)
    SELECT
        'Monto Cancelados (Pesos)',
        'RD$ ' || TO_CHAR(NVL(SUM(MONTO), 0), 'FM999,999,999,990.00'),
        'Cancelados o Vencidos',
        'fa-ban',
        'u-color-21',
        8 AS ORDER_COL,
        NULL AS VALOR_FILTRO
    FROM CertificadosFiltrados
    WHERE COD_MONEDA = '1'
      AND ESTADO IN ('C', 'P', 'N', 'I')

    UNION ALL

    -- BLOQUE 9: MONTO CANCELADOS DOLARES (solo por ESTADO)
    SELECT
        'Monto Cancelados (Dólares)',
        'US$ ' || TO_CHAR(NVL(SUM(MONTO), 0), 'FM999,999,999,990.00'),
        'Cancelados o Vencidos',
        'fa-ban',
        'u-color-21',
        9 AS ORDER_COL,
        NULL AS VALOR_FILTRO
    FROM CertificadosFiltrados
    WHERE COD_MONEDA = '2'
      AND ESTADO IN ('C', 'P', 'N', 'I')
)
SELECT
    CARD_TITLE,
    CARD_TEXT,
    CARD_SUBTEXT,
    CARD_ICON,
    CARD_COLOR,
    ORDER_COL,
    VALOR_FILTRO,
    CASE
        WHEN VALOR_FILTRO IS NOT NULL THEN 'pointer'
        ELSE 'default'
    END AS CSS_CURSOR
FROM Tarjetas
ORDER BY ORDER_COL;
