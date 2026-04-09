-- =====================================================================
-- RESTAURAR: Crear indices de OPT-002, 009, 011, 013
-- Ejecutar DESPUES de medir el baseline para restaurar las optimizaciones
-- NOTA: En QA los indices se crearon bajo JOOGANDO, aqui se crean bajo el schema correcto
-- =====================================================================

-- OPT-002: Indice covering CUR_DE08_SIB
CREATE INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR
ON PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION)
TABLESPACE PA_DAT;

-- OPT-009: Indice para F_Obtener_Nuevo_Credito
CREATE INDEX PR.IDX_CREDITOS_HI_NOCREDITO
ON PR.PR_CREDITOS_HI (NO_CREDITO);

-- OPT-011: Indice covering CUR_Anular_creditos_cancelados
CREATE INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED
ON PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)
TABLESPACE PR_DAT;

-- OPT-013: Indice covering CUR_DE05_SIB
CREATE INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA
ON PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD)
TABLESPACE PA_DAT;

-- Verificar que se crearon:
SELECT INDEX_NAME, TABLE_NAME, TABLE_OWNER, STATUS
FROM ALL_INDEXES
WHERE INDEX_NAME IN (
    'IDX_DE08_SIB_FECHA_DEUDOR',
    'IDX_CREDITOS_HI_NOCREDITO',
    'IDX_REPRESTAMOS_EMP_EST_NOCRED',
    'IDX_DE05_SIB_CASTIGO_CEDULA'
);
-- Debe retornar 4 filas con STATUS = VALID
