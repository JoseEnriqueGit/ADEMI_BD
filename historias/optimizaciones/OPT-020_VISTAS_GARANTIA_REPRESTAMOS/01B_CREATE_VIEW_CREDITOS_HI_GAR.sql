-- =====================================================================
-- OPT-020 - Crear solo PR.V_REPRE_CREDITOS_HI_GAR
--
-- Usar si 01_CREATE_VIEWS.sql no muestra claramente el error de creacion.
-- =====================================================================

PROMPT ================================================================
PROMPT OPT-020 Q01B - Crear vista PR.V_REPRE_CREDITOS_HI_GAR
PROMPT ================================================================

CREATE OR REPLACE VIEW PR.V_REPRE_CREDITOS_HI_GAR AS
SELECT cr.codigo_empresa,
       cr.no_credito,
       COUNT(1) cantidad_garantias
  FROM PR.PR_CREDITOS_HI cr
  JOIN PR.PR_GARANTIAS_X_CREDITO gx
    ON gx.codigo_empresa = cr.codigo_empresa
   AND gx.no_credito = cr.no_credito
  JOIN PR.PR_GARANTIAS g
    ON g.codigo_empresa = gx.codigo_empresa
   AND g.numero_garantia = gx.numero_garantia
 WHERE cr.estado IN ('D', 'V', 'M', 'E', 'J')
   AND g.codigo_tipo_garantia_sb != 'NA'
 GROUP BY cr.codigo_empresa,
          cr.no_credito;

PROMPT ================================================================
PROMPT OPT-020 Q01B - Verificar vista creada
PROMPT ================================================================

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name = 'V_REPRE_CREDITOS_HI_GAR';

PROMPT Debe retornar 1 fila con STATUS = VALID.
