-- QA02 - Validacion de estados de PR_CREDITOS usados para filtro de precalifica
WITH estados_objetivo AS (
    SELECT 'D' codigo_estado, 1 orden FROM dual
    UNION ALL
    SELECT 'V', 2 FROM dual
    UNION ALL
    SELECT 'M', 3 FROM dual
    UNION ALL
    SELECT 'J', 4 FROM dual
    UNION ALL
    SELECT 'E', 5 FROM dual
),
conteos_creditos AS (
    SELECT c.estado codigo_estado,
           COUNT(*) cantidad_creditos
      FROM PR.PR_CREDITOS c
     WHERE c.estado IN ('D', 'V', 'M', 'J', 'E')
     GROUP BY c.estado
)
SELECT eo.codigo_estado,
       NVL(ec.abrev_estado, 'NO_EXISTE_EN_CATALOGO') abrev_estado,
       NVL(ec.descripcion_estado, 'NO_EXISTE_EN_CATALOGO') descripcion_estado,
       NVL(cc.cantidad_creditos, 0) cantidad_creditos
  FROM estados_objetivo eo
  LEFT JOIN PR.PR_ESTADOS_CREDITO ec
    ON ec.codigo_estado = eo.codigo_estado
  LEFT JOIN conteos_creditos cc
    ON cc.codigo_estado = eo.codigo_estado
 ORDER BY eo.orden
