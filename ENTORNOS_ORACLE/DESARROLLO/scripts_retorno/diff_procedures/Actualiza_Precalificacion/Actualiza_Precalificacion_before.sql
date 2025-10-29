-- PROCEDURE Actualiza_Precalificacion (before)
   PROCEDURE Actualiza_Precalificacion  IS 
    -- QUERY DE LOS CREDITOS PRECALIFICADOS

    CURSOR Actualizar_Mto_Credito_Actual IS
    SELECT R.ID_REPRESTAMO,NO_CREDITO,CODIGO_CLIENTE 
        FROM PR.PR_REPRESTAMOS R 
     WHERE ESTADO = 'RE';
    
       CURSOR PRECALIFICADOS IS
               SELECT a.rowid id, 
                     a.id_represtamo,
                    a.CODIGO_CLIENTE,
                    a.DIAS_ATRASO,
                    P.CODIGO_REPRESTAMO,
                    a.mto_credito_Actual, 
                    p.factor, 
                    a.mto_credito_Actual*P.FACTOR  mto_preaprobado,
                    A.NO_CREDITO
               FROM PR.PR_REPRESTAMOS a,
                    PR.PR_CODIGOS_REPRESTAMO P
              WHERE a.codigo_empresa = vCodigoEmpresa
                AND A.ID_REPRESTAMO= A.ID_REPRESTAMO+0
                AND a.ESTADO ='RE' 
                --AND a.DIAS_ATRASO BETWEEN P.DESDE AND P.HASTA
                AND P.CODIGO_EMPRESA   = a.CODIGO_EMPRESA;
       --
      -- Cursor para la validaci¿n de la super con respecto a la clasificaci¿n del cliente a nivel interbancario                       
         CURSOR CUR_DE08_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION
             FROM PA_DE08_SIB A,
                  PR_REPRESTAMOS B
             WHERE A.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DE08_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
             AND B.ESTADO = 'RE'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;
                      
          -- Cursor para la validaci¿n de la super con respecto a la clasificaci¿n del cliente a nivel interbancario con Fiador    
        CURSOR CUR_FIADOR IS 
             SELECT B.ROWID ID, b.id_represtamo,B.NO_CREDITO,B.CODIGO_CLIENTE,B.CODIGO_PRECALIFICACION
             FROM PR_REPRESTAMOS B
             WHERE B.ESTADO = 'RE' ;
             
   --Castigados a nivel interbancario
         CURSOR CUR_DE05_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad
             FROM PA_DE05_SIB A,
                     PR_REPRESTAMOS B
             WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
             AND B.ESTADO = 'RE'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';
            
           vClasificaion NUMBER :=0;
           vEstado       VARCHAR2(400);      
           vComentario   VARCHAR2(400);  
           v_fecha_corte DATE;
            --agregue esta variable
           pMensaje      VARCHAR2(100);    
           --Defino la variable para capturar si existe un detalle
            idCabeceraDet NUMBER; 
                       v_fiador_exist NUMBER;
           v_dos_prestamos_cancelados NUMBER;                
   BEGIN 
   
         --VERIFICAR SI EXISTE EL REGISTRO
            /*BEGIN
                SELECT ID_APLICACION_PASO_DET
                INTO idCabeceraDet
                FROM PR.PR_APLICACION_PASO_DET
                WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
                
                DBMS_OUTPUT.PUT_LINE ( 'qUE PASO AQUI = ' || idCabeceraDet );
                
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    --SI NO SE ENCUENTRA NINGUN REGISTRO CREARA UNO NUEVO
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.ACTUALIZA_PRECALIFICACION', 'INICIADO', pMensaje ); 
                        
                        
                     --OBTENER EL ID DEL NUEVO REGISTRO
                     SELECT PR.SEQ_PR_APLICACION_PASO_DET.CURRVAL
                     INTO idCabeceraDet
                     FROM DUAL;  
                     
                     DBMS_OUTPUT.PUT_LINE ( 'idCabeceraDet = ' || idCabeceraDet );
                     
                     --ACTUALIZAR EL PARAMETRO DE ENTRADA CON EL NUEVO ID
                     pIDAPLICACION := idCabeceraDet;
                     
                     DBMS_OUTPUT.PUT_LINE ( 'pIDAPLICACION PARA EL OTRO PASO = ' || pIDAPLICACION );
                     DBMS_OUTPUT.PUT_LINE ('SE CREO EL REGISTRO CON ID: ' || idCabeceraDet);
                                      
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error inesperado al verificar o crear el registro: ' || SQLERRM);
                    RETURN;                     
               END;
            
        --ACTUALIZAR BITACORA SI YA EXISTE
            IF idCabeceraDet IS NOT NULL THEN
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 10, 'EN PROCESO', pMensaje );
            END IF;*/

          -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );                         
      --Actualizo el estado del detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
                     
   --ACTUALIZA EL MONTO CREDITO ACTUAL
          
          FOR y in Actualizar_Mto_Credito_Actual LOOP
             UPDATE PR.PR_REPRESTAMOS R SET  R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.NO_CREDITO       = y.NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = y.CODIGO_CLIENTE
                                                 AND D.FECHA_CORTE   = ( SELECT MAX(P.FECHA_CORTE)   
                                                                                                FROM PA_DETALLADO_DE08 P
                                                                                                WHERE P.FUENTE       = 'PR' 
                                                                                                AND P.NO_CREDITO     = y.NO_CREDITO 
                                                                                                AND P.CODIGO_CLIENTE = y.CODIGO_CLIENTE))
                                                                                                
               WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND R.CODIGO_CLIENTE =   y.CODIGO_CLIENTE
               AND R.NO_CREDITO     =   y.NO_CREDITO 
               AND R.ESTADO         = 'RE';
               
             COMMIT;
       
             UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO 
                     FROM PA_DETALLADO_DE08 
                    WHERE NO_CREDITO = y.NO_CREDITO 
                      AND CALIFICA_CLIENTE  NOT IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
                      AND  fecha_corte = v_fecha_corte);
             
             COMMIT;
      END LOOP;
    
    
      --Cambio el estado del detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
      -- Se actualiza el campo CODIGO_PRECALIFICACION con valor 'NI' y el campo OBSERVACIONES con valor 'NINGUNA PRECALIFICACION' 
      -- para todos lo cr¿ditos en la tabla PR_PRECALIFICADOS con ESTADO diferente a 'P'
      FOR a IN PRECALIFICADOS LOOP
           --IF a.CODIGO_REPRESTAMO != 'NI' THEN
             UPDATE PR_REPRESTAMOS  
                SET codigo_precalificacion = a.CODIGO_REPRESTAMO,
                    mto_preaprobado = a.mto_preaprobado
              WHERE rowid = a.id;
      END LOOP;
           
           
       --Validacion del DE08 FIADOR
       --COMENTADO AQUI
