-- OPT-002: Covering index para cursor CUR_DE08_SIB
-- Medicion real (OPT-014): paso 4 (Precalifica_Represtamo_fiadores_hi) -79% tiempo
-- Tablespace corregido a PA_IDX por observacion de Directora TI (estandar ADEMI)
CREATE INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR
ON PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION)
TABLESPACE PA_IDX;
