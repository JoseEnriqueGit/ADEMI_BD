-- ============================================================
-- OPT-005 BEFORE: Procedure Actualiza_XCORE_CUSTOM original
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Linea ~3309
-- ============================================================
-- Problema: Loop doble (FOR i IN 1..vCantidad_Procesar / FOR A IN CUR_UPDATE_XCORE)
-- con xcore hardcodeado (la llamada a DataCredito esta comentada)
-- y COMMIT por cada fila individual.
-- ============================================================

PROCEDURE Actualiza_XCORE_CUSTOM IS
--Represtamos En estado RE sin xcore ademi
      CURSOR VALIDACION_CLASIFICACION IS
      SELECT R.ID_REPRESTAMO FROM PR_REPRESTAMOS R
      WHERE  R.ESTADO = 'RE'
      AND NOT EXISTS( SELECT CODIGO_ESTADO FROM PR_BITACORA_REPRESTAMO WHERE CODIGO_ESTADO = 'CLS' AND ID_REPRESTAMO = R.ID_REPRESTAMO );

      CURSOR CUR_UPDATE_XCORE IS
      SELECT A.ROWID ID,A.ID_REPRESTAMO, A.CODIGO_CLIENTE,A.ESTADO,A.XCORE_GLOBAL
      FROM PR.PR_REPRESTAMOS A
      WHERE A.ESTADO = 'RE' AND XCORE_GLOBAL IS NULL AND ROWNUM<= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE'));

      CURSOR CUR_UPDATE_CREADOS IS
      SELECT A.ROWID ID,A.ID_REPRESTAMO, A.CODIGO_CLIENTE,A.ESTADO,A.XCORE_GLOBAL
      FROM PR.PR_REPRESTAMOS A
      WHERE A.ESTADO = 'RE';


      vTotal_Carga NUMBER(10);
      vCantidad_Procesar NUMBER(10);
      Vlote_Proceso_Xcore NUMBER(10);
       --agregue esta variable
          pMensaje      VARCHAR2(100);
      --Defino la variable para capturar si existe un detalle
        --idCabeceraDet NUMBER;
      xcore NUMBER(30);
  BEGIN

  --VERIFICAR SI EXISTE EL REGISTRO
           /*BEGIN
               SELECT ID_APLICACION_PASO_DET
               INTO idCabeceraDet
               FROM PR.PR_APLICACION_PASO_DET
               WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
               ...
           END;*/


   Vlote_Proceso_Xcore := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE'));
              BEGIN
               SELECT COUNT(*) INTO vTotal_Carga FROM PR.PR_REPRESTAMOS A WHERE A.ESTADO = 'RE';
               EXCEPTION WHEN NO_DATA_FOUND THEN
                vTotal_Carga:= 0;
                DBMS_OUTPUT.PUT_LINE ( 'vTotal_Carga = ' || vTotal_Carga );
                   COMMIT;
             END;

        vCantidad_Procesar :=  round(vTotal_Carga / Vlote_Proceso_Xcore) + 1  ;

      /*FOR A IN VALIDACION_CLASIFICACION LOOP
        PR_PKG_REPRESTAMOS.p_generar_bitacora(a.ID_REPRESTAMO,NULL,'RSB',NULL,'Cliente sin clasificacion', USER);
      END LOOP;*/

      FOR i IN 1..vCantidad_Procesar LOOP
       FOR A IN CUR_UPDATE_XCORE LOOP

          BEGIN
              xcore := 750;--NVL(TRIM(JSON_VALUE( PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON(...))), 0);
              IF xcore IS NULL THEN
                   xcore := 0;
              END IF;

             EXCEPTION WHEN OTHERS THEN
               DECLARE
                   vIdError      PLS_INTEGER := 0;
               BEGIN
                 pMensaje:='ERROR CON EL STORE PROCEDURE ACTUALIZA_XCORE_CUSTOM';
                 setError(pProgramUnit => 'Actualiza_XCORE_CUSTOM',
                          pPieceCodeName => NULL,
                          pErrorDescription => SQLERRM ,
                          pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                          pEmailNotification => NULL,
                          pParamList => IA.LOGGER.vPARAMLIST,
                          pOutputLogger => FALSE,
                          pExecutionTime => NULL,
                          pIdError => vIdError);
                   xcore := 0;
               END;

                     COMMIT;

            END ;

           DBMS_OUTPUT.PUT_LINE('ENTRO PARA ACTUALIZAR EL XCORE');
            UPDATE PR_REPRESTAMOS
            SET XCORE_GLOBAL = xcore, XCORE_CUSTOM = xcore
            WHERE rowid = a.id;
             COMMIT;
           DBMS_OUTPUT.PUT_LINE('TERMINO DE ACTUALIZAR EL XCORE');
         END LOOP ;

     END LOOP;


          EXCEPTION WHEN OTHERS THEN
               DECLARE
                   vIdError      PLS_INTEGER := 0;
               BEGIN
                 pMensaje:='ERROR CON EL STORE PROCEDURE ACTUALIZA_XCORE_CUSTOM';
                 setError(pProgramUnit => 'Actualiza_XCORE_CUSTOM',
                          pPieceCodeName => NULL,
                          pErrorDescription => SQLERRM ,
                          pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                          pEmailNotification => NULL,
                          pParamList => IA.LOGGER.vPARAMLIST,
                          pOutputLogger => FALSE,
                          pExecutionTime => NULL,
                          pIdError => vIdError);
                          DBMS_OUTPUT.PUT_LINE ( 'DBMS_UTILITY.FORMAT_ERROR_BACKTRACE 2 = ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
              END;


    /* FOR A IN CUR_UPDATE_CREADOS LOOP
          IF NVL(a.XCORE_GLOBAL,0) < TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_XCORE'))  THEN
           PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Credito cancelado por Xcore Ademi', USER);
          END IF;
      END LOOP; */


   END Actualiza_XCORE_CUSTOM;
