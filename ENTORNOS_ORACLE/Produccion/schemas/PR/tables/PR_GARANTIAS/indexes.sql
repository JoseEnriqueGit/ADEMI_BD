-- OPT-010 / OPT-015: Indice de soporte para validacion inline de garantias
-- Evidencia: Explain Plan en paquete de pruebas OPT-015
-- IMPORTANTE: El beneficio real requiere los cambios de codigo de OPT-010/OPT-015
--             (inline de F_TIENE_GARANTIA / rewrite set-based de cancelado).
-- Tablespace: PR_IDX (estandar ADEMI, indices fuera de tablespace DATA)
CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB
ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
TABLESPACE PR_IDX;
