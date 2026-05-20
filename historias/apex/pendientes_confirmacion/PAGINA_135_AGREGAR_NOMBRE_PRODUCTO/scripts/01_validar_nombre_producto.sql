-- Validacion: cobertura de DESCRIPCION en PA.PRODUCTOS para los productos digitales
-- Pagina 135 APEX - Cambio 2026-05-08
-- Confirma que cada COD_PRODUCTO digital tiene un nombre asociado en PA.PRODUCTOS
-- y reporta cuantos certificados existen por producto.

-- Reemplazar antes de ejecutar:
--   :P_COD_EMPRESA -> codigo empresa (default '1')

SELECT
    cd.COD_PRODUCTO,
    NVL(prod.DESCRIPCION, '<<SIN DESCRIPCION EN PA.PRODUCTOS>>') AS DESCRIPCION,
    COUNT(*) AS CANTIDAD_CERTIFICADOS
FROM CD.CD_CERTIFICADO cd
LEFT JOIN PA.PRODUCTOS prod
    ON cd.COD_PRODUCTO = prod.COD_PRODUCTO
   AND cd.COD_EMPRESA = prod.COD_EMPRESA
WHERE cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')
  AND cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)
GROUP BY
    cd.COD_PRODUCTO,
    prod.DESCRIPCION
ORDER BY
    cd.COD_PRODUCTO;
