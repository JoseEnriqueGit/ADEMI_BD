-- OPT-016: Covering para subquery de F_Obtener_Nuevo_Credito
-- Evidencia: medicion aislada en DESARROLLO (Buffers ~5 -> 2, ejecutada por fila del cursor).
-- IMPORTANTE: El beneficio pleno requiere los cambios de codigo de OPT-016 en PROD.
-- Tablespace: PR_IDX (estandar ADEMI, indices fuera de tablespace DATA)
CREATE INDEX PR.IDX_SOLREPRE_IDREPRE_TIPCRED
ON PR.PR_SOLICITUD_REPRESTAMO (ID_REPRESTAMO, TIPO_CREDITO)
TABLESPACE PR_IDX;
