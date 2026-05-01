-- OPT-004: Indice de soporte para UPDATE set-based de clasificacion SIB
-- Evidencia: Explain Plan UPDATE 2 con indice: cost 12,149 -> 71
-- IMPORTANTE: El beneficio real requiere que el paquete PR_PKG_REPRESTAMOS tenga los
--             cambios de codigo de OPT-004 (UPDATE set-based). Si PROD aun usa el loop
--             row-by-row, este indice ocupa espacio sin beneficio observable.
-- Tablespace: PA_IDX (estandar ADEMI, indices fuera de tablespace DATA)
CREATE INDEX PA.IDX_DE08_NOCRED_CALIF_FECHA
ON PA.PA_DETALLADO_DE08 (NO_CREDITO, FECHA_CORTE, CALIFICA_CLIENTE)
TABLESPACE PA_IDX;
