-- Validacion: montos vigentes y cancelados por ESTADO y moneda (sin FEC_VENCIMIENTO)
-- Pagina 135 APEX - Cambio 2026-05-08
-- Comparar contra las cards "Monto en Pesos", "Monto en Dolares",
-- "Monto Cancelados (Pesos)" y "Monto Cancelados (Dolares)".

-- Reemplazar antes de ejecutar:
--   :P_COD_EMPRESA       -> codigo empresa (default '1')
--   :P135_FROM_DATE      -> rango fecha emision (DD-MM-YYYY)
--   :P135_TO_DATE
--   :P135_FROM_CANC      -> rango fecha vencimiento (DD-MM-YYYY)
--   :P135_TO_CANC
--   :P135_LOGICA_FECHA   -> 'AND' o 'OR'

WITH CertificadosBase AS (
    SELECT cd.NUM_CERTIFICADO, cd.ESTADO, cd.COD_MONEDA, cd.MONTO
    FROM CD.CD_CERTIFICADO cd
    WHERE cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')
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
)
SELECT
    'Monto en Pesos (vigente)' AS METRICA,
    COUNT(*)                    AS CANTIDAD,
    NVL(SUM(MONTO), 0)          AS MONTO_TOTAL
FROM CertificadosBase
WHERE COD_MONEDA = '1' AND ESTADO IN ('A', 'R')
UNION ALL
SELECT
    'Monto en Dolares (vigente)',
    COUNT(*),
    NVL(SUM(MONTO), 0)
FROM CertificadosBase
WHERE COD_MONEDA = '2' AND ESTADO IN ('A', 'R')
UNION ALL
SELECT
    'Monto Cancelados (Pesos)',
    COUNT(*),
    NVL(SUM(MONTO), 0)
FROM CertificadosBase
WHERE COD_MONEDA = '1' AND ESTADO IN ('C', 'P', 'N', 'I')
UNION ALL
SELECT
    'Monto Cancelados (Dolares)',
    COUNT(*),
    NVL(SUM(MONTO), 0)
FROM CertificadosBase
WHERE COD_MONEDA = '2' AND ESTADO IN ('C', 'P', 'N', 'I')
ORDER BY METRICA;
