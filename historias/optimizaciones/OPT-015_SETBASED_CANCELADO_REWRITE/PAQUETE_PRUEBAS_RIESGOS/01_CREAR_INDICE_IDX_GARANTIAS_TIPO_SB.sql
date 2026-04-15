-- =============================================================
-- OPT-015: Crear indice requerido (si no existe)
-- Ejecutar SOLO si el indice no existe en el entorno de pruebas
-- =============================================================

-- Verificar si existe:
-- SELECT INDEX_NAME, STATUS FROM ALL_INDEXES
-- WHERE OWNER = 'PR' AND INDEX_NAME = 'IDX_GARANTIAS_TIPO_SB';

-- Si no existe, ejecutar:
CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB
ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
TABLESPACE PR_DAT;
