-- OPT-009: Indice para F_Obtener_Nuevo_Credito (lookup por NO_CREDITO)
-- Medicion real (OPT-014) incluida en reduccion -41% tiempo total del job de cancelado
-- Sin TABLESPACE declarado para seguir el patron del indice original en este objeto
-- (ajustar a PR_IDX si DBA lo requiere explicito).
CREATE INDEX PR.IDX_CREDITOS_HI_NOCREDITO
ON PR.PR_CREDITOS_HI (NO_CREDITO)
TABLESPACE PR_IDX;
