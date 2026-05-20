-- ============================================================
-- OPT-004 AFTER: UPDATE set-based en Actualiza_Precalificacion
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- ============================================================

-- Sin cursor ni FOR loop. 2 UPDATEs directos + 1 COMMIT.

-- UPDATE 1: Actualizar monto credito actual para TODOS los 'RE' de una vez
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado
                              FROM PA.PA_DETALLADO_DE08 D
                             WHERE D.FUENTE         = 'PR'
                               AND D.NO_CREDITO     = R.NO_CREDITO
                               AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
                               AND D.FECHA_CORTE    = (SELECT MAX(P.FECHA_CORTE)
                                                         FROM PA_DETALLADO_DE08 P
                                                        WHERE P.FUENTE         = 'PR'
                                                          AND P.NO_CREDITO     = R.NO_CREDITO
                                                          AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE))
WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
  AND R.ESTADO = 'RE';

-- UPDATE 2: Marcar como RSB los que no cumplen clasificacion SIB
UPDATE PR_REPRESTAMOS R
SET R.ESTADO = 'RSB'
WHERE R.ESTADO = 'RE'
  AND EXISTS (SELECT 1
                FROM PA_DETALLADO_DE08 D
               WHERE D.NO_CREDITO = R.NO_CREDITO
                 AND D.CALIFICA_CLIENTE NOT IN (SELECT COLUMN_VALUE
                                                  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB')))
                 AND D.fecha_corte = v_fecha_corte);

COMMIT;
