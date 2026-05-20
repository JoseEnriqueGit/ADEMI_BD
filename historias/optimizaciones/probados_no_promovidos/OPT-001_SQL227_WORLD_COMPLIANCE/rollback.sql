-- ============================================================
-- OPT-001 | ROLLBACK | PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE
-- Entorno: QA | Fecha: 2026-03-18
--
-- INSTRUCCIONES:
-- 1. Abrir Toad conectado a QA, schema PR
-- 2. Abrir el body de PR_PKG_REPRESTAMOS
-- 3. Buscar el procedure PVALIDA_WORLD_COMPLIANCE
-- 4. Reemplazar el cursor CARGAR_WORLD_COMPLIANCE (lineas 3741-3749)
--    con la version BEFORE de abajo
-- 5. Reemplazar el loop (lineas 3829-3860) con la version BEFORE
-- 6. Compilar el body
--
-- Alternativa: git revert ac552c5
-- ============================================================

-- === REEMPLAZAR CURSOR (lineas 3741-3749) CON ESTO: ===

/*
CURSOR CARGAR_WORLD_COMPLIANCE IS
 SELECT R.ID_REPRESTAMO, R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
 FROM PR_REPRESTAMOS R
 LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE
 LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
 LEFT JOIN CLIENTES_B2000 B ON B.CODIGO_CLIENTE = R.CODIGO_CLIENTE
 WHERE R.ESTADO = 'RE'
 AND WORLD_COMPLIANCE IS NULL
 AND ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));
*/


-- === REEMPLAZAR LOOP (lineas 3829-3860) CON ESTO: ===

/*
FOR i IN 1..vCantidad_Procesar LOOP
  FOR A IN CARGAR_WORLD_COMPLIANCE LOOP
      BEGIN
      PR.PR_PKG_REPRESTAMOS.OBT_WORLD_COMPLIANCE ( REPLACE(A.NUMERO_IDENTIFICACION,'-'), UTL_URL.ESCAPE(a.PRIMER_NOMBRE), UTL_URL.ESCAPE(a.PRIMER_APELLIDO), VALOR, PMENSAJE );
      IF VALOR IS NULL THEN
         VALOR := 0;
      END IF;
       DBMS_OUTPUT.PUT_LINE ( 'WORLD_COMPLIANCE ' || VALOR || ' id ' ||a.id_represtamo );
       UPDATE PR.PR_SOLICITUD_REPRESTAMO SET WORLD_COMPLIANCE = VALOR WHERE ID_REPRESTAMO = A.ID_REPRESTAMO ;
       COMMIT;
       EXCEPTION WHEN OTHERS THEN
           DECLARE
               vIdError      PLS_INTEGER := 0;
           BEGIN
             setError(pProgramUnit => 'OBT_WORLD_COMPLIANCE',
                      pPieceCodeName => NULL,
                      pErrorDescription => SQLERRM ,
                      pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                      pEmailNotification => NULL,
                      pParamList => IA.LOGGER.vPARAMLIST,
                      pOutputLogger => FALSE,
                      pExecutionTime => NULL,
                      pIdError => vIdError);
           END;
      END;
    END LOOP ;

END LOOP ;
*/
