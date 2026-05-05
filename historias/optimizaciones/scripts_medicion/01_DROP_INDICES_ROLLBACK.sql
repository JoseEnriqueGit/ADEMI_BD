-- =====================================================================
-- ROLLBACK: Eliminar indices de OPT-002, 004, 009, 010, 011, 013
-- Ejecutar ANTES de medir el baseline (rendimiento sin optimizaciones)
-- IMPORTANTE: Guardar este script para restaurar despues
-- =====================================================================

-- OPT-002: Indice covering CUR_DE08_SIB (cost 64,753 -> 39)
DROP INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR;

-- OPT-004: Indice de soporte para UPDATE set-based de clasificacion SIB
DROP INDEX PA.IDX_DE08_NOCRED_CALIF_FECHA;

-- OPT-009: Indice para F_Obtener_Nuevo_Credito (cost 17,232 -> 909)
DROP INDEX PR.IDX_CREDITOS_HI_NOCREDITO;

-- OPT-010 / OPT-015: Indice de soporte para validacion inline de garantias
DROP INDEX PR.IDX_GARANTIAS_TIPO_SB;

-- OPT-011: Indice covering CUR_Anular_creditos_cancelados (cost 10,656 -> 9,748)
DROP INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED;

-- OPT-013: Indice covering CUR_DE05_SIB (cost 120,122 -> 11)
DROP INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA;

-- Verificar que se eliminaron:
SELECT INDEX_NAME, TABLE_NAME, TABLE_OWNER
FROM ALL_INDEXES
WHERE INDEX_NAME IN (
    'IDX_DE08_SIB_FECHA_DEUDOR',
    'IDX_DE08_NOCRED_CALIF_FECHA',
    'IDX_CREDITOS_HI_NOCREDITO',
    'IDX_GARANTIAS_TIPO_SB',
    'IDX_REPRESTAMOS_EMP_EST_NOCRED',
    'IDX_DE05_SIB_CASTIGO_CEDULA'
);
-- Debe retornar 0 filas
