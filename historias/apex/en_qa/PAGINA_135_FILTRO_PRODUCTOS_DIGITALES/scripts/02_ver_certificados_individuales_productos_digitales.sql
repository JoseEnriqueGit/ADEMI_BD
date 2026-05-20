/*
  Historia: Pagina 135 APEX - filtro de productos digitales
  Objetivo: ver individualmente los certificados existentes para los productos
            digitales usados por la pagina 135.

  Nota:
  - Esta consulta no usa GROUP BY porque el objetivo es ver cada certificado.
  - TOTAL_POR_PRODUCTO muestra el total de certificados del producto sin agrupar
    el resultado.
*/

SELECT
    cd.COD_EMPRESA,
    cd.COD_PRODUCTO,
    COUNT(*) OVER (PARTITION BY cd.COD_PRODUCTO) AS TOTAL_POR_PRODUCTO,
    cd.NUM_CERTIFICADO,
    cd.CLIENTE,
    cd.ESTADO,
    cd.COD_MONEDA,
    cd.MONTO,
    cd.FEC_EMISION,
    cd.FEC_VENCIMIENTO
FROM CD.CD_CERTIFICADO cd
WHERE cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)
ORDER BY
    cd.COD_PRODUCTO,
    cd.NUM_CERTIFICADO;
    
SELECT
    cd.COD_EMPRESA,
    cd.COD_PRODUCTO,
    COUNT(*) OVER (PARTITION BY cd.COD_PRODUCTO) AS TOTAL_POR_PRODUCTO,
    cd.NUM_CERTIFICADO,
    cd.CLIENTE,
    cd.ESTADO,
    cd.COD_MONEDA,
    cd.MONTO,
    cd.FEC_EMISION,
    cd.FEC_VENCIMIENTO
FROM CD.CD_CERTIFICADO cd
WHERE cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')
  AND cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)
ORDER BY
    cd.COD_PRODUCTO,
    cd.NUM_CERTIFICADO;
