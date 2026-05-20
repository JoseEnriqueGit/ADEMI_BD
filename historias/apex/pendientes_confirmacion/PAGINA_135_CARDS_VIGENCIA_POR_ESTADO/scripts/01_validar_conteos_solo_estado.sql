-- Validacion: conteos de certificados vigentes / vencidos por ESTADO (sin FEC_VENCIMIENTO)
-- Pagina 135 APEX - Cambio 2026-05-08
-- Comparar resultados contra las cards "Certificados Vigentes" y "Certificados Vencidos".

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
    'Total Certificados Abiertos' AS METRICA,
    COUNT(*)                       AS VALOR
FROM CertificadosBase
UNION ALL
SELECT
    'Certificados Vigentes (ESTADO A,R)',
    COUNT(*)
FROM CertificadosBase
WHERE ESTADO IN ('A', 'R')
UNION ALL
SELECT
    'Certificados Vencidos (ESTADO C,P,N,I)',
    COUNT(*)
FROM CertificadosBase
WHERE ESTADO IN ('C', 'P', 'N', 'I')
UNION ALL
SELECT
    'Sin clasificar (otros ESTADO)',
    COUNT(*)
FROM CertificadosBase
WHERE ESTADO NOT IN ('A', 'R', 'C', 'P', 'N', 'I')
   OR ESTADO IS NULL
ORDER BY 1;
