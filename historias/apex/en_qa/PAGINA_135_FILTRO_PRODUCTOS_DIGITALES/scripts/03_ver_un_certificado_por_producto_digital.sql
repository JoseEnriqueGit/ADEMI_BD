/*
  Historia: Pagina 135 APEX - filtro de productos digitales
  Objetivo: mostrar un certificado de ejemplo por cada producto digital.

  Criterio usado:
  - Se toma el certificado mas reciente por FEC_EMISION para cada COD_PRODUCTO.
  - Si un producto no tiene certificados, aparece con EXISTE_CERTIFICADO = 'NO'.
*/

WITH productos_digitales AS (
    SELECT 310 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 311 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 313 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 314 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 315 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 316 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 317 AS COD_PRODUCTO FROM DUAL UNION ALL
    SELECT 318 AS COD_PRODUCTO FROM DUAL
),
certificados AS (
    SELECT
        cd.COD_EMPRESA,
        cd.COD_PRODUCTO,
        cd.NUM_CERTIFICADO,
        cd.CLIENTE,
        cd.ESTADO,
        cd.COD_MONEDA,
        cd.MONTO,
        cd.FEC_EMISION,
        cd.FEC_VENCIMIENTO,
        ROW_NUMBER() OVER (
            PARTITION BY cd.COD_PRODUCTO
            ORDER BY
                cd.FEC_EMISION DESC NULLS LAST,
                cd.NUM_CERTIFICADO DESC
        ) AS RN
    FROM CD.CD_CERTIFICADO cd
    WHERE cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')
      AND cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)
)
SELECT
    p.COD_PRODUCTO,
    CASE
        WHEN c.NUM_CERTIFICADO IS NOT NULL THEN 'SI'
        ELSE 'NO'
    END AS EXISTE_CERTIFICADO,
    c.COD_EMPRESA,
    c.NUM_CERTIFICADO,
    c.CLIENTE,
    c.ESTADO,
    c.COD_MONEDA,
    c.MONTO,
    c.FEC_EMISION,
    c.FEC_VENCIMIENTO
FROM productos_digitales p
LEFT JOIN certificados c
    ON c.COD_PRODUCTO = p.COD_PRODUCTO
   AND c.RN = 1
ORDER BY
    p.COD_PRODUCTO;
