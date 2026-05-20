-- ============================================================
-- OPT-003 AFTER: COMMITs movidos fuera de loops en Actualiza_Precalificacion
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- ============================================================

-- LOOP 1: Actualizar_Mto_Credito_Actual
-- COMMITs eliminados del loop, un solo COMMIT despues del END LOOP
FOR y in Actualizar_Mto_Credito_Actual LOOP
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

    UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO
            FROM PA_DETALLADO_DE08
            WHERE NO_CREDITO = y.NO_CREDITO
            AND CALIFICA_CLIENTE NOT IN (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB')))
            AND fecha_corte = v_fecha_corte);
END LOOP;
COMMIT;     -- <<< Un solo COMMIT para todo el loop


-- LOOP 2: PRECALIFICADOS
-- COMMIT movido fuera del loop
FOR a IN PRECALIFICADOS LOOP
    UPDATE PR_REPRESTAMOS
       SET codigo_precalificacion = a.CODIGO_REPRESTAMO,
           mto_preaprobado = a.mto_preaprobado
     WHERE rowid = a.id;
END LOOP;
COMMIT;     -- <<< Un solo COMMIT para todo el loop


-- LOOP 3: CUR_FIADOR
-- COMMIT movido fuera del loop
FOR a in CUR_FIADOR LOOP
    SELECT COUNT(1) INTO v_fiador_exist ...;
    SELECT COUNT(1) INTO v_dos_prestamos_cancelados ...;

    IF v_fiador_exist > 0 AND v_dos_prestamos_cancelados > 0 AND a.CODIGO_PRECALIFICACION != 01 THEN
        vEstado:= 'RSB';
        vComentario:=' RECHAZO: Cliente no muy bueno con FIADOR ';
        PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
    END IF;
END LOOP;
COMMIT;     -- <<< Un solo COMMIT para todo el loop
