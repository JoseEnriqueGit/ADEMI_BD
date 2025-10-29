-- PROCEDURE Precalifica_Represtamo (after)
   PROCEDURE Precalifica_Represtamo  IS 
       
       --- => Condicones a tomar en cuenta para la Precalificaci¿n de Cr¿ditos
       -- 1 - Microcreditos Monto Tope RD$ 772,280;       
       -- 2 - Haber pagado al menos 70% capital;    
       -- 3 - Pr¿stamo en categoria A o B   
       -- 4 - No debe ser un Pr¿stamo Reestructurado; ESTADO =>(E)
       --   - Se actualizar¿ el Campo 'ESTADO' con 'X6', y el Campo 'OBSERVACIONES' con 'EL CLIENTE POSEE PRESTAMOS REESTRUCTURADOS', en la Tabla PR_PRECALIFICADOS
       --
       -- 5 - Incluir los tipos de cr¿ditos ('150','152','154','166','176','178','180','187','189','191','203','713','714','751','753','755','773','774','775','776','779','790')
       -- 6 - Excluir cr¿ditos con atraso mayor a 45 d¿as en los ¿ltimos 6 meses (Tomando el atraso m¿ximo en los ¿ltimos 6 meses)
       -- Se actualizar¿ el Campo 'ESTADO' con 'X2', y el Campo 'OBSERVACIONES' con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||v_mayor_45||' DIAS',
       -- en la Tabla PR_PRECALIFICADOS
       --
       -- 7 - Excluir cliente con TC (Tarjetas de Cr¿dito) con d¿as de atraso mayor a 30 d¿as; se actualizar¿ el ESTADO con el valor 'X3';
       --   - el Campo OBSERVACIONES se actualizar¿ con  'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'.
       --
       -- 8 - Excluir cliente que tengas pr¿stamos desembolsados en los ¿ltimos 6 meses;
       --   - Se actualizar¿ el Campo 'ESTADO' con 'X1', y el Campo 'OBSERVACIONES' con 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ¿LTIMOS '||PA.PARAM.PARAMETRO_GENERAL
       --   - ('PRECAL_DESEMBOLSO_PR', 'PR')||' DIAS' en la Tabla PR_PRECALIFICADOS

       CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS    
       select a.codigo_empresa
         CODIGO_EMPRESA, 
         pr_pkg_represtamos.f_genera_secuencia ID_REPRESTAMO,
         a.codigo_cliente, 
         P_FECHA_CORTE FECHA_CORTE,
         a.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         sysdate FECHA_PROCESO, 
         0 PIN,--lpad(PA.PKG_NOTIFICACIONES.GENERAR_PIN_RANDOM(100,999999),6, '0') PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,    --   TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'INTENTOS_IDENT')) INTENTOS_IDENTIFICACION,    ---DEBE INSERTAR ESTE PARAMETRO 
         'N' IND_SOLICITA_AYUDA,
         --0 mto_aprobado,
         b.monto_desembolsado mto_aprobado,
         0 mto_preaprobado,
         null OBSERVACIONES, 
         USER ADICIONADO_POR, 
         sysdate FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         null FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,--NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0) XCORE_GLOBAL,
         NULL XCORE_CUSTOM, --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE_CUSTOM(PA.OBT_IDENTIFICACION_PERSONA( A.codigo_cliente,'1')),0) XCORE_CUSTOM
         NULL ID_CARGA_DIRIGIDA,
         NULL ID_CAMPANA_ESPECIALES,
         'N'  ES_FIADOR
         FROM PR_CREDITOS a,
         pa_detallado_De08 b,
              PR_tipo_credito_REPRESTAMO c 
         WHERE ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO')) and  a.tipo_credito= c.tipo_credito  
         AND (EXISTS (SELECT 1
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)OR NOT EXISTS ( SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq ) )
         AND b.tipo_credito= c.tipo_credito 
         AND  b.fecha_corte =  TO_DATE('19/11/2024', 'DD/MM/YYYY')
         AND  b.no_credito = a.no_credito
         AND  b.fuente = 'PR'
         AND  c.CARGA = 'S'         
         AND  b.dias_atraso <=PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_MORA_MAYOR_PR')
         AND b.CALIFICA_CLIENTE  IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
          
           AND (( b.MTO_BALANCE_CAPITAL / 
                     CASE WHEN b.MONTO_DESEMBOLSADO =0 then
                         b.MONTO_CREDITO
                         else b.MONTO_DESEMBOLSADO END )*100 )<= 100 - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CAPITAL_PAGADO'))
         
         and a.codigo_empresa =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
         and not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                                   AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))))
          AND not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.ESTADO              = 'E')
          -- validación para  solo pesonas físicas                     
          AND exists (SELECT 1 
                      FROM PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA' ))
         -- validación la nacionalidad              
         AND EXISTS ( SELECT 1
                      FROM ID_PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
                      AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO'))))          
         --  se valida que no exista el mismo crédito con un proceso iniciado de représtamo 
         AND not exists (select 1
                                 from pr_represtamos
                                 where codigo_empresa = a.codigo_empresa 
                                 and no_credito =  a.NO_CREDITO
                                 and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_NO_REPROCESO')))
                                 --('RE','VR','NP','SC','CRB','CRS','CRD')
                                 )
         -- Se valida que solo se selecciones creditos que cumplan con el criterio del monto desembolsado se encuentre entre el parámetro
        /* AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )*/
      -- Se valida que sea a una sola firma        
        AND not EXISTS (select 1--a.no_credito---, a.codigo_cliente, b.codigo_aval_repre
                        from PR_CREDITOS a1, 
                            PR_AVAL_REPRE_X_CREDITO b
                        where a1.codigo_empresa = 1
                        and a1.no_credito = a.no_credito
                        and b.codigo_empresa = a1.codigo_empresa
                        and b.no_credito = a1.no_credito
                        and b.codigo_aval_repre != a1.codigo_cliente
                        AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CLIENTES_A_SOLA_FIRMA' ) = 'S')
        -- Se valida que los clientes no tengan no garantes 
        AND   PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0   
        -- Se valida que los clientes no esten en lista PEP
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 0 
        -- Se valida que los clientes no esten en lista NEGRA
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0 
        ;
           
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       --agregue esta variable
       pMensaje      VARCHAR2(100);
       
       --AGREGUE ESTA NUEVA VARIABLE   
       --idCabeceraDet NUMBER;
          
    BEGIN
    
            
            --VERIFICAR SI EXISTE EL REGISTRO
           /* BEGIN
                SELECT ID_APLICACION_PASO_DET
                INTO idCabeceraDet
                FROM PR.PR_APLICACION_PASO_DET
                WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
                
                DBMS_OUTPUT.PUT_LINE ( 'qUE PASO AQUI = ' || idCabeceraDet );
                
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    --SI NO SE ENCUENTRA NINGUN REGISTRO CREARA UNO NUEVO
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRESTAMO', 'INICIADO', pMensaje ); 
                        
                        
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
    
       
       -- Asigna el valor del Par¿metro a la variable correspondioente 
       v_atraso_30 := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC'));
      -- Ejecuto un SELECT INTO de la FECHA_PROCESO en la tabla PR_REPRESTAMOS    
      -- Calculo que la variable v_fecha_froceso + el Par¿metro de Fecha_a_Procesar(Que puede ser 10 d¿as)
      -- Si la Fecha resultante es Mayor al trunc(Sysdate) Ejecuto el Package PR_PKG_PRECALIFICADOS;
      -- de lo contrario ejecuto un Return, para que el Package CDG.P_CARGA_PRESTAMOS termine su Ejecuci¿n.  
          BEGIN
              SELECT P.FECHA_PROCESO
               INTO v_fecha_proceso      
               FROM PR.PR_REPRESTAMOS P
              WHERE P.FECHA_PROCESO IS NOT NULL 
                AND ROWNUM = 1;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              v_fecha_proceso:= TRUNC(SYSDATE)-30;
          END;      
       --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );   
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
       
      
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 30, 'EN PROCESO', pMensaje );
       
       -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
       
       OPEN CREDITOS_PROCESAR(v_fecha_corte); 

        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 40, 'EN PROCESO', pMensaje );
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

         

           -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as
           -- 7 - en los ¿ltimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           -- con el M¿ximo d¿a de atraso en los ¿ltimos 6 meses   
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as en los ¿ltimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                               --  AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';   
         
       
              
            --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );  
       
              
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 d¿as 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizar¿ el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'RE'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
          
            
          --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 60, 'EN PROCESO', pMensaje );
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los ¿ltimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los ¿ltimos 6 meses
          -- Se actualizar¿ el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ¿LTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ¿LTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los ¿ltimos 6 meses
                           AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))));

          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;
       END LOOP;
       
       CLOSE CREDITOS_PROCESAR;
       
       
       --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 70, 'EN PROCESO', pMensaje );
       
       -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Cr¿ditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > 1000--OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 80, 'EN PROCESO', pMensaje );   
        -- Se eliminan los represtamos que tienen creditos mancomunados
        DELETE  PR_REPRESTAMOS --PR_OPCIONES_REPRESTAMO
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND EXISTS (SELECT 1
                                FROM CUENTA_CLIENTE_RELACION
                                WHERE COD_SISTEMA = 'PR'
                                AND NUM_CUENTA = A.NO_CREDITO
                                AND NVL(TIPO_RELACION,'x') = 'O'
                                )
                    ); 
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
                
     DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%';  
      
      --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 100, 'EN PROCESO', pMensaje );
         --Finalizo el proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO',pMensaje );
        
          
      COMMIT;
        -- PR.PR_PKG_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
        pMensaje:='ERROR CON EL STORE PROCEDURE PRECALIFICA_REPRESTAMO';
          setError(pProgramUnit => 'Precalifica_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
                   
        --Si da error actualizo el detalle de la bitacora para capturar el error           
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
        
        END;
        
        
    END Precalifica_Represtamo;

-- PROCEDURE Precalifica_Repre_Cancelado (after)
PROCEDURE Precalifica_Repre_Cancelado IS 
    CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS
         select a.codigo_empresa
         CODIGO_EMPRESA, 
         pr_pkg_represtamos.f_genera_secuencia ID_REPRESTAMO,
         a.codigo_cliente, 
         P_FECHA_CORTE FECHA_CORTE,
         a.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         sysdate FECHA_PROCESO, 
         0 PIN,--lpad(PA.PKG_NOTIFICACIONES.GENERAR_PIN_RANDOM(100,999999),6, '0') PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,    --   TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'INTENTOS_IDENT')) INTENTOS_IDENTIFICACION,    ---DEBE INSERTAR ESTE PARAMETRO 
         'N' IND_SOLICITA_AYUDA,
         0 mto_aprobado,
         --b.monto_desembolsado mto_aprobado,
         0 mto_preaprobado,
         null OBSERVACIONES, 
         USER ADICIONADO_POR, 
         sysdate FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         null FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,--NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0) XCORE_GLOBAL,
         NULL XCORE_CUSTOM, --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE_CUSTOM(PA.OBT_IDENTIFICACION_PERSONA( A.codigo_cliente,'1')),0) XCORE_CUSTOM
         NULL ID_CARGA_DIRIGIDA,
         NULL ID_CAMPANA_ESPECIALES,
         'N'  ES_FIADOR
         FROM PR_CREDITOS a,
         --pa_detallado_De08 b,
              PR_tipo_credito_REPRESTAMO c 
         WHERE ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO')) and  a.tipo_credito= c.tipo_credito  
         AND (EXISTS (SELECT 1
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)OR NOT EXISTS ( SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq ) )
         and A.TIPO_CREDITO = C.TIPO_CREDITO
         and  A.F_CANCELACION= ( SELECT  d.F_CANCELACION
                        FROM PR_CREDITOS d
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(1000) --TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                        AND d.F_CANCELACION <= SYSDATE
                        AND d.NO_CREDITO =   a.NO_CREDITO
                        AND d.ESTADO = 'C'
                        ) 
         AND c.CARGA = 'S'   
         and a.codigo_empresa =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
         and not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                                   AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))))
          AND not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.ESTADO              = 'E')
          -- validación para  solo pesonas físicas                     
          AND exists (SELECT 1 
                      FROM PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA' ))
         -- validación la nacionalidad              
         AND EXISTS ( SELECT 1
                      FROM ID_PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
                      AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO'))))          
         --  se valida que no exista el mismo crédito con un proceso iniciado de représtamo 
         AND not exists (select 1
                                 from pr_represtamos
                                 where codigo_empresa = a.codigo_empresa 
                                 and no_credito =  a.NO_CREDITO
                                 and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_NO_REPROCESO')))
                                 --('RE','VR','NP','SC','CRB','CRS','CRD')
                                 )
         -- Se valida que solo se selecciones creditos que cumplan con el criterio del monto desembolsado se encuentre entre el parámetro
         /*AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )*/
      -- Se valida que sea a una sola firma        
        AND NOT EXISTS (select 1--a.no_credito---, a.codigo_cliente, b.codigo_aval_repre
                        from PR_CREDITOS a1, 
                            PR_AVAL_REPRE_X_CREDITO b
                        where a1.codigo_empresa = 1
                        and a1.no_credito = a.no_credito
                        and b.codigo_empresa = a1.codigo_empresa
                        and b.no_credito = a1.no_credito
                        and b.codigo_aval_repre != a1.codigo_cliente
                        AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CLIENTES_A_SOLA_FIRMA' ) = 'S')
        -- Se valida que los clientes no tengan no garantes 
        AND   PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0   
        -- Se valida que los clientes no esten en lista PEP
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 0 
        -- Se valida que los clientes no esten en lista NEGRA
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0 
        ;
        
                         
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       v_conteo                  NUMBER(10); 
       --agregue esta variable
       pMensaje      VARCHAR2(100);
       --Defino la variable para capturar si existe un detalle
       --idCabeceraDet NUMBER;   
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
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRE_CANCELADO', 'INICIADO', pMensaje ); 
                        
                        
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
    /*
    --Con esto es que realizo la validacion de si realmente existe de lo contrario, se creara el detalle de la bitacora.
            SELECT COUNT(*)
            INTO idCabeceraDet
            FROM PR.PR_APLICACION_PASO_DET
            WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
    
        --Realizo la validacion y dependiendo el resulto hace una accion distinta. 
        IF idCabeceraDet <=0 THEN
        --Creo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRE_CANCELADO', 'INICIADO', pMensaje );
        ELSIF idCabeceraDet >=1 THEN
        --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 10, 'EN PROCESO', pMensaje );
        END IF;*/
        DBMS_OUTPUT.PUT_LINE ( 'entra en el begin' );    
       -- Asigna el valor del Parámetro a la variable correspondioente 
       v_atraso_30 := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC'));
      -- Ejecuto un SELECT INTO de la FECHA_PROCESO en la tabla PR_REPRESTAMOS    
      -- Calculo que la variable v_fecha_froceso + el Parámetro de Fecha_a_Procesar(Que puede ser 10 días)
      -- Si la Fecha resultante es Mayor al trunc(Sysdate) Ejecuto el Package PR_PKG_PRECALIFICADOS;
      -- de lo contrario ejecuto un Return, para que el Package CDG.P_CARGA_PRESTAMOS termine su Ejecución.  
          BEGIN
              SELECT P.FECHA_PROCESO
               INTO v_fecha_proceso      
               FROM PR.PR_REPRESTAMOS P
              WHERE P.FECHA_PROCESO IS NOT NULL 
                AND ROWNUM = 1;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              v_fecha_proceso:= TRUNC(SYSDATE)-30;
          END;      
          --Cambio el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 20, 'EN PROCESO', pMensaje );    
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
       
      
      --Cambio el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );
      
       -- Para obtener la fecha máxima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
       
       
                    
       
       
       OPEN CREDITOS_PROCESAR(v_fecha_corte); 
        --Cambio el estado del detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

            
            --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
            
           -- 7 - Excluir créditos con atraso mayor a 45 días
           -- 7 - en los últimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           -- con el Máximo día de atraso en los últimos 6 meses   
           
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                                 --AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';  
               
               --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );
               
         --SE actualiza el MTO_CREDITO_ACTUAL      
          FORALL y IN 1 .. VCREDITOS_PROCESAR.COUNT     
             UPDATE PR.PR_REPRESTAMOS R SET  R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
                                                 AND D.FECHA_CORTE   = ( SELECT MAX(P.FECHA_CORTE)   
                                                                                                FROM PA_DETALLADO_DE08 P
                                                                                                WHERE P.FUENTE       = 'PR' 
                                                                                                AND P.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                                                                AND P.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE))
             WHERE R.CODIGO_EMPRESA = VCREDITOS_PROCESAR(y).CODIGO_EMPRESA
               AND R.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
               AND R.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
               AND R.ESTADO         = 'RE';  
               
            --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje );   
               
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 días 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizará el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'RE'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
              --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );              
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los últimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
          -- Se actualizará el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                           AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))));
  
          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;

       END LOOP;

     CLOSE CREDITOS_PROCESAR;
     
     --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );
     
  -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Créditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        -- Se eliminan los represtamos que tienen creditos mancomunados
        DELETE  PR_REPRESTAMOS --PR_OPCIONES_REPRESTAMO
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND EXISTS (SELECT 1
                                FROM CUENTA_CLIENTE_RELACION
                                WHERE COD_SISTEMA = 'PR'
                                AND NUM_CUENTA = A.NO_CREDITO
                                AND NVL(TIPO_RELACION,'x') = 'O'
                                )
                    );  

       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
                
    DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%'; 
      
        --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE PRECALIFICA_REPRE_CANCELADO';
          setError(pProgramUnit => 'Precalifica_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
                   
         --Cambio el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ERROR', 100, SQLERRM,pMensaje );
        
        END;
        
     
     END Precalifica_Repre_Cancelado;

-- PROCEDURE Precalifica_Repre_Cancelado_hi (after)
PROCEDURE Precalifica_Repre_Cancelado_hi IS 
    CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS
         select a.codigo_empresa CODIGO_EMPRESA, 
         pr_pkg_represtamos.f_genera_secuencia ID_REPRESTAMO,
         a.codigo_cliente, 
         P_FECHA_CORTE FECHA_CORTE,
         a.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         sysdate FECHA_PROCESO, 
         0 PIN,--lpad(PA.PKG_NOTIFICACIONES.GENERAR_PIN_RANDOM(100,999999),6, '0') PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,    --   TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'INTENTOS_IDENT')) INTENTOS_IDENTIFICACION,    ---DEBE INSERTAR ESTE PARAMETRO 
         'N' IND_SOLICITA_AYUDA,
         0  mto_aprobado,
          --b.monto_desembolsado mto_aprobado,
         0 mto_preaprobado,
         null OBSERVACIONES, 
         USER ADICIONADO_POR, 
         sysdate FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         null FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,--NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0) XCORE_GLOBAL,
         NULL XCORE_CUSTOM, --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE_CUSTOM(PA.OBT_IDENTIFICACION_PERSONA( A.codigo_cliente,'1')),0) XCORE_CUSTOM
         NULL ID_CARGA_DIRIGIDA,
         NULL ID_CAMPANA_ESPECIALES,
         'N'  ES_FIADOR
         FROM PR_CREDITOS_HI a,
              PR_tipo_credito_REPRESTAMO c 
         WHERE ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO')) and  a.tipo_credito= c.tipo_credito      
         AND (EXISTS (SELECT 1
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)OR NOT EXISTS ( SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq ) )   
          and  A.F_CANCELACION= ( SELECT  d.F_CANCELACION
                        FROM PR_CREDITOS_HI d
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(1000) --TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                        AND d.F_CANCELACION <= SYSDATE
                        AND d.NO_CREDITO =   a.NO_CREDITO
                        AND d.ESTADO = 'C'
                        )
         AND c.CARGA = 'S'
         and a.codigo_empresa =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo

         and not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                                   AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))))
          AND not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.ESTADO              = 'E')
          -- validación para  solo pesonas físicas                     
          AND exists (SELECT 1 
                      FROM PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA' ))
         -- validación la nacionalidad              
         AND EXISTS ( SELECT 1
                      FROM ID_PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
                      AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO'))))          
         --  se valida que no exista el mismo crédito con un proceso iniciado de représtamo 
         AND not exists (select 1
                                 from pr_represtamos
                                 where codigo_empresa = a.codigo_empresa 
                                 and no_credito =  a.NO_CREDITO
                                 and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_NO_REPROCESO')))
                                 --('RE','VR','NP','SC','CRB','CRS','CRD')
                                 )
         -- Se valida que solo se selecciones creditos que cumplan con el criterio del monto desembolsado se encuentre entre el parámetro
         /*AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )*/
        -- Se valida que sea a una sola firma        
        AND NOT EXISTS (select 1--a.no_credito---, a.codigo_cliente, b.codigo_aval_repre
                        from PR_CREDITOS_HI a1, 
                            PR_AVAL_REPRE_X_CREDITO b
                        where a1.codigo_empresa = 1
                        and a1.no_credito = a.no_credito
                        and b.codigo_empresa = a1.codigo_empresa
                        and b.no_credito = a1.no_credito
                        and b.codigo_aval_repre != a1.codigo_cliente
                        AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CLIENTES_A_SOLA_FIRMA' ) = 'S')
        -- Se valida que los clientes no tengan no garantes 
        AND   PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
        -- Se valida que los clientes no esten en lista PEP
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 0 
        -- Se valida que los clientes no esten en lista NEGRA
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0 ;
                         
      
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       v_conteo                  NUMBER(10);  
       --agregue esta variable
       pMensaje      VARCHAR2(100);
       --Defino la variable para capturar si existe un detalle
       --idCabeceraDet NUMBER;    
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
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRE_CANCELADO_HI', 'INICIADO', pMensaje ); 
                        
                        
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
        DBMS_OUTPUT.PUT_LINE ( 'Entro aqui' );
       
       
        --DBMS_OUTPUT.PUT_LINE ( 'entra en el begin' );    
       -- Asigna el valor del Parámetro a la variable correspondioente 
       v_atraso_30 := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC'));
      -- Ejecuto un SELECT INTO de la FECHA_PROCESO en la tabla PR_REPRESTAMOS    
      -- Calculo que la variable v_fecha_froceso + el Parámetro de Fecha_a_Procesar(Que puede ser 10 días)
      -- Si la Fecha resultante es Mayor al trunc(Sysdate) Ejecuto el Package PR_PKG_PRECALIFICADOS;
      -- de lo contrario ejecuto un Return, para que el Package CDG.P_CARGA_PRESTAMOS termine su Ejecución.  
          BEGIN
              SELECT P.FECHA_PROCESO
               INTO v_fecha_proceso      
               FROM PR.PR_REPRESTAMOS P
              WHERE P.FECHA_PROCESO IS NOT NULL 
                AND ROWNUM = 1;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              v_fecha_proceso:= TRUNC(SYSDATE)-30;
          END;      
              
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                --DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
       
      --Actualizo el detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
      
       -- Para obtener la fecha máxima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
       
       
                      
       
       OPEN CREDITOS_PROCESAR(v_fecha_corte); 
        
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

            --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );

           -- 7 - Excluir créditos con atraso mayor a 45 días
           -- 7 - en los últimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           -- con el Máximo día de atraso en los últimos 6 meses   
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                                 --AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';  
               
               --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
               
         --SE actualiza el MTO_CREDITO_ACTUAL      
          FORALL y IN 1 .. VCREDITOS_PROCESAR.COUNT     
             UPDATE PR.PR_REPRESTAMOS R SET  R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
                                                 AND D.FECHA_CORTE   = ( SELECT MAX(P.FECHA_CORTE)   
                                                                                                FROM PA_DETALLADO_DE08 P
                                                                                                WHERE P.FUENTE       = 'PR' 
                                                                                                AND P.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                                                                AND P.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE))
             WHERE R.CODIGO_EMPRESA = VCREDITOS_PROCESAR(y).CODIGO_EMPRESA
               AND R.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
               AND R.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
               AND R.ESTADO         = 'RE';  
               
              --Actualizo el detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje ); 
               
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 días 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizará el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'RE'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
                                           
                                           
           --Cambio el estado del detalle de la bitacora
           --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );  
            
                           
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los últimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
          -- Se actualizará el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                           AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))));
  
          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;

       END LOOP;

     CLOSE CREDITOS_PROCESAR;
     
         --Actualizo el detalle de la bitacora
         --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
     
     
  -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Créditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > 1000--OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        -- Se eliminan los represtamos que tienen creditos mancomunados
        DELETE  PR_REPRESTAMOS --PR_OPCIONES_REPRESTAMO
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND EXISTS (SELECT 1
                                FROM CUENTA_CLIENTE_RELACION
                                WHERE COD_SISTEMA = 'PR'
                                AND NUM_CUENTA = A.NO_CREDITO
                                AND NVL(TIPO_RELACION,'x') = 'O'
                                )
                    );  
        --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
    --Cambio el estado del detalle de la bitacora
    --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );            
    DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%'; 
              
          --Actualizo el detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
       

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE PRECALIFICA_REPRE_CANCELADO_HI';
          
          setError(pProgramUnit => 'Precalifica_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          
          --Capturo el error del detalle
          --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
 
        END;
    
      
                        
        
     END Precalifica_Repre_Cancelado_hi;   

-- PROCEDURE Precalifica_Represtamo_fiadores (after)
  PROCEDURE Precalifica_Represtamo_fiadores  IS 
  
       CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS
       select a.codigo_empresa
         CODIGO_EMPRESA, 
         pr_pkg_represtamos.f_genera_secuencia ID_REPRESTAMO,
         a.codigo_cliente, 
         P_FECHA_CORTE FECHA_CORTE,
         a.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         sysdate FECHA_PROCESO, 
         0 PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,
         'N' IND_SOLICITA_AYUDA,
         b.monto_desembolsado mto_aprobado,
         0 mto_preaprobado,
         null OBSERVACIONES, 
         USER ADICIONADO_POR, 
         sysdate FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         null FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,
         NULL XCORE_CUSTOM,
         NULL ID_CARGA_DIRIGIDA,
         NULL ID_CAMPANA_ESPECIALES,
         'S'  ES_FIADOR
         FROM PR_CREDITOS a,
         pa_detallado_De08 b,
              PR_tipo_credito_REPRESTAMO c 
         WHERE ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO')) and  a.tipo_credito= c.tipo_credito  
         AND (EXISTS (SELECT 1
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)OR NOT EXISTS ( SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq ) )
         AND b.tipo_credito= c.tipo_credito 
         AND  b.fecha_corte =  TO_DATE('19/11/2024', 'DD/MM/YYYY')
         AND  b.no_credito = a.no_credito
         AND  b.fuente = 'PR'
         AND  c.CARGA = 'S'
         AND  b.dias_atraso <=PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_MORA_MAYOR_PR')
         AND b.CALIFICA_CLIENTE  IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
          
           AND (( b.MTO_BALANCE_CAPITAL / 
                     CASE WHEN b.MONTO_DESEMBOLSADO =0 then
                         b.MONTO_CREDITO
                         else b.MONTO_DESEMBOLSADO END )*100 )<= 100 - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CAPITAL_PAGADO'))
         
         and a.codigo_empresa =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
         and not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                                   AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))))
          AND not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.ESTADO              = 'E')
          -- validación para  solo pesonas físicas                     
          AND exists (SELECT 1 
                      FROM PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA' ))
         -- validación la nacionalidad              
         AND EXISTS ( SELECT 1
                      FROM ID_PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
                      AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO'))))          
         --  se valida que no exista el mismo crédito con un proceso iniciado de représtamo 
         AND not exists (select 1
                                 from pr_represtamos
                                 where codigo_empresa = a.codigo_empresa 
                                 and no_credito =  a.NO_CREDITO
                                 and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_NO_REPROCESO')))
                                 --('RE','VR','NP','SC','CRB','CRS','CRD')
                                 )
         -- Se valida que solo se selecciones creditos que cumplan con el criterio del monto desembolsado se encuentre entre el parámetro
       /*  AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )*/
      -- Se valida que sea a una sola firma        
        AND  EXISTS (select 1--a.no_credito---, a.codigo_cliente, b.codigo_aval_repre
                        from PR_CREDITOS a1, 
                            PR_AVAL_REPRE_X_CREDITO b
                        where a1.codigo_empresa = 1
                        and a1.no_credito = a.no_credito
                        and b.codigo_empresa = a1.codigo_empresa
                        and b.no_credito = a1.no_credito
                        and b.codigo_aval_repre != a1.codigo_cliente)
        -- Se valida que los clientes no tengan no garantes 
       AND   PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0   
        -- Se valida que los clientes no esten en lista PEP
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 0 
        -- Se valida que los clientes no esten en lista NEGRA
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0
        AND EXISTS (
          SELECT 1
          FROM PR_CREDITOS C2
          WHERE C2.CODIGO_CLIENTE = a.CODIGO_CLIENTE
            AND C2.ESTADO = 'C'
          GROUP BY C2.CODIGO_CLIENTE
          HAVING COUNT(*) = 2);
           
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       --agregue esta variable
       pMensaje      VARCHAR2(100);
       
          
    BEGIN
            
    
            --VERIFICAR SI EXISTE EL REGISTRO
           /* BEGIN
                SELECT ID_APLICACION_PASO_DET
                INTO idCabeceraDet
                FROM PR.PR_APLICACION_PASO_DET
                WHERE ID_APLICACION_PASO_DET = pIDAPLICACION;
                
                DBMS_OUTPUT.PUT_LINE ( 'qUE PASO AQUI = ' || idCabeceraDet );
                
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    --SI NO SE ENCUENTRA NINGUN REGISTRO CREARA UNO NUEVO
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRESTAMO', 'INICIADO', pMensaje ); 
                        
                        
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
    
       
       -- Asigna el valor del Par¿metro a la variable correspondioente 
       v_atraso_30 := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC'));
          BEGIN
              SELECT P.FECHA_PROCESO
               INTO v_fecha_proceso      
               FROM PR.PR_REPRESTAMOS P
              WHERE P.FECHA_PROCESO IS NOT NULL 
                AND ROWNUM = 1;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              v_fecha_proceso:= TRUNC(SYSDATE)-30;
          END;      
       --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );   
         BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
      
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 30, 'EN PROCESO', pMensaje ); 
       -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
       
       OPEN CREDITOS_PROCESAR(v_fecha_corte); 

        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 40, 'EN PROCESO', pMensaje );
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

         

           -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as
           -- 7 - en los ¿ltimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           -- con el M¿ximo d¿a de atraso en los ¿ltimos 6 meses   
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as en los ¿ltimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                               --  AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';   
         
       
              
            --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );  
       
              
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 d¿as 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizar¿ el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'RE'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
          
            
          --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 60, 'EN PROCESO', pMensaje );
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los ¿ltimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los ¿ltimos 6 meses
          -- Se actualizar¿ el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ¿LTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ¿LTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los ¿ltimos 6 meses
                           AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))));

          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;
       END LOOP;
       
       CLOSE CREDITOS_PROCESAR;
       
       
       --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 70, 'EN PROCESO', pMensaje );
       
       -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Cr¿ditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > 1000--OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 80, 'EN PROCESO', pMensaje );   
        -- Se eliminan los represtamos que tienen creditos mancomunados
        DELETE  PR_REPRESTAMOS --PR_OPCIONES_REPRESTAMO
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND EXISTS (SELECT 1
                                FROM CUENTA_CLIENTE_RELACION
                                WHERE COD_SISTEMA = 'PR'
                                AND NUM_CUENTA = A.NO_CREDITO
                                AND NVL(TIPO_RELACION,'x') = 'O'
                                )
                    ); 
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
                
     DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%';  
      
      --Actualiza el detalle de la bitacora para cambiar el estado a proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 100, 'EN PROCESO', pMensaje );
         --Finalizo el proceso
        --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO',pMensaje );
        
          
      COMMIT;
        -- PR.PR_PKG_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
        pMensaje:='ERROR CON EL STORE PROCEDURE Precalifica_Represtamo_fiadores';
          setError(pProgramUnit => 'Precalifica_Represtamo_fiadores', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        
        END;
        
        
    END Precalifica_Represtamo_fiadores;

-- PROCEDURE Precalifica_Represtamo_fiadores_hi (after)
    PROCEDURE Precalifica_Represtamo_fiadores_hi IS 
    CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS
         select a.codigo_empresa CODIGO_EMPRESA, 
         pr_pkg_represtamos.f_genera_secuencia ID_REPRESTAMO,
         a.codigo_cliente, 
         P_FECHA_CORTE FECHA_CORTE,
         a.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         sysdate FECHA_PROCESO, 
         0 PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,  
         'N' IND_SOLICITA_AYUDA,
         0  mto_aprobado,
          --b.monto_desembolsado mto_aprobado,
         0 mto_preaprobado,
         null OBSERVACIONES, 
         USER ADICIONADO_POR, 
         sysdate FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         null FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,
         NULL XCORE_CUSTOM,
         NULL ID_CARGA_DIRIGIDA,
         NULL ID_CAMPANA_ESPECIALES,
         'S'  ES_FIADOR
         FROM PR_CREDITOS_HI a,
              PR_tipo_credito_REPRESTAMO c 
         WHERE ROWNUM <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO')) and  a.tipo_credito= c.tipo_credito      
         AND (EXISTS (SELECT 1
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)OR NOT EXISTS ( SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq ) )   
          and  A.F_CANCELACION= ( SELECT  d.F_CANCELACION
                        FROM PR_CREDITOS_HI d
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(1000) --TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                        AND d.F_CANCELACION <= SYSDATE
                        AND d.NO_CREDITO =   a.NO_CREDITO
                        AND d.ESTADO = 'C'
                        )
         AND c.CARGA = 'S'
         and a.codigo_empresa =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo

         and not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                                   AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))))
          AND not exists (SELECT 1
                                  FROM PR_CREDITOS C 
                                 WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
                                   AND C.NO_CREDITO          != a.NO_CREDITO                       
                                   AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
                                   AND C.ESTADO              = 'E')
          -- validación para  solo pesonas físicas                     
          AND exists (SELECT 1 
                      FROM PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA' ))
         -- validación la nacionalidad              
         AND EXISTS ( SELECT 1
                      FROM ID_PERSONAS a
                      WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
                      AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
                      AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO'))))          
         --  se valida que no exista el mismo crédito con un proceso iniciado de représtamo 
         AND not exists (select 1
                                 from pr_represtamos
                                 where codigo_empresa = a.codigo_empresa 
                                 and no_credito =  a.NO_CREDITO
                                 and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_NO_REPROCESO')))
                                 --('RE','VR','NP','SC','CRB','CRS','CRD')
                                 )
         -- Se valida que solo se selecciones creditos que cumplan con el criterio del monto desembolsado se encuentre entre el parámetro
         /*AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )*/
        -- Se valida que sea a una sola firma        
        AND EXISTS (select 1--a.no_credito---, a.codigo_cliente, b.codigo_aval_repre
                        from PR_CREDITOS_HI a1, 
                            PR_AVAL_REPRE_X_CREDITO b
                        where a1.codigo_empresa = 1
                        and a1.no_credito = a.no_credito
                        and b.codigo_empresa = a1.codigo_empresa
                        and b.no_credito = a1.no_credito
                        and b.codigo_aval_repre != a1.codigo_cliente)
        -- Se valida que los clientes no tengan no garantes 
        AND   PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
        -- Se valida que los clientes no esten en lista PEP
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 0 
        -- Se valida que los clientes no esten en lista NEGRA
        AND   PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0
        AND EXISTS (
          SELECT 1
          FROM PR_CREDITOS_HI C2
          WHERE C2.CODIGO_CLIENTE = a.CODIGO_CLIENTE
            AND C2.ESTADO = 'C'
          GROUP BY C2.CODIGO_CLIENTE
          HAVING COUNT(*) = 2
      );
                         
      
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       v_conteo                  NUMBER(10);  
       --agregue esta variable
       pMensaje      VARCHAR2(100);
       --Defino la variable para capturar si existe un detalle
       --idCabeceraDet NUMBER;    
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
                     PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.PRECALIFICA_REPRE_CANCELADO_HI', 'INICIADO', pMensaje ); 
                        
                        
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
       
       
        --DBMS_OUTPUT.PUT_LINE ( 'entra en el begin' );    
       -- Asigna el valor del Parámetro a la variable correspondioente 
       v_atraso_30 := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC'));
      -- Ejecuto un SELECT INTO de la FECHA_PROCESO en la tabla PR_REPRESTAMOS    
      -- Calculo que la variable v_fecha_froceso + el Parámetro de Fecha_a_Procesar(Que puede ser 10 días)
      -- Si la Fecha resultante es Mayor al trunc(Sysdate) Ejecuto el Package PR_PKG_PRECALIFICADOS;
      -- de lo contrario ejecuto un Return, para que el Package CDG.P_CARGA_PRESTAMOS termine su Ejecución.  
          BEGIN
              SELECT P.FECHA_PROCESO
               INTO v_fecha_proceso      
               FROM PR.PR_REPRESTAMOS P
              WHERE P.FECHA_PROCESO IS NOT NULL 
                AND ROWNUM = 1;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              v_fecha_proceso:= TRUNC(SYSDATE)-30;
          END;      
              
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                --DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
       
      --Actualizo el detalle de la bitacora
      --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
      
       -- Para obtener la fecha máxima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
       
       
                      
       
       OPEN CREDITOS_PROCESAR(v_fecha_corte); 
        
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

            --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );

           -- 7 - Excluir créditos con atraso mayor a 45 días
           -- 7 - en los últimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           -- con el Máximo día de atraso en los últimos 6 meses   
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                                 --AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';  
               
               --Cambio el estado del detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
               
         --SE actualiza el MTO_CREDITO_ACTUAL      
          FORALL y IN 1 .. VCREDITOS_PROCESAR.COUNT     
             UPDATE PR.PR_REPRESTAMOS R SET  R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
                                                 AND D.FECHA_CORTE   = ( SELECT MAX(P.FECHA_CORTE)   
                                                                                                FROM PA_DETALLADO_DE08 P
                                                                                                WHERE P.FUENTE       = 'PR' 
                                                                                                AND P.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
                                                                                                AND P.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE))
             WHERE R.CODIGO_EMPRESA = VCREDITOS_PROCESAR(y).CODIGO_EMPRESA
               AND R.CODIGO_CLIENTE = VCREDITOS_PROCESAR(y).CODIGO_CLIENTE
               AND R.NO_CREDITO     = VCREDITOS_PROCESAR(y).NO_CREDITO 
               AND R.ESTADO         = 'RE';  
               
              --Actualizo el detalle de la bitacora
            --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje ); 
               
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 días 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizará el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'RE'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
                                           
                                           
           --Cambio el estado del detalle de la bitacora
           --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );  
            
                           
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los últimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
          -- Se actualizará el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_REPRESTAMOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_REPRESTAMOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                           AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS'))));
  
          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;

       END LOOP;

     CLOSE CREDITOS_PROCESAR;
     
         --Actualizo el detalle de la bitacora
         --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
     
     
  -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Créditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        -- Se eliminan los represtamos que tienen creditos mancomunados
        DELETE  PR_REPRESTAMOS --PR_OPCIONES_REPRESTAMO
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND EXISTS (SELECT 1
                                FROM CUENTA_CLIENTE_RELACION
                                WHERE COD_SISTEMA = 'PR'
                                AND NUM_CUENTA = A.NO_CREDITO
                                AND NVL(TIPO_RELACION,'x') = 'O'
                                )
                    );  
        --Cambio el estado del detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
    --Cambio el estado del detalle de la bitacora
    --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );            
    DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%'; 
              
          --Actualizo el detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
       --PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
       

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE Precalifica_Represtamo_fiadores_hi';
          
          setError(pProgramUnit => 'Precalifica_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          
          --Capturo el error del detalle
          --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
 
        END;
    
      
                        
        
     END Precalifica_Represtamo_fiadores_hi;

-- PROCEDURE P_REGISTRO_SOLICITUD (after)
   PROCEDURE P_REGISTRO_SOLICITUD IS
        
       VMSG          VARCHAR2(4000);
       pMensaje      VARCHAR2(100);  
       idCabeceraDet NUMBER; 
       vUsuario      VARCHAR2(30) := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
       CURSOR CUR_REPRESTAMO IS 
         SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL
           FROM PR_REPRESTAMOS
          WHERE ESTADO = 'RE';
            
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
                  PR.PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_DET ( 'RD_CARGA_PRECALIFICACION', 'RD_CARGA.REGISTRAR_SOLICITUD', 'INICIADO', pMensaje ); 
                        
                        
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
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
                END IF;           
                */
                
                FOR A IN CUR_REPRESTAMO LOOP
                    VMSG := NULL;
                    PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO, vUsuario, VMSG);
                    PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(A.ID_REPRESTAMO, NULL, 'RE', NULL, '', vUsuario);
                END LOOP;
                COMMIT;
                /*PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );
                PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );*/
                      
                EXCEPTION WHEN OTHERS THEN   
                    DECLARE
                       vIdError      PLS_INTEGER := 0;
                     BEGIN                                    
                        pMensaje:='ERROR CON EL STORE PROCEDURE REGISTRAR_SOLICITUD';
                        setError(pProgramUnit => 'P_REGISTRO_SOLICITUD', 
                           pPieceCodeName => NULL, 
                           pErrorDescription => SQLERRM ,                                                              
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                           pEmailNotification => NULL, 
                           pParamList => IA.LOGGER.vPARAMLIST, 
                           pOutputLogger => FALSE, 
                           pExecutionTime => NULL, 
                           pIdError => vIdError); 
                           --Capturo el error del detalle de la bitacora
                           --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM, pMensaje );
                     END;    
            --END;     
       
                 
  END P_REGISTRO_SOLICITUD;

-- PROCEDURE Actualiza_Precalificacion (after)
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
               --Actualizo el estado del detalle de la bitacora
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );
       
       UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO 
               FROM PA_DETALLADO_DE08 
               WHERE NO_CREDITO = y.NO_CREDITO 
               AND CALIFICA_CLIENTE  NOT IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
               AND  fecha_corte = v_fecha_corte);
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
