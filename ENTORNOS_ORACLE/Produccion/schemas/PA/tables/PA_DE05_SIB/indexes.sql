-- OPT-013: Indice covering para CUR_DE05_SIB
-- Medicion real (OPT-014) incluida en reduccion -41% tiempo total del job de cancelado
-- Tablespace corregido a PA_IDX por observacion de Directora TI (estandar ADEMI)
CREATE INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA
ON PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD)
TABLESPACE PA_IDX;
