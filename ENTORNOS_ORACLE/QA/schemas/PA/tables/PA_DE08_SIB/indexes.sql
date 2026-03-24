-- OPT-002: Covering index para cursor CUR_DE08_SIB
-- Incluye FECHA_CORTE, ID_DEUDOR y CLASIFICACION para que Oracle
-- lea todo del indice sin acceder a la tabla (cost 4,142 -> 39)
-- NOTA: En QA fue creado bajo JOOGANDO. Para produccion crear bajo PA.
CREATE INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR ON PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION)
TABLESPACE PA_DAT;
