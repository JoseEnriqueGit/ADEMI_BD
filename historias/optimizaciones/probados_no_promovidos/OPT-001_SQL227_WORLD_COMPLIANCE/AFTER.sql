-- ============================================================
-- OPT-001 | AFTER | PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE
-- Entorno: QA | Fecha: 2026-03-18
-- Cursor CARGAR_WORLD_COMPLIANCE y loop de procesamiento
-- Cost del cursor: 15 (0 TABLE ACCESS FULL, todo por indice)
-- ============================================================

-- CURSOR OPTIMIZADO (lineas 3741-3749)
CURSOR CARGAR_WORLD_COMPLIANCE IS
 SELECT R.ID_REPRESTAMO, R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
 FROM PR_REPRESTAMOS R
 LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = TO_CHAR(R.CODIGO_CLIENTE)            -- FIX: TO_CHAR sobre el valor, no sobre la columna indexada -> PK_PERSONASFISICAS
 LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND S.ID_REPRESTAMO = R.ID_REPRESTAMO  -- FIX: ambas columnas del PK -> PK_SOLICITUD_REPRESTAMO
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
       EXCEPTION WHEN OTHERS THEN                                                           -- FIX: sin COMMIT aqui, se mueve al final del loop
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
    COMMIT;                                                                                  -- FIX: un solo COMMIT por lote, no por fila

END LOOP ;