--     FOR a in CUR_FIADOR LOOP
--
--       -- Validar si el cliente tiene un fiador
--        SELECT COUNT(1) INTO v_fiador_exist
--        FROM PR_CREDITOS a1
--            JOIN PR_AVAL_REPRE_X_CREDITO b 
--            ON a1.codigo_empresa = b.codigo_empresa AND a1.no_credito = b.no_credito
--        WHERE a1.codigo_empresa = 1
--          AND a1.no_credito = a.no_credito AND b.codigo_aval_repre != a1.codigo_cliente;
--          
--        -- Validar si el cliente tiene dos préstamos cancelados
--        SELECT COUNT(1) INTO v_dos_prestamos_cancelados
--        FROM (SELECT 1
--                FROM PR_CREDITOS c2
--               WHERE c2.codigo_cliente = a.codigo_cliente
--                 AND c2.estado = 'C'
--               GROUP BY c2.codigo_cliente
--              HAVING COUNT(*) = 2);
--              
--        -- Si cumple con ambos criterios, realiza el UPDATE
--        IF v_fiador_exist > 0 AND v_dos_prestamos_cancelados > 0 AND a.CODIGO_PRECALIFICACION !=  01 THEN
--         vEstado:= 'RSB'; 
--         vComentario:=' RECHAZO: Cliente no muy bueno con FIADOR ';
--         DBMS_OUTPUT.PUT_LINE('Antes de generar bitaciora de '||a.id_represtamo||' a '||vEstado);
--         PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
--         DBMS_OUTPUT.PUT_LINE('Despues de generar bitacora '||a.id_represtamo);
--        END IF;
--       COMMIT; 
--
--          END LOOP;   
          --HASTA AQUI
           
       --Actualizo el estado del detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
      
      /*DELETE PR_REPRESTAMOS 
      WHERE estado = 'RE'  
      AND   CODIGO_PRECALIFICACION IS NULL;*/
    
   
        --Se agrego este codigo sustituyendo el codigo comentado de arriba el cual eliminara los represtamos sin precalificacion.
        -- CAMBIO AQUI
        DECLARE
            CURSOR cur_sin_precalificacion IS
            SELECT
                b.rowid id,
                b.id_represtamo,
                b.codigo_cliente
            FROM
                pr.pr_represtamos b
            WHERE
                b.codigo_precalificacion IS NULL
                AND b.estado = 'RE';
        
            v_result BOOLEAN;
        BEGIN --Cambio el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje ); 
            FOR a IN cur_sin_precalificacion LOOP
                DELETE FROM pr.pr_bitacora_represtamo
                WHERE
                    id_represtamo = a.id_represtamo;
        
                DELETE FROM pr.pr_canales_represtamo
                WHERE
                    id_represtamo = a.id_represtamo;
        
                DELETE FROM pr.pr_represtamos
                WHERE
                    id_represtamo = a.id_represtamo;
        
                --v_result := pa.p_datos_persona.esta_en_lista_ofac('1', a.codigo_cliente);
