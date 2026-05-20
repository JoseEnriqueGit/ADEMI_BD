-- ============================================================
-- OPT-001 | BEFORE | PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE
-- Entorno: QA | Fecha: 2026-03-18
-- Cursor CARGAR_WORLD_COMPLIANCE y loop de procesamiento
-- Cost del cursor: 18,293 (2 TABLE ACCESS FULL)
-- ============================================================

-- CURSOR ORIGINAL (lineas 3741-3749)
CURSOR CARGAR_WORLD_COMPLIANCE IS
 SELECT R.ID_REPRESTAMO, R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
 FROM PR_REPRESTAMOS R
 LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE                    -- PROBLEMA: conversion implicita TO_NUMBER sobre columna VARCHAR2 indexada
 LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO                  -- PROBLEMA: PK es (CODIGO_EMPRESA, ID_REPRESTAMO), falta primera columna
 LEFT JOIN CLIENTES_B2000 B ON B.CODIGO_CLIENTE = R.CODIGO_CLIENTE
 WHERE R.ESTADO = 'RE'
 AND WORLD_COMPLIANCE IS NULL
 AND ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));


-- LOOP DE PROCESAMIENTO (lineas 3829-3860)
FOR i IN 1..vCantidad_Procesar LOOP
  FOR A IN CARGAR_WORLD_COMPLIANCE LOOP
      BEGIN
      PR.PR_PKG_REPRESTAMOS.OBT_WORLD_COMPLIANCE ( REPLACE(A.NUMERO_IDENTIFICACION,'-'), UTL_URL.ESCAPE(a.PRIMER_NOMBRE), UTL_URL.ESCAPE(a.PRIMER_APELLIDO), VALOR, PMENSAJE );
      IF VALOR IS NULL THEN
         VALOR := 0;
      END IF;
       DBMS_OUTPUT.PUT_LINE ( 'WORLD_COMPLIANCE ' || VALOR || ' id ' ||a.id_represtamo );
       UPDATE PR.PR_SOLICITUD_REPRESTAMO SET WORLD_COMPLIANCE = VALOR WHERE ID_REPRESTAMO = A.ID_REPRESTAMO ;
       COMMIT;                                                                              -- PROBLEMA: COMMIT por cada fila, genera flush de redo log por registro
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
