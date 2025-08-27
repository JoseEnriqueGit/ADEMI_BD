CREATE OR REPLACE PACKAGE BODY PR.PR_PKG_REPRESTAMOS IS

   PROCEDURE Precalifica_Represtamo(pIDAPLICACION IN OUT NUMBER)  IS 
       
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
         AND  b.fecha_corte =  P_FECHA_CORTE
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
         AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )
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
            PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.PRECALIFICA_REPRESTAMO',10,pMensaje);

       
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
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );   
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
       
      
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 30, 'EN PROCESO', pMensaje );
       
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
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 40, 'EN PROCESO', pMensaje );
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );  
       
              
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 60, 'EN PROCESO', pMensaje );
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
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 70, 'EN PROCESO', pMensaje );
       
       -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Cr¿ditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'RE';
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 80, 'EN PROCESO', pMensaje );   
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
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 100, 'EN PROCESO', pMensaje );
         --Finalizo el proceso
        PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO',pMensaje );
        
          
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
        
        END;
        
        
    END Precalifica_Represtamo;
PROCEDURE Precalifica_Repre_Cancelado(pIDAPLICACION IN OUT NUMBER) IS 
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
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
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
         AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )
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
    BEGIN
    
     
            PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.PRECALIFICA_REPRE_CANCELADO',10,pMensaje);
            
  
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
         PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 20, 'EN PROCESO', pMensaje );    
          BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                RETURN;
              END IF;
          END; 
       
      
      --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );
      
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
         PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

            
            --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
            
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );
               
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje );   
               
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );              
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
       PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );
     
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE PRECALIFICA_REPRE_CANCELADO';
          setError(pProgramUnit => 'Precalifica_Repre_Cancelado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
                   
         --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ERROR', 100, SQLERRM,pMensaje );
        
        END;
        
     
     END Precalifica_Repre_Cancelado;
PROCEDURE Precalifica_Repre_Cancelado_hi(pIDAPLICACION IN OUT NUMBER) IS 
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
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
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
         AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )
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
    
        PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.PRECALIFICA_REPRE_CANCELADO_HI',10,pMensaje);

       
       
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
      
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );

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
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
               
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
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje ); 
               
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );  
            
                           
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
     
     
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
    --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );            
    DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%'; 
              
          --Actualizo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
       

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE PRECALIFICA_REPRE_CANCELADO_HI';
          
          setError(pProgramUnit => 'Precalifica_Repre_Cancelado_hi', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          
          --Capturo el error del detalle
               PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
 
        END;
    
      
                        
        
     END Precalifica_Repre_Cancelado_hi;   
  PROCEDURE Precalifica_Represtamo_fiadores(pIDAPLICACION IN OUT NUMBER)  IS 
  
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
         AND  b.fecha_corte =  P_FECHA_CORTE
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
         AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )
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
            
       PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.PRECALIFICA_REPRE_FIADORES',10,pMensaje);
            
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );   
         BEGIN
              v_fecha_proceso:= v_fecha_proceso +  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIAS_PROCESAR'));
              IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                --PR_REPRESTAMOS.ACTUALIZA_PRECALIFICACION;
                DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                RETURN;
              END IF;
          END; 
      
        --Actualiza el detalle de la bitacora para cambiar el estado a proceso
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 30, 'EN PROCESO', pMensaje ); 
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 40, 'EN PROCESO', pMensaje );
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );  
       
              
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 60, 'EN PROCESO', pMensaje );
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 70, 'EN PROCESO', pMensaje );
       
       -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_REPRESTAMOS para todos los Cr¿ditos precalificados con Estodo ='P'
        UPDATE PR.PR_REPRESTAMOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 100, 'EN PROCESO', pMensaje );
      --Finalizo el proceso
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO',pMensaje );
        
          
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
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
        END;
        
        
    END Precalifica_Represtamo_fiadores;
    PROCEDURE Precalifica_Represtamo_fiadores_hi(pIDAPLICACION IN OUT NUMBER) IS 
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
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
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
         AND exists (select 1
                            from PR_PLAZO_CREDITO_REPRESTAMO
                            where codigo_empresa = a.codigo_empresa
                            and tipo_credito = c.tipo_credito
                            AND A.MONTO_DESEMBOLSADO between monto_min and monto_max
                           )
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
    
        PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.PRECALIFICA_REPRE_FIADORES_HI',10,pMensaje);
  
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
      
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );

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
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
               
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje ); 
               
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje );  
            
                           
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
     
     
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje );
       -- Se valida que la edad este entre el rango de 18 a 75, definido por parametros
       DELETE  PR_REPRESTAMOS
        WHERE ID_REPRESTAMO IN (SELECT ID_REPRESTAMO
                    FROM PR_REPRESTAMOS A
                    WHERE ESTADO = 'RE'
                    AND   PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0
                    ); 
    --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );            
    DELETE PR_REPRESTAMOS
      WHERE ESTADO LIKE 'X%'; 
              
        --Actualizo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        --Finalizo el detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
       

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          pMensaje:='ERROR CON EL STORE PROCEDURE Precalifica_Represtamo_fiadores_hi';
          
          setError(pProgramUnit => 'Precalifica_Represtamo_fiadores_hi', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          
          --Capturo el error del detalle
          PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
 
        END;
    
      
                        
        
     END Precalifica_Represtamo_fiadores_hi;
 PROCEDURE Precalifica_Carga_Dirigida IS
    
    CURSOR CREDITOS_PROCESAR(P_FECHA_CORTE DATE,P_ESTADO VARCHAR)  IS
        
        SELECT 
         A.CODIGO_EMPRESA  CODIGO_EMPRESA, 
         PR_PKG_REPRESTAMOS.F_GENERA_SECUENCIA ID_REPRESTAMO,
         A.CODIGO_CLIENTE, 
         P_FECHA_CORTE FECHA_CORTE,
         A.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         SYSDATE FECHA_PROCESO, 
         0 PIN,
         PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,    
         'N' IND_SOLICITA_AYUDA,
         0 MTO_APROBADO,
         A.MTO_PREAPROBADO,
         NULL OBSERVACIONES, 
         USER ADICIONADO_POR, 
         SYSDATE FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         NULL FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,
         NULL XCORE_CUSTOM,
         A.ID_CARGA_DIRECCIONADA, --PR_PKG_REPRESTAMOS.F_GENERA_SECUENCIA_CARGA_DIRIGIDA  ID_CARGA_DIRIGIDA 
         NULL ID_CAMPANA_ESPECIALES,
         'N'  ES_FIADOR
        FROM PR.PR_CARGA_DIRECCIONADA A
        WHERE A.ESTADO = P_ESTADO;     
        
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR (); 
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       v_Persona_Fisica          NUMBER;
       v_Nacionalidad            NUMBER;
       v_Sola_Firma              NUMBER;
       v_Creditos_Estado_E       NUMBER;
       v_Creditos_Activo_represtamos         NUMBER;
       v_Creditos_Valido         NUMBER;
       v_Creditos_monto_valido   NUMBER;
       v_Creditos_Activo         NUMBER;
       v_Dias_atraso             NUMBER;
       v_Capital_Pagado          NUMBER;
       v_atraso_tc               NUMBER;
       v_cancelacion             NUMBER;   
   BEGIN
       -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
                                    
    FOR A IN CREDITOS_PROCESAR(v_fecha_corte,'P') LOOP
    
        UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'T', FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='P';
        COMMIT;
        
        -- validación para  solo pesonas físicas   
        SELECT COUNT(*) INTO v_Persona_Fisica FROM PERSONAS 
        WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15)) AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA');
          
        -- validación la nacionalidad 
        SELECT COUNT(*)INTO v_Nacionalidad FROM ID_PERSONAS
        WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
        AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
        AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO')));
      
        -- Se valida que sea a una sola firma y tenga 2 creditos cancelados   
        SELECT COUNT(*) INTO v_Sola_Firma
        FROM PR_CREDITOS A1,PR_AVAL_REPRE_X_CREDITO B
        WHERE A1.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND A1.NO_CREDITO = A.NO_CREDITO
        AND B.CODIGO_EMPRESA = A1.CODIGO_EMPRESA
        AND B.NO_CREDITO = A1.NO_CREDITO
        AND B.CODIGO_AVAL_REPRE != A1.CODIGO_CLIENTE
        AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CLIENTES_A_SOLA_FIRMA' ) = 'S'
        AND EXISTS (
          SELECT 1
          FROM PR_CREDITOS C2
          WHERE C2.CODIGO_CLIENTE = A.CODIGO_CLIENTE
            AND C2.ESTADO = 'C'
          GROUP BY C2.CODIGO_CLIENTE
          HAVING COUNT(*) = 2);
        
       --Validar creditos estado E
       SELECT COUNT(*) INTO V_CREDITOS_ESTADO_E
       FROM PR_CREDITOS C 
       WHERE C.CODIGO_EMPRESA   =  A.CODIGO_EMPRESA
       AND C.NO_CREDITO         != A.NO_CREDITO                       
       AND C.CODIGO_CLIENTE     = A.CODIGO_CLIENTE                        
        AND C.ESTADO            = 'E';
        
        --Valida que el credito no tenga un represtamo activo
       SELECT COUNT(*) INTO v_Creditos_Activo_represtamos
       FROM PR_REPRESTAMOS
       WHERE CODIGO_EMPRESA = A.CODIGO_EMPRESA 
       AND NO_CREDITO =  A.NO_CREDITO
       AND ESTADO IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'ESTADOS_NO_REPROCESO')));
       
       --Validar que el tipo de credito sea valido
       SELECT COUNT(*) INTO v_Creditos_Valido
       FROM PR_TIPO_CREDITO_REPRESTAMO R
       JOIN PR_CREDITOS C ON C.TIPO_CREDITO = R.TIPO_CREDITO
       WHERE C.NO_CREDITO = A.NO_CREDITO;
       
       --Validar que el monto este entre el rango de represtamo
      /* SELECT COUNT(*) INTO v_Creditos_monto_valido
       FROM PR_PLAZO_CREDITO_REPRESTAMO P 
       JOIN PR_CREDITOS C ON C.NO_CREDITO = A.NO_CREDITO
       WHERE P.CODIGO_EMPRESA = A.CODIGO_EMPRESA
       AND P.TIPO_CREDITO = C.TIPO_CREDITO
       AND A.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX;*/
       
       --Se valida que no tenga un Credito activo
       SELECT COUNT(*) INTO v_Creditos_Activo
       FROM PR_CREDITOS C 
       WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
       AND C.NO_CREDITO          != a.NO_CREDITO                       
       AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
       AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) 
       AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS')));
       
       --Validar dias de atraso
       SELECT MAX(D.DIAS_ATRASO) into v_Dias_atraso
       FROM  PA.PA_DETALLADO_DE08 D
       WHERE  D.FUENTE           = 'PR'
       AND D.FECHA_CORTE         >= ADD_MONTHS((SELECT MAX (P.FECHA_CORTE)  
                                             FROM PA_DETALLADO_DE08 P
                                             WHERE P.FUENTE       = 'PR'
                                             AND P.FECHA_CORTE < 
                                             ( SELECT MAX(P.FECHA_CORTE)   
                                               FROM PA_DETALLADO_DE08 P
                                               WHERE P.FUENTE       = 'PR' )), -6)                                                          
       AND D.NO_CREDITO       = a.NO_CREDITO
       AND D.CODIGO_CLIENTE   = a.CODIGO_CLIENTE;
       DBMS_OUTPUT.PUT_LINE ( 'DIAS DE ATRASO '|| v_Dias_atraso );
       
       --Validar Capital pagado
       SELECT COUNT(*) INTO v_cancelacion 
                        FROM PR_CREDITOS d
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                        AND d.F_CANCELACION <= SYSDATE
                        AND d.NO_CREDITO =   a.NO_CREDITO  
                        AND d.ESTADO = 'C';
       
       IF v_cancelacion = 0 THEN
           SELECT COUNT(*) into v_Capital_Pagado
            FROM PR.PR_CREDITOS C 
            JOIN PA_DETALLADO_DE08 D ON D.TIPO_CREDITO=C.TIPO_CREDITO 
            AND D.FUENTE='PR'
            AND D.FECHA_CORTE=a.FECHA_CORTE
            AND D.CODIGO_CLIENTE=C.CODIGO_CLIENTE
            WHERE 
            C.CODIGO_EMPRESA=PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
            AND C.NO_CREDITO=a.NO_CREDITO
            AND (((D.MTO_BALANCE_CAPITAL/CASE WHEN D.MONTO_DESEMBOLSADO=0 then D.MONTO_CREDITO else D.MONTO_DESEMBOLSADO END)*100)<= 100 - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CAPITAL_PAGADO_CARGA_DIRIGIDA')));
        ELSE v_Capital_Pagado := 1;
      
      END IF;
        -- atraso en Tarjeta de credito
        SELECT COUNT(*) into v_atraso_tc
        FROM PA_DETALLADO_DE08 D
        WHERE D.FUENTE         =  'TC'
        AND D.FECHA_CORTE      =  a.FECHA_CORTE
        AND D.NO_CREDITO      !=  a.NO_CREDITO                                     
        AND D.CODIGO_CLIENTE   =  a.CODIGO_CLIENTE
        AND D.CODIGO_EMPRESA   =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND D.DIAS_ATRASO      >= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC')); 
        
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_PERSONA_FISICA_CARGADIRIGIDA') = 'S' THEN   
         IF  v_Persona_Fisica = 0 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no es Físico',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
              DBMS_OUTPUT.PUT_LINE ( 'v_Persona_Fisica = ' || v_Persona_Fisica );
         END IF;  
      END IF; 
     IF  v_Nacionalidad = 0 THEN
          UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no tiene Nacionalidad Dominicana',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
          WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
          CONTINUE;
          DBMS_OUTPUT.PUT_LINE ( 'v_Nacionalidad = ' || v_Nacionalidad );
     END IF;    
     
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_FIADORES_CARGADIRIGIDA') = 'S' THEN
         IF  v_Sola_Firma = 0 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no es a una sola firma o no tiene 2 creditos cancelados',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
              DBMS_OUTPUT.PUT_LINE ( 'v_Sola_Firma = ' || v_Sola_Firma );
         END IF;  
     END IF;
     -- Se valida que los clientes no tengan no garantes
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_TIENE_GARANTE_CARGADIRIGIDA') = 'S' THEN
         IF  PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(A.no_credito) =  1 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente tiene garante',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'F_TIENE_GARANTIA ' );
         END IF; 
      END IF;
    -- Se valida la edad
     IF  PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0  THEN
          UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente es mayor a la edad valida',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
          CONTINUE;
           DBMS_OUTPUT.PUT_LINE ( 'F_VALIDAR_EDAD'  );
     END IF;

     -- Valida que no tenga un credito con estado E
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_ESTADO_E_CARGADIRIGIDA') = 'S' THEN
         IF  v_Creditos_Estado_E = 1 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este cliente tiene un Crédito con estado E',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              --CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Estado_E = ' || v_Creditos_Estado_E );
         END IF; 
     END IF;

     --Se valida represtamo activo
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_REPRESTAMO_ACTIVO_CARGADIRIGIDA') = 'S' THEN
         IF  v_Creditos_Activo_represtamos > 0 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este credito tiene un représtamo activo',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Activo_represtamos = ' || v_Creditos_Activo_represtamos );
         END IF; 
     END IF;

     --Validar que el tipo de credito sea valido
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_VALIDO_CARGADIRIGIDA') = 'S' THEN
         IF  v_Creditos_Valido = 0 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente no tiene un tipo de Crédito valido en Represtamo Digital',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
              WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Valido = ' || v_Creditos_Valido );
         END IF; 
     END IF;

    --Se valida que no tenga un credito activo
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_ACTIVO_CARGADIRIGIDA') = 'S' THEN
         IF  v_Creditos_Activo > 0 THEN
              UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene un Crédito activo',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Activo = ' || v_Creditos_Activo );
         END IF;   
     END IF;
     
     --Se valida el monto
     /*IF  v_Creditos_monto_valido = 0 THEN
          UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente no aplica para el rango de monto de Représtamo',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
          WHERE NO_CREDITO = A.NO_CREDITO;
          CONTINUE;
           DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_monto_valido = ' || v_Creditos_monto_valido );
     END IF; */
     --Se valida dias atraso
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_DIAS_ATRASO_CARGADIRIGIDA') = 'S' THEN
         IF  v_Dias_atraso >=PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_MORA_MAYOR_PR')  THEN
             UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene días de atraso mayor al parametrizado',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
             DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_dias_atraso = ' || v_Dias_atraso );
         END IF; 
     END IF;
     
     --Se valida monto pagado
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CAPITAL_PAGADO_CARGADIRIGIDA') = 'S' THEN
         IF  v_Capital_Pagado =0  THEN
             UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Crédito no tiene suficiente capital pagado',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
             DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_capital_pagado = ' || v_Capital_Pagado );
         END IF;
     END IF; 
     
     --Se valida atraso en tc
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_DIAS_ATRASO_TC_CARGADIRIGIDA') = 'S' THEN
         IF  v_atraso_tc >0  THEN
             UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene Tarjetas de Crédito con atraso mayor al permitido',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
             DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_atraso_tc = ' || v_Creditos_monto_valido );
         END IF;
      END IF;
     
         -- Se valida que los clientes no esten en lista PEP
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_LISTA_PEPS_CARGADIRIGIDA') = 'S' THEN    
         IF PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 1 THEN
             UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente esta en lista PEP',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
         END IF;
      END IF;
      
        -- Se valida que los clientes no esten en lista NEGRA
        IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_LISTA_NEGRA_CARGADIRIGIDA') = 'S' THEN
         IF PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 1 THEN
             UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente en lista NEGRA',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
         END IF;
        END IF;
        UPDATE PA.PA_PARAMETROS_MVP SET VALOR = 'N' WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO IN ('VALIDAR_CAPITAL_PAGADO_CARGADIRIGIDA','VALIDAR_CREDITO_ACTIVO_CARGADIRIGIDA','VALIDAR_CREDITO_ESTADO_E_CARGADIRIGIDA','VALIDAR_CREDITO_VALIDO_CARGADIRIGIDA','VALIDAR_DIAS_ATRASO_CARGADIRIGIDA','VALIDAR_DIAS_ATRASO_TC_CARGADIRIGIDA','VALIDAR_EXISTE_TIPO_CREDITO_CARGADIRIGIDA','VALIDAR_FIADORES_CARGADIRIGIDA','VALIDAR_LISTA_NEGRA_CARGADIRIGIDA','VALIDAR_LISTA_PEPS_CARGADIRIGIDA','VALIDAR_PERSONA_FISICA_CARGADIRIGIDA','VALIDAR_REPRESTAMO_ACTIVO_CARGADIRIGIDA','VALIDAR_TIENE_GARANTE_CARGADIRIGIDA','VALIDAR_XCORE_CARGADIRIGIDA');
      COMMIT;
    END LOOP; 
  
   OPEN CREDITOS_PROCESAR(v_fecha_corte,'T');

       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

          
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as en los ¿ltimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';   
          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;
       END LOOP;
       
       CLOSE CREDITOS_PROCESAR;
      
    
    
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'Precalifica_Carga_Dirigida', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        
    END Precalifica_Carga_Dirigida;
    
  PROCEDURE Precalifica_Campana_Especiales IS
    
    CURSOR CREDITOS_PROCESAR(P_FECHA_CORTE DATE,P_ESTADO VARCHAR)  IS
        
        SELECT 
         A.CODIGO_EMPRESA  CODIGO_EMPRESA, 
         PR_PKG_REPRESTAMOS.F_GENERA_SECUENCIA ID_REPRESTAMO,
         A.CODIGO_CLIENTE, 
         P_FECHA_CORTE FECHA_CORTE,
         A.NO_CREDITO,           
         'RE' ESTADO, 
         NULL CODIGO_PRECALIFICACION, 
         0 DIAS_ATRASO, 
         SYSDATE FECHA_PROCESO, 
         0 PIN,
         PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MAX_INTENTOS_PIN') INTENTOS_PIN,
         PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MAX_INTENTOS_IDENTIFICACION') INTENTOS_IDENTIFICACION,    
         'N' IND_SOLICITA_AYUDA,
         0 MTO_APROBADO,
         A.MTO_PREAPROBADO,
         NULL OBSERVACIONES, 
         USER ADICIONADO_POR, 
         SYSDATE FECHA_ADICION, 
         NULL MODIFICADO_POR, 
         NULL FECHA_MODIFICACION,
         NULL ESTADO_ORIGINAL,
         NULL XCORE_GLOBAL,
         NULL XCORE_CUSTOM,
         NULL ID_CARGA_DIRIGIDA,
         A.ID_CAMPANA_ESPECIALES, --PR_PKG_REPRESTAMOS.F_GENERA_SECUENCIA_CARGA_DIRIGIDA  ID_CARGA_DIRIGIDA 
         'N'  ES_FIADOR
        FROM PR.PR_CAMPANA_ESPECIALES A
        WHERE A.ESTADO = P_ESTADO;     
        
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR (); 
       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_atraso_30               NUMBER(10); 
       v_Persona_Fisica          NUMBER;
       v_Nacionalidad            NUMBER;
       v_Sola_Firma              NUMBER;
       v_Creditos_Estado_E       NUMBER;
       v_Creditos_Activo_represtamos         NUMBER;
       v_Creditos_Valido         NUMBER;
       v_Creditos_monto_valido   NUMBER;
       v_Creditos_Activo         NUMBER;
       v_Dias_atraso             NUMBER;
       v_Capital_Pagado          NUMBER;
       v_atraso_tc               NUMBER;
       v_cancelacion             NUMBER; 
       v_TIPO_CREDITO            NUMBER; 
   BEGIN
       -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
                                    
    FOR A IN CREDITOS_PROCESAR(v_fecha_corte,'P') LOOP
    DBMS_OUTPUT.PUT_LINE('Estado previo: ' || A.ESTADO);
    DBMS_OUTPUT.PUT_LINE ( 'v_fecha_corte = ' || v_fecha_corte );
    DBMS_OUTPUT.PUT_LINE ( 'A.CODIGO_CLIENTE ' || A.CODIGO_CLIENTE );
        UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'T', FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='P';
        COMMIT;
        
        --Validar si el credito existe en la campaña actual
        Select COUNT(*)INTO v_TIPO_CREDITO  FROM  PR.PR_REPRESTAMO_CAMPANA_DET C 
        WHERE C.TIPO_CREDITO_ORIGEN = (SELECT TIPO_CREDITO FROM (SELECT TIPO_CREDITO FROM PR.PR_CAMPANA_ESPECIALES WHERE CODIGO_CLIENTE = A.CODIGO_CLIENTE ORDER BY FECHA_ADICION DESC) WHERE ROWNUM = 1 ) AND ESTADO = 1;
        DBMS_OUTPUT.PUT_LINE ( 'v_TIPO_CREDITO ' || v_TIPO_CREDITO );
        -- validación para  solo pesonas físicas   
        SELECT COUNT(*) INTO v_Persona_Fisica FROM PERSONAS 
        WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15)) AND ES_FISICA = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'PERSONA_FISICA');
          
        -- validación la nacionalidad 
        SELECT COUNT(*)INTO v_Nacionalidad FROM ID_PERSONAS
        WHERE COD_PERSONA = cast(a.codigo_cliente as varchar2(15))
        AND   COD_PAIS    IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'NACIONALIDAD')))
        AND   COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'TIPO_DOCUMENTO')));
      
        -- Se valida que sea a una sola firma y tenga 2 creditos cancelados   
        SELECT COUNT(*) INTO v_Sola_Firma
        FROM PR_CREDITOS A1,PR_AVAL_REPRE_X_CREDITO B
        WHERE A1.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND A1.NO_CREDITO = A.NO_CREDITO
        AND B.CODIGO_EMPRESA = A1.CODIGO_EMPRESA
        AND B.NO_CREDITO = A1.NO_CREDITO
        AND B.CODIGO_AVAL_REPRE != A1.CODIGO_CLIENTE
        AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CLIENTES_A_SOLA_FIRMA' ) = 'S'
        AND EXISTS (
          SELECT 1
          FROM PR_CREDITOS C2
          WHERE C2.CODIGO_CLIENTE = A.CODIGO_CLIENTE
            AND C2.ESTADO = 'C'
          GROUP BY C2.CODIGO_CLIENTE
          HAVING COUNT(*) = 2);
        
        
       --Validar creditos estado E
       SELECT COUNT(*) INTO V_CREDITOS_ESTADO_E
       FROM PR_CREDITOS C 
       WHERE C.CODIGO_EMPRESA   =  A.CODIGO_EMPRESA
       AND C.NO_CREDITO         != A.NO_CREDITO                       
       AND C.CODIGO_CLIENTE     = A.CODIGO_CLIENTE                        
        AND C.ESTADO            = 'E';
        
        --Valida que el credito no tenga un represtamo activo
       SELECT COUNT(*) INTO v_Creditos_Activo_represtamos
       FROM PR_REPRESTAMOS
       WHERE CODIGO_EMPRESA = A.CODIGO_EMPRESA 
       AND NO_CREDITO =  A.NO_CREDITO
       AND ESTADO IN (SELECT COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS ( 'ESTADOS_NO_REPROCESO')));
       
       --Validar que el tipo de credito sea valido
       SELECT COUNT(*) INTO v_Creditos_Valido
       FROM PR_TIPO_CREDITO_REPRESTAMO R
       JOIN PR_CREDITOS C ON C.TIPO_CREDITO = R.TIPO_CREDITO
       WHERE C.NO_CREDITO = A.NO_CREDITO;
       
       --Validar que el monto este entre el rango de represtamo
      /* SELECT COUNT(*) INTO v_Creditos_monto_valido
       FROM PR_PLAZO_CREDITO_REPRESTAMO P 
       JOIN PR_CREDITOS C ON C.NO_CREDITO = A.NO_CREDITO
       WHERE P.CODIGO_EMPRESA = A.CODIGO_EMPRESA
       AND P.TIPO_CREDITO = C.TIPO_CREDITO
       AND A.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX;*/
       
       --Se valida que no tenga un Credito activo
       SELECT COUNT(*) INTO v_Creditos_Activo
       FROM PR_CREDITOS C 
       WHERE C.CODIGO_EMPRESA      =  a.CODIGO_EMPRESA
       AND C.NO_CREDITO          != a.NO_CREDITO                       
       AND C.CODIGO_CLIENTE      = a.CODIGO_CLIENTE                        
       AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO')) 
       AND C.ESTADO              IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CREDITOS')));
       
       --Validar dias de atraso
       SELECT MAX(D.DIAS_ATRASO) into v_Dias_atraso
       FROM  PA.PA_DETALLADO_DE08 D
       WHERE  D.FUENTE           = 'PR'
       AND D.FECHA_CORTE         >= ADD_MONTHS((SELECT MAX (P.FECHA_CORTE)  
                                             FROM PA_DETALLADO_DE08 P
                                             WHERE P.FUENTE       = 'PR'
                                             AND P.FECHA_CORTE < 
                                             ( SELECT MAX(P.FECHA_CORTE)   
                                               FROM PA_DETALLADO_DE08 P
                                               WHERE P.FUENTE       = 'PR' )), -6)                                                          
       AND D.NO_CREDITO       = a.NO_CREDITO
       AND D.CODIGO_CLIENTE   = a.CODIGO_CLIENTE;
       DBMS_OUTPUT.PUT_LINE ( 'DIAS DE ATRASO '|| v_Dias_atraso );
       
       --Validar Capital pagado
       SELECT COUNT(*) INTO v_cancelacion 
                        FROM PR_CREDITOS d
                        WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION_CAMPANA_ESPECIAL'))
                        AND d.F_CANCELACION <= SYSDATE
                        AND d.NO_CREDITO =   a.NO_CREDITO  
                        AND d.ESTADO = 'C';
                        
                        
       IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_TIPO_CREDITO_VALIDO_CAMPANA') = 'S' THEN                   
           IF v_TIPO_CREDITO = 0 THEN
            UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente no tiene un tipo de Crédito valido en esta campaña',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
           END IF;
       END IF;

       
       IF v_cancelacion = 0 THEN
           SELECT COUNT(*) into v_Capital_Pagado
            FROM PR.PR_CREDITOS C 
            JOIN PA_DETALLADO_DE08 D ON D.TIPO_CREDITO=C.TIPO_CREDITO 
            AND D.FUENTE='PR'
            AND D.FECHA_CORTE=a.FECHA_CORTE
            AND D.CODIGO_CLIENTE=C.CODIGO_CLIENTE
            WHERE 
            C.CODIGO_EMPRESA=PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
            AND C.NO_CREDITO=a.NO_CREDITO
            AND (((D.MTO_BALANCE_CAPITAL/CASE WHEN D.MONTO_DESEMBOLSADO=0 then D.MONTO_CREDITO else D.MONTO_DESEMBOLSADO END)*100)<= 100 - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CAPITAL_PAGADO_CARGA_DIRIGIDA')));
        ELSE v_Capital_Pagado := 1;
      
      END IF;
        -- atraso en Tarjeta de credito
        SELECT COUNT(*) into v_atraso_tc
        FROM PA_DETALLADO_DE08 D
        WHERE D.FUENTE         =  'TC'
        AND D.FECHA_CORTE      =  a.FECHA_CORTE
        AND D.NO_CREDITO      !=  a.NO_CREDITO                                     
        AND D.CODIGO_CLIENTE   =  a.CODIGO_CLIENTE
        AND D.CODIGO_EMPRESA   =  PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND D.DIAS_ATRASO      >= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_DIA_ATRASO_TC')); 
        
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_PERSONA_FISICA_CAMPANA') = 'S' THEN  
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_PERSONA_FISICA_CAMPANA' ); 
         IF  v_Persona_Fisica = 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no es Físico',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
              DBMS_OUTPUT.PUT_LINE ( 'v_Persona_Fisica = ' || v_Persona_Fisica );
         END IF; 
     END IF; 
     
         IF  v_Nacionalidad = 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no tiene Nacionalidad Dominicana',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
              WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
              CONTINUE;
              DBMS_OUTPUT.PUT_LINE ( 'v_Nacionalidad = ' || v_Nacionalidad );
         END IF;   
         
     -- Se valida que sea a una sola firma  
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_FIADORES_CAMPANA') = 'S' THEN
     DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_FIADORES_CAMPANA' );
         IF  v_Sola_Firma = 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente no es a una sola firma o no tiene 2 creditos cancelados',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
              DBMS_OUTPUT.PUT_LINE ( 'v_Sola_Firma = ' || v_Sola_Firma );
         END IF;  
     END IF;
     
     -- Se valida que los clientes no tengan no garantes
     /*IF  PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(A.no_credito) =  1 THEN
          UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente tiene garante',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
          CONTINUE;
           DBMS_OUTPUT.PUT_LINE ( 'F_TIENE_GARANTIA ' );
     END IF; */

    -- Se valida la edad
     IF  PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD ( A.CODIGO_CLIENTE,'CARGA' ) = 0  THEN
          UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente es mayor a la edad valida',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
          CONTINUE;
           DBMS_OUTPUT.PUT_LINE ( 'F_VALIDAR_EDAD'  );
     END IF;

     -- Valida que no tenga un credito con estado E
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_ESTADO_E_CAMPANA') = 'S' THEN 
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO CREDITO_ESTADO_E' );
         IF  v_Creditos_Estado_E = 1 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este cliente tiene un Crédito con estado E',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              --CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Estado_E = ' || v_Creditos_Estado_E );
         END IF; 
     END IF;

     --Se valida represtamo activo
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_REPRESTAMO_ACTIVO_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_REPRESTAMO_ACTIVO_CAMPANA' );
         IF  v_Creditos_Activo_represtamos > 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este credito tiene un représtamo activo',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Activo_represtamos = ' || v_Creditos_Activo_represtamos );
         END IF; 
     END IF;

     --Validar que el tipo de credito sea valido
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_VALIDO_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_CREDITO_VALIDO_CAMPANA' );
         IF  v_Creditos_Valido = 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente no tiene un tipo de Crédito valido en Represtamo Digital',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
              WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Valido = ' || v_Creditos_Valido );
         END IF; 
      END IF;
     

    --Se valida que no tenga un credito activo
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CREDITO_ACTIVO_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_CREDITO_ACTIVO_CAMPANA' );
         IF  v_Creditos_Activo > 0 THEN
              UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene un Crédito activo',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
              CONTINUE;
               DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_Activo = ' || v_Creditos_Activo );
         END IF;   
      END IF;
     --Se valida el monto
     /*IF  v_Creditos_monto_valido = 0 THEN
          UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente no aplica para el rango de monto de Représtamo',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
          WHERE NO_CREDITO = A.NO_CREDITO;
          CONTINUE;
           DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_monto_valido = ' || v_Creditos_monto_valido );
     END IF; */
     
     --Se valida dias atraso
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_DIAS_ATRASO_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_DIAS_ATRASO_CAMPANA' );
         IF  v_Dias_atraso >=PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PRECAL_MORA_MAYOR_PR')  THEN
             UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene días de atraso mayor al parametrizado',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
             DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_dias_atraso = ' || v_Dias_atraso );
         END IF; 
     END IF;
     --Se valida monto pagado
    /* IF  v_Capital_Pagado =0  THEN
         UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Crédito no tiene suficiente capital pagado',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
         WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
         CONTINUE;
         DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_capital_pagado = ' || v_Capital_Pagado );
     END IF;*/
     
     --Se valida atraso en tc
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_DIAS_ATRASO_TC_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_DIAS_ATRASO_TC_CAMPANA' );
         IF  v_atraso_tc >0  THEN
             UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente tiene Tarjetas de Crédito con atraso mayor al permitido',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
             DBMS_OUTPUT.PUT_LINE ( 'v_Creditos_atraso_tc = ' || v_Creditos_monto_valido );
         END IF;
     END IF;
     
         -- Se valida que los clientes no esten en lista PEP
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_LISTA_PEPS_CAMPANA') = 'S' THEN
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_LISTA_PEPS_CAMPANA' );    
         IF PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP (1, a.codigo_cliente)= 1 THEN
             UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente esta en lista PEP',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
         END IF;
     END IF;
     
        -- Se valida que los clientes no esten en lista NEGRA
     IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_LISTA_NEGRA_CAMPANA') = 'S' THEN   
        DBMS_OUTPUT.PUT_LINE ( 'ENTRO VALIDAR_LISTA_NEGRA_CAMPANA' );
         IF PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 1 THEN
             UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Este Cliente en lista NEGRA',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
             WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
             CONTINUE;
         END IF; 
     END IF;
      
     UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO IN ('VALIDAR_CAPITAL_PAGADO_CAMPANA','VALIDAR_CREDITO_ACTIVO_CAMPANA','VALIDAR_CREDITO_ESTADO_E_CAMPANA','VALIDAR_CREDITO_VALIDO_CAMPANA','VALIDAR_DIAS_ATRASO_CAMPANA','VALIDAR_DIAS_ATRASO_TC_CAMPANA','VALIDAR_EXISTE_TIPO_CREDITO_CAMPANA','VALIDAR_FIADORES_CAMPANA','VALIDAR_LISTA_NEGRA_CAMPANA','VALIDAR_LISTA_PEPS_CAMPANA','VALIDAR_PERSONA_FISICA_CAMPANA','VALIDAR_REPRESTAMO_ACTIVO_CAMPANA','VALIDAR_XCORE_CAMPANA');    
     COMMIT;
    END LOOP; 
  
   OPEN CREDITOS_PROCESAR(v_fecha_corte,'T');

       LOOP
          VCREDITOS_PROCESAR.DELETE;
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 100;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_REPRESTAMOS VALUES VCREDITOS_PROCESAR (i);

          
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT                                 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_REPRESTAMOS
           UPDATE PR.PR_REPRESTAMOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir cr¿ditos con atraso mayor a 45 d¿as en los ¿ltimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'RE';   
          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;
       END LOOP;
       
       CLOSE CREDITOS_PROCESAR;
      
    
    
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'Precalifica_Campana_Especiales', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        
    END Precalifica_Campana_Especiales;    
   PROCEDURE Actualiza_Precalificacion(pIDAPLICACION IN OUT NUMBER)  IS 
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
                AND a.DIAS_ATRASO BETWEEN P.DESDE AND HASTA
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
   
           PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.ACTUALIZA_PRECALIFICACION',10,pMensaje);

          -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
                                    
      --Actualizo el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 20, 'EN PROCESO', pMensaje );
                     
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
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 30, 'EN PROCESO', pMensaje );
       
         COMMIT;     
         
        UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO 
                FROM PA_DETALLADO_DE08 
                WHERE NO_CREDITO = y.NO_CREDITO 
                AND CALIFICA_CLIENTE  NOT IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
                AND  fecha_corte = v_fecha_corte);
           COMMIT;         
      END LOOP;
    
    
      --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
      -- Se actualiza el campo CODIGO_PRECALIFICACION con valor 'NI' y el campo OBSERVACIONES con valor 'NINGUNA PRECALIFICACION' 
      -- para todos lo cr¿ditos en la tabla PR_PRECALIFICADOS con ESTADO diferente a 'P'
      FOR a IN PRECALIFICADOS LOOP
           --IF a.CODIGO_REPRESTAMO != 'NI' THEN
             UPDATE PR_REPRESTAMOS  
                SET codigo_precalificacion = a.CODIGO_REPRESTAMO,
                    mto_preaprobado = a.mto_preaprobado
              WHERE rowid = a.id;
           COMMIT;
      END LOOP;
           
           
           
           --Validacion del DE08 FIADOR
     FOR a in CUR_FIADOR LOOP

       -- Validar si el cliente tiene un fiador
        SELECT COUNT(1) INTO v_fiador_exist
        FROM PR_CREDITOS a1
            JOIN PR_AVAL_REPRE_X_CREDITO b 
            ON a1.codigo_empresa = b.codigo_empresa AND a1.no_credito = b.no_credito
        WHERE a1.codigo_empresa = 1
          AND a1.no_credito = a.no_credito AND b.codigo_aval_repre != a1.codigo_cliente;
          
        -- Validar si el cliente tiene dos préstamos cancelados
        SELECT COUNT(1) INTO v_dos_prestamos_cancelados
        FROM (SELECT 1
                FROM PR_CREDITOS c2
               WHERE c2.codigo_cliente = a.codigo_cliente
                 AND c2.estado = 'C'
               GROUP BY c2.codigo_cliente
              HAVING COUNT(*) = 2);
              
        -- Si cumple con ambos criterios, realiza el UPDATE
        IF v_fiador_exist > 0 AND v_dos_prestamos_cancelados > 0 AND a.CODIGO_PRECALIFICACION !=  01 THEN
         vEstado:= 'RSB'; 
         vComentario:=' RECHAZO: Cliente no muy bueno con FIADOR ';
         PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
         
        END IF;
       COMMIT; 

          END LOOP;          
           
       --Actualizo el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 50, 'EN PROCESO', pMensaje );
      
      /*DELETE PR_REPRESTAMOS 
      WHERE estado = 'RE'  
      AND   CODIGO_PRECALIFICACION IS NULL;*/
    
   
   --Se agrego este codigo sustituyendo el codigo comentado de arriba el cual eliminara los represtamos sin precalificacion.
      DECLARE
        CURSOR CUR_SIN_PRECALIFICACION IS
        SELECT B.ROWID ID, b.ID_REPRESTAMO,B.CODIGO_CLIENTE
        FROM PR.PR_REPRESTAMOS B
        WHERE B.CODIGO_PRECALIFICACION IS NULL
        AND B.ESTADO = 'RE';
       v_result BOOLEAN;
      
      
      BEGIN
        --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje ); 
        FOR a IN CUR_SIN_PRECALIFICACION LOOP
            DELETE FROM PR.PR_BITACORA_REPRESTAMO WHERE ID_REPRESTAMO=a.id_represtamo;
            DELETE FROM PR.PR_CANALES_REPRESTAMO WHERE ID_REPRESTAMO=a.id_represtamo;
            DELETE FROM PR.PR_REPRESTAMOS WHERE ID_REPRESTAMO=a.id_represtamo;
        
        
            v_result := PA.P_DATOS_PERSONA.ESTA_EN_LISTA_OFAC('1',A.CODIGO_CLIENTE);
            IF v_result THEN
                DELETE FROM PR.PR_BITACORA_REPRESTAMO WHERE ID_REPRESTAMO=a.id_represtamo;
                DELETE FROM PR.PR_CANALES_REPRESTAMO WHERE ID_REPRESTAMO=a.id_represtamo;
                DELETE FROM PR.PR_REPRESTAMOS WHERE ID_REPRESTAMO=a.id_represtamo;
                --DBMS_OUTPUT.PUT_LINE('La persona está en la lista OFAC.'|| A.CODIGO_CLIENTE);
            --ELSE
                --DBMS_OUTPUT.PUT_LINE('La persona no está en la lista OFAC.'|| A.CODIGO_CLIENTE);
            END IF;   
        END LOOP;
        COMMIT;
      END;
      
      
      --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
       
      FOR a in CUR_DE08_SIB LOOP

             SELECT COUNT (1) INTO vClasificaion FROM ( WITH CLASIFICACIONES AS (SELECT VALOR FROM PA.PA_PARAMETROS_MVP where CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CLASIFICACION_SIB')
             SELECT regexp_substr (VALOR,'[^,]+',1,level) CLASIFICACION FROM  CLASIFICACIONES  connect by level <=length(VALOR) - length(replace( VALOR,','))+1 )T1 
             WHERE T1.CLASIFICACION = a.clasificacion ;
             
        --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 80, 'EN PROCESO', pMensaje ); 
            
            IF vClasificaion  = 1 THEN
             vEstado:= 'CLS'; 
             vComentario:= a.clasificacion;
            ELSE
              vEstado:= 'RSB'; 
              vComentario:= 'RECHAZO: Cliente en clasificacion: '||a.clasificacion;
            END IF;
               DBMS_OUTPUT.PUT_LINE('Antes de generar bitaciora de '||a.id_represtamo||' a '||vEstado);
              PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
               --DBMS_OUTPUT.PUT_LINE('Despues de generar bitacora '||a.id_represtamo);
          END LOOP; 
          
         
      
        
        

      --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje );     
      FOR a in CUR_DE05_SIB LOOP
           PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,'RCS',NULL,'RECHAZO: Cedula: '||a.cedula||' con castigo en '||a.entidad, USER);
       END LOOP;
       
        --Actualizo el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
        
       --Finalizo el detalle
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO', pMensaje );
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
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ERROR', 100, SQLERRM,pMensaje );
        
           
        END;   
        
       
                      
        
    END Actualiza_Precalificacion;
    
    
  PROCEDURE Actualiza_Preca_Dirigida IS 
    -- QUERY DE LOS CREDITOS PRECALIFICADOS

    CURSOR Actualizar_Mto_Credito_Actual IS
    SELECT R.ID_REPRESTAMO,NO_CREDITO,CODIGO_CLIENTE 
        FROM PR.PR_REPRESTAMOS R 
     WHERE ESTADO = 'RE';
    
       CURSOR PRECALIFICADOS IS
            SELECT 
            a.rowid id, 
            a.id_represtamo,
            a.CODIGO_CLIENTE,
            a.DIAS_ATRASO,
            P.CODIGO_REPRESTAMO,
            a.mto_credito_Actual, 
            p.factor, 
            A.MTO_PREAPROBADO mto_preaprobado,
            A.NO_CREDITO
            FROM PR.PR_REPRESTAMOS a
            LEFT JOIN PR.PR_CODIGOS_REPRESTAMO P ON P.CODIGO_EMPRESA = a.CODIGO_EMPRESA AND a.DIAS_ATRASO BETWEEN P.DESDE AND HASTA
            WHERE a.ESTADO ='RE' AND a.codigo_empresa = vCodigoEmpresa;
       --
      -- Cursor para la validaci¿n de la super con respecto a la clasificaci¿n del cliente a nivel interbancario                       
         CURSOR CUR_DE08_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION, B.NO_CREDITO
             FROM PA_DE08_SIB A,
                  PR_REPRESTAMOS B
             WHERE A.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DE08_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
             AND B.ESTADO = 'RE'
             AND B.ES_FIADOR = 'N'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;

         
   --Castigados a nivel interbancario
         CURSOR CUR_DE05_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad, B.NO_CREDITO
             FROM PA_DE05_SIB A,
                     PR_REPRESTAMOS B
             WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
             AND B.ESTADO = 'RE'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';

        
           vClasificaion NUMBER :=0;
           vEstado VARCHAR2(400);      
           vComentario VARCHAR2(400);  
           v_fecha_corte             DATE;
           vcontador NUMBER :=0; 
              
   BEGIN 
   

          -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
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
                                                                                                            
        WHERE R.CODIGO_EMPRESA = 1
        AND R.CODIGO_CLIENTE =   y.CODIGO_CLIENTE
        AND R.NO_CREDITO     =   y.NO_CREDITO 
        AND R.ESTADO         = 'RE';   
        COMMIT;     
         
        --FILTRO PARA RECHAZAR POR CLASIFICACION SIB.
        IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA') = 'S' THEN
            UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO 
            FROM PA_DETALLADO_DE08 
            WHERE NO_CREDITO = y.NO_CREDITO 
            AND CALIFICA_CLIENTE  NOT IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
            AND  fecha_corte = v_fecha_corte); 
        END IF;     
        COMMIT;
        
        SELECT COUNT(*) into vcontador FROM PR_REPRESTAMOS WHERE ESTADO = 'RSB' AND NO_CREDITO = y.NO_CREDITO;
        
        IF vcontador>0 THEN
            UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = y.NO_CREDITO  AND ESTADO='T';
            COMMIT;
        END IF;
        
      END LOOP;
    
    
    
      -- Se actualiza el campo CODIGO_PRECALIFICACION con valor 'NI' y el campo OBSERVACIONES con valor 'NINGUNA PRECALIFICACION' 
      -- para todos lo cr¿ditos en la tabla PR_PRECALIFICADOS con ESTADO diferente a 'P'
      FOR a IN PRECALIFICADOS LOOP
           --IF a.CODIGO_REPRESTAMO != 'NI' THEN
             UPDATE PR_REPRESTAMOS  
                SET codigo_precalificacion = a.CODIGO_REPRESTAMO,
                    mto_preaprobado = NVL(a.mto_preaprobado,0)
              WHERE rowid = a.id;
           COMMIT;
           
           
           SELECT COUNT(*) into vcontador FROM PR_REPRESTAMOS WHERE estado = 'RE' and codigo_precalificacion is null AND NO_CREDITO = a.NO_CREDITO;
           --Esta validacion se comento por la HISOTRIA IRD-270

          /* IF vcontador>0 THEN
               UPDATE PR.PR_CARGA_DIRECCIONADA 
               SET ESTADO = 'E',
               OBSERVACIONES = 'Este Cliente tiene código de precalificación por que tiene días de atraso mayor al parametrizado',
               FECHA_MODIFICACION = SYSDATE, 
               MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
               WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               COMMIT;
           END IF;*/
           
      END LOOP;
          
      DELETE PR_REPRESTAMOS 
      WHERE estado = 'RE'  
      AND   CODIGO_PRECALIFICACION IS NULL;
 --Validacion del DE08 
      FOR a in CUR_DE08_SIB LOOP

             SELECT COUNT (1) INTO vClasificaion FROM ( WITH CLASIFICACIONES AS (SELECT VALOR FROM PA.PA_PARAMETROS_MVP where CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CLASIFICACION_SIB')
             SELECT regexp_substr (VALOR,'[^,]+',1,level) CLASIFICACION FROM  CLASIFICACIONES  connect by level <=length(VALOR) - length(replace( VALOR,','))+1 )T1 
             WHERE T1.CLASIFICACION = a.clasificacion ;
  
            IF vClasificaion  = 1 THEN
             vEstado:= 'CLS'; 
             vComentario:= a.clasificacion;
            ELSE
            IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA') = 'S' THEN
              vEstado:= 'RSB'; 
              vComentario:= 'Cliente en clasificacion: '||a.clasificacion;
            END IF;
            
               UPDATE PR.PR_CARGA_DIRECCIONADA 
               SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, 
               MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
               WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               COMMIT;
            
            END IF;
               DBMS_OUTPUT.PUT_LINE('Antes de generar bitaciora de '||a.id_represtamo||' a '||vEstado);
              PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
               DBMS_OUTPUT.PUT_LINE('Despues de generar bitacora '||a.id_represtamo);
          END LOOP; 
        
      FOR a in CUR_DE05_SIB LOOP
      --CASTIGADOS SIB
        IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CASTIGADOS_SIB_CARGADIRIGIDA') = 'S' THEN
           PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,'RCS',NULL,'Cedula: '||a.cedula||' con castigo en '||a.entidad, USER);
        END IF;
           UPDATE PR.PR_CARGA_DIRECCIONADA 
           SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, 
           MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
           WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
           COMMIT;
      END LOOP; 
      
      UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO IN ('VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA','VALIDAR_CASTIGADOS_SIB_CARGADIRIGIDA');
      COMMIT;
      

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'Actualiza_Preca_Dirigida', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
    END Actualiza_Preca_Dirigida;
    -- Se genere la secuencia de identificaci¿n ¿nica del registro de repr¿stamo
    PROCEDURE Actualiza_Preca_Campana_Especiale IS
    
    
    CURSOR Actualizar_Mto_Credito_Actual IS
    SELECT R.ID_REPRESTAMO,NO_CREDITO,CODIGO_CLIENTE 
        FROM PR.PR_REPRESTAMOS R 
     WHERE ESTADO = 'RE';
    
       CURSOR PRECALIFICADOS IS
            SELECT 
            a.rowid id, 
            a.id_represtamo,
            a.CODIGO_CLIENTE,
            a.DIAS_ATRASO,
            P.CODIGO_REPRESTAMO,
            a.mto_credito_Actual, 
            p.factor, 
            A.MTO_PREAPROBADO mto_preaprobado,
            A.NO_CREDITO
            FROM PR.PR_REPRESTAMOS a
            LEFT JOIN PR.PR_CODIGOS_REPRESTAMO P ON P.CODIGO_EMPRESA = a.CODIGO_EMPRESA AND a.DIAS_ATRASO BETWEEN P.DESDE AND HASTA
            WHERE a.ESTADO ='RE' AND a.codigo_empresa = vCodigoEmpresa;
       --
      -- Cursor para la validaci¿n de la super con respecto a la clasificaci¿n del cliente a nivel interbancario                       
         CURSOR CUR_DE08_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION, B.NO_CREDITO
             FROM PA_DE08_SIB A,
                  PR_REPRESTAMOS B
             WHERE A.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DE08_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
             AND B.ESTADO = 'RE'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;
         
   --Castigados a nivel interbancario
         CURSOR CUR_DE05_SIB IS 
             SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad, B.NO_CREDITO
             FROM PA_DE05_SIB A,
                     PR_REPRESTAMOS B
             WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
             AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
             AND B.ESTADO = 'RE'
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';

        
           vClasificaion NUMBER :=0;
           vEstado VARCHAR2(400);      
           vComentario VARCHAR2(400);  
           v_fecha_corte             DATE;
           vcontador NUMBER :=0; 
                             
   BEGIN 
   

          -- Para obtener la fecha m¿xima anterior
        SELECT MAX (P.FECHA_CORTE)  
          INTO v_fecha_corte
          FROM PA_DETALLADO_DE08 P
         WHERE P.FUENTE       = 'PR'
           AND P.FECHA_CORTE  <  ( SELECT MAX(P.FECHA_CORTE)   
                                     FROM PA_DETALLADO_DE08 P
                                    WHERE P.FUENTE       = 'PR' );
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
                                                                                                            
        WHERE R.CODIGO_EMPRESA = 1
        AND R.CODIGO_CLIENTE =   y.CODIGO_CLIENTE
        AND R.NO_CREDITO     =   y.NO_CREDITO 
        AND R.ESTADO         = 'RE';   
        COMMIT;     
         
        IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CLASIFICACION_SIB_CAMPANA') = 'S' THEN
            UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB' WHERE NO_CREDITO = ( SELECT NO_CREDITO 
            FROM PA_DETALLADO_DE08 
            WHERE NO_CREDITO = y.NO_CREDITO 
            AND CALIFICA_CLIENTE  NOT IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'CLASIFICACION_SIB')))
            AND  fecha_corte = v_fecha_corte);  
        END IF;    
        COMMIT;
        
        SELECT COUNT(*) into vcontador FROM PR_REPRESTAMOS WHERE ESTADO = 'RSB' AND NO_CREDITO = y.NO_CREDITO;
        
        IF vcontador>0 THEN
            UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = y.NO_CREDITO  AND ESTADO='T';
            COMMIT;
        END IF;
        
      END LOOP;
    
    
    
      -- Se actualiza el campo CODIGO_PRECALIFICACION con valor 'NI' y el campo OBSERVACIONES con valor 'NINGUNA PRECALIFICACION' 
      -- para todos lo cr¿ditos en la tabla PR_PRECALIFICADOS con ESTADO diferente a 'P'
      FOR a IN PRECALIFICADOS LOOP
           --IF a.CODIGO_REPRESTAMO != 'NI' THEN
             UPDATE PR_REPRESTAMOS  
                SET codigo_precalificacion = a.CODIGO_REPRESTAMO,
                    mto_preaprobado = NVL(a.mto_preaprobado,0)
              WHERE rowid = a.id;
           COMMIT;
           
           
           SELECT COUNT(*) into vcontador FROM PR_REPRESTAMOS WHERE estado = 'RE' and codigo_precalificacion is null AND NO_CREDITO = a.NO_CREDITO;
           --Esta validacion se comento por la HISOTRIA IRD-270

          /* IF vcontador>0 THEN
               UPDATE PR.PR_CAMPANA_ESPECIALES 
               SET ESTADO = 'E',
               OBSERVACIONES = 'Este Cliente tiene código de precalificación por que tiene días de atraso mayor al parametrizado',
               FECHA_MODIFICACION = SYSDATE, 
               MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
               WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               COMMIT;
           END IF;*/
           
      END LOOP;
          
      DELETE PR_REPRESTAMOS 
      WHERE estado = 'RE'  
      AND   CODIGO_PRECALIFICACION IS NULL;
 --Validacion del DE08 
      FOR a in CUR_DE08_SIB LOOP

             SELECT COUNT (1) INTO vClasificaion FROM ( WITH CLASIFICACIONES AS (SELECT VALOR FROM PA.PA_PARAMETROS_MVP where CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CLASIFICACION_SIB')
             SELECT regexp_substr (VALOR,'[^,]+',1,level) CLASIFICACION FROM  CLASIFICACIONES  connect by level <=length(VALOR) - length(replace( VALOR,','))+1 )T1 
             WHERE T1.CLASIFICACION = a.clasificacion ;
  
            IF vClasificaion  = 1 THEN
             vEstado:= 'CLS'; 
             vComentario:= a.clasificacion;
            ELSE
            IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CLASIFICACION_SIB_CAMPANA') = 'S' THEN
              vEstado:= 'RSB'; 
              vComentario:= 'Cliente en clasificacion: '||a.clasificacion;
            END IF;
            
               UPDATE PR.PR_CAMPANA_ESPECIALES 
               SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, 
               MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
               WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               COMMIT;
            
            END IF;
               DBMS_OUTPUT.PUT_LINE('Antes de generar bitaciora de '||a.id_represtamo||' a '||vEstado);
              PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,vEstado,NULL,vComentario, USER);
               DBMS_OUTPUT.PUT_LINE('Despues de generar bitacora '||a.id_represtamo);
          END LOOP; 
          
      FOR a in CUR_DE05_SIB LOOP
      IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_CASTIGADOS_SIB_CAMPANA') = 'S' THEN
           PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,'RCS',NULL,'Cedula: '||a.cedula||' con castigo en '||a.entidad, USER);
      END IF;
           UPDATE PR.PR_CAMPANA_ESPECIALES 
           SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, 
           MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) 
           WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
           COMMIT;
      END LOOP;
      
      UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO IN ('VALIDAR_CLASIFICACION_SIB_CAMPANA','VALIDAR_CASTIGADOS_SIB_CAMPANA'); 
      COMMIT;
      

    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'Actualiza_Preca_Campana_Especiale', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
    END Actualiza_Preca_Campana_Especiale;
 PROCEDURE Actualiza_XCORE_CUSTOM(pIDAPLICACION IN OUT NUMBER) IS
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
   
   
     PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.ACTUALIZA_XCORE_CUSTOM',20,pMensaje);
    
        
    Vlote_Proceso_Xcore := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE'));
    --DBMS_OUTPUT.PUT_LINE ( 'Vlote_Proceso_Xcore = ' || Vlote_Proceso_Xcore );
               BEGIN
                SELECT COUNT(*) INTO vTotal_Carga FROM PR.PR_REPRESTAMOS A WHERE A.ESTADO = 'RE';
                EXCEPTION WHEN NO_DATA_FOUND THEN
                 vTotal_Carga:= 0;   
                 DBMS_OUTPUT.PUT_LINE ( 'vTotal_Carga = ' || vTotal_Carga );
                    COMMIT;
              END; 
         
         vCantidad_Procesar :=  round(vTotal_Carga / Vlote_Proceso_Xcore) + 1  ;     
     --DBMS_OUTPUT.PUT_LINE ( 'vCantidad_Procesar = ' || vCantidad_Procesar );
     
       --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 40, 'EN PROCESO', pMensaje );
                          
       FOR A IN VALIDACION_CLASIFICACION LOOP
         PR_PKG_REPRESTAMOS.p_generar_bitacora(a.ID_REPRESTAMO,NULL,'RSB',NULL,'Cliente sin clasificación', USER);
          --DBMS_OUTPUT.PUT_LINE ( 'VALIDACION_CLASIFICACION ' );
       END LOOP;
       
       --Cambio el estado del detalle de la bitacora
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION,'ENPROCESO', 50, 'EN PROCESO', pMensaje ); 
        
       FOR i IN 1..vCantidad_Procesar LOOP
        FOR A IN CUR_UPDATE_XCORE LOOP
            DBMS_OUTPUT.PUT_LINE ( 'Entro al for ' );
         
        --Cambio el estado del detalle de la bitacora
         PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje ); 
            
            
           BEGIN
               xcore := 600;--NVL(TRIM(JSON_VALUE( PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON(PA.OBT_IDENTIFICACION_PERSONA(a.codigo_cliente,'1') ,'C','COMPATIBILIDAD',NULL,NULL,NULL,NULL,0), '$.respuesta.valor.applicants.primaryConsumer.interconnectResponse.Xcore_PD12M_ALL_PC_NC_Global.Xcore')),0);
               --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0);
               IF xcore IS NULL THEN
                    xcore := 0;
               END IF;
               DBMS_OUTPUT.PUT_LINE ( 'xcore1 = ' || xcore );

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
                           --DBMS_OUTPUT.PUT_LINE ( 'DBMS_UTILITY.FORMAT_ERROR_BACKTRACE = ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
                    --Capturo el error del detalle de la bitacora
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM, pMensaje );
                    xcore := 0;
                    --DBMS_OUTPUT.PUT_LINE ( 'xcore2 = ' || xcore );
                END;  

                      COMMIT;

             END ; 
             
             --Cambio el estado del detalle de la bitacora
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
            
             UPDATE PR_REPRESTAMOS  
             SET XCORE_GLOBAL = xcore, XCORE_CUSTOM = xcore
             WHERE rowid = a.id;
              COMMIT;
              DBMS_OUTPUT.PUT_LINE ( SQLERRM);
          END LOOP ;
        
      END LOOP;
      
      
       --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
       --Finalizo el detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
        
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
                     --Capturo el error del detalle de la bitacora
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM, pMensaje );
               END;  
            
                          
     /* FOR A IN CUR_UPDATE_CREADOS LOOP
           IF NVL(a.XCORE_GLOBAL,0) < TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_XCORE'))  THEN
            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Credito cancelado por Xcore Ademi', USER);
           END IF;
       END LOOP; */
       
       
    END Actualiza_XCORE_CUSTOM;
  
  
  PROCEDURE ACTUALIZA_XCORE_DIRIGIDA IS --SROBLES
         --Represtamos En estado RE sin xcore ademi
               CURSOR VALIDACION_CLASIFICACION IS
               SELECT R.ID_REPRESTAMO,R.NO_CREDITO FROM PR_REPRESTAMOS R 
               WHERE  R.ESTADO = 'RE'
               AND NOT EXISTS( SELECT CODIGO_ESTADO FROM PR_BITACORA_REPRESTAMO WHERE CODIGO_ESTADO = 'CLS' AND ID_REPRESTAMO = R.ID_REPRESTAMO );
               
               CURSOR CUR_UPDATE_XCORE IS 
               SELECT A.ROWID ID,A.ID_REPRESTAMO, A.CODIGO_CLIENTE,A.ESTADO,A.XCORE_GLOBAL
               FROM PR.PR_REPRESTAMOS A
               WHERE A.ESTADO = 'RE' AND XCORE_GLOBAL IS NULL AND ROWNUM<= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE')); 
    
               vTotal_Carga NUMBER(10);
               vCantidad_Procesar NUMBER(10);
               Vlote_Proceso_Xcore NUMBER(10);
             
               xcore NUMBER(30);
    BEGIN
    Vlote_Proceso_Xcore := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE'));
           
                       BEGIN
                        SELECT COUNT(*) INTO vTotal_Carga FROM PR.PR_REPRESTAMOS A WHERE A.ESTADO = 'RE';
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                         vTotal_Carga:= 0;   
                            COMMIT;
                      END; 
                 
                 vCantidad_Procesar :=  round(vTotal_Carga / Vlote_Proceso_Xcore) + 1;     
             
                      
               FOR A IN VALIDACION_CLASIFICACION LOOP
                 PR_PKG_REPRESTAMOS.p_generar_bitacora(a.ID_REPRESTAMO,NULL,'RSB',NULL,'Cliente sin clasificación', USER);
                 UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               END LOOP;
               
               FOR i IN 1..vCantidad_Procesar LOOP
               FOR A IN CUR_UPDATE_XCORE LOOP
               --DBMS_OUTPUT.PUT_LINE ( 'ACTUALIZA XCORE: ' );
                       BEGIN
                       xcore := NVL(TRIM(JSON_VALUE( PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON(PA.OBT_IDENTIFICACION_PERSONA(a.codigo_cliente,'1') ,'C','COMPATIBILIDAD',NULL,NULL,NULL,NULL,0), '$.respuesta.valor.applicants.primaryConsumer.interconnectResponse.Xcore_PD12M_ALL_PC_NC_Global.Xcore')),0);
               --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0);
                              UPDATE PR_REPRESTAMOS  
                                SET XCORE_GLOBAL = xcore,
                                    XCORE_CUSTOM =xcore
                              WHERE rowid = a.id;
                              COMMIT;
                            EXCEPTION WHEN OTHERS THEN   
                        DECLARE
                            vIdError      PLS_INTEGER := 0;
                        BEGIN                                    
                          
                          setError(pProgramUnit => 'ACTUALIZA_XCORE_DIRIGIDA', 
                                   pPieceCodeName => NULL, 
                                   pErrorDescription => SQLERRM ,                                                              
                                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                                   pEmailNotification => NULL, 
                                   pParamList => IA.LOGGER.vPARAMLIST, 
                                   pOutputLogger => FALSE, 
                                   pExecutionTime => NULL, 
                                   pIdError => vIdError); 
                        END;  
                      END ; 
                      COMMIT;
                      DBMS_OUTPUT.PUT_LINE ( SQLERRM);
                  END LOOP ;
                
              END LOOP;
                                      
  END ACTUALIZA_XCORE_DIRIGIDA;
  
  PROCEDURE ACTUALIZA_XCORE_CAMPANA_ESPECIAL IS --SROBLES
         --Represtamos En estado RE sin xcore ademi
               CURSOR VALIDACION_CLASIFICACION IS
               SELECT R.ID_REPRESTAMO,R.NO_CREDITO FROM PR_REPRESTAMOS R 
               WHERE  R.ESTADO = 'RE'
               AND NOT EXISTS( SELECT CODIGO_ESTADO FROM PR_BITACORA_REPRESTAMO WHERE CODIGO_ESTADO = 'CLS' AND ID_REPRESTAMO = R.ID_REPRESTAMO );
               
               CURSOR CUR_UPDATE_XCORE IS 
               SELECT A.ROWID ID,A.ID_REPRESTAMO, A.CODIGO_CLIENTE,A.ESTADO,A.XCORE_GLOBAL
               FROM PR.PR_REPRESTAMOS A
               WHERE A.ESTADO = 'RE' AND XCORE_GLOBAL IS NULL AND ROWNUM<= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE')); 
    
               vTotal_Carga NUMBER(10);
               vCantidad_Procesar NUMBER(10);
               Vlote_Proceso_Xcore NUMBER(10);
             
               xcore NUMBER(30);
    BEGIN
    Vlote_Proceso_Xcore := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_XCORE'));
           
                       BEGIN
                        SELECT COUNT(*) INTO vTotal_Carga FROM PR.PR_REPRESTAMOS A WHERE A.ESTADO = 'RE';
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                         vTotal_Carga:= 0;   
                            COMMIT;
                      END; 
                 
                 vCantidad_Procesar :=  round(vTotal_Carga / Vlote_Proceso_Xcore) + 1;     
             
                      
               FOR A IN VALIDACION_CLASIFICACION LOOP
                 PR_PKG_REPRESTAMOS.p_generar_bitacora(a.ID_REPRESTAMO,NULL,'RSB',NULL,'Cliente sin clasificación', USER);
                 UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO  AND ESTADO='T';
               END LOOP;
               
               FOR i IN 1..vCantidad_Procesar LOOP
               FOR A IN CUR_UPDATE_XCORE LOOP
               --DBMS_OUTPUT.PUT_LINE ( 'ACTUALIZA XCORE: ' );
                       BEGIN
                       xcore := 750;--NVL(TRIM(JSON_VALUE( PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON(PA.OBT_IDENTIFICACION_PERSONA(a.codigo_cliente,'1') ,'C','COMPATIBILIDAD',NULL,NULL,NULL,NULL,0), '$.respuesta.valor.applicants.primaryConsumer.interconnectResponse.Xcore_PD12M_ALL_PC_NC_Global.Xcore')),0);
               --NVL(PA_PKG_CONSULTA_DATACREDITO.OBTIENE_XCORE(PA.OBT_IDENTIFICACION_PERSONA(  a.codigo_cliente,'1')),0);
                              UPDATE PR_REPRESTAMOS  
                                SET XCORE_GLOBAL = xcore,
                                    XCORE_CUSTOM =xcore
                              WHERE rowid = a.id;
                              COMMIT;
                            EXCEPTION WHEN OTHERS THEN   
                        DECLARE
                            vIdError      PLS_INTEGER := 0;
                        BEGIN                                    
                          
                          setError(pProgramUnit => 'ACTUALIZA_XCORE_CAMPANA_ESPECIAL', 
                                   pPieceCodeName => NULL, 
                                   pErrorDescription => SQLERRM ,                                                              
                                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                                   pEmailNotification => NULL, 
                                   pParamList => IA.LOGGER.vPARAMLIST, 
                                   pOutputLogger => FALSE, 
                                   pExecutionTime => NULL, 
                                   pIdError => vIdError); 
                        END;  
                      END ; 
                      COMMIT;
                      DBMS_OUTPUT.PUT_LINE ( SQLERRM);
                  END LOOP ;
                
              END LOOP;
  
  
  END ACTUALIZA_XCORE_CAMPANA_ESPECIAL;
  
 PROCEDURE PVALIDA_XCORE(pIDAPLICACION IN OUT NUMBER) IS --SROBLES

            CURSOR c_clientes IS
                SELECT S.TIPO_CREDITO, C.GRUPO_TIPO_CREDITO,R.XCORE_GLOBAL,R.ID_REPRESTAMO
                FROM PR.PR_SOLICITUD_REPRESTAMO S
                JOIN pr_tipo_credito C ON C.TIPO_CREDITO = S.TIPO_CREDITO
                JOIN PR.PR_REPRESTAMOS R ON R.ID_REPRESTAMO = S.ID_REPRESTAMO
                WHERE C.GRUPO_TIPO_CREDITO IN ('C', 'P') AND R.ESTADO = 'RE'; -- Solo considera 'C' y 'P'

            v_tipo_credito VARCHAR2(200);
            v_grupo_tipo_credito VARCHAR2(200);
             --agregue esta variable
            pMensaje      VARCHAR2(100);
            --Defino la variable para capturar si existe un detalle
            --idCabeceraDet NUMBER;  
        BEGIN
        
        PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.VALIDA_XCORE',35,pMensaje);

            FOR cliente IN c_clientes LOOP
                v_tipo_credito := cliente.TIPO_CREDITO;
                v_grupo_tipo_credito := cliente.GRUPO_TIPO_CREDITO;
                --DBMS_OUTPUT.PUT_LINE ( 'cliente ' || cliente.ID_REPRESTAMO ||'  '|| CLIENTE.XCORE_GLOBAL );
                
                --Cambio el estado del detalle de la bitacora
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 70, 'EN PROCESO', pMensaje ); 
                
                -- Realizar la validación específica para cada tipo de crédito
                IF v_grupo_tipo_credito = 'C' AND NVL(CLIENTE.XCORE_GLOBAL,0) <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('XCORE_CREDITO_COMERCIAL')) OR CLIENTE.XCORE_GLOBAL IS NULL THEN
                --DBMS_OUTPUT.PUT_LINE ( ' ENTRO' );
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(CLIENTE.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Rechazado por Xcore inferior para Credito Comercial', USER);
                    DBMS_OUTPUT.PUT_LINE('Validación para clientes con tipo de crédito C');
            
            --Cambio el estado del detalle de la bitacora
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
            
                ELSIF v_grupo_tipo_credito = 'P' AND NVL(CLIENTE.XCORE_GLOBAL,0) <= TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('XCORE_CREDITO_CONSUMO')) OR CLIENTE.XCORE_GLOBAL IS NULL  THEN
                
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(CLIENTE.ID_REPRESTAMO, NULL, 'RXC', NULL, 'Rechazado por Xcore inferior para Credito de Consumo', USER);
                    DBMS_OUTPUT.PUT_LINE('Validación para clientes con tipo de crédito P');

                END IF;
                COMMIT;
            END LOOP;
        
         --ACTUALIZO EL DETALLE DE LA BITACORA
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );    
            
        --FINALIZO EL DETALLE DE LA BITACORA
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET ( pIDAPLICACION,'FINALIZADO', 'SE FINALIZO', pMensaje ); 
         
        EXCEPTION WHEN OTHERS THEN   
                DECLARE
                    vIdError      PLS_INTEGER := 0;
                BEGIN                                    
                  pMensaje:='ERROR CON EL STORE PROCEDURE PVALIDA_XCORE';
                  setError(pProgramUnit => 'PVALIDA_XCORE', 
                           pPieceCodeName => NULL, 
                           pErrorDescription => SQLERRM ,                                                              
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                           pEmailNotification => NULL, 
                           pParamList => IA.LOGGER.vPARAMLIST, 
                           pOutputLogger => FALSE, 
                           pExecutionTime => NULL, 
                           pIdError => vIdError); 
                           
                     --Capturo el error del detalle
                        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
                           
                END;   
        
     END PVALIDA_XCORE;
   
  PROCEDURE PVALIDA_WORLD_COMPLIANCE(pIDAPLICACION IN OUT NUMBER) IS
  
              CURSOR CARGAR_WORLD_COMPLIANCE IS
               SELECT R.ID_REPRESTAMO,R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
               FROM PR_REPRESTAMOS R 
               LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE
               LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
               LEFT JOIN CLIENTES_B2000 B ON B.CODIGO_CLIENTE = R.CODIGO_CLIENTE
               WHERE R.ESTADO = 'RE'
               AND WORLD_COMPLIANCE IS NULL
               AND ROWNUM <=  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));
               --AND NOT EXISTS( SELECT CODIGO_ESTADO FROM PR_BITACORA_REPRESTAMO WHERE CODIGO_ESTADO = 'CLS' AND ID_REPRESTAMO = R.ID_REPRESTAMO );
               
               CURSOR CUR_UPDATE_CREADOS IS 
               SELECT A.ROWID ID,A.ID_REPRESTAMO, A.CODIGO_CLIENTE,A.ESTADO,S.WORLD_COMPLIANCE
               FROM PR.PR_REPRESTAMOS A
               LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = A.ID_REPRESTAMO
               WHERE  A.ESTADO = 'RE'; 
       
       
        v_response    CLOB;
        vUrlAPI       VARCHAR2 (256);
        vKey          RAW (2000);
        vRutaWallet   VARCHAR2 (1000);
        vPassWallet   VARCHAR2 (200);
        vHigherPercent NUMBER;
        Vlote_WORLD_COMPLIANCE NUMBER(10);
        vTotal_Carga NUMBER(10);    
        vCantidad_Procesar NUMBER(10);      
        vRespuesta VARCHAR2(200);
        vPrimerNombre VARCHAR2(200);
        vSegundoNombre VARCHAR2(200);
        vPrimerApellido VARCHAR2(200);
        vSegundoApellido VARCHAR2(200);
        VALOR NUMBER;
        PMENSAJE VARCHAR2(500);
    BEGIN
    
        PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.VALIDA_WORLD_COMPLIANCE',30,pMensaje);
                         
    Vlote_WORLD_COMPLIANCE := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));
        BEGIN
         SELECT COUNT(*) INTO vTotal_Carga FROM PR.PR_REPRESTAMOS A WHERE A.ESTADO = 'RE';
         EXCEPTION WHEN NO_DATA_FOUND THEN
         vTotal_Carga:= 0;   
         COMMIT;
        END; 
     
      --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 60, 'EN PROCESO', pMensaje ); 
             
      vCantidad_Procesar :=  round(vTotal_Carga / Vlote_WORLD_COMPLIANCE) + 1;   
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
                  
                  setError(pProgramUnit => 'PVALIDA_WORLD_COMPLIANCE', 
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
            --DBMS_OUTPUT.PUT_LINE ( 'WORLD_COMPLIANCE ' || VALOR || ' id ' ||a.id_represtamo );
            --DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
            --DBMS_OUTPUT.PUT_LINE ('higherPercent = ' || VALOR);
         END LOOP ;
           
     END LOOP ;
     
       --Cambio el estado del detalle de la bitacora
        PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 90, 'EN PROCESO', pMensaje ); 
       
       FOR A IN CUR_UPDATE_CREADOS LOOP
       --DBMS_OUTPUT.PUT_LINE ( 'a.WORLD_COMPLIANCE = ' || a.WORLD_COMPLIANCE );
       --DBMS_OUTPUT.PUT_LINE ( 'a.ID = ' || a.ID_REPRESTAMO );
           IF NVL(a.WORLD_COMPLIANCE,0) > TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('WORLD_COMPLIANCE'))  THEN
           UPDATE PR.PR_REPRESTAMOS SET ESTADO= 'RXW' WHERE ID_REPRESTAMO = A.ID_REPRESTAMO;
            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXW', NULL, 'Credito cancelado por World Compliance', USER);
            COMMIT;
           END IF;
       END LOOP; 
       
       
       --ACTUALIZO LA BITACORA
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );
       
        --FINALIZO EL DETALLE DE LA BITACORA
            PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje ); 
      EXCEPTION WHEN OTHERS THEN   
                DECLARE
                    vIdError      PLS_INTEGER := 0;
                BEGIN                                    
                  pMensaje:='ERROR CON EL STORE PROCEDURE PVALIDA_WORLD_COMPLIANCE';
                  setError(pProgramUnit => 'PVALIDA_WORLD_COMPLIANCE', 
                           pPieceCodeName => NULL, 
                           pErrorDescription => SQLERRM ,                                                              
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                           pEmailNotification => NULL, 
                           pParamList => IA.LOGGER.vPARAMLIST, 
                           pOutputLogger => FALSE, 
                           pExecutionTime => NULL, 
                           pIdError => vIdError); 
             --Capturo el error del detalle
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje  );
                END;   
               
  END PVALIDA_WORLD_COMPLIANCE;
  
  PROCEDURE OBT_WORLD_COMPLIANCE(P_Identificacion     IN VARCHAR2,
                                 P_Primer_Nombre      IN VARCHAR2,
                                 P_Primer_Apellido    IN VARCHAR2,
                                 VALOR                OUT NUMBER, 
                                 PMENSAJE             OUT VARCHAR2) IS  --SROBLES 20/11/2023
                                      

               

       
       
        v_response    CLOB;
        vUrlAPI       VARCHAR2 (256);
        vKey          RAW (2000);
        vRutaWallet   VARCHAR2 (1000);
        vPassWallet   VARCHAR2 (200);
        vHigherPercent NUMBER;
    BEGIN
           
        --ACTUALIZO EL DETALLE DE LA BITACORA
        --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( 'ENPROCESO', 7, 'SE ACTUALIZO', pMensaje );
        
        
        
            -- Set Header with Token
            APEX_WEB_SERVICE.g_request_headers.delete ();
            APEX_WEB_SERVICE.g_request_headers (1).name := 'Content-Type';
            APEX_WEB_SERVICE.g_request_headers (1).VALUE := 'application/json';

            -- Desencriptar ruta y pass
            vKey := PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw ('CIFRADO_MASTERKEY');
            vRutaWallet := PA.DECIFRAR (PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw ('RUTA_WALLET'), vKey);
            vPassWallet := PA.DECIFRAR (PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw ('CLAVE_WALLET'), vKey); 
            vUrlAPI :=F_Obt_Parametro_Represtamo('RUTA_API_WorldCompliance')||'/api/WorldCompliance/GetReportURL?' ||'IdentificationNumber=' || P_Identificacion ||'&FIRSTNAME=' || P_Primer_Nombre ||'&LASTNAME=' || P_Primer_Apellido;
           --https://bmaqa0178.bancoademi.local:81/api/WorldCompliance/GetReportURL?
            v_response :=
                apex_web_service.make_rest_request (p_url           => vUrlAPI,
                                                    p_http_method   => 'GET',
                                                    p_wallet_path   => vRutaWallet,
                                                    p_wallet_pwd    => vPassWallet);
            
            APEX_JSON.PARSE(v_response);
            vHigherPercent := APEX_JSON.GET_NUMBER('higherPercent');
            --vRespuesta := APEX_JSON.GET_NUMBER('message');
            VALOR := vHigherPercent;
            --PMENSAJE := vRespuesta;
            
            --DBMS_OUTPUT.PUT_LINE ( 'WORLD_COMPLIANCE ' || vHigherPercent || ' id ' ||a.id_represtamo );
            DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
            DBMS_OUTPUT.PUT_LINE ('higherPercent = ' || vHigherPercent);
               --FINALIZO EL DETALLE DE LA BITACORA
        
      EXCEPTION WHEN OTHERS THEN   
                DECLARE
                    vIdError      PLS_INTEGER := 0;
                BEGIN                                    
                  pMensaje:='ERROR CON EL STORE PROCEDURE OBT_WORLD_COMPLIANCE';
                  setError(pProgramUnit => 'OBT_WORLD_COMPLIANCE', 
                           pPieceCodeName => NULL, 
                           pErrorDescription => SQLERRM ,                                                              
                           pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                           pEmailNotification => NULL, 
                           pParamList => IA.LOGGER.vPARAMLIST, 
                           pOutputLogger => FALSE, 
                           pExecutionTime => NULL, 
                           pIdError => vIdError); 
                           
                           --Capturo el error del detalle
             --PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( 'ERROR', 15, SQLERRM,pMensaje  );
                END;   
    END OBT_WORLD_COMPLIANCE;

  FUNCTION F_Genera_Secuencia RETURN NUMBER IS
        CURSOR cur_Secuencia is
            SELECT REPRESTAMOS_SEQ.NEXTVAL FROM DUAL;
    vSecuencia NUMBER(10);
    BEGIN
       OPEN  cur_Secuencia;
       FETCH cur_Secuencia into vSecuencia;
       CLOSE cur_Secuencia;
       vSecuencia := lpad(to_char(sysdate,'YYMM'),4,'0')|| lpad(vSecuencia,6,'0'); 
       RETURN vSecuencia;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'F_Genera_Secuencia', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Genera_Secuencia;
   --     
   --
   
   FUNCTION F_Genera_Secuencia_Carga_Dirigida RETURN NUMBER IS
           CURSOR cur_Secuencia is
            SELECT PA.SQ_CARGA_DIRIGIDA.NEXTVAL FROM DUAL;
    vSecuencia NUMBER(10);
    BEGIN
       OPEN  cur_Secuencia;
       FETCH cur_Secuencia into vSecuencia;
       CLOSE cur_Secuencia;
       --vSecuencia := lpad(to_char(sysdate,'YYMM'),4,'0')|| lpad(vSecuencia,6,'0'); 
       RETURN vSecuencia;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'F_Genera_Secuencia_Carga_Dirigida', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Genera_Secuencia_Carga_Dirigida;
    
   FUNCTION F_Genera_Secuencia_Campana_Especiales RETURN NUMBER IS
           CURSOR cur_Secuencia is
            SELECT PA.SQ_CAMPANA_ESPECIALES.NEXTVAL FROM DUAL;
    vSecuencia NUMBER(10);
    BEGIN
       OPEN  cur_Secuencia;
       FETCH cur_Secuencia into vSecuencia;
       CLOSE cur_Secuencia;
       --vSecuencia := lpad(to_char(sysdate,'YYMM'),4,'0')|| lpad(vSecuencia,6,'0'); 
       RETURN vSecuencia;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          
          setError(pProgramUnit => 'F_Genera_Secuencia_Campana_Especiales', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Genera_Secuencia_Campana_Especiales;
   FUNCTION F_Obt_Parametro_Represtamo(pCodigo IN VARCHAR) RETURN VARCHAR2 IS
     CURSOR CUR_parametro IS
        SELECT VALOR
        FROM PA_PARAMETROS_MVP
        WHERE CODIGO_EMPRESA = VCODIGOEMPRESA
        AND codigo_mvp  = vTipo_parametro
        and codigo_parametro = pCodigo; 
      vValor PA_PARAMETROS_MVP.valor%TYPE;
   BEGIN
     OPEN  CUR_parametro;
     FETCH CUR_parametro INTO vValor;
     CLOSE CUR_parametro;
     RETURN vValor;
   EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo',            pCodigo);       
          
          setError(pProgramUnit => 'F_Obt_Parametro_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
   END F_Obt_Parametro_Represtamo;
  --
  FUNCTION F_Obt_Valor_Parametros(pParametro IN VARCHAR2) RETURN  string_table pipelined
    as
      delimited_string_cleaned varchar2(32767);
      substring varchar2(4000);
      pos       pls_integer;
      separator        varchar2(2) default ',';
      delimited_string varchar2(4000);
    begin
      delimited_string := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo(pParametro);
      delimited_string_cleaned :=trim ( both separator from delimited_string ) ||separator;
      pos := instr ( delimited_string_cleaned, separator );
      substring := substr ( delimited_string_cleaned, 1, pos - 1 );
 
      loop
        exit when substring is null;
        pipe row ( substring );
      
        substring := substr ( 
          delimited_string_cleaned, 
          pos + 1, 
          instr ( 
            delimited_string_cleaned, separator, pos + 1 
          ) - pos - 1 
        );
        pos := instr ( delimited_string_cleaned, separator, pos + 1 );   
      end loop;

      return;
     EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pParametro',            pParametro);       
          
          setError(pProgramUnit => 'F_Obt_Valor_Parametros', 

                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;  

  END F_Obt_Valor_Parametros;
  
  FUNCTION F_Obt_Parametro_Represtamo_Raw(pCodigo IN VARCHAR) RETURN RAW IS
     CURSOR CUR_parametro IS
        SELECT VALOR_RAW
        FROM PA_PARAMETROS_MVP
        WHERE CODIGO_EMPRESA = VCODIGOEMPRESA
        AND codigo_mvp  = vTipo_parametro
        and codigo_parametro = pCodigo; 
      vValor PA_PARAMETROS_MVP.valor_raw%TYPE;
   BEGIN
     OPEN  CUR_parametro;
     FETCH CUR_parametro INTO vValor;
     CLOSE CUR_parametro;
     RETURN vValor;
   EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo',            pCodigo);       
          
          setError(pProgramUnit => 'F_Obt_Parametro_Represtamo_raw', 

                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
   END F_Obt_Parametro_Represtamo_Raw;
  
  FUNCTION F_Obt_Descripcion_Estado(pCodigo   IN VARCHAR2) RETURN VARCHAR2 IS
    vDescripcion        PR.PR_ESTADOS_REPRESTAMO.DES_ESTADO%TYPE;
  BEGIN
      BEGIN
          SELECT E.DES_ESTADO
            INTO vDescripcion
            FROM PR.PR_ESTADOS_REPRESTAMO E
           WHERE E.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
             AND E.CODIGO_ESTADO = pCodigo;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        vDescripcion := NULL;
      END;
      
      RETURN vDescripcion;
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo',            pCodigo);     
          
          setError(pProgramUnit => 'F_Obt_Descripcion_Estado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
  END F_Obt_Descripcion_Estado;
  --
   FUNCTION F_Obt_Telefono(pCodigo   IN VARCHAR2,pTipo IN VARCHAR2) RETURN VARCHAR2 IS
      v_telefono     VARCHAR2(100);
      v_valor        VARCHAR2(100);
  BEGIN
       DECLARE
        vid_represtamo VARCHAR2(100);
        --v_telefono      VARCHAR2(100);
        BEGIN
            select  RE.ID_REPRESTAMO, TP.COD_AREA || TP.NUM_TELEFONO  INTO  vid_represtamo,v_telefono
                                          FROM PR.PR_REPRESTAMOS RE 
                                          JOIN PA.TEL_PERSONAS TP ON TP.COD_PERSONA = RE.CODIGO_CLIENTE
                                          WHERE RE.CODIGO_CLIENTE   = pCodigo --'1002466' --:COD_PERSONA
                                          AND TP.TIP_TELEFONO = 'C'
                                          AND TP.FEC_INCLUSION = (SELECT MAX(EP.FEC_INCLUSION)FROM TEL_PERSONAS EP WHERE EP.COD_PERSONA   = pCodigo)--:COD_PERSONA);
                                          AND RE.ESTADO NOT IN ('AN','CRN');
                                         DBMS_OUTPUT.PUT_LINE ( 'vid_represtamo '|| vid_represtamo );
                                         DBMS_OUTPUT.PUT_LINE ( 'v_telefono '|| v_telefono );
                                         IF pTipo = 'I' THEN
                                            v_valor := vid_represtamo;                                    
                                         ELSE 
                                            IF pTipo = 'T' THEN
                                             v_valor := v_telefono;
                                             END IF;
                                          END IF;   
                                        DBMS_OUTPUT.PUT_LINE ( 'v_valor: '|| v_valor );
                                         EXCEPTION WHEN OTHERS THEN
                                         DBMS_OUTPUT.PUT_LINE(SQLERRM||' El represtamo esta en estado AN o CRN'||vid_represtamo);              
     END;  
     
     RETURN v_valor;
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo',            pCodigo);     
          IA.LOGGER.ADDPARAMVALUEV('pTipo',              pTipo); 
          setError(pProgramUnit => 'F_Obt_Telefono', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
  END F_Obt_Telefono;
  
 
 FUNCTION F_Validar_Telefono (pTelefono  IN VARCHAR2) RETURN VARCHAR2 IS
 vSubtring VARCHAR2(100);
     BEGIN
     DECLARE
       vSubtringSinParentesis VARCHAR2(100);
       BEGIN

       SELECT   REPLACE(REPLACE(pTelefono,'(',''),')','') INTO vSubtringSinParentesis FROM DUAL;
       
        SELECT REGEXP_SUBSTR (vSubtringSinParentesis,PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('EXPREG_TELEFONO'))INTO vSubtring FROM dual;
        DBMS_OUTPUT.PUT_LINE (  vSubtring );
        END;
        RETURN vSubtring;
     EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',          pTelefono);  
          setError(pProgramUnit => 'F_Validar_Telefono', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
     END F_Validar_Telefono; 
     
  FUNCTION F_Obt_Des_Precalificacion(pCodigo_cliente IN NUMBER) RETURN VARCHAR2 IS
     CURSOR CUR_Valor IS
       SELECT b.descripcion, CASE A.ESTADO WHEN 'CRD' THEN 'REPR¿STAMO DIGITAL' ELSE NULL END Desembolsado
        FROM   PR_REPRESTAMOS a,
               PR_CODIGOS_REPRESTAMO b
        WHERE a.codigo_empresa = 1
        and a.ESTADO != 'AP'
        AND a.ESTADO != vEstadoLinkVencido
        AND a.cODIGO_CLIENTE =pCodigo_cliente
        AND b.CODIGO_EMPRESA = a.codigo_empresa
        AND b.CODIGO_REPRESTAMO = a.codigo_precalificacion;
        
     vDescripcion   VARCHAR2(60);
     vDesembolso    VARCHAR2(60);
  BEGIN
    OPEN  CUR_Valor;
    FETCH CUR_Valor INTO vDescripcion, vDesembolso;
    CLOSE CUR_Valor;
    IF vDesembolso IS NOT NULL THEN
        vDescripcion := vDesembolso;
    ELSE
        IF vDescripcion IS NOT NULL THEN
          vDescripcion := 'PRECALIFICADO-'||vDescripcion;
        END IF;
    END IF;
    RETURN vDescripcion;
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEN('pCodigo_Cliente',       pCodigo_Cliente);                    
          
          setError(pProgramUnit => 'F_Obt_Des_Precalificacion', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
  END F_Obt_Des_Precalificacion;
  
  FUNCTION F_Obt_Empresa_Represtamo RETURN number IS
   BEGIN
     RETURN vCodigoEmpresa;
     
   EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          setError(pProgramUnit => 'F_Obt_Empresa_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
  END F_Obt_Empresa_Represtamo;
  
  FUNCTION F_Validar_Edad(pCodigo_cliente NUMBER,pTipo VARCHAR2 ) RETURN NUMBER IS 
  BEGIN
      DECLARE 
    FECHA DATE;
    EDAD NUMBER;
      BEGIN
        SELECT FEC_NACIMIENTO INTO FECHA FROM PA.PERSONAS_FISICAS WHERE COD_PER_FISICA = cast(pCodigo_cliente as varchar2(15));
        
        IF pTipo = 'CARGA' THEN
            IF FECHA IS NULL THEN 
            RETURN 0;
            
            ELSE 
             --DBMS_OUTPUT.PUT_LINE ( 'FECHA: ' || FECHA );
            --SELECT ROUND((SYSDATE - TO_DATE(FECHA))/365) INTO EDAD from DUAL;
            EDAD := PA.OBTENEREDAD(FECHA) ;
            --DBMS_OUTPUT.PUT_LINE ( 'EDAD1 ' || EDAD || ' CLIENTE : ' || pCodigo_cliente );
                IF EDAD BETWEEN  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('EDAD_MINIMA'))AND TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('EDAD_MAXIMA'))  THEN
                   RETURN 1;
                ELSE
                    RETURN 0;
                END IF;
                --DBMS_OUTPUT.PUT_LINE ( 'EDAD ' || EDAD || ' CLIENTE : ' || pCodigo_cliente );
            END IF;
        ELSIF   pTipo = 'SEGURO' THEN
           IF FECHA IS NULL THEN 
            RETURN 0;
            
            ELSE 
            EDAD := PA.OBTENEREDAD(FECHA) ;
                IF EDAD BETWEEN  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('EDAD_MINIMA_SEGURO'))AND TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('EDAD_MAXIMA_SEGURO'))  THEN
                   RETURN 1;
                ELSE
                    RETURN 0;
                END IF;
            END IF;
        END IF;
      END;
        
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo_cliente',     pCodigo_cliente);
          IA.LOGGER.ADDPARAMVALUEV('pTipo',               pTipo);
          setError(pProgramUnit => 'F_Validar_Edad', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
                   RETURN 0;
        END; 
        
  END F_Validar_Edad;
  
  FUNCTION f_Validar_Canal(pCanal  IN VARCHAR2)
     RETURN BOOLEAN IS
    vRetorno        BOOLEAN := FALSE;
    vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
    vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);
  BEGIN
    
    IF TO_NUMBER(pCanal) IN (vSMS, vEMAIL) THEN
        vRetorno := TRUE;
    ELSE
        vRetorno := FALSE;
    END IF;
  
    RETURN vRetorno;
    
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pCanal',     pCanal);                                    
          setError(pProgramUnit => 'f_Validar_Canal', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    
  END;       
  
  PROCEDURE P_Montos_Represtamos(
                            pNoCredito              IN     NUMBER,
                            pTipo_Credito           IN     NUMBER,
                            pCodigo_Cliente         IN     NUMBER,
                            pFechaPrestamo          IN     DATE DEFAULT Calendar.Fecha_Actual_Calendario('PR', '1', '50'),
                            pTasa                   IN     NUMBER,
                            pMontoPrestamo          IN     NUMBER,
                            pPlazo_Segun_Unidad     IN     NUMBER,    
                            pEsVida                 IN     VARCHAR2 DEFAULT 'S',
                            pEsDesempleo            IN     VARCHAR2 DEFAULT 'S',
                            nMontoCuota             OUT    NUMBER,
                            nMontoCargos            OUT    NUMBER,
                            nMontoCancelacion       OUT    NUMBER,
                            nMontoDepositar         OUT    NUMBER,
                            nMontoSeguroVida        OUT    NUMBER,
                            nMontoSeguroDesempleo   OUT    NUMBER,
                            nMontoMypime            Out    NUMBER,     
                            nMontoCuotaTotal        OUT    NUMBER,
                            PCalculaSeguroMypime  IN     VARCHAR2,
                            PCalculaSeguroDesempleo IN     VARCHAR2,                 
                            pMensajeError           IN OUT VARCHAR2) IS
                      
    --    
    pEmpresa              VARCHAR2(3) := PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo; 
    pFechaVenc            DATE   := ADD_MONTHS( NVL(pFechaPrestamo,SYSDATE), pPlazo_Segun_Unidad);
    pDiaExtra             NUMBER := 0;
    pPeriodicidad         PR.PR_PERIODICIDAD.DIAS_PERIODO%TYPE;
    pCodigoPeriodoCuota   PR_CREDITOS.CODIGO_PERIODO_CUOTA%type;
    pTipoCuota            PR_CREDITOS.TIPO_CUOTA%TYPE;
    pCod_Codeudor         NUMBER;
    pPlazoTotal           NUMBER := ( pFechaVenc - NVL(pFechaPrestamo,SYSDATE));
    MontoMypime           NUMBER;
  
  BEGIN
    -- Determina periodicidad
    
    BEGIN
    
     SELECT T1.DIAS_PERIODO,T1.Codigo_Periodo_Cuota, T1.TIPO_CUOTA
      INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
        FROM
    (
        SELECT P.DIAS_PERIODO, C.Codigo_Periodo_Cuota, C.TIPO_CUOTA
              --INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
              FROM PR.PR_PERIODICIDAD P, PR_CREDITOS c
              WHERE c.codigo_empresa = pEmpresa
              AND c.no_credito = pNoCredito
              AND P.CODIGO_PERIODO = C.Codigo_Periodo_Cuota
        UNION
            SELECT P.DIAS_PERIODO, C.Codigo_Periodo_Cuota, C.TIPO_CUOTA
              --INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
              FROM PR.PR_PERIODICIDAD P, PR_CREDITOS_HI c
              WHERE c.codigo_empresa = pEmpresa
              AND c.no_credito = pNoCredito
              AND P.CODIGO_PERIODO = C.Codigo_Periodo_Cuota
    ) T1 WHERE ROWNUM=1;
           
           
           
    EXCEPTION WHEN NO_DATA_FOUND THEN
        pMensajeError := 'Datos de la periodicidad no encontrados para el Crédito '||pNoCredito;
        RAISE_APPLICATION_ERROR(-20100, pMensajeError);
    END;
  
    -- Determina Dias Extra
    /*pDiaExtra  := PR_PKG_UTIL.F_CALCULAR_DIAS_EXTRA(  pEmpresa,
                                                      pTipo_Credito,
                                                      pCodigoPeriodoCuota,
                                                      0,
                                                      pMontoPrestamo,
                                                      pTasa,
                                                      NVL(pFechaPrestamo,SYSDATE));*/
    pDiaExtra  := 0;                                                        
   

     DBMS_OUTPUT.PUT_LINE ( 'pFechaPrestamo = ' || pFechaPrestamo );
     
     DBMS_OUTPUT.PUT_LINE ( 'pFechaVenc = ' || pFechaVenc );
     
     DBMS_OUTPUT.PUT_LINE ( 'pTasa = ' || pTasa );
     
     DBMS_OUTPUT.PUT_LINE ( 'pPlazoTotal = ' || pPlazoTotal );
     
     DBMS_OUTPUT.PUT_LINE ( ' pMontoPrestamo '||pMontoPrestamo );

    -- Calcular Cuotas
    nMontoCuota := PR_PKG_CUOTA.FN_CALCULA_CUOTA(  pF_Primer_Desem           => NVL(pFechaPrestamo,SYSDATE),
                                                   pF_Vencimiento            => pFechaVenc,
                                                   pGracia_Principal         => 0,
                                                   pSaldo_Real               => pMontoPrestamo,
                                                   pTipo_Cuota               => pTipoCuota,
                                                   pPeriodicidad             => pPeriodicidad,                --pr_periodicidad.dias_periodo,
                                                   pTasa                     => pTasa,
                                                   pTipo_Interes             => 'V',                  
                                                   pTipo_Calendario          => 4,
                                                   pPlazo_Total              => pPlazoTotal,
                                                   pF_Calculo                => NVL(pFechaPrestamo,SYSDATE),
                                                   pDias_Extra               => pDiaExtra,                          -- D+C
                                                   pPeriodo_Gracia_Interes   => 0,
                                                   pTipo_Gracia              => NULL);
    
    -- Calcular Seguro Vida
    pr_pkg_util.Calcular_Poliza (pEmpresa,
                                 pTipo_Credito,
                                 pCodigo_Cliente,
                                 pCod_Codeudor,
                                 pMontoPrestamo,
                                 pPlazo_Segun_Unidad,
                                 NVL(pFechaPrestamo,SYSDATE),
                                 pEsVida,
                                 pEsDesempleo,
                                 --OUT
                                 nMontoSeguroVida,
                                 nMontoSeguroDesempleo,
                                 pMensajeError);
    

    --Calcular Seguro Desempleo
    IF PCalculaSeguroDesempleo = 'S' THEN
    nMontoSeguroDesempleo := pr_pkg_util.calcular_seguro_desempleo(pEmpresa, pTipo_Credito, pMontoPrestamo, pCodigo_Cliente, NVL(pFechaPrestamo,SYSDATE), nMontoCuota, nMontoSeguroVida);
    ELSE 
    nMontoSeguroDesempleo := 0;
    END IF;

    ---Calcular Gastos Legales
    --pr_pkg_util.Generar_Cargos_2 (pEmpresa, pTipo_Credito, pMontoPrestamo, pMensajeError);
    pr_pkg_util.Generar_Cargos_5 (pEmpresa, pTipo_Credito, pMontoPrestamo,nMontoCargos, pMensajeError);
    
    --nMontoCargos := pr_pkg_util.Bkdesem.Monto_Cargos; --MALMANZAR 06-12-2022
    
    -- Calcular seguro MYPIME
    IF PCalculaSeguroMypime = 'S' THEN
        SELECT  MONTO_ASEGURADORA INTO nMontoMypime  FROM PR_COBERTURAS_X_TIPO_POLIZA WHERE TIPO_POLIZA = 17 AND  pMontoPrestamo BETWEEN MONTO_MINIMO_PAGAR AND MONTO_MAXIMO_PAGAR;
    ELSE
        nMontoMypime := 0;
    END IF;
    
    --Calcular Saldo Total Cr¿dito a Cancelar
    --DBMS_OUTPUT.PUT_LINE ( 'BANDERA 10pNoCredito = ' || pNoCredito );
    nMontoCancelacion := NVL(PR.pr_pagos_prestamos.F_SALDO_TOTAL_OPERACIONES ( pEmpresa, pNoCredito, NVL(pFechaPrestamo,SYSDATE)),0);
    
    -- (R.MTO_PREAPROBADO - (monto_descontar + gastos_cierre)  
    nMontoDepositar := pMontoPrestamo - (nMontoCancelacion + nMontoCargos);
    
    
    nMontoCuotaTotal := nMontoCuota + nMontoSeguroVida + nMontoSeguroDesempleo + nMontoMypime; 
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN   
          DBMS_OUTPUT.PUT_LINE ( DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);                                 
          IA.LOGGER.ADDPARAMVALUEV('pNoCredito',            pNoCredito);
          IA.LOGGER.ADDPARAMVALUEN('pTipo_Credito',         pTipo_Credito);
          IA.LOGGER.ADDPARAMVALUEN('pCodigo_Cliente',       pCodigo_Cliente);
          IA.LOGGER.ADDPARAMVALUED('pFechaPrestamo',        pFechaPrestamo);
          IA.LOGGER.ADDPARAMVALUEN('pTasa',                 pTasa);
          IA.LOGGER.ADDPARAMVALUEN('pMontoPrestamo',        pMontoPrestamo);
          IA.LOGGER.ADDPARAMVALUEN('pPlazo_Segun_Unidad',   pPlazo_Segun_Unidad);
          IA.LOGGER.ADDPARAMVALUEV('pEsVida',               pEsVida);
          IA.LOGGER.ADDPARAMVALUEV('pEsDesempleo',          pEsDesempleo);          
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroMypime',  PCalculaSeguroMypime);
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroDesempleo',  PCalculaSeguroDesempleo);
          
          setError(pProgramUnit => 'P_Montos_Represtamos', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
  END P_Montos_Represtamos;
  PROCEDURE P_Montos_Represtamos_Cancelado(
                            pNoCredito              IN     NUMBER,
                            pTipo_Credito           IN     NUMBER,
                            pCodigo_Cliente         IN     NUMBER,
                            pFechaPrestamo          IN     DATE DEFAULT Calendar.Fecha_Actual_Calendario('PR', '1', '50'),
                            pTasa                   IN     NUMBER,
                            pMontoPrestamo          IN     NUMBER,
                            pPlazo_Segun_Unidad     IN     NUMBER,    
                            pEsVida                 IN     VARCHAR2 DEFAULT 'S',
                            pEsDesempleo            IN     VARCHAR2 DEFAULT 'S',
                            nMontoCuota             OUT    NUMBER,
                            nMontoCargos            OUT    NUMBER,
                            nMontoCancelacion       OUT    NUMBER,
                            nMontoDepositar         OUT    NUMBER,
                            nMontoSeguroVida        OUT    NUMBER,
                            nMontoSeguroDesempleo   OUT    NUMBER,
                            nMontoMypime            Out    NUMBER,     
                            nMontoCuotaTotal        OUT    NUMBER,
                            PCalculaSeguroMypime  IN     VARCHAR2,
                            PCalculaSeguroDesempleo IN     VARCHAR2,                 
                            pMensajeError           IN OUT VARCHAR2) IS
                      
    --    
    pEmpresa              VARCHAR2(3) := PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo; 
    pFechaVenc            DATE   := ADD_MONTHS( NVL(pFechaPrestamo,SYSDATE), pPlazo_Segun_Unidad);
    pDiaExtra             NUMBER := 0;
    pPeriodicidad         PR.PR_PERIODICIDAD.DIAS_PERIODO%TYPE;
    pCodigoPeriodoCuota   PR_CREDITOS.CODIGO_PERIODO_CUOTA%type;
    pTipoCuota            PR_CREDITOS.TIPO_CUOTA%TYPE;
    pCod_Codeudor         NUMBER;
    pPlazoTotal           NUMBER := ( pFechaVenc - NVL(pFechaPrestamo,SYSDATE));
  
  BEGIN
    -- Determina periodicidad
    BEGIN
    
     SELECT T1.DIAS_PERIODO,T1.Codigo_Periodo_Cuota, T1.TIPO_CUOTA
      INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
        FROM
    (
        SELECT P.DIAS_PERIODO, C.Codigo_Periodo_Cuota, C.TIPO_CUOTA
              --INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
              FROM PR.PR_PERIODICIDAD P, PR_CREDITOS c
              WHERE c.codigo_empresa = pEmpresa
              AND c.no_credito = pNoCredito
              AND P.CODIGO_PERIODO = C.Codigo_Periodo_Cuota
        UNION
            SELECT P.DIAS_PERIODO, C.Codigo_Periodo_Cuota, C.TIPO_CUOTA
              --INTO pPeriodicidad, pCodigoPeriodoCuota, pTipoCuota
              FROM PR.PR_PERIODICIDAD P, PR_CREDITOS_HI c
              WHERE c.codigo_empresa = pEmpresa
              AND c.no_credito = pNoCredito
              AND P.CODIGO_PERIODO = C.Codigo_Periodo_Cuota
    ) T1 WHERE ROWNUM=1;
           
           
           
    EXCEPTION WHEN NO_DATA_FOUND THEN
        pMensajeError := 'Datos de la periodicidad no encontrados para el Crédito '||pNoCredito;
        RAISE_APPLICATION_ERROR(-20100, pMensajeError);
    END;
  
    -- Determina Dias Extra
    /*pDiaExtra  := PR_PKG_UTIL.F_CALCULAR_DIAS_EXTRA(  pEmpresa,
                                                      pTipo_Credito,
                                                      pCodigoPeriodoCuota,
                                                      0,
                                                      pMontoPrestamo,
                                                      pTasa,
                                                      NVL(pFechaPrestamo,SYSDATE));*/
    pDiaExtra  := 0;                                                        
   

     DBMS_OUTPUT.PUT_LINE ( 'pFechaPrestamo = ' || pFechaPrestamo );
     
     DBMS_OUTPUT.PUT_LINE ( 'pFechaVenc = ' || pFechaVenc );
     
     DBMS_OUTPUT.PUT_LINE ( 'pTasa = ' || pTasa );
     
     DBMS_OUTPUT.PUT_LINE ( 'pPlazoTotal = ' || pPlazoTotal );
     
     DBMS_OUTPUT.PUT_LINE ( ' pMontoPrestamo '||pMontoPrestamo );

 -- Calcular Cuotas
    nMontoCuota := PR_PKG_CUOTA.FN_CALCULA_CUOTA(  pF_Primer_Desem           => NVL(pFechaPrestamo,SYSDATE),
                                                   pF_Vencimiento            => pFechaVenc,
                                                   pGracia_Principal         => 0,
                                                   pSaldo_Real               => pMontoPrestamo,
                                                   pTipo_Cuota               => pTipoCuota,
                                                   pPeriodicidad             => pPeriodicidad,                --pr_periodicidad.dias_periodo,
                                                   pTasa                     => pTasa,
                                                   pTipo_Interes             => 'V',                  
                                                   pTipo_Calendario          => 4,
                                                   pPlazo_Total              => pPlazoTotal,
                                                   pF_Calculo                => NVL(pFechaPrestamo,SYSDATE),
                                                   pDias_Extra               => pDiaExtra,                          -- D+C
                                                   pPeriodo_Gracia_Interes   => 0,
                                                   pTipo_Gracia              => NULL);
    
    -- Calcular Seguro Vida
    pr_pkg_util.Calcular_Poliza (pEmpresa,
                                 pTipo_Credito,
                                 pCodigo_Cliente,
                                 pCod_Codeudor,
                                 pMontoPrestamo,
                                 pPlazo_Segun_Unidad,
                                 NVL(pFechaPrestamo,SYSDATE),
                                 pEsVida,
                                 pEsDesempleo,
                                 --OUT
                                 nMontoSeguroVida,
                                 nMontoSeguroDesempleo,
                                 pMensajeError);
    

            -- Calcular seguro MYPIME
    IF PCalculaSeguroMypime = 'S' THEN
        SELECT  MONTO_PCT INTO nMontoMypime  FROM PR_COBERTURAS_X_TIPO_POLIZA WHERE TIPO_POLIZA = 17 AND  pMontoPrestamo BETWEEN MONTO_MINIMO_PAGAR AND MONTO_MAXIMO_PAGAR;
    ELSE
        nMontoMypime := 0;
    END IF;
    
    --Calcular Seguro Desempleo
    IF PCalculaSeguroDesempleo = 'S' THEN
    nMontoSeguroDesempleo := pr_pkg_util.calcular_seguro_desempleo(pEmpresa, pTipo_Credito, pMontoPrestamo, pCodigo_Cliente, NVL(pFechaPrestamo,SYSDATE), nMontoCuota + nMontoMypime, nMontoSeguroVida);
    ELSE 
    nMontoSeguroDesempleo := 0;
    END IF;

    ---Calcular Gastos Legales
    --pr_pkg_util.Generar_Cargos_2 (pEmpresa, pTipo_Credito, pMontoPrestamo, pMensajeError);
    pr_pkg_util.Generar_Cargos_5 (pEmpresa, pTipo_Credito, pMontoPrestamo,nMontoCargos, pMensajeError);
    
    --nMontoCargos := pr_pkg_util.Bkdesem.Monto_Cargos; --MALMANZAR 06-12-2022
    

    
    --Calcular Saldo Total Cr¿dito a Cancelar
    --DBMS_OUTPUT.PUT_LINE ( 'BANDERA 10pNoCredito = ' || pNoCredito );
    nMontoCancelacion := NVL(PR.pr_pagos_prestamos.F_SALDO_TOTAL_OPERACIONES ( pEmpresa, pNoCredito, NVL(pFechaPrestamo,SYSDATE)),0);
    
    -- (R.MTO_PREAPROBADO - (monto_descontar + gastos_cierre)  
    nMontoDepositar := pMontoPrestamo - (nMontoCancelacion + nMontoCargos);
    
    
    nMontoCuotaTotal := nMontoCuota + nMontoSeguroVida + nMontoSeguroDesempleo + nMontoMypime; 
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN   
          DBMS_OUTPUT.PUT_LINE ( DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);                                 
          IA.LOGGER.ADDPARAMVALUEV('pNoCredito',            pNoCredito);
          IA.LOGGER.ADDPARAMVALUEN('pTipo_Credito',         pTipo_Credito);
          IA.LOGGER.ADDPARAMVALUEN('pCodigo_Cliente',       pCodigo_Cliente);
          IA.LOGGER.ADDPARAMVALUED('pFechaPrestamo',        pFechaPrestamo);
          IA.LOGGER.ADDPARAMVALUEN('pTasa',                 pTasa);
          IA.LOGGER.ADDPARAMVALUEN('pMontoPrestamo',        pMontoPrestamo);
          IA.LOGGER.ADDPARAMVALUEN('pPlazo_Segun_Unidad',   pPlazo_Segun_Unidad);
          IA.LOGGER.ADDPARAMVALUEV('pEsVida',               pEsVida);
          IA.LOGGER.ADDPARAMVALUEV('pEsDesempleo',          pEsDesempleo);
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroMypime',     PCalculaSeguroMypime);
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroDesempleo',  PCalculaSeguroDesempleo);          
          
          setError(pProgramUnit => 'P_Montos_Represtamos_Cancelado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
  END P_Montos_Represtamos_Cancelado;
  PROCEDURE P_Cargar_Opcion_Represtamo(pIdReprestamo     IN     VARCHAR2,
                                       pMensajeError     IN OUT VARCHAR2) IS
     PRAGMA AUTONOMOUS_TRANSACTION;
     
     CURSOR cOpciones(pId     IN     VARCHAR2) IS
     SELECT PL.PLAZO, r.NO_CREDITO, R.CODIGO_CLIENTE, PL.TIPO_CREDITO, R.MTO_PREAPROBADO, C.TASA_INTERES, 
            (SELECT COUNT(1) EXISTE 
              FROM PR.PR_OPCIONES_REPRESTAMO o 
             WHERE O.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo 
               AND o.id_represtamo = pId 
               AND o.plazo = PL.PLAZO) EXISTE, 
            ROWNUM ORDEN
       FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl, PR_CREDITOS c 
      WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND R.ID_REPRESTAMO = pId
        AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA
        AND C.NO_CREDITO = R.NO_CREDITO
        AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
         AND PL.TIPO_CREDITO = PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO (pIdReprestamo)
        AND PL.PLAZO = PL.PLAZO + 0
        AND R.MTO_PREAPROBADO >= PL.MONTO_MIN
        AND R.MTO_PREAPROBADO <= PL.MONTO_MAX
      ORDER BY 1;

     TYPE tOpciones IS TABLE OF cOpciones%ROWTYPE;
     vOpciones tOpciones := tOpciones();        
     
     nMontoCuota             NUMBER := 0;
     nMontoCargos            NUMBER := 0;
     nMontoCancelacion       NUMBER := 0;
     nMontoDepositar         NUMBER := 0;
     nMontoSeguroVida        NUMBER := 0;
     nMontoSeguroDesempleo   NUMBER := 0; 
     nMontoCuotaTotal        NUMBER := 0;
     vTasa                   NUMBER := 0;
     vVariacion_base         NUMBER := 0;
     vIndSeguroVida          VARCHAR2(3) := 'S';
     vIndSeguroDesempleo     VARCHAR2(3) := 'S';
     vExiste                 NUMBER := 0;
     vTipoCredito            NUMBER;
  BEGIN
        vIndSeguroVida := NVL(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_VIDA'),'S');
        vIndSeguroDesempleo := NVL(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_DESEMPLEO'),'S');
        
        OPEN cOpciones(pIdReprestamo);
        
        LOOP
            FETCH cOpciones BULK COLLECT INTO vOpciones LIMIT 5000;
            
            FOR i IN 1 .. vOpciones.COUNT LOOP
                
            IF  vTipoCredito IS NULL OR vTipoCredito <= 0 THEN
                vTipoCredito :=  vOpciones(i).TIPO_CREDITO;
            END IF;
                pMensajeError := NULL;
                
                vTasa := PR.F_obt_tasa_credito (vOpciones(i).TIPO_CREDITO, vVariacion_base);
--DBMS_OUTPUT.PUT_LINE('tasa = '|| vtasa);                
                /*BEGIN
                    p_montos_represtamos(
                                        vOpciones(i).NO_CREDITO,
                                        vOpciones(i).TIPO_CREDITO,
                                        vOpciones(i).CODIGO_CLIENTE,
                                        Calendar.Fecha_Actual_Calendario('PR', PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, '50'),
                                        vTasa,
                                        vOpciones(i).MTO_PREAPROBADO,
                                        vOpciones(i).PLAZO,    
                                        vIndSeguroVida,
                                        vIndSeguroDesempleo,
                                        nMontoCuota,
                                        nMontoCargos,
                                        nMontoCancelacion,
                                        nMontoDepositar,
                                        nMontoSeguroVida,
                                        nMontoSeguroDesempleo, 
                                        nMontoCuotaTotal,
                                                                  
                                        pMensajeError);
                EXCEPTION WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(SQLERRM||' '||pMensajeError);
                END;      */
                --DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError );                          
                DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError||'vOpciones(i).Existe:'||vOpciones(i).Existe );      
                              
                IF pMensajeError is null then                                  
                    
                    IF vOpciones(i).Existe = 0 THEN
                       DBMS_OUTPUT.PUT_LINE ( 'nMontoCuota = ' || nMontoCuota );
                        IF nMontoCuota > 0 THEN
                            BEGIN
                                INSERT INTO PR.PR_OPCIONES_REPRESTAMO
                                ( CODIGO_EMPRESA, ID_REPRESTAMO, PLAZO, MTO_PRESTAMO, MTO_DESCONTAR, 
                                  MTO_DEPOSITAR, MTO_CUOTA, MTO_CARGOS, MTO_SEGURO_VIDA, MTO_SEGURO_DESEMPLEO, MTO_CUOTA_TOTAL, TASA, ORDEN, ESTADO, ADICIONADO_POR, FECHA_ADICION)
                                VALUES
                                  (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, vOpciones(i).PLAZO, vOpciones(i).MTO_PREAPROBADO, nMontoCancelacion, 
                                   nMontoDepositar, nMontoCuota, nMontoCargos, nMontoSeguroVida, nMontoSeguroDesempleo, nMontoCuotaTotal,
                                   vTasa, vOpciones(i).ORDEN, 'A', USER, SYSDATE);
                                   COMMIT;
                            EXCEPTION WHEN OTHERS THEN
                                DBMS_OUTPUT.PUT_LINE(SQLERRM);
                                ROLLBACK;
                            END; 
                        END IF;
                    ELSE
                        IF nMontoCuota > 0 THEN
                            UPDATE PR.PR_OPCIONES_REPRESTAMO O
                               SET MTO_CUOTA = nMontoCuota,
                                   MTO_DESCONTAR = nMontoCancelacion,
                                   MTO_DEPOSITAR = nMontoDepositar,
                                   MTO_CARGOS = nMontoCargos, 
                                   MTO_SEGURO_VIDA = nMontoSeguroVida, 
                                   MTO_SEGURO_DESEMPLEO = nMontoSeguroDesempleo,
                                   MTO_CUOTA_TOTAL = nMontoCuotaTotal,
                                   TASA = vTasa
                             WHERE o.codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                               AND o.id_represtamo = pIdReprestamo 
                               AND o.plazo = vOpciones(i).PLAZO;
                               COMMIT; 
                        END IF;                              
                    END IF;
                END IF;                
                                                    
            END LOOP;
                        
            EXIT WHEN cOpciones%NOTFOUND;
            
        END LOOP;

        CLOSE cOpciones;
        UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TIPO_CREDITO = vTipoCredito WHERE S.ID_REPRESTAMO = pIdReprestamo; 
        COMMIT;                            
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          setError(pProgramUnit => 'P_Cargar_Opcion_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
        ROLLBACK;
  END P_Cargar_Opcion_Represtamo;

  PROCEDURE P_Actualizar_Opcion_Front (pNoCredito                IN     VARCHAR2,
                                        pTIPO_CREDITO             IN     VARCHAR2,
                                         pMonto                    IN     VARCHAR2,
                                         pPlazo                    IN     VARCHAR2,
                                         pMensajeError             IN OUT VARCHAR2) IS
                         
PRAGMA AUTONOMOUS_TRANSACTION;
   CURSOR cOpciones(pNoCredito     IN     VARCHAR2) IS
 SELECT PL.PLAZO, r.NO_CREDITO, R.CODIGO_CLIENTE, PL.TIPO_CREDITO, R.MTO_PREAPROBADO, C.TASA_INTERES,R.ID_REPRESTAMO,S.PLAZO AS PLAZO_SOLICITUD,
            (SELECT COUNT(1) EXISTE
              FROM PR.PR_OPCIONES_REPRESTAMO o
             WHERE O.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND o.id_represtamo = R.ID_REPRESTAMO
               AND o.plazo = pPlazo) EXISTE,
            ROWNUM ORDEN
       FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl, PR_CREDITOS c,PR_SOLICITUD_REPRESTAMO S
      WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND S.NO_CREDITO = pNoCredito
        AND S.ID_REPRESTAMO = R.ID_REPRESTAMO
        --AND R.ID_REPRESTAMO = pId
        AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA   
        AND C.NO_CREDITO = R.NO_CREDITO
        AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
        AND PL.TIPO_CREDITO = pTIPO_CREDITO
        AND pPlazo <= (SELECT MAX (PLAZO) FROM  pr.PR_PLAZO_CREDITO_REPRESTAMO )
        AND pMonto >= TO_NUMBER( PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MONTO_MINIMO'))
        --AND pMonto <= R.MTO_PREAPROBADO
 
 UNION
        
        SELECT PL.PLAZO, r.NO_CREDITO, R.CODIGO_CLIENTE, PL.TIPO_CREDITO, R.MTO_PREAPROBADO, H.TASA_INTERES,R.ID_REPRESTAMO,S.PLAZO AS PLAZO_SOLICITUD,
                    (SELECT COUNT(1) EXISTE
              FROM PR.PR_OPCIONES_REPRESTAMO o
             WHERE O.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND o.id_represtamo = R.ID_REPRESTAMO
               AND o.plazo = pPlazo) EXISTE,
            ROWNUM ORDEN
       FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl,PR_CREDITOS_HI H,PR_SOLICITUD_REPRESTAMO S
      WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND S.NO_CREDITO = pNoCredito
        AND S.ID_REPRESTAMO = R.ID_REPRESTAMO
        --AND R.ID_REPRESTAMO = pId
        AND H.CODIGO_EMPRESA = R.CODIGO_EMPRESA   
        AND H.NO_CREDITO = R.NO_CREDITO
        AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
        AND PL.TIPO_CREDITO = pTIPO_CREDITO
        AND pPlazo <= (SELECT MAX (PLAZO) FROM  pr.PR_PLAZO_CREDITO_REPRESTAMO )
        AND pMonto >= TO_NUMBER( PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MONTO_MINIMO'))
        AND pMonto <= R.MTO_PREAPROBADO
        
        
      ORDER BY 1;
     TYPE tOpciones IS TABLE OF cOpciones%ROWTYPE;
     vOpciones tOpciones := tOpciones();
     nMontoCuota             NUMBER := 0;
     nMontoCargos            NUMBER := 0;
     nMontoCancelacion       NUMBER := 0;
     nMontoDepositar         NUMBER := 0;
     nMontoSeguroVida        NUMBER := 0;
     nMontoSeguroDesempleo   NUMBER := 0;
     nMontoMypime            NUMBER := 0;
     nMontoCuotaTotal        NUMBER := 0;
     vTasa                   NUMBER := 0;
     vVariacion_base         NUMBER := 0;
     vIndSeguroVida          VARCHAR2(3) := 'S';
     vIndSeguroDesempleo     VARCHAR2(3);
     vExiste                 NUMBER := 0;
     vTipoCredito            NUMBER;
     vTipo_Credito           NUMBER;
     v_PLAZO                 NUMBER;
     vTipo_Mipyme            NUMBER;
     vTipo_Desempleo         NUMBER;
     vSeguroMipyme           VARCHAR2(3);
     vSeguroDesempleo        VARCHAR2(3);
      pIdReprestamo          VARCHAR2(400);
      
  
      
      
    BEGIN
  
 
         BEGIN
            SELECT COUNT(*) INTO vTipo_Mipyme FROM PR_POLIZAS_X_CREDITO WHERE NO_CREDITO = pNoCredito AND TIPO_POLIZA =17;
        EXCEPTION WHEN NO_DATA_FOUND THEN
              vTipo_Mipyme:= 0;
      END;   
      
       BEGIN
        SELECT COUNT(*) INTO vTipo_Desempleo FROM PR_POLIZAS_X_CREDITO WHERE TO_NUMBER(NO_CREDITO) = TO_NUMBER(pNoCredito) AND TO_NUMBER(TIPO_POLIZA) = 24;
        EXCEPTION WHEN NO_DATA_FOUND THEN
         vTipo_Desempleo:= 0;   
           
      END;   
        --SELECT ID_REPRESTAMO INTO pIdReprestamo FROM PR_REPRESTAMOS WHERE NO_CREDITO =pNoCredito ;
        vIndSeguroVida := NVL(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_VIDA'),'S');
        vIndSeguroDesempleo := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_DESEMPLEO');
         
        OPEN cOpciones(pNoCredito);
        LOOP
            FETCH cOpciones BULK COLLECT INTO vOpciones LIMIT 5000;
            FOR i IN 1 .. vOpciones.COUNT LOOP
            IF  vTipoCredito IS NULL OR vTipoCredito <= 0 THEN
                vTipoCredito :=  vOpciones(i).TIPO_CREDITO;
                --PtipoCredito :=  vOpciones(i).TIPO_CREDITO;
            END IF;
                pMensajeError := NULL;
                vTasa := PR.F_obt_tasa_credito (vOpciones(i).TIPO_CREDITO, vVariacion_base);
                
             
                
                IF vTipo_Mipyme > 0 THEN
                    vSeguroMipyme := 'S';
                ELSE
                vSeguroMipyme := 'N';
                END IF;
                DBMS_OUTPUT.PUT_LINE ( 'vTipo_Mipyme ' || vTipo_Mipyme);
                DBMS_OUTPUT.PUT_LINE ( 'vSeguroMipyme ' || vSeguroMipyme);
                
               
                IF vTipo_Desempleo > 0 THEN
                    vSeguroDesempleo := 'S';
                ELSE 
                 vSeguroDesempleo := 'N';
                END IF;
                

                --DBMS_OUTPUT.PUT_LINE ( 'vTipo_Desempleo ' || vTipo_Desempleo);
                --DBMS_OUTPUT.PUT_LINE ( 'vSeguroDesempleo ' || vSeguroDesempleo);

                BEGIN
                    p_montos_represtamos_cancelado(
                                        vOpciones(i).NO_CREDITO,
                                        vOpciones(i).TIPO_CREDITO,
                                        vOpciones(i).CODIGO_CLIENTE,
                                        Calendar.Fecha_Actual_Calendario('PR', PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, '50'),
                                        vTasa,
                                        pMonto,--vOpciones(i).MTO_PREAPROBADO,
                                        pPlazo,--vOpciones(i).PLAZO,
                                        vIndSeguroVida,
                                        vIndSeguroDesempleo,
                                        nMontoCuota,
                                        nMontoCargos,
                                        nMontoCancelacion,
                                        nMontoDepositar,
                                        nMontoSeguroVida,
                                        nMontoSeguroDesempleo,
                                        nMontoMypime,
                                        nMontoCuotaTotal,
                                        vSeguroMipyme,-- vSeguroMipyme,
                                        vSeguroDesempleo,
                                        pMensajeError);
                EXCEPTION WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(SQLERRM||' '||pMensajeError);
                END;
                --DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError );
                DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError||'vOpciones(i).Existe:'||vOpciones(i).Existe );
                IF pMensajeError is null then
                
                      UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.PLAZO = pPlazo,S. TIPO_CREDITO = pTIPO_CREDITO  WHERE S.ID_REPRESTAMO = vOpciones(i).ID_REPRESTAMO;   
                      COMMIT;             
                       DBMS_OUTPUT.PUT_LINE ( 'nMontoCuota = ' || nMontoCuota );
                        IF nMontoCuota > 0 THEN
                                        DBMS_OUTPUT.PUT_LINE ( vOpciones(i).ID_REPRESTAMO);
                                   UPDATE PR.PR_OPCIONES_REPRESTAMO
                                        SET    TASA                 = vTasa,
                                               PLAZO                = pPlazo,
                                               MTO_SEGURO_VIDA      = nMontoSeguroVida,
                                               MTO_SEGURO_MIPYME    = nMontoMypime,
                                               MTO_SEGURO_DESEMPLEO = nMontoSeguroDesempleo,
                                               MTO_PRESTAMO         = pMonto,
                                               MTO_DESCONTAR        = nMontoCancelacion,
                                               MTO_DEPOSITAR        = nMontoDepositar,
                                               MTO_CUOTA_TOTAL      = nMontoCuotaTotal,
                                               MTO_CUOTA            = nMontoCuota,
                                               MTO_CARGOS           = nMontoCargos,
                                               MODIFICADO_POR       = USER,
                                               FECHA_MODIFICACION   = SYSDATE
                                        WHERE  ID_REPRESTAMO        = vOpciones(i).ID_REPRESTAMO
                                        AND    PLAZO                = vOpciones(i).PLAZO_SOLICITUD
                                        ;
                                        UPDATE PR.PR_REPRESTAMOS
                                        SET    MTO_PREAPROBADO         = pMonto
                                        WHERE  ID_REPRESTAMO          = vOpciones(i).ID_REPRESTAMO
                                        ;
                          COMMIT;              
                        END IF;
                END IF;
            END LOOP;
            EXIT WHEN cOpciones%NOTFOUND;
            
        END LOOP;
        CLOSE cOpciones;
        --UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TIPO_CREDITO = vTipoCredito WHERE S.ID_REPRESTAMO = pIdReprestamo;
        COMMIT;
        IF nMontoCuotaTotal <=0 THEN
        pMensajeError := 'Opción no se pudo calcular por parámetros inválidos';
       -- status := 400;
        END IF;
        
        
        /* IF  Montodepositar < 0  THEN
            pMensajeError := 'El monto seleccionado no puede ser menor al monto que debe';
            --status := 400;
        END IF;*/
        
        
        
        EXCEPTION WHEN NO_DATA_FOUND THEN
        pMensajeError := 'Opcion no se pudo calcular por parametros invalidos';
        
         WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pNoCredito',    pNoCredito);
          IA.LOGGER.ADDPARAMVALUEV('pTIPO_CREDITO', pTIPO_CREDITO);
          IA.LOGGER.ADDPARAMVALUEV('pMonto',        pMonto);
          IA.LOGGER.ADDPARAMVALUEV('pPlazo',        pPlazo);
          setError(pProgramUnit => 'P_Actualizar_Opcion_Front',
                   pPieceCodeName => NULL,
                   pErrorDescription => SQLERRM,
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                   pEmailNotification => NULL,
                   pParamList => IA.LOGGER.vPARAMLIST,
                   pOutputLogger => FALSE,
                   pExecutionTime => NULL,
                   pIdError => vIdError);
          ROLLBACK;
        END;
        
    END P_Actualizar_Opcion_Front;
        FUNCTION F_ES_REPRESTAMO_DIGITAL(PNO_CREDITO IN NUMBER) RETURN VARCHAR2 IS
     vExiste VARCHAR2(10);
       BEGIN
        SELECT COUNT(1) INTO vExiste FROM PR_REPRESTAMOS R WHERE R.NO_CREDITO =  PNO_CREDITO AND R.ESTADO  IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_VALIDOS_CARTERA_DIGITAL')));
        
        IF vExiste >  0 THEN
            RETURN  'S';
        ELSE
            RETURN 'N';
        END IF;
       
        EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('PNO_CREDITO',   PNO_CREDITO);
          
          setError(pProgramUnit => 'F_ES_REPRESTAMO_DIGITAL', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
       END;
  PROCEDURE P_Calcular_Opcion_Front      (pIdReprestamo       IN     VARCHAR2,
                                        pMonto              IN     VARCHAR2,
                                        pPlazo               IN     VARCHAR2,
                                        PCalculaSeguroMypime  IN     VARCHAR2,
                                        PCalculaSeguroDesempleo IN     VARCHAR2,
                                        Montoaprobado       Out Varchar2,
                                        Montocancelacion    Out Varchar2,
                                        Montodepositar    Out Varchar2,
                                        Montocuota        Out Varchar2,
                                        Montocargo        Out Varchar2,
                                        MontoseguroVida   Out Varchar2,
                                        Montodesempleo    Out Varchar2,
                                        MontoMypime       Out Varchar2,
                                        Montocuotatotal   Out Varchar2,
                                        Tasa              Out Varchar2,
                                        Plazo             Out Varchar2,
                                        Monto             Out Varchar2,
                                        PtipoCredito      Out Varchar2,
                                        status                    OUT Varchar2,
                                        pMensajeError     IN OUT VARCHAR2)  IS
     PRAGMA AUTONOMOUS_TRANSACTION;
   CURSOR cOpciones(pId     IN     VARCHAR2) IS
     SELECT PL.PLAZO, r.NO_CREDITO, R.CODIGO_CLIENTE, PL.TIPO_CREDITO, R.MTO_PREAPROBADO, C.TASA_INTERES,
            (SELECT COUNT(1) EXISTE
              FROM PR.PR_OPCIONES_REPRESTAMO o
             WHERE O.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND o.id_represtamo = pId
               AND o.plazo = pPlazo) EXISTE,
            ROWNUM ORDEN
       FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl, PR_CREDITOS c
      WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND R.ID_REPRESTAMO = pId
        AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA   
        AND C.NO_CREDITO = R.NO_CREDITO
        AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
        AND PL.TIPO_CREDITO = PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO (pIdReprestamo,pMonto)
        AND pPlazo <= (SELECT MAX (PLAZO) FROM  pr.PR_PLAZO_CREDITO_REPRESTAMO )
        AND pMonto >= TO_NUMBER( PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MONTO_MINIMO'))
        AND pMonto <= R.MTO_PREAPROBADO
 
 UNION
        
        SELECT PL.PLAZO, r.NO_CREDITO, R.CODIGO_CLIENTE, PL.TIPO_CREDITO, R.MTO_PREAPROBADO, H.TASA_INTERES,
                    (SELECT COUNT(1) EXISTE
              FROM PR.PR_OPCIONES_REPRESTAMO o
             WHERE O.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND o.id_represtamo = pId
               AND o.plazo = pPlazo) EXISTE,
            ROWNUM ORDEN
       FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl,PR_CREDITOS_HI H
      WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        AND R.ID_REPRESTAMO = pId
        AND H.CODIGO_EMPRESA = R.CODIGO_EMPRESA   
        AND H.NO_CREDITO = R.NO_CREDITO
        AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
        AND PL.TIPO_CREDITO = PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO (pIdReprestamo,pMonto)
        AND pPlazo <= (SELECT MAX (PLAZO) FROM  pr.PR_PLAZO_CREDITO_REPRESTAMO )
        AND pMonto >= TO_NUMBER( PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MONTO_MINIMO'))
        AND pMonto <= R.MTO_PREAPROBADO
        
        
      ORDER BY 1;
     TYPE tOpciones IS TABLE OF cOpciones%ROWTYPE;
     vOpciones tOpciones := tOpciones();
     nMontoCuota             NUMBER := 0;
     nMontoCargos            NUMBER := 0;
     nMontoCancelacion       NUMBER := 0;
     nMontoDepositar         NUMBER := 0;
     nMontoSeguroVida        NUMBER := 0;
     nMontoSeguroDesempleo   NUMBER := 0;
     nMontoMypime            NUMBER := 0;
     nMontoCuotaTotal        NUMBER := 0;
     vTasa                   NUMBER := 0;
     vVariacion_base         NUMBER := 0;
     vIndSeguroVida          VARCHAR2(3) := 'S';
     vIndSeguroDesempleo     VARCHAR2(3) := 'S';
     vExiste                 NUMBER := 0;
     vTipoCredito            NUMBER;
     vTipo_Credito           NUMBER;
  BEGIN
        vIndSeguroVida := NVL(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_VIDA'),'S');
        vIndSeguroDesempleo := NVL(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SEGURO_DESEMPLEO'),'S');
        OPEN cOpciones(pIdReprestamo);
        LOOP
            FETCH cOpciones BULK COLLECT INTO vOpciones LIMIT 5000;
            FOR i IN 1 .. vOpciones.COUNT LOOP
            IF  vTipoCredito IS NULL OR vTipoCredito <= 0 THEN
                vTipoCredito :=  vOpciones(i).TIPO_CREDITO;
                PtipoCredito :=  vOpciones(i).TIPO_CREDITO;
            END IF;
                pMensajeError := NULL;
                vTasa := PR.F_obt_tasa_credito (vOpciones(i).TIPO_CREDITO, vVariacion_base);
                DBMS_OUTPUT.PUT_LINE('tasa = '|| vtasa);
                BEGIN
                    p_montos_represtamos_cancelado(
                                        vOpciones(i).NO_CREDITO,
                                        vOpciones(i).TIPO_CREDITO,
                                        vOpciones(i).CODIGO_CLIENTE,
                                        Calendar.Fecha_Actual_Calendario('PR', PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, '50'),
                                        vTasa,
                                        pMonto,--vOpciones(i).MTO_PREAPROBADO,
                                        pPlazo,--vOpciones(i).PLAZO,
                                        vIndSeguroVida,
                                        vIndSeguroDesempleo,
                                        nMontoCuota,
                                        nMontoCargos,
                                        nMontoCancelacion,
                                        nMontoDepositar,
                                        nMontoSeguroVida,
                                        nMontoSeguroDesempleo,
                                        nMontoMypime,
                                        nMontoCuotaTotal,
                                        PCalculaSeguroMypime,
                                        PCalculaSeguroDesempleo,
                                        pMensajeError);
                                         DBMS_OUTPUT.PUT_LINE ( 'nMontoCuotaTotal = ' || nMontoCuotaTotal );
                     COMMIT;
                EXCEPTION WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(SQLERRM||' '||pMensajeError);
                    DBMS_OUTPUT.PUT_LINE ( 'nMontoCuotaTotal = ' || nMontoCuotaTotal );
                    ROLLBACK;
                END;
                --DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError );
                DBMS_OUTPUT.PUT_LINE ( 'pMensajeError = ' || pMensajeError||'vOpciones(i).Existe:'||vOpciones(i).Existe );
                 --DBMS_OUTPUT.PUT_LINE ( 'nMontoCuotaTotal = ' || nMontoCuotaTotal );
                IF pMensajeError is null then
                    IF vOpciones(i).Existe = 0 THEN
                       DBMS_OUTPUT.PUT_LINE ( 'nMontoCuota = ' || nMontoCuota );
                       DBMS_OUTPUT.PUT_LINE ( 'nMontoCuotaTotal = ' || nMontoCuotaTotal );
                        IF nMontoCuota > 0 THEN
                                        Montoaprobado       := vOpciones(i).MTO_PREAPROBADO;
                                        Montocancelacion    := nMontoCancelacion;
                                        Montodepositar      := nMontoDepositar;
                                        Montocuota          := nMontoCuota;
                                        Montocargo          := nMontoCargos;
                                        MontoseguroVida     := nMontoSeguroVida;
                                        Montodesempleo      := nMontoSeguroDesempleo;
                                        MontoMypime         := nMontoMypime;
                                        Montocuotatotal     := nMontoCuotaTotal;
                                        Tasa                := vTasa;
                                        Plazo               := pPlazo; --vOpciones(i).PLAZO;
                                        Monto               := pMonto;
                        END IF;
                    END IF;
                END IF;
                COMMIT;
            END LOOP;
            EXIT WHEN cOpciones%NOTFOUND;
            
        END LOOP;
        CLOSE cOpciones;
        --UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TIPO_CREDITO = vTipoCredito WHERE S.ID_REPRESTAMO = pIdReprestamo;
        COMMIT;
        IF nMontoCuotaTotal <=0 THEN
        DBMS_OUTPUT.PUT_LINE ( 'nMontoCuotaTotal = ' || nMontoCuotaTotal );
        pMensajeError := 'Opción no se pudo calcular por parámetros inválidos';
        status := 400;
        END IF;
        
        
         IF  Montodepositar < 0  THEN
            pMensajeError := 'El monto seleccionado no puede ser menor al monto que debe';
            status := 400;
        END IF;
        
        COMMIT;
        
        EXCEPTION WHEN NO_DATA_FOUND THEN
        pMensajeError := 'Opcion no se pudo calcular por parametros invalidos';
        
         WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',         pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pMonto',                pMonto);
          IA.LOGGER.ADDPARAMVALUEV('pPlazo',                pPlazo);
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroMypime',  PCalculaSeguroMypime);
          IA.LOGGER.ADDPARAMVALUEV('PCalculaSeguroDesempleo', PCalculaSeguroDesempleo);
          
          setError(pProgramUnit => 'P_Calcular_Opcion_Front',
                   pPieceCodeName => NULL,
                   pErrorDescription => SQLERRM,
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                   pEmailNotification => NULL,
                   pParamList => IA.LOGGER.vPARAMLIST,
                   pOutputLogger => FALSE,
                   pExecutionTime => NULL,
                   pIdError => vIdError);
         ROLLBACK;
        END;
        
    END P_Calcular_Opcion_Front;
    
   PROCEDURE P_Carga_Opcion_Front     (pIdReprestamo           IN     VARCHAR2,
                                         Plazo                   IN Varchar2,
                                         MontoReprestamo         IN Varchar2,
                                         MontoDescontar          IN Varchar2,
                                         Montodepositar          IN Varchar2,
                                         Montocuota              IN Varchar2,
                                         Montocargo              IN Varchar2,
                                         MontoseguroVida         IN Varchar2,
                                         Montodesempleo          IN Varchar2,
                                         Tasa                    IN Varchar2,
                                         Montocuotatotal         IN Varchar2,
                                         MontoMipyme             IN Varchar2,
                                         pMensajeError           IN OUT VARCHAR2)IS
                                         
                                         
    v_PLAZO VARCHAR(20);
    v_Tipo_Credito NUMBER;
    BEGIN 
    
       INSERT INTO PR.PR_OPCIONES_REPRESTAMO
            (CODIGO_EMPRESA, ID_REPRESTAMO, PLAZO, MTO_PRESTAMO, MTO_DESCONTAR,MTO_DEPOSITAR, MTO_CUOTA, MTO_CARGOS, MTO_SEGURO_VIDA, MTO_SEGURO_DESEMPLEO,
             MTO_CUOTA_TOTAL, TASA, ORDEN, ESTADO, ADICIONADO_POR, FECHA_ADICION,MTO_SEGURO_MIPYME)
       VALUES
         (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, Plazo, MontoReprestamo, MontoDescontar, 
          Montodepositar, Montocuota, Montocargo, MontoseguroVida, Montodesempleo, Montocuotatotal,Tasa,1, 'A', USER, SYSDATE,MontoMipyme);
         COMMIT;
           
         v_Tipo_Credito :=  PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO (pIdReprestamo,MontoReprestamo);
         v_PLAZO := Plazo;
          UPDATE PR_SOLICITUD_REPRESTAMO s SET s.PLAZO = v_PLAZO , S.TIPO_CREDITO = v_Tipo_Credito  WHERE ID_REPRESTAMO = pIdReprestamo;
          COMMIT;
         
        IF F_Existe_Opciones(pIdReprestamo) THEN 
          --COLOCAR EL REPRESTAMO EN ESTADO SC LUEGO DE QUE SE CREE LA OPCION     
           /* UPDATE PR_REPRESTAMOS R SET ESTADO = 'SC' WHERE ID_REPRESTAMO =  pIdReprestamo;
            COMMIT;*/
            DECLARE
                pError VARCHAR2(20);
                vERRORDESCRIPTION VARCHAR2(20);
                vERRORCODE VARCHAR2(20);
            BEGIN
           PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(pIdReprestamo, NULL, 'SC', NULL, 'Cambiando a estado SC luego de cargar la opcion.', USER);
           COMMIT;
           EXCEPTION WHEN OTHERS THEN
                                pError := 'Linea ' || $$plsql_line || 'sqlerrm ' || SQLERRM || ' vERRORDESCRIPTION ' || vERRORDESCRIPTION || ' vERRORCODE ' || vERRORCODE;
           END;

        END IF;      
         COMMIT;
     EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('Plazo',     Plazo);
          IA.LOGGER.ADDPARAMVALUEV('MontoReprestamo',     MontoReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('MontoDescontar',     MontoDescontar);
          IA.LOGGER.ADDPARAMVALUEV('Montodepositar',     Montodepositar);
          IA.LOGGER.ADDPARAMVALUEV('Montocuota',     Montocuota);
          IA.LOGGER.ADDPARAMVALUEV('Montocargo',     Montocargo);
          IA.LOGGER.ADDPARAMVALUEV('MontoseguroVida',     MontoseguroVida);
          IA.LOGGER.ADDPARAMVALUEV('Montodesempleo',     Montodesempleo);
          IA.LOGGER.ADDPARAMVALUEV('Tasa',     Tasa);
          IA.LOGGER.ADDPARAMVALUEV('Montocuotatotal',     Montocuotatotal);
          IA.LOGGER.ADDPARAMVALUEV('MontoMipyme',     MontoMipyme);
          
          setError(pProgramUnit => 'P_Carga_Opcion_Front', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
                            
  END P_Carga_Opcion_Front;
  PROCEDURE P_Validar_Idreprestamos(pIdReprestamo     IN VARCHAR2,
                                    pCanal            IN VARCHAR2,
                                    pNombres          IN OUT VARCHAR2,
                                    pApellidos        IN OUT VARCHAR2,
                                    pIdentificacion   IN OUT VARCHAR2,
                                    pSexo             IN OUT VARCHAR2,
                                    pMonto            IN OUT NUMBER,
                                    pIntentosIdent    IN OUT NUMBER,
                                    pIntentosPin      IN OUT NUMBER,
                                    pPinTiempo        IN OUT NUMBER,
                                    pEstado           IN OUT VARCHAR2,
                                    pDescEstado       IN OUT VARCHAR2,
                                    pStep             IN OUT VARCHAR2,
                                    pTipoRelacion     IN OUT VARCHAR2,
                                    pOrigenFiador     IN OUT VARCHAR2,
                                    pOrigenCampana    IN OUT VARCHAR2,
                                    pMensaje          IN OUT VARCHAR2) IS    
    vCodCliente             CLIENTES_B2000.COD_CLIENTE%TYPE;
    vFec_Nacimiento         CLIENTES_B2000.FECHA_DE_NACIMIENTO%TYPE;
    vNacionalidad           VARCHAR2(60);
    vEstadoCivil            CLIENTES_B2000.ESTADO_CIVIL%TYPE;
                                             
  BEGIN
      
      pPinTiempo := NVL(f_obt_parametro_Represtamo('TIEMPO_EXPIRA_PIN'), 12000);
      
      BEGIN
          SELECT R.CODIGO_CLIENTE, R.MTO_PREAPROBADO, 
                 R.INTENTOS_IDENTIFICACION, R.INTENTOS_PIN, R.ESTADO, f_obt_descripcion_estado(R.ESTADO)
            INTO vCodCliente, pMonto, pIntentosIdent, pIntentosPin, pEstado, pDescEstado
            FROM PR.PR_REPRESTAMOS r, PR.PR_CANALES_REPRESTAMO cr -- TODO: Incluir la tabla de los canales por donde se notific¿ al cliente
           WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
             AND R.ID_REPRESTAMO = pIdReprestamo             
             AND cr.CODIGO_EMPRESA = R.CODIGO_EMPRESA
             AND cr.ID_REPRESTAMO =  r.ID_REPRESTAMO
             AND cr.CANAL = pCanal;
      
      EXCEPTION WHEN NO_DATA_FOUND THEN        
        pPinTiempo := 12000;
        vCodCliente := NULL;
      END; 
      
      IF vCodCliente IS NOT NULL THEN
          p_datos_primarios(vCodCliente,
                            pNombres,
                            pApellidos,
                            pIdentificacion,
                            pSexo,
                            vFec_Nacimiento,
                            vNacionalidad,
                            vEstadoCivil,
                            pMensaje);

        
      END IF; 
           
     /*  BEGIN
                SELECT 
                    CASE
                        WHEN R.ES_FIADOR = 'S' AND B.OBSERVACIONES = 'B' THEN 'TRUE'
                        ELSE 'FALSE'
                    END
                INTO 
                    pTipoRelacion
                FROM PR.PR_REPRESTAMOS R
                LEFT JOIN PR.PR_BITACORA_REPRESTAMO B ON B.ID_REPRESTAMO = R.ID_REPRESTAMO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        pTipoRelacion := 'FALSE';
            END;*/
            
       /*   BEGIN
                SELECT 
                    CASE
                        WHEN R.ES_FIADOR = 'S' AND R.CODIGO_PRECALIFICACION =  01 THEN 'TRUE'
                        ELSE 'FALSE'
                    END
                INTO 
                    pOrigenFiador
                FROM PR.PR_REPRESTAMOS R
                WHERE R.ID_REPRESTAMO = pIdReprestamo;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        pOrigenFiador := 'FALSE';
            END;*/
        BEGIN
                SELECT 
                    CASE
                        WHEN R.ID_REPRE_CAMPANA_ESPECIALES IS NOT NULL THEN 'TRUE'
                        ELSE 'FALSE'
                    END
                INTO
                    pOrigenCampana
                FROM PR.PR_REPRESTAMOS R
                WHERE R.ID_REPRESTAMO = pIdReprestamo;
            
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    pOrigenCampana := 'FALSE';
        END;
        
      pTipoRelacion := 'FALSE';
      
      
        DBMS_OUTPUT.PUT_LINE(pEstado);      
      pStep := PR.PR_PKG_REPRESTAMOS.f_Step_Actual(pEstado, pIdReprestamo);      
                                
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',    pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',           pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',         pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',       pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pIdentificacion',  pIdentificacion);
          IA.LOGGER.ADDPARAMVALUEV('pSexo',            pSexo);
          IA.LOGGER.ADDPARAMVALUEV('pIntentosIdent',   pIntentosIdent);
          IA.LOGGER.ADDPARAMVALUEV('pIntentosPin',     pIntentosPin);
          IA.LOGGER.ADDPARAMVALUEV('pPinTiempo',       pPinTiempo);
          IA.LOGGER.ADDPARAMVALUEV('pEstado',          pEstado);
          IA.LOGGER.ADDPARAMVALUEV('pDescEstado',      pDescEstado);
          IA.LOGGER.ADDPARAMVALUEV('pStep',            pStep);
          IA.LOGGER.ADDPARAMVALUEV('pOrigenFiador',    pOrigenFiador);
          IA.LOGGER.ADDPARAMVALUEV('pOrigenCampana',   pOrigenCampana);
          IA.LOGGER.ADDPARAMVALUEV('pTipoRelacion',    pTipoRelacion);
          
          setError(pProgramUnit => 'P_Validar_Idreprestamos', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;       
  END P_Validar_Idreprestamos;
  
  FUNCTION F_Validar_Pin(pIdReprestamo     IN VARCHAR2,
                         pCanal            IN VARCHAR2,
                         pIdentificacion   IN VARCHAR2,
                         pPin              IN VARCHAR2)
      RETURN BOOLEAN IS
    vRetorno        PLS_INTEGER := 0;

  BEGIN
        BEGIN
            SELECT 1
              INTO vRetorno
              FROM PR.PR_REPRESTAMOS r, 
                   PR_CANALES_REPRESTAMO cr,  
                   PR_SOLICITUD_REPRESTAMO c
             WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND R.ID_REPRESTAMO = pIdReprestamo
               AND R.PIN = pPin             
               AND cr.CODIGO_EMPRESA = R.CODIGO_EMPRESA
               AND cr.ID_REPRESTAMO  =  r.ID_REPRESTAMO
               AND cr.CANAL          = pCanal
               AND C.id_represtamo   = r.ID_REPRESTAMO
               AND c.identificacion  = REPLACE(pIdentificacion,'-');
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vRetorno := 0;             
        END;
    
    DBMS_OUTPUT.PUT_LINE('IdReprestamo='||pIdReprestamo||' pCanal='||pCanal||' pPin='||pPin||' pIdentificacion='||pIdentificacion||' Validar PIN '||vRetorno);
    --  TRUE = PIN Validado
    RETURN (vRetorno > 0);
  
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',            pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pIdentificacion',   pIdentificacion);
          IA.LOGGER.ADDPARAMVALUEV('pPin',              pPin);
          setError(pProgramUnit => 'F_Validar_Pin', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
  END F_Validar_Pin;            
  
  PROCEDURE P_Datos_Primarios(pCodCliente       IN     VARCHAR2,
                              pNombres          IN OUT VARCHAR2,
                              pApellidos        IN OUT VARCHAR2,
                              pIdentificacion   IN OUT VARCHAR2,
                              pSexo             IN OUT VARCHAR2,
                              pFec_Nacimiento   IN OUT DATE,
                              pNacionalidad     IN OUT VARCHAR2,
                              pEstadoCivil      IN OUT VARCHAR2,
                              pMensaje          IN OUT VARCHAR2) IS
    vPrimer_Apellido        PA.PERSONAS_FISICAS.PRIMER_APELLIDO%TYPE;
    vSegundo_Apellido       PA.PERSONAS_FISICAS.SEGUNDO_APELLIDO%TYPE;
    vCasada_Apellido        PA.PERSONAS_FISICAS.APELLIDO_CASADA%TYPE;                                                          
  BEGIN      
      
      IF pCodCliente IS NOT NULL THEN
          BEGIN
              SELECT REPLACE(C.NUMERO_IDENTIFICACION,'-'), C.NOMBRES, C.PRIMER_APELLIDO||' '||C.SEGUNDO_APELLIDO|| CASE NVL(C.APELLIDO_DE_CASADA,'0') WHEN '0' THEN '' ELSE 'DE '||C.APELLIDO_DE_CASADA END,
                     C.SEXO, C.FECHA_DE_NACIMIENTO, C.ESTADO_CIVIL, pf.NACIONALIDAD
                INTO pIdentificacion, pNombres, pApellidos, pSexo,  pFec_Nacimiento, pEstadoCivil, pNacionalidad
                FROM CLIENTES_B2000 c, PERSONAS_FISICAS Pf 
               WHERE C.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                 AND C.CODIGO_CLIENTE = pCodCliente
                 AND PF.COD_PER_FISICA = C.CODIGO_CLIENTE;
          EXCEPTION WHEN NO_DATA_FOUND THEN
              pIdentificacion := NULL;
          END;
      ELSE
        pMensaje := 'Datos del cliente no encontrados.';
      END IF; 
      
--      IF pIdentificacion IS NOT NULL THEN
--          BEGIN
--              pa_utl.obtiene_info_padron_rd (pIdentificacion,
--                                             vPrimer_Apellido, 
--                                             vSegundo_Apellido,          
--                                             vCasada_Apellido, 
--                                             pNombres,
--                                             pSexo,
--                                             pFec_Nacimiento);
--              
--              pApellidos := vPrimer_Apellido||' '||vSegundo_Apellido;
--              
--              IF vCasada_Apellido IS NOT NULL THEN
--                pApellidos := 'DE '||vCasada_Apellido;
--              END IF;
--                                                       
--          EXCEPTION WHEN OTHERS THEN
--            pNombres := NULL;
--            pApellidos := NULL;
--            pSexo := NULL;
--            pFec_Nacimiento := NULL;
--          END; 
--      END IF;  
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodCliente',       pCodCliente);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pIdentificacion',   pIdentificacion);
          IA.LOGGER.ADDPARAMVALUEV('pSexo',             pSexo);
          IA.LOGGER.ADDPARAMVALUED('pFec_Nacimiento',   pFec_Nacimiento);
          IA.LOGGER.ADDPARAMVALUEV('pNacionalidad',     pNacionalidad);
          IA.LOGGER.ADDPARAMVALUEV('pEstadoCivil',      pEstadoCivil);          
          
          setError(pProgramUnit => 'P_Datos_Primarios', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
  END P_Datos_Primarios;

  PROCEDURE P_Datos_Secundarios(pCodCliente         IN     VARCHAR2,
                                pTelefonoCelular    IN OUT VARCHAR2,
                                pTelefonoResidencia IN OUT VARCHAR2,
                                pTelefonoTrabajo    IN OUT VARCHAR2,
                                pCorreo             IN OUT VARCHAR2,
                                pCodDireccion       IN OUT VARCHAR2,
                                pTipDireccion       IN OUT VARCHAR2,
                                pDireccion          IN OUT VARCHAR2,
                                pMensaje            IN OUT VARCHAR2) IS                                   
  CURSOR CUR_email IS
      SELECT C.EMAIL_USUARIO, 
                 NVL(PA.obt_telefono_persona(C.COD_PER_FISICA, 'C'), 'N/A') telefono_celular,
                 NVL(NVL(PA.obt_telefono_persona(C.COD_PER_FISICA, 'D'), NVL(PA.obt_telefono_persona(C.COD_PER_FISICA, 'R'), PA.obt_telefono_persona(C.COD_PER_FISICA, 'T'))), 'N/A') telefono_residencia,
                 NVL(NVL(PA.obt_telefono_persona(C.COD_PER_FISICA, 'O'), PA.obt_telefono_persona(C.COD_PER_FISICA, 'X')), 'N/A') telefono_oficina,
                 obt_direccion_actualizada(C.COD_PER_FISICA) detalle--D.DETALLE DIRECCION-- D.COD_DIRECCION, D.TIP_DIRECCION
            FROM PERSONAS_FISICAS c
           WHERE C.COD_PER_FISICA = pCodCliente;
  BEGIN
     --  Consulta del datos secundarios del Core 
     OPEN  CUR_email;
     FETCH CUR_email INTO pCorreo, pTelefonoCelular, pTelefonoResidencia, pTelefonoTrabajo, pDireccion;
     CLOSE CUR_email;
  EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodCliente',           pCodCliente);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoCelular',      pTelefonoCelular);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoResidencia',   pTelefonoResidencia);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoTrabajo',      pTelefonoTrabajo);
          IA.LOGGER.ADDPARAMVALUEV('pCorreo',               pCorreo);
          IA.LOGGER.ADDPARAMVALUEV('pCodDireccion',         pCodDireccion);
          IA.LOGGER.ADDPARAMVALUEV('pTipDireccion',         pTipDireccion);
          IA.LOGGER.ADDPARAMVALUEV('pDireccion',            pDireccion);          
          
          setError(pProgramUnit => 'P_Datos_Secundarios', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
  END P_Datos_Secundarios;  
  PROCEDURE P_Obtener_Nombres_Cliente(pNum_Represtamo        IN     VARCHAR2,
                                  pPrimerNombre       OUT VARCHAR2,
                                  pSegundoNombre      OUT VARCHAR2,
                                  pPrimerApellido     OUT VARCHAR2,
                                  pSegundoApellido    OUT VARCHAR2
                                  )
                                  IS
            PNombres             VARCHAR2(100);
            PApellidos           VARCHAR2(100);
        BEGIN
        
            SELECT TRIM(REPLACE(PA.OBT_NOMBRE_PERSONA(R.CODIGO_CLIENTE),SR.APELLIDOS)) AS NOMBRES,SR.APELLIDOS INTO PNombres,PApellidos FROM PR.PR_SOLICITUD_REPRESTAMO SR
            JOIN PR_REPRESTAMOS R ON R.ID_REPRESTAMO=SR.ID_REPRESTAMO
            WHERE SR.ID_REPRESTAMO= pNum_Represtamo;
        
            --SELECT NOMBRES,APELLIDOS INTO PNombres,PApellidos FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO= 
            pPrimerNombre:= TRIM(REGEXP_SUBSTR(PNombres,'[^ ]+',1,1));
            pSegundoNombre:= TRIM(TRIM(REGEXP_SUBSTR(PNombres,'[^ ]+',1,2))||' '||TRIM(REGEXP_SUBSTR(PNombres,'[^ ]+',1,3))||' '||TRIM(REGEXP_SUBSTR(PNombres,'[^ ]+',1,4)));

            IF LENGTH(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,1)))>3 THEN
                pPrimerApellido:=TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,1));
                pSegundoApellido:=TRIM(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,2))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,3))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,4)));
            ELSIF LENGTH(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,1)))<=3 AND LENGTH(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,2)))<=3 THEN
                pPrimerApellido:=TRIM(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,1))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,2))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,3)));
                pSegundoApellido:=TRIM(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,4))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,5))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,6)));
            ELSE
                pPrimerApellido:=TRIM(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,1))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,2)));
                pSegundoApellido:=TRIM(TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,3))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,4))||' '||TRIM(REGEXP_SUBSTR(PApellidos,'[^ ]+',1,5)));
            END IF;
            
       EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pNum_Represtamo',       pNum_Represtamo);
          IA.LOGGER.ADDPARAMVALUEV('pPrimerNombre',         pPrimerNombre);
          IA.LOGGER.ADDPARAMVALUEV('pSegundoNombre',        pSegundoNombre);  
          IA.LOGGER.ADDPARAMVALUEV('pPrimerApellido',       pPrimerApellido);  
          IA.LOGGER.ADDPARAMVALUEV('pSegundoApellido',      pSegundoApellido);  
          
          setError(pProgramUnit => 'P_Obtener_Nombres_Cliente', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
                 
   END P_Obtener_Nombres_Cliente;

  FUNCTION P_Solicitar_Pin(pIdReprestamo     IN VARCHAR2,
                           pCanal            IN VARCHAR2,
                           pUsuario          IN VARCHAR2,
                           pRespuesta        IN OUT VARCHAR2,
                           pObservacion      IN  VARCHAR2 DEFAULT 'Solicitado nuevo PIN')
     RETURN VARCHAR2 IS
      vPIN          VARCHAR2(10) := NULL;
      vContacto     PR_CANALES_REPRESTAMO.VALOR%TYPE;
      vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
      vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);
      vSubject      VARCHAR2(4000);
      vMensaje      VARCHAR2(4000);
      vNotificacion PA.tNotificacion := PA.tNotificacion();
      vNombres      PR_SOLICITUD_REPRESTAMO.NOMBRES%TYPE;
      vApellidos    PR_SOLICITUD_REPRESTAMO.APELLIDOS%TYPE;
      vLinkActivado NUMBER := 0;
      vIdReprestamo VARCHAR2(4000);
    BEGIN
        IF f_Validar_Canal(pCanal) = FALSE THEN
            pRespuesta := 'Debe especificar el canal v¿lido';
            RETURN vPin;
        END IF;
        BEGIN
            -- Determinar nuevo PIN a traves de la notificacion Inicial
            SELECT lpad(PKG_NOTIFICACIONES.GENERAR_PIN_RANDOM(100,999999), 6, '0'), c.VALOR, s.NOMBRES, S.APELLIDOS
              INTO vPIN, vContacto, vNombres, vApellidos
              FROM PR_CANALES_REPRESTAMO c, PR_SOLICITUD_REPRESTAMO s
             WHERE c.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND c.ID_REPRESTAMO =  pIdReprestamo
               AND c.CANAL = pCanal
               AND S.CODIGO_EMPRESA = c.CODIGO_EMPRESA
               AND S.ID_REPRESTAMO = C.ID_REPRESTAMO;  
        EXCEPTION WHEN NO_DATA_FOUND THEN
             vPIN := NULL;   
             pRespuesta := 'Error obteniendo los datos del PIN en la maestra de represtamos';             
             RAISE_APPLICATION_ERROR(-20100, pRespuesta);
            
        END;
        
        IF vPIN IS NOT NULL THEN
        
            vLinkActivado := PR.PR_PKG_REPRESTAMOS.P_Total_Estado_Bitacora_ID('LA', pIdReprestamo);
            IF vLinkActivado = 0 THEN
                PR_PKG_REPRESTAMOS.p_generar_bitacora( pIdReprestamo, pCanal, 'LA', '0', 'Inicio del Proceso del cliente', pRespuesta );
            END IF;
            
            vNotificacion.CONTACTO := vContacto;
            vNotificacion.NOMBRES := vNombres;
            vNotificacion.APELLIDOS := vApellidos;
            vNotificacion.FECHA_ENVIO := SYSDATE;
            vNotificacion.FECHA_RECEPCION := NULL;
            vNotificacion.ESTADO := 'NP';
        
            -- Actualizacion de la tabla de represtamos con el PIN nuevo            
            BEGIN
                UPDATE PR.PR_REPRESTAMOS r
                   SET R.PIN = vPIN, 
                       R.INTENTOS_PIN = PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN')
                 WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                   AND R.ID_REPRESTAMO = pIdReprestamo;
                   
                COMMIT;
                   
            EXCEPTION WHEN OTHERS THEN
                pRespuesta := 'Error actualizando el PIN en la maestra de represtamos';             
                RAISE_APPLICATION_ERROR(-20100, pRespuesta);
            END;
        
            -- Consumir API para enviar notificaci¿n del PIN            
            IF pCanal = vSMS THEN
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS_PIN'),'[PIN]', vPIN);
                
                vNotificacion.CANAL := 'SMS';
                vNotificacion.SUBJECT := NULL;
                vNotificacion.FORMATO_MENSAJE := 'TEXT';
                vNotificacion.MENSAJE := vMensaje;
                              
                BEGIN
                    -- Enviar SMS
                    Enviar_SMS_API( 
                            pIdReprestamo => pIdReprestamo,
                            pTelefono           => vNotificacion.CONTACTO ,
                            pNombres            => vNotificacion.NOMBRES ,
                            pApellidos          => vNotificacion.APELLIDOS,
                            pTipoNotificacion   => vNotificacion.CANAL,
                            pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                            pMensaje            => vNotificacion.MENSAJE,
                            pRespuesta          => pRespuesta
                            );
                                        
                    vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                    DBMS_OUTPUT.PUT_LINE ( 'IDREPRESTAMO DENTRO DEL P_SOLICITAR PIN: '|| pIdReprestamo);
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := SQLERRM;
                END;                
                
                vNotificacion.ERROR_RESPUESTA := pRespuesta;  
              
            /*ELSIF pCanal = vEMAIL THEN  
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL_PIN'),'[PIN]', vPIN);
                vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'),'[FECHA]', TO_CHAR(SYSDATE, 'DD-MM-YYYY'));
                vNotificacion.CANAL := 'EMAIL';
                vNotificacion.SUBJECT := vSubject;
                vNotificacion.FORMATO_MENSAJE := 'HTML';
                vNotificacion.MENSAJE := vMensaje;
                              
                BEGIN
                    -- Enviar Correo
                    Enviar_Correo_API( 
                            pEmail              => vNotificacion.CONTACTO ,
                            pNombres            => vNotificacion.NOMBRES ,
                            pApellidos          => vNotificacion.APELLIDOS,
                            pSubject            => vNotificacion.SUBJECT, 
                            pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                            pMensaje            => vNotificacion.MENSAJE,
                            pRespuesta          => pRespuesta);
                            
                    vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := SQLERRM;
                END;                
                
                vNotificacion.ERROR_RESPUESTA := pRespuesta; */ 
                
            END IF;
            
            
            IF pObservacion IS NULL THEN
             p_generar_bitacora(pIdReprestamo, pCanal, 'PS', null, 'Solicitado nuevo PIN', NVL(pUsuario,  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)));
            ELSE
             p_generar_bitacora(pIdReprestamo, pCanal, 'PS', null, pObservacion, NVL(pUsuario,  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)));
             
            END IF;
             DBMS_OUTPUT.PUT_LINE ( 'pObservacion = ' || pObservacion );
             pRespuesta:= 'El pin fue solicitado correctamente. Por el canal '||pCanal;                                                   
        END IF;                
        COMMIT;
        RETURN vPIN;
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',          pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',      pUsuario);
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',    pRespuesta);
          IA.LOGGER.ADDPARAMVALUEV('pObservacion',  pObservacion);
          setError(pProgramUnit => 'P_Solicitar_Pin', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        RAISE_APPLICATION_ERROR(-20100, SQLERRM);
    END P_Solicitar_Pin;
    
  PROCEDURE P_Validar_Cambio_Estado(pIdReprestamo     IN VARCHAR2,
                                      pEstado           IN VARCHAR2) IS
                                      
        PRAGMA AUTONOMOUS_TRANSACTION;
        
      CURSOR CUR_CAMBIO_ESTADO IS
         SELECT NVL(B.IND_CAMBIA_ESTADO_ORIGINAL,'N') ESTADO_ORIGINAL, B.IND_NOTIFICA_CLIENTE, B.IND_CAMBIA_ESTADO_REPRE
         FROM PR_ESTADOS_REPRESTAMO B
         WHERE B.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
         AND B.CODIGO_ESTADO    = pEstado;
      vOriginal     PR_ESTADOS_REPRESTAMO.IND_CAMBIA_ESTADO_ORIGINAL%TYPE;
      vNotifica     PR_ESTADOS_REPRESTAMO.IND_NOTIFICA_CLIENTE%TYPE;
      vCambiaEstado VARCHAR2(2);
      vError        VARCHAR2(4000);
      vEstadoBloqueo NUMBER;
      vEstadoAcceso  NUMBER;
      vEstado        NUMBER;
      
    BEGIN
      OPEN  CUR_CAMBIO_ESTADO;
      FETCH CUR_CAMBIO_ESTADO INTO vOriginal, vNotifica, vCambiaEstado; 
      CLOSE CUR_CAMBIO_ESTADO;
      --
      IF vCambiaEstado = 'S' THEN
      
         BEGIN
             UPDATE PR_REPRESTAMOS
                SET estado = pEstado,
                    estado_original = CASE vOriginal 
                                           WHEN 'S' THEN estado 
                                           ELSE NULL 
                                      END
              WHERE codigo_empresa = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                AND ID_REPRESTAMO    = pIdReprestamo;
         
         COMMIT;
        EXCEPTION 
            WHEN OTHERS THEN   
                DECLARE
                    vIdError PLS_INTEGER := 0;
                BEGIN                                    
                    IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pIdReprestamo);
                    IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);
                    setError(
                        pProgramUnit      => 'P_Validar_Cambio_Estado', 
                        pPieceCodeName    => NULL, 
                        pErrorDescription => SQLERRM,                                                              
                        pErrorTrace       => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                        pEmailNotification => NULL, 
                        pParamList        => IA.LOGGER.vPARAMLIST, 
                        pOutputLogger     => FALSE, 
                        pExecutionTime    => NULL, 
                        pIdError          => vIdError
                    ); 
                    ROLLBACK;
                END;
         END;
         
         -- Si el estado esta marcado para notificar al cliente 
         IF vNotifica = 'S' THEN
         
            IF pEstado = 'CRA' THEN
               PR_PKG_REPRESTAMOS.P_Notificar_Desembolso(pIdReprestamo, pEstado, vError);                        
             ELSIF pEstado = 'CRD' THEN
                -- Notificacion Encuesta
                PR_PKG_REPRESTAMOS.P_Notificar_Encuesta(pIdReprestamo, vError);
             ELSE
               PR_PKG_REPRESTAMOS.p_Notificar_Estado(pIdReprestamo, NULL, pEstado, vError);
            END IF;  
                       
            END IF;
         
        COMMIT;    
      END IF;  
      
      IF pEstado = 'NR' THEN
          BEGIN
                UPDATE PR_REPRESTAMOS
                SET FECHA_PROCESO = SYSDATE
              WHERE codigo_empresa = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                AND ID_REPRESTAMO    = pIdReprestamo;
          END;
          
         COMMIT; 
          
      END IF;
     
      SELECT COUNT (COLUMN_VALUE) INTO vEstadoBloqueo FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_DESACTIVAR_ACCESO_FRONTEND')) WHERE COLUMN_VALUE = pEstado;
       
      SELECT COUNT (COLUMN_VALUE) INTO vEstadoAcceso  FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ACTIVAR_ACCESO_FRONTEND'))    WHERE COLUMN_VALUE = pEstado; 
      
      SELECT COUNT (1) CODIGO_ESTADO INTO  vEstado FROM PR_BITACORA_REPRESTAMO WHERE CODIGO_ESTADO = 'NR' AND ID_REPRESTAMO = pIdReprestamo;
      
      IF  vEstadoBloqueo  >=  1 AND vEstado >= 1 THEN 
            PR_PKG_REPRESTAMOS.P_Desactivar_Activar_FrontEnd ( pIdReprestamo, 1, vError );
            COMMIT;
      ELSIF vEstadoAcceso >=  1 THEN 
            PR_PKG_REPRESTAMOS.P_Desactivar_Activar_FrontEnd ( pIdReprestamo, 2, vError );
            COMMIT;
       END IF;  
      COMMIT;    
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);
          setError(pProgramUnit => 'P_Validar_Cambio_Estado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        ROLLBACK;
    END P_Validar_Cambio_Estado;                             
                                     
    
    -- Generar bit¿cora
    PROCEDURE P_Generar_Bitacora(pIdReprestamo     IN VARCHAR2,
                                 pCanal            IN VARCHAR2,
                                 pEstado           IN VARCHAR2,
                                 pStep             IN VARCHAR2,
                                 pObservaciones    IN VARCHAR2,
                                 pUsuario          IN VARCHAR2
                                 ) IS
                                 
         PRAGMA AUTONOMOUS_TRANSACTION;
         
                                 
        vMensaje            VARCHAR2(4000);               
        vParametros         VARCHAR2(4000); 
        CURSOR CUR_SECUENCIA IS
          SELECT COUNT(1)+1
            FROM PR_BITACORA_REPRESTAMO
           WHERE CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
             AND ID_REPRESTAMO = pIdReprestamo;
        vSecuencia  NUMBER(10):= 0;
        
    BEGIN
        
     -- Cambiar el estado del represtamo
        PR_PKG_REPRESTAMOS.P_Validar_Cambio_Estado(pIdReprestamo, pEstado);
        --DBMS_OUTPUT.PUT_LINE('Cambiar estado de la Bitacora de '||pIdReprestamo||' a '||pEstado);
        COMMIT; 
        OPEN  CUR_SECUENCIA;
        FETCH CUR_SECUENCIA INTO vSecuencia; 
        CLOSE CUR_SECUENCIA;
        
        BEGIN
            INSERT INTO PR_BITACORA_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, ID_BITACORA, FECHA_BITACORA, CODIGO_ESTADO, STEP, OBSERVACIONES, CANAL, ADICIONADO_POR, FECHA_ADICION)
              VALUES (f_obt_Empresa_Represtamo, pIdReprestamo, vSecuencia, TRUNC(SYSDATE), pEstado, pStep, pObservaciones, pCanal, pUsuario, SYSDATE );  
              
            COMMIT; 
                       
        EXCEPTION WHEN OTHERS THEN
            vMensaje := 'Fallo, Ingresando Bitacora del Represtamo.'; 
             ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010, vMensaje||' '||SQLERRM);  
        END;
        COMMIT;
        --DBMS_OUTPUT.PUT_LINE('Insertar Bitacora de '||pIdReprestamo||' a '||pEstado);
        --DBMS_OUTPUT.PUT_LINE('Antes de Cambiar estado de la Bitacora de '||pIdReprestamo||' a '||pEstado);
       
        
        
    EXCEPTION WHEN OTHERS THEN 
            
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',          pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);
          IA.LOGGER.ADDPARAMVALUEV('pStep',  pStep);
          IA.LOGGER.ADDPARAMVALUEV('pObservaciones',  pObservaciones);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',  pUsuario);
          setError(pProgramUnit => 'P_Generar_Bitacora', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        ROLLBACK;
        END;
        RETURN;     
    END P_Generar_Bitacora; 
    
    PROCEDURE P_Actualizar_Intentos(pIdReprestamo     IN VARCHAR2,
                                    pTipoIntento      IN VARCHAR2,        -- TIPO I = Identificacion, P = PIN
                                    pNumeroIntento    IN NUMBER,
                                    pRespuesta        IN OUT VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION; 
        vParametros         VARCHAR2(4000);                
                                        
    BEGIN        
        
        IF pNumeroIntento >= 0 THEN
            IF pTipoIntento = 'P' THEN
                BEGIN
                    UPDATE PR.PR_REPRESTAMOS r
                       SET R.INTENTOS_PIN = pNumeroIntento
                     WHERE CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                       AND R.ID_REPRESTAMO = pIdReprestamo;
                       
                       pRespuesta:= 'Intento de solicitud de PIN registrado.';
                   COMMIT;    
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := 'Fall¿, Al Actualizar el intento de validaci¿n de PIN en el Represtamo. Intente m¿s tarde';
                    RAISE_APPLICATION_ERROR(-20100, pRespuesta);
                    ROLLBACK;
                END;
                
                IF pNumeroIntento = 0 THEN
                    p_Bloquear_represtamo(pIdReprestamo, pTipoIntento, pRespuesta);
                END IF;
                
            ELSIF pTipoIntento = 'I' THEN
                BEGIN
                    UPDATE PR.PR_REPRESTAMOS r
                       SET R.INTENTOS_IDENTIFICACION = pNumeroIntento
                     WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                       AND R.ID_REPRESTAMO = pIdReprestamo;
                     
                     pRespuesta:= 'Intento de solicitud de Identificaci¿n registrado.';  
                     COMMIT;  
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := 'Fall¿, Al Actualizar el intento de validaci¿n de Identificaci¿n en el Represtamo. Intente m¿s tarde';
                    RAISE_APPLICATION_ERROR(-20100, pRespuesta);
                    ROLLBACK;
                END;
                
                IF pNumeroIntento = 0 THEN
                    p_Bloquear_represtamo(pIdReprestamo, pTipoIntento, pRespuesta);
                END IF;
                
            END IF;
        END IF;
        
        COMMIT;
        
    EXCEPTION WHEN OTHERS THEN   
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pTipoIntento',    pTipoIntento);
          IA.LOGGER.ADDPARAMVALUEN('pNumeroIntento',  pNumeroIntento);
          setError(pProgramUnit => 'P_Actualizar_Intentos', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          ROLLBACK;
        END;    
        
    END P_Actualizar_Intentos;
    
    FUNCTION P_Total_Estado_Bitacora(pEstado      IN VARCHAR2)
     RETURN NUMBER IS
     vTotal  PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1)
          INTO vTotal
          FROM PR.PR_BITACORA_REPRESTAMO b
         WHERE B.CODIGO_ESTADO = pEstado;
        
        RETURN vTotal;
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);                                          
                                           
          setError(pProgramUnit => 'P_Total_Estado_Bitacora', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;                    
    END P_Total_Estado_Bitacora;
    
    FUNCTION P_Total_Estado_Bitacora_ID(pEstado      IN VARCHAR2, pIdReprestamo     IN VARCHAR2)
     RETURN NUMBER IS
     vTotal  PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1)
          INTO vTotal
          FROM PR.PR_BITACORA_REPRESTAMO b
         WHERE B.CODIGO_ESTADO = pEstado AND ID_REPRESTAMO=pIdReprestamo;
        
        RETURN vTotal;
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',  pIdReprestamo);                                         
                                           
          setError(pProgramUnit => 'P_Total_Estado_Bitacora_ID', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;                    
    END P_Total_Estado_Bitacora_ID;
    
    FUNCTION P_Total_Estado(pEstado      IN VARCHAR2)
     RETURN NUMBER IS
        vTotal  PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1) 
          INTO vTotal
          FROM PR.PR_REPRESTAMOS r 
         WHERE R.CODIGO_EMPRESA = f_obt_Empresa_Represtamo
           AND R.ESTADO = pEstado;
         
         -- ayuda atendida por dia desde la bitacora
         
        RETURN vTotal;
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pEstado',  pEstado);                                          
                                           
          setError(pProgramUnit => 'P_Total_Estado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;        
    END P_Total_Estado;
    
    FUNCTION f_Step_Actual(pEstado      IN VARCHAR2, pIdReprestamo     IN VARCHAR2) RETURN VARCHAR2 IS
        vStep       VARCHAR2(2) := '0';
    BEGIN
        BEGIN
            SELECT b.STEP
              INTO vStep
              FROM PR.PR_BITACORA_REPRESTAMO b
             WHERE B.CODIGO_ESTADO = pEstado 
               AND ID_REPRESTAMO = pIdReprestamo
               AND B.FECHA_ADICION = (SELECT MAX(x.FECHA_ADICION) 
                                         FROM PR.PR_BITACORA_REPRESTAMO x
                                        WHERE x.CODIGO_ESTADO = pEstado 
                                          AND x.ID_REPRESTAMO = pIdReprestamo)
               AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vStep := '0';
        END;
        
        RETURN NVL(vStep, '0');
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pEstado',           pEstado);
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          
          setError(pProgramUnit => 'f_Step_Actual', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;                                       
    END; 
    
    FUNCTION P_Obt_Estado_Represtamo(pIdReprestamo     IN VARCHAR2,
                                     pTipo             IN VARCHAR2 DEFAULT 'A')  -- A = Actual, O = Original
     RETURN VARCHAR2 IS
        vEstado  PR.PR_REPRESTAMOS.ESTADO%type;
    BEGIN
        SELECT CASE 
                  WHEN pTipo = 'A' THEN 
                    ESTADO 
                  WHEN pTipo = 'O' THEN 
                    ESTADO_ORIGINAL 
               END
          INTO vEstado
          FROM PR.PR_REPRESTAMOS r 
         WHERE R.CODIGO_EMPRESA = f_obt_Empresa_Represtamo
           AND R.ID_REPRESTAMO = pIdReprestamo;
         
        RETURN vEstado;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',  pIdReprestamo);                                      
          IA.LOGGER.ADDPARAMVALUEV('pTipo',          pTipo);                                          
                                           
          setError(pProgramUnit => 'P_Obt_Estado_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
    END P_Obt_Estado_Represtamo; 
    
    PROCEDURE P_Notificar_Ayuda(pUsuario    IN VARCHAR2) IS
    
    PRAGMA AUTONOMOUS_TRANSACTION;
    
        CURSOR cReprestamos IS
        SELECT ID_REPRESTAMO
          FROM PR.PR_REPRESTAMOS r
         WHERE R.ESTADO = 'AYS';
        
        TYPE tReprestamos IS TABLE OF cReprestamos%ROWTYPE;
        vReprestamos tReprestamos := tReprestamos();

        vStep   VARCHAR2(2);
        
    BEGIN
        OPEN cReprestamos;
        
        LOOP
            FETCH cReprestamos BULK COLLECT INTO vReprestamos LIMIT 500;
            FOR i IN 1 .. vReprestamos.COUNT LOOP
                vStep := PR.PR_PKG_REPRESTAMOS.f_Step_Actual('AYS', vReprestamos(i).ID_REPRESTAMO);  
                p_generar_bitacora(vReprestamos(i).ID_REPRESTAMO, NULL, 'AYN', vStep, 'Notificaci¿n de Ayuda', pUsuario );
                COMMIT;
                --p_validar_Cambio_Estado(reg.ID_REPRESTAMO, 'AYN');                               
            END LOOP;
            EXIT WHEN cReprestamos%NOTFOUND;
        END LOOP;         
        CLOSE cReprestamos;
        
        COMMIT;        
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',          pUsuario);                                          
                                           
          setError(pProgramUnit => 'P_Notificar_Ayuda', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
            ROLLBACK; 
        END;
                                        
    END P_Notificar_Ayuda;                        
  
    PROCEDURE P_Bloquear_Represtamo(pIdReprestamo     IN     VARCHAR2,
                                    pTipoIntento      IN     VARCHAR2,        
                                    pRespuesta        IN OUT VARCHAR2) IS
        vCodigoEstado       PR.PR_ESTADOS_REPRESTAMO.CODIGO_ESTADO%TYPE;                                    
    BEGIN
        CASE pTipoIntento 
            WHEN 'I' THEN
                vCodigoEstado := 'BLI';
            WHEN 'P' THEN
                vCodigoEstado := 'BLP';
            ELSE
                pRespuesta := 'Tipo de Intento no es v¿lido.  Debe ser [I,P]';
        END CASE;
        pRespuesta:= 'Bloqueo del Repr¿stamo por Intentos '||vCodigoEstado||' agotados';
        p_generar_bitacora(pIdReprestamo, NULL, vCodigoEstado, '1', pRespuesta, NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));                               
        --p_validar_Cambio_Estado(pIdReprestamo, vCodigoEstado);
           
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pTipoIntento',     pTipoIntento);                                        
                                           
          setError(pProgramUnit => 'P_Bloquear_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;              
    END P_Bloquear_Represtamo;
    
    PROCEDURE P_Desbloquear_Represtamo(pIdReprestamo     IN      VARCHAR2,
                                       pCodigoEstado     IN      VARCHAR2, 
                                       pUsuario          IN      VARCHAR2,
                                       pObservacion      IN      VARCHAR2,
                                       pRespuesta        IN OUT  VARCHAR2) IS
                                       
          PRAGMA AUTONOMOUS_TRANSACTION; 
                                        
        vEstadoAnterior     PR.PR_BITACORA_REPRESTAMO.CODIGO_ESTADO%TYPE;  
        vIntento            PLS_INTEGER := 0;
        
        CURSOR cCanal (pIdRep       IN NUMBER) IS
        SELECT C.CANAL, C.VALOR
          FROM PR.PR_CANALES_REPRESTAMO c
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND C.ID_REPRESTAMO = pIdReprestamo;
        
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal      tCanal  := tCanal();        
        
                                                   
    BEGIN
        /*pRespuesta := 'Fall¿, '||pIdReprestamo  ||' '|| pCodigoEstado ||' '||  pUsuario ||' '|| pObservacion;
        raise_application_error(-20100,  pRespuesta);*/
        
        IF pCodigoEstado IS NOT NULL THEN
            -- Busca el estado original
            BEGIN
                SELECT ESTADO_ORIGINAL
                  INTO vEstadoAnterior 
                  FROM PR.PR_REPRESTAMOS P
                 WHERE P.ID_REPRESTAMO = pIdReprestamo
                   AND P.ESTADO = pCodigoEstado;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vEstadoAnterior := NULL;
               
            END;
        ELSE
            pRespuesta := 'Fall¿, Al determinar el estado anterior en el Represtamo. Intente m¿s tarde';            
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
        END IF;
                
         
        IF vEstadoAnterior IS NOT NULL THEN
            OPEN cCanal(pIdReprestamo);
            LOOP
                FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
             EXIT WHEN cCanal%NOTFOUND;
            END LOOP;        
            CLOSE cCanal;
        
            --  Reversar el Estado del represtamo                
            CASE pCodigoEstado 
                WHEN 'BLI' THEN 
                    vIntento := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION'); 
                     BEGIN
                        UPDATE PR.PR_REPRESTAMOS r
                           SET R.INTENTOS_IDENTIFICACION = vIntento
                         WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                           AND R.ID_REPRESTAMO = pIdReprestamo;                           
                        COMMIT;   
                     EXCEPTION WHEN OTHERS THEN
                         pRespuesta := 'Fall¿, Al Actualizar el intento de validaci¿n de Identificaci¿n en el Represtamo. Intente m¿s tarde';
                         ROLLBACK;
                         RAISE_APPLICATION_ERROR(-20100, pRespuesta);
                         
                     END;
                     
                    FOR i IN 1 .. vCanal.COUNT LOOP
                         P_Desbloqueo_FrontEnd(pIdReprestamo, vCanal(i).CANAL, 1, vIntento, pRespuesta);
                     END LOOP;
                    
                WHEN 'BLP' THEN 
                     vIntento := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN');
                    
                     BEGIN
                        UPDATE PR.PR_REPRESTAMOS r
                           SET R.INTENTOS_PIN = vIntento
                         WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                           AND R.ID_REPRESTAMO = pIdReprestamo;                           
                        COMMIT;   
                     EXCEPTION WHEN OTHERS THEN
                         pRespuesta := 'Fall¿, Al Actualizar el intento de validaci¿n de PIN en el Represtamo. Intente m¿s tarde';
                         ROLLBACK;
                         RAISE_APPLICATION_ERROR(-20100, pRespuesta);
                     END;                                           
                     
                     FOR i IN 1 .. vCanal.COUNT LOOP
                         P_Desbloqueo_FrontEnd(pIdReprestamo, vCanal(i).CANAL, 2, vIntento, pRespuesta);
                     END LOOP;                 
            END CASE;    
            
            COMMIT;
            
            -- Restaura los intentos                                            
            --p_Actualizar_intentos(pIdReprestamo, vTipo, vIntento,vMensaje);
            
            -- Desbloquear Represtamo
            PR_PKG_REPRESTAMOS.p_generar_bitacora(pIdReprestamo, NULL, vEstadoAnterior, NULL, NVL(pObservacion,'Desbloqueo de cliente'), pUsuario);                       
            
            -- Notificar al Cliente del Enlace Desbloqueado
            PR_PKG_REPRESTAMOS.p_Notificar_Desbloqueo(pIdReprestamo, vEstadoAnterior, pRespuesta);
            
            PR_PKG_REPRESTAMOS.p_generar_bitacora(pIdReprestamo, NULL, 'AYR', '1', NVL(pObservacion,'Desbloqueo de cliente'), pUsuario); 
            COMMIT;
        END IF;
        
        COMMIT;
        
        IF pRespuesta IS NULL THEN
            pRespuesta := 'El cliente'||pIdReprestamo||' ha sido desbloqueado correctamente';
        END IF;
         
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCodigoEstado',     pCodigoEstado);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',          pUsuario);
          IA.LOGGER.ADDPARAMVALUEV('pObservacion',      pObservacion);                                          
                                           
          setError(pProgramUnit => 'P_Desbloquear_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
           ROLLBACK;
        END; 
        RETURN;                                              
    END P_Desbloquear_Represtamo;  
    
    PROCEDURE P_Desbloqueo_FrontEnd(pIdReprestamo     IN     VARCHAR2,
                                    pCanal            IN     VARCHAR2,
                                    pTipoBloqueo      IN     NUMBER,
                                    pInternto         IN     NUMBER DEFAULT 3,
                                    pRespuesta        IN OUT VARCHAR2) IS
        /*            
            el parametro unlockType recibe: 0 = All(Todos), 1 = ID(Cedula) y 2 = Pin
            /api/Session/UnlockSession
        */
        vUrlAPI         VARCHAR2(4000);
        v_response      CLOB;
        vBody           VARCHAR2(4000);
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200);
    BEGIN
               
        -- Desencriptar ruta y pass
        vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
        vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
        vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
          
        -- Set Header with Token
        APEX_WEB_SERVICE.g_request_headers.delete ();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';          
        vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Session/UnlockSession';             
        vBody := '{"session": "'||pIdReprestamo||'","channel": "'||pCanal||'","unlockType": '||pTipoBloqueo||',"attemptValue": '||pInternto||'}';          
        
        v_response := apex_web_service.make_rest_request(
              p_url           => vUrlAPI,
              p_http_method   => 'POST',
              p_body          => vBody,
              p_wallet_path   => vRutaWallet,
              p_wallet_pwd    => vPassWallet
                                                    
        );        
        
        pRespuesta    := v_response;                    
     
    EXCEPTION WHEN OTHERS THEN
       /*pRespuesta := SQLERRM;
       RAISE_APPLICATION_ERROR(-20100, pRespuesta);*/
       
       DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',            pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pTipoBloqueo',      pTipoBloqueo);
          IA.LOGGER.ADDPARAMVALUEV('pInternto',         pInternto); 
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',        pRespuesta);   
          
          setError(pProgramUnit => 'P_Desbloqueo_FrontEnd', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
       
       
    END P_Desbloqueo_FrontEnd;
    
    
    PROCEDURE P_Desactivar_Activar_FrontEnd(pIdReprestamo      IN     VARCHAR2,
                                            pActivacion        IN     NUMBER,
                                            pRespuesta         IN OUT VARCHAR2) IS


        vUrlAPI         VARCHAR2(4000);
        v_response      CLOB;
        vBody           VARCHAR2(4000);
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200);
    BEGIN
               
        -- Desencriptar ruta y pass
        vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
        vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
        vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
          
        -- Set Header with Token
        APEX_WEB_SERVICE.g_request_headers.delete ();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';          
        vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Session/isActiveSession'; 
                    
        vBody := '{"session": "'||pIdReprestamo||'","activationType":'||pActivacion||'}';         
        
         DBMS_OUTPUT.PUT_LINE ( 'vBody = ' || vBody );
        v_response := apex_web_service.make_rest_request(
              p_url           => vUrlAPI,
              p_http_method   => 'POST',
              p_body          => vBody,
              p_wallet_path   => vRutaWallet,
              p_wallet_pwd    => vPassWallet
                                                    
        );        
        
        pRespuesta    := v_response;
DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
    /*EXCEPTION WHEN OTHERS THEN
       pRespuesta := SQLERRM;
       RAISE_APPLICATION_ERROR(-20100, pRespuesta);
       DBMS_OUTPUT.PUT_LINE ( 'ERROR: = ' || pRespuesta );*/
       
             EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);          
              IA.LOGGER.ADDPARAMVALUEV('pActivacion',         pActivacion); 
              IA.LOGGER.ADDPARAMVALUEV('pRespuesta',          pRespuesta); 
              setError(pProgramUnit => 'P_Desactivar_Activar_FrontEnd', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END;
    END P_Desactivar_Activar_FrontEnd;
    
    PROCEDURE P_Notificar_Desbloqueo(pIdReprestamo    IN      NUMBER,
                                     pCodigoEstado    IN      VARCHAR2,
                                     pRespuesta       IN OUT  VARCHAR2) IS
        CURSOR cCanal (pIdRep       IN NUMBER) IS
        SELECT C.CANAL, C.VALOR
          FROM PR.PR_CANALES_REPRESTAMO c
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND C.ID_REPRESTAMO = pIdReprestamo;
        
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal      tCanal  := tCanal();
        vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);  
        vNotificacion PA.tNotificacion := PA.tNotificacion();
        vMensaje      VARCHAR2(4000);
        vSubject      VARCHAR2(600);
    BEGIN
        OPEN cCanal(pIdReprestamo);
        LOOP
            FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
         EXIT WHEN cCanal%NOTFOUND;
        END LOOP;        
        CLOSE cCanal;
        
        FOR i IN 1 .. vCanal.COUNT LOOP
            IF vCanal(i).Canal = vSMS THEN
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS_DESBLOQUEO'),'[ESTADO]', pCodigoEstado);
                vNotificacion.CONTACTO := vCanal(i).VALOR;
                vNotificacion.CANAL := 'SMS';
                vNotificacion.SUBJECT := NULL;
                vNotificacion.FORMATO_MENSAJE := 'TEXT';
                vNotificacion.MENSAJE := vMensaje;
                DBMS_OUTPUT.PUT_LINE('Mensaje ' || vMensaje);            
                BEGIN
                    -- Enviar SMS
                    Enviar_SMS_API_DESBLOQUEO( 
                            pIdReprestamo       => pIdReprestamo,
                            pTelefono           => vNotificacion.CONTACTO ,
                            pNombres            => vNotificacion.NOMBRES ,
                            pApellidos          => vNotificacion.APELLIDOS,
                            pTipoNotificacion   => vNotificacion.CANAL,
                            pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                            pMensaje            => vNotificacion.MENSAJE,
                            pRespuesta          => pRespuesta);
                                        
                    vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := SQLERRM;
                END;                
                
                vNotificacion.ERROR_RESPUESTA := pRespuesta;  
                DBMS_OUTPUT.PUT_LINE('Mensaje Enviado' || vMensaje);    
                              
                p_generar_bitacora(pIdReprestamo, 1, 'DBA', NULL, 'Notificaci¿n Desbloqueo Canal SMS', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
              
           /* ELSIF vCanal(i).CANAL = vEMAIL THEN  
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL_DESBLOQUEO'),'[ESTADO]', pCodigoEstado);
                vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'),'[FECHA]', TO_CHAR(SYSDATE, 'DD-MM-YYYY'));
                vNotificacion.CANAL := 'EMAIL';
                vNotificacion.CONTACTO := vCanal(i).VALOR;
                vNotificacion.SUBJECT := vSubject;
                vNotificacion.FORMATO_MENSAJE := 'HTML';
                vNotificacion.MENSAJE := vMensaje;
                              
                BEGIN
                    -- Enviar Correo
                    Enviar_Correo_API( 
                            pEmail              => vNotificacion.CONTACTO ,
                            pNombres            => vNotificacion.NOMBRES ,
                            pApellidos          => vNotificacion.APELLIDOS,
                            pSubject            => vNotificacion.SUBJECT, 
                            pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                            pMensaje            => vNotificacion.MENSAJE,
                            pRespuesta          => pRespuesta);
                            
                    vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := SQLERRM;
                END;               
                
                vNotificacion.ERROR_RESPUESTA := pRespuesta;  
                DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');                
                p_generar_bitacora(pIdReprestamo, 2, 'DBA', NULL, 'Notificaci¿n Desbloqueo Canal EMAIL', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));  */
                
            END IF;
        END LOOP; 
        
     EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCodigoEstado',          pCodigoEstado);
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',        pRespuesta);  
          
          setError(pProgramUnit => 'P_Notificar_Desbloqueo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;       
    END P_Notificar_Desbloqueo; 
    
     PROCEDURE P_Notificar_Encuesta(pIdReprestamo    IN      NUMBER,
                                   pRespuesta       IN OUT  VARCHAR2) IS
    CURSOR cCanal (pIdRep       IN NUMBER) IS
     SELECT c.CANAL, c.VALOR, S.NOMBRES, S.APELLIDOS, s.ESTADO, s.PLAZO, O.MTO_CUOTA, O.MTO_PRESTAMO 
       FROM PR.PR_CANALES_REPRESTAMO c, PR_SOLICITUD_REPRESTAMO s, PR_OPCIONES_REPRESTAMO o 
      WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
        AND C.ID_REPRESTAMO = pIdReprestamo
        AND C.CANAL = C.CANAL ||''
        AND S.CODIGO_EMPRESA = C.CODIGO_EMPRESA
        AND S.ID_REPRESTAMO = C.ID_REPRESTAMO
        AND O.CODIGO_EMPRESA = S.CODIGO_EMPRESA
        AND O.ID_REPRESTAMO = S.ID_REPRESTAMO
        AND O.PLAZO = S.PLAZO;
        
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal      tCanal  := tCanal();
        vMensaje      VARCHAR2(4000);
        vSubject      VARCHAR2(600);
        vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);  
        vUrlAPI         VARCHAR2(4000);
        v_response      CLOB;
        vBody           VARCHAR2(4000);   
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200);      
    BEGIN
        OPEN cCanal(pIdReprestamo);
        LOOP
            FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
         EXIT WHEN cCanal%NOTFOUND;
        END LOOP;        
        CLOSE cCanal;              
           
        -- Set Header with Token
        APEX_WEB_SERVICE.g_request_headers.delete ();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';     
        
        -- Desencriptar ruta y pass
        vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
        vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
        vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
                                  
        FOR i IN 1 .. vCanal.COUNT LOOP
            IF vCanal(i).Canal = vSMS THEN
              vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendSurveyLinkBySMS';         
              vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS_ENCUESTA'),'[ESTADO]', vCanal(i).ESTADO);  
              vMensaje := replace(vMensaje,'[NOMBRE]',vCanal(i).NOMBRES);  
              vBody := '{"sessionId": "'||pIdReprestamo||'","name":"'||vCanal(i).NOMBRES||'","number": "'||vCanal(i).VALOR||'", "message":"'||vMensaje||'"}';  
              DBMS_OUTPUT.PUT_LINE (vBody );       
              v_response := apex_web_service.make_rest_request(
                      p_url           => vUrlAPI,
                      p_http_method   => 'POST',
                      p_body          => vBody,
                      p_wallet_path   => vRutaWallet,
                     p_wallet_pwd    => vPassWallet                                       
              );          
              DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');
              p_generar_bitacora(pIdReprestamo, 1, 'NTE', NULL, 'Notificaci¿n Encuesta Canal SMS', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
            ELSIF vCanal(i).CANAL = vEMAIL THEN  
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL_ENCUESTA'),'[ESTADO]', vCanal(i).ESTADO);
                vMensaje := replace(vMensaje,'[NOMBRE]',vCanal(i).NOMBRES);
                vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'),'[FECHA]', TO_CHAR(SYSDATE, 'DD-MM-YYYY'));
                vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendSurveyLinkByEmail';         
                vBody := '{"sessionId": "'||pIdReprestamo||'","toName": "'||vCanal(i).NOMBRES||'","toEmail": "'||vCanal(i).VALOR||'","subject": "'||vSubject||'","message": "'||vMensaje||'"}';                                  
                v_response := apex_web_service.make_rest_request(
                      p_url           => vUrlAPI,
                      p_http_method   => 'POST',
                      p_body          => vBody,
                      p_wallet_path   => vRutaWallet,
                      p_wallet_pwd    => vPassWallet                                       
                ); 
                DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');
                
                p_generar_bitacora(pIdReprestamo, 2, 'NTE', NULL, 'Notificaci¿n Encuesta Canal EMAIL', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                
            END IF;
        END LOOP; 
        
      EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',          pRespuesta);
          
          setError(pProgramUnit => 'P_Notificar_Encuesta', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
        
    END P_Notificar_Encuesta;                                    
    
    PROCEDURE P_Notificar_Desembolso(pIdReprestamo    IN      NUMBER,
                                    pCodigoEstado    IN      VARCHAR2,
                                    pRespuesta       IN OUT  VARCHAR2) IS
     CURSOR cCanal (pIdRep       IN NUMBER) IS
     SELECT c.CANAL, c.VALOR, S.NOMBRES, S.APELLIDOS, s.PLAZO, O.MTO_CUOTA, O.MTO_PRESTAMO 
       FROM PR.PR_CANALES_REPRESTAMO c, PR_SOLICITUD_REPRESTAMO s, PR_OPCIONES_REPRESTAMO o 
      WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
        AND C.ID_REPRESTAMO = pIdReprestamo
        AND C.CANAL = C.CANAL ||''
        AND S.CODIGO_EMPRESA = C.CODIGO_EMPRESA
        AND S.ID_REPRESTAMO = C.ID_REPRESTAMO
        AND O.CODIGO_EMPRESA = S.CODIGO_EMPRESA
        AND O.ID_REPRESTAMO = S.ID_REPRESTAMO
        AND O.PLAZO = S.PLAZO;
        
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal      tCanal  := tCanal();
        vMensaje      VARCHAR2(4000);
        vSubject      VARCHAR2(600);
        vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);  
        vUrlAPI         VARCHAR2(4000);
        v_response      CLOB;
        vBody           VARCHAR2(4000);        
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200); 
    BEGIN
        OPEN cCanal(pIdReprestamo);
        LOOP
            FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
         EXIT WHEN cCanal%NOTFOUND;
        END LOOP;        
        CLOSE cCanal;              
           
        -- Set Header with Token
        APEX_WEB_SERVICE.g_request_headers.delete ();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';     
        
        -- Desencriptar ruta y pass
        vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
        vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
        vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
        
        FOR i IN 1 .. vCanal.COUNT LOOP
            IF vCanal(i).Canal = vSMS THEN
              vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendReloanApprovedLinkBySMS';         
              vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS_DESEMBOLSO'),'[ESTADO]', pCodigoEstado); 
              vMensaje := replace(vMensaje,'[NOMBRE]',vCanal(i).NOMBRES);   
              vBody := '{"sessionId":"'||pIdReprestamo||'","name":"'||vCanal(i).NOMBRES||'","number": "'||vCanal(i).VALOR||'", "message":"'||vMensaje||'","amount": "'||vCanal(i).MTO_PRESTAMO||'", "installments": "'||vCanal(i).PLAZO||'", "installmentAmount": "'||vCanal(i).MTO_CUOTA||'"}';                  
              DBMS_OUTPUT.PUT_LINE(vBody);
              v_response := apex_web_service.make_rest_request(
                      p_url           => vUrlAPI,
                      p_http_method   => 'POST',
                      p_body          => vBody,
                      p_wallet_path   => vRutaWallet,
                      p_wallet_pwd    => vPassWallet                                       
              );          
             --DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
             DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');
             p_generar_bitacora(pIdReprestamo, 1, 'NBD', NULL, 'Notificaci¿n Desembolso Canal SMS', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
            ELSIF vCanal(i).CANAL = vEMAIL THEN  
                -- Reemplazar el mensaje del parametro 
                vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL_DESEMBOLSO'),'[ESTADO]', pCodigoEstado);
                vMensaje := replace(vMensaje,'[NOMBRE]',vCanal(i).NOMBRES);
                vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'),'[FECHA]', TO_CHAR(SYSDATE, 'DD-MM-YYYY'));
                vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendReloanApprovedLinkByEmail';         
                vBody := '{"toName": "'||vCanal(i).NOMBRES||'","toEmail": "'||vCanal(i).VALOR||'","subject": "'||vSubject||'","message": "'||vMensaje||'","amount": "'||vCanal(i).MTO_PRESTAMO||'", "installments": "'||vCanal(i).PLAZO||'", "installmentAmount": "'||vCanal(i).MTO_CUOTA||'"}';                                  
                v_response := apex_web_service.make_rest_request(
                      p_url           => vUrlAPI,
                      p_http_method   => 'POST',
                      p_body          => vBody,
                      p_wallet_path   => vRutaWallet,
                      p_wallet_pwd    => vPassWallet                                       
                ); 
                DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');
                p_generar_bitacora(pIdReprestamo, 2, 'NBD', NULL, 'Notificaci¿n Desembolso Canal EMAIL', NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
            END IF;
        END LOOP; 
        DBMS_OUTPUT.PUT_LINE('SMS Enviado');
        
      EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',          pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCodigoEstado',          pCodigoEstado);
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',             pRespuesta);  
          
          setError(pProgramUnit => 'P_Notificar_Desembolso', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;  
    END P_Notificar_Desembolso;                 
    
    PROCEDURE P_Notificar_Reenvio_Link(pIdReprestamo    IN      NUMBER,
                                       pRespuesta       IN OUT  VARCHAR2) IS
        
        CURSOR cCanal(pIdReprestamo    IN      NUMBER) IS
        SELECT c.CANAL, c.VALOR, S.NOMBRES, S.APELLIDOS 
          FROM PR.PR_CANALES_REPRESTAMO c, PR_SOLICITUD_REPRESTAMO s 
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND C.ID_REPRESTAMO = pIdReprestamo
           AND C.CANAL = C.CANAL ||''
           AND S.CODIGO_EMPRESA = C.CODIGO_EMPRESA
           AND S.ID_REPRESTAMO = C.ID_REPRESTAMO;  
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal tCanal := tCanal(); 
        vMensaje      VARCHAR2(4000); 
        vSubject      VARCHAR2(4000);
        vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);   
        vTipoCanal    VARCHAR2(5) := 'SMS';                                         
    BEGIN
         OPEN cCanal(pIdReprestamo);
         LOOP
             FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;       
             FOR x IN 1 .. vCanal.COUNT LOOP
                 vMensaje :=   PR_PKG_REPRESTAMOS.F_Obt_Body_Mensaje(pIdReprestamo, vCanal(x).CANAL);
                 IF vCanal(x).CANAL = vSMS THEN                    
                     vTipoCanal := 'SMS';
                     PR_PKG_REPRESTAMOS.Reenviar_Sms_Api(pIdReprestamo, vCanal(x).VALOR, vCanal(x).NOMBRES, vCanal(x).APELLIDOS, vTipoCanal, 'TXT',vMensaje, pRespuesta);
                     IF pRespuesta IS NULL THEN
                        pRespuesta := 'Notificacion Enviada';
                        DBMS_OUTPUT.PUT_LINE ( pRespuesta );
                     END IF;
                 /*ELSIF vCanal(x).CANAL = vEMAIL THEN
                     vTipoCanal := 'MAIL';
                     vSubject := PR.PR_PKG_REPRESTAMOS.f_OBT_subject_email(pIdReprestamo);
                     PR_PKG_REPRESTAMOS.Reenviar_Correo_Api(pIdReprestamo, vCanal(x).VALOR, vCanal(x).NOMBRES, vCanal(x).APELLIDOS, vSubject, 'TXT',vMensaje, pRespuesta);            
                     IF pRespuesta IS NULL THEN
                        pRespuesta := 'Notificacion Enviada';
                     END IF;/*/
                 END IF;                 
                 DBMS_OUTPUT.PUT_LINE (vMensaje);
             END LOOP;
             EXIT WHEN cCanal%NOTFOUND;
         END LOOP;
         CLOSE cCanal; 
     EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',          pRespuesta);  
          
          setError(pProgramUnit => 'P_Notificar_Reenvio_Link', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;       
    END;                                       
    
    FUNCTION F_Obt_Subject_Email(pIdReprestamo     IN VARCHAR2) RETURN VARCHAR2 IS
        vSubject    VARCHAR2(4000);
        vNombres    VARCHAR2(400);
    BEGIN
    
         BEGIN
            SELECT PA.OBT_NOMBRE_PERSONA(R.CODIGO_CLIENTE) Nombres
              INTO vNombres
              FROM PR.PR_REPRESTAMOS r
             WHERE r.ID_REPRESTAMO = pIdReprestamo;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vNombres := NULL;  
        END;
        
        IF vNombres IS NOT NULL THEN
            vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'), '[NOMBRES]', vNombres);
            vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'), '[FECHA]', TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
        END IF;
        
        RETURN vSubject;
    
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);   
                                           
          setError(pProgramUnit => 'F_Obt_Subject_Email', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        
    END F_Obt_Subject_Email;
    
    FUNCTION F_Obt_Body_Mensaje(pIdReprestamo     IN VARCHAR2,
                                pCanal            IN VARCHAR2)
     RETURN VARCHAR2 IS
        vBody       VARCHAR2(4000);
        vNombres    VARCHAR2(400);
        vFecha      DATE;
         vUltimoDia  DATE;       
    BEGIN
        BEGIN
            SELECT PF.PRIMER_NOMBRE,R.fecha_proceso --PA.OBT_NOMBRE_PERSONA(R.CODIGO_CLIENTE) Nombres
              INTO vNombres,vFecha
              FROM PR.PR_REPRESTAMOS r, PA.PERSONAS_FISICAS pf
             WHERE r.ID_REPRESTAMO = pIdReprestamo
               AND R.CODIGO_CLIENTE = PF.COD_PER_FISICA;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vNombres := NULL;  
        END;
        
        IF vNombres IS NOT NULL THEN
        
        SELECT TO_DATE(TO_CHAR(LAST_DAY(R.FECHA_PROCESO), 'DD/MM/YYYY') || ' 11:59:59 PM', 'DD/MM/YYYY HH:MI:SS AM')
        INTO vUltimoDia
        FROM PR.PR_REPRESTAMOS R
        WHERE R.ID_REPRESTAMO = pIdReprestamo;
        
        
            IF pCanal = 1 THEN  -- SMS
                --vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS'), '[NOMBRES]', vNombres),'[FECHA]',to_char(trunc(vFecha)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK'),'DD/MM/YYYY'));
                vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS'), '[NOMBRES]', vNombres), '[FECHA]', TO_CHAR(vUltimoDia, 'DD/MM/YYYY HH:MI:SS AM'));
            ELSIF pCanal = 2 THEN  -- EMAIL
                vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL'), '[NOMBRES]', vNombres),'[FECHA]',to_char(trunc(vFecha)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK'),'DD/MM/YYYY'));
            END IF;
        END IF;
        
        RETURN vBody;
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',            pCanal);          
                                           
          setError(pProgramUnit => 'F_Obt_Body_Mensaje', 
                   pPieceCodeName => NULL, 


                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
        
    END F_Obt_Body_Mensaje; 
    
    PROCEDURE P_Registrar_Solicitud(pIdReprestamo     IN     VARCHAR2,
                                    pUsuario          IN     VARCHAR2,
                                    pMensaje          IN OUT VARCHAR2) IS
        vCodCliente             CLIENTES_B2000.COD_CLIENTE%TYPE;
        vNombres                CLIENTES_B2000.NOMBRES%TYPE;
        vApellidos              CLIENTES_B2000.NOMBRES%TYPE;
        vIdentificacion         CLIENTES_B2000.NUMERO_IDENTIFICACION%TYPE;
        vSexo                   CLIENTES_B2000.SEXO%TYPE;
        vFec_Nacimiento         CLIENTES_B2000.FECHA_DE_NACIMIENTO%TYPE;
        vNacionalidad           PA.PERSONAS_FISICAS.NACIONALIDAD%TYPE;
        vEstadoCivil            CLIENTES_B2000.ESTADO_CIVIL%TYPE;
        vCorreo                 PA.PERSONAS_FISICAS.EMAIL_USUARIO%TYPE;
        vIdreprestamoSolicitud  PR.PR_SOLICITUD_REPRESTAMO.ID_REPRESTAMO%TYPE;
         
        vPersonaFisica      PA.PERSONAS_FISICAS_OBJ;
        vDirPersona         PA.DIR_PERSONAS_OBJ;

        vTelPersona         PA.TEL_PERSONAS_OBJ;
        vTelefonoCelular    VARCHAR2(50);


        vTelefonoResidencia VARCHAR2(50);
        vTelefonoTrabajo    VARCHAR2(50);
        vCodDireccion       PA.DIR_PERSONAS.COD_DIRECCION%TYPE;
        vTipDireccion       PA.DIR_PERSONAS.TIP_DIRECCION%TYPE;
        vDireccion          PA.DIR_PERSONAS.DETALLE%TYPE;
        vCodArea            VARCHAR2(3);
        vNumTel             VARCHAR2(50);           

    BEGIN
        BEGIN
            SELECT R.CODIGO_CLIENTE
              INTO vCodCliente
              FROM PR.PR_REPRESTAMOS r
             WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND r.ID_REPRESTAMO = pIdReprestamo;

        EXCEPTION WHEN NO_DATA_FOUND THEN
            pMensaje := 'Datos del Re-pr¿stamo no encontrados';
            RAISE_APPLICATION_ERROR(-20100, pMensaje);
        END;       
        
         BEGIN
            SELECT R.ID_REPRESTAMO
              INTO vIdreprestamoSolicitud
              FROM PR.PR_SOLICITUD_REPRESTAMO r
             WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND r.ID_REPRESTAMO = pIdReprestamo;

        EXCEPTION WHEN NO_DATA_FOUND THEN
            vIdreprestamoSolicitud := 0;
        END;
        
        IF vCodCliente IS NOT NULL THEN
              p_datos_primarios(vCodCliente, vNombres, vApellidos, vIdentificacion, vSexo, vFec_Nacimiento, vNacionalidad, vEstadoCivil, pMensaje);
                                
              p_datos_secundarios(vCodCliente, vTelefonoCelular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, vCodDireccion, vTipDireccion, vDireccion, pMensaje);                                     
          
          IF vIdreprestamoSolicitud = 0 THEN   
             
             BEGIN
                    INSERT INTO PR.PR_SOLICITUD_REPRESTAMO
                      (   CODIGO_EMPRESA,        
                          ID_REPRESTAMO,              
                          NOMBRES,               
                          APELLIDOS,     
                          IDENTIFICACION,        
                          FEC_NACIMIENTO,        
                          SEXO,                  
                          NACIONALIDAD,          
                          ESTADO_CIVIL,          
                          TELEFONO_CELULAR,      
                          TELEFONO_RESIDENCIA,   
                          TELEFONO_TRABAJO,      
                          EMAIL,                 
                          COD_DIRECCION,         
                          TIP_DIRECCION,         
                          DIRECCION,             
                          PLAZO,                 
                          OPCION_RECHAZO,        
                          NO_CREDITO,            
                          ESTADO,
                          ADICIONADO_POR,
                          FECHA_ADICION,
                          COD_PAIS,
                          TIPO_CREDITO
                      ) 
                    VALUES
                    (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo,
                     pIdReprestamo,
                     vNombres,
                     vApellidos,
                     vIdentificacion,
                     vFec_Nacimiento,
                     vSexo,
                     vNacionalidad,
                     vEstadoCivil,
                     vTelefonoCelular,
                     vTelefonoResidencia,
                     vTelefonoTrabajo,
                     vCorreo,
                     NULL,
                     NULL,
                     vDireccion,
                     NULL,
                     NULL,
                     NULL,
                     'A',
                     pUsuario,
                     SYSDATE,
                     '1',
                     PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO (pIdReprestamo));
             EXCEPTION WHEN OTHERS THEN
                pMensaje := 'Error Insertando los datos de la solicitud: '  || SQLERRM;
                RAISE_APPLICATION_ERROR(-20100, pMensaje);
                     
             END;
             
          END IF;
             
        END IF; 
        
        IF pIdReprestamo IS NOT NULL AND F_Validar_Telefono(vTelefonoCelular) IS NOT NULL THEN
        
        INSERT INTO PR.PR_CANALES_REPRESTAMO ( CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION )
               VALUES ( PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo,1/*Obtener el valor de la tabla parametro*/, F_Validar_Telefono(vTelefonoCelular), pUsuario, SYSDATE);
               COMMIT;
        END IF;
           -- UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TIPO_CREDITO = PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO (pIdReprestamo) WHERE S.ID_REPRESTAMO = pIdReprestamo;
        /*IF pIdReprestamo IS NOT NULL AND  vCorreo IS NOT NULL THEN
        
        INSERT INTO PR.PR_CANALES_REPRESTAMO ( CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION )
            VALUES ( PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo,2/*Obtener el valor de la tabla parametro, vCorreo, pUsuario, SYSDATE);
            COMMIT;
        END IF; */
    COMMIT;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',            pUsuario);          
                                           
          setError(pProgramUnit => 'P_Registrar_Solicitud', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
                     
    END P_Registrar_Solicitud;    
    
   PROCEDURE P_Registra_Solicitud_Dirigida(pIdReprestamo     IN     VARCHAR2,
                                           pUsuario          IN     VARCHAR2,
                                           pMensaje          IN OUT VARCHAR2) IS
                                 
        vCodCliente             CLIENTES_B2000.COD_CLIENTE%TYPE;
        vNombres                CLIENTES_B2000.NOMBRES%TYPE;
        vApellidos              CLIENTES_B2000.NOMBRES%TYPE;
        vIdentificacion         CLIENTES_B2000.NUMERO_IDENTIFICACION%TYPE;
        vSexo                   CLIENTES_B2000.SEXO%TYPE;
        vFec_Nacimiento         CLIENTES_B2000.FECHA_DE_NACIMIENTO%TYPE;
        vNacionalidad           PA.PERSONAS_FISICAS.NACIONALIDAD%TYPE;
        vEstadoCivil            CLIENTES_B2000.ESTADO_CIVIL%TYPE;
        vCorreo                 PA.PERSONAS_FISICAS.EMAIL_USUARIO%TYPE;
        vIdreprestamoSolicitud  PR.PR_SOLICITUD_REPRESTAMO.ID_REPRESTAMO%TYPE;
         
        vPersonaFisica      PA.PERSONAS_FISICAS_OBJ;
        vDirPersona         PA.DIR_PERSONAS_OBJ;

        vTelPersona         PA.TEL_PERSONAS_OBJ;
        vTelefonoCelular    VARCHAR2(15);
        v_Telefono_Celular  VARCHAR2(15);

        vTelefonoResidencia VARCHAR2(15);
        vTelefonoTrabajo    VARCHAR2(15);
        vCodDireccion       PA.DIR_PERSONAS.COD_DIRECCION%TYPE;
        vTipDireccion       PA.DIR_PERSONAS.TIP_DIRECCION%TYPE;
        vDireccion          PA.DIR_PERSONAS.DETALLE%TYPE;
        vCodArea            VARCHAR2(3);
        vNumTel             VARCHAR2(10);           

    BEGIN
        BEGIN
            SELECT R.CODIGO_CLIENTE
              INTO vCodCliente
              FROM PR.PR_REPRESTAMOS r
             WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND r.ID_REPRESTAMO = pIdReprestamo;

        EXCEPTION WHEN NO_DATA_FOUND THEN
            pMensaje := 'Datos del Represtamo no encontrados';
            RAISE_APPLICATION_ERROR(-20100, pMensaje);
        END;    
        
        BEGIN
           SELECT CELULAR INTO v_Telefono_Celular
           FROM PR.PR_CARGA_DIRECCIONADA C
           JOIN PR.PR_REPRESTAMOS R ON C.NO_CREDITO = R.NO_CREDITO
           WHERE R.ID_REPRESTAMO = pIdReprestamo AND C.ESTADO='T' AND ROWNUM=1;
       END;
        
         BEGIN
            SELECT R.ID_REPRESTAMO
              INTO vIdreprestamoSolicitud
              FROM PR.PR_SOLICITUD_REPRESTAMO r
             WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
               AND r.ID_REPRESTAMO = pIdReprestamo;

        EXCEPTION WHEN NO_DATA_FOUND THEN
            vIdreprestamoSolicitud := 0;
        END;
        
        IF vCodCliente IS NOT NULL THEN
              p_datos_primarios(vCodCliente, vNombres, vApellidos, vIdentificacion, vSexo, vFec_Nacimiento, vNacionalidad, vEstadoCivil, pMensaje);
                                
              p_datos_secundarios(vCodCliente, vTelefonoCelular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, vCodDireccion, vTipDireccion, vDireccion, pMensaje);                                     
          
          IF vIdreprestamoSolicitud = 0 THEN   
             
             BEGIN
                    INSERT INTO PR.PR_SOLICITUD_REPRESTAMO
                      (   CODIGO_EMPRESA,        
                          ID_REPRESTAMO,              
                          NOMBRES,               
                          APELLIDOS,     
                          IDENTIFICACION,        
                          FEC_NACIMIENTO,        
                          SEXO,                  
                          NACIONALIDAD,          
                          ESTADO_CIVIL,          
                          TELEFONO_CELULAR,      
                          TELEFONO_RESIDENCIA,   
                          TELEFONO_TRABAJO,      
                          EMAIL,                 
                          COD_DIRECCION,         
                          TIP_DIRECCION,         
                          DIRECCION,             
                          PLAZO,                 
                          OPCION_RECHAZO,        
                          NO_CREDITO,            
                          ESTADO,
                          ADICIONADO_POR,
                          FECHA_ADICION,
                          COD_PAIS,
                          TIPO_CREDITO
                      ) 
                    VALUES
                    (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo,
                     pIdReprestamo,
                     vNombres,
                     vApellidos,
                     vIdentificacion,
                     vFec_Nacimiento,
                     vSexo,
                     vNacionalidad,
                     vEstadoCivil,
                     v_Telefono_Celular,
                     vTelefonoResidencia,
                     vTelefonoTrabajo,
                     vCorreo,
                     NULL,
                     NULL,
                     vDireccion,
                     NULL,
                     NULL,
                     NULL,
                     'A',
                     pUsuario,
                     SYSDATE,
                     '1',
                     PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO (pIdReprestamo));
             EXCEPTION WHEN OTHERS THEN
                pMensaje := 'Error Insertando los datos de la solicitud: '  || SQLERRM;
                RAISE_APPLICATION_ERROR(-20100, pMensaje);
                     
             END;
             
          END IF;
             
        END IF; 
        
        IF pIdReprestamo IS NOT NULL AND F_Validar_Telefono(v_Telefono_Celular) IS NOT NULL THEN
        
        INSERT INTO PR.PR_CANALES_REPRESTAMO ( CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION )
               VALUES ( PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo,1/*Obtener el valor de la tabla parametro*/, F_Validar_Telefono(v_Telefono_Celular), pUsuario, SYSDATE);
               COMMIT;
        END IF;

    COMMIT;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario',            pUsuario);          
                                           
          setError(pProgramUnit => 'P_Registra_Solicitud_Dirigida', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
                     
    END P_Registra_Solicitud_Dirigida;  
 PROCEDURE P_Registra_Solicitud_Campana(
    pIdReprestamo     IN     VARCHAR2,
    pTipo_Credito     IN     NUMBER,
    pUsuario          IN     VARCHAR2,
    pMensaje          IN OUT VARCHAR2
) IS
    vCodCliente             CLIENTES_B2000.COD_CLIENTE%TYPE;
    vNombres                CLIENTES_B2000.NOMBRES%TYPE;
    vApellidos              CLIENTES_B2000.NOMBRES%TYPE;
    vIdentificacion         CLIENTES_B2000.NUMERO_IDENTIFICACION%TYPE;
    vSexo                   CLIENTES_B2000.SEXO%TYPE;
    vFec_Nacimiento         CLIENTES_B2000.FECHA_DE_NACIMIENTO%TYPE;
    vNacionalidad           PA.PERSONAS_FISICAS.NACIONALIDAD%TYPE;
    vEstadoCivil            CLIENTES_B2000.ESTADO_CIVIL%TYPE;
    vCorreo                 PA.PERSONAS_FISICAS.EMAIL_USUARIO%TYPE;
    vIdreprestamoSolicitud  PR.PR_SOLICITUD_REPRESTAMO.ID_REPRESTAMO%TYPE;
    vPersonaFisica          PA.PERSONAS_FISICAS_OBJ;
    vDirPersona             PA.DIR_PERSONAS_OBJ;
    vTelPersona             PA.TEL_PERSONAS_OBJ;
    vTelefonoCelular        VARCHAR2(15);
    v_Telefono_Celular      VARCHAR2(15);
    vTelefonoResidencia     VARCHAR2(15);
    vTelefonoTrabajo        VARCHAR2(15);
    vCodDireccion           PA.DIR_PERSONAS.COD_DIRECCION%TYPE;
    vTipDireccion           PA.DIR_PERSONAS.TIP_DIRECCION%TYPE;
    vDireccion              PA.DIR_PERSONAS.DETALLE%TYPE;
    vCodArea                VARCHAR2(3);
    vNumTel                 VARCHAR2(10);           
    NUEVO_TIPO              NUMBER;
    CREDITO                 NUMBER;
BEGIN
    BEGIN
        SELECT R.CODIGO_CLIENTE
          INTO vCodCliente
          FROM PR.PR_REPRESTAMOS r
         WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND r.ID_REPRESTAMO = pIdReprestamo;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            pMensaje := 'Datos del Represtamo no encontrados';
            RAISE_APPLICATION_ERROR(-20100, pMensaje);
    END;    
    
    BEGIN
       SELECT CELULAR INTO v_Telefono_Celular
       FROM PR.PR_CAMPANA_ESPECIALES C
       JOIN PR.PR_REPRESTAMOS R ON C.NO_CREDITO = R.NO_CREDITO
       WHERE R.ID_REPRESTAMO = pIdReprestamo AND C.ESTADO='T' AND ROWNUM=1;
    END;
    
    BEGIN
        SELECT R.ID_REPRESTAMO
          INTO vIdreprestamoSolicitud
          FROM PR.PR_SOLICITUD_REPRESTAMO r
         WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND r.ID_REPRESTAMO = pIdReprestamo;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            vIdreprestamoSolicitud := 0;
    END;
    
    IF vCodCliente IS NOT NULL THEN
        p_datos_primarios(vCodCliente, vNombres, vApellidos, vIdentificacion, vSexo, vFec_Nacimiento, vNacionalidad, vEstadoCivil, pMensaje);
        p_datos_secundarios(vCodCliente, vTelefonoCelular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, vCodDireccion, vTipDireccion, vDireccion, pMensaje);                                     
      
        IF vIdreprestamoSolicitud = 0 THEN   
            BEGIN
                INSERT INTO PR.PR_SOLICITUD_REPRESTAMO
                  (CODIGO_EMPRESA, ID_REPRESTAMO, NOMBRES, APELLIDOS, IDENTIFICACION, FEC_NACIMIENTO, SEXO, NACIONALIDAD, ESTADO_CIVIL, TELEFONO_CELULAR, TELEFONO_RESIDENCIA, TELEFONO_TRABAJO, EMAIL, COD_DIRECCION, TIP_DIRECCION, DIRECCION, PLAZO, OPCION_RECHAZO, NO_CREDITO, ESTADO, ADICIONADO_POR, FECHA_ADICION, COD_PAIS, TIPO_CREDITO) 
                VALUES
                (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, vNombres, vApellidos, vIdentificacion, vFec_Nacimiento, vSexo, vNacionalidad, vEstadoCivil, v_Telefono_Celular, vTelefonoResidencia, vTelefonoTrabajo, vCorreo, NULL, NULL, vDireccion, NULL, NULL, NULL, 'A', pUsuario, SYSDATE, '1', pTipo_Credito);
            EXCEPTION 
                WHEN OTHERS THEN
                    pMensaje := 'Error Insertando los datos de la solicitud: '  || SQLERRM;
                    RAISE_APPLICATION_ERROR(-20100, pMensaje);
            END;
        END IF;
    END IF;

    BEGIN 
        CREDITO := PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO(pIdReprestamo);
        
        IF CREDITO = 1 THEN
            DBMS_OUTPUT.PUT_LINE('CREDITO1 = ' || CREDITO);
            DBMS_OUTPUT.PUT_LINE('pIdReprestamo1 = ' || pIdReprestamo);
            PR.PR_PKG_REPRESTAMOS.p_generar_bitacora(pIdReprestamo, NULL, 'AN', NULL, 'Represtamo anulado por salto de Tipo Credito', USER);
            UPDATE PR.PR_SOLICITUD_REPRESTAMO 
            SET ESTADO = 'AN' 
            WHERE ID_REPRESTAMO = pIdReprestamo;
            
            UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'E', OBSERVACIONES = 'Represtamo anulado por salto de Tipo Credito',FECHA_MODIFICACION = SYSDATE , MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER)
            WHERE ESTADO='T' AND NO_CREDITO = (SELECT NO_CREDITO FROM PR.PR_REPRESTAMOS WHERE ID_REPRESTAMO = pIdReprestamo );
        ELSE
            DBMS_OUTPUT.PUT_LINE('CREDITO = ' || CREDITO);
            DBMS_OUTPUT.PUT_LINE('pIdReprestamo = ' || pIdReprestamo);
            IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
                UPDATE PR.PR_SOLICITUD_REPRESTAMO 
                SET TIPO_CREDITO = CREDITO 
                WHERE ID_REPRESTAMO = pIdReprestamo;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No se encontraron datos para la consulta.');
        WHEN OTHERS THEN
            DECLARE
                vIdError PLS_INTEGER := 0;
            BEGIN
                IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo', pIdReprestamo);
                IA.LOGGER.ADDPARAMVALUEV('pUsuario', pUsuario);        
                IA.LOGGER.ADDPARAMVALUEV('NUEVO_TIPO_CREDITO', NUEVO_TIPO);                          
                setError(pProgramUnit => 'P_Registra_Solicitud_Campana_Tipo_Credito', 
                         pPieceCodeName => NULL, 
                         pErrorDescription => SQLERRM,                                                              
                         pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                         pEmailNotification => NULL, 
                         pParamList => IA.LOGGER.vPARAMLIST, 
                         pOutputLogger => FALSE, 
                         pExecutionTime => NULL, 
                         pIdError => vIdError); 
            END;
    END;

    IF pIdReprestamo IS NOT NULL AND F_Validar_Telefono(v_Telefono_Celular) IS NOT NULL THEN
        INSERT INTO PR.PR_CANALES_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION)
        VALUES (PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo, pIdReprestamo, 1, F_Validar_Telefono(v_Telefono_Celular), pUsuario, SYSDATE);
    END IF;

    COMMIT;
EXCEPTION 
    WHEN OTHERS THEN
        DECLARE
            vIdError PLS_INTEGER := 0;
        BEGIN
            IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo', pIdReprestamo);
            IA.LOGGER.ADDPARAMVALUEV('pUsuario', pUsuario);        
            IA.LOGGER.ADDPARAMVALUEV('NUEVO_TIPO_CREDITO', NUEVO_TIPO);    
            setError(pProgramUnit => 'P_Registra_Solicitud_Campana', 
                     pPieceCodeName => NULL, 
                     pErrorDescription => SQLERRM,                                                              
                     pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                     pEmailNotification => NULL, 
                     pParamList => IA.LOGGER.vPARAMLIST, 
                     pOutputLogger => FALSE, 
                     pExecutionTime => NULL, 
                     pIdError => vIdError); 
        END;
END P_Registra_Solicitud_Campana;

    PROCEDURE P_Actualizar_Datos_Solicitud(pIdReprestamo        IN     VARCHAR2,
                                           pCanal               IN     VARCHAR2,
                                           pEstado              IN     VARCHAR2,
                                           pStep                IN     VARCHAR2,
                                           pPlazo               IN     NUMBER,                                                
                                           pTelefonoCelular     IN     VARCHAR2,
                                           pTelefonoResidencia  IN     VARCHAR2,
                                           pTelefonoTrabajo     IN     VARCHAR2,
                                           pEmail               IN     VARCHAR2,
                                           pDireccion           IN     VARCHAR2,                                           
                                           pMensaje             IN OUT VARCHAR2) IS
    BEGIN
        IF pEstado in ('LA','EP', 'SC') THEN
            
            
            BEGIN
                UPDATE PR.PR_SOLICITUD_REPRESTAMO S
                   SET s.ESTADO = pEstado, 
                       s.PLAZO = pPlazo, 
                       s.TELEFONO_CELULAR = NVL(pTelefonoCelular, s.TELEFONO_CELULAR), 
                       s.TELEFONO_RESIDENCIA = NVL(pTelefonoResidencia,s.TELEFONO_RESIDENCIA),
                       s.TELEFONO_TRABAJO = NVL(pTelefonoTrabajo,s.TELEFONO_TRABAJO),
                       s.EMAIL = NVL(pEmail,s.EMAIL), 
                       s.DIRECCION = NVL(pDireccion, s.DIRECCION) 
                 WHERE S.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                   AND S.ID_REPRESTAMO = pIdReprestamo; 
                   COMMIT;
            EXCEPTION WHEN OTHERS THEN
                pMensaje := 'Fallo al registrar la solicitud. Intente m¿s tarde.';    
                RAISE_APPLICATION_ERROR(-20010, pMensaje);  
            END;
        ELSE
            pMensaje := 'No es posible actualizar la solicitud en el Estado '||pEstado;
            RAISE_APPLICATION_ERROR(-20010, pMensaje);
        END IF;
        
        -- Genera en la Bitacora la actualiza el Represtamo
        p_generar_bitacora(pIdReprestamo, NULL, pEstado, pStep, NULL,  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));                               
        --p_validar_Cambio_Estado(pIdReprestamo, pEstado);
        COMMIT;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',       pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',              pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pEstado',             pEstado);
          IA.LOGGER.ADDPARAMVALUEV('pStep',               pStep);
          IA.LOGGER.ADDPARAMVALUEV('pPlazo',              pPlazo);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoCelular',    pTelefonoCelular);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoResidencia', pTelefonoResidencia);
          IA.LOGGER.ADDPARAMVALUEV('pTelefonoTrabajo',    pTelefonoTrabajo);
          IA.LOGGER.ADDPARAMVALUEV('pEmail',              pEmail);
          IA.LOGGER.ADDPARAMVALUEV('pDireccion',          pDireccion);
                                           
          setError(pProgramUnit => 'P_Actualizar_Datos_Solicitud', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END P_Actualizar_Datos_Solicitud;
    
    PROCEDURE P_Actualizar_Canal_Represtamo ( pCod_persona  IN  VARCHAR2,
                                              pcod_area     IN  VARCHAR2,
                                              Pnum_telefono IN  VARCHAR2,
                                              pMensaje      IN OUT VARCHAR2) IS
    BEGIN
            DECLARE
            vid_represtamo VARCHAR2(100);
            vEstado VARCHAR2(100);
            v_telefono      VARCHAR2(100);
            
                       CURSOR REPRESTAMOS IS 
                          SELECT RE.ROWID ID, RE.ID_REPRESTAMO,RE.ESTADO 
                          FROM PR.PR_REPRESTAMOS RE 
                          WHERE RE.CODIGO_CLIENTE   = pCod_persona 
                          AND RE.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ACTUALIZAR_CANAL_REPRESTAMO')));        
                          
                      CURSOR TELEFONOS_ACTUALIZAR IS 
                          SELECT RE.ROWID ID, RE.ID_REPRESTAMO,RE.ESTADO 
                          FROM PR.PR_REPRESTAMOS RE 
                          WHERE RE.CODIGO_CLIENTE   = pCod_persona 
                          AND RE.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PARA_ACTUALIZACION_DE_EMAIL_TELEFONO'))); 
            
            
                         
           BEGIN
            
                FOR A IN TELEFONOS_ACTUALIZAR LOOP
                vid_represtamo :=A.ID_REPRESTAMO;
                vEstado := A.ESTADO;
                
                
                IF PR_PKG_REPRESTAMOS.F_VALIDAR_TELEFONO(pcod_area || pnum_telefono) IS NOT NULL THEN
                
                    IF F_Existe_Canales(A.ID_REPRESTAMO) = FALSE THEN
                    
                        INSERT INTO PR.PR_CANALES_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION, MODIFICADO_POR, FECHA_MODIFICACION) 
                        VALUES ( 1,A.ID_REPRESTAMO,1,pcod_area ||Pnum_telefono ,USER,SYSDATE,NULL,SYSDATE );
                       
                    ELSE
                        UPDATE PR.PR_CANALES_REPRESTAMO S 
                        SET  S.CANAL = 1, S.VALOR = pcod_area ||Pnum_telefono
                        WHERE  S.ID_REPRESTAMO = A.ID_REPRESTAMO AND S.CANAL = 1;      

                    END IF;
                    
                   UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TELEFONO_CELULAR = pcod_area ||Pnum_telefono
                   WHERE  S.CODIGO_EMPRESA = 1 AND S.ID_REPRESTAMO = A.ID_REPRESTAMO;
                   
                ELSE
                    PR_PKG_REPRESTAMOS.p_generar_bitacora(vid_represtamo, NULL,vEstado, NULL,'No se pudo actualizar el canal del represtamo debido a que el telefono no cumple con el formato permitido: ' || pcod_area || pnum_telefono, USER);
                END IF;
                         
             END LOOP;
            
            
              FOR A IN REPRESTAMOS LOOP
                vid_represtamo :=A.ID_REPRESTAMO;
                vEstado := A.ESTADO;

                IF PR_PKG_REPRESTAMOS.F_VALIDAR_TELEFONO(pcod_area || pnum_telefono) IS NOT NULL THEN
                    IF F_Existe_Canales(A.ID_REPRESTAMO) = FALSE THEN
                    
                        INSERT INTO PR.PR_CANALES_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION, MODIFICADO_POR, FECHA_MODIFICACION) 
                        VALUES ( 1,A.ID_REPRESTAMO,1,pcod_area ||Pnum_telefono ,USER,SYSDATE,NULL,SYSDATE );

                        
                      FOR B IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ACTUALIZAR_CANAL_REPRESTAMO'))) LOOP
                         IF A.ESTADO = B.COLUMN_VALUE THEN 
                            PR_PKG_REPRESTAMOS.p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Canal actualizado y resprestamo en estado NP', USER);
                            
                        END IF;
                      END LOOP;
                    ELSE
                        UPDATE PR.PR_CANALES_REPRESTAMO S 
                        SET  S.CANAL = 1, S.VALOR = pcod_area ||Pnum_telefono
                        WHERE  S.ID_REPRESTAMO = A.ID_REPRESTAMO AND S.CANAL = 1; 
                       
                     FOR B IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_ACTUALIZAR_CANAL_REPRESTAMO'))) LOOP  
                         IF A.ESTADO = B.COLUMN_VALUE THEN 
                                PR_PKG_REPRESTAMOS.p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Canal actualizado y resprestamo en estado NP', USER);
                               
                            END IF;
                       END LOOP; 
                        
                    END IF;
                   
                   UPDATE PR.PR_SOLICITUD_REPRESTAMO S SET S.TELEFONO_CELULAR = pcod_area ||Pnum_telefono
                   WHERE  S.CODIGO_EMPRESA = 1 AND S.ID_REPRESTAMO = A.ID_REPRESTAMO;
                ELSE
                    PR_PKG_REPRESTAMOS.p_generar_bitacora(vid_represtamo, NULL,vEstado, NULL,'No se pudo actualizar el canal del represtamo debido a que el telefono no cumple con el formato permitido: ' || pcod_area || pnum_telefono, USER);
                    
                END IF;


             END LOOP;

            EXCEPTION WHEN OTHERS THEN
            pMensaje :=  'Error al ejecutar '|| SQLERRM;

            END; 
         
         EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pCod_persona',      pCod_persona);          
              IA.LOGGER.ADDPARAMVALUEV('pcod_area',         pcod_area);
              IA.LOGGER.ADDPARAMVALUEV('Pnum_telefono',     Pnum_telefono);
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);
              
              setError(pProgramUnit => 'P_Actualizar_Canal_Represtamo', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
                       
                     
            END;          
        
    END P_Actualizar_Canal_Represtamo;
    
  PROCEDURE P_Actualizar_Email_Represtamo  (pCod_persona  IN  VARCHAR2,
                                            PEmail         IN  VARCHAR2,
                                            pMensaje          IN OUT VARCHAR2) IS
      BEGIN
            DECLARE
            vid_represtamo VARCHAR2(100);
            vEstado VARCHAR2(100);
            
                       CURSOR REPRESTAMOS IS 
                          SELECT RE.ROWID ID, RE.ID_REPRESTAMO,RE.ESTADO 
                          FROM PR.PR_REPRESTAMOS RE 
                          WHERE RE.CODIGO_CLIENTE   = pCod_persona 
                          AND RE.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PARA_ACTUALIZACION_DE_EMAIL_TELEFONO')));                  
            BEGIN
            
              FOR A IN REPRESTAMOS LOOP
                vid_represtamo :=A.ID_REPRESTAMO;
                vEstado := A.ESTADO;
                    
                    
                      FOR B IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_PARA_ACTUALIZACION_DE_EMAIL_TELEFONO'))) LOOP
                         IF A.ESTADO = B.COLUMN_VALUE THEN 
                            --vEstado
                          UPDATE PR.PR_SOLICITUD_REPRESTAMO
                            SET    EMAIL                  = PEmail
                            WHERE  CODIGO_EMPRESA          = 1
                            AND    ID_REPRESTAMO           = A.ID_REPRESTAMO; 
                        END IF;
                      END LOOP;
             END LOOP;

            EXCEPTION WHEN OTHERS THEN
            pMensaje :=  'Error al ejecutar '|| SQLERRM; 
            END;                                       
                                            
          EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pCod_persona',      pCod_persona);          
              IA.LOGGER.ADDPARAMVALUEV('PEmail',            PEmail); 
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje); 
              setError(pProgramUnit => 'P_Actualizar_Email_Represtamo', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END;                                            
  END P_Actualizar_Email_Represtamo; 
                                              
    PROCEDURE P_Actualizar_Anular_Represtamo( pMensaje IN OUT VARCHAR2, pIDAPLICACION IN OUT NUMBER) IS
    
    
    BEGIN
    
    
                /*DECLARE
                CURSOR CUR_DATOS IS 
                 SELECT ID_REPRESTAMO
                 FROM PR_REPRESTAMOS
                 WHERE ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_CALCULAR_OPCIONES')))
                 --'AYN','AEP','AYR','BLI','BLP','DBA','NR','PS','AYS','LA','AP','MS','EP','SC'
                 AND XCORE_CUSTOM >0;
            VMSG  VARCHAR2(4000);*/
            
                      
            BEGIN
            
            PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.ACTUALIZAR_ANULAR_REPRESTAMO',25,pMensaje);
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION, 'ENPROCESO', 75, 'EN PROCESO', pMensaje );
              --1 Anular solicitudes
              PR_PKG_REPRESTAMOS.P_ANULAR_REPRESTAMOS_INACTIVOS;
              -- 2 Recalcular opciones de represtamo
              /*FOR A IN CUR_DATOS LOOP
              DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                PR_PKG_REPRESTAMOS.P_CARGAR_OPCION_REPRESTAMO(A.ID_REPRESTAMO, VMSG);
                COMMIT;
               -- IF vMsg IS NOT NULL THEN
                    DBMS_OUTPUT.PUT_LINE ( 'vMsg = ' || VMSG );
                    VMSG := NULL;
               -- END IF;
              END LOOP;*/
              COMMIT;
              
              --ACTUALIZO EL DETALLE DE LA BITACORA
              PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'EN PROCESO', pMensaje );
              --FINALIZO EL DETALLE DE LA BITACORA
               PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje ); 
        END;
              
    EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              pMensaje:='ERROR CON EL STORE PROCEDURE P_ACTUALIZAR_ANULAR_REPRESTAMO';
              setError(pProgramUnit => 'P_Actualizar_Anular_Represtamo', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
                       
            PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET ( pIDAPLICACION, 'ERROR', 100, SQLERRM,pMensaje );
              
            END;       
               
         
    END P_Actualizar_Anular_Represtamo;
 
   

   PROCEDURE P_Carga_Precalifica_Represtamo ( pMensaje IN OUT VARCHAR2) IS

       BEGIN
                DECLARE
                CURSOR CUR_REPRESTAMO IS 
                 SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
                 FROM PR_REPRESTAMOS
                 WHERE ESTADO = 'RE';

            VMSG  VARCHAR2(4000);
            pIDAPLICACION1 NUMBER;
            pIDAPLICACION2 NUMBER;
            pIDAPLICACION3 NUMBER;
            pIDAPLICACION4 NUMBER;
            
          BEGIN
              --1 
              PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo( pMensaje,pIDAPLICACION1);
              --2
              PR_PKG_REPRESTAMOS.Precalifica_Represtamo(pIDAPLICACION2);
              --3
              PR_PKG_REPRESTAMOS.Actualiza_Precalificacion(pIDAPLICACION3);
              --4
              PR_PKG_REPRESTAMOS.Actualiza_XCORE_CUSTOM(pIDAPLICACION4);
                         
              FOR A IN CUR_REPRESTAMO LOOP
              --DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
               p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                COMMIT;
               -- IF vMsg IS NOT NULL THEN
                    DBMS_OUTPUT.PUT_LINE ( 'vMsg = ' || VMSG );
                    VMSG := NULL;
               -- END IF;
               
                              -- validar que tenga solicitud, que tenga canales
               IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) THEN 
                   PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
               ELSE
                IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE THEN
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                ELSE
                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                END IF;
                
                END IF; 
              END LOOP;
         
              COMMIT;
              --5
              /*FOR A IN CUR_REPRESTAMO LOOP
              DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                PR_PKG_REPRESTAMOS.P_Cargar_Opcion_Represtamo(A.ID_REPRESTAMO,VMSG);
               --p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                COMMIT;
               -- IF vMsg IS NOT NULL THEN
                    DBMS_OUTPUT.PUT_LINE ( 'vMsg = ' || VMSG );
                    VMSG := NULL;
               -- END IF;
               

               /*-- validar que tenga solicitud, que tenga canales y que tenga opciones 
               IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) AND F_Existe_Opciones(A.ID_REPRESTAMO) THEN 
                   PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
               ELSE
                IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Opciones(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE THEN
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                ELSE
                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                END IF;
                
                END IF; 
              END LOOP;
              COMMIT;*/

               COMMIT;
        END;
   
       EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              
              setError(pProgramUnit => 'P_Carga_Precalifica_Represtamo', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END;          
   END P_Carga_Precalifica_Represtamo;
   
   PROCEDURE P_REGISTRO_SOLICITUD(pIDAPLICACION IN OUT NUMBER) IS
        
       VMSG  VARCHAR2(4000);
       pMensaje      VARCHAR2(100);  
       idCabeceraDet NUMBER; 
            
       CURSOR CUR_REPRESTAMO IS 
       SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
       FROM PR_REPRESTAMOS
       WHERE ESTADO = 'RE';
            
      BEGIN
      
            PR.PR_PKG_TRAZABILIDAD.PR_VERIFICAR_O_CREAR_REGISTRO_DET(pIDAPLICACION,'RD_CARGA.REGISTRAR_SOLICITUD',50,pMensaje);

                
                FOR A IN CUR_REPRESTAMO LOOP
                    PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
                            
                    PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                            
                    COMMIT;
                END LOOP ;
                PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ENPROCESO', 100, 'SE ACTUALIZO', pMensaje );
                PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_DET (pIDAPLICACION, 'FINALIZADO', 'SE FINALIZO', pMensaje );
                      
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
                           PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_DET (pIDAPLICACION, 'ERROR', 100, SQLERRM, pMensaje );
                     END;    
            --END;     
       
                 
  END P_REGISTRO_SOLICITUD;
   
  PROCEDURE P_Carga_Precalifica_Cancelado ( pMensaje IN OUT VARCHAR2) IS

  
    BEGIN
    
          --Crear bitacora Cabecera
        PR_PKG_TRAZABILIDAD.PR_CREAR_BITACORA_CAB ( 'RD_CARGA_PRECALIFICACION', 'ACTIVO', Null,pMensaje);
        
        DECLARE
        
        CURSOR CUR_REPRESTAMO IS 
            SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
            FROM PR_REPRESTAMOS
            WHERE ESTADO = 'RE';
                         
        CURSOR CUR_REPRESTAMO_XCORE IS 
         SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL
         FROM PR_REPRESTAMOS
         WHERE ESTADO = 'RE';
           
         VMSG  VARCHAR2(4000);
         v_Id_Represtamo  VARCHAR2(400);
         v_conteo  NUMBER(10);
         v_ini DATE;
         v_fin DATE;
         v_seg NUMBER(10);
         VALOR VARCHAR(400);
         
         --ESTO ES DE BITACORA
         VIDCABECERA NUMBER;
         pIDAPLICACION1 NUMBER;
         pIDAPLICACION2 NUMBER;
         pIDAPLICACION3 NUMBER;
         pIDAPLICACION4 NUMBER;
         pIDAPLICACION5 NUMBER;
         pIDAPLICACION6 NUMBER;
         pIDAPLICACION7 NUMBER;
         pIDAPLICACION8 NUMBER;
         pIDAPLICACION9 NUMBER;
         pIDAPLICACION10 NUMBER;
         pIDAPLICACION11 NUMBER;
         
           BEGIN
                  
                    SELECT MAX(APC.ID_APLICACION_PASO_CAB) 
                    INTO VIDCABECERA 
                    FROM PR.PR_APLICACION_PASO_CAB APC 
                    JOIN PR.PR_APLICACION A ON A.ID_APLICACION=APC.ID_APLICACION 
                    WHERE CODIGO_APLICACION='RD_CARGA_PRECALIFICACION';
                            
                     --INICIALIZO EL PROCESO
                    PR.PR_PKG_TRAZABILIDAD.PR_ACTUALIZAR_BITACORA_CAB ( VIDCABECERA, 'INICIADO',0, 'PROCESO INICIADO', PMENSAJE );
                      
                      
                      --1  
                      PR.PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo( pMensaje,pIDAPLICACION1);
                                            
                       --2
                       PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo(pIDAPLICACION2);
                       --3                        
                       --PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores(pIDAPLICACION3);
                       --4
                       --PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores_hi(pIDAPLICACION4);                                        
                       --5
                       PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado(pIDAPLICACION5);
                       --6
                       PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi(pIDAPLICACION6);

                      
                        BEGIN
                          SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
                       END;
                       --7
                      PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion(pIDAPLICACION7);
                      
                      --8
                      PR.PR_PKG_REPRESTAMOS.Actualiza_XCORE_CUSTOM(pIDAPLICACION8);
                     
                      --9
                      PR.PR_PKG_REPRESTAMOS.P_REGISTRO_SOLICITUD(pIDAPLICACION9);
                      
                      --10     
                       PR.PR_PKG_REPRESTAMOS.PVALIDA_WORLD_COMPLIANCE(pIDAPLICACION10);
                      COMMIT;     

                      --11
                      PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE(pIDAPLICACION11);  
                      COMMIT;

                    
                      
                      FOR A IN CUR_REPRESTAMO LOOP
                      --DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );

                        -- validar que tenga solicitud, que tenga canales
                        IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO)AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN 
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
                         
                         ELSE
                         
                            IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) = FALSE THEN
                             PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                            ELSE
                                IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN
                                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                                ELSE
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                                END IF;
                
                        END IF; 
                       
                       END IF;
                      
                      END LOOP;
                      
                
                --FINALIZO EL PROCESO DE LA CABECERA
                PR.PR_PKG_TRAZABILIDAD.PR_FINALIZAR_BITACORA_CAB(VIDCABECERA);
                COMMIT;
                 
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='EJECUCIONES';
                COMMIT;

      END;
                
       EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              
              setError(pProgramUnit => 'P_Carga_Precalifica_Cancelado', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END;          
   END P_Carga_Precalifica_Cancelado; 
   
   PROCEDURE P_Carga_Precalifica_Manual(pMensaje             IN OUT VARCHAR2) IS
   
     BEGIN
          DECLARE
          CURSOR CUR_REPRESTAMO IS 
          SELECT ID_REPRESTAMO,ESTADO,XCORE_GLOBAL,NO_CREDITO
          FROM PR_REPRESTAMOS
          WHERE ESTADO = 'RE';

          VMSG  VARCHAR2(4000);
          pIDAPLICACION1 NUMBER;
          v_Id_Represtamo  VARCHAR2(400);
          v_conteo  NUMBER(10);
          v_ini DATE;
          v_fin DATE;
          v_seg NUMBER(10);
          v_proceso_activo VARCHAR2(4000);
          BEGIN
          
            v_proceso_activo:= PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CARGA_DIRIGIDA_PROCESO_ACTIVO');
            IF  v_proceso_activo='N' THEN 
            
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='S' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CARGA_DIRIGIDA_PROCESO_ACTIVO';
                COMMIT;
                
            
                  --1
                  PR.PR_PKG_REPRESTAMOS.Precalifica_Carga_Dirigida;
                     
                    BEGIN
                      SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
                   DBMS_OUTPUT.PUT_LINE ( 'v_conteo = ' || v_conteo );
                   END;
                  --2
                  PR.PR_PKG_REPRESTAMOS.Actualiza_Preca_Dirigida;
                  --3
                  PR_PKG_REPRESTAMOS.ACTUALIZA_XCORE_DIRIGIDA;
                      

                                 
                  FOR A IN CUR_REPRESTAMO LOOP
                  --DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                    PR.PR_PKG_REPRESTAMOS.P_Registra_Solicitud_Dirigida(A.ID_REPRESTAMO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
                   p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                  UPDATE PR.PR_CARGA_DIRECCIONADA SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
                    COMMIT;

                       
                    -- validar que tenga solicitud, que tenga canales
                    IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO)AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN 
                     PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
                         
                     ELSE
                         
                        IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) = FALSE THEN
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                        ELSE
                            IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                            ELSE
                            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                            END IF;
                
                    END IF; 
                       
                   END IF;
                       
                  END LOOP;
                  
                  --5
                  IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_XCORE_CARGADIRIGIDA') = 'S' THEN
                  PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE(pIDAPLICACION1);
                    DBMS_OUTPUT.PUT_LINE ( 'VALIDO EL XCORE' );
                  COMMIT;
                  END IF;
                  
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='CARGA_DIRIGIDA_EJECUCIONES';
                COMMIT;
                
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CARGA_DIRIGIDA_PROCESO_ACTIVO';
                COMMIT;
                
          END IF;

          END;
                
           
   
            EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              
              setError(pProgramUnit => 'P_Carga_Precalifica_Manual', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END; 
    END P_Carga_Precalifica_Manual;  
    PROCEDURE P_Carga_Precalifica_Campana_Especial(pMensaje             IN OUT VARCHAR2)IS
   
     BEGIN
          DECLARE
          CURSOR CUR_REPRESTAMO IS 
          SELECT R.ID_REPRESTAMO,C.TIPO_CREDITO,R.ESTADO,R.XCORE_GLOBAL,R.NO_CREDITO
          FROM PR_REPRESTAMOS R
          LEFT JOIN PR_CAMPANA_ESPECIALES C ON C.NO_CREDITO = R.NO_CREDITO AND C.ID_CAMPANA_ESPECIALES =R.ID_REPRE_CAMPANA_ESPECIALES
          WHERE R.ESTADO = 'RE';

          VMSG  VARCHAR2(4000);
          pIDAPLICACION1 NUMBER;
          v_Id_Represtamo  VARCHAR2(400);
          v_conteo  NUMBER(10);
          v_ini DATE;
          v_fin DATE;
          v_seg NUMBER(10);
          v_proceso_activo VARCHAR2(4000);
          BEGIN
          
            v_proceso_activo:= PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CAMPANA_ESPECIAL_PROCESO_ACTIVO');
            IF  v_proceso_activo='N' THEN 
            
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='S' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_PROCESO_ACTIVO';
                COMMIT;
                
            
                  --1
                  PR.PR_PKG_REPRESTAMOS.Precalifica_Campana_Especiales;
                  
                     
                    BEGIN
                      SELECT COUNT(*) INTO v_conteo  FROM PR.PR_REPRESTAMOS R  WHERE ESTADO = 'RE';
                   DBMS_OUTPUT.PUT_LINE ( 'v_conteo = ' || v_conteo );
                   END;
                  --2
                  PR.PR_PKG_REPRESTAMOS.Actualiza_Preca_Campana_Especiale;
                  --3
                  PR_PKG_REPRESTAMOS.ACTUALIZA_XCORE_CAMPANA_ESPECIAL;
                      

                                 
                  FOR A IN CUR_REPRESTAMO LOOP
                  --DBMS_OUTPUT.PUT_LINE ( 'Entra = '||A.ID_REPRESTAMO  );
                    PR.PR_PKG_REPRESTAMOS.P_Registra_Solicitud_Campana(A.ID_REPRESTAMO,A.TIPO_CREDITO,NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),VMSG);
                    COMMIT;
                  END LOOP;
                    
                  FOR A IN CUR_REPRESTAMO LOOP
                    DBMS_OUTPUT.PUT_LINE ( 'A.ESTADO = ' || A.ESTADO|| '--- ' || A.ID_REPRESTAMO );
                  -- IF A.ESTADO = 'RE' THEN
                   
                    p_generar_bitacora(A.ID_REPRESTAMO, NULL, 'RE', NULL, '',  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));
                    UPDATE PR.PR_CAMPANA_ESPECIALES SET ESTADO = 'F',FECHA_MODIFICACION = SYSDATE, MODIFICADO_POR=NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) WHERE NO_CREDITO = A.NO_CREDITO AND ESTADO='T';
                    COMMIT;
                   -- END IF;

                       
                    -- validar que tenga solicitud, que tenga canales
                    IF  F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO)AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN 
                     PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificaci¿n Pendiente', USER);
                         
                     ELSE
                         
                        IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) = FALSE THEN
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                        ELSE
                            IF F_Existe_Solicitudes(A.ID_REPRESTAMO) AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO ( A.ID_REPRESTAMO ) THEN
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                            ELSE
                            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                            END IF;
                
                    END IF; 
                       
                   END IF;
                       
                  END LOOP;
                  
                  --5
                  IF PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('VALIDAR_XCORE_CAMPANA') = 'S' THEN
                  PR.PR_PKG_REPRESTAMOS.PVALIDA_XCORE(pIDAPLICACION1);
                    DBMS_OUTPUT.PUT_LINE ( 'VALIDO EL XCORE' );
                  COMMIT;
                  END IF;
                  
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR=VALOR||(CASE WHEN NVL(REGEXP_COUNT(VALOR, '}'),0)>0 THEN ',' ELSE '' END)||'{"F":"'||TO_CHAR(SYSDATE,'dd/mm/yyyy hh:mi:ss')||'","R":'||v_conteo||',"E":'||NVL(REGEXP_COUNT(VALOR, '}')+1,1)||'}'
                WHERE CODIGO_MVP = 'REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_EJECUCIONES';
                COMMIT;
                UPDATE PA.PA_PARAMETROS_MVP SET VALOR='N' WHERE CODIGO_MVP='REPRESTAMOS' AND CODIGO_PARAMETRO='CAMPANA_ESPECIAL_PROCESO_ACTIVO';
                COMMIT;
                
          END IF;

          END;
                
           
   
            EXCEPTION WHEN OTHERS THEN
            DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              
              IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
              
              setError(pProgramUnit => 'P_Carga_Precalifica_Campana_Especial', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END; 
    
    
    END P_Carga_Precalifica_Campana_Especial;         
    PROCEDURE P_Registrar_Rechazo(pIdReprestamo   IN     VARCHAR2,
                                  pCanal          IN     VARCHAR2,
                                  pIdRechazo      IN     VARCHAR2,
                                  pMensaje        IN OUT VARCHAR2) IS
        vDescripcion    VARCHAR2(4000);            
        vNoPromo        VARCHAR2(2) := F_Obt_Parametro_Represtamo('DECLINA_ACTUALIZA_PROMO');     
        vSMS            NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);
        vCanalCore      PA.CANAL_PROMOCION.COD_CANAL%TYPE;                 
    BEGIN
        -- Busca la Opcion Seleccionada
        BEGIN
            SELECT R.DESCRIPCION, CASE pCanal WHEN TO_CHAR(vSMS) THEN 'SMS' WHEN TO_CHAR(vEMAIL) THEN 'MAIL' END
              INTO vDescripcion, vCanalCore
              FROM PR.PR_V_RECHAZO_REPRESTAMOS r
              WHERE r.CODIGO_RECHAZO = pIdRechazo;
        EXCEPTION WHEN OTHERS THEN
            pMensaje := 'Fall¿, Opci¿n de rechazo no encontrada.'; 
            RAISE_APPLICATION_ERROR(-20010, pMensaje);
        END;
    
        -- Genera en la Bitacora la anulacion y actualiza el Represtamo
        p_generar_bitacora(pIdReprestamo, pCanal, 'RZ', NULL, vDescripcion,  NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER));                               
        --p_validar_Cambio_Estado(pIdReprestamo, 'RZ');
                
        BEGIN
            
            UPDATE PR.PR_SOLICITUD_REPRESTAMO S
               SET S.ESTADO = 'RZ', S.OPCION_RECHAZO = pIdRechazo                  
             WHERE S.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo 
               AND S.ID_REPRESTAMO = pIdReprestamo; 
            
           pMensaje := 'Solicitud '||pIdReprestamo||' Rechazada con la opci¿n: '||vDescripcion;     
           --COMMIT;    
        EXCEPTION WHEN OTHERS THEN
            pMensaje := 'Fallo Registrando la raz¿n de declinaci¿n, Intente m¿s tarde';            
            RAISE_APPLICATION_ERROR(-20010, pMensaje);
        END;
        
        BEGIN
            IF vNoPromo = pIdRechazo THEN
                
                UPDATE PA.PROMOCION_PERSONA p
                   SET P.AUTORIZADO = 'N', P.COD_ORIGEN = 'RD'
                 WHERE P.COD_PERSONA = ( SELECT CODIGO_CLIENTE
                                            FROM PR.PR_REPRESTAMOS r
                                           WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo 
                                             AND r.ID_REPRESTAMO = pIdReprestamo)
                   AND P.COD_CANAL = vCanalCore;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            pMensaje := 'Fallo el sistema de promociones del Core';            
            RAISE_APPLICATION_ERROR(-20010, pMensaje);
        END;
        
        COMMIT;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',          pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pIdRechazo',        pIdRechazo);  
          
          setError(pProgramUnit => 'P_Registrar_Rechazo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;  
               
    END P_Registrar_Rechazo;     
    
    PROCEDURE Enviar_Correo_API(pEmail            IN     VARCHAR2,
                                pNombres          IN     VARCHAR2,
                                pApellidos        IN     VARCHAR2,
                                pSubject          IN     VARCHAR2,
                                pFormatoMensaje   IN     VARCHAR2,
                                pMensaje          IN     VARCHAR2,
                                pRespuesta        IN OUT VARCHAR2) IS      
      
      vUrlBase  VARCHAR2(1000) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI   VARCHAR2(1000);
      
      v_response      CLOB;
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
      
   BEGIN
      BEGIN                
            
           APEX_WEB_SERVICE.g_request_headers.delete();
           APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
           APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';        
           
           -- Desencriptar ruta y pass
           vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
           vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
           vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
                       
           vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendReLoanEmail';--'http://bma0112:8001/api/Notification/SendReLoanEmail';
           
           --DBMS_OUTPUT.PUT_LINE(vUrlAPI);
           
           -- GET Response with Token
           v_response := apex_web_service.make_rest_request(
                 p_url           => vUrlAPI,
                 p_http_method   => 'POST',
                 p_body          => '{ "toName": "'||pNombres||' '||pApellidos||'", "toEmail": "'||pEmail||'", "subject": "'||pSubject||'", "message": "'||pMensaje||'" }',                 
                 p_wallet_path   => vRutaWallet,
                 p_wallet_pwd    => vPassWallet);

           --DBMS_OUTPUT.PUT_LINE('RESPONSE: '||v_response);
      
      EXCEPTION WHEN OTHERS THEN
        pRespuesta := SQLERRM;        
      END;  
      
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pEmail',            pEmail);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pSubject',          pSubject);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Enviar_Correo_API', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;         
      
   END Enviar_Correo_API;   
   PROCEDURE Enviar_Correo_API_ENCUESTA(pIdReprestamo   IN     NUMBER,
                                 pEmail            IN     VARCHAR2,
                                 pNombres          IN     VARCHAR2,
                                 pApellidos        IN     VARCHAR2,
                                 pSubject          IN     VARCHAR2,
                                 pFormatoMensaje   IN     VARCHAR2,
                                 pMensaje          IN     VARCHAR2,
                                 pRespuesta        IN OUT VARCHAR2) IS      
      
      vUrlBase  VARCHAR2(1000) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI   VARCHAR2(1000);
      
      v_response      CLOB;
     
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
   BEGIN
      BEGIN                
            
           APEX_WEB_SERVICE.g_request_headers.delete();
           APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
           APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';  
           
           -- Desencriptar ruta y pass
           vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
           vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
           vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
                  
           
           vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendSurveyLinkByEmail';--'http://bma0112:8001/api/Notification/SendReLoanEmail';
           
           --DBMS_OUTPUT.PUT_LINE(vUrlAPI);
           
           -- GET Response with Token
           v_response := apex_web_service.make_rest_request(
                 p_url           => vUrlAPI,
                 p_http_method   => 'POST',
                 p_body          => '{"sessionId": "'||pIdReprestamo||'","toName": "'||pNombres||' '||pApellidos||'","toEmail": "'||pEmail||'","subject": "'||pSubject||'","message": "'||pMensaje||'"}',
                 p_wallet_path   => vRutaWallet,
                 p_wallet_pwd    => vPassWallet
                 );

           --DBMS_OUTPUT.PUT_LINE('RESPONSE: '||v_response);
      
      EXCEPTION WHEN OTHERS THEN
        pRespuesta := SQLERRM;        
      END;  
      
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);  
          IA.LOGGER.ADDPARAMVALUEV('pEmail',            pEmail);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pSubject',          pSubject);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Enviar_Correo_API_ENCUESTA', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;        
      
   END Enviar_Correo_API_ENCUESTA;   
   PROCEDURE Enviar_Sms_Api(pIdreprestamo       IN     VARCHAR2,
                            pTelefono           IN     VARCHAR2,
                            pNombres            IN     VARCHAR2,
                            pApellidos          IN     VARCHAR2,
                            pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                            pFormatoMensaje     IN     VARCHAR2,
                            pMensaje            IN     VARCHAR2,
                            pRespuesta          IN OUT VARCHAR2) IS
                            
      vNotificacion   PA.tNotificacion := PA.tNotificacion();
      vIdRprestamo VARCHAR2(4000); 
      v_response      CLOB;
      vUrlBase  VARCHAR2(256) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI   VARCHAR2(256);

      vBody     VARCHAR2(4000);
      
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
   BEGIN
      IF pTipoNotificacion = 'SMS' THEN
         BEGIN
                
               -- Set Header with Token
               APEX_WEB_SERVICE.g_request_headers.delete ();
               APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
               APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
               
               -- Desencriptar ruta y pass
               vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
               vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
               vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
          
               
              vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendSMS';    
                --vUrlAPI := 'http://bma0112.bancoademi.local:8078/api/Notification/SendSMS';  
               DBMS_OUTPUT.PUT_LINE ( 'IDREPRESTAMO DENTRO DE ENVIAR SMS: '|| pIdReprestamo);
               DBMS_OUTPUT.PUT_LINE ( 'vUrlAPI = ' || vUrlAPI );
               vBody := '{"sessionId": "'||pIdreprestamo||'","name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
               --vBody :='{"sessionId": "'||pIdReprestamo||'","name": "'||pNombre||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(12), ''),'\n','')||'"}';           
               -- GET Response with Token
               v_response := apex_web_service.make_rest_request(
                     p_url           => vUrlAPI,
                     p_http_method   => 'POST',
                     p_body          => vBody,
                     p_wallet_path   => vRutaWallet,
                     p_wallet_pwd    => vPassWallet  
                                
               );                                
          DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );           
         EXCEPTION WHEN OTHERS THEN
            pRespuesta := SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
         END;
      ELSIF pTipoNotificacion = 'WHAT' THEN
         BEGIN
            -- Usar API de WHATSAPP
            pRespuesta := 'ERROR API NO desarrollado.';
         END;
      END IF;
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',         pTelefono);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pTipoNotificacion', pTipoNotificacion);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Enviar_Sms_Api', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          RAISE_APPLICATION_ERROR(-20100, SQLERRM);                     
        END;  
   END Enviar_Sms_Api;  
   PROCEDURE Enviar_SMS_API_DESBLOQUEO(pIdreprestamo       IN     VARCHAR2,
                            pTelefono           IN     VARCHAR2,
                            pNombres            IN     VARCHAR2,
                            pApellidos          IN     VARCHAR2,
                            pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                            pFormatoMensaje     IN     VARCHAR2,
                            pMensaje            IN     VARCHAR2,
                            pRespuesta          IN OUT VARCHAR2) IS
                            
      vNotificacion   PA.tNotificacion := PA.tNotificacion();
      vIdRprestamo VARCHAR2(4000); 
      v_response      CLOB;
      vUrlBase  VARCHAR2(256) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI   VARCHAR2(256);

      vBody     VARCHAR2(4000);
      
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
   BEGIN
      IF pTipoNotificacion = 'SMS' THEN
         BEGIN
                
               -- Set Header with Token
               APEX_WEB_SERVICE.g_request_headers.delete ();
               APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
               APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
               
               -- Desencriptar ruta y pass
               vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
               vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
               vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
          
               
              vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/ForwardingLinkBySMS';    
                --vUrlAPI := 'http://bma0112.bancoademi.local:8078/api/Notification/SendSMS';  
               DBMS_OUTPUT.PUT_LINE ( 'IDREPRESTAMO DENTRO DE ENVIAR SMS: '|| pIdReprestamo);
               DBMS_OUTPUT.PUT_LINE ( 'vUrlAPI = ' || vUrlAPI );
               vBody := '{"sessionId": "'||pIdreprestamo||'","name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
               --vBody :='{"sessionId": "'||pIdReprestamo||'","name": "'||pNombre||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(12), ''),'\n','')||'"}';           
               -- GET Response with Token
               v_response := apex_web_service.make_rest_request(
                     p_url           => vUrlAPI,
                     p_http_method   => 'POST',
                     p_body          => vBody,
                     p_wallet_path   => vRutaWallet,
                     p_wallet_pwd    => vPassWallet  
                                
               );                                
          DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );           
         EXCEPTION WHEN OTHERS THEN
            pRespuesta := SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
         END;
      ELSIF pTipoNotificacion = 'WHAT' THEN
         BEGIN
            -- Usar API de WHATSAPP
            pRespuesta := 'ERROR API NO desarrollado.';
         END;
      END IF;
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',         pTelefono);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pTipoNotificacion', pTipoNotificacion);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Enviar_SMS_API_DESBLOQUEO', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          RAISE_APPLICATION_ERROR(-20100, SQLERRM);                     
        END;  
   END Enviar_SMS_API_DESBLOQUEO;  
  PROCEDURE Enviar_Sms_Api_ENCUESTA(pIdReprestamo       IN     NUMBER,
                              pTelefono           IN     VARCHAR2,
                              pNombres            IN     VARCHAR2,
                              pApellidos          IN     VARCHAR2,
                              pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                              pFormatoMensaje     IN     VARCHAR2,
                              pMensaje            IN     VARCHAR2,
                              pRespuesta          IN OUT VARCHAR2) IS
      vNotificacion   PA.tNotificacion := PA.tNotificacion();
      v_response        CLOB;
      vUrlBase          VARCHAR2(256) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI           VARCHAR2(256);
      vBody             VARCHAR2(4000);
      vKey              RAW(2000);
      vRutaWallet       VARCHAR2(1000); 
      vPassWallet       VARCHAR2(200);
   BEGIN
      IF pTipoNotificacion = 'SMS' THEN
         BEGIN
                
               -- Set Header with Token
               APEX_WEB_SERVICE.g_request_headers.delete ();
               APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
               APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
               
               -- Desencriptar ruta y pass
               vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
               vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
               vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
                         
               vUrlAPI := PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/SendSurveyLinkBySMS';      
               
               --vBody := '{"name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
               vBody :='{"sessionId": "'||pIdReprestamo||'","name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
                          
               -- GET Response with Token
               v_response := apex_web_service.make_rest_request(
                     p_url           => vUrlAPI,
                     p_http_method   => 'POST',
                     p_body          => vBody,
                     p_wallet_path   => vRutaWallet,
                     p_wallet_pwd    => vPassWallet                                       
               );                                
          
         EXCEPTION WHEN OTHERS THEN
            pRespuesta := SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
         END;
      ELSIF pTipoNotificacion = 'WHAT' THEN
         BEGIN
            -- Usar API de WHATSAPP
            pRespuesta := 'ERROR API NO desarrollado.';
         END;
      END IF;
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);  
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',         pTelefono);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pTipoNotificacion', pTipoNotificacion);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Enviar_Sms_Api_ENCUESTA', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          RAISE_APPLICATION_ERROR(-20100, SQLERRM);                     
        END;  
   END Enviar_Sms_Api_ENCUESTA; 
   
   PROCEDURE Reenviar_Sms_Api(pIdReprestamo       IN     NUMBER,
                              pTelefono           IN     VARCHAR2,
                              pNombres            IN     VARCHAR2,
                              pApellidos          IN     VARCHAR2,
                              pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                              pFormatoMensaje     IN     VARCHAR2,
                              pMensaje            IN     VARCHAR2,
                              pRespuesta          IN OUT VARCHAR2) IS
      vNotificacion   PA.tNotificacion := PA.tNotificacion();
      v_response      CLOB;
      vUrlBase        VARCHAR2(256) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI         VARCHAR2(256);
      vBody           VARCHAR2(4000);
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
   BEGIN
      IF pTipoNotificacion = 'SMS' THEN
         BEGIN
                
               -- Set Header with Token
               APEX_WEB_SERVICE.g_request_headers.delete ();
               APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
               APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
               
               -- Desencriptar ruta y pass
               vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
               vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
               vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
               
               
               vUrlAPI := PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/ForwardingLinkBySMS';    
               DBMS_OUTPUT.PUT_LINE ( vUrlAPI );
               
               --vBody := '{"name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
               vBody :='{"sessionId": "'||pIdReprestamo||'","name": "'||pNombres||'","number": "'||pTelefono||'","message": "'||REPLACE(REPLACE(pMensaje, CHR(13), ''),'\n','')||'"}';
               DBMS_OUTPUT.PUT_LINE ( 'vBody = ' || vBody );           
               -- GET Response with Token
               v_response := apex_web_service.make_rest_request(
                     p_url           => vUrlAPI,
                     p_http_method   => 'POST',
                     p_body          => vBody,
                     p_wallet_path   => vRutaWallet,
                     p_wallet_pwd    => vPassWallet                                       
               );  
               
               /*v_response := apex_web_service.make_rest_request(
                     p_url           => vUrlAPI,
                     p_http_method   => 'POST',
                     p_body          => vBody                                       
               );  */       
          
         EXCEPTION WHEN OTHERS THEN
            pRespuesta := SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
         END;
      ELSIF pTipoNotificacion = 'WHAT' THEN
         BEGIN
            -- Usar API de WHATSAPP
            pRespuesta := 'ERROR API NO desarrollado.';
         END;
      END IF;
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);  
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',         pTelefono);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pTipoNotificacion', pTipoNotificacion);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Reenviar_Sms_Api', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
          RAISE_APPLICATION_ERROR(-20100, SQLERRM);                     
        END;  
   END Reenviar_Sms_Api; 
   
   PROCEDURE Reenviar_Correo_API(pIdReprestamo       IN     NUMBER,
                                 pEmail            IN     VARCHAR2,
                                 pNombres          IN     VARCHAR2,
                                 pApellidos        IN     VARCHAR2,
                                 pSubject          IN     VARCHAR2,
                                 pFormatoMensaje   IN     VARCHAR2,
                                 pMensaje          IN     VARCHAR2,
                                 pRespuesta        IN OUT VARCHAR2) IS      
      
      vUrlBase  VARCHAR2(1000) := OBT_PARAMETROS('1', 'PA', 'RUTA_API_ORDS');
      vUrlAPI   VARCHAR2(1000);
      
      v_response      CLOB;
      vBody           VARCHAR2(4000);
      
      vKey            RAW(2000);
      vRutaWallet     VARCHAR2(1000); 
      vPassWallet     VARCHAR2(200);
      
   BEGIN
      BEGIN                
            
           APEX_WEB_SERVICE.g_request_headers.delete();
           APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
           APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';  
           
           -- Desencriptar ruta y pass
           vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
           vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
           vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
                  
           
           vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') ||'api/Notification/ForwardingLinkByEmail';--'http://bma0112:8001/api/Notification/SendReLoanEmail';           
           --DBMS_OUTPUT.PUT_LINE(vUrlAPI);
           vBody := '{"sessionId": "'||pIdReprestamo||'","toName": "'||pNombres||' '||pApellidos||'","toEmail": "'||pEmail||'","subject": "'||pSubject||'","message": "'||pMensaje||'"}';
           
           -- GET Response with Token
           v_response := apex_web_service.make_rest_request(
                 p_url           => vUrlAPI,
                 p_http_method   => 'POST',
                 p_body          => vBody,
                 p_wallet_path   => vRutaWallet,
                 p_wallet_pwd    => vPassWallet);

           --DBMS_OUTPUT.PUT_LINE('RESPONSE: '||v_response);
           pRespuesta := v_response;
      EXCEPTION WHEN OTHERS THEN
        pRespuesta := SQLERRM;        
      END;  
      
   EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);  
          IA.LOGGER.ADDPARAMVALUEV('pEmail',            pEmail);
          IA.LOGGER.ADDPARAMVALUEV('pNombres',          pNombres);
          IA.LOGGER.ADDPARAMVALUEV('pApellidos',        pApellidos);
          IA.LOGGER.ADDPARAMVALUEV('pSubject',          pSubject);
          IA.LOGGER.ADDPARAMVALUEV('pFormatoMensaje',   pFormatoMensaje);
          IA.LOGGER.ADDPARAMVALUEV('pMensaje',          pMensaje);          
          
          setError(pProgramUnit => 'Reenviar_Correo_API', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;         
      
   END Reenviar_Correo_API;  
   
   FUNCTION F_Reenviar_Represtamo(pIdReprestamoAnt IN      NUMBER,
                                  pUsuario         IN      VARCHAR2,
                                  pError           IN OUT  VARCHAR2) 
      RETURN NUMBER IS
       CURSOR cReprestamo(pIdReprestamo IN NUMBER) IS
        SELECT *
          FROM PR.PR_REPRESTAMOS r
         WHERE r.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND R.ID_REPRESTAMO  = pIdReprestamo
           AND r.ESTADO NOT IN ('EP', 'SC', 'CRS', 'CRV', 'CRH', 'CRA', 'CRD');  
        TYPE tReprestamos IS TABLE OF cReprestamo%ROWTYPE;
        vReprestamo      tReprestamos := tReprestamos();  
        
        vIdReprestamoNuevo  PR.PR_REPRESTAMOS.ID_REPRESTAMO%TYPE := 0;  
        
        CURSOR cCanal (pIdReprestamo IN NUMBER) IS
        SELECT * 
          FROM PR.PR_CANALES_REPRESTAMO c 
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND C.ID_REPRESTAMO = pIdReprestamo
           AND C.CANAL = C.CANAL ||'';

        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal tCanal := tCanal();
        
        CURSOR cSolicitud(pIdReprestamo IN NUMBER) IS
        SELECT * 
          FROM PR.PR_SOLICITUD_REPRESTAMO S
         WHERE S.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND S.ID_REPRESTAMO = pIdReprestamo;
        
        TYPE tSolicitud IS TABLE OF cSolicitud%ROWTYPE;
        vSolicitud tSolicitud := tSolicitud();
        
        CURSOR cOpcion(pIdReprestamo IN NUMBER) IS
        SELECT * 
          FROM PR.PR_OPCIONES_REPRESTAMO o
         WHERE o.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND o.ID_REPRESTAMO = pIdReprestamo
           AND o.PLAZO > 0;
        
        TYPE tOpcion IS TABLE OF cOpcion%ROWTYPE;
        vOpcion tOpcion := tOpcion();  

    BEGIN
        -- Busca datos del represtamo anterior
        OPEN cReprestamo(pIdReprestamoAnt);        
        LOOP
            FETCH cReprestamo BULK COLLECT INTO vReprestamo LIMIT 1;            
            FOR i IN 1 .. vReprestamo.COUNT LOOP
                vIdReprestamoNuevo := PR_PKG_REPRESTAMOS.f_genera_secuencia;
                BEGIN
                    INSERT INTO PR.PR_REPRESTAMOS
                       (CODIGO_EMPRESA, ID_REPRESTAMO, CODIGO_CLIENTE, FECHA_CORTE, NO_CREDITO, 
                        ESTADO, CODIGO_PRECALIFICACION, DIAS_ATRASO, FECHA_PROCESO, PIN, 
                        INTENTOS_PIN, INTENTOS_IDENTIFICACION, IND_SOLICITA_AYUDA, MTO_CREDITO_ACTUAL, MTO_PREAPROBADO, 
                        OBSERVACIONES, ADICIONADO_POR, FECHA_ADICION, ESTADO_ORIGINAL)
                     VALUES
                       (vReprestamo(i).CODIGO_EMPRESA, vIdReprestamoNuevo, 
                        vReprestamo(i).CODIGO_CLIENTE, vReprestamo(i).FECHA_CORTE, vReprestamo(i).NO_CREDITO, 
                        'RE', vReprestamo(i).CODIGO_PRECALIFICACION, vReprestamo(i).DIAS_ATRASO, vReprestamo(i).FECHA_PROCESO, 
                        PA.PKG_NOTIFICACIONES.GENERAR_PIN_RANDOM(100, 999999), 
                        PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN'),
                        PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION'), 'N', 
                        vReprestamo(i).MTO_CREDITO_ACTUAL, vReprestamo(i).MTO_PREAPROBADO, 
                        vReprestamo(i).OBSERVACIONES, pUsuario, SYSDATE, 'RE');
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error Insertando nuevo Represtamo';
                    RAISE_APPLICATION_ERROR(-20100, pError);
                END;                
            END LOOP;            
            EXIT WHEN cReprestamo%NOTFOUND;            
        END LOOP;        
        CLOSE cReprestamo;  
        COMMIT;               
        
        IF vIdReprestamoNuevo IS NOT NULL THEN                       
            --  Inserta los canales del Represtamo Nuevo
            OPEN cCanal(pIdReprestamoAnt);            
            LOOP
                FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
                FOR x IN 1 .. vCanal.COUNT LOOP
                    BEGIN
                        INSERT INTO PR.PR_CANALES_REPRESTAMO ( CODIGO_EMPRESA, ID_REPRESTAMO, CANAL, VALOR, ADICIONADO_POR, FECHA_ADICION )
                        VALUES ( vCanal(x).CODIGO_EMPRESA, vIdReprestamoNuevo, vCanal(x).CANAL, vCanal(x).VALOR, pUsuario, SYSDATE);
                    EXCEPTION WHEN OTHERS THEN
                        pError := 'Error Insertando los canales del Represtamo';
                        RAISE_APPLICATION_ERROR(-20100, pError);
                    END;                        
                    DBMS_OUTPUT.PUT_LINE('INSERT CANAL '||vIdReprestamoNuevo||' CANAL:'||vCanal(x).CANAL);
                END LOOP;
                EXIT WHEN cCanal%NOTFOUND;
            END LOOP;
            CLOSE cCanal;
            COMMIT;
            
            -- Generar las Opciones
            BEGIN
                OPEN cOpcion(pIdReprestamoAnt);
                LOOP
                    FETCH cOpcion BULK COLLECT INTO vOpcion LIMIT 500;
                    FOR o IN 1 .. vOpcion.COUNT LOOP
                        BEGIN
                            INSERT INTO PR.PR_OPCIONES_REPRESTAMO
                            ( CODIGO_EMPRESA, ID_REPRESTAMO, PLAZO, MTO_PRESTAMO, MTO_DESCONTAR, MTO_DEPOSITAR, MTO_CUOTA, MTO_CARGOS, 
                              MTO_SEGURO_VIDA, MTO_SEGURO_DESEMPLEO, TASA, ORDEN, ESTADO, ADICIONADO_POR, FECHA_ADICION, MTO_CUOTA_TOTAL ) 
                            VALUES
                            ( vOpcion(o).CODIGO_EMPRESA, vIdReprestamoNuevo, vOpcion(o).PLAZO, vOpcion(o).MTO_PRESTAMO, vOpcion(o).MTO_DESCONTAR, vOpcion(o).MTO_DEPOSITAR, vOpcion(o).MTO_CUOTA, vOpcion(o).MTO_CARGOS,
                              vOpcion(o).MTO_SEGURO_VIDA, vOpcion(o).MTO_SEGURO_DESEMPLEO, vOpcion(o).TASA, vOpcion(o).ORDEN, vOpcion(o).ESTADO, pUsuario, SYSDATE, vOpcion(o).MTO_CUOTA_TOTAL );
                        EXCEPTION WHEN OTHERS THEN
                            pError := 'Error Insertando las opciones del Represtamo ';
                            RAISE_APPLICATION_ERROR(-20100, pError||' '||SQLERRM);    
                        END;
                        DBMS_OUTPUT.PUT_LINE('INSERT OPCION '||vIdReprestamoNuevo||' PLAZO:'||vOpcion(o).PLAZO);
                    END LOOP;
                    EXIT WHEN cOpcion%NOTFOUND;
                END LOOP;
                CLOSE cOpcion;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('DATOS DE OPCIONES NO ENCONTRADOS '||pIdReprestamoAnt||' '||SQLERRM);   
            END;              
            COMMIT; 
                    
            BEGIN
                -- Generar los datos de la solicitud Solicitud
                OPEN cSolicitud(pIdReprestamoAnt);                
                LOOP
                    FETCH cSolicitud BULK COLLECT INTO vSolicitud LIMIT 500;
                    FOR s IN 1 .. vSolicitud.COUNT LOOP
                        BEGIN
                            INSERT INTO PR.PR_SOLICITUD_REPRESTAMO 
                            (
                              CODIGO_EMPRESA, ID_REPRESTAMO, NOMBRES, APELLIDOS, IDENTIFICACION, FEC_NACIMIENTO, SEXO, NACIONALIDAD, ESTADO_CIVIL,
                              TELEFONO_CELULAR, TELEFONO_RESIDENCIA, TELEFONO_TRABAJO, EMAIL, COD_DIRECCION, TIP_DIRECCION, DIRECCION, PLAZO,
                              ESTADO, ADICIONADO_POR, FECHA_ADICION                                  
                            )
                            VALUES
                            (
                              vSolicitud(s).CODIGO_EMPRESA, vIdReprestamoNuevo, vSolicitud(s).NOMBRES, vSolicitud(s).APELLIDOS, vSolicitud(s).IDENTIFICACION,
                              vSolicitud(s).FEC_NACIMIENTO, vSolicitud(s).SEXO, vSolicitud(s).NACIONALIDAD, vSolicitud(s).ESTADO_CIVIL,
                              vSolicitud(s).TELEFONO_CELULAR, vSolicitud(s).TELEFONO_RESIDENCIA, vSolicitud(s).TELEFONO_TRABAJO, vSolicitud(s).EMAIL,
                              vSolicitud(s).COD_DIRECCION, vSolicitud(s).TIP_DIRECCION, vSolicitud(s).DIRECCION, vSolicitud(s).PLAZO, vSolicitud(s).ESTADO,
                              pUsuario, SYSDATE
                            );
                        EXCEPTION WHEN OTHERS THEN
                            pError := 'Error Insertando los datos de la solicitud del Represtamo';
                            RAISE_APPLICATION_ERROR(-20100, pError);
                        END; 
                        DBMS_OUTPUT.PUT_LINE('INSERT SOLICITUD '||vIdReprestamoNuevo);                    
                    END LOOP;
                    EXIT WHEN cSolicitud%NOTFOUND;
                END LOOP;        
                CLOSE cSolicitud;   
            EXCEPTION WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('DATOS DE SOLICITUD NO ENCONTRADOS '||pIdReprestamoAnt||' '||SQLERRM);   
            END;     
            COMMIT;        
        
            -- Anular Represtamo Anterior
            PR_PKG_REPRESTAMOS.p_generar_bitacora(pIdReprestamoAnt,NULL,'AN',NULL,'Anulado por Solicitud nuevo Link', pUsuario);    
            --p_validar_Cambio_Estado(pIdReprestamoAnt, 'AN');
            
            -- Cargar la Bitacoras
            PR_PKG_REPRESTAMOS.p_generar_bitacora(vIdReprestamoNuevo,NULL,'RE',NULL,'Carga inicial', pUsuario);                        
            PR_PKG_REPRESTAMOS.p_generar_bitacora(vIdReprestamoNuevo,NULL,'VR',NULL,'Preparado para la Validaci¿n Riesgo', pUsuario);    
            --p_validar_Cambio_Estado(vIdReprestamoNuevo, 'VR');
            PR_PKG_REPRESTAMOS.p_generar_bitacora(vIdReprestamoNuevo,NULL,'NP',NULL,'Validaci¿n realizada por Riesgo', pUsuario);    
            --p_validar_Cambio_Estado(vIdReprestamoNuevo, 'NP');
            
            -- Notificar al cliente el Nuevo Link
            P_Notificar_Reenvio_Link(vIdReprestamoNuevo, pError);
            
            COMMIT;
        END IF;        
        RETURN vIdReprestamoNuevo;
    EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEN('pIdReprestamoAnt', pIdReprestamoAnt);
          IA.LOGGER.ADDPARAMVALUEV('pUsuario', pUsuario);
          
          setError(pProgramUnit => 'F_Reenviar_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;  
    END F_Reenviar_Represtamo;    
                                                   
    PROCEDURE P_Anular_Represtamos_Inactivos(pIdReprestamo IN NUMBER DEFAULT NULL) IS
    -- Elaborado por Jose D¿az. 22/08/2022
    -- Se inactivan todos los represtamos que no concluyeron el proceso
    -- Este proceso debe de ejecutarse previo a la recarga autom¿tica diaria
    CURSOR CUR_Anular IS
        SELECT id_represtamo
        FROM PR_REPRESTAMOS
        WHERE codigo_empresa =PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        and  id_represtamo = nvl(pIdReprestamo,id_represtamo)
        and ESTADO in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
        AND TRUNC(FECHA_proceso)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK')<=TRUNC(SYSDATE);
        --and rownum<=10;
        
    CURSOR CUR_Anular_campana_especiales IS
        SELECT id_represtamo
        FROM PR_REPRESTAMOS
        WHERE codigo_empresa =PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
        and  id_represtamo = nvl(pIdReprestamo,id_represtamo)
        and ESTADO in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
        AND TRUNC(FECHA_proceso)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK_CANCELADOS')<=TRUNC(SYSDATE);  
          
    CURSOR CUR_Anular_creditos_cancelados IS
             SELECT id_represtamo, no_credito
            FROM PR_REPRESTAMOS a
            WHERE codigo_empresa =PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
            and ESTADO in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_CREDITOS_CANCELADOS')))
            and not exists (select 1
                            from pr_creditos
                            where no_credito = a.no_credito
                            and estado in (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_CREDITOS'))))
            and not exists(
                            select 1
                            from pr_creditos_hi h
                            where h.no_credito = a.no_credito
                            and h.F_CANCELACION >= SYSDATE - TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
                            and h.F_CANCELACION <= SYSDATE
                            and h.estado = 'C');
    BEGIN
     --Se procede a anular los represtamos asociados cr¿ditos que se cancelan en el dia por abono normal o cancelaci¿n de cr¿dito
      FOR a in CUR_Anular_creditos_cancelados LOOP
        PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo,NULL,'CC',NULL,'Anulacion por cancelaci¿n de credito '||a.no_credito, USER);
      END LOOP; 
      
      FOR a in CUR_Anular LOOP
        PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo, NULL, 'AN', NULL, 'Represtamo anulado (Link Vencido) por no concluir proceso.', USER );
        --PR_PKG_REPRESTAMOS.p_validar_Cambio_Estado(a.id_represtamo, 'AN');
        DBMS_OUTPUT.PUT_LINE ( 'id_represtamo = ' || a.id_represtamo );
      END LOOP;
      
      FOR a in CUR_Anular_campana_especiales LOOP
        PR_PKG_REPRESTAMOS.p_generar_bitacora(a.id_represtamo, NULL, 'AN', NULL, 'Represtamo anulado (Link Vencido) por no concluir proceso.', USER );
        --PR_PKG_REPRESTAMOS.p_validar_Cambio_Estado(a.id_represtamo, 'AN');
        DBMS_OUTPUT.PUT_LINE ( 'id_represtamo = ' || a.id_represtamo );
      END LOOP;

      COMMIT;
      
    EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEN('pId_represtamo', pIdReprestamo);
          setError(pProgramUnit => 'P_Anular_Represtamos_Inactivos', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;                   
                
    END P_Anular_Represtamos_Inactivos;
    
    PROCEDURE P_Notificar_Estado(pIdReprestamo    IN      VARCHAR2,
                                 pCanal           IN      VARCHAR2,
                                 pCodigoEstado    IN      VARCHAR2,
                                 pRespuesta       IN OUT  VARCHAR2) IS
        CURSOR cCanal (pIdRep       IN NUMBER) IS
        SELECT C.CANAL, C.VALOR
          FROM PR.PR_CANALES_REPRESTAMO c
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
           AND C.ID_REPRESTAMO = pIdReprestamo
           AND C.CANAL = NVL(pCanal, C.CANAL);
        
        TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
        vCanal      tCanal  := tCanal();
        vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
        vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);  
        vNotificacion PA.tNotificacion := PA.tNotificacion();
        vMensaje      VARCHAR2(4000);
        vSubject      VARCHAR2(600);
    BEGIN
        OPEN cCanal(pIdReprestamo);
        LOOP
            FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;
            FOR i IN 1 .. vCanal.COUNT LOOP
                IF vCanal(i).Canal = vSMS THEN
                    -- Reemplazar el mensaje del parametro 
                    vMensaje := REPLACE(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('TEXTO_SMS_ESTADO'),'[ESTADO]', PR.PR_PKG_REPRESTAMOS.F_Obt_Descripcion_Estado(pCodigoEstado));
                    DBMS_OUTPUT.PUT_LINE ( 'Esto es el mensaje vMensaje = ' || vMensaje );        
                    vNotificacion.CANAL := 'SMS';
                    vNotificacion.SUBJECT := NULL;
                    vNotificacion.FORMATO_MENSAJE := 'TEXT';
                    vNotificacion.MENSAJE := vMensaje;
                    vNotificacion.CONTACTO := vCanal(i).VALOR;
                    BEGIN
                        -- Enviar SMS
                        Enviar_SMS_API( 
                                pIdReprestamo       => pIdReprestamo,
                                pTelefono           => vNotificacion.CONTACTO ,
                                pNombres            => vNotificacion.NOMBRES ,
                                pApellidos          => vNotificacion.APELLIDOS,
                                pTipoNotificacion   => vNotificacion.CANAL,
                                pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                                pMensaje            => vNotificacion.MENSAJE,
                                pRespuesta          => pRespuesta);
                                            
                        vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                        DBMS_OUTPUT.PUT_LINE ( 'IDREPRESTAMO DENTRO DEL P_Notificar_Estado: '|| vNotificacion.MENSAJE);
                        DBMS_OUTPUT.PUT_LINE ( 'vNotificacion.CONTACTO: '|| vNotificacion.CONTACTO);
                    EXCEPTION WHEN OTHERS THEN
                        pRespuesta := SQLERRM;
                    END;                
                    
                    vNotificacion.ERROR_RESPUESTA := pRespuesta;  
                  
               /* ELSIF vCanal(i).CANAL = vEMAIL THEN  
                    -- Reemplazar el mensaje del parametro 
                    vMensaje := REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL_ESTADO'),'[ESTADO]', F_Obt_Descripcion_Estado(pCodigoEstado));
                    vSubject := REPLACE(f_obt_parametro_Represtamo('SUBJECT_EMAIL'),'[FECHA]', TO_CHAR(SYSDATE, 'DD-MM-YYYY'));
                    vNotificacion.CANAL := 'EMAIL';
                    vNotificacion.SUBJECT := vSubject;
                    vNotificacion.FORMATO_MENSAJE := 'HTML';
                    vNotificacion.MENSAJE := vMensaje;
                                  
                    BEGIN
                        -- Enviar Correo
                        Enviar_Correo_API( 
                                pEmail              => vNotificacion.CONTACTO ,
                                pNombres            => vNotificacion.NOMBRES ,
                                pApellidos          => vNotificacion.APELLIDOS,
                                pSubject            => vNotificacion.SUBJECT, 
                                pFormatoMensaje     => vNotificacion.FORMATO_MENSAJE,
                                pMensaje            => vNotificacion.MENSAJE,
                                pRespuesta          => pRespuesta);
                                
                        vNotificacion.MENSAJE_RESPUESTA := pRespuesta;
                    EXCEPTION WHEN OTHERS THEN
                        pRespuesta := SQLERRM;
                    END;            */    
                    
                    vNotificacion.ERROR_RESPUESTA := pRespuesta;  
                    DBMS_OUTPUT.PUT_LINE('Mensaje Enviado');
                END IF;
            END LOOP; 
            EXIT WHEN cCanal%NOTFOUND;
        END LOOP;
        CLOSE cCanal;
        
     EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pCanal',            pCanal);
          IA.LOGGER.ADDPARAMVALUEV('pCodigoEstado',     pCodigoEstado);  
          IA.LOGGER.ADDPARAMVALUEV('pRespuesta',        pRespuesta);
          
          setError(pProgramUnit => 'P_Notificar_Estado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;  
    END P_Notificar_Estado;
    
    FUNCTION F_Validar_Existe_IdDeclinar(pIdDeclinar     IN VARCHAR2)
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_V_RECHAZO_REPRESTAMOS R 
         WHERE R.CODIGO_RECHAZO = pIdDeclinar;
    
        RETURN (vExiste > 0);
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdDeclinar',            pIdDeclinar);  
          
          setError(pProgramUnit => 'F_Validar_Existe_IdDeclinar', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
    END F_Validar_Existe_IdDeclinar;
    FUNCTION F_Validar_Tipo_Represtamo(pIdReprestamo IN NUMBER)
     RETURN BOOLEAN IS
    vExiste     PLS_INTEGER := 0;
     BEGIN
     SELECT COUNT(1) INTO vExiste
       FROM PR.PR_REPRESTAMOS R
       WHERE R.ID_REPRE_CAMPANA_ESPECIALES IS NOT NULL
       AND R.ID_REPRESTAMO = pIdReprestamo;
       
       RETURN (vExiste > 0);
       
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Validar_Tipo_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
    END F_Validar_Tipo_Represtamo;
    FUNCTION F_Validar_Existe_Estado(pCodigoEstado     IN VARCHAR2)
      RETURN BOOLEAN IS
         vExiste     PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1) INTO vExiste FROM PR.PR_ESTADOS_REPRESTAMO E WHERE E.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo AND E.CODIGO_ESTADO = pCodigoEstado;
        
        RETURN (vExiste > 0);
        
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigoEstado',            pCodigoEstado);  
          
          setError(pProgramUnit => 'F_Validar_Existe_Estado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
    END F_Validar_Existe_Estado;
  FUNCTION F_Validar_Listas_PEP (
    p_codempresa IN VARCHAR2,
    p_codpersona IN VARCHAR2) RETURN NUMBER IS
   BEGIN
            IF PA.P_DATOS_PERSONA.esta_en_lista_pep(p_codempresa, p_codpersona) THEN
                RETURN 1;
            ELSE
                RETURN 0;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('p_codempresa',            p_codempresa);  
          IA.LOGGER.ADDPARAMVALUEV('p_codpersona',            p_codpersona);
          
          setError(pProgramUnit => 'F_Validar_Listas_PEP', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
            
   END;
        
  FUNCTION F_Validar_Lista_NEGRA (
    p_codempresa IN VARCHAR2,
    p_codpersona IN VARCHAR2) RETURN NUMBER IS
    BEGIN
            IF PA.P_DATOS_PERSONA.esta_en_lista_negra(p_codempresa, p_codpersona) THEN
                RETURN 1;
            ELSE
                RETURN 0;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('p_codempresa',            p_codempresa);  
          IA.LOGGER.ADDPARAMVALUEV('p_codpersona',            p_codpersona);
          
          setError(pProgramUnit => 'F_Validar_Lista_NEGRA', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
            
    END;    
    FUNCTION F_Existe_Represtamo(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_REPRESTAMOS R 
         WHERE R.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND R.ID_REPRESTAMO = pIdReprestamo;
           
        RETURN (vExiste > 0);
    
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',        pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Existe_Represtamo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
    END F_Existe_Represtamo;
    
    FUNCTION F_Existe_Solicitudes(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_SOLICITUD_REPRESTAMO R 
         WHERE R.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND R.ID_REPRESTAMO = pIdReprestamo;
           
        RETURN (vExiste > 0);
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',        pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Existe_Solicitudes', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
    END F_Existe_Solicitudes;
  
  FUNCTION F_Existe_Credito(pIdReprestamo IN NUMBER )
            
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_SOLICITUD_REPRESTAMO R 
         WHERE R.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND R.ID_REPRESTAMO = pIdReprestamo
           AND R.TIPO_CREDITO IS NOT NULL;
           
        RETURN (vExiste > 0);
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',        pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Existe_Credito', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Existe_Credito;
    FUNCTION F_Existe_Canales(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_CANALES_REPRESTAMO R 
         WHERE R.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND R.ID_REPRESTAMO = pIdReprestamo;
           
        RETURN (vExiste > 0);
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',        pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Existe_Canales', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Existe_Canales;
    
    
    FUNCTION F_Existe_Opciones(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN IS
        vExiste     PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_OPCIONES_REPRESTAMO R 
         WHERE R.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND R.ID_REPRESTAMO = pIdReprestamo;
           
        RETURN (vExiste > 0);
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',        pIdReprestamo);  
          
          setError(pProgramUnit => 'F_Existe_Opciones', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Existe_Opciones;
    
     
     FUNCTION F_Obtener_Total_SMS_Enviados(pIdReprestamo IN NUMBER)
      RETURN   NUMBER IS
        TOTAL NUMBER;
      
        vUrlAPI         VARCHAR2(4000);
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200);
      
      BEGIN
      
      -- Desencriptar ruta y pass
        vKey := F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
        vRutaWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
        vPassWallet := PA.DECIFRAR(F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);
          
        -- Set Header with Token
        APEX_WEB_SERVICE.g_request_headers.delete ();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';          
        vUrlAPI := F_Obt_Parametro_Represtamo('RUTA_API_MANAGER') || 'api/Notification/GetNotificationLogs?sessionId='||pIdReprestamo||'&codeOpt=SMS_Sendiu&CodeIdentity=ReloanId';
         
        SELECT COUNT(*) INTO TOTAL  
        FROM xmltable (
            '/json/row'
            passing apex_json.to_xmltype( 
                apex_web_service.make_rest_request(
                  p_url           => vUrlAPI,
                  p_http_method   => 'GET',
                  p_wallet_path   => vRutaWallet,
                  p_wallet_pwd    => vPassWallet
                ))
            columns id number path '/row/id');
        RETURN TOTAL;
        
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
      
       RETURN 0; 
            
      WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo); 
          
          setError(pProgramUnit => 'F_Obtener_Total_SMS_Enviados', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;        
      END F_Obtener_Total_SMS_Enviados;
     
 FUNCTION F_Obtener_Nuevo_Credito(pIdReprestamo IN NUMBER)
    RETURN NUMBER IS
        NUEVO_TIPO NUMBER;
        CURSOR CREDITO IS 
            SELECT TIPO_CREDITO_DESTINO 
            FROM PR.PR_REPRESTAMO_CAMPANA_DET 
            WHERE TIPO_CREDITO_ORIGEN = (SELECT TIPO_CREDITO FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO = pIdReprestamo);
    BEGIN
        IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
            FOR A IN CREDITO LOOP
                BEGIN
                    SELECT T.TIPO_CREDITO 
                    INTO NUEVO_TIPO
                    FROM PR.PR_TIPO_CREDITO_REPRESTAMO T, PR.PR_REPRESTAMOS R      
                    WHERE T.TIPO_CREDITO = A.TIPO_CREDITO_DESTINO
                      AND R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO) 
                      AND R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
                      AND ROWNUM <= 1
                      AND R.ID_REPRESTAMO = pIdReprestamo;
                    DBMS_OUTPUT.PUT_LINE('CREDITO DE CAMPAÑA ESPECIAL');
                    DBMS_OUTPUT.PUT_LINE('Nuevo Tipo de Crédito: ' || NUEVO_TIPO);
                    RETURN NUEVO_TIPO; -- Retorna el valor encontrado y sale de la función
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        DBMS_OUTPUT.PUT_LINE('No se encontró un nuevo tipo de crédito para el TIPO_CREDITO_DESTINO = ' || A.TIPO_CREDITO_DESTINO);
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
                END;
            END LOOP;
        ELSE 
            BEGIN
                SELECT (SELECT NT.TIPO_CREDITO 
                        FROM PR_TIPO_CREDITO NT 
                        WHERE R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND T.CODIGO_SUB_APLICACION = NT.CODIGO_SUB_APLICACION 
                          AND T.GRUPO_TIPO_CREDITO = NT.GRUPO_TIPO_CREDITO 
                          AND (NT.TIPO_CREDITO IN (881, 882, 883) OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC)
                          AND NT.TIPO_CREDITO NOT IN (881, 882, 883) -- Exclusión de reasignación a 881, 882, 883
                          AND EXISTS (SELECT 1 
                                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO 
                                      WHERE TIPO_CREDITO = NT.TIPO_CREDITO 
                                        AND OBSOLETO = 0)) INTO NUEVO_TIPO
                                FROM PR.PR_REPRESTAMOS R
                                LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO = R.NO_CREDITO
                                LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO = R.NO_CREDITO
                                LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
                                WHERE R.ID_REPRESTAMO = pIdReprestamo;
                
            
                /*SELECT (SELECT NT.TIPO_CREDITO FROM PR_TIPO_CREDITO NT WHERE R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) AND R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                AND T.CODIGO_SUB_APLICACION = NT.CODIGO_SUB_APLICACION AND T.GRUPO_TIPO_CREDITO = NT.GRUPO_TIPO_CREDITO AND T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC
                AND EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO IN (NT.TIPO_CREDITO) AND OBSOLETO = 0)) INTO NUEVO_TIPO
                FROM PR.PR_REPRESTAMOS R
                LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;*/
                RETURN NUEVO_TIPO;
                
                
                
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No se encontró un nuevo tipo de crédito en la parte ELSE');
            END;
        END IF;
        -- Si no se ha retornado un valor hasta este punto, retorna un valor por defecto
        RETURN 1;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          
          setError(pProgramUnit => 'F_Obtener_Nuevo_Credito', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
    END F_Obtener_Nuevo_Credito;

  FUNCTION F_Obtener_Credito_Cancelado(pIdReprestamo IN NUMBER, PMONTO IN NUMBER)
    RETURN NUMBER IS
        NUEVO_TIPO NUMBER;
        CURSOR CREDITO IS 
        SELECT TIPO_CREDITO FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO = pIdReprestamo;
       /* SELECT TIPO_CREDITO_DESTINO 
        FROM PR.PR_REPRESTAMO_CAMPANA_DET 
        WHERE TIPO_CREDITO_ORIGEN = (SELECT TIPO_CREDITO FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO = pIdReprestamo);*/
    BEGIN
        IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
            FOR A IN CREDITO LOOP
                BEGIN
                SELECT (SELECT NT.TIPO_CREDITO 
                        FROM PR_TIPO_CREDITO NT 
                        WHERE PMONTO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND PMONTO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND T.CODIGO_SUB_APLICACION = NT.CODIGO_SUB_APLICACION 
                          AND T.GRUPO_TIPO_CREDITO = NT.GRUPO_TIPO_CREDITO 
                          AND T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC 
                          AND EXISTS (SELECT 1 
                                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO 
                                      WHERE TIPO_CREDITO = NT.TIPO_CREDITO 
                                      AND OBSOLETO = 0 
                                      AND (CREDITO_CAMPANA_ESPECIAL = 'S')
                                      AND ESTADO = 'A'
                                      ))
                INTO NUEVO_TIPO
                FROM PR.PR_REPRESTAMOS R
                LEFT JOIN PR.PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
                LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = S.TIPO_CREDITO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;
                DBMS_OUTPUT.PUT_LINE('CREDITO DE CAMPAÑA ESPECIAL');
                DBMS_OUTPUT.PUT_LINE('Nuevo Tipo de Crédito: ' || NUEVO_TIPO);
                RETURN NUEVO_TIPO;
                    /*SELECT T.TIPO_CREDITO 
                    INTO NUEVO_TIPO
                    FROM PR.PR_TIPO_CREDITO_REPRESTAMO T            
                    WHERE T.TIPO_CREDITO = A.TIPO_CREDITO--A.TIPO_CREDITO_DESTINO
                      AND PMONTO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO) 
                      AND PMONTO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
                      AND ROWNUM <= 1;
                    DBMS_OUTPUT.PUT_LINE('CREDITO DE CAMPAÑA ESPECIAL');
                    DBMS_OUTPUT.PUT_LINE('Nuevo Tipo de Crédito: ' || NUEVO_TIPO);
                    RETURN NUEVO_TIPO; -- Retorna el valor encontrado y sale de la función*/
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        DBMS_OUTPUT.PUT_LINE('No se encontró un nuevo tipo de crédito para el TIPO_CREDITO_DESTINO = ' || A.TIPO_CREDITO);
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
                END;
            END LOOP;
        ELSE 
            BEGIN
                SELECT (SELECT NT.TIPO_CREDITO 
                        FROM PR_TIPO_CREDITO NT 
                        WHERE PMONTO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND PMONTO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND T.CODIGO_SUB_APLICACION = NT.CODIGO_SUB_APLICACION 
                          AND T.GRUPO_TIPO_CREDITO = NT.GRUPO_TIPO_CREDITO 
                          AND T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC 
                          -- Permitir el salto de los créditos 881, 882, 883 sin verificar FACILIDAD_CREDITIC
                          AND (NT.TIPO_CREDITO IN (SELECT TIPO_CREDITO FROM PR.PR_TIPO_CREDITO_REPRESTAMO
                                                   WHERE CREDITO_FMO = 'S') OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC)
                          -- Excluir que los créditos vayan a los tipos 881, 882 o 883
                          AND NT.TIPO_CREDITO NOT IN (SELECT TIPO_CREDITO FROM PR.PR_TIPO_CREDITO_REPRESTAMO
                                                      WHERE CREDITO_FMO = 'S')
                          AND EXISTS (SELECT 1 
                                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO 
                                      WHERE TIPO_CREDITO = NT.TIPO_CREDITO 
                                        AND OBSOLETO = 0 AND (CREDITO_CAMPANA_ESPECIAL != 'S' OR CREDITO_CAMPANA_ESPECIAL IS NULL))) 
                INTO NUEVO_TIPO
                FROM PR.PR_REPRESTAMOS R
                LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;

               /* SELECT (SELECT NT.TIPO_CREDITO 
                        FROM PR_TIPO_CREDITO NT 
                        WHERE PMONTO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND PMONTO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = NT.TIPO_CREDITO) 
                          AND T.CODIGO_SUB_APLICACION = NT.CODIGO_SUB_APLICACION 
                          AND T.GRUPO_TIPO_CREDITO = NT.GRUPO_TIPO_CREDITO 
                          AND T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC 
                          AND EXISTS (SELECT 1 
                                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO 
                                      WHERE TIPO_CREDITO = NT.TIPO_CREDITO 
                                      AND OBSOLETO = 0))
                INTO NUEVO_TIPO
                FROM PR.PR_REPRESTAMOS R
                LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;*/
                DBMS_OUTPUT.PUT_LINE('CREDITO NORMAL');
                RETURN NUEVO_TIPO;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No se encontró un nuevo tipo de crédito para el ID_REPRESTAMO = ' || pIdReprestamo);
                    RETURN NULL;
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
                    RETURN NULL;
            END;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('PMONTO',            PMONTO);
          
          setError(pProgramUnit => 'F_Obtener_Credito_Cancelado', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Obtener_Credito_Cancelado;
  
   FUNCTION F_Obtener_plazo(pIdReprestamo IN NUMBER, pMtoSeleccionado IN NUMBER)
      RETURN   NUMBER IS
      NUEVO_PLAZO NUMBER;
      V_TIPO_CREDITO NUMBER;
      BEGIN
                -- Verificar si el tipo de préstamo es válido usando la función F_Validar_Tipo_Represtamo
        IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
            -- Iterar sobre los créditos si la validación es exitosa
                BEGIN
                SELECT MAX(R.PLAZO) INTO NUEVO_PLAZO
                 FROM PR_PLAZO_CREDITO_REPRESTAMO R
                 WHERE
                    R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                    AND R.TIPO_CREDITO = (
                        SELECT (SELECT NT.TIPO_CREDITO FROM PR_TIPO_CREDITO NT WHERE pMtoSeleccionado>=(SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO) AND pMtoSeleccionado<= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO)
                        AND T.CODIGO_SUB_APLICACION=NT.CODIGO_SUB_APLICACION AND T.GRUPO_TIPO_CREDITO=NT.GRUPO_TIPO_CREDITO AND T.FACILIDAD_CREDITIC=NT.FACILIDAD_CREDITIC
                        AND EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO IN (NT.TIPO_CREDITO) AND OBSOLETO = 0 and CREDITO_CAMPANA_ESPECIAL = 'S' AND ESTADO = 'A'))
                        FROM PR.PR_REPRESTAMOS R
                        LEFT JOIN PR.PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
                        LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO = S.TIPO_CREDITO
                        WHERE R.ID_REPRESTAMO=pIdReprestamo
                        )
                 AND pMtoSeleccionado BETWEEN R.MONTO_MIN AND R.MONTO_MAX
                 GROUP BY R.TIPO_CREDITO;
                  -- Obtener el tipo de crédito desde la solicitud de préstamo
                       /* SELECT TIPO_CREDITO
                        INTO V_TIPO_CREDITO
                        FROM PR.PR_SOLICITUD_REPRESTAMO
                        WHERE ID_REPRESTAMO = pIdReprestamo;

                        -- Obtener el máximo plazo según el tipo de crédito y monto seleccionado
                        SELECT MAX(R.PLAZO) INTO NUEVO_PLAZO
                        FROM PR.PR_PLAZO_CREDITO_REPRESTAMO R
                        WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                          AND R.TIPO_CREDITO = V_TIPO_CREDITO
                          AND pMtoSeleccionado BETWEEN R.MONTO_MIN AND R.MONTO_MAX;*/
                
                    -- Obtener el máximo plazo según las condiciones
                    /*SELECT MAX(R.PLAZO) INTO NUEVO_PLAZO
                    FROM PR_PLAZO_CREDITO_REPRESTAMO R
                    WHERE
                        R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                        AND R.TIPO_CREDITO = (
                        SELECT (SELECT NT.TIPO_CREDITO FROM PR_TIPO_CREDITO NT WHERE pMtoSeleccionado>=(SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO) AND pMtoSeleccionado<= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO)
                        AND T.CODIGO_SUB_APLICACION=NT.CODIGO_SUB_APLICACION AND T.GRUPO_TIPO_CREDITO=NT.GRUPO_TIPO_CREDITO AND T.FACILIDAD_CREDITIC=NT.FACILIDAD_CREDITIC
                        AND EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO IN (NT.TIPO_CREDITO) AND OBSOLETO = 0 and (CREDITO_CAMPANA_ESPECIAL != 'N' OR CREDITO_CAMPANA_ESPECIAL IS NOT NULL)))
                        FROM PR.PR_REPRESTAMOS R
                        LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO=R.NO_CREDITO
                        LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO=R.NO_CREDITO
                        LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO=C.TIPO_CREDITO OR T.TIPO_CREDITO=H.TIPO_CREDITO
                        WHERE R.ID_REPRESTAMO=pIdReprestamo
                        )
                    AND pMtoSeleccionado BETWEEN R.MONTO_MIN AND R.MONTO_MAX
                    GROUP BY R.TIPO_CREDITO;*/
                    DBMS_OUTPUT.PUT_LINE ( 'Este plazo y credito es de campaña ' );
                END;
        ELSE
            BEGIN
                -- Si la validación no es exitosa, ejecutar un bloque alternativo
                SELECT MAX(R.PLAZO) INTO NUEVO_PLAZO
                FROM PR_PLAZO_CREDITO_REPRESTAMO R
                WHERE
                    R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                    AND R.TIPO_CREDITO = (
                        SELECT (SELECT NT.TIPO_CREDITO FROM PR_TIPO_CREDITO NT WHERE pMtoSeleccionado>=(SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO) AND pMtoSeleccionado<= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO=NT.TIPO_CREDITO)
                        AND T.CODIGO_SUB_APLICACION=NT.CODIGO_SUB_APLICACION AND T.GRUPO_TIPO_CREDITO=NT.GRUPO_TIPO_CREDITO AND T.FACILIDAD_CREDITIC=NT.FACILIDAD_CREDITIC
                        AND EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO IN (NT.TIPO_CREDITO) AND OBSOLETO = 0 and (CREDITO_CAMPANA_ESPECIAL != 'S' OR CREDITO_CAMPANA_ESPECIAL IS NULL)))
                        FROM PR.PR_REPRESTAMOS R
                        LEFT JOIN PR.PR_CREDITOS C ON C.NO_CREDITO=R.NO_CREDITO
                        LEFT JOIN PR.PR_CREDITOS_HI H ON H.NO_CREDITO=R.NO_CREDITO
                        LEFT JOIN PR.PR_TIPO_CREDITO T ON T.TIPO_CREDITO=C.TIPO_CREDITO OR T.TIPO_CREDITO=H.TIPO_CREDITO
                        WHERE R.ID_REPRESTAMO=pIdReprestamo
                        )
                AND pMtoSeleccionado BETWEEN R.MONTO_MIN AND R.MONTO_MAX
                GROUP BY R.TIPO_CREDITO;
                DBMS_OUTPUT.PUT_LINE ( 'Este plazo y credito es NORMAL ' );
            
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No se encontró un nuevo tipo de crédito para el ID_REPRESTAMO = ' || pIdReprestamo);
                    RETURN NULL;
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
                    RETURN NULL;
            END;
        END IF;
        RETURN NUEVO_PLAZO;
        
      EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pMtoSeleccionado',            pMtoSeleccionado);
          
          setError(pProgramUnit => 'F_Obtener_plazo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
      END F_Obtener_plazo;
    FUNCTION F_Existe_Plazo(pTipoCredito    IN VARCHAR2,
                            pPlazo          IN NUMBER )
      RETURN BOOLEAN IS
       vExiste     PLS_INTEGER := 0;
    BEGIN
        SELECT COUNT(1) INTO vExiste 
          FROM PR.PR_PLAZO_CREDITO_REPRESTAMO P 
         WHERE P.CODIGO_EMPRESA = F_Obt_Empresa_Represtamo 
           AND P.TIPO_CREDITO  =pTipoCredito
           AND P.PLAZO = pPlazo;
        
        RETURN (vExiste > 0);
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pTipoCredito',            pTipoCredito);
          IA.LOGGER.ADDPARAMVALUEV('pPlazo',                 pPlazo);
          
          setError(pProgramUnit => 'F_Existe_Plazo', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
    END F_Existe_Plazo;
    
    FUNCTION F_TIENE_GARANTIA(pNoCredito IN NUMBER)
   
   RETURN NUMBER IS
   vExiste     NUMBER := 0;
   BEGIN
           SELECT COUNT(1) INTO vExiste
        FROM PR_CREDITOS A,
             PR_GARANTIAS_X_CREDITO B,
             PR_GARANTIAS C
        WHERE A.codigo_empresa = F_Obt_Empresa_Represtamo
        AND A.no_credito = pNoCredito
        AND A.estado IN ('D','V','M','E','J') 
        AND B.codigo_empresa = a.codigo_empresa
        AND B.no_credito = a.no_credito
        AND C.codigo_empresa = b.codigo_empresa 
        AND C.numero_garantia = b.numero_garantia
        AND C.codigo_tipo_garantia_sb != 'NA';
        
        RETURN vExiste;
        
   EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pNoCredito',            pNoCredito);
          
          setError(pProgramUnit => 'F_TIENE_GARANTIA', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;      
    END F_TIENE_GARANTIA;
    
  FUNCTION F_TIENE_GARANTIA_HISTORICO(pNoCredito IN NUMBER)
  
   
   RETURN NUMBER IS
   vExiste     NUMBER := 0;
   BEGIN
           SELECT COUNT(1) INTO vExiste
        FROM PR_CREDITOS_HI A,
             PR_GARANTIAS_X_CREDITO B,
             PR_GARANTIAS C
        WHERE A.codigo_empresa = F_Obt_Empresa_Represtamo
        AND A.no_credito = pNoCredito
        AND A.estado IN ('D','V','M','E','J') 
        AND B.codigo_empresa = a.codigo_empresa
        AND B.no_credito = a.no_credito
        AND C.codigo_empresa = b.codigo_empresa 
        AND C.numero_garantia = b.numero_garantia
        AND C.codigo_tipo_garantia_sb != 'NA';
        
        RETURN vExiste;
        
  EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pNoCredito',            pNoCredito);
          
          setError(pProgramUnit => 'F_TIENE_GARANTIA_HISTORICO', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
  END F_TIENE_GARANTIA_HISTORICO;
    FUNCTION F_Obtiene_Desc_Bitacora(pIdReprestamo      IN NUMBER,
                                     pEstado            IN VARCHAR2)
      RETURN VARCHAR2 IS
      vDescripcion          PR.PR_BITACORA_REPRESTAMO.OBSERVACIONES%TYPE;
    BEGIN
        BEGIN
             SELECT B.OBSERVACIONES
              INTO vDescripcion 
              FROM PR.PR_BITACORA_REPRESTAMO B 
             WHERE B.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
               AND B.ID_REPRESTAMO = pIdReprestamo
               AND B.ID_BITACORA >= 0
               AND B.CODIGO_ESTADO = pEstado
               AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vDescripcion := NULL;
        END;
        
        RETURN vDescripcion;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',      pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pEstado',            pEstado);
          
          setError(pProgramUnit => 'F_Obtiene_Desc_Bitacora', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
    END F_Obtiene_Desc_Bitacora;
    
  FUNCTION F_HORARIO_VALIDO_NOTIFICACION(pfecha IN DATE)
                                        RETURN NUMBER IS
v_valido NUMBER;
v_validacion_feriado NUMBER;
v_validacion_dias_semana NUMBER;
v_hora_ini_semama VARCHAR2(10);
v_hora_fin_semama VARCHAR2(10);
v_validacion_dias_fin_semana NUMBER;
v_hora_ini_fin_semama VARCHAR2(10);
v_hora_fin_fin_semama VARCHAR2(10);
BEGIN
   
   v_valido := 0; 
 
   /*VALIDACION DE FERIADOS*/
   SELECT COUNT(1) INTO v_validacion_feriado FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('NOT_DIAS_FERIADOS')) WHERE TRIM(COLUMN_VALUE) IN (TRIM(TO_CHAR(pfecha,'DD/MM/YYYY')));
      
   IF v_validacion_feriado>0 THEN
      RETURN 0;
   END IF;
   
   /*VALIDACION DE DIAS SEMANA HABILES*/
   SELECT COUNT(1) INTO v_validacion_dias_semana FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('NOT_DIAS_SEMANA_VALIDOS')) WHERE TRIM(COLUMN_VALUE) IN (TRIM(TO_CHAR(pfecha,'DAY')));
   SELECT TRIM(REGEXP_SUBSTR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('NOT_HORARIOS_SEMANA_VALIDOS'),'[^,]+',1,1)) INTO v_hora_ini_semama FROM DUAL;
   SELECT TRIM(REGEXP_SUBSTR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('NOT_HORARIOS_SEMANA_VALIDOS'),'[^,]+',1,2)) INTO v_hora_fin_semama FROM DUAL;
   
   IF v_validacion_dias_semana>0 AND TO_CHAR(pfecha,'HH24:Mi')>=v_hora_ini_semama AND TO_CHAR(pfecha,'HH24:Mi')<=v_hora_fin_semama THEN
      RETURN 1;
   END IF;
   
   /*VALIDACION DE DIAS FIN SEMANA HABILES*/
   SELECT COUNT(1) INTO v_validacion_dias_fin_semana FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('NOT_DIAS_FIN_SEMANA_VALIDOS')) WHERE TRIM(COLUMN_VALUE) IN (TRIM(TO_CHAR(pfecha,'DAY')));
   SELECT TRIM(REGEXP_SUBSTR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('NOT_HORARIOS_FIN_SEMANA_VALIDOS'),'[^,]+',1,1)) INTO v_hora_ini_fin_semama FROM DUAL;
   SELECT TRIM(REGEXP_SUBSTR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('NOT_HORARIOS_FIN_SEMANA_VALIDOS'),'[^,]+',1,2)) INTO v_hora_fin_fin_semama FROM DUAL;
   
   IF v_validacion_dias_fin_semana>0 AND TO_CHAR(pfecha, 'HH24:Mi')>=v_hora_ini_fin_semama AND TO_CHAR(pfecha, 'HH24:Mi')<=v_hora_fin_fin_semama THEN
      RETURN 1;
   END IF;
   
   RETURN v_valido;
   
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       RETURN 0;
     
     WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pfecha',      pfecha);
          
          setError(pProgramUnit => 'F_HORARIO_VALIDO_NOTIFICACION', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
       
END F_HORARIO_VALIDO_NOTIFICACION;

    
    PROCEDURE P_Actualiza_Credito_Solicitud(
                                 pNum_Represtamo   IN       NUMBER,
                                 pNuevo_credito    IN       NUMBER,        ---Out
                                 pIdTempfud        IN       VARCHAR2,         
                                 pNombreArchivo    IN       VARCHAR2,
                                 pError               OUT   VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;                                 
    BEGIN
        UPDATE PR.PR_SOLICITUD_REPRESTAMO S
          SET S.NO_CREDITO = pNuevo_credito, S.ID_TEMPFUD = pIdTempfud, S.NOMARCHIVO = pNombreArchivo
        WHERE S.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
          AND S.ID_REPRESTAMO = pNum_Represtamo;
          
        COMMIT;   
        
         EXCEPTION 
            WHEN OTHERS THEN   
                DECLARE
                    vIdError PLS_INTEGER := 0;
                BEGIN                                    
                    IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pNum_Represtamo);
                    IA.LOGGER.ADDPARAMVALUEV('pNuevo_credito',  pNuevo_credito);
                    IA.LOGGER.ADDPARAMVALUEV('pIdTempfud',  pIdTempfud);
                    IA.LOGGER.ADDPARAMVALUEV('pNombreArchivo',  pNombreArchivo);
                    IA.LOGGER.ADDPARAMVALUEV('pError',  pError);
                    setError(
                        pProgramUnit      => 'P_Actualiza_Credito_Solicitud', 
                        pPieceCodeName    => NULL, 
                        pErrorDescription => SQLERRM,                                                              
                        pErrorTrace       => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                        pEmailNotification => NULL, 
                        pParamList        => IA.LOGGER.vPARAMLIST, 
                        pOutputLogger     => FALSE, 
                        pExecutionTime    => NULL, 
                        pIdError          => vIdError
                    ); 
                    ROLLBACK;
                   end;                  
    /*EXCEPTION WHEN OTHERS THEN
         pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
         p_depura (pError);
         DBMS_OUTPUT.put_line (pError);
         ROLLBACK;*/
         RETURN;    
    END P_Actualiza_Credito_Solicitud;   
    
    PROCEDURE P_Actualiza_Fud(pIdReprestamo         IN      NUMBER,
                              pTelefono             IN      VARCHAR2,
                              pEmail                IN      VARCHAR2,
                              pCodPais              IN      NUMBER,
                              pCodProvincia         IN      NUMBER,
                              pCodCanton            IN      NUMBER,
                              pCodDistrito          IN      NUMBER,
                              pCodCiudad            IN      NUMBER,
                              pDireccion            IN      VARCHAR2,
                              pLugarTrabajo         IN      VARCHAR2,
                              pFechaIngreso         IN      VARCHAR2,
                              pCargo                IN      VARCHAR2,
                              pNombreEstablecimiento IN      VARCHAR2,
                              pMes                  IN      VARCHAR2,
                              pAno                  IN      VARCHAR2,
                              pDestinoCredito       IN      NUMBER,
                              pDestino              IN      VARCHAR2,
                              pTrabajoDireccion     IN      VARCHAR2,
                              pTipoGeneradorDivisas IN      VARCHAR2,
                              pOcupacion            IN      VARCHAR2,
                              pError                 OUT  VARCHAR2) IS
        vTempFud            PR_SOLICITUD_REPRESTAMO.ID_TEMPFUD%TYPE := 0;
        vNomArchivo         PR_SOLICITUD_REPRESTAMO.NOMARCHIVO%TYPE;
        v_idPais            PR.TEMPFUD.IDPAIS%TYPE;
        v_idprovincia       PR.TEMPFUD.DIRECCION_IDPROVINCIA%TYPE;
        v_idmunicipio       PR.TEMPFUD.DIRECCION_IDMUNICIPIO%TYPE;
        v_Distrito          PR.TEMPFUD.DIRECCION_DISTRITO%TYPE;
        vCodigoCliente      PR_REPRESTAMOS.CODIGO_CLIENTE%TYPE;
        vCreditoAnterior    PR_SOLICITUD_REPRESTAMO.NO_CREDITO%TYPE;
        vCreditoNuevo       PR_SOLICITUD_REPRESTAMO.NO_CREDITO%TYPE;
        vCiudad             PR_SOLICITUD_REPRESTAMO.DIRECCION%TYPE;
        vCodArea            VARCHAR2(3);
        vNumTel             VARCHAR2(10);
        vURL                VARCHAR2(4000);
        vIdAplication       PLS_INTEGER := 2; -- Prestamos
        vIdTipoDocumento    PLS_INTEGER := '452'; -- Formulario de Conozca
        vCodigoReferencia   VARCHAR2(300) := vCreditoNuevo||':'||vCreditoAnterior;
        vDocumento          VARCHAR2(30) := 'FCSCPF';
        vNombreArchivo      VARCHAR2(60);
        vPlazo              VARCHAR2(10);
        vMonto              VARCHAR2(300);
        vTasa               VARCHAR2(10);
        vIDAGENCIA          VARCHAR2(20);
    BEGIN

    
        BEGIN
            SELECT ID_TEMPFUD, S.NOMARCHIVO, R.CODIGO_CLIENTE, R.NO_CREDITO CREDITO_ANTERIOR, S.NO_CREDITO CREDITO_NUEVO,S.PLAZO,O.TASA,O.MTO_PRESTAMO,CODIGO_AGENCIA
              INTO vTempFud,vNomArchivo, vCodigoCliente, vCreditoAnterior, vCreditoNuevo,vPlazo,vTasa,vMonto,vIDAGENCIA
              FROM PR_SOLICITUD_REPRESTAMO S, PR_REPRESTAMOS R,PR_OPCIONES_REPRESTAMO O 
             WHERE S.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
               AND S.ID_REPRESTAMO = pIdReprestamo
               AND S.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PARA_ACTUALIZACION_FUD')))
               AND S.ID_TEMPFUD IS NOT NULL
               AND R.CODIGO_EMPRESA = S.CODIGO_EMPRESA
               AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
               AND O.ID_REPRESTAMO = S.ID_REPRESTAMO
               AND O.PLAZO         = S.PLAZO;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vTempFud := 0;
        END;
        
        BEGIN
            UPDATE PR.PR_SOLICITUD_REPRESTAMO S
               SET  S.TELEFONO_CELULAR = pTelefono, 
                    S.EMAIL = pEmail, 
                    S.COD_PAIS = pCodPais,
                    S.COD_PROVINCIA = pCodProvincia,
                    S.COD_CANTON = pCodCanton,
                    S.COD_DISTRITO = pCodDistrito,
                    S.COD_CIUDAD = pCodCiudad,
                    S.DIRECCION = pDireccion
               WHERE S.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
               AND S.ID_REPRESTAMO = pIdReprestamo  
               AND S.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PARA_ACTUALIZACION_FUD')));    
        EXCEPTION WHEN OTHERS THEN
            pError := 'Error actualizando la solicitud '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20101, pError);
        END;
        
        -- Actualiza Direccion del Cliente
        DECLARE
            vResultado      PA.PKG_DIR_PERSONAS.RESULTADO;
        BEGIN
            PA.PKG_DIR_PERSONAS.Generar (
                      pCod_Persona          => vCodigoCliente,
                      pCod_Direccion        => null,--NVL(PA.OBTIENE_COD_DIRECCION (vCodigoCliente, pError),1) + 1,
                      pTip_Direccion        => 1,
                      pApartado_Postal      => NULL,
                      pCod_Postal           => NULL,
                      pDetalle              => pDireccion,
                      pCod_Pais             => pCodPais,
                      pCod_Provincia        => pCodProvincia,
                      pCod_Canton           => pCodCanton,
                      pCod_Distrito         => pCodDistrito,
                      pCod_Pueblo           => pCodCiudad,
                      pEs_Default           => 'S',
                      pColonia              => NULL,
                      pZona                 => NULL,
                      pInd_Estado           => 'S',           
                      pResultado            => vResultado);
        
        EXCEPTION WHEN OTHERS THEN
            pError := 'Error generando la direcci¿n del cliente '||vResultado.DESCRIPCION||' '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20103, pError);             
        END;
        
        -- Si existe FUD entonces actualiza FUD
        IF vTempFud <> 0 THEN
            SELECT pais_sb
              INTO v_idpais
              FROM pais
             WHERE cod_pais = pCodPais;
            DBMS_OUTPUT.PUT_LINE ( 'pCodPais = ' || pCodPais );DBMS_OUTPUT.PUT_LINE ( 'pCodProvincia = ' || pCodProvincia );DBMS_OUTPUT.PUT_LINE ( 'pCodCanton = ' || pCodCanton );
            DBMS_OUTPUT.PUT_LINE ( 'pCodDistrito = ' || pCodDistrito );
            Select lpad(RPAD(cod_canton,'0',2),'0',6) provincia, 
                   lpad(RPAD(cod_canton,'0',2)||RPAD(cod_distrito,'0',2),6) municipio, 
                   lpad(RPAD(cod_canton,'0',2)||RPAD(cod_distrito,'0',2)||RPAD(cod_pueblo,'0',2),6) distrrito
                  Into v_idprovincia, v_idmunicipio, v_distrito
                  From pa.pueblos
                 Where cod_pais = pCodPais
                   AND cod_provincia = pCodProvincia
                   And cod_canton = pCodCanton
                   And cod_distrito = pCodDistrito
                   and cod_pueblo = pCodCiudad; 
        DBMS_OUTPUT.PUT_LINE ( 'v_idprovincia = ' || v_idprovincia );
        DBMS_OUTPUT.PUT_LINE ( 'v_idmunicipio = ' || v_idmunicipio );
        DBMS_OUTPUT.PUT_LINE ( 'v_distrito = ' || v_distrito );
            BEGIN
                UPDATE PR.TEMPFUD T
                  SET T.TELEFONO_CELULAR = pTelefono,
                      T.IDPAIS = v_idpais,
                      T.EMAIL = pEmail,
                      T.DIRECCION = pDireccion,
                      T.DIRECCION_IDPROVINCIA = v_idprovincia,
                      T.DIRECCION_IDMUNICIPIO = v_IdMunicipio,
                      T.DIRECCION_DISTRITO = v_Distrito,
                      T.LUGARTRABAJO = pLugarTrabajo,
                      T.FECHAINGRESO = pFechaIngreso,
                      T.CARGO        = pCargo,
                      T.NOMBRENEGOCIO = pNombreEstablecimiento,
                      T.INICIO_MES  =  pMes,
                      T.INICIO_ANO  =  pAno,
                      T.DESTINOCREDITO = 0||pDestinoCredito,
                      T.TIPOSOLICITUD = 'R',
                      T.ESPECIFIQUEDESTINO  =  pDestino,
                      T.PLAZOCAL    =  vPlazo,
                      T.TasaCal     =  vTasa,
                      T.MONTOCAL    =  vMonto,
                      T.TRABAJO_DIRECCION = pTrabajoDireccion
                      --T.IDAGENCIA = vIDAGENCIA
                WHERE T.ID_TEMPFUD = vTempFud
                  AND T.NOMARCHIVO = vNomArchivo;
            EXCEPTION WHEN OTHERS THEN
                pError := 'Error actualizando la FUD '||SQLERRM;  
                RAISE_APPLICATION_ERROR(-20101, pError);    
            END;
            
            --  Actualiza Persona Fisica
            BEGIN
              UPDATE PA.PERSONAS_FISICAS PF
                 SET PF.EMAIL_USUARIO = pEmail,
                     PF.TIPO_GEN_DIVISAS = pTipoGeneradorDivisas,
                     PF.OCUPACION_CLASIF_NAC = pOcupacion
               WHERE PF.COD_PER_FISICA = vCodigoCliente;
            EXCEPTION WHEN OTHERS THEN
                pError := 'Error actualizando datos de la persona '||SQLERRM;  
                RAISE_APPLICATION_ERROR(-20102, pError);        
            END;
            
            -- Actualiza el Tel¿fono
           IF pTelefono IS NOT NULL THEN
                DECLARE
                    vResultado  PA.PKG_TEL_PERSONAS.RESULTADO;
                BEGIN
                    vCodArea    := SUBSTR(pTelefono, 1, 3);
                    vNumTel     := SUBSTR(pTelefono, 4);
                                            
                      --Descomentar que ira a produccion         
                  PA.PKG_TEL_PERSONAS.GENERAR (PCOD_PERSONA              => VCODIGOCLIENTE,
                                                  PCOD_AREA                 => VCODAREA,
                                                  PNUM_TELEFONO             => VNUMTEL,
                                                  PTIP_TELEFONO             => 'C',
                                                  PTEL_UBICACION            => 'C',
                                                  PEXTENSION                => NULL,
                                                  PNOTA                     => NULL,
                                                  PES_DEFAULT               => 'S',
                                                  PPOSICION                 => NULL,
                                                  PCOD_DIRECCION            => NULL,
                                                  PCOD_PAIS                 => PCODPAIS,
                                                  PNOTIF_DIGITAL            => NULL,
                                                  PFECHA_NOTIF_DIGITAL      => NULL,
                                                  PUSUAARIO_NOTIF_DIGITAL   => NULL,
                                                  PRESULTADO                => VRESULTADO);      
                    --Comentar que esto no va                             
                    /*PA.PKG_TEL_PERSONAS.Generar (pCod_Persona         => vCodigoCliente,
                                                 pCod_Area            => vCodArea,
                                                 pNum_Telefono        => vNumTel,
                                                 pTip_Telefono        => 'C',
                                                 pTel_Ubicacion       => 'C',
                                                 pExtension           => NULL,
                                                 pNota                => NULL,
                                                 pEs_Default          => 'S',
                                                 pPosicion            => NULL,
                                                 pCod_Direccion       => NULL,
                                                 pCod_Pais            => pCodPais,
                                                 pModificado_Por      => SUBSTR(V('APP_USER'),1,10),
                                                 pFecha_Modificacion  => NULL,
                                                 pIncluido_Por        => NULL,
                                                 pFec_Inclusion       => NULL,
                                                 pResultado           => vResultado);*/ 
                
                /*EXCEPTION WHEN OTHERS THEN
                    pError := vResultado.DESCRIPCION||' '||SQLERRM;  
                    RAISE_APPLICATION_ERROR(-20103, pError);  */
                END; 
            END IF;                                                                                          
        
        /*ELSE
            -- Si no existe la FUD la genero
            PR_PKG_REPRESTAMOS.P_Procesa_Credito (
                               PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO,
                               pIdReprestamo,
                               '05', --- (2) := '05'; ---In
                               vCreditoNuevo,        ---Out
                               pError);*/
                                       
        END IF;       
        
        
         
    EXCEPTION WHEN OTHERS THEN
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',            pIdReprestamo);
          IA.LOGGER.ADDPARAMVALUEV('pTelefono',                pTelefono);
          IA.LOGGER.ADDPARAMVALUEV('pEmail',                   pEmail);  
          IA.LOGGER.ADDPARAMVALUEV('pCodPais',                 pCodPais);  
          IA.LOGGER.ADDPARAMVALUEV('pCodProvincia',            pCodProvincia);  
          IA.LOGGER.ADDPARAMVALUEV('pCodCanton',               pCodCanton);  
          IA.LOGGER.ADDPARAMVALUEV('pCodDistrito',             pCodDistrito);  
          IA.LOGGER.ADDPARAMVALUEV('pCodCiudad',               pCodCiudad);  
          IA.LOGGER.ADDPARAMVALUEV('pDireccion',               pDireccion);  
          IA.LOGGER.ADDPARAMVALUEV('pLugarTrabajo',            pLugarTrabajo);  
          IA.LOGGER.ADDPARAMVALUEV('pFechaIngreso',            pFechaIngreso);  
          IA.LOGGER.ADDPARAMVALUEV('pCargo',                   pCargo);  
          IA.LOGGER.ADDPARAMVALUEV('pNombreEstablecimiento',   pNombreEstablecimiento);  
          IA.LOGGER.ADDPARAMVALUEV('pMes',                     pMes);  
          IA.LOGGER.ADDPARAMVALUEV('pAno',                     pAno);  
          IA.LOGGER.ADDPARAMVALUEV('pDestinoCredito',          pDestinoCredito);  
          IA.LOGGER.ADDPARAMVALUEV('pDestino',                 pDestino);  
          IA.LOGGER.ADDPARAMVALUEV('pTrabajoDireccion',        pTrabajoDireccion);  
          
          setError(pProgramUnit => 'P_Actualiza_Fud', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
      /* pError := 'Error: '||pError||' '||SQLERRM||' '||dbms_utility.format_error_backtrace; 
       RAISE_APPLICATION_ERROR(-20100, pError);  */
    END;                                  
    
    PROCEDURE P_Procesa_Credito (pCodigo_Empresa   IN     NUMBER,
                                 pNum_Represtamo   IN     NUMBER,
                                 pPeriodicidad     IN     VARCHAR2 DEFAULT '05', --- (2) := '05'; ---In
                                 pNuevo_credito       OUT NUMBER,        ---Out
                                 pError               OUT VARCHAR2) 
    IS                                                                      ---Out
      /*Miguel Angel Almanzar /Banco Ademi 06-10-2022, proceso genera repr¿stamo a partir de una solicitud,
        utilizando Fud del credito actual para generar el nuevo cr¿dito y nueva Fud*/
        pFecha_Calendario     DATE := pa.fecha_actual_calendario ('PR', 1, 0);
        
        --Obtiene los datos de la solicitud del repr¿stamo
        CURSOR c_repre (Empresap NUMBER, pid_represtamop NUMBER)
        IS
            SELECT a.id_represtamo,
                   a.codigo_cliente,
                   a.no_credito,
                   c.mto_prestamo,
                   c.plazo,
                   c.tasa     tasa_interes,
                   c.mto_cuota,
                   CASE WHEN  nvl(c.mto_seguro_vida,0) > 0 then 'TRUE' ELSE 'FALSE' END seguro_vida ,
                   CASE WHEN  nvl(c.mto_cargos,0) > 0 then 'TRUE' ELSE 'FALSE' END gastoslegales
              FROM pr_represtamos           a,
                   pr_solicitud_represtamo  b,
                   pr_opciones_represtamo   c
             WHERE a.codigo_empresa = empresap
               AND a.id_represtamo = pid_represtamop
               AND a.estado = 'SC'
               AND b.codigo_empresa = a.codigo_empresa
               AND b.id_represtamo = a.id_represtamo
               AND c.codigo_empresa = a.codigo_empresa
               AND c.id_represtamo = a.id_represtamo
               AND c.plazo = b.plazo;

        vRow_Repre            c_repre%ROWTYPE;

        ---Obtiene registro Tempfud del cr¿dito base del repr¿stamo
        CURSOR c_fud (No_CreditoP VARCHAR2) IS
            SELECT *
              FROM tempfud
             WHERE nocredito = No_CreditoP;
       --
       -- Obtiene el tipo de proyecto del represtamo  JOSE DIAZ 05/12/2022
       --
        CURSOR CUR_tipo_PROYECTO IS
         SELECT PL.TIPO_CREDITO, c.codigo_ejecutivo
           FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl, PR_CREDITOS c 
          WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
            AND R.ID_REPRESTAMO = pNum_Represtamo
            AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA
            AND C.NO_CREDITO = R.NO_CREDITO
            AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
            AND PL.TIPO_CREDITO = PR.PR_PKG_REPRESTAMOS.F_OBTENER_NUEVO_CREDITO (pNum_Represtamo)
            AND PL.PLAZO = PL.PLAZO + 0
            AND R.MTO_PREAPROBADO >= PL.MONTO_MIN
            AND R.MTO_PREAPROBADO <= PL.MONTO_MAX;
            
        fudRow                c_fud%ROWTYPE;
        vid_tempfud           tempfud.id_tempfud%TYPE;
        vid_tempfudGenerado   tempfud.id_tempfud%TYPE;
        vTipoProyecto         VARCHAR2(5);
        vERRORCODE            VARCHAR2 (30);
        vERRORDESCRIPTION     VARCHAR2 (1000);
        vpNOCREDITO           VARCHAR2 (30);
        vpNOCREDITOGenerado   VARCHAR2 (30);
        vCodigoEjecutivo      pr_creditos.codigo_ejecutivo%TYPE;

        vFecha                DATE := TRUNC (SYSDATE);
        vTipoID               VARCHAR2 (5);
        vNombreArchivoNuevo   VARCHAR2 (100);
        vNombreArchivoNuevoGenerado   VARCHAR2 (100);
        vCount                NUMBER;
        vPeriodicidad         VARCHAR2(5) := pPeriodicidad;
        vPrimerNombre VARCHAR2(200);
        vSegundoNombre VARCHAR2(200);
        vPrimerApellido VARCHAR2(200);
        vSegundoApellido VARCHAR2(200);

    BEGIN
        OPEN  CUR_tipo_PROYECTO;
        FETCH CUR_tipo_PROYECTO INTO vTipoProyecto, vCodigoEjecutivo;
        CLOSE CUR_tipo_PROYECTO;
        OPEN c_repre (pCodigo_Empresa, pNum_Represtamo);

        FETCH c_repre INTO vRow_Repre;

        IF c_repre%FOUND
        THEN
        
        dbms_output.put_line('Linea: '||$$plsql_line);
            --Verifica Estado cr¿dito Actual (Cr¿dito base del represtamo)
            BEGIN
                SELECT COUNT (1)
                  INTO vCount
                  FROM Pr_Creditos cre
                 WHERE Cre.codigo_Empresa = pCodigo_Empresa
                   AND cre.no_credito = TO_NUMBER (vRow_Repre.no_credito)
                   AND Cre.estado IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PROCESAR_CREDITOS')));
                   --('D', 'V', 'M', 'E', 'J');

                IF vCount = 0 THEN
                    pError := 'Error: Cr¿dito base no encontrado en cartera vigente';
                    DBMS_OUTPUT.put_Line (pError);
                    ROLLBACK;
                    RETURN;
                END IF;
            END;
            


             dbms_output.put_line('Linea: '||$$plsql_line||' vRow_Repre.no_credito '||vRow_Repre.no_credito);    
            OPEN c_fud (vRow_Repre.no_credito);

            FETCH c_fud INTO fudRow;

            IF c_fud%FOUND --La consulta de la fud para el cr¿dito base fue exitosa
            THEN
            dbms_output.put_line('Linea: '||$$plsql_line);
                BEGIN
                    SELECT SQ_TEMPFUD.NEXTVAL INTO vID_TEMPFUD FROM DUAL;
                    vid_tempfudGenerado :=vID_TEMPFUD;
                END;

                vTipoID :=
                    CASE
                        WHEN fudrow.TIPODOCUMENTOIDENTIDAD = '1' THEN 'C'
                        ELSE fudrow.TIPODOCUMENTOIDENTIDAD
                    END;
                    

                vNombreArchivoNuevo := SUBSTR (fudRow.NOMARCHIVO, 1, 5) || TO_CHAR (SYSDATE, 'yyyymmddhhmiss') || '_0';
               
                

                DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevo: ' || vNombreArchivoNuevo);
                DBMS_OUTPUT.put_line ( 'vID_TEMPFUD: ' || vID_TEMPFUD);
                DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' ||vRow_Repre.no_credito);
                DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' || fudrow.IDPAIS);

                BEGIN
                
                dbms_output.put_line('Linea: '||$$plsql_line||' fudrow.PRIMERNOMBRE '||fudrow.PRIMERNOMBRE||' vTipoID: '||vTipoID);
                    --ia.api_portacredit.pcrearFud 
                    vCodigoEjecutivo := nvl(vCodigoEjecutivo,fudrow.IDOFICIAL);
                    PR.PR_PKG_REPRESTAMOS.P_Obtener_Nombres_Cliente ( pNum_Represtamo,vPrimerNombre,vSegundoNombre,vPrimerApellido,vSegundoApellido );
                DBMS_OUTPUT.put_line ( 'pNum_Represtamo: ' || pNum_Represtamo);
                DBMS_OUTPUT.put_line ( 'vPrimerNombre: ' || vPrimerNombre);
                DBMS_OUTPUT.put_line ('vSegundoNombre: ' ||vSegundoNombre);
                DBMS_OUTPUT.put_line ('vPrimerApellido: ' || vPrimerApellido);
                DBMS_OUTPUT.put_line ('vSegundoApellido: ' || vSegundoApellido);
                
                DBMS_OUTPUT.put_line ('TIPO DE CREDITO: ' );
                    PR.PKG_SOLICITUD_CREDITO.PCREARFUD
                    (
                        pID_TEMPFUD               => vID_TEMPFUD, /*fudrow.ID_TEMPFUD */
                        pNOMARCHIVO               => vNombreArchivoNuevo, --fudrow.NOMARCHIVO, --malmanzar 22-09-2022
                        pPROCESADO                => fudrow.PROCESADO,
                        pIDAPERTURACLIENTE        => fudrow.IDAPERTURACLIENTE,
                        pTIPODOCUMENTOIDENTIDAD   => vTipoID, --fudrow.TIPODOCUMENTOIDENTIDAD,
                        pNUMDOCUMENTOIDENTIDAD    => fudrow.NUMDOCUMENTOIDENTIDAD,
                        pIDOFICIAL                => vCodigoEjecutivo, --fudrow.IDOFICIAL),
                        pIDAGENCIA                => fudrow.IDAGENCIA,
                        pPRIMERNOMBRE             => vPrimerNombre,  --fudrow.PRIMERNOMBRE,
                        pPRIMERAPELLIDO           => vPrimerApellido,--fudrow.PRIMERAPELLIDO,
                        pSEXO                     => fudrow.SEXO,
                        pFECHANACIMIENTO          => fudrow.FECHANACIMIENTO,
                        pAPODO                    => fudrow.APODO,
                        pIDEMPLEADO               => fudrow.IDEMPLEADO,
                        pIDPAIS                   => fudrow.IDPAIS,
                        pIDPROVINCIA              => fudrow.IDPROVINCIA,
                        pIDMUNICIPIO              => fudrow.IDMUNICIPIO,
                        pIDDISTRITO               => fudrow.IDDISTRITO,
                        pIDESTADOCIVIL            => fudrow.IDESTADOCIVIL,
                        pNOHIJOS                  => fudrow.NOHIJOS,
                        pDEPENDIENTES             => fudrow.DEPENDIENTES,
                        pGRADOINT                 => fudrow.GRADOINT,
                        pIDOCUPACION              => fudrow.IDOCUPACION,
                        pIDVINCULADO              => fudrow.IDVINCULADO,
                        pNOMBREVINCULADO          => fudrow.NOMBREVINCULADO,
                        pIDTIPOVINCULADO          => fudrow.IDTIPOVINCULADO,
                        pIDCOMOSUPONOSOTROS       => fudrow.IDCOMOSUPONOSOTROS,
                        pDIRECCION                => fudrow.DIRECCION,
                        pDIRECCION_IDSECTOR       => fudrow.DIRECCION_IDSECTOR,
                        pDIRECCION_IDPROVINCIA    => fudrow.DIRECCION_IDPROVINCIA,
                        pDIRECCION_IDMUNICIPIO    => fudrow.DIRECCION_IDMUNICIPIO,
                        pDIRECCION_DISTRITO       => fudrow.DIRECCION_DISTRITO,
                        pDIRECCION_IDTIPOVIVIENDA => fudrow.DIRECCION_IDTIPOVIVIENDA,
                        pREF_DOMICILIO            => fudrow.REF_DOMICILIO,
                        pTELEFONO_CASA            => fudrow.TELEFONO_CASA,
                        pTELEFONO_CELULAR         => fudrow.TELEFONO_CELULAR,
                        pNOMBRENEGOCIO            => fudrow.NOMBRENEGOCIO,
                        pNOEMPLEADOS              => fudrow.NOEMPLEADOS,
                        pRNC                      => fudrow.RNC,
                        pFAX                      => fudrow.FAX,
                        pEMAIL                    => fudrow.EMAIL,
                        pSECTORECONOMICO          => fudrow.SECTORECONOMICO,
                        pACTIVIDAD_CIIU           => fudrow.ACTIVIDAD_CIIU,
                        pIDRAMA_CIIU              => fudrow.IDRAMA_CIIU,
                        pINICIO_MES               => fudrow.INICIO_MES,
                        pINICIO_ANO               => fudrow.INICIO_ANO,
                        pUBICACION_NEG            => fudrow.UBICACION_NEG,
                        pLUGARTRABAJO             => fudrow.LUGARTRABAJO,
                        pFECHAINGRESO             => fudrow.FECHAINGRESO,
                        pCARGO                    => fudrow.CARGO,
                        pTRABAJO_DIRECCION        => fudrow.TRABAJO_DIRECCION,
                        pTRABAJO_IDSECTOR         => fudrow.TRABAJO_IDSECTOR,
                        pTRABAJO_IDPROVINCIA      => fudrow.TRABAJO_IDPROVINCIA,
                        pTRABAJO_IDMUNICIPIO      => fudrow.TRABAJO_IDMUNICIPIO,
                        pTRABAJO_IDDISTRITO       => fudrow.TRABAJO_IDDISTRITO,
                        pPUNTOREFERENCIA          => fudrow.PUNTOREFERENCIA,
                        pTELEFONO                 => fudrow.TELEFONO,
                        pEXTENSION                => fudrow.EXTENSION,
                        pREFPERSONALES_APELLIDOS  => fudrow.REFPERSONALES_APELLIDOS,
                        pREFPERSONALES_NOMBRES    => fudrow.REFPERSONALES_NOMBRES,
                        pREFPERSONALES_TELEFONO   => fudrow.REFPERSONALES_TELEFONO,
                        pREFPERSONALES_RELFAMILIAR => fudrow.refpersonales_relacionfamiliar,
                        pREFPERSONALES_NOMBRES2   => fudrow.REFPERSONALES_NOMBRES2,
                        pREFPERSONALES_APELLIDOS2 => fudrow.REFPERSONALES_APELLIDOS2,
                        pREFPERSONALES_TELEFONO2  => fudrow.REFPERSONALES_TELEFONO2,
                        pREFPERSONALES_RELFAM2    => fudrow.REFPERSONALES_RELFAM2,
                        pACTUALMENTEENMORA        => fudrow.ACTUALMENTEENMORA,
                        pCUMPLIOREQUISITOS        => fudrow.CUMPLIOREQUISITOS,
                        pPRESENTO_DOC_FRAUDULENTA => fudrow.PRESENTO_DOC_FRAUDULENTA,
                        pDIJOLAVERDAD             => fudrow.DIJOLAVERDAD,
                        pCLIENTEESFIADOR          => fudrow.CLIENTEESFIADOR,
                        pCLIENTEMOROSO            => fudrow.CLIENTEMOROSO,
                        pSOBREENDEUDAMIENTO_SF    => fudrow.SOBREENDEUDAMIENTO_SF,
                        pACTIVIDADCLIENTE         => fudrow.ACTIVIDADCLIENTE,
                        pTIPOPERSONA              => fudrow.TIPOPERSONA,
                        pTIPODOCUMENTOIDENTIDADCO => fudrow.TIPODOCUMENTOIDENTIDADCO,
                        pNUMDOCUMENTOIDENTIDADCO  => fudrow.NUMDOCUMENTOIDENTIDADCO,
                        pPRIMERNOMBRECO           => fudrow.PRIMERNOMBRECO,
                        pPRIMERAPELLIDOCO         => fudrow.PRIMERAPELLIDOCO,
                        pSEXOCO                   => fudrow.SEXOCO,
                        pFECHANACIMIENTOCO        => fudrow.FECHANACIMIENTOCO,
                        pAPODOCO                  => fudrow.APODOCO,
                        pIDEMPLEADOCO             => fudrow.IDEMPLEADOCO,
                        pIDPAISCO                 => fudrow.IDPAISCO,
                        pIDPROVINCIACO            => fudrow.IDPROVINCIACO,
                        pIDMUNICIPIOCO            => fudrow.IDMUNICIPIOCO,
                        pIDDISTRITOCO             => fudrow.IDDISTRITOCO,
                        pIDESTADOCIVILCO          => fudrow.IDESTADOCIVILCO,
                        pNOHIJOSCO                => fudrow.NOHIJOSCO,
                        pDEPENDIENTESCO           => fudrow.DEPENDIENTESCO,
                        pGRADOINTCO               => fudrow.GRADOINTCO,
                        pIDOCUPACIONCO            => fudrow.IDOCUPACIONCO,
                        pIDVINCULADOCO            => fudrow.IDVINCULADOCO,
                        pNOMBREVINCULADOCO        => fudrow.NOMBREVINCULADOCO,
                        pIDTIPOVINCULADOCO        => fudrow.IDTIPOVINCULADOCO,
                        pIDCOMOSUPONOSOTROSCO     => fudrow.IDCOMOSUPONOSOTROSCO,
                        pNOMBRENEGOCIOCO          => fudrow.NOMBRENEGOCIOCO,
                        pNOEMPLEADOSCO            => fudrow.NOEMPLEADOSCO,
                        pRNCCO                    => fudrow.RNCCO,
                        pFAXCO                    => fudrow.FAXCO,
                        pEMAILCO                  => fudrow.EMAILCO,
                        pSECTORECONOMICOCO        => fudrow.SECTORECONOMICOCO,
                        pACTIVIDAD_CIIUCO         => fudrow.ACTIVIDAD_CIIUCO,
                        pIDRAMA_CIIUCO            => fudrow.IDRAMA_CIIUCO,
                        pINICIO_MESCO             => fudrow.INICIO_MESCO,
                        pINICIO_ANOCO             => fudrow.INICIO_ANOCO,
                        pUBICACION_NEGCO          => fudrow.UBICACION_NEGCO,
                        pLUGARTRABAJOCO           => fudrow.LUGARTRABAJOCO,
                        pFECHAINGRESOCO           => fudrow.FECHAINGRESOCO,
                        pTRABAJO_DIRECCIONCO      => fudrow.TRABAJO_DIRECCIONCO,
                        pTRABAJO_IDSECTORCO       => fudrow.TRABAJO_IDSECTORCO,
                        pTRABAJO_IDPROVINCIACO    => fudrow.TRABAJO_IDPROVINCIACO,
                        pTRABAJO_IDMUNICIPIOCO    => fudrow.TRABAJO_IDMUNICIPIOCO,
                        pTRABAJO_IDDISTRITOCO     => fudrow.TRABAJO_IDDISTRITOCO,
                        pPUNTOREFERENCIACO        => fudrow.PUNTOREFERENCIACO,
                        pTELEFONOCO               => fudrow.TELEFONOCO,
                        pEXTENSIONCO              => fudrow.EXTENSIONCO,
                        pCARGOCO                  => fudrow.CARGOCO,
                        pRESIDE_MES               => fudrow.RESIDE_MES,
                        pRESIDE_ANO               => fudrow.RESIDE_ANO,
                        pACTIVIDADCO              => fudrow.ACTIVIDADCO,
                        pTIPOPERSONACO            => fudrow.TIPOPERSONACO,
                        pTIPOSOLICITUD            => fudrow.TIPOSOLICITUD,
                        pCODIGOPROYECTO           => vTipoProyecto,--fudrow.CODIGOPROYECTO),
                        pDESTINOCREDITO           => fudrow.DESTINOCREDITO,
                        pESPECIFIQUEDESTINO       => fudrow.ESPECIFIQUEDESTINO,
                        pTIPOPERSONACAL           => fudrow.TIPOPERSONACAL,
                        pEDADCAL                  => fudrow.EDADCAL,
                        pMONTOCAL                 => vRow_Repre.mto_prestamo, --fudrow.MONTOCAL,  ---Valor solicitud
                        pPLAZOCAL                 => vRow_Repre.plazo, -- fudrow.PLAZOCAL,   ----Valor solicitud
                        pMONEDACAL                => fudrow.MONEDACAL,
                        pDIAPAGOCAL               => fudrow.DIAPAGOCAL,
                        pFRECUENCIACAL            => vPeriodicidad, ---fudrow.FRECUENCIACAL,  Frecuencia Mensual Fija por el momento
                        pGRACIACAL                => fudrow.GRACIACAL,
                        pGARANTIACAL              => fudrow.GARANTIACAL,
                        pSEGURO_VEHICULOCAL       => fudrow.SEGURO_VEHICULOCAL,
                        pSEGURO_VIDACAL           => fudrow.SEGURO_VIDACAL,
                        pSEGURO_INCENDIOCAL       => fudrow.SEGURO_INCENDIOCAL,
                        pGASTOSCAL                => fudrow.GASTOSCAL,
                        pTIPOPRESTAMOCAL          => fudrow.TIPOPRESTAMOCAL,
                        pGARANTIASOLIDARIACAL     => fudrow.GARANTIASOLIDARIACAL,
                        pHIPOTECARIACAL           => fudrow.HIPOTECARIACAL,
                        pPRENDARIACAL             => fudrow.PRENDARIACAL,
                        pLIQUIDACAL               => fudrow.LIQUIDACAL,
                        pCUOTASEGUROCAL           => fudrow.CUOTASEGUROCAL,
                        pCUOTAPRESTAMOCAL         => vRow_Repre.mto_cuota,---fudrow.CUOTAPRESTAMOCAL,
                        pTOTALFINANCIARCAL        => fudrow.TOTALFINANCIARCAL,
                        pTASACAL                  => vRow_Repre.tasa_interes, --fudrow.TASACAL,  --Valor solicitud
                        pGASTOSLEGALESCAL         => vRow_Repre.GASTOSLEGALES, -------------
                        pSEGUROVIDACAL            => vRow_Repre.SEGURO_VIDA, ---fudrow.SEGUROVIDACAL,
                        pSEGUROALIADACAL          => fudrow.SEGUROALIADACAL,
                        pSEGUROVEHCAL             => fudrow.SEGUROVEHCAL,
                        pCLASIFICACION            => fudrow.CLASIFICACION,
                        pFIRMACLIENTE             => fudrow.FIRMACLIENTE,
                        pFIRMACO                  => fudrow.FIRMACO,
                        pCLIENTEPERTENECE         => fudrow.CLIENTEPERTENECE,
                        pFECHA_REGISTRO           => vFecha, --sysdate,--fudow.FECHA_REGISTRO,
                        pTIPOCAL                  => fudrow.TIPOCAL,
                        pTIPOPARENTESCO           => fudrow.TIPOPARENTESCO,
                        pTIPOPARENTESCOCO         => fudrow.TIPOPARENTESCOCO,
                        pTIPOPERSONA2             => fudrow.TIPOPERSONA2,
                        pTIPOCLIENTE              => fudrow.TIPOCLIENTE,
                        pTIPOPRODUCTOS            => fudrow.TIPOPRODUCTOS,
                        pACTIVIDADCIIU_SOL        => fudrow.ACTIVIDADCIIU_SOL,
                        pIDRAMACIIU_SOL           => fudrow.IDRAMACIIU_SOL,
                        ERRORCODE                 => vERRORCODE,
                        ERRORDESCRIPTION          => vERRORDESCRIPTION,
                        pNOCREDITO                => vpNOCREDITO,
                        pSEGUNDONOMBRE            => vSegundoNombre,  --fudrow.PRIMERNOMBRE,
                        pSEGUNDOAPELLIDO          => vSegundoApellido,--fudrow.SEGUNDOAPELLIDO,
                        pSEGUNDONOMBRECO          => fudrow.SEGUNDONOMBRECO,
                        pSEGUNDOAPELLIDOCO        => fudrow.SEGUNDOAPELLIDOCO,
                        pCODPAISISO               => fudrow.CODPAISISO,
                        pAPELLIDOCASADACLIENTE    => fudrow.APELLIDOCASADACLIENTE,
                        pCEDULAEXTRANJERA         => fudrow.CEDULAEXTRANJERA);

                    IF vERRORDESCRIPTION IS NOT NULL
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' Error creando tempfud vERRORDESCRIPTION' || vERRORDESCRIPTION;
                        p_depura (pError);
                        DBMS_OUTPUT.put_line (pError);
                        ROLLBACK;
                        RETURN;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
                        p_depura (pError);
                        --DBMS_OUTPUT.put_line (pError);
                        ROLLBACK;
                        RETURN;
                END;

    
                --            DBMS_OUTPUT.put_line ('vERRORCODE ' || vERRORCODE);
                --            DBMS_OUTPUT.put_line ('vERRORDESCRIPTION ' || vERRORDESCRIPTION);
                --            DBMS_OUTPUT.put_line ('vpNOCREDITO ' || vpNOCREDITO);
                --            DBMS_OUTPUT.put_line ('vID_TEMPFUD ' || vID_TEMPFUD);

                SELECT NOCREDITO,NOMARCHIVO INTO vpNOCREDITOGenerado,vNombreArchivoNuevoGenerado FROM TEMPFUD WHERE ID_TEMPFUD = vid_tempfudGenerado;
                pNuevo_credito := vpNOCREDITOGenerado;
                
                    DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevoGenerado: ' || vNombreArchivoNuevoGenerado);
                    DBMS_OUTPUT.put_line ('vpNOCREDITOGenerado: ' ||vpNOCREDITOGenerado);
                    DBMS_OUTPUT.put_line ('pNuevo_credito: ' ||pNuevo_credito);
                IF vpNOCREDITOGenerado IS NOT NULL THEN
                    BEGIN
                        pr.pkg_recredito.p_genera_recredito (
                            pcodigo_empresa    => pCodigo_Empresa,
                            pNo_credito        => vpNOCREDITOGenerado,
                            pCredito_Cancela   => vRow_Repre.no_credito,
                            pfecha             => pFecha_Calendario,
                            pUser              => USER,
                            pAccion            => 'I'); -- I = Insert, 'D' = Delete
                    EXCEPTION
                        WHEN DUP_VAL_ON_INDEX  THEN
                            NULL;
                        WHEN OTHERS
                        THEN
                            pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
                            p_depura (pError);
                            DBMS_OUTPUT.put_line (pError);
                            ROLLBACK;
                            RETURN;
                    END;

                    --Registra Bit¿cora
                    PR_PKG_REPRESTAMOS.p_generar_bitacora ( pNum_Represtamo, NULL, 'CRS', NULL, 'Credito solicitado', USER);
                    
                    
                    DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevo: ' || vNombreArchivoNuevoGenerado);
                    DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' ||vRow_Repre.no_credito);
                    DBMS_OUTPUT.put_line ('vID_TEMPFUD: ' ||vid_tempfudGenerado);
                    COMMIT;
                    IF pNuevo_credito IS NOT NULL AND vid_tempfudGenerado IS NOT NULL AND vNombreArchivoNuevoGenerado IS NOT NULL THEN
                        -- Actualiza el numero de credito en Solicitud
                        PR_PKG_REPRESTAMOS.P_Actualiza_Credito_Solicitud( pNum_Represtamo, pNuevo_credito, vid_tempfudGenerado, vNombreArchivoNuevoGenerado, pError);
                        COMMIT;    
                        ELSE
                         pError := 'Linea ' || $$plsql_line || ' No se ha generado la Fud Correctamente pNuevo_credito: '||pNuevo_credito ||' vID_TEMPFUD: '||vid_tempfudGenerado || 'vNombreArchivoNuevo: '||vNombreArchivoNuevoGenerado;
                         p_depura (pError);
                          DBMS_OUTPUT.put_line (pError);
                    END IF;                
                    
                    --IF vTipoID IS NOT NULL AND fudrow.NumDocumentoIdentidad IS NOT NULL AND pNuevo_credito IS NOT NULL AND vRow_Repre.no_credito IS NOT NULL THEN
                    
                        DECLARE
                           vURL                 VARCHAR2(4000);
                           vIdAplication        PLS_INTEGER := 2; -- Prestamos
                           vIdTipoDocumento     PLS_INTEGER := '231'; -- Formulario de Conozca
                           vCodigoReferencia    VARCHAR2(300) := vpNOCREDITOGenerado||':'||vRow_Repre.no_credito;
                           --vDocumento           VARCHAR2(30) := 'BURO';
                           vNombreArchivo       VARCHAR2(60);
                        BEGIN                                                                                                                  
                            -- Documento Inicial con el credito anterior para la carga
                            vNombreArchivo    := 'app-106-logo.pdf';                                                   
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => NULL, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo,   
                                                            pEstado             => 'P',
                                                            pRespuesta          => pError
                                                           );                                                                           
                            
                                                           
                        EXCEPTION WHEN OTHERS THEN 
                           pError := pError||' '||dbms_utility.format_error_backtrace;      
                           RAISE_APPLICATION_ERROR(-20100, pError);
                        END;
                        
                         ELSE
                         pError := 'Linea ' || $$plsql_line || ' No se ha insertado correctamente la URL del reporte vTipoID: '||vTipoID ||
                           ' fudrow.NumDocumentoIdentidad: '||fudrow.NumDocumentoIdentidad || ' pNuevo_credito: '||pNuevo_credito||' vRow_Repre.no_credito '||vRow_Repre.no_credito;
                         p_depura (pError);
                          DBMS_OUTPUT.put_line (pError);
                    
                    --END IF;
                    
                END IF;
            ELSE                                                   ---c_fud%found;
                pError := 'Error: tempfud no encontrada para el cr¿dito base ' || vRow_Repre.no_credito;
                p_depura (pError);
                ROLLBACK;
                RETURN;
            END IF;                                                 ---c_fud%found

            fudRow := NULL;
        ELSE
            pError := 'Error: id_represtamo ' || pNum_Represtamo || ' NO encontrado';
            p_depura (pError);
            ROLLBACK;
            RETURN;
        END IF;                                                   -- c_repre%found

        CLOSE c_repre;
    EXCEPTION
        WHEN OTHERS THEN
            /*pError := 'Linea ' || $$plsql_line || 'sqlerrm ' || SQLERRM || ' vERRORDESCRIPTION ' || vERRORDESCRIPTION || ' vERRORCODE ' || vERRORCODE;
            P_DEPURA (pError);
            --DBMS_OUTPUT.put_line (pError);
            ROLLBACK;
            RETURN;*/
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pCodigo_Empresa',            pCodigo_Empresa);
          IA.LOGGER.ADDPARAMVALUEV('pNum_Represtamo',          pNum_Represtamo);
          IA.LOGGER.ADDPARAMVALUEV('pPeriodicidad',        pPeriodicidad);  
          
          setError(pProgramUnit => 'p_Procesa_Credito', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
            
    END p_Procesa_Credito;
  PROCEDURE P_Procesa_Credito_Cancelado (pCodigo_Empresa   IN     NUMBER,
                                 pNum_Represtamo   IN     NUMBER,
                                 pPeriodicidad     IN     VARCHAR2 DEFAULT '05', --- (2) := '05'; ---In
                                 pMtoPrestamo      IN     NUMBER,
                                 pNuevo_credito    OUT    NUMBER,
                                 pNumCliente       IN     VARCHAR2,        ---Out
                                 pError            OUT    VARCHAR2) 
    IS                                                                      ---Out
      /*Smaylin Robles  /Banco Ademi 16-05-2023, proceso genera représtamo a partir de una solicitud,
        utilizando Fud del credito actual para generar el nuevo crédito y nueva Fud*/
        pFecha_Calendario     DATE := pa.fecha_actual_calendario ('PR', 1, 0);
        
        
        
        vIdDocsReutilizar   VARCHAR2(100);   --NUEVA VARIABLE
        
        --Obtiene los datos de la solicitud del représtamo
        CURSOR c_repre (Empresap NUMBER, pid_represtamop NUMBER)
        IS
            SELECT a.id_represtamo,
                   a.codigo_cliente,
                   a.no_credito,
                   c.mto_prestamo,
                   c.plazo,
                   c.tasa     tasa_interes,
                   c.mto_cuota,
                   b.identificacion,
                   CASE WHEN  nvl(c.mto_seguro_vida,0) > 0 then 'TRUE' ELSE 'FALSE' END seguro_vida ,
                   CASE WHEN  nvl(c.mto_cargos,0) > 0 then 'TRUE' ELSE 'FALSE' END gastoslegales
              FROM pr_represtamos           a,
                   pr_solicitud_represtamo  b,
                   pr_opciones_represtamo   c
             WHERE a.codigo_empresa = empresap
               AND a.id_represtamo = pid_represtamop
               AND a.estado = 'SC'
               AND b.codigo_empresa = a.codigo_empresa
               AND b.id_represtamo = a.id_represtamo
               AND c.codigo_empresa = a.codigo_empresa
               AND c.id_represtamo = a.id_represtamo
               AND c.plazo = b.plazo;
               
               
           CURSOR ACTUALIZA_TELEFONO IS                 
            SELECT TIP_TELEFONO, TP.COD_AREA || TP.NUM_TELEFONO AS TELEFONO 
            FROM PA.TEL_PERSONAS TP 
            WHERE TP.COD_PERSONA   = pNumCliente;

        vRow_Repre            c_repre%ROWTYPE;

        ---Obtiene registro Tempfud del crédito base del représtamo
                CURSOR c_fud (No_CreditoP VARCHAR2) IS
            SELECT FUD.*,
               CASE
                   WHEN REGEXP_LIKE(FUD.FECHAINGRESO, '^([0-2][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$') THEN FUD.FECHAINGRESO
                   WHEN REGEXP_LIKE(FUD.FECHAINGRESO, '^(0[1-9]|1[0-2])/([0-9]{4})$') THEN '01/' || FUD.FECHAINGRESO
                   ELSE NULL
               END AS FECHA_PROCESADA,
               
                REPLACE(REPLACE(REPLACE(FUD.telefono_celular, '('),')'), '-') AS TELEFONO_CELULAR_FORMATO,

                REPLACE(REPLACE(REPLACE(FUD.telefono_casa, '('),')'),'-') AS TELEFONO_CASA_FORMATO     
            FROM tempfud FUD
             WHERE nocredito = No_CreditoP
             AND TIPOPERSONA='Cliente' AND ROWNUM<=1;
       --
       -- Obtiene el tipo de proyecto del represtamo  JOSE DIAZ 05/12/2022
       --
        CURSOR CUR_tipo_PROYECTO IS  
        
        
                   SELECT PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO (pNum_Represtamo,pMtoPrestamo), c.codigo_ejecutivo
                   FROM PR.PR_REPRESTAMOS r, pr.PR_PLAZO_CREDITO_REPRESTAMO pl, PR_CREDITOS c 
                  WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                    AND R.ID_REPRESTAMO = pNum_Represtamo
                    AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA
                    AND C.NO_CREDITO = R.NO_CREDITO
                    AND PL.CODIGO_EMPRESA = R.CODIGO_EMPRESA
                                    
   UNION
          SELECT PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO (pNum_Represtamo,pMtoPrestamo), c.codigo_ejecutivo
                   FROM PR.PR_REPRESTAMOS r ,PR_CREDITOS_HI c 
                  WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
                    AND R.ID_REPRESTAMO = pNum_Represtamo
                    AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA
                    AND C.NO_CREDITO = R.NO_CREDITO;
  
  
        fudRow                c_fud%ROWTYPE;
        vid_tempfud           tempfud.id_tempfud%TYPE;
        vID_TEMPFUD_EXT       fudextendida.id%TYPE;
        vid_tempfudGenerado   tempfud.id_tempfud%TYPE;
        vTipoProyecto           PR_CREDITOS.TIPO_CREDITO%TYPE; --VARCHAR2(5);
        vERRORCODE           VARCHAR2 (1000);
        vERRORDESCRIPTION     VARCHAR2 (1000);
        vERROR                VARCHAR2 (1000);
        vERRORCODE1            VARCHAR2 (1000);
        vERRORDESCRIPTION1     VARCHAR2 (1000);
        vERROR1                VARCHAR2 (1000);
        vpNOCREDITO           VARCHAR2 (300);
        vpNOCREDITOGenerado   VARCHAR2 (300);
        vCodigoEjecutivo      pr_creditos.codigo_ejecutivo%TYPE;

        vFecha                DATE := TRUNC (SYSDATE);
        vTipoID               VARCHAR2 (50);
        vNombreArchivoNuevo   VARCHAR2 (500);
        vNombreArchivoNuevoGenerado   VARCHAR2 (500);
        vCount                NUMBER;
        vPeriodicidad         VARCHAR2(5) := pPeriodicidad;
        vPrimerNombre VARCHAR2(200);
        vSegundoNombre VARCHAR2(200);
        vPrimerApellido VARCHAR2(200);
        vSegundoApellido VARCHAR2(200);
        vSeguroMipyme    VARCHAR2(1000);
        vSeguroDesempleo VARCHAR2(1000);
        v_telefono     VARCHAR2(100);
        vid_represtamo VARCHAR2(100);
        vCtelefono     VARCHAR2(100);
        vTipo_TELEFONO VARCHAR2(10);
         vURL                 VARCHAR2(4000);
        vIdAplication        PLS_INTEGER := 2; 
        vIdTipoDocumento     PLS_INTEGER ; 
        vCodigoReferencia    VARCHAR2(100);
        vDocumento           VARCHAR2(30) ;
        vNombreArchivo       VARCHAR2(60);
        vSubqueryResult     VARCHAR2(100);
        COD_AGENCIA          VARCHAR2(10);
        vSucursal           VARCHAR2(10);
        vFECHA_PROCESADA VARCHAR2(50);
    BEGIN
        OPEN  CUR_tipo_PROYECTO;
        FETCH CUR_tipo_PROYECTO INTO vTipoProyecto, vCodigoEjecutivo;
        CLOSE CUR_tipo_PROYECTO;
        OPEN c_repre (pCodigo_Empresa, pNum_Represtamo);
        --DBMS_OUTPUT.PUT_LINE ( 'F_OBTENER_CREDITO_CANCELADO = ' || PR.PR_PKG_REPRESTAMOS.F_OBTENER_CREDITO_CANCELADO(pNum_Represtamo,pMtoPrestamo) ); 
       -- DBMS_OUTPUT.PUT_LINE ( 'pNum_Represtamo = ' || pNum_Represtamo );
       -- DBMS_OUTPUT.PUT_LINE ( 'pMtoPrestamo = ' || pMtoPrestamo );
       -- DBMS_OUTPUT.put_line ('TIPO DE CREDITO1: ' || vTipoProyecto || 'CODIGO EJECUTIVO: ' || vCodigoEjecutivo );
        FETCH c_repre INTO vRow_Repre;

        IF c_repre%FOUND
        THEN
        
        dbms_output.put_line('Linea: '||$$plsql_line);
            --Verifica Estado crédito Actual (Crédito base del represtamo)
            BEGIN
                SELECT COUNT (1)
                  INTO vCount
                  FROM 
                  (
                  SELECT COUNT (1)
                  FROM Pr_Creditos cre
                    WHERE Cre.codigo_Empresa = pCodigo_Empresa
                   AND cre.no_credito = TO_NUMBER (vRow_Repre.no_credito)
                   AND Cre.estado IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PROCESAR_CREDITOS')))
        
               UNION
               
                  SELECT COUNT (1)
                  FROM Pr_Creditos_HI cre
                    WHERE Cre.codigo_Empresa = pCodigo_Empresa
                   AND cre.no_credito = TO_NUMBER (vRow_Repre.no_credito)
                   AND Cre.estado IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PROCESAR_CREDITOS')))
                  ) T1 WHERE ROWNUM=1;
                IF vCount = 0 THEN
                    pError := 'Error: Crédito base no encontrado en cartera vigente';
                    DBMS_OUTPUT.put_Line (pError);
                    ROLLBACK;
                    RETURN;
                END IF;
            END;
                
                        
            BEGIN 
              SELECT MTO_SEGURO_MIPYME,MTO_SEGURO_DESEMPLEO INTO vSeguroMipyme,vSeguroDesempleo 
              FROM PR_OPCIONES_REPRESTAMO WHERE ID_REPRESTAMO = pNum_Represtamo AND PLAZO = vRow_Repre.plazo ; 
              
                IF vSeguroMipyme > 0 THEN
                    vSeguroMipyme := 1;
                ELSE 
                    vSeguroMipyme := 0;
                END IF;
                
                IF vSeguroDesempleo > 0 THEN
                    vSeguroDesempleo := 1;
                ELSE 
                vSeguroDesempleo := 0;
                END IF;
            END;

            dbms_output.put_line('Linea: '||$$plsql_line||' vRow_Repre.no_credito '||vRow_Repre.no_credito);    
            OPEN c_fud (vRow_Repre.no_credito);

            FETCH c_fud INTO fudRow;

           IF c_fud%FOUND --La consulta de la fud para el crédito base fue exitosa
           THEN
            dbms_output.put_line('Linea: '||$$plsql_line);
                BEGIN
                    SELECT SQ_TEMPFUD.NEXTVAL INTO vID_TEMPFUD FROM DUAL;
                    vid_tempfudGenerado :=vID_TEMPFUD;
                END;

                vTipoID :=
                    CASE
                        WHEN fudrow.TIPODOCUMENTOIDENTIDAD = '1' THEN 'C'
                        ELSE fudrow.TIPODOCUMENTOIDENTIDAD
                    END;


                vNombreArchivoNuevo := SUBSTR (fudRow.NOMARCHIVO, 1, 5) || TO_CHAR (SYSDATE, 'yyyymmddhhmiss') || '_0';
               
                

                --DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevo: ' || vNombreArchivoNuevo);
               -- DBMS_OUTPUT.put_line ( 'vID_TEMPFUD: ' || vID_TEMPFUD);
               -- DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' ||vRow_Repre.no_credito);
                --DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' || fudrow.IDPAIS);

                BEGIN
                
                --dbms_output.put_line('Linea: '||$$plsql_line||' fudrow.PRIMERNOMBRE '||fudrow.PRIMERNOMBRE||' vTipoID: '||vTipoID);
                    --ia.api_portacredit.pcrearFud 
                    vCodigoEjecutivo := nvl(vCodigoEjecutivo,fudrow.IDOFICIAL);
                    PR.PR_PKG_REPRESTAMOS.P_Obtener_Nombres_Cliente ( pNum_Represtamo,vPrimerNombre,vSegundoNombre,vPrimerApellido,vSegundoApellido );
               -- DBMS_OUTPUT.put_line ( 'pNum_Represtamo: ' || pNum_Represtamo);
               -- DBMS_OUTPUT.put_line ( 'vPrimerNombre: ' || vPrimerNombre);
                --DBMS_OUTPUT.put_line ('vPrimerApellido: ' || vPrimerApellido);
                --DBMS_OUTPUT.put_line ('TIPO DE CREDITO1: ' || vTipoProyecto );
                vFECHA_PROCESADA := fudrow.FECHA_PROCESADA;
                    PR.PKG_SOLICITUD_CREDITO.PCREARFUD
                    (
                        pID_TEMPFUD               => vID_TEMPFUD, /*fudrow.ID_TEMPFUD */
                        pNOMARCHIVO               => vNombreArchivoNuevo, --fudrow.NOMARCHIVO, --malmanzar 22-09-2022
                        pPROCESADO                => fudrow.PROCESADO,
                        pIDAPERTURACLIENTE        => fudrow.IDAPERTURACLIENTE,
                        pTIPODOCUMENTOIDENTIDAD   => vTipoID, --fudrow.TIPODOCUMENTOIDENTIDAD,
                        pNUMDOCUMENTOIDENTIDAD    => fudrow.NUMDOCUMENTOIDENTIDAD,
                        pIDOFICIAL                => vCodigoEjecutivo, --fudrow.IDOFICIAL),
                        pIDAGENCIA                => fudrow.IDAGENCIA,
                        pPRIMERNOMBRE             => vPrimerNombre,  --fudrow.PRIMERNOMBRE,
                        pPRIMERAPELLIDO           => vPrimerApellido,--fudrow.PRIMERAPELLIDO,
                        pSEXO                     => fudrow.SEXO,
                        pFECHANACIMIENTO          => fudrow.FECHANACIMIENTO,
                        pAPODO                    => fudrow.APODO,
                        pIDEMPLEADO               => fudrow.IDEMPLEADO,
                        pIDPAIS                   => fudrow.IDPAIS,
                        pIDPROVINCIA              => fudrow.IDPROVINCIA,
                        pIDMUNICIPIO              => fudrow.IDMUNICIPIO,
                        pIDDISTRITO               => fudrow.IDDISTRITO,
                        pIDESTADOCIVIL            => fudrow.IDESTADOCIVIL,
                        pNOHIJOS                  => fudrow.NOHIJOS,
                        pDEPENDIENTES             => fudrow.DEPENDIENTES,
                        pGRADOINT                 => fudrow.GRADOINT,
                        pIDOCUPACION              => fudrow.IDOCUPACION,
                        pIDVINCULADO              => fudrow.IDVINCULADO,
                        pNOMBREVINCULADO          => fudrow.NOMBREVINCULADO,
                        pIDTIPOVINCULADO          => fudrow.IDTIPOVINCULADO,
                        pIDCOMOSUPONOSOTROS       => fudrow.IDCOMOSUPONOSOTROS,
                        pDIRECCION                => fudrow.DIRECCION,
                        pDIRECCION_IDSECTOR       => fudrow.DIRECCION_IDSECTOR,
                        pDIRECCION_IDPROVINCIA    => fudrow.DIRECCION_IDPROVINCIA,
                        pDIRECCION_IDMUNICIPIO    => fudrow.DIRECCION_IDMUNICIPIO,
                        pDIRECCION_DISTRITO       => fudrow.DIRECCION_DISTRITO,
                        pDIRECCION_IDTIPOVIVIENDA => fudrow.DIRECCION_IDTIPOVIVIENDA,
                        pREF_DOMICILIO            => fudrow.REF_DOMICILIO,
                        pTELEFONO_CASA            => fudrow.TELEFONO_CASA_FORMATO,--fudrow.TELEFONO_CASA,
                        pTELEFONO_CELULAR         => fudrow.TELEFONO_CELULAR_FORMATO,--fudrow.TELEFONO_CELULAR,
                        pNOMBRENEGOCIO            => fudrow.NOMBRENEGOCIO,
                        pNOEMPLEADOS              => fudrow.NOEMPLEADOS,
                        pRNC                      => fudrow.RNC,
                        pFAX                      => fudrow.FAX,
                        pEMAIL                    => fudrow.EMAIL,
                        pSECTORECONOMICO          => fudrow.SECTORECONOMICO,
                        pACTIVIDAD_CIIU           => fudrow.ACTIVIDAD_CIIU,
                        pIDRAMA_CIIU              => fudrow.IDRAMA_CIIU,
                        pINICIO_MES               => fudrow.INICIO_MES,
                        pINICIO_ANO               => fudrow.INICIO_ANO,
                        pUBICACION_NEG            => fudrow.UBICACION_NEG,
                        pLUGARTRABAJO             => fudrow.LUGARTRABAJO,
                        pFECHAINGRESO             => vFECHA_PROCESADA,--fudrow.FECHAINGRESO,
                        pCARGO                    => fudrow.CARGO,
                        pTRABAJO_DIRECCION        => fudrow.TRABAJO_DIRECCION,
                        pTRABAJO_IDSECTOR         => fudrow.TRABAJO_IDSECTOR,
                        pTRABAJO_IDPROVINCIA      => fudrow.TRABAJO_IDPROVINCIA,
                        pTRABAJO_IDMUNICIPIO      => fudrow.TRABAJO_IDMUNICIPIO,
                        pTRABAJO_IDDISTRITO       => fudrow.TRABAJO_IDDISTRITO,
                        pPUNTOREFERENCIA          => fudrow.PUNTOREFERENCIA,
                        pTELEFONO                 => fudrow.TELEFONO,
                        pEXTENSION                => fudrow.EXTENSION,
                        pREFPERSONALES_APELLIDOS  => fudrow.REFPERSONALES_APELLIDOS,
                        pREFPERSONALES_NOMBRES    => fudrow.REFPERSONALES_NOMBRES,
                        pREFPERSONALES_TELEFONO   => fudrow.REFPERSONALES_TELEFONO,
                        pREFPERSONALES_RELFAMILIAR => fudrow.refpersonales_relacionfamiliar,
                        pREFPERSONALES_NOMBRES2   => fudrow.REFPERSONALES_NOMBRES2,
                        pREFPERSONALES_APELLIDOS2 => fudrow.REFPERSONALES_APELLIDOS2,
                        pREFPERSONALES_TELEFONO2  => fudrow.REFPERSONALES_TELEFONO2,
                        pREFPERSONALES_RELFAM2    => fudrow.REFPERSONALES_RELFAM2,
                        pACTUALMENTEENMORA        => fudrow.ACTUALMENTEENMORA,
                        pCUMPLIOREQUISITOS        => fudrow.CUMPLIOREQUISITOS,
                        pPRESENTO_DOC_FRAUDULENTA => fudrow.PRESENTO_DOC_FRAUDULENTA,
                        pDIJOLAVERDAD             => fudrow.DIJOLAVERDAD,
                        pCLIENTEESFIADOR          => fudrow.CLIENTEESFIADOR,
                        pCLIENTEMOROSO            => fudrow.CLIENTEMOROSO,
                        pSOBREENDEUDAMIENTO_SF    => fudrow.SOBREENDEUDAMIENTO_SF,
                        pACTIVIDADCLIENTE         => fudrow.ACTIVIDADCLIENTE,
                        pTIPOPERSONA              => fudrow.TIPOPERSONA,
                        pTIPODOCUMENTOIDENTIDADCO => fudrow.TIPODOCUMENTOIDENTIDADCO,
                        pNUMDOCUMENTOIDENTIDADCO  => fudrow.NUMDOCUMENTOIDENTIDADCO,
                        pPRIMERNOMBRECO           => fudrow.PRIMERNOMBRECO,
                        pPRIMERAPELLIDOCO         => fudrow.PRIMERAPELLIDOCO,
                        pSEXOCO                   => fudrow.SEXOCO,
                        pFECHANACIMIENTOCO        => fudrow.FECHANACIMIENTOCO,
                        pAPODOCO                  => fudrow.APODOCO,
                        pIDEMPLEADOCO             => fudrow.IDEMPLEADOCO,
                        pIDPAISCO                 => fudrow.IDPAISCO,
                        pIDPROVINCIACO            => fudrow.IDPROVINCIACO,
                        pIDMUNICIPIOCO            => fudrow.IDMUNICIPIOCO,
                        pIDDISTRITOCO             => fudrow.IDDISTRITOCO,
                        pIDESTADOCIVILCO          => fudrow.IDESTADOCIVILCO,
                        pNOHIJOSCO                => fudrow.NOHIJOSCO,
                        pDEPENDIENTESCO           => fudrow.DEPENDIENTESCO,
                        pGRADOINTCO               => fudrow.GRADOINTCO,
                        pIDOCUPACIONCO            => fudrow.IDOCUPACIONCO,
                        pIDVINCULADOCO            => fudrow.IDVINCULADOCO,
                        pNOMBREVINCULADOCO        => fudrow.NOMBREVINCULADOCO,
                        pIDTIPOVINCULADOCO        => fudrow.IDTIPOVINCULADOCO,
                        pIDCOMOSUPONOSOTROSCO     => fudrow.IDCOMOSUPONOSOTROSCO,
                        pNOMBRENEGOCIOCO          => fudrow.NOMBRENEGOCIOCO,
                        pNOEMPLEADOSCO            => fudrow.NOEMPLEADOSCO,
                        pRNCCO                    => fudrow.RNCCO,
                        pFAXCO                    => fudrow.FAXCO,
                        pEMAILCO                  => fudrow.EMAILCO,
                        pSECTORECONOMICOCO        => fudrow.SECTORECONOMICOCO,
                        pACTIVIDAD_CIIUCO         => fudrow.ACTIVIDAD_CIIUCO,
                        pIDRAMA_CIIUCO            => fudrow.IDRAMA_CIIUCO,
                        pINICIO_MESCO             => fudrow.INICIO_MESCO,
                        pINICIO_ANOCO             => fudrow.INICIO_ANOCO,
                        pUBICACION_NEGCO          => fudrow.UBICACION_NEGCO,
                        pLUGARTRABAJOCO           => fudrow.LUGARTRABAJOCO,
                        pFECHAINGRESOCO           => fudrow.FECHAINGRESOCO,
                        pTRABAJO_DIRECCIONCO      => fudrow.TRABAJO_DIRECCIONCO,
                        pTRABAJO_IDSECTORCO       => fudrow.TRABAJO_IDSECTORCO,
                        pTRABAJO_IDPROVINCIACO    => fudrow.TRABAJO_IDPROVINCIACO,
                        pTRABAJO_IDMUNICIPIOCO    => fudrow.TRABAJO_IDMUNICIPIOCO,
                        pTRABAJO_IDDISTRITOCO     => fudrow.TRABAJO_IDDISTRITOCO,
                        pPUNTOREFERENCIACO        => fudrow.PUNTOREFERENCIACO,
                        pTELEFONOCO               => fudrow.TELEFONOCO,
                        pEXTENSIONCO              => fudrow.EXTENSIONCO,
                        pCARGOCO                  => fudrow.CARGOCO,
                        pRESIDE_MES               => fudrow.RESIDE_MES,
                        pRESIDE_ANO               => fudrow.RESIDE_ANO,
                        pACTIVIDADCO              => fudrow.ACTIVIDADCO,
                        pTIPOPERSONACO            => fudrow.TIPOPERSONACO,
                        pTIPOSOLICITUD            => fudrow.TIPOSOLICITUD,
                        pCODIGOPROYECTO           => vTipoProyecto,--fudrow.CODIGOPROYECTO),
                        pDESTINOCREDITO           => fudrow.DESTINOCREDITO,
                        pESPECIFIQUEDESTINO       => fudrow.ESPECIFIQUEDESTINO,
                        pTIPOPERSONACAL           => fudrow.TIPOPERSONACAL,
                        pEDADCAL                  => fudrow.EDADCAL,
                        pMONTOCAL                 => vRow_Repre.mto_prestamo, --fudrow.MONTOCAL,  ---Valor solicitud
                        pPLAZOCAL                 => vRow_Repre.plazo, -- fudrow.PLAZOCAL,   ----Valor solicitud
                        pMONEDACAL                => fudrow.MONEDACAL,
                        pDIAPAGOCAL               => fudrow.DIAPAGOCAL,
                        pFRECUENCIACAL            => vPeriodicidad, ---fudrow.FRECUENCIACAL,  Frecuencia Mensual Fija por el momento
                        pGRACIACAL                => fudrow.GRACIACAL,
                        pGARANTIACAL              => fudrow.GARANTIACAL,
                        pSEGURO_VEHICULOCAL       => fudrow.SEGURO_VEHICULOCAL,
                        pSEGURO_VIDACAL           => fudrow.SEGURO_VIDACAL,
                        pSEGURO_INCENDIOCAL       => fudrow.SEGURO_INCENDIOCAL,
                        pGASTOSCAL                => fudrow.GASTOSCAL,
                        pTIPOPRESTAMOCAL          => fudrow.TIPOPRESTAMOCAL,
                        pGARANTIASOLIDARIACAL     => fudrow.GARANTIASOLIDARIACAL,
                        pHIPOTECARIACAL           => fudrow.HIPOTECARIACAL,
                        pPRENDARIACAL             => fudrow.PRENDARIACAL,
                        pLIQUIDACAL               => fudrow.LIQUIDACAL,
                        pCUOTASEGUROCAL           => fudrow.CUOTASEGUROCAL,
                        pCUOTAPRESTAMOCAL         => vRow_Repre.mto_cuota,---fudrow.CUOTAPRESTAMOCAL,
                        pTOTALFINANCIARCAL        => fudrow.TOTALFINANCIARCAL,
                        pTASACAL                  => vRow_Repre.tasa_interes, --fudrow.TASACAL,  --Valor solicitud
                        pGASTOSLEGALESCAL         => vRow_Repre.GASTOSLEGALES, -------------
                        pSEGUROVIDACAL            => vRow_Repre.SEGURO_VIDA, ---fudrow.SEGUROVIDACAL,
                        pSEGUROALIADACAL          => fudrow.SEGUROALIADACAL,
                        pSEGUROVEHCAL             => fudrow.SEGUROVEHCAL,
                        pCLASIFICACION            => fudrow.CLASIFICACION,
                        pFIRMACLIENTE             => fudrow.FIRMACLIENTE,
                        pFIRMACO                  => fudrow.FIRMACO,
                        pCLIENTEPERTENECE         => fudrow.CLIENTEPERTENECE,
                        pFECHA_REGISTRO           => vFecha, --sysdate,--fudow.FECHA_REGISTRO,
                        pTIPOCAL                  => fudrow.TIPOCAL,
                        pTIPOPARENTESCO           => fudrow.TIPOPARENTESCO,
                        pTIPOPARENTESCOCO         => fudrow.TIPOPARENTESCOCO,
                        pTIPOPERSONA2             => fudrow.TIPOPERSONA2,
                        pTIPOCLIENTE              => fudrow.TIPOCLIENTE,
                        pTIPOPRODUCTOS            => fudrow.TIPOPRODUCTOS,
                        pACTIVIDADCIIU_SOL        => fudrow.ACTIVIDADCIIU_SOL,
                        pIDRAMACIIU_SOL           => fudrow.IDRAMACIIU_SOL,
                        ERRORCODE                 => vERRORCODE,
                        ERRORDESCRIPTION          => vERRORDESCRIPTION,
                        pNOCREDITO                => vpNOCREDITO,
                        pSEGUNDONOMBRE            => vSegundoNombre,  --fudrow.PRIMERNOMBRE,
                        pSEGUNDOAPELLIDO          => vSegundoApellido,--fudrow.SEGUNDOAPELLIDO,
                        pSEGUNDONOMBRECO          => fudrow.SEGUNDONOMBRECO,
                        pSEGUNDOAPELLIDOCO        => fudrow.SEGUNDOAPELLIDOCO,
                        pCODPAISISO               => fudrow.CODPAISISO,
                        pAPELLIDOCASADACLIENTE    => fudrow.APELLIDOCASADACLIENTE,
                        pCEDULAEXTRANJERA         => fudrow.CEDULAEXTRANJERA);

                    IF vERRORDESCRIPTION IS NOT NULL
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' Error creando tempfud vERRORDESCRIPTION' || vERRORDESCRIPTION;
                        p_depura (pError);
                        DBMS_OUTPUT.put_line (pError);
                        ROLLBACK;
                        RETURN;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
                        p_depura (pError);
                        DBMS_OUTPUT.put_line (pError);
                         DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); 
                        ROLLBACK;
                        RETURN;
                END;
               COMMIT;
               BEGIN
                    SELECT PR.SQ_TEMPFUD_EXT.NEXTVAL INTO vID_TEMPFUD_EXT FROM DUAL;
                END;

             BEGIN
             
              SELECT NOCREDITO,NOMARCHIVO INTO vpNOCREDITOGenerado,vNombreArchivoNuevoGenerado FROM TEMPFUD WHERE ID_TEMPFUD = vid_tempfudGenerado;
                pNuevo_credito := vpNOCREDITOGenerado;
             --DBMS_OUTPUT.PUT_LINE ( 'fud extendida Linea:' || $$plsql_linec|| vid_tempfudGenerado  || ' ' || vNombreArchivoNuevoGenerado  ); 
               
                    PR.PKG_SOLICITUD_CREDITO.P_CREAR_FUDExtendida (
                                    pID                             => vID_TEMPFUD_EXT,
                                    pID_TEMPFUD                     => vid_tempfudGenerado,
                                    pNOMARCHIVO                     => vNombreArchivoNuevoGenerado,
                                    --Nacionalidad USA
                                    pRESIDENTEUSA                   => NULL,
                                    pNROPASAPORTEUSA                => NULL,
                                    pNROITIN                        => NULL,
                                    pNROSSN                         => NULL,
                                    pNRORESIDENCIA                  => NULL, --green card
                                    ---
                                    pZONA                           => NULL,
                                    pCONDICIONVIVIENDA              => NULL,
                                    pNEGOCIODOMICILIO               => NULL, --VARCHAR2,
                                    pTIPOSERVICIO                   => NULL,
                                    pMONTOINICIAL                   => NULL,
                                    pORIGENRECURSOS                 => NULL, --NUMBER,
                                    pFORMAOPERACION                 => NULL,
                                    pINGRESOSMENSUAL                => NULL,
                                    --PEPS
                                    pFUNCIONARIOGOB                 => NULL, --VARCHAR2, --PEPS
                                    pESPEFICIQUEFUNCI               => NULL,
                                    pPARENTESCOFUNCI                => NULL, --VARCHAR2, --PARENTESCO PEPS
                                    pEXPECIFIQUEPAREN               => NULL,
                                    pREFERENCIACOMERNOM1            => NULL,
                                    pREFERENCIACOMERTEL1            => NULL,
                                    pREFERENCIACOMERNOM2            => NULL,
                                    pREFERENCIACOMERTEL2            => NULL,
                                    pREFERENCIABANCANOM1            => NULL,
                                    pREFERENCIABANCATIP1            => NULL,
                                    pREFERENCIABANCANUM1            => NULL,
                                    pREFERENCIABANCANOM2            => NULL,
                                    pREFERENCIABANCATIP2            => NULL,
                                    pREFERENCIABANCANUM2            => NULL,
                                    pREFERENCIAPERAPODO1            => NULL,
                                    pREFERENCIAPERAPODO2            => NULL,
                                    pREFERENCIAFAMNOM               => NULL,
                                    pREFERENCIAFAMAPE               => NULL,
                                    pREFERENCIAFAMAPODO             => NULL,
                                    pREFERENCIAFAMTELEFONO          => NULL,
                                    --pSEGUROCONTRATADO            NUMBER,
                                    --pSEGUROOTROESPEFICIQUE       VARCHAR2,
                                    pSEGUROINCENDIOpyme             => vSeguroMipyme, --malmanzar 16-03-2023
                                    pSEGURODESEMPLEODIS             => vSeguroDesempleo,
                                    pSEGUROOTROESPEFICIQUE          => NULL,
                                    pFECHA_CARGA                    => CURRENT_DATE,
                                    --malmanzar 23-01-2023 Begin
                                    pTIPOMONEDA                     => NULL,
                                    pFORMASDEPOSITO                 => NULL,
                                    pACTIVOSTOTAL                   => NULL,
                                    pVOLUMENVENTA                   => NULL,
                                    pPATRIMONIONETO                 => NULL,
                                    pRANGOVOLUMENMENSUAL            => NULL,
                                    pCANTIDADTRANSACCIONES          => NULL,
                                    pTIENEEBANKINGNUMBER            => NULL,
                                    pPOSEEDOBLECIUDADANIA           => NULL,
                                    pPOSEEDOBLECIUDADANIAPAIS       => NULL,
                                    pMENSAJE                    => vERRORCODE1,
                                    pERRORCODE                   => vERROR1,
                                    pERRORDESCRIPTION           => vERRORDESCRIPTION1 );

                    IF vERRORDESCRIPTION1 IS NOT NULL
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' Error creando tempfud vERRORDESCRIPTION1' || vERRORDESCRIPTION1;
                        p_depura (pError);
                        DBMS_OUTPUT.PUT_LINE ( 'vERRORCODE1 = ' || vERRORCODE1 );
                        DBMS_OUTPUT.PUT_LINE ( 'vERROR1 = ' || vERROR1 );
                        DBMS_OUTPUT.put_line (pError);
                        ROLLBACK;
                        RETURN;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
                        p_depura (pError);
                        --DBMS_OUTPUT.put_line (pError);
                         -- DBMS_OUTPUT.PUT_LINE ( 'vERRORCODE1 = ' || vERRORCODE1 );
                          --DBMS_OUTPUT.PUT_LINE ( 'vERROR1 = ' || vERROR1 );
                         -- DBMS_OUTPUT.PUT_LINE ( 'vERRORDESCRIPTION1 = ' || vERRORDESCRIPTION1 );
                        ROLLBACK;
                        RETURN;
             END;

    
                           -- DBMS_OUTPUT.put_line ('vERRORCODE ' || vERRORCODE);
                           --DBMS_OUTPUT.put_line ('vERRORDESCRIPTION ' || vERRORDESCRIPTION);
                           -- DBMS_OUTPUT.put_line ('vpNOCREDITO ' || vpNOCREDITO);
                           -- DBMS_OUTPUT.put_line ('vID_TEMPFUD ' || vID_TEMPFUD);

                SELECT NOCREDITO,NOMARCHIVO INTO vpNOCREDITOGenerado,vNombreArchivoNuevoGenerado FROM TEMPFUD WHERE ID_TEMPFUD = vid_tempfudGenerado;
                pNuevo_credito := vpNOCREDITOGenerado;
                
                    --DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevoGenerado: ' || vNombreArchivoNuevoGenerado);
                   -- DBMS_OUTPUT.put_line ('vpNOCREDITOGenerado: ' ||vpNOCREDITOGenerado);
                    --DBMS_OUTPUT.put_line ('pNuevo_credito: ' ||pNuevo_credito);
                IF vpNOCREDITOGenerado IS NOT NULL THEN
                    BEGIN
                        pr.pkg_recredito.p_genera_recredito (
                            pcodigo_empresa    => pCodigo_Empresa,
                            pNo_credito        => vpNOCREDITOGenerado,
                            pCredito_Cancela   => vRow_Repre.no_credito,
                            pfecha             => pFecha_Calendario,
                            pUser              => USER,
                            pAccion            => 'I'); -- I = Insert, 'D' = Delete
                    EXCEPTION
                        WHEN DUP_VAL_ON_INDEX  THEN
                            NULL;
                        WHEN OTHERS
                        THEN
                            pError := 'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM;
                            p_depura (pError);
                            DBMS_OUTPUT.put_line (pError);
                            ROLLBACK;
                            RETURN;
                    END;                   
                   -- DBMS_OUTPUT.put_line ( 'vNombreArchivoNuevo: ' || vNombreArchivoNuevoGenerado);
                   -- DBMS_OUTPUT.put_line ('fudrow.IDPAIS: ' ||vRow_Repre.no_credito);
                    --DBMS_OUTPUT.put_line ('vID_TEMPFUD: ' ||vid_tempfudGenerado);
                    COMMIT;
                    IF pNuevo_credito IS NOT NULL AND vid_tempfudGenerado IS NOT NULL AND vNombreArchivoNuevoGenerado IS NOT NULL THEN
                        -- Actualiza el numero de credito en Solicitud
                        PR_PKG_REPRESTAMOS.P_Actualiza_Credito_Solicitud( pNum_Represtamo, pNuevo_credito, vid_tempfudGenerado, vNombreArchivoNuevoGenerado, pError);    
                        COMMIT;
                        ELSE
                         pError := 'Linea ' || $$plsql_line || ' No se ha generado la Fud Correctamente pNuevo_credito: '||pNuevo_credito ||' vID_TEMPFUD: '||vid_tempfudGenerado || 'vNombreArchivoNuevo: '||vNombreArchivoNuevoGenerado;
                         p_depura (pError);
                          DBMS_OUTPUT.put_line (pError);
                    END IF;                
                    
                    IF PR.PR_PKG_REPRESTAMOS.F_VALIDAR_TIPO_REPRESTAMO(pNum_Represtamo) THEN
                        vIdDocsReutilizar := PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CODIGOS_DOCUMENTOS_REUTILIZAR');
                    
                    ELSE
                        vIdDocsReutilizar := NULL;
                    
                    END IF;

                            vIdTipoDocumento := '450'; -- CONSULTA LEXIS NEXIS SROBLES 28/11/2023
                            vDocumento := 'LEXISNEXIS';
                            vCodigoReferencia := '1:'||vRow_Repre.identificacion||':'||vpNOCREDITOGenerado||':'||vRow_Repre.no_credito||':LEXISNEXIS'|| ':' || vid_tempfudGenerado;
                            vNombreArchivo := vDocumento || '_' || vpNOCREDITOGenerado || '_' || vRow_Repre.no_credito;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Represtamo',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vNombreArchivo || '.pdf',
                                pEstado             => 'R',
                                pIdDocsReutilizar   => vIdDocsReutilizar,
                                pRespuesta          => pError);
                                
                             COMMIT;
                       
                       
                       PR_PKG_REPRESTAMOS.p_generar_bitacora ( pNum_Represtamo, NULL, 'CRS', NULL, 'Credito solicitado', USER);           
                         ELSE
                         pError := 'Linea ' || $$plsql_line || ' No se ha insertado correctamente la URL del reporte vTipoID: '||vTipoID ||
                           ' fudrow.NumDocumentoIdentidad: '||fudrow.NumDocumentoIdentidad || ' pNuevo_credito: '||pNuevo_credito||' vRow_Repre.no_credito '||vRow_Repre.no_credito;
                         p_depura (pError);
                          DBMS_OUTPUT.put_line (pError);
                          
                      
                    --Registra Bitácora
                    /*UPDATE PR.PR_REPRESTAMOS R SET R.ESTADO= 'CRS' WHERE R.ID_REPRESTAMO = pNum_Represtamo;
                    COMMIT;*/
                    
                       BEGIN
                        
                        COMMIT;    
                        
                            EXCEPTION WHEN OTHERS THEN
                                DECLARE
                               vIdError      PLS_INTEGER := 0;
                               BEGIN                                    
                                  
                                  IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',   pNum_Represtamo);
                                  IA.LOGGER.ADDPARAMVALUEV('ESTADO',    'CRS');
                                        
                                  setError(pProgramUnit => 'P_PROCESA_CREDITO_CANCELADO', 
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
                END IF;
                
               --ACTUALIZACION DEL CAMPO NOTIF_DIGITAL  EN TEL PERSONA

              SELECT VALOR into vCtelefono FROM PR_CANALES_REPRESTAMO WHERE CANAL = 1 AND ID_REPRESTAMO = vRow_Repre.id_represtamo;
              SELECT CODIGO_AGENCIA INTO COD_AGENCIA FROM PA.CLIENTES_B2000 WHERE COD_CLIENTE =  vRow_Repre.codigo_cliente;
              
              SELECT COUNT(*)
              INTO vSubqueryResult
              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('SUCURSALES_PILOTO_FIRMA')) t
              WHERE t.COLUMN_VALUE = COD_AGENCIA;
              vSucursal := PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SUCURSALES_PILOTO_FIRMA') ;
              
                FOR A IN ACTUALIZA_TELEFONO LOOP
                    IF vSubqueryResult > 0  OR  vSucursal IS NULL THEN
                        IF A.TELEFONO = vCtelefono AND A.TIP_TELEFONO = 'C' THEN
                            UPDATE PA.TEL_PERSONAS
                            SET NOTIF_DIGITAL = 'S'
                            WHERE TIP_TELEFONO = 'C' AND COD_AREA || NUM_TELEFONO = vCtelefono AND COD_PERSONA = vRow_Repre.codigo_cliente;
                        ELSIF A.TELEFONO <> vCtelefono THEN
                        --DBMS_OUTPUT.PUT_LINE ( 'VALIDO QUE LOS CANALES SEAN DISTINTOS '  );
                            UPDATE PA.TEL_PERSONAS
                            SET NOTIF_DIGITAL = 'N'
                            WHERE COD_AREA || NUM_TELEFONO <> vCtelefono AND COD_PERSONA = vRow_Repre.codigo_cliente;
                        END IF;
                    ELSE
                    --DBMS_OUTPUT.PUT_LINE ( 'VALIDO QUE NO ESTA EN LA SUCURSAL HABILITAD '  );
                        UPDATE PA.TEL_PERSONAS
                        SET NOTIF_DIGITAL = 'N'
                        WHERE COD_PERSONA = vRow_Repre.codigo_cliente;
                    END IF;
                END LOOP;
            
            /*FOR A IN ACTUALIZA_TELEFONO LOOP
            
             IF vRow_Repre.codigo_agencia IN (5,6) THEN
             --(select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'SUCURSALES_PILOTO_FIRMA')))
                IF A.TELEFONO = vCtelefono AND A.TIP_TELEFONO = 'C' THEN
                    UPDATE PA.TEL_PERSONAS SET NOTIF_DIGITAL = 'S' WHERE TIP_TELEFONO = 'C' AND COD_AREA || NUM_TELEFONO = vCtelefono AND COD_PERSONA = vRow_Repre.codigo_cliente;
                ELSIF A.TELEFONO <> vCtelefono THEN
                    UPDATE PA.TEL_PERSONAS SET NOTIF_DIGITAL = 'N' WHERE COD_AREA || NUM_TELEFONO <> vCtelefono AND COD_PERSONA = vRow_Repre.codigo_cliente;
                END IF;
             ELSE
             
               UPDATE PA.TEL_PERSONAS SET NOTIF_DIGITAL = 'N' WHERE COD_PERSONA = vRow_Repre.codigo_cliente;
             
             END IF;
            END LOOP;*/


            ELSE                                                  
                pError := 'Error: tempfud no encontrada para el crédito base ' || vRow_Repre.no_credito;
                p_depura (pError);
                ROLLBACK;
                RETURN;
            END IF;                                                 

            fudRow := NULL;
        ELSE
            pError := 'Error: id_represtamo ' || pNum_Represtamo || ' NO encontrado';
            p_depura (pError);
            ROLLBACK;
            RETURN;
        END IF;                                                   --

        CLOSE c_repre;
    EXCEPTION
        WHEN OTHERS THEN
            /*pError := 'Linea ' || $$plsql_line || 'sqlerrm ' || SQLERRM || ' vERRORDESCRIPTION ' || vERRORDESCRIPTION || ' vERRORCODE ' || vERRORCODE;
            P_DEPURA (pError);
            --DBMS_OUTPUT.put_line (pError);
            ROLLBACK;
            RETURN;*/
          DECLARE
            vIdError      PLS_INTEGER := 0;
          BEGIN
                                    
              IA.LOGGER.ADDPARAMVALUEV('pCodigo_Empresa',            pCodigo_Empresa);
              IA.LOGGER.ADDPARAMVALUEV('pNum_Represtamo',          pNum_Represtamo);
              IA.LOGGER.ADDPARAMVALUEV('pPeriodicidad',        pPeriodicidad);  
              IA.LOGGER.ADDPARAMVALUEV('pMtoPrestamo',        pMtoPrestamo); 
              IA.LOGGER.ADDPARAMVALUEV('pNumCliente',        pNumCliente); 
              
              setError(pProgramUnit => 'P_Procesa_Credito_Cancelado', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
          END;  
            
    END P_Procesa_Credito_Cancelado;  
    PROCEDURE P_GENERA_DOCUMENTOS (pError OUT VARCHAR2)IS 
    
     CURSOR CARGA_DOCUMENTOS IS
       SELECT  R.NO_CREDITO CREDITO_ANTERIOR, S.NO_CREDITO CREDITO_NUEVO,ID_TEMPFUD, NVL(ID_TEMPFEC,0) ID_TEMPFEC, S.NOMARCHIVO, R.CODIGO_CLIENTE, S.IDENTIFICACION, S.ESTADO
          FROM PR_SOLICITUD_REPRESTAMO S, PR_REPRESTAMOS R
         WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND S.CODIGO_EMPRESA = R.CODIGO_EMPRESA
           AND R.ESTADO IN (select COLUMN_VALUE FROM  TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_PARA_ENVIO_SIB_BURO')))
           AND S.ID_REPRESTAMO = R.ID_REPRESTAMO;
           
                  
        vMensaje    VARCHAR2(4000);
        vIdTemfec   PR.PR_SOLICITUD_REPRESTAMO.ID_TEMPFEC%TYPE;
        vURL                 VARCHAR2(4000);
        vIdAplication        PLS_INTEGER := 2; 
        vIdTipoDocumento     PLS_INTEGER ; 
        vCodigoReferencia    VARCHAR2(100);
        vDocumento           VARCHAR2(30) ;
        vNombreArchivo       VARCHAR2(60);
        vESTADO              VARCHAR2(30);
        vBuro                NUMBER(10);
        vSIB                 NUMBER(10);
        VCREDITO VARCHAR2(300);
    BEGIN

       FOR A IN CARGA_DOCUMENTOS LOOP
            BEGIN
            SELECT ESTADO_REPORTE, CODIGO_REFERENCIA INTO vESTADO, VCREDITO FROM PA.PA_REPORTES_AUTOMATICOS WHERE NOMBRE_ARCHIVO = 'LEXISNEXIS_'||A.CREDITO_NUEVO||'_'||A.CREDITO_ANTERIOR||'.pdf';
            DBMS_OUTPUT.PUT_LINE ( 'vESTADO = ' || vESTADO );
            DBMS_OUTPUT.PUT_LINE ( 'VCREDITO = ' || VCREDITO );
             EXCEPTION WHEN NO_DATA_FOUND THEN
                      vESTADO:= 'l';
            END;
            
            BEGIN
               SELECT COUNT(*) INTO vBuro FROM  PA.PA_REPORTES_AUTOMATICOS WHERE NOMBRE_ARCHIVO = 'BURO'||'_'||A.CREDITO_NUEVO||'_'||A.CREDITO_ANTERIOR||'.pdf';
             EXCEPTION WHEN NO_DATA_FOUND THEN
                      vBuro:= 1;
            END;
            
           
            BEGIN
                SELECT COUNT(*) INTO vSIB FROM  PA.PA_REPORTES_AUTOMATICOS WHERE NOMBRE_ARCHIVO = 'SIB'||'_'||A.CREDITO_NUEVO||'_'||A.CREDITO_ANTERIOR||'.pdf';
             EXCEPTION WHEN NO_DATA_FOUND THEN
                      vSIB:= 1;
            END;
            DBMS_OUTPUT.PUT_LINE ( 'vSIB = ' || vSIB || A.CREDITO_NUEVO );
            
         IF vESTADO = 'S' AND vBURO = 0 AND vSIB = 0 THEN
                            vIdTipoDocumento := '193';  -- CONSULTA BURO DE CREDITO PRIVADO 
                            vDocumento       := 'BURO';  
                            vCodigoReferencia := '1:'||A.IDENTIFICACION||':'||A.CREDITO_NUEVO||': :'||vDocumento||':'||A.ID_TEMPFUD; 
                            vNombreArchivo    := vDocumento||'_'||A.CREDITO_NUEVO||'_'||A.CREDITO_ANTERIOR;                                                   
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => NULL, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo||'.pdf',   
                                                            pEstado             => 'R',
                                                            pRespuesta          => pError
                                                           );
                        DBMS_OUTPUT.PUT_LINE ( 'vCodigoReferencia = ' || vCodigoReferencia );
                            vIdTipoDocumento := '194';  -- CONSULTA BUSCADOR DE GOOGLE
                            vDocumento       := 'SIB';  
                            vCodigoReferencia := '1:'||A.IDENTIFICACION||':'||A.CREDITO_NUEVO||': :'||vDocumento;     
                            vNombreArchivo    := vDocumento||'_'||A.CREDITO_NUEVO||'_'||A.CREDITO_ANTERIOR;                                                                                                 
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => NULL, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo||'.pdf',   
                                                            pEstado             => 'R',
                                                            pRespuesta          => pError
                                                           );   
                                                           DBMS_OUTPUT.PUT_LINE ( 'vCodigoReferencia = ' || vCodigoReferencia );
                                                           
                                                           
                                                      
                         /*  vIdTipoDocumento := '450';                  -- CONSULTA LEXIS NEXIS
                            vDocumento := 'LEXIS';
                            vCodigoReferencia := '1:' || A.IDENTIFICACION || ':' || A.CREDITO_NUEVO || ': :' || vDocumento;
                            vNombreArchivo := vDocumento || '_' || A.CREDITO_NUEVO || '_' || A.CREDITO_ANTERIOR;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Represtamo',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vNombreArchivo || '.pdf',
                                pEstado             => 'R',
                                pRespuesta          => pError);     */  
                                 
                                                  
            END IF;
      END LOOP;
      
          EXCEPTION WHEN OTHERS THEN   
           DECLARE
           vIdError      PLS_INTEGER := 0;
           BEGIN                                    
                      
              setError(pProgramUnit => 'P_GENERA_DOCUMENTOS', 
              pPieceCodeName => NULL, 
              pErrorDescription => SQLERRM ,                                                              
              pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
              pEmailNotification => NULL, 
              pParamList => IA.LOGGER.vPARAMLIST, 
              pOutputLogger => FALSE, 
              pExecutionTime => NULL, 
              pIdError => vIdError); 
             END;  
     END P_GENERA_DOCUMENTOS;
    PROCEDURE p_Procesa_Fec(pNum_Represtamo         IN      NUMBER,
                            pCOD_AGENCIA            IN      VARCHAR2,
                            pCOD_OFICIAL            IN      VARCHAR2,
                            pCODIGO_ACTIVIDAD       IN      VARCHAR2,
                            pMARGEN_BRUTO_STD       IN      NUMBER,
                            pGASTOS_OPERATIVOS_STD  IN      NUMBER,  
                            pVENTAS_MENSUAL         IN      NUMBER,
                            pCOSTO_VENTAS           IN      NUMBER,
                            pGASTOS_OPERATIVO       IN      NUMBER,
                            pOTROS_INGRESOS         IN      NUMBER,
                            pGASTOS_FAMILIARES      IN      NUMBER,
                            pEXCEDENTE_FAMILIAR     IN      NUMBER,
                            pREL_CUOTA_EXCED_FAM    IN      NUMBER,    
                            pError                     OUT  VARCHAR2) IS
                            
        CURSOR cSol(pIdReprestamo   IN NUMBER) IS
        SELECT R.NO_CREDITO CREDITO_ANTERIOR, S.NO_CREDITO CREDITO_NUEVO, S.ID_TEMPFUD, NVL(ID_TEMPFEC,0)ID_TEMPFEC, S.NOMARCHIVO, 
               R.CODIGO_CLIENTE, S.IDENTIFICACION, S.ESTADO, OP.MTO_PRESTAMO, TF.ESPECIFIQUEDESTINO, PA.F_OBT_DESC_ACTIVIDAD(S.CODIGO_ACTIVIDAD) ACTIVIDAD_ECONOMICA   
          FROM PR.PR_SOLICITUD_REPRESTAMO S, 
               PR.PR_REPRESTAMOS R,
               PR.PR_OPCIONES_REPRESTAMO OP,
               PR.TEMPFUD TF
         WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND R.ID_REPRESTAMO = pIdReprestamo
           AND S.CODIGO_EMPRESA = R.CODIGO_EMPRESA
           AND S.ID_REPRESTAMO = R.ID_REPRESTAMO
           AND S.ID_REPRESTAMO = OP.ID_REPRESTAMO
           AND S.ID_TEMPFUD = TF.ID_TEMPFUD;
        
        vRow        cSol%ROWTYPE;           
        vMensaje    VARCHAR2(4000);
        vIdTemfec   PR.PR_SOLICITUD_REPRESTAMO.ID_TEMPFEC%TYPE;
        vURL                 VARCHAR2(4000);
        vIdAplication        PLS_INTEGER := 2; -- Prestamos
        vIdTipoDocumento     PLS_INTEGER := '477'; -- FEC DEUDOR
        vCodigoReferencia    VARCHAR2(100) := vRow.CREDITO_NUEVO||':'||vRow.CREDITO_ANTERIOR;
        vDocumento           VARCHAR2(30) := 'FEC';
        vNombreArchivo       VARCHAR2(60);
        vTipo_Mipyme            NUMBER;
        vTipo_Desempleo         NUMBER;
        vTipo_Vida              NUMBER;
        vSeguroMipyme           VARCHAR2(3);
        vSeguroDesempleo        VARCHAR2(3);
        vCodigoActividad        VARCHAR2(100);
    BEGIN
        -- Validación de parámetros
    IF pNum_Represtamo IS NULL THEN
        pError := 'Error el campo No.Solicitud no puede estar en blanco';
        RETURN;
    ELSIF pCODIGO_ACTIVIDAD IS NULL THEN
        pError := 'Error el campo Actividad Económica no puede estar en blanco';
        RETURN;
    ELSIF pMARGEN_BRUTO_STD IS NULL THEN
        pError := 'Error el campo Margen de Ganancia (%) no puede estar en blanco';
        RETURN;
    ELSIF pGASTOS_OPERATIVOS_STD IS NULL THEN
        pError := 'Error el campo Costos Operativos (% de ventas) no puede estar en blanco';
        RETURN;
    ELSIF pVENTAS_MENSUAL IS NULL THEN
        pError := 'Error el campo Ventas (Ingresos) no puede estar en blanco';
        RETURN;
    ELSIF pCOSTO_VENTAS IS NULL THEN
        pError := 'Error el campo Costos de Ventas no puede estar en blanco';
        RETURN;
    ELSIF pGASTOS_OPERATIVO IS NULL THEN
        pError := 'Error el campo Costos Operativos  no puede estar en blanco';
        RETURN;
    ELSIF pOTROS_INGRESOS IS NULL THEN
        pError := 'Error el campo Otros Ingresos no puede estar en blanco';
        RETURN;
    ELSIF pGASTOS_FAMILIARES IS NULL THEN
        pError := 'Error el campo Gastos Familiares no puede estar en blanco';
        RETURN;
    ELSIF pEXCEDENTE_FAMILIAR IS NULL THEN
        pError := 'Error el campo Excedente Familiar no puede estar en blanco';
        RETURN;
    ELSIF pREL_CUOTA_EXCED_FAM IS NULL THEN
        pError := 'Error el campo Relación Cuota / Excedente Familiar  no puede estar en blanco';
        RETURN;
    END IF;
        -- Determina si no se ha generado la fec
        OPEN cSol (pNum_Represtamo);
        FETCH cSol INTO vRow;

        IF cSol%FOUND THEN
    
            IF vRow.ID_TEMPFEC = 0 OR vRow.ID_TEMPFEC IS NULL then           
                BEGIN
                    UPDATE PR_SOLICITUD_REPRESTAMO 
                       SET  CODIGO_AGENCIA       = pCOD_AGENCIA,
                            CODIGO_OFICIAL       = pCOD_OFICIAL,
                            CODIGO_ACTIVIDAD     = pCODIGO_ACTIVIDAD,
                            MARGEN_BRUTO_STD     = pMARGEN_BRUTO_STD,
                            GASTO_OPERATIVO_STD  = pGASTOS_OPERATIVOS_STD,  
                            VENTAS_MENSUAL       = pVENTAS_MENSUAL,
                            COSTO_VENTAS         = pCOSTO_VENTAS,
                            GASTO_OPERATIVO      = pGASTOS_OPERATIVO,
                            OTROS_INGRESOS       = pOTROS_INGRESOS,
                            GASTOS_FAMILIARES    = pGASTOS_FAMILIARES,
                            EXCEDENTE_FAMILIARES = pEXCEDENTE_FAMILIAR,
                            REL_CUOTA_EXCED_FAM  = pREL_CUOTA_EXCED_FAM
                    WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_Obt_Empresa_Represtamo 
                      AND ID_REPRESTAMO = pNum_Represtamo;
                                                           
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error actualizando los datos para generar la FEC. '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20101, pError);
                END;
                
                -- Actualizar la informaci¿n del Cliente
                BEGIN
                    UPDATE PA.PERSONAS_FISICAS PF
                       SET PF.COD_ACTIVIDAD = pCODIGO_ACTIVIDAD
                     WHERE PF.COD_PER_FISICA = vRow.CODIGO_CLIENTE; 
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error actualizando la actividad economica del cliente. '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20102, pError);
                END;
                
                BEGIN
                    UPDATE PA.INFO_LABORAL I
                       SET i.MONTO = pVENTAS_MENSUAL + pOTROS_INGRESOS
                     WHERE i.COD_PER_FISICA = vRow.CODIGO_CLIENTE;   
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error actualizando la informaci¿n laboral del cliente. '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20103, pError);
                END;
              --ACTUALIZA FUD en CODIGO ACTIVIDAD y PLAN DE INVERSION
                
                BEGIN
                    UPDATE PR.TEMPFUD T
                      SET T.ACTIVIDAD_CIIU = (SELECT I.PLAN_INVERSION
                        FROM PA.ACTIVIDADES_ECONOMICAS_BC_CIIU A 
                        LEFT JOIN PA.ACTIV_ECONOMICAS_BC B ON B.COD_ACTIVIDAD = A.DIVISION
                        LEFT JOIN PR.PR_PLAN_INVERSION I ON I.PLAN_INVERSION = B.COD_ACTIVIDAD_BC
                        WHERE A.SEGREGACION_RD = pCODIGO_ACTIVIDAD AND ROWNUM <=1), --Plan de Inversion
                      T.IDRAMA_CIIU = pCODIGO_ACTIVIDAD
                    WHERE T.ID_TEMPFUD = vRow.ID_TEMPFUD
                      AND T.NOMARCHIVO = vRow.NOMARCHIVO;
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error actualizando Actividad de la FUD '||SQLERRM;  
                    RAISE_APPLICATION_ERROR(-20101, pError);    
                END;
                
                COMMIT;
                
                BEGIN
                    PR.PKG_SOLICITUD_CREDITO.CREA_FEC_SOLICITUD (PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO, pNum_Represtamo, vMensaje, pError);            
                    
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error generando la FEC. '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20104, pError);
                END;
                
                 --QUERY PARA OBTENER LA ACTIVIDAD ECONOMICA DE LA FEC Y ACTUALIZARLA PARA EL CONOZCA SU CLIENTE
                BEGIN
                    SELECT AC.CONCEPTO 
                    INTO vCodigoActividad
                    FROM PA.ACTIVIDADES_ECONOMICAS_BC_CIIU AC
                    LEFT JOIN PR.PR_SOLICITUD_REPRESTAMO SR ON SR.CODIGO_ACTIVIDAD = AC.SEGREGACION_RD
                    WHERE AC.SEGREGACION_RD = pCODIGO_ACTIVIDAD
                    AND   SR.ID_REPRESTAMO = pNum_Represtamo;
                END;
                                
                --ACTUALIZAR LOS CAMPOS (MONTO INICIAL, PROPOSITO, ORIGEN FONDOS Y ACTIVIDAD ECONOMICA) DEL CONOZCA SU CLIENTE 
                BEGIN
                    
                 PR.pkg_solicitud_credito.p_operaciones_realizar (
                    pcod_persona            => vRow.CODIGO_CLIENTE,
                    ptipo_producto          => 'PRESTAMOS',
                    pcod_moneda             => 1,             --'1',
                    pproposito              => vRow.ESPECIFIQUEDESTINO,
                    pmonto_inicial          => vRow.MTO_PRESTAMO,
                    pinstrumento_bancario   => '',
                        /*CASE
                            WHEN pformaoperacion = '1' THEN 'EFECTIVO'
                            WHEN pformaoperacion = '2' THEN 'CHEQUE'
                            WHEN pformaoperacion = '3' THEN 'TRANSFERENCIA'
                        END,*/
                    porigen_fondos          => vCodigoActividad,--vRow.ACTIVIDAD_ECONOMICA,
                    pno_credito             => TO_NUMBER (vRow.CREDITO_NUEVO));
                    
                END;
                   
                -- Buscar la Fec generada
                SELECT NVL(S.ID_TEMPFEC,0)
                  INTO vIdTemfec
                  FROM PR_SOLICITUD_REPRESTAMO S
                 WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_Obt_Empresa_Represtamo 
                   AND ID_REPRESTAMO = pNum_Represtamo;          
                
                IF vIdTemfec IS NOT NULL AND vIdTemfec <> 0  THEN
                    -- Generar Reporte BURO
                    BEGIN
                           /* vIdTipoDocumento := '193';  -- CONSULTA BURO DE CREDITO PRIVADO 
                            vDocumento       := 'BURO';  
                            vCodigoReferencia := '1:'||vRow.IDENTIFICACION||':'||vRow.CREDITO_NUEVO||': :'||vDocumento||':'||vRow.ID_TEMPFUD; 
                            vNombreArchivo    := vDocumento||'_'||vRow.CREDITO_NUEVO||'_'||vRow.CREDITO_ANTERIOR;                                                   
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => NULL, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo||'.pdf',   
                                                            pEstado             => 'R',
                                                            pRespuesta          => pError
                                                           );
                        
                            vIdTipoDocumento := '194';  -- CONSULTA BUSCADOR DE GOOGLE
                            vDocumento       := 'SIB';  
                            vCodigoReferencia := '1:'||vRow.IDENTIFICACION||':'||vRow.CREDITO_NUEVO||': :'||vDocumento;     
                            vNombreArchivo    := vDocumento||'_'||vRow.CREDITO_NUEVO||'_'||vRow.CREDITO_ANTERIOR;                                                                                                 
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => NULL, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo||'.pdf',   
                                                            pEstado             => 'R',
                                                            pRespuesta          => pError
                                                           );*/
                                    
                       -- Generar FEC para File Flow 
                       vIdTipoDocumento     := '477'; -- FEC DEUDOR
                       vDocumento           := 'FEC';
                       vCodigoReferencia    := vRow.CREDITO_NUEVO||': ';                       
                       vNombreArchivo := vDocumento||'_'|| vRow.CREDITO_NUEVO|| '.pdf';           
                       vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlFecReprestamos(pNum_Represtamo);                   
                       PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                        pFechaReporte       => SYSDATE,
                                                        pId_Aplicacion      => vIdAplication,
                                                        pIdTipoDocumento    => vIdTipoDocumento,
                                                        pOrigenPkm          => 'Represtamo',  
                                                        pUrlReporte         => vUrl, 
                                                        pFormatoDocumento   => 'PDF',
                                                        pNombreArchivo      => vNombreArchivo,  
                                                        pEstado             => 'P',
                                                        pRespuesta          => pError
                                                       );
                       
                       vIdTipoDocumento := '474';  -- FUD
                       vDocumento       := 'FUD';                                                                              
                       vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlFudReprestamos(vRow.ID_TEMPFUD, vRow.NOMARCHIVO);  
                       vNombreArchivo := vDocumento||'_'|| vRow.CREDITO_NUEVO|| '.pdf';                       
                       PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( 
                                                        pCodigoReferencia   => vCodigoReferencia,
                                                        pFechaReporte       => SYSDATE,
                                                        pId_Aplicacion      => vIdAplication,
                                                        pIdTipoDocumento    => vIdTipoDocumento,
                                                        pOrigenPkm          => 'Represtamo',  
                                                        pUrlReporte         => vUrl, 
                                                        pFormatoDocumento   => 'PDF',
                                                        pNombreArchivo      =>vNombreArchivo,   
                                                        pEstado             => 'P',
                                                        pRespuesta          => pError
                                                       );
                       
                       vIdTipoDocumento     := '452'; -- Formulario de Conozca
                       vDocumento           := 'FCSCPF';
                       --vCodigoReferencia    := vRow.CREDITO_NUEVO;
                       vNombreArchivo := vDocumento||'_'|| vRow.CREDITO_NUEVO||'.pdf';
                       -- Generar Conozca Su Cliente para File Flow 
                       vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlConozcaSuCliente(pCodCliente => vRow.CODIGO_CLIENTE, pEmpresa => PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO);                   
                       PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( 
                                                            pCodigoReferencia   => vCodigoReferencia,
                                                            pFechaReporte       => SYSDATE,
                                                            pId_Aplicacion      => vIdAplication,
                                                            pIdTipoDocumento    => vIdTipoDocumento,
                                                            pOrigenPkm          => 'Represtamo',  
                                                            pUrlReporte         => vUrl, 
                                                            pFormatoDocumento   => 'PDF',
                                                            pNombreArchivo      => vNombreArchivo,  
                                                            pEstado             => 'P', 
                                                            pRespuesta          => pError
                                                           );            
                                
                              --DEPONENTE
                              
                              /*DECLARE
                                    vCiudad   VARCHAR2 (300) := 'Santo Domingo';
                                    vError    VARCHAR2 (4000);
                                BEGIN
                                    P_Generar_reporte_deponente (p_No_Credito       => vRow.CREDITO_NUEVO,
                                                                  p_Codigo_Cliente   => vRow.CODIGO_CLIENTE,
                                                                  p_Ciudad           => vCiudad,
                                                                  pError             => vError);
                                    EXCEPTION  WHEN OTHERS THEN
                                    pError := pError||' '||SQLERRM;     
                                    RAISE_APPLICATION_ERROR(-20105, pError);
                                    ROLLBACK;
                                 END;*/
                                 
                    vIdTipoDocumento     := '451';
                    vDocumento            := 'DEPONENTE';
                    vNombreArchivo := vDocumento||'_'|| vRow.CREDITO_NUEVO||'.pdf';           
                    vCodigoReferencia := 1||':'|| vRow.IDENTIFICACION ||':'|| vRow.CREDITO_NUEVO || ':'|| ' ' || ':'|| vDocumento || ':' ||vRow.CREDITO_ANTERIOR;
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( 
                                                    pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Represtamo',  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vNombreArchivo,   
                                                    pEstado             => 'R',
                                                    pRespuesta          => pError
                                                   );         
                     
                              
                    -- Agregando bloque   seguro de vida                                 
                    vIdTipoDocumento     := '204';
                    vDocumento            := 'SVIDA';
                    vNombreArchivo := vDocumento||'_'|| vRow.CREDITO_NUEVO||'.pdf';           
                    vCodigoReferencia := 1||':'|| vRow.IDENTIFICACION ||':'|| vRow.CREDITO_NUEVO || ':'|| ' ' || ':'|| vDocumento;-- || ':' ||vRow.CREDITO_ANTERIOR;
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( 
                                                    pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Represtamo',  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vNombreArchivo,   
                                                    pEstado             => 'R',
                                                    pRespuesta          => pError
                                                   );            
                              
                         BEGIN
                           SELECT COUNT(*) INTO vTipo_Vida FROM PR_POLIZAS_X_CREDITO WHERE TO_NUMBER(NO_CREDITO) = TO_NUMBER(vRow.CREDITO_NUEVO) AND TO_NUMBER(TIPO_POLIZA) = 2;
                         EXCEPTION WHEN NO_DATA_FOUND THEN
                           vTipo_Vida:= 0;   
                           COMMIT;
                          END;       
                                
                     IF vTipo_Vida > 0 THEN
                            vIdTipoDocumento := '851';
                            vDocumento           := 'APOLIZA'; --POLIZA SEGURO DE VIDA / ENDOSO / DESISTIMIENTO
                            vCodigoReferencia := '1:' || vRow.IDENTIFICACION || ':' || vRow.CREDITO_NUEVO || ': :' || vDocumento;
                            vNombreArchivo := vDocumento || '_' || vRow.CREDITO_NUEVO ;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Represtamo',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vNombreArchivo || '.pdf',
                                pEstado             => 'R',
                                pRespuesta          => pError); 
                         
                       END IF;         
                                                           
      
                               
                                
                          BEGIN
                            SELECT COUNT(*) INTO vTipo_Mipyme FROM PR_POLIZAS_X_CREDITO WHERE NO_CREDITO = vRow.CREDITO_NUEVO AND TIPO_POLIZA =17;
                          EXCEPTION WHEN NO_DATA_FOUND THEN
                            vTipo_Mipyme:= 0;
                        END;   
                     IF  vTipo_Mipyme > 0 THEN
                            vIdTipoDocumento := '218';
                            vDocumento           := 'SMIPYME'; --POLIZA SEGURO INCENDIO Y LINEAS ALIADAS / ENDOSO / DESESTIMIENTO
                            vCodigoReferencia := '1:' || vRow.IDENTIFICACION || ':' || vRow.CREDITO_NUEVO || ': :' || vDocumento;
                            vNombreArchivo := vDocumento || '_' || vRow.CREDITO_NUEVO ;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Represtamo',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vNombreArchivo || '.pdf',
                                pEstado             => 'R',
                                pRespuesta          => pError);                                             
                         
                        END IF;          
                       
                         BEGIN
                            SELECT COUNT(*) INTO vTipo_Desempleo FROM PR_POLIZAS_X_CREDITO WHERE TO_NUMBER(NO_CREDITO) = TO_NUMBER(vRow.CREDITO_NUEVO) AND TO_NUMBER(TIPO_POLIZA) = 24;
                         EXCEPTION WHEN NO_DATA_FOUND THEN
                           vTipo_Desempleo:= 0;   
                           COMMIT;
                          END;       
                                
                     IF vTipo_Desempleo > 0 THEN
                            vIdTipoDocumento := '882';
                            vDocumento           := 'SDESEMPLEO'; --POLIZA SEGURO DE VIDA / ENDOSO / DESISTIMIENTO
                            vCodigoReferencia := '1:' || vRow.IDENTIFICACION || ':' || vRow.CREDITO_NUEVO || ': :' || vDocumento;
                            vNombreArchivo := vDocumento || '_' || vRow.CREDITO_NUEVO  ;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Represtamo',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vNombreArchivo || '.pdf',
                                pEstado             => 'R',
                                pRespuesta          => pError); 
                         
                       END IF;      
                                                           
                    EXCEPTION WHEN OTHERS THEN 
                       pError := pError||' '||dbms_utility.format_error_backtrace;      
                       RAISE_APPLICATION_ERROR(-20105, pError);
                    END;
                
                    COMMIT;
                END IF;
            ELSE
                pError := 'La FEC ya ha sido generada anteriormente ID:'||vIdTemfec;
            END IF;
            
            pError := 'FEC creada';
            
            --Registra Bit¿cora
            --PR_PKG_REPRESTAMOS.p_generar_bitacora ( pNum_Represtamo, NULL, vRow.ESTADO, NULL, ',FUD y FEC creada', nvl(sys_context('APEX$SESSION','APP_USER'),USER));                    
            PR_PKG_REPRESTAMOS.p_generar_bitacora ( pNum_Represtamo, NULL, 'CFF', NULL, ',FUD y FEC creada', nvl(sys_context('APEX$SESSION','APP_USER'),USER));                    
            
            
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('pNum_Represtamo',        pNum_Represtamo);
          IA.LOGGER.ADDPARAMVALUEV('pCOD_AGENCIA',           pCOD_AGENCIA);
          IA.LOGGER.ADDPARAMVALUEV('pCOD_OFICIAL',           pCOD_OFICIAL);  
          IA.LOGGER.ADDPARAMVALUEV('pCODIGO_ACTIVIDAD',      pCODIGO_ACTIVIDAD); 
          IA.LOGGER.ADDPARAMVALUEV('pMARGEN_BRUTO_STD',      pMARGEN_BRUTO_STD); 
          IA.LOGGER.ADDPARAMVALUEV('pGASTOS_OPERATIVOS_STD', pGASTOS_OPERATIVOS_STD); 
          IA.LOGGER.ADDPARAMVALUEV('pVENTAS_MENSUAL',        pVENTAS_MENSUAL); 
          IA.LOGGER.ADDPARAMVALUEV('pCOSTO_VENTAS',          pCOSTO_VENTAS); 
          IA.LOGGER.ADDPARAMVALUEV('pGASTOS_OPERATIVO',      pGASTOS_OPERATIVO); 
          IA.LOGGER.ADDPARAMVALUEV('pOTROS_INGRESOS',        pOTROS_INGRESOS); 
          IA.LOGGER.ADDPARAMVALUEV('pGASTOS_FAMILIARES',     pGASTOS_FAMILIARES); 
          IA.LOGGER.ADDPARAMVALUEV('pEXCEDENTE_FAMILIAR',    pEXCEDENTE_FAMILIAR); 
          IA.LOGGER.ADDPARAMVALUEV('pREL_CUOTA_EXCED_FAM',   pREL_CUOTA_EXCED_FAM); 
          
          setError(pProgramUnit => 'p_Procesa_Fec', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END; 
    END;

    PROCEDURE setError(pProgramUnit        IN     VARCHAR2,
                       pPieceCodeName      IN     VARCHAR2,
                       pErrorDescription   IN     VARCHAR2,
                       pErrorTrace         IN     CLOB,
                       pEmailNotification  IN     VARCHAR2,
                       pParamList          IN     ia.logger.TPARAMLIST,
                       pOutputLogger       IN     BOOLEAN,
                       pExecutionTime      IN     NUMBER,
                       pIdError              OUT NUMBER) IS
      pPackageName CONSTANT IA.LOG_ERROR.PACKAGENAME%TYPE := 'PR_PKG_REPRESTAMOS';
   BEGIN
      IA.LOGGER.LOG(INOWNER => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 
                    Inpackagename =>        pPackageName, 
                    Inprogramunit =>        pProgramUnit, 
                    Inpiececodename =>      pPieceCodeName, 
                    inErrorDescription =>   pErrorDescription, 
                    inErrorTrace =>         pErrorTrace, 
                    inEmailNotification =>  pEmailNotification, 
                    inParamList =>          NVL(pParamList, IA.LOGGER.VPARAMLIST), 
                    inOutputLogger =>       pOutputLogger, 
                    inExecutionTime =>      pExecutionTime, 
                    outIdError =>           pIdError);

       IF IA.LOGGER.VPARAMLIST.COUNT > 0 THEN
            IA.LOGGER.VPARAMLIST.DELETE;
       END IF;                     
   END setError;
   ---
   PROCEDURE P_JOB_CREA_CREDITO_S IS
     CURSOR cur_represtamos_x_procesar IS
        SELECT id_represtamo, codigo_empresa
        FROM PR_REPRESTAMOS
        WHERE CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
        AND ESTADO = 'SC';
        pPeriodicidad     VARCHAR2 (5) := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PERIODICIDAD_CUOTA');  --DEFAULT MENSUAL
        pNuevo_credito    NUMBER;                                           ---Out
        pError            VARCHAR2 (1000);
    BEGIN
       FOR a in cur_represtamos_x_procesar LOOP
         PR_PKG_REPRESTAMOS.P_Procesa_Credito (a.Codigo_Empresa,
                                               a.id_represtamo,
                                               pPeriodicidad, --- (2) := '05'; ---In
                                               pNuevo_credito,               ---Out
                                               pError);
         COMMIT;
       END LOOP;
       DBMS_OUTPUT.PUT_LINE ( 'pPeriodicidad = ' || pPeriodicidad );
       
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          setError(pProgramUnit => 'P_JOB_CREA_CREDITO_S', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;    
    END; 
  PROCEDURE P_JOB_CREA_CREDITO IS
     CURSOR cur_represtamos_x_procesar IS
        SELECT R.id_represtamo, R.codigo_empresa,O.MTO_PRESTAMO,R.CODIGO_CLIENTE,R.ESTADO
        FROM PR_REPRESTAMOS R
        LEFT JOIN PR_OPCIONES_REPRESTAMO O ON O.ID_REPRESTAMO = R.ID_REPRESTAMO
        WHERE R.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
        AND R.ESTADO = 'SC';
        pPeriodicidad     VARCHAR2 (5) := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('PERIODICIDAD_CUOTA');  --DEFAULT MENSUAL
        pNuevo_credito    NUMBER;                                           ---Out
        pError            VARCHAR2 (1000);
        V_NO_CREDITO        NUMBER;
    BEGIN
       FOR a in cur_represtamos_x_procesar LOOP
         PR_PKG_REPRESTAMOS.P_Procesa_Credito_Cancelado (a.Codigo_Empresa,
                                               a.id_represtamo,
                                               pPeriodicidad, --- (2) := '05'; ---In
                                               a.MTO_PRESTAMO,
                                               pNuevo_credito,
                                               A.CODIGO_CLIENTE,        ---Out
                                               pError);
         COMMIT;
         SELECT NO_CREDITO INTO V_NO_CREDITO  FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO = A.ID_REPRESTAMO;
         
         IF V_NO_CREDITO IS NOT NULL  AND A.ESTADO  IN ('SC') THEN
            UPDATE PR.PR_REPRESTAMOS SET ESTADO = 'CRS' WHERE ID_REPRESTAMO = A.ID_REPRESTAMO;
            
          END IF;
       END LOOP;
       DBMS_OUTPUT.PUT_LINE ( 'pPeriodicidad = ' || pPeriodicidad );
       
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          setError(pProgramUnit => 'P_JOB_CREA_CREDITO', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
    END; 
    
 PROCEDURE P_JOB_CREA_ACTUALIZA_CORE IS
    
      CURSOR c_creditos IS
      SELECT NO_CREDITO, TIPO_CREDITO, MONTO_CREDITO, PLAZO_SEGUN_UNIDAD, ESTADO
      FROM PR_CREDITOS
      WHERE FECHA_MODIFICACION >= SYSDATE - (5/(24*60));


      VNO_CREDTIO    NUMBER;
      VTIPO_CREDITO  NUMBER;
      VMONTO         NUMBER;
      VPLAZO         NUMBER;
      MONTO_A_PAGAR_17  NUMBER;
      MONTO_A_PAGAR_24  NUMBER;
      MTO_SEGURO_DESEMPLEO NUMBER;
      MTO_SEGURO_MIPYME  NUMBER;
      ID_REPRESTAMO  NUMBER;
      PMENSAJEERROR VARCHAR2(400);
  BEGIN    
      FOR A IN C_CREDITOS LOOP
      
        SELECT S.NO_CREDITO,S.TIPO_CREDITO,O.MTO_PRESTAMO,S.PLAZO,O.MTO_SEGURO_DESEMPLEO,O.MTO_SEGURO_MIPYME,S.ID_REPRESTAMO
        INTO VNO_CREDTIO,VTIPO_CREDITO,VMONTO,VPLAZO,MTO_SEGURO_DESEMPLEO,MTO_SEGURO_MIPYME,ID_REPRESTAMO 
        FROM PR_SOLICITUD_REPRESTAMO S 
        LEFT JOIN PR_OPCIONES_REPRESTAMO O ON O.ID_REPRESTAMO = S.ID_REPRESTAMO WHERE S.NO_CREDITO = A.NO_CREDITO;
        
        
         BEGIN
            SELECT MONTO_A_PAGAR  INTO MONTO_A_PAGAR_17 FROM PR_POLIZAS_X_CREDITO WHERE NO_CREDITO = A.NO_CREDITO AND TIPO_POLIZA =17;
         EXCEPTION WHEN NO_DATA_FOUND THEN
                  MONTO_A_PAGAR_17:= 0;
        END;
      --DBMS_OUTPUT.PUT_LINE ( 'MONTO_A_PAGAR_17 = ' || MONTO_A_PAGAR_17 );
         BEGIN
        SELECT MONTO_A_PAGAR  INTO MONTO_A_PAGAR_24 FROM PR_POLIZAS_X_CREDITO WHERE NO_CREDITO =  A.NO_CREDITO AND TIPO_POLIZA =24;
         EXCEPTION WHEN NO_DATA_FOUND THEN
                  MONTO_A_PAGAR_24:= 0;
        END; 
        --DBMS_OUTPUT.PUT_LINE ( 'MONTO_A_PAGAR_24 = ' || MONTO_A_PAGAR_24 );
        
       IF  A.ESTADO = 'N' THEN
       UPDATE PR.PR_REPRESTAMOS R SET R.ESTADO = 'CRN' WHERE R.ID_REPRESTAMO = ID_REPRESTAMO;
       END IF;
     -- DBMS_OUTPUT.PUT_LINE ( 'A.ESTADO = ' || A.ESTADO );
      
      
        IF A.TIPO_CREDITO != VTIPO_CREDITO OR A.MONTO_CREDITO != VMONTO OR A.PLAZO_SEGUN_UNIDAD != VPLAZO OR MONTO_A_PAGAR_17 != MTO_SEGURO_MIPYME OR MONTO_A_PAGAR_24 != MTO_SEGURO_DESEMPLEO   THEN
         --DBMS_OUTPUT.PUT_LINE ( 'Entro ' );
         PR.PR_PKG_REPRESTAMOS.P_ACTUALIZAR_OPCION_FRONT ( A.NO_CREDITO, A.TIPO_CREDITO, A.MONTO_CREDITO, A.PLAZO_SEGUN_UNIDAD, PMENSAJEERROR );
         --DBMS_OUTPUT.PUT_LINE ( 'PMENSAJEERROR = ' || PMENSAJEERROR );
         END IF;
         
      END LOOP;
  


      EXCEPTION WHEN OTHERS THEN   
       DECLARE
       vIdError      PLS_INTEGER := 0;
       BEGIN                                    
                  
          setError(pProgramUnit => 'P_JOB_CREA_ACTUALIZA_CORE', 
          pPieceCodeName => NULL, 
          pErrorDescription => SQLERRM ,                                                              
          pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
          pEmailNotification => NULL, 
          pParamList => IA.LOGGER.vPARAMLIST, 
          pOutputLogger => FALSE, 
          pExecutionTime => NULL, 
          pIdError => vIdError); 
         END; 
      
    
    END P_JOB_CREA_ACTUALIZA_CORE;

 PROCEDURE P_CARGA_DE08(PFECHAREGULATORIA IN DATE) IS
 CURSOR CARGADE08 IS 
 SELECT IDDEUDOR, FECHACORTE,NOMBRES,CLASIFICACION,CALIFICACION FROM PR.DE08_TEMPORAL;
 --TYPE TCARGADE08 IS TABLE OF CARGADE08%ROWTYPE;
    BEGIN
    
        FOR A IN CARGADE08 LOOP 
            
            INSERT INTO  PA.PA_DE08_SIB(TIPO_DEUDOR, NOMBRE, ID_DEUDOR,FECHA_PROCESO, FECHA_CORTE, CLASIFICACION)
            VALUES (A.CLASIFICACION,A.NOMBRES,A.IDDEUDOR,SYSDATE,PFECHAREGULATORIA,A.CALIFICACION);
            DBMS_OUTPUT.PUT_LINE ( ' ' );
        END LOOP;
      
    DELETE FROM PR.DE08_TEMPORAL;  
        
    COMMIT;
    
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('PFECHAREGULATORIA',    PFECHAREGULATORIA);
        
          setError(pProgramUnit => 'P_CARGA_DE08', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;   
    END;

PROCEDURE P_ACTUALIZA_COMENTARIO_CAMPANA(pComentario in VARCHAR2) IS
    vUltimaFecha DATE;
BEGIN

        SELECT MAX(FECHA_ADICION)
        INTO vUltimaFecha
        FROM PR.PR_CAMPANA_ESPECIALES;
        
        UPDATE PR.PR_CAMPANA_ESPECIALES 
        SET COMENTARIO = pComentario
        WHERE FECHA_ADICION = vUltimaFecha;
END;

PROCEDURE P_CARGA_DE05(PFECHACASTIGO IN DATE) IS
CURSOR CARGADE05 IS
    SELECT CEDULA, CLIENTE, ENTIDAD FROM PR.DE05_Temporal;
 BEGIN
            FOR A IN CARGADE05 LOOP
            
                INSERT INTO PA.PA_DE05_SIB(CEDULA,FECHA_CASTIGO,NOMBRE,ENTIDAD,FECHA_PROCESO)
                VALUES (A.CEDULA, PFECHACASTIGO,A.CLIENTE,A.ENTIDAD,SYSDATE);
                
            END LOOP;
          
        DELETE FROM PR.DE05_TEMPORAL;

    COMMIT;
    
 EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
          IA.LOGGER.ADDPARAMVALUEV('PFECHACASTIGO',    PFECHACASTIGO);
        
          setError(pProgramUnit => 'P_CARGA_DE05', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;
 END;  

     PROCEDURE P_Generar_reporte_deponente(p_No_Credito       IN     NUMBER,
                                                             p_Codigo_Cliente   IN     VARCHAR2,
                                                             p_Ciudad           IN     VARCHAR2,
                                                             p_SubirFileFlow    IN     BOOLEAN DEFAULT TRUE,
                                                             pError             IN OUT VARCHAR2) IS
        vReporteBlob        BLOB;
        vReportName         VARCHAR2(100) := 'prdepone.rep';
        vConnexion          VARCHAR2(200);  
        vMasterKey          RAW(2000);
        vUsername           VARCHAR2(30) := 'ia';
        vPass               VARCHAR2(30) := 'ia';  
        
        vExtencion          VARCHAR2(10)  := 'pdf';
        vReportHost         VARCHAR2(100) := PARAM.PARAMETRO_GENERAL('WEBLOGIC_SERVER','PA');
        vNombrearchivo      VARCHAR2(256) := 'prdeponente_'|| TO_CHAR(SYSDATE, 'DD-MM-YYYY-HH-MI-SS')||'.'||vExtencion;
        vDirectorio         VARCHAR2(100) := PARAM.PARAMETRO_GENERAL('DIR_ARCHIVO_TASAS','PA');
        
        vIdAplication        PLS_INTEGER := 2;      -- Prestamos
        vIdTipoDocumento     PLS_INTEGER := '451';  -- 
        vCodigoReferencia    VARCHAR2(200);
        vDocumento           VARCHAR2(30) := 'DEPONENTE';
        vIdTemFud            VARCHAR2(30);
        vNoCreditoAnterior   VARCHAR2(30);
        
        --
        vIdentificacion      VARCHAR(30);
        
    BEGIN
        BEGIN
            -- Authentication
            vMasterKey := pa.Obt_Parametro_General_raw ('MKDB', 'PR');  
            vUsername := PA.DECIFRAR(pa.Obt_Parametro_General_raw('DBUSR', 'PR'), vMasterKey);
            vPass := PA.DECIFRAR(pa.Obt_Parametro_General_raw('DBPWD', 'PR'), vMasterKey);
                 
            -- Determina el String Connection
            SELECT vUsername||'/'||vPass||'@'||REPLACE(SYS_CONTEXT('USERENV', 'SERVICE_NAME'), '.bancoademi.local') INTO vConnexion FROM DUAL;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vConnexion := 'ia/ia@ADMQA1';
        END;
      
        -- Ejecutar el Oracle Report
        BEGIN
            PA.PKG_REPORTS.AgregaParametro ('p_ciudad', '"'||p_Ciudad||'"', FALSE);
            PA.PKG_REPORTS.AgregaParametro ('P_CODIGO_CLIENTE', p_Codigo_Cliente, FALSE);

            vReporteBlob := PA.PKG_REPORTS.GeneraReporte (pConexion       => vConnexion,
                                                          pReportHost     => vReportHost,
                                                          pReportServer   => PARAM.PARAMETRO_X_EMPRESA('1', 'REPORT_SERVER', 'PA'),
                                                          pRutaBase       => PARAM.PARAMETRO_GENERAL('RUTA_EJECUT_REPORTES','PA'),
                                                          pReporte        => vReportName,
                                                          pDesFormat      => vExtencion);
        EXCEPTION WHEN OTHERS THEN
            pError := 'Error generando el reporte '|| vReportName||' del cliente '|| p_Codigo_Cliente||' '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pError); 
        END;
        
        IF LENGTH(vReporteBlob) > 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Reporte Descargado '||LENGTH(vReporteBlob));
            -- Crear el archivo PDF
            BEGIN
                PA.PKG_REPORTS.EscribeArchivo(pblobdata => vReporteBlob, pdirectory => vDirectorio, pfilename => vNombreArchivo);
            EXCEPTION WHEN OTHERS THEN
                pError := 'Error creando el archivo '|| vNombreArchivo||' '||SQLERRM;
                RAISE_APPLICATION_ERROR(-20100, pError); 
            END;
            
            DBMS_OUTPUT.PUT_LINE('Archivo Creado '||vNombreArchivo);
            
            IF p_SubirFileFlow THEN
                -- Subir documento a FileFlow
                BEGIN
                    
                    -- Determina el Crédito anterior
                    BEGIN
                        SELECT s.NO_CREDITO_CANCELADO
                          INTO vNoCreditoAnterior
                        FROM PR.PR_CANCELACION_CREDITOS s
                        WHERE s.NO_CREDITO = p_No_Credito;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vNoCreditoAnterior := ' ';
                    END;
                    
                    -- Determina el ID Temp Fud
                    BEGIN
                        SELECT F.ID_TEMPFUD
                          INTO vIdTemFud
                          FROM PR.TEMPFUD F
                         WHERE F.NOCREDITO = p_No_Credito;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vIdTemFud := ' ';
                    END;
                    
                    
                     -- Obtener la cedula del solicitante por su credito
                     BEGIN
                        SELECT IDENTIFICACION
                        INTO vIdentificacion
                        FROM PR.PR_SOLICITUD_REPRESTAMO
                        WHERE NO_CREDITO = p_No_Credito;
                     EXCEPTION WHEN NO_DATA_FOUND THEN
                        vIdentificacion :=' ';
                     END;
                     
                    -- Carga el Reporte Automatico a FileFlow 
                    --vCodigoReferencia := p_No_Credito||':'||vNoCreditoAnterior||':'||vDocumento||':'||vIdTemFud;
                    vCodigoReferencia := 1||':'|| vIdentificacion ||':'|| p_No_Credito || ':'|| ' ' || ':'|| vDocumento || ':' ||vNoCreditoAnterior;
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( 
                                                    pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Represtamo',  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => UPPER(vExtencion),
                                                    pNombreArchivo      => vNombreArchivo,   
                                                    pEstado             => 'D',
                                                    pRespuesta          => pError
                                                   );
                
                EXCEPTION WHEN OTHERS THEN
                    pError := 'Error cargando reporte a FileFlow '|| pError||' '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20100, pError);
                END;
            
            END IF;
                                        
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
    
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('p_No_Credito',            p_No_Credito);
          IA.LOGGER.ADDPARAMVALUEV('p_Codigo_Cliente',          p_Codigo_Cliente);
          IA.LOGGER.ADDPARAMVALUEV('p_Ciudad',        p_Ciudad);   
          
          setError(pProgramUnit => 'P_Generar_reporte_deponente', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;                              
    END P_Generar_reporte_deponente;


 

--Revisar SP hecho por nolivo 09-11-2023 11:01 PM

  PROCEDURE P_Insertar_Campana(
                                p_codigoEmpresa IN NUMBER,
                                p_nombre IN VARCHAR2,
                                p_descripcion IN VARCHAR2,
                                p_estado IN VARCHAR2,
                                pError   OUT VARCHAR2)IS
            PRAGMA AUTONOMOUS_TRANSACTION;
    
            v_estadoActivo NUMBER;
            
       BEGIN
       SELECT COUNT(*) INTO v_estadoActivo FROM PR_REPRESTAMO_CAMPANA where ESTADO = 1;
                             
       
       IF p_estado = '1' AND v_estadoActivo > 0 THEN
      
           pError := 'Error - Ya existe una campaña activa ' ||SQLERRM;
           
           --Luego de pasar la validacion realizare la insercion de los datos
       ELSE
            INSERT INTO PR.PR_REPRESTAMO_CAMPANA(
                   CODIGO_EMPRESA,
                   NOMBRE,
                   DESCRIPCION,
                   ESTADO,
                   ADICIONADO_POR,
                   FECHA_ADICION,
                   MODIFICADO_POR,
                   FECHA_MODIFICACION)
             VALUES(
                    p_codigoEmpresa,
                    p_nombre,
                    p_descripcion,
                    p_estado,
                    NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),
                    SYSDATE,
                    NULL,
                    NULL);
                  pError := 'El registro se ha creado';
            COMMIT;
         END IF;
  EXCEPTION
         WHEN NO_DATA_FOUND THEN
                v_estadoActivo := 0;
                COMMIT;
    WHEN OTHERS THEN
                pError := 'Error - Ya existe una campaña activa ' ||SQLERRM;
        DECLARE
            vIdError      PLS_INTEGER := 0;
        BEGIN
                                    
          IA.LOGGER.ADDPARAMVALUEV('p_codigoEmpresa',            p_codigoEmpresa);
          IA.LOGGER.ADDPARAMVALUEV('p_nombre',          p_nombre);
          IA.LOGGER.ADDPARAMVALUEV('p_descripcion',        p_descripcion);  
          IA.LOGGER.ADDPARAMVALUEV('p_estado',        p_estado);  
          
          setError(pProgramUnit => 'P_Insertar_Campana', 
                   pPieceCodeName => NULL, 
                   pErrorDescription => SQLERRM,                                                              
                   pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                   pEmailNotification => NULL, 
                   pParamList => IA.LOGGER.vPARAMLIST, 
                   pOutputLogger => FALSE, 
                   pExecutionTime => NULL, 
                   pIdError => vIdError); 
        END;     
                ROLLBACK;   
  END P_Insertar_Campana;
  
  PROCEDURE P_Actualizar_Campana(
                                   p_codigoEmpresa IN NUMBER,
                                   p_codigoCampana IN NUMBER,
                                   p_nombre IN VARCHAR2,
                                   p_descripcion IN VARCHAR2,
                                   p_estado IN VARCHAR2,
                                   pError   OUT VARCHAR2) IS
                                   
                                   
                 PRAGMA AUTONOMOUS_TRANSACTION;
                 
                 v_estadoActivo NUMBER;
                 
        BEGIN
        
           --Selecciono la cantidad de los registros que tengan el estado en 1 o Activo
           SELECT COUNT(*) 
           INTO v_estadoActivo 
           FROM PR.PR_REPRESTAMO_CAMPANA 
           WHERE ESTADO = 1
           AND CODIGO_CAMPANA <> p_codigoCampana;
       
           --Valido que el valor del parametro sea 1 o Activo y el valor que tiene mi variable sea mayor a 0 esto dara la excepcion.
            
           IF  v_estadoActivo > 0 AND p_estado = 1 THEN
               pError := 'Error - Ya existe una campaña activa ' ||SQLERRM;
           
           --De lo contrario procedera a Actualizar el registro
           ELSE
              UPDATE PR.PR_REPRESTAMO_CAMPANA
              SET NOMBRE             = p_nombre,
                  DESCRIPCION        = p_descripcion,
                  ESTADO             = p_estado,
                  MODIFICADO_POR     = NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),
                  FECHA_MODIFICACION = SYSDATE 
               WHERE CODIGO_CAMPANA = p_codigoCampana
               AND   CODIGO_EMPRESA = p_codigoEmpresa;
              
              
               -- Si el estado es inactivo (2), también inactiva los detalles y tipos de crédito relacionados
                -- Inactivar PR_REPRESTAMO_CAMPANA_DET
                UPDATE PR.PR_REPRESTAMO_CAMPANA_DET RCD
                SET ESTADO = 2
                WHERE CODIGO_CAMPANA = p_codigoCampana
                  AND EXISTS (
                      SELECT 1
                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO TCR
                      WHERE TCR.TIPO_CREDITO = RCD.TIPO_CREDITO_DESTINO
                        AND TCR.CREDITO_CAMPANA_ESPECIAL = 'S'
                  );

                -- Inactivar PR_TIPO_CREDITO_REPRESTAMO
                UPDATE PR.PR_TIPO_CREDITO_REPRESTAMO TCR
                SET ESTADO = 'I'
                WHERE TCR.CREDITO_CAMPANA_ESPECIAL = 'S'
                  AND EXISTS (
                      SELECT 1
                      FROM PR.PR_REPRESTAMO_CAMPANA_DET RCD
                      WHERE RCD.CODIGO_CAMPANA = p_codigoCampana
                        AND RCD.TIPO_CREDITO_DESTINO = TCR.TIPO_CREDITO
                  );                                 
              COMMIT;
                  pError := 'El registro ha sido Actualizado';
           END IF;
               
        EXCEPTION
            WHEN OTHERS THEN
                
                pError := 'Error - ' ||SQLERRM;
                
           DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
                                        
              IA.LOGGER.ADDPARAMVALUEV('p_codigoEmpresa',            p_codigoEmpresa);
              IA.LOGGER.ADDPARAMVALUEV('p_codigoCampana',            p_codigoCampana);
              IA.LOGGER.ADDPARAMVALUEV('p_nombre',          p_nombre);
              IA.LOGGER.ADDPARAMVALUEV('p_descripcion',        p_descripcion);  
              IA.LOGGER.ADDPARAMVALUEV('p_estado',        p_estado);  
              
              setError(pProgramUnit => 'P_Actualizar_Campana', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END; 
        
        ROLLBACK;     
           
       END P_Actualizar_Campana;
       
       PROCEDURE P_Inactivar_Campana 
        AS
             PRAGMA AUTONOMOUS_TRANSACTION;
             
             vError VARCHAR2(100);
              
         BEGIN 
              UPDATE PR.PR_REPRESTAMO_CAMPANA 
              SET ESTADO = 2,
                  MODIFICADO_POR     = NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER),
                  FECHA_MODIFICACION = SYSDATE
              WHERE  CODIGO_EMPRESA = 1;
              
              vError := 'Todas las campañas estan inactivas!';
              
              COMMIT;
       EXCEPTION
       
            WHEN OTHERS THEN
                vError := 'Error - ' ||SQLERRM;
                DECLARE
                vIdError      PLS_INTEGER := 0;
            BEGIN
              setError(pProgramUnit => 'P_Inactivar_Campana', 
                       pPieceCodeName => NULL, 
                       pErrorDescription => SQLERRM,                                                              
                       pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                       pEmailNotification => NULL, 
                       pParamList => IA.LOGGER.vPARAMLIST, 
                       pOutputLogger => FALSE, 
                       pExecutionTime => NULL, 
                       pIdError => vIdError); 
            END; 
                ROLLBACK;
       END P_Inactivar_Campana;
      PROCEDURE P_CARGAR_DATOS_FUD_ANTERIOR(
                    p_id_represtamo IN VARCHAR2,
                    p_tipo_documento_identidad OUT VARCHAR2,
                    p_num_documento_identidad OUT VARCHAR2,
                    p_apodo OUT VARCHAR2,
                    p_id_agencia OUT VARCHAR2,
                    p_sexo OUT VARCHAR2,
                    p_fecha_nacimiento OUT VARCHAR2,
                    p_id_empleado OUT VARCHAR2,
                    p_id_pais OUT VARCHAR2,
                    p_id_provincia OUT VARCHAR2,
                    p_id_municipio OUT VARCHAR2,
                    p_id_distrito OUT VARCHAR2,
                    p_id_estado_civil OUT VARCHAR2,
                    p_nombre_vinculado OUT VARCHAR2,
                    p_direccion OUT VARCHAR2,
                    p_direccion_idsector OUT VARCHAR2,
                    p_direccion_idprovincia OUT VARCHAR2,
                    p_direccion_distrito OUT VARCHAR2,
                    p_ref_domicilio OUT VARCHAR2,
                    p_tipo_persona OUT VARCHAR2,
                    p_reside_mes OUT VARCHAR2,
                    p_reside_ano OUT VARCHAR2,
                    p_telefono_casa OUT VARCHAR2,
                    p_telefono_celular OUT VARCHAR2,
                    p_nombre_negocio OUT VARCHAR2,
                    p_rnc OUT VARCHAR2,
                    p_fax OUT VARCHAR2,
                    p_email OUT VARCHAR2,
                    p_inicio_mes OUT VARCHAR2,
                    p_inicio_ano OUT VARCHAR2,
                    p_lugar_trabajo OUT VARCHAR2,
                    p_fecha_ingreso OUT VARCHAR2,
                    p_cargo OUT VARCHAR2,
                    p_trabajo_direccion OUT VARCHAR2,
                    p_trabajo_idprovincia OUT VARCHAR2,
                    p_trabajo_idmunicipio OUT VARCHAR2,
                    p_trabajo_iddistrito OUT VARCHAR2,
                    p_punto_referencia OUT VARCHAR2,
                    p_telefono OUT VARCHAR2,
                    p_codigo_proyecto OUT VARCHAR2,
                    p_especifique_destino OUT VARCHAR2,
                    p_tasa_cal OUT VARCHAR2,
                    p_id_tipo_vinculado OUT VARCHAR2,
                    p_refpersonales_apellidos OUT VARCHAR2,
                    p_refpersonales_nombres OUT VARCHAR2,
                    p_refpers_relfamiliar OUT VARCHAR2,
                    p_refpersonales_nombres2 OUT VARCHAR2,
                    p_refpersonales_apellidos2 OUT VARCHAR2,
                    p_refpers_relfamiliar2 OUT VARCHAR2,
                    p_numdocumentoidentidadco OUT VARCHAR2,
                    p_primernombreco OUT VARCHAR2,
                    p_segundonombreco OUT VARCHAR2,
                    p_primerapellidoco OUT VARCHAR2,
                    p_segundoapellidoco OUT VARCHAR2,
                    p_fechanacimientoco OUT VARCHAR2,
                    p_apodoco OUT VARCHAR2,
                    p_idpaisco OUT VARCHAR2,
                    p_idprovinciaco OUT VARCHAR2,
                    p_idmunicipioco OUT VARCHAR2,
                    p_iddistritoco OUT VARCHAR2,
                    p_nombrevinculadoco OUT VARCHAR2,
                    p_idtipovinculadoco OUT VARCHAR2,
                    p_nombre_negocioco OUT VARCHAR2,
                    p_rncco OUT VARCHAR2,
                    p_faxco OUT VARCHAR2,
                    p_emailco OUT VARCHAR2,
                    p_actividad_ciiuco OUT VARCHAR2,
                    p_inicio_mes_co OUT VARCHAR2,
                    p_inicio_ano_co OUT VARCHAR2,
                    p_lugar_trabajoco OUT VARCHAR2,
                    p_fecha_ingresoco OUT VARCHAR2,
                    p_trabajo_direccionco OUT VARCHAR2,
                    p_trabajo_idsectorco OUT VARCHAR2,
                    p_trabajo_idprovinciaco OUT VARCHAR2,
                    p_trabajo_idmunicipioco OUT VARCHAR2,
                    p_trabajo_iddistritoco OUT VARCHAR2,
                    p_punto_referenciaco OUT VARCHAR2,
                    p_cargoco OUT VARCHAR2,
                    p_plazocal OUT VARCHAR2,
                    p_frecuencia_cal OUT VARCHAR2,
                    p_gradoint OUT VARCHAR2,
                    p_idocupacion OUT VARCHAR2,
                    p_idvinculado OUT VARCHAR2,
                    p_actividad_ciiu OUT VARCHAR2,
                    p_trabajo_idsector OUT VARCHAR2,
                    p_nombres OUT VARCHAR2,
                    p_apellidos OUT VARCHAR2,
                    p_primernombre OUT VARCHAR2,
                    p_segundonombre OUT VARCHAR2,
                    p_primerapellido OUT VARCHAR2,
                    p_segundoapellido OUT VARCHAR2,
                    p_desc_provincia OUT VARCHAR2,
                    p_desc_distrito OUT VARCHAR2,
                    p_desc_ciudad OUT VARCHAR2,
                    p_desc_provincia_dom OUT VARCHAR2,
                    p_desc_distrito_dom OUT VARCHAR2,
                    p_desc_ciudad_dom OUT VARCHAR2,
                    p_trabajo_desc_provincia OUT VARCHAR2,
                    p_trabajo_desc_distrito OUT VARCHAR2,
                    p_trabajo_desc_ciudad OUT VARCHAR2,
                    p_id_tempfud OUT VARCHAR2,
                    p_nomarchivo OUT VARCHAR2,
                    p_monto_solicitado OUT VARCHAR2
    )AS
   
  BEGIN
    BEGIN
        SELECT NVL(T.TIPODOCUMENTOIDENTIDAD, ''),
               NVL(T.NUMDOCUMENTOIDENTIDAD, ''),
               NVL(T.APODO, '') AS APODO,
               NVL(T.IDAGENCIA, NULL),
               NVL(T.SEXO, '') AS SEXO,
               NVL(T.FECHANACIMIENTO, NULL),
               NVL(T.IDEMPLEADO, ''),
               NVL(T.IDPAIS, '') ,
               NVL(T.IDPROVINCIA, '') ,
               NVL(T.IDMUNICIPIO, '') ,
               NVL(T.IDDISTRITO, '') ,
               NVL(T.IDESTADOCIVIL, '') ,
               NVL(T.NOMBREVINCULADO, '')  ,
               NVL(T.DIRECCION, '')  ,
               NVL(T.DIRECCION_IDSECTOR, '')  ,
               NVL(T.DIRECCION_IDPROVINCIA, '')  ,
               NVL(T.DIRECCION_DISTRITO, '')  ,
               NVL(T.REF_DOMICILIO, '')  ,
               NVL(T.TIPOPERSONA, '')  ,
               NVL(T.RESIDE_MES, '')  ,
               NVL(T.RESIDE_ANO, '')  ,
               NVL(T.TELEFONO_CASA, '')  ,
               NVL(T.TELEFONO_CELULAR, '')  ,
               NVL(T.NOMBRENEGOCIO, '')  ,
               NVL(T.RNC, '')  ,
               NVL(T.FAX, '')  ,
               NVL(T.EMAIL, '')  ,
               NVL(T.INICIO_MES, '')  ,
               NVL(T.INICIO_ANO, '')  ,
               NVL(T.LUGARTRABAJO, '')  ,
               NVL(T.FECHAINGRESO, '')  ,
               NVL(T.CARGO, '')  ,
               NVL(T.TRABAJO_DIRECCION, '')  ,
               NVL(T.TRABAJO_IDPROVINCIA, '')  ,
               NVL(T.TRABAJO_IDMUNICIPIO, '')  ,
               NVL(T.TRABAJO_IDDISTRITO, '')  ,
               NVL(T.PUNTOREFERENCIA, '')  ,
               NVL(T.TELEFONO, '')  ,
               NVL(T.CODIGOPROYECTO, '')  ,
               NVL(T.ESPECIFIQUEDESTINO, '')  ,
               NVL(T.TASACAL, '')  ,
               NVL(T.IDTIPOVINCULADO, '')  ,
               NVL(T.REFPERSONALES_APELLIDOS, '')  ,
               NVL(T.REFPERSONALES_NOMBRES, '')  ,
               NVL(T.REFPERS_RELFAMILIAR, '')  ,
               NVL(T.REFPERSONALES_NOMBRES2, '')  ,
               NVL(T.REFPERSONALES_APELLIDOS2, '')  ,
               NVL(T.REFPERS_RELFAMILIAR2, '')  ,
               NVL(T.NUMDOCUMENTOIDENTIDADCO, '')  ,
               NVL(T.PRIMERNOMBRECO, '')  ,
               NVL(T.SEGUNDONOMBRECO, '')  ,
               NVL(T.PRIMERAPELLIDOCO, '')  ,
               NVL(T.SEGUNDOAPELLIDOCO, '')  ,
               NVL(T.FECHANACIMIENTOCO, '')  ,
               NVL(T.APODOCO, '')  ,
               NVL(T.IDPAISCO, '')  ,
               NVL(T.IDPROVINCIACO, '')  ,
               NVL(T.IDMUNICIPIOCO, '')  ,
               NVL(T.IDDISTRITOCO, '')  ,
               NVL(T.NOMBREVINCULADOCO, '')  ,
               NVL(T.IDTIPOVINCULADOCO, '')  ,
               NVL(T.NOMBRENEGOCIOCO, '')  ,
               NVL(T.RNCCO, '')  ,
               NVL(T.FAXCO, '')  ,
               NVL(T.EMAILCO, '')  ,
               NVL(T.ACTIVIDAD_CIIUCO, '')  ,
               NVL(T.INICIO_MESCO, '')  ,
               NVL(T.INICIO_ANOCO, '') , 
               NVL(T.LUGARTRABAJOCO, '') ,
               NVL(T.FECHAINGRESOCO, '')  ,
               NVL(T.TRABAJO_DIRECCIONCO, '') ,
               NVL(T.TRABAJO_IDSECTORCO, '') ,
               NVL(T.TRABAJO_IDPROVINCIACO, '') ,
               NVL(T.TRABAJO_IDMUNICIPIOCO, '') ,
               NVL(T.TRABAJO_IDDISTRITOCO, '') ,
               NVL(T.PUNTOREFERENCIACO, '') ,
               NVL(T.CARGOCO, '') ,
               NVL(T.PLAZOCAL, '') ,
               NVL(T.FRECUENCIACAL, '') ,
               NVL(T.GRADOINT, '') ,
               NVL(T.IDOCUPACION, '') ,
               NVL(T.IDVINCULADO, '') ,
               NVL(T.ACTIVIDAD_CIIU, '') ,
               NVL(T.TRABAJO_IDSECTOR, '') ,
               NVL(T.NOMBRES, '') ,
               NVL(T.APELLIDOS, '') ,
               NVL(T.PRIMERNOMBRE, ''),
               NVL(T.SEGUNDONOMBRE, '') ,
               NVL(T.PRIMERAPELLIDO, '') ,
               NVL(T.SEGUNDOAPELLIDO, '') ,
               NVL(T.DESC_PROVINCIA, ''),
               NVL(T.DESC_DISTRITO, '') ,
               NVL(T.DESC_CIUDAD, '') ,
               NVL(T.DESC_PROVINCIA_DOM, '') ,
               NVL(T.DESC_DISTRITO_DOM, '') ,
               NVL(T.DESC_CIUDAD_DOM, '') ,
               NVL(T.TRABAJO_DESC_PROVINCIA, '') ,
               NVL(T.TRABAJO_DESC_DISTRITO, '') ,
               NVL(T.TRABAJO_DESC_CIUDAD, '') ,
               NVL(T.ID_TEMPFUD, '') ,
               NVL(T.NOMARCHIVO, '') ,
               NVL(T.MONTOSOLICITADO, '')
          INTO  p_tipo_documento_identidad,
                 p_num_documento_identidad,
                 p_apodo,
                 p_id_agencia,
                 p_sexo,
                 p_fecha_nacimiento,
                 p_id_empleado,
                 p_id_pais,
                 p_id_provincia,
                 p_id_municipio ,
                    p_id_distrito ,
                    p_id_estado_civil ,
                    p_nombre_vinculado ,
                    p_direccion ,
                    p_direccion_idsector ,
                    p_direccion_idprovincia ,
                    p_direccion_distrito ,
                    p_ref_domicilio ,
                    p_tipo_persona ,
                    p_reside_mes ,
                    p_reside_ano ,
                    p_telefono_casa ,
                    p_telefono_celular ,
                    p_nombre_negocio ,
                    p_rnc ,
                    p_fax ,
                    p_email ,
                    p_inicio_mes ,
                    p_inicio_ano ,
                    p_lugar_trabajo ,
                    p_fecha_ingreso ,
                    p_cargo ,
                    p_trabajo_direccion ,
                    p_trabajo_idprovincia ,
                    p_trabajo_idmunicipio ,
                    p_trabajo_iddistrito ,
                    p_punto_referencia ,
                    p_telefono ,
                    p_codigo_proyecto ,
                    p_especifique_destino ,
                    p_tasa_cal ,
                    p_id_tipo_vinculado ,
                    p_refpersonales_apellidos ,
                    p_refpersonales_nombres ,
                    p_refpers_relfamiliar ,
                    p_refpersonales_nombres2 ,
                    p_refpersonales_apellidos2 ,
                    p_refpers_relfamiliar2 ,
                    p_numdocumentoidentidadco ,
                    p_primernombreco ,
                    p_segundonombreco ,
                    p_primerapellidoco ,
                    p_segundoapellidoco ,
                    p_fechanacimientoco ,
                    p_apodoco ,
                    p_idpaisco ,
                    p_idprovinciaco ,
                    p_idmunicipioco ,
                    p_iddistritoco ,
                    p_nombrevinculadoco ,
                    p_idtipovinculadoco ,
                    p_nombre_negocioco ,
                    p_rncco ,
                    p_faxco ,
                    p_emailco ,
                    p_actividad_ciiuco ,
                    p_inicio_mes_co ,
                    p_inicio_ano_co ,
                    p_lugar_trabajoco ,
                    p_fecha_ingresoco ,
                    p_trabajo_direccionco ,
                    p_trabajo_idsectorco ,
                    p_trabajo_idprovinciaco ,
                    p_trabajo_idmunicipioco ,
                    p_trabajo_iddistritoco ,
                    p_punto_referenciaco ,
                    p_cargoco ,
                    p_plazocal ,
                    p_frecuencia_cal ,
                    p_gradoint ,
                    p_idocupacion ,
                    p_idvinculado ,
                    p_actividad_ciiu ,
                    p_trabajo_idsector ,
                    p_nombres ,
                    p_apellidos ,
                    p_primernombre ,
                    p_segundonombre ,
                    p_primerapellido ,
                    p_segundoapellido ,
                    p_desc_provincia ,
                    p_desc_distrito ,
                    p_desc_ciudad ,
                    p_desc_provincia_dom ,
                    p_desc_distrito_dom ,
                    p_desc_ciudad_dom ,
                    p_trabajo_desc_provincia ,
                    p_trabajo_desc_distrito ,
                    p_trabajo_desc_ciudad ,
                    p_id_tempfud ,
                    p_nomarchivo ,
                    p_monto_solicitado
        FROM PR.PR_SOLICITUD_REPRESTAMO S
        LEFT JOIN PR.PR_REPRESTAMOS R ON R.ID_REPRESTAMO = S.ID_REPRESTAMO
        LEFT JOIN PR.TEMPFUD F ON F.NOCREDITO = R.NO_CREDITO
        LEFT JOIN PR.TEMPFUD_V T ON T.ID_TEMPFUD = F.ID_TEMPFUD
        WHERE S.ID_REPRESTAMO = p_id_represtamo; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  
            p_tipo_documento_identidad := '';
            p_num_documento_identidad := '';
            p_apodo := '';
            p_id_agencia := NULL;
            p_sexo := '';
            p_fecha_nacimiento := NULL;
            p_id_empleado := '';
            p_id_pais := '';
            p_id_provincia := '';
            p_id_municipio  :='';
                    p_id_distrito  :='';
                    p_id_estado_civil  :='';
                    p_nombre_vinculado  :='';
                    p_direccion  :='';
                    p_direccion_idsector  :='';
                    p_direccion_idprovincia  :='';
                    p_direccion_distrito  :='';
                    p_ref_domicilio  :='';
                    p_tipo_persona  :='';
                    p_reside_mes  :='';
                    p_reside_ano  :='';
                    p_telefono_casa  :='';
                    p_telefono_celular  :='';
                    p_nombre_negocio  :='';
                    p_rnc  :='';
                    p_fax  :='';
                    p_email  :='';
                    p_inicio_mes  :='';
                    p_inicio_ano  :='';
                    p_lugar_trabajo  :='';
                    p_fecha_ingreso  :=NULL;
                    p_cargo  :='';
                    p_trabajo_direccion  :='';
                    p_trabajo_idprovincia  :='';
                    p_trabajo_idmunicipio  :='';
                    p_trabajo_iddistrito  :='';
                    p_punto_referencia  :='';
                    p_telefono  :='';
                    p_codigo_proyecto  :='';
                    p_especifique_destino  :='';
                    p_tasa_cal  :='';
                    p_id_tipo_vinculado  :='';
                    p_refpersonales_apellidos  :='';
                    p_refpersonales_nombres  :='';
                    p_refpers_relfamiliar  :='';
                    p_refpersonales_nombres2  :='';
                    p_refpersonales_apellidos2  :='';
                    p_refpers_relfamiliar2  :='';
                    p_numdocumentoidentidadco  :='';
                    p_primernombreco  :='';
                    p_segundonombreco  :='';
                    p_primerapellidoco  :='';
                    p_segundoapellidoco  :='';
                    p_fechanacimientoco  :=NULL;
                    p_apodoco  :='';
                    p_idpaisco  :='';
                    p_idprovinciaco  :='';
                    p_idmunicipioco  :='';
                    p_iddistritoco  :='';
                    p_nombrevinculadoco  :='';
                    p_idtipovinculadoco  :='';
                    p_nombre_negocioco  :='';
                    p_rncco  :='';
                    p_faxco  :='';
                    p_emailco  :='';
                    p_actividad_ciiuco  :='';
                    p_inicio_mes_co  :='';
                    p_inicio_ano_co  :='';
                    p_lugar_trabajoco  :='';
                    p_fecha_ingresoco  :=NULL;
                    p_trabajo_direccionco  :='';
                    p_trabajo_idsectorco  :='';
                    p_trabajo_idprovinciaco  :='';
                    p_trabajo_idmunicipioco  :='';
                    p_trabajo_iddistritoco  :='';
                    p_punto_referenciaco  :='';
                    p_cargoco  :='';
                    p_plazocal  :='';
                    p_frecuencia_cal  :='';
                    p_gradoint  :='';
                    p_idocupacion  :='';
                    p_idvinculado  :='';
                    p_actividad_ciiu  :='';
                    p_trabajo_idsector  :='';
                    p_nombres  :='';
                    p_apellidos  :='';
                    p_primernombre  :='';
                    p_segundonombre  :='';
                    p_primerapellido  :='';
                    p_segundoapellido  :='';
                    p_desc_provincia  :='';
                    p_desc_distrito  :='';
                    p_desc_ciudad  :='';
                    p_desc_provincia_dom  :='';
                    p_desc_distrito_dom  :='';
                    p_desc_ciudad_dom  :='';
                    p_trabajo_desc_provincia  :='';
                    p_trabajo_desc_distrito  :='';
                    p_trabajo_desc_ciudad  :='';
                    p_id_tempfud  :='';
                    p_nomarchivo  :='';
                    p_monto_solicitado  :='';
    END;
  
  END  P_CARGAR_DATOS_FUD_ANTERIOR; 
  
  PROCEDURE P_CARGAR_DATOS_FUD_NUEVO(
                    p_id_represtamo IN VARCHAR2,
                    p_tipo_documento_identidad OUT VARCHAR2,
                    p_num_documento_identidad OUT VARCHAR2,
                    p_apodo OUT VARCHAR2,
                    p_id_agencia OUT VARCHAR2,
                    p_sexo OUT VARCHAR2,
                    p_fecha_nacimiento OUT VARCHAR2,
                    p_id_empleado OUT VARCHAR2,
                    p_id_pais OUT VARCHAR2,
                    p_id_provincia OUT VARCHAR2,
                    p_id_municipio OUT VARCHAR2,
                    p_id_distrito OUT VARCHAR2,
                    p_id_estado_civil OUT VARCHAR2,
                    p_nombre_vinculado OUT VARCHAR2,
                    p_direccion OUT VARCHAR2,
                    p_direccion_idsector OUT VARCHAR2,
                    p_direccion_idprovincia OUT VARCHAR2,
                    p_direccion_distrito OUT VARCHAR2,
                    p_ref_domicilio OUT VARCHAR2,
                    p_tipo_persona OUT VARCHAR2,
                    p_reside_mes OUT VARCHAR2,
                    p_reside_ano OUT VARCHAR2,
                    p_telefono_casa OUT VARCHAR2,
                    p_telefono_celular OUT VARCHAR2,
                    p_nombre_negocio OUT VARCHAR2,
                    p_rnc OUT VARCHAR2,
                    p_fax OUT VARCHAR2,
                    p_email OUT VARCHAR2,
                    p_inicio_mes OUT VARCHAR2,
                    p_inicio_ano OUT VARCHAR2,
                    p_lugar_trabajo OUT VARCHAR2,
                    p_fecha_ingreso OUT VARCHAR2,
                    p_cargo OUT VARCHAR2,
                    p_trabajo_direccion OUT VARCHAR2,
                    p_trabajo_idprovincia OUT VARCHAR2,
                    p_trabajo_idmunicipio OUT VARCHAR2,
                    p_trabajo_iddistrito OUT VARCHAR2,
                    p_punto_referencia OUT VARCHAR2,
                    p_telefono OUT VARCHAR2,
                    p_codigo_proyecto OUT VARCHAR2,
                    p_especifique_destino OUT VARCHAR2,
                    p_tasa_cal OUT VARCHAR2,
                    p_id_tipo_vinculado OUT VARCHAR2,
                    p_refpersonales_apellidos OUT VARCHAR2,
                    p_refpersonales_nombres OUT VARCHAR2,
                    p_refpers_relfamiliar OUT VARCHAR2,
                    p_refpersonales_nombres2 OUT VARCHAR2,
                    p_refpersonales_apellidos2 OUT VARCHAR2,
                    p_refpers_relfamiliar2 OUT VARCHAR2,
                    p_numdocumentoidentidadco OUT VARCHAR2,
                    p_primernombreco OUT VARCHAR2,
                    p_segundonombreco OUT VARCHAR2,
                    p_primerapellidoco OUT VARCHAR2,
                    p_segundoapellidoco OUT VARCHAR2,
                    p_fechanacimientoco OUT VARCHAR2,
                    p_apodoco OUT VARCHAR2,
                    p_idpaisco OUT VARCHAR2,
                    p_idprovinciaco OUT VARCHAR2,
                    p_idmunicipioco OUT VARCHAR2,
                    p_iddistritoco OUT VARCHAR2,
                    p_nombrevinculadoco OUT VARCHAR2,
                    p_idtipovinculadoco OUT VARCHAR2,
                    p_nombre_negocioco OUT VARCHAR2,
                    p_rncco OUT VARCHAR2,
                    p_faxco OUT VARCHAR2,
                    p_emailco OUT VARCHAR2,
                    p_actividad_ciiuco OUT VARCHAR2,
                    p_inicio_mes_co OUT VARCHAR2,
                    p_inicio_ano_co OUT VARCHAR2,
                    p_lugar_trabajoco OUT VARCHAR2,
                    p_fecha_ingresoco OUT VARCHAR2,
                    p_trabajo_direccionco OUT VARCHAR2,
                    p_trabajo_idsectorco OUT VARCHAR2,
                    p_trabajo_idprovinciaco OUT VARCHAR2,
                    p_trabajo_idmunicipioco OUT VARCHAR2,
                    p_trabajo_iddistritoco OUT VARCHAR2,
                    p_punto_referenciaco OUT VARCHAR2,
                    p_cargoco OUT VARCHAR2,
                    p_plazocal OUT VARCHAR2,
                    p_frecuencia_cal OUT VARCHAR2,
                    p_gradoint OUT VARCHAR2,
                    p_idocupacion OUT VARCHAR2,
                    p_idvinculado OUT VARCHAR2,
                    p_actividad_ciiu OUT VARCHAR2,
                    p_trabajo_idsector OUT VARCHAR2,
                    p_nombres OUT VARCHAR2,
                    p_apellidos OUT VARCHAR2,
                    p_primernombre OUT VARCHAR2,
                    p_segundonombre OUT VARCHAR2,
                    p_primerapellido OUT VARCHAR2,
                    p_segundoapellido OUT VARCHAR2,
                    p_desc_provincia OUT VARCHAR2,
                    p_desc_distrito OUT VARCHAR2,
                    p_desc_ciudad OUT VARCHAR2,
                    p_desc_provincia_dom OUT VARCHAR2,
                    p_desc_distrito_dom OUT VARCHAR2,
                    p_desc_ciudad_dom OUT VARCHAR2,
                    p_trabajo_desc_provincia OUT VARCHAR2,
                    p_trabajo_desc_distrito OUT VARCHAR2,
                    p_trabajo_desc_ciudad OUT VARCHAR2,
                    p_id_tempfud OUT VARCHAR2,
                    p_nomarchivo OUT VARCHAR2,
                    p_monto_solicitado OUT VARCHAR2
    )AS
   
  BEGIN
    BEGIN
        SELECT NVL(T.TIPODOCUMENTOIDENTIDAD, ''),
               NVL(T.NUMDOCUMENTOIDENTIDAD, ''),
               NVL(T.APODO, '') AS APODO,
               NVL(T.IDAGENCIA, NULL),
               NVL(T.SEXO, '') AS SEXO,
               NVL(T.FECHANACIMIENTO, NULL),
               NVL(T.IDEMPLEADO, ''),
               NVL(T.IDPAIS, '') ,
               NVL(T.IDPROVINCIA, '') ,
               NVL(T.IDMUNICIPIO, '') ,
               NVL(T.IDDISTRITO, '') ,
               NVL(T.IDESTADOCIVIL, '') ,
               NVL(T.NOMBREVINCULADO, '')  ,
               NVL(T.DIRECCION, '')  ,
               NVL(T.DIRECCION_IDSECTOR, '')  ,
               NVL(T.DIRECCION_IDPROVINCIA, '')  ,
               NVL(T.DIRECCION_DISTRITO, '')  ,
               NVL(T.REF_DOMICILIO, '')  ,
               NVL(T.TIPOPERSONA, '')  ,
               NVL(T.RESIDE_MES, '')  ,
               NVL(T.RESIDE_ANO, '')  ,
               NVL(T.TELEFONO_CASA, '')  ,
               NVL(T.TELEFONO_CELULAR, '')  ,
               NVL(T.NOMBRENEGOCIO, '')  ,
               NVL(T.RNC, '')  ,
               NVL(T.FAX, '')  ,
               NVL(T.EMAIL, '')  ,
               NVL(T.INICIO_MES, '')  ,
               NVL(T.INICIO_ANO, '')  ,
               NVL(T.LUGARTRABAJO, '')  ,
               NVL(T.FECHAINGRESO, '')  ,
               NVL(T.CARGO, '')  ,
               NVL(T.TRABAJO_DIRECCION, '')  ,
               NVL(T.TRABAJO_IDPROVINCIA, '')  ,
               NVL(T.TRABAJO_IDMUNICIPIO, '')  ,
               NVL(T.TRABAJO_IDDISTRITO, '')  ,
               NVL(T.PUNTOREFERENCIA, '')  ,
               NVL(T.TELEFONO, '')  ,
               NVL(T.CODIGOPROYECTO, '')  ,
               NVL(T.ESPECIFIQUEDESTINO, '')  ,
               NVL(T.TASACAL, '')  ,
               NVL(T.IDTIPOVINCULADO, '')  ,
               NVL(T.REFPERSONALES_APELLIDOS, '')  ,
               NVL(T.REFPERSONALES_NOMBRES, '')  ,
               NVL(T.REFPERS_RELFAMILIAR, '')  ,
               NVL(T.REFPERSONALES_NOMBRES2, '')  ,
               NVL(T.REFPERSONALES_APELLIDOS2, '')  ,
               NVL(T.REFPERS_RELFAMILIAR2, '')  ,
               NVL(T.NUMDOCUMENTOIDENTIDADCO, '')  ,
               NVL(T.PRIMERNOMBRECO, '')  ,
               NVL(T.SEGUNDONOMBRECO, '')  ,
               NVL(T.PRIMERAPELLIDOCO, '')  ,
               NVL(T.SEGUNDOAPELLIDOCO, '')  ,
               NVL(T.FECHANACIMIENTOCO, '')  ,
               NVL(T.APODOCO, '')  ,
               NVL(T.IDPAISCO, '')  ,
               NVL(T.IDPROVINCIACO, '')  ,
               NVL(T.IDMUNICIPIOCO, '')  ,
               NVL(T.IDDISTRITOCO, '')  ,
               NVL(T.NOMBREVINCULADOCO, '')  ,
               NVL(T.IDTIPOVINCULADOCO, '')  ,
               NVL(T.NOMBRENEGOCIOCO, '')  ,
               NVL(T.RNCCO, '')  ,
               NVL(T.FAXCO, '')  ,
               NVL(T.EMAILCO, '')  ,
               NVL(T.ACTIVIDAD_CIIUCO, '')  ,
               NVL(T.INICIO_MESCO, '')  ,
               NVL(T.INICIO_ANOCO, '') , 
               NVL(T.LUGARTRABAJOCO, '') ,
               NVL(T.FECHAINGRESOCO, '')  ,
               NVL(T.TRABAJO_DIRECCIONCO, '') ,
               NVL(T.TRABAJO_IDSECTORCO, '') ,
               NVL(T.TRABAJO_IDPROVINCIACO, '') ,
               NVL(T.TRABAJO_IDMUNICIPIOCO, '') ,
               NVL(T.TRABAJO_IDDISTRITOCO, '') ,
               NVL(T.PUNTOREFERENCIACO, '') ,
               NVL(T.CARGOCO, '') ,
               NVL(T.PLAZOCAL, '') ,
               NVL(T.FRECUENCIACAL, '') ,
               NVL(T.GRADOINT, '') ,
               NVL(T.IDOCUPACION, '') ,
               NVL(T.IDVINCULADO, '') ,
               NVL(T.ACTIVIDAD_CIIU, '') ,
               NVL(T.TRABAJO_IDSECTOR, '') ,
               NVL(T.NOMBRES, '') ,
               NVL(T.APELLIDOS, '') ,
               NVL(T.PRIMERNOMBRE, ''),
               NVL(T.SEGUNDONOMBRE, '') ,
               NVL(T.PRIMERAPELLIDO, '') ,
               NVL(T.SEGUNDOAPELLIDO, '') ,
               NVL(T.DESC_PROVINCIA, ''),
               NVL(T.DESC_DISTRITO, '') ,
               NVL(T.DESC_CIUDAD, '') ,
               NVL(T.DESC_PROVINCIA_DOM, '') ,
               NVL(T.DESC_DISTRITO_DOM, '') ,
               NVL(T.DESC_CIUDAD_DOM, '') ,
               NVL(T.TRABAJO_DESC_PROVINCIA, '') ,
               NVL(T.TRABAJO_DESC_DISTRITO, '') ,
               NVL(T.TRABAJO_DESC_CIUDAD, '') ,
               NVL(T.ID_TEMPFUD, '') ,
               NVL(T.NOMARCHIVO, '') ,
               NVL(T.MONTOSOLICITADO, '')
          INTO  p_tipo_documento_identidad,
                 p_num_documento_identidad,
                 p_apodo,
                 p_id_agencia,
                 p_sexo,
                 p_fecha_nacimiento,
                 p_id_empleado,
                 p_id_pais,
                 p_id_provincia,
                 p_id_municipio ,
                    p_id_distrito ,
                    p_id_estado_civil ,
                    p_nombre_vinculado ,
                    p_direccion ,
                    p_direccion_idsector ,
                    p_direccion_idprovincia ,
                    p_direccion_distrito ,
                    p_ref_domicilio ,
                    p_tipo_persona ,
                    p_reside_mes ,
                    p_reside_ano ,
                    p_telefono_casa ,
                    p_telefono_celular ,
                    p_nombre_negocio ,
                    p_rnc ,
                    p_fax ,
                    p_email ,
                    p_inicio_mes ,
                    p_inicio_ano ,
                    p_lugar_trabajo ,
                    p_fecha_ingreso ,
                    p_cargo ,
                    p_trabajo_direccion ,
                    p_trabajo_idprovincia ,
                    p_trabajo_idmunicipio ,
                    p_trabajo_iddistrito ,
                    p_punto_referencia ,
                    p_telefono ,
                    p_codigo_proyecto ,
                    p_especifique_destino ,
                    p_tasa_cal ,
                    p_id_tipo_vinculado ,
                    p_refpersonales_apellidos ,
                    p_refpersonales_nombres ,
                    p_refpers_relfamiliar ,
                    p_refpersonales_nombres2 ,
                    p_refpersonales_apellidos2 ,
                    p_refpers_relfamiliar2 ,
                    p_numdocumentoidentidadco ,
                    p_primernombreco ,
                    p_segundonombreco ,
                    p_primerapellidoco ,
                    p_segundoapellidoco ,
                    p_fechanacimientoco ,
                    p_apodoco ,
                    p_idpaisco ,
                    p_idprovinciaco ,
                    p_idmunicipioco ,
                    p_iddistritoco ,
                    p_nombrevinculadoco ,
                    p_idtipovinculadoco ,
                    p_nombre_negocioco ,
                    p_rncco ,
                    p_faxco ,
                    p_emailco ,
                    p_actividad_ciiuco ,
                    p_inicio_mes_co ,
                    p_inicio_ano_co ,
                    p_lugar_trabajoco ,
                    p_fecha_ingresoco ,
                    p_trabajo_direccionco ,
                    p_trabajo_idsectorco ,
                    p_trabajo_idprovinciaco ,
                    p_trabajo_idmunicipioco ,
                    p_trabajo_iddistritoco ,
                    p_punto_referenciaco ,
                    p_cargoco ,
                    p_plazocal ,
                    p_frecuencia_cal ,
                    p_gradoint ,
                    p_idocupacion ,
                    p_idvinculado ,
                    p_actividad_ciiu ,
                    p_trabajo_idsector ,
                    p_nombres ,
                    p_apellidos ,
                    p_primernombre ,
                    p_segundonombre ,
                    p_primerapellido ,
                    p_segundoapellido ,
                    p_desc_provincia ,
                    p_desc_distrito ,
                    p_desc_ciudad ,
                    p_desc_provincia_dom ,
                    p_desc_distrito_dom ,
                    p_desc_ciudad_dom ,
                    p_trabajo_desc_provincia ,
                    p_trabajo_desc_distrito ,
                    p_trabajo_desc_ciudad ,
                    p_id_tempfud ,
                    p_nomarchivo ,
                    p_monto_solicitado
        FROM PR.PR_SOLICITUD_REPRESTAMO S
        LEFT JOIN PR.PR_REPRESTAMOS R ON R.ID_REPRESTAMO = S.ID_REPRESTAMO
        LEFT JOIN PR.TEMPFUD F ON F.NOCREDITO = S.NO_CREDITO
        LEFT JOIN PR.TEMPFUD_V T ON T.ID_TEMPFUD = F.ID_TEMPFUD
        WHERE S.ID_REPRESTAMO = p_id_represtamo; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  
            p_tipo_documento_identidad := '';
            p_num_documento_identidad := '';
            p_apodo := '';
            p_id_agencia := NULL;
            p_sexo := '';
            p_fecha_nacimiento := NULL;
            p_id_empleado := '';
            p_id_pais := '';
            p_id_provincia := '';
            p_id_municipio  :='';
                    p_id_distrito  :='';
                    p_id_estado_civil  :='';
                    p_nombre_vinculado  :='';
                    p_direccion  :='';
                    p_direccion_idsector  :='';
                    p_direccion_idprovincia  :='';
                    p_direccion_distrito  :='';
                    p_ref_domicilio  :='';
                    p_tipo_persona  :='';
                    p_reside_mes  :='';
                    p_reside_ano  :='';
                    p_telefono_casa  :='';
                    p_telefono_celular  :='';
                    p_nombre_negocio  :='';
                    p_rnc  :='';
                    p_fax  :='';
                    p_email  :='';
                    p_inicio_mes  :='';
                    p_inicio_ano  :='';
                    p_lugar_trabajo  :='';
                    p_fecha_ingreso  :=NULL;
                    p_cargo  :='';
                    p_trabajo_direccion  :='';
                    p_trabajo_idprovincia  :='';
                    p_trabajo_idmunicipio  :='';
                    p_trabajo_iddistrito  :='';
                    p_punto_referencia  :='';
                    p_telefono  :='';
                    p_codigo_proyecto  :='';
                    p_especifique_destino  :='';
                    p_tasa_cal  :='';
                    p_id_tipo_vinculado  :='';
                    p_refpersonales_apellidos  :='';
                    p_refpersonales_nombres  :='';
                    p_refpers_relfamiliar  :='';
                    p_refpersonales_nombres2  :='';
                    p_refpersonales_apellidos2  :='';
                    p_refpers_relfamiliar2  :='';
                    p_numdocumentoidentidadco  :='';
                    p_primernombreco  :='';
                    p_segundonombreco  :='';
                    p_primerapellidoco  :='';
                    p_segundoapellidoco  :='';
                    p_fechanacimientoco  :=NULL;
                    p_apodoco  :='';
                    p_idpaisco  :='';
                    p_idprovinciaco  :='';
                    p_idmunicipioco  :='';
                    p_iddistritoco  :='';
                    p_nombrevinculadoco  :='';
                    p_idtipovinculadoco  :='';
                    p_nombre_negocioco  :='';
                    p_rncco  :='';
                    p_faxco  :='';
                    p_emailco  :='';
                    p_actividad_ciiuco  :='';
                    p_inicio_mes_co  :='';
                    p_inicio_ano_co  :='';
                    p_lugar_trabajoco  :='';
                    p_fecha_ingresoco  :=NULL;
                    p_trabajo_direccionco  :='';
                    p_trabajo_idsectorco  :='';
                    p_trabajo_idprovinciaco  :='';
                    p_trabajo_idmunicipioco  :='';
                    p_trabajo_iddistritoco  :='';
                    p_punto_referenciaco  :='';
                    p_cargoco  :='';
                    p_plazocal  :='';
                    p_frecuencia_cal  :='';
                    p_gradoint  :='';
                    p_idocupacion  :='';
                    p_idvinculado  :='';
                    p_actividad_ciiu  :='';
                    p_trabajo_idsector  :='';
                    p_nombres  :='';
                    p_apellidos  :='';
                    p_primernombre  :='';
                    p_segundonombre  :='';
                    p_primerapellido  :='';
                    p_segundoapellido  :='';
                    p_desc_provincia  :='';
                    p_desc_distrito  :='';
                    p_desc_ciudad  :='';
                    p_desc_provincia_dom  :='';
                    p_desc_distrito_dom  :='';
                    p_desc_ciudad_dom  :='';
                    p_trabajo_desc_provincia  :='';
                    p_trabajo_desc_distrito  :='';
                    p_trabajo_desc_ciudad  :='';
                    p_id_tempfud  :='';
                    p_nomarchivo  :='';
                    p_monto_solicitado  :='';
    END;
  
  END  P_CARGAR_DATOS_FUD_NUEVO;  
  
  PROCEDURE P_CARGAR_DATOS_FEC_NUEVO( 
                    p_id_represtamo          IN  VARCHAR2,
                    p_no_credito             OUT VARCHAR2,
                    p_id_represtamo_out      OUT VARCHAR2,
                    p_nombres                OUT VARCHAR2,
                    p_codigo_cliente         OUT VARCHAR2,
                    p_fecha                  OUT VARCHAR2,
                    p_oficina                OUT VARCHAR2,
                    p_oficial_negocio        OUT VARCHAR2,
                    p_no_credito_nuevo       OUT VARCHAR2,
                    p_actividad_economica    OUT VARCHAR2,
                    p_mto_prestamo           OUT VARCHAR2,
                    p_plazo                  OUT VARCHAR2,
                    p_mto_cuota_total        OUT VARCHAR2,
                    p_tasa                   OUT VARCHAR2,
                    p_excedente_familiares   OUT VARCHAR2,
                    p_costo_ventas           OUT VARCHAR2,
                    p_gasto_operativo        OUT VARCHAR2,
                    p_gasto_operativo_std    OUT VARCHAR2,
                    p_margen_bruto_std       OUT VARCHAR2,
                    p_gastos_familiares      OUT VARCHAR2,
                    p_otros_ingresos         OUT VARCHAR2,
                    p_rel_cuota_exced_fam    OUT VARCHAR2,
                    p_ventas_mensual         OUT VARCHAR2 
        )AS
     BEGIN
    SELECT S.NO_CREDITO, 
           S.ID_REPRESTAMO, 
           S.NOMBRES || ' ' || S.APELLIDOS AS nombres,
           R.CODIGO_CLIENTE, 
           SYSDATE AS fecha,
           S.CODIGO_AGENCIA || ' - ' || A.DESCRIPCION AS oficina,
           S.CODIGO_OFICIAL || ' - ' || PA.Obtiene_NombreEmpleado(S.CODIGO_OFICIAL) AS oficial_negocio,
           S.NO_CREDITO AS no_credito_nuevo,
           PA.F_OBT_DESC_ACTIVIDAD(S.CODIGO_ACTIVIDAD) AS actividad_economica, 
           O.MTO_PRESTAMO, 
           S.PLAZO,  
           O.MTO_CUOTA_TOTAL, 
           O.TASA AS tasa,
           S.EXCEDENTE_FAMILIARES,
           S.COSTO_VENTAS, 
           S.GASTO_OPERATIVO,
           S.GASTO_OPERATIVO_STD,
           S.MARGEN_BRUTO_STD, 
           S.GASTOS_FAMILIARES,
           S.OTROS_INGRESOS, 
           S.REL_CUOTA_EXCED_FAM, 
           S.VENTAS_MENSUAL 
    INTO   p_no_credito,
           p_id_represtamo_out,
           p_nombres,
           p_codigo_cliente,
           p_fecha,
           p_oficina,
           p_oficial_negocio,
           p_no_credito_nuevo,
           p_actividad_economica,
           p_mto_prestamo,
           p_plazo,
           p_mto_cuota_total,
           p_tasa,
           p_excedente_familiares,
           p_costo_ventas,
           p_gasto_operativo,
           p_gasto_operativo_std,
           p_margen_bruto_std,
           p_gastos_familiares,
           p_otros_ingresos,
           p_rel_cuota_exced_fam,
           p_ventas_mensual
    FROM   PR.PR_SOLICITUD_REPRESTAMO S
           JOIN PR.PR_OPCIONES_REPRESTAMO O ON O.CODIGO_EMPRESA = S.CODIGO_EMPRESA AND O.ID_REPRESTAMO = S.ID_REPRESTAMO AND O.PLAZO = S.PLAZO
           JOIN PR.PR_REPRESTAMOS R ON R.CODIGO_EMPRESA = S.CODIGO_EMPRESA AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
           JOIN PA.AGENCIA A ON A.COD_EMPRESA = S.CODIGO_EMPRESA AND A.COD_AGENCIA = S.CODIGO_AGENCIA
    WHERE  S.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
    AND    S.ID_REPRESTAMO = p_id_represtamo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_no_credito := NULL;
        p_id_represtamo_out := NULL;
        p_nombres := NULL;
        p_codigo_cliente := NULL;
        p_fecha := NULL;
        p_oficina := NULL;
        p_oficial_negocio := NULL;
        p_no_credito_nuevo := NULL;
        p_actividad_economica := NULL;
        p_mto_prestamo := NULL;
        p_plazo := NULL;
        p_mto_cuota_total := NULL;
        p_tasa := NULL;
        p_excedente_familiares := NULL;
        p_costo_ventas := NULL;
        p_gasto_operativo := NULL;
        p_gasto_operativo_std := NULL;
        p_margen_bruto_std := NULL;
        p_gastos_familiares := NULL;
        p_otros_ingresos := NULL;
        p_rel_cuota_exced_fam := NULL;
        p_ventas_mensual := NULL;   
   END P_CARGAR_DATOS_FEC_NUEVO;   
PROCEDURE P_SPLIT_CHAMPION_CHALLENGER(
    p_id_lote            IN NUMBER,
    p_nombre_campana     IN VARCHAR2,
    p_challenger_ratio   IN NUMBER DEFAULT 0.40,
    p_error              OUT VARCHAR2
) IS
    -- Definición del tipo para el registro de un candidato
    TYPE type_candidate_rec IS RECORD (
        id_represtamo         NUMBER,
        nombre_cliente        VARCHAR(100),
        identificacion        VARCHAR(30),
        cod_cliente           NUMBER,
        no_credito            NUMBER,
        mto_preaprobado       NUMBER,
        tipo_credito          NUMBER,
        xcore_global          NUMBER,
        oficina               VARCHAR(50),
        zona                  VARCHAR(50),
        oficial               VARCHAR(50)
    );
    -- Definición del tipo para la colección (array) de candidatos
    TYPE type_candidate_tbl IS TABLE OF type_candidate_rec;
    v_candidates         type_candidate_tbl;

    -- Variables internas
    v_challenger_count   NUMBER;
    v_total_candidates   NUMBER := 0;
    v_previous_runs      NUMBER;
    
BEGIN
    SELECT 
        r.id_represtamo, pa.obt_nombre_persona(r.codigo_cliente)AS "nombre_cliente", s.identificacion, r.codigo_cliente, r.no_credito, r.mto_preaprobado,
        s.tipo_credito, r.xcore_global, ag.descripcion AS "Oficina", pa.obt_desc_zona(1, ag.cod_zona) AS "Zona", 
        pa.obt_nombre_empleado(c.codigo_empresa, c.codigo_ejecutivo) AS "Oficial"
    BULK COLLECT INTO v_candidates
    FROM pr.pr_represtamos r
    JOIN pr.pr_solicitud_represtamo s ON r.id_represtamo = s.id_represtamo
    JOIN pr.pr_creditos c ON c.no_credito = r.no_credito
    JOIN pa.agencia ag ON ag.cod_agencia = c.codigo_agencia
    WHERE r.estado = 'NP';

    v_total_candidates := v_candidates.COUNT;
    IF v_total_candidates = 0 THEN
        p_error := 'No hay candidatos en estado NP para procesar.';
        RETURN;
    END IF;
    
    v_challenger_count := TRUNC(v_total_candidates * p_challenger_ratio);

    FOR i IN 1..v_total_candidates LOOP
        DECLARE
            j           INTEGER := TRUNC(DBMS_RANDOM.VALUE(i, v_total_candidates + 1));
            temp_rec    type_candidate_rec;
        BEGIN
            temp_rec          := v_candidates(i);
            v_candidates(i)   := v_candidates(j);
            v_candidates(j)   := temp_rec;
        END;
    END LOOP;
    
    -- 4. Procesar la colección ya mezclada
    FOR i IN 1..v_total_candidates LOOP
        -- Contar cuántas veces este cliente/crédito original ya existe en el log
        SELECT COUNT(*)
        INTO v_previous_runs
        FROM PR.PR_CHAMPION_CHALLENGE_LOG
        WHERE cod_cliente = v_candidates(i).cod_cliente
          AND no_credito = v_candidates(i).no_credito;
          
        IF i <= v_challenger_count THEN
            -- Es un CHALLENGER: Cambiar estado a CHCH (AHORA LCC)
            P_Generar_Bitacora(
                pIdReprestamo  => v_candidates(i).id_represtamo,
                pEstado        => 'LCC',
                pObservaciones => 'Asignado al grupo Challenger. Lote ID: ' || p_id_lote,
                pUsuario       => 'JOB_CHAMPION_CHALLENGE',
                pCanal         => NULL,
                pStep          => NULL
            );
            
            -- Registrar en el LOG como Challenger
            INSERT INTO PR.PR_CHAMPION_CHALLENGE_LOG (
                id_lote, id_represtamo, nombre_cliente, identificacion, cod_cliente, no_credito, fecha_proceso,
                nombre_campana, xcore_al_preaprobar, monto_preaprobado,
                tipo_credito, grupo_asignado, canal_notificacion, veces_procesado, oficina, zona, oficial
            ) VALUES (
                p_id_lote, v_candidates(i).id_represtamo, v_candidates(i).nombre_cliente, v_candidates(i).identificacion, v_candidates(i).cod_cliente, v_candidates(i).no_credito, SYSDATE,
                p_nombre_campana, v_candidates(i).xcore_global, v_candidates(i).mto_preaprobado,
                v_candidates(i).tipo_credito, 'CHALLENGER', NULL, v_previous_runs + 1, v_candidates(i).oficina, v_candidates(i).zona, v_candidates(i).oficial
            );
        ELSE
            -- Es un CHAMPION: Se queda en NP, solo se registra en el log
            INSERT INTO PR.PR_CHAMPION_CHALLENGE_LOG (
                id_lote, id_represtamo, nombre_cliente, identificacion, cod_cliente, no_credito, fecha_proceso,
                nombre_campana, xcore_al_preaprobar, monto_preaprobado,
                tipo_credito, grupo_asignado, canal_notificacion, veces_procesado, oficina, zona, oficial
            ) VALUES (
                p_id_lote, v_candidates(i).id_represtamo, v_candidates(i).nombre_cliente, v_candidates(i).identificacion, v_candidates(i).cod_cliente, v_candidates(i).no_credito, SYSDATE,
                p_nombre_campana, v_candidates(i).xcore_global, v_candidates(i).mto_preaprobado,
                v_candidates(i).tipo_credito, 'CHAMPION', 'SMS', v_previous_runs + 1, v_candidates(i).oficina, v_candidates(i).zona, v_candidates(i).oficial
            );
        END IF;
    END LOOP;

    p_error := 'Proceso de división finalizado. Total: ' || v_total_candidates || 
               '. Challengers: ' || v_challenger_count || 
               '. Champions: ' || (v_total_candidates - v_challenger_count);
EXCEPTION
    WHEN OTHERS THEN
        p_error := 'ERROR en P_SPLIT_CHAMPION_CHALLENGER: ' || SQLERRM;
END P_SPLIT_CHAMPION_CHALLENGER;
PROCEDURE P_EJECUTAR_CAMPANA_CHALLENGE(
    p_error OUT VARCHAR2
) IS
    v_nombre_campana VARCHAR2(100) := 'Campaña ' || TO_CHAR(SYSDATE, 'YYYY-MM');
    v_id_lote        NUMBER;
BEGIN

    SELECT PR.PR_LOTE_ID_SEC.NEXTVAL INTO v_id_lote FROM DUAL;
    
    P_SPLIT_CHAMPION_CHALLENGER(
        p_id_lote => v_id_lote,
        p_nombre_campana => v_nombre_campana,
        p_challenger_ratio => 0.40,
        p_error => p_error
    );
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        p_error := 'ERROR en P_EJECUTAR_CAMPANA_CHALLENGE: ' || SQLERRM;
        ROLLBACK;
END P_EJECUTAR_CAMPANA_CHALLENGE;

PROCEDURE ACTUALIZAR_CHAMPION_CHALLENGE
AS
    v_ultimo_lote NUMBER;
BEGIN
    SELECT MAX(id_lote) INTO v_ultimo_lote FROM PR.PR_CHAMPION_CHALLENGE_LOG;
    
    IF v_ultimo_lote IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('No hay lotes en el log para procesar.');
        RETURN;
    END IF;
    
    -- Actualizar DESEMBOLSO POR FIRMA DIGITAL
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR FIRMA DIGITAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHAMPION'
        AND log.tipo_desembolso IS NULL
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b1
            WHERE b1.id_represtamo = log.id_represtamo
              AND b1.codigo_estado = 'CRY'
        )
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b2
            WHERE b2.id_represtamo = log.id_represtamo
              AND b2.codigo_estado = 'CRD'
        );
    
    -- Actualizar DESEMBOLSO TRADICIONAL
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO TRADICIONAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHAMPION'
        AND log.tipo_desembolso IS NULL
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b1
            WHERE b1.id_represtamo = log.id_represtamo
              AND b1.codigo_estado = 'CRD'
        )
        AND NOT EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b2
            WHERE b2.id_represtamo = log.id_represtamo
              AND b2.codigo_estado = 'CRY'
        );
    
    -- Actualizar DESEMBOLSO POR OFICINA
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR OFICINA',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHALLENGER'
        AND log.tipo_desembolso IS NULL
        AND (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ) IS NOT NULL;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Proceso completado exitosamente para el lote: ' || v_ultimo_lote);
        
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('No se guardó ningún cambio.');
        ROLLBACK;
        RAISE;
END ACTUALIZAR_CHAMPION_CHALLENGE;
END PR_PKG_REPRESTAMOS;
/