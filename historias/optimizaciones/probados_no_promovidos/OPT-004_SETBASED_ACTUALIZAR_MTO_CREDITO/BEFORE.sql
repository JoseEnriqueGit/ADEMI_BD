-- ============================================================
-- OPT-004 BEFORE: Loop row-by-row en Actualiza_Precalificacion
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- ============================================================

-- Cursor que selecciona todos los represtamos en estado 'RE'
CURSOR Actualizar_Mto_Credito_Actual IS
SELECT R.ID_REPRESTAMO, NO_CREDITO, CODIGO_CLIENTE
    FROM PR.PR_REPRESTAMOS R
 WHERE ESTADO = 'RE';

-- FOR loop: 2 UPDATEs por cada fila
FOR y in Actualizar_Mto_Credito_Actual LOOP

    -- UPDATE 1: Actualizar monto credito actual con subquery correlacionada
    UPDATE PR.PR_REPRESTAMOS R SET R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                      FROM  PA.PA_DETALLADO_DE08 D
                                     WHERE  D.FUENTE           = 'PR'
                                        AND D.NO_CREDITO       = y.NO_CREDITO
                                        AND D.CODIGO_CLIENTE   = y.CODIGO_CLIENTE
                                        AND D.FECHA_CORTE   = ( SELECT MAX(P.FECHA_CORTE)
                                                                   FROM PA_DETALLADO_DE08 P
                                                                  WHERE P.FUENTE       = 'PR'
                                                                    AND P.NO_CREDITO   = y.NO_CREDITO
                                                                    AND P.CODIGO_CLIENTE = y.CODIGO_CLIENTE))
      WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND R.CODIGO_CLIENTE = y.CODIGO_CLIENTE
        AND R.NO_CREDITO     = y.NO_CREDITO
        AND R.ESTADO         = 'RE';

    -- UPDATE 2: Marcar como RSB si no cumple clasificacion
    UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO
            FROM PA_DETALLADO_DE08
            WHERE NO_CREDITO = y.NO_CREDITO
            AND CALIFICA_CLIENTE NOT IN (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB')))
            AND fecha_corte = v_fecha_corte);

END LOOP;
COMMIT;