--                IF v_result THEN
--                    DELETE FROM pr.pr_bitacora_represtamo
--                    WHERE
--                        id_represtamo = a.id_represtamo;
--        
--                    DELETE FROM pr.pr_canales_represtamo
--                    WHERE
--                        id_represtamo = a.id_represtamo;
--        
--                    DELETE FROM pr.pr_represtamos
--                    WHERE
--                        id_represtamo = a.id_represtamo;
--        
--                    dbms_output.put_line('La persona está en la lista OFAC.' || a.codigo_cliente);
--                ELSE
--                    dbms_output.put_line('La persona no está en la lista OFAC.' || a.codigo_cliente);
--                END IF;
        
            END LOOP;
        
            COMMIT;
        END;
        --HASTA AQUI
      --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
       
      FOR a in CUR_DE08_SIB LOOP

             SELECT COUNT (1) INTO vClasificaion FROM ( WITH CLASIFICACIONES AS (SELECT VALOR FROM PA.PA_PARAMETROS_MVP where CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CLASIFICACION_SIB')
             SELECT regexp_substr (VALOR,'[^,]+',1,level) CLASIFICACION FROM  CLASIFICACIONES  connect by level <=length(VALOR) - length(replace( VALOR,','))+1 )T1 
             WHERE T1.CLASIFICACION = a.clasificacion ;
            
             vEstado:= 'CLS'; 
             vComentario:= a.clasificacion;
        --Cambio el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje ); 
            
            /*IF vClasificaion  = 1 THEN
             vEstado:= 'CLS'; 
             vComentario:= a.clasificacion;
            ELSE
              vEstado:= 'RSB'; 
              vComentario:= 'RECHAZO: Cliente en clasificacion: '||a.clasificacion;
            END IF;*/
               DBMS_OUTPUT.PUT_LINE('Antes de generar bitaciora de '||a.id_represtamo||' a '||vEstado);
              PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
               --DBMS_OUTPUT.PUT_LINE('Despues de generar bitacora '||a.id_represtamo);
          END LOOP; 
          
         
      
        
        

      --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );     
      FOR a in CUR_DE05_SIB LOOP
           PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,'RCS',NULL,'RECHAZO: Cedula: '||a.cedula||' con castigo en '||a.entidad, USER);
       END LOOP;
       
        --Actualizo el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        
       --Finalizo el detalle
       --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO', pMensaje );
      COMMIT;
      

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
        
        pMensaje:='ERROR CON EL STORE PROCEDURE ACTUALIZA_PRECALIFICACION';
        
          setError(pProgramUnit => 'Actualiza_Precalificacion', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
                   
           --Capturo el error del detalle
           --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ERROR', 100, SQLERRM,pMensaje );
        
           
        END;   
        
       
                      
        
    END Actualiza_Precalificacion;
