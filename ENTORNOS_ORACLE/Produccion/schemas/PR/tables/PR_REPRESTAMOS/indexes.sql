-- Indices agregados en el pase 2026-04-23 (ver ENTORNOS_ORACLE/Produccion/CHANGELOG.md)
-- Tabla caliente: ya tenia PK_REPRESTAMOS, IND01, IND02, IND3. Con estos quedan 6 indices.

-- OPT-011: Covering para CUR_Anular_creditos_cancelados
-- Medicion real (OPT-014) incluida en reduccion -41% tiempo total del job de cancelado
CREATE INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED
ON PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)
TABLESPACE PR_IDX;

-- OPT-016: Covering para cursor de P_REGISTRO_SOLICITUD (WHERE ESTADO = 'RE')
-- Evidencia: medicion aislada en DESARROLLO (Buffers 126 -> 3). NO incluido en OPT-014.
-- RIESGO: columna lider ESTADO es baja cardinalidad. El beneficio pleno requiere que
--         el codigo de OPT-016 este en PROD. Monitorear si Oracle lo elige para queries
--         OLTP no previstas (posible regresion de planes existentes).
CREATE INDEX PR.IDX_REPRESTAMOS_ESTADO_COV
ON PR.PR_REPRESTAMOS (ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)
TABLESPACE PR_IDX;
