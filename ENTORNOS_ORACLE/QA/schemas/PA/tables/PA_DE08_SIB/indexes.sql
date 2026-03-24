-- OPT-002: Indice creado para eliminar TABLE ACCESS FULL en cursor CUR_DE08_SIB
-- NOTA: En QA fue creado bajo JOOGANDO. Para produccion debe crearse bajo PA.
CREATE INDEX PA.IDX_DE08_SIB_FECHA ON PA.PA_DE08_SIB (FECHA_CORTE)
TABLESPACE PA_DAT;
