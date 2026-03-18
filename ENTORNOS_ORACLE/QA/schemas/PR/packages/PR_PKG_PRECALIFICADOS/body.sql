create or replace PACKAGE BODY    PR_PKG_PRECALIFICADOS IS

   PROCEDURE PRECALIFICA_CREDITO  IS     
       --- => Condicones a tomar en cuenta para la Precalificación de Créditos
       -- 1 - Microcreditos Monto Tope RD$ 772,280;       
       -- 2 - Haber pagado al menos 70% capital;    
       -- 3 - Préstamo en categoria A o B   
       -- 4 - No debe ser un Préstamo Reestructurado; ESTADO =>(E)
       --   - Se actualizará el Campo 'ESTADO' con 'X6', y el Campo 'OBSERVACIONES' con 'EL CLIENTE POSEE PRESTAMOS REESTRUCTURADOS', en la Tabla PR_PRECALIFICADOS
       --
       -- 5 - Incluir los tipos de créditos ('150','152','154','166','176','178','180','187','189','191','203','713','714','751','753','755','773','774','775','776','779','790')
       -- 6 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses (Tomando el atraso máximo en los últimos 6 meses)
       -- Se actualizará el Campo 'ESTADO' con 'X2', y el Campo 'OBSERVACIONES' con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||v_mayor_45||' DIAS',
       -- en la Tabla PR_PRECALIFICADOS
       --
       -- 7 - Excluir cliente con TC (Tarjetas de Crédito) con días de atraso mayor a 30 días; se actualizará el ESTADO con el valor 'X3';
       --   - el Campo OBSERVACIONES se actualizará con  'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'.
       --
       -- 8 - Excluir cliente que tengas préstamos desembolsados en los últimos 6 meses;
       --   - Se actualizará el Campo 'ESTADO' con 'X1', y el Campo 'OBSERVACIONES' con 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||PA.PARAM.PARAMETRO_GENERAL
       --   - ('PRECAL_DESEMBOLSO_PR', 'PR')||' DIAS' en la Tabla PR_PRECALIFICADOS
       
       CURSOR CREDITOS_PROCESAR (P_FECHA_CORTE DATE)  IS
          SELECT C.CODIGO_EMPRESA,
                 C.CODIGO_CLIENTE,
                 D.FECHA_CORTE, 
                 C.NO_CREDITO,
                 CASE
                    WHEN D.REESTRUCTURADO != 'NR' THEN 'X7'
                    ELSE 'P'
                 END AS  ESTADO,
                 NULL codigo_precalificacion,
                 CASE
                    WHEN D.REESTRUCTURADO != 'NR' THEN 'CREDITO CON REESTRUCTURACION '||D.REESTRUCTURADO
                    ELSE NULL
                 END AS  OBSERVACIONES,
                 D.DIAS_ATRASO,
                 TRUNC(SYSDATE) FECHA_PROCESO
            FROM PR_CREDITOS C, 
                 PR_TIPO_CREDITO T, 
                 PA_DETALLADO_DE08 D
           WHERE C.CODIGO_EMPRESA      = T.CODIGO_EMPRESA
             AND C.TIPO_CREDITO        = T.TIPO_CREDITO
             AND C.ESTADO              IN ('V', 'D', 'M')
             AND  f_convierte_monto (1,
                             D.fecha_corte,
                             C.MONTO_DESEMBOLSADO,
                             D.codigo_moneda,
                             1)  <= OBT_PARAMETROS( '1', 'PR', 'PRECAL_MONTO_TOPE_MC')-- 1 - Microcreditos Monto Tope RD$ 772,280
                 --
             AND T.TIPO_CREDITO        IN ('150','152','154','166','176','178','180','187','189','191','203','713','714','751','753','755','773','774','775','776','779','790') -- 6 - Incluir estos los tipos de créditos
             AND T.GRUPO_TIPO_CREDITO  = 'C'
                 --
             AND D.FUENTE              = 'PR'
             AND D.FECHA_CORTE         = P_FECHA_CORTE     
             AND D.NO_CREDITO          = C.NO_CREDITO
             AND D.CODIGO_CLIENTE      = C.CODIGO_CLIENTE
             AND D.CODIGO_EMPRESA      = C.CODIGO_EMPRESA         
             AND D.CALIFICA_CLIENTE    IN ('A', 'B') -- 3 - Préstamo en categoria A o B
             AND D.DIAS_ATRASO         <=OBT_PARAMETROS( '1', 'PR', 'PRECAL_MORA_MAYOR_PR')-- 7 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses
            AND (( D.MTO_BALANCE_CAPITAL / 
             CASE WHEN D.MONTO_DESEMBOLSADO =0 then
                 D.MONTO_CREDITO
                 else D.MONTO_DESEMBOLSADO END )*100 )<= 30; -- 2 - Haber pagado al menos 70% capital
             
       TYPE tCREDITOS_PROCESAR IS TABLE OF CREDITOS_PROCESAR%ROWTYPE;
       vCREDITOS_PROCESAR        tCREDITOS_PROCESAR := TCREDITOS_PROCESAR ();
       
       v_fecha_tope              DATE;      

       v_fecha_corte             DATE; 
       v_fecha_proceso           DATE;
       v_mayor_45                NUMBER;
       v_atraso_30               NUMBER;
       v_dias_180                NUMBER;
       v_dias_atraso_max         NUMBER;
        
    BEGIN
       -- Asigna el valor del Parámetro a la variable correspondioente 
       v_mayor_45  := TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR'));
       v_atraso_30 := TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'PRECAL_DIA_ATRASO_TC'));
       v_dias_180  := TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')); 
      
      -- Ejecuto un SELECT INTO de la FECHA_PROCESO en la tabla PR_PRECALIFICADOS    
      -- Calculo que la variable v_fecha_froceso + el Parámetro de Fecha_a_Procesar(Que puede ser 10 días)
      -- Si la Fecha resultante es Mayor al trunc(Sysdate) Ejecuto el Package PR_PKG_PRECALIFICADOS;
      -- de lo contrario ejecuto un Return, para que el Package CDG.P_CARGA_PRESTAMOS termine su Ejecución.  
          BEGIN
               SELECT P.FECHA_PROCESO
                 INTO v_fecha_proceso      
                 FROM PR.PR_PRECALIFICADOS P
                WHERE P.FECHA_PROCESO IS NOT NULL 
                  AND ROWNUM = 1;
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    v_fecha_proceso:= TRUNC(SYSDATE)-30;
                 END;      
              
                BEGIN
                   v_fecha_proceso:= v_fecha_proceso + OBT_PARAMETROS( '1','PR','PRECAL_DIAS_PROCESAR');
                  IF v_fecha_proceso > TRUNC(SYSDATE) THEN
                    PR.PR_PKG_PRECALIFICADOS.ACTUALIZA_PRECALIFICACION;
                    DBMS_OUTPUT.PUT_LINE ( 'v_fecha_proceso = ' || v_fecha_proceso );
                    RETURN;
                  END IF;
                END; 
       
      -- Limpiar la tabla de precalificados  
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PR.PR_PRECALIFICADOS';

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
          FETCH CREDITOS_PROCESAR BULK COLLECT INTO VCREDITOS_PROCESAR LIMIT 1000;
          -- Inserta los Precalificados
          FORALL i IN 1 .. VCREDITOS_PROCESAR.COUNT INSERT INTO PR.PR_PRECALIFICADOS VALUES VCREDITOS_PROCESAR (i);

          -- Préstamos reestructurados
          -- 4 - No debe ser un Préstamo Reestructurado, Préstamos con Estado =>(E)
          -- Se actualizará el Campo 'ESTADO' con 'X6'; y el Campo 'OBSERVACIONES' con 'EL CLIENTE POSEE PRESTAMOS REESTRUCTURADOS'
          -- en la Tabla PR_PRECALIFICADOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_PRECALIFICADOS y
                SET y.ESTADO         = 'X6',
                    Y.OBSERVACIONES = 'EL CLIENTE POSEE PRESTAMOS REESTRUCTURADOS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR (x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR (x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR (x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR (x).NO_CREDITO
                AND y.ESTADO         = 'P' 
                AND 1                = (SELECT DISTINCT 1
                                         FROM PR_CREDITOS c
                                        WHERE C.CODIGO_EMPRESA  = VCREDITOS_PROCESAR (x).CODIGO_EMPRESA                                      
                                          AND C.NO_CREDITO     != VCREDITOS_PROCESAR (x).NO_CREDITO
                                          AND C.CODIGO_CLIENTE  = VCREDITOS_PROCESAR (x).CODIGO_CLIENTE
                                          AND C.ESTADO = 'E');  -- 4 - No debe ser un Préstamo Reestructurado; Estado =>(E) 


          -- Garantias Excluyentes
          -- 5 - Excluir préstamos con garantias  
          -- Para excluir los Créditos con caulquier Garantía 
          -- Se actualizará el Campo 'ESTADO' con 'X4'; y el Campo 'OBSERVACIONES' con 'EL CLIENTE POSEE PRESTAMO CON GARANTIA'
          -- en la Tabla PR_PRECALIFICADOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_PRECALIFICADOS y
                SET y.ESTADO         = 'X4',
                    Y.OBSERVACIONES = 'EL CLIENTE POSEE PRESTAMO CON GARANTIA'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR (x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR (x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR (x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR (x).NO_CREDITO
                AND y.ESTADO         = 'P'             
                AND 1                = (SELECT DISTINCT 1
                                          FROM PR_CREDITOS c, 
                                               PR_GARANTIAS g
                                         WHERE C.CODIGO_EMPRESA          = VCREDITOS_PROCESAR (x).CODIGO_EMPRESA
                                           AND C.NO_CREDITO              = VCREDITOS_PROCESAR (x).NO_CREDITO
                                           AND G.CODIGO_EMPRESA          = C.CODIGO_EMPRESA
                                           AND G.NUMERO_GARANTIA         >= 0
                                           AND G.CODIGO_TIPO_GARANTIA_SB != 'S4'
                                           AND G.NO_CREDITO              = C.NO_CREDITO);

           -- 7 - Excluir créditos con atraso mayor a 45 días
           -- 7 - en los últimos 6 meses = v_dias_180 
           FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT 
           -- Se actualiza el campo DIAS_ATRASO en la Tabla PR_PRECALIFICADOS
           -- con el Máximo día de atraso en los últimos 6 meses   
           UPDATE PR.PR_PRECALIFICADOS y
                SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
                                               FROM  PA.PA_DETALLADO_DE08 D
                                              WHERE  D.FUENTE           = 'PR'
                                                 AND D.FECHA_CORTE      >= ADD_MONTHS(VCREDITOS_PROCESAR(x).FECHA_CORTE , -6) -- 7 - Excluir créditos con atraso mayor a 45 días en los últimos 6 meses
                                                 AND D.NO_CREDITO       = VCREDITOS_PROCESAR(x).NO_CREDITO 
                                                 AND D.CODIGO_CLIENTE   = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                               --  AND D.DIAS_ATRASO      >= v_mayor_45 
                                                 )
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'P';   
                 
          -- 8 - Excluir cliente con TC con dias de atraso mayor a 30 días 
          -- Actualiza el estado cuando existe un detalle PA.PA_DETALLADO_DE08 de TC
          -- Se actualizará el Campo 'ESTADO' con 'X3'; y el Campo 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
          -- en la Tabla PR_PRECALIFICADOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_PRECALIFICADOS y
                SET y.ESTADO         = 'X3',
                    Y.OBSERVACIONES  = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
              WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
                AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO
                AND y.ESTADO         = 'P'             
                AND 1                IN (SELECT 1
                                          FROM PA_DETALLADO_DE08 D
                                         WHERE D.FUENTE           =  'TC'
                                           AND D.FECHA_CORTE      =  VCREDITOS_PROCESAR(x).FECHA_CORTE
                                           AND D.NO_CREDITO       != VCREDITOS_PROCESAR(x).NO_CREDITO                                      
                                           AND D.CODIGO_CLIENTE   =  VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
                                           AND D.CODIGO_EMPRESA   =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                                           AND D.DIAS_ATRASO      >= v_atraso_30); 
                            
          -- Evalua si el cliente tiene otro Prestamo Desembolsados en los últimos 6 Meses
          -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
          -- Se actualizará el Campo 'ESTADO' con 'X1'; y el Campo 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||PA.PARAMETROS_X_EMPRESA( 'PRECAL_DESEMBOLSO_PR', 'PR')||' MESES'
          -- en la Tabla PR_PRECALIFICADOS
          FORALL x IN 1 .. VCREDITOS_PROCESAR.COUNT
             UPDATE PR.PR_PRECALIFICADOS y
                SET y.ESTADO         = 'X1', 
                    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ÚLTIMOS '||OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')||' MESES'
             WHERE y.CODIGO_EMPRESA = VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
               AND y.CODIGO_CLIENTE = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE
               AND Y.FECHA_CORTE    = VCREDITOS_PROCESAR(x).FECHA_CORTE
               AND y.NO_CREDITO     = VCREDITOS_PROCESAR(x).NO_CREDITO 
               AND y.ESTADO         = 'P'   
               AND 1 = (SELECT DISTINCT 1
                          FROM PR_CREDITOS C 
                         WHERE C.CODIGO_EMPRESA      =  VCREDITOS_PROCESAR(x).CODIGO_EMPRESA
                           AND C.NO_CREDITO          != VCREDITOS_PROCESAR(x).NO_CREDITO                       
                           AND C.CODIGO_CLIENTE      = VCREDITOS_PROCESAR(x).CODIGO_CLIENTE                        
                           AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - OBT_PARAMETROS('1','PR', 'PRECAL_DESEMBOLSO_PR')) -- 9 - Excluir cliente que tengas prestamos desembolsados de los últimos 6 meses
                           AND C.ESTADO              IN ('V', 'D', 'M'));

          EXIT WHEN CREDITOS_PROCESAR%NOTFOUND;
       END LOOP;
       
       CLOSE CREDITOS_PROCESAR;
       
       -- Se actualiza el ESTADO con valor 'X2' y el campo OBSERVACIONES con 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
       -- en la tabla PR_PRECALIFICADOS para todos los Créditos precalificados con Estodo ='P'
        UPDATE PR.PR_PRECALIFICADOS P
           SET P.ESTADO         = 'X2',
               P.OBSERVACIONES  = 'EL CLIENTE TIENE EN LOS ULTIMOS 6 MESES ATRASO O MORA MAYOR IGUAL A '||P.DIAS_ATRASO||' DIAS'
         WHERE P.DIAS_ATRASO    > OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')
           AND P.ESTADO         = 'P';
           
         PR.PR_PKG_PRECALIFICADOS.ACTUALIZA_PRECALIFICACION;
    EXCEPTION
      WHEN OTHERS THEN 
         raise_application_error(-20001, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);  
    END PRECALIFICA_CREDITO;

    PROCEDURE ACTUALIZA_PRECALIFICACION  IS 
    -- QUERY DE LOS CREDITOS PRECALIFICADOS
       CURSOR PRECALIFICADOS IS
             SELECT PC.CODIGO_EMPRESA, 
                    PC.NO_CREDITO,
                    PC.CODIGO_CLIENTE,
                    PC.DIAS_ATRASO,
                    P.CODIGO_PRECALIFICACION
               FROM PR.PR_PRECALIFICADOS PC,
                    PR.PR_CODIGO_PRECALIFICACION P
              WHERE PC.CODIGO_EMPRESA         = P.CODIGO_EMPRESA 
                AND PC.ESTADO ='P' 
                AND PC.DIAS_ATRASO BETWEEN P.DESDE AND HASTA;
               -- AND NVL(P.CODIGO_PRECALIFICACION,'x')!=pc.CODIGO_PRECALIFICACION;
             -- ORDER BY 4 ASC;
              
    BEGIN 
        
      -- Se actualiza el campo CODIGO_PRECALIFICACION con valor 'NI' y el campo OBSERVACIONES con valor 'NINGUNA PRECALIFICACION' 
      -- para todos lo créditos en la tabla PR_PRECALIFICADOS con ESTADO diferente a 'P'  
        UPDATE PR.PR_PRECALIFICADOS p 
           SET P.CODIGO_PRECALIFICACION = 'NI'
         WHERE P.ESTADO != 'P';
        DBMS_OUTPUT.PUT_LINE ( ' BANDERA 10' ); 
      FOR X IN PRECALIFICADOS 
       LOOP
              -- 1 - Actualizar el Código de Precalificación en la Tabla PR.PR_PRECALIFICADOS 
             UPDATE PR.PR_PRECALIFICADOS  
                SET CODIGO_PRECALIFICACION = x.CODIGO_PRECALIFICACION 
              WHERE CODIGO_EMPRESA         = x.codigo_empresa 
                AND CODIGO_CLIENTE         = x.codigo_cliente
                AND NO_CREDITO             = x.no_credito
                AND ESTADO                 = 'P';
                --AND (CODIGO_PRECALIFICACION IS NOT NULL OR CODIGO_PRECALIFICACION !=x.CODIGO_PRECALIFICACION); 
         
             -- 2 - Actualizar el Código de Precalificación en la Tabla CDG.CREDITOS_GT_TMP
              UPDATE CDG.CREDITOS_GT_TMP y
                 SET y.CODIGO_PRECALIFICACION = x.CODIGO_PRECALIFICACION 
               WHERE y.IDCREDITO              = x.NO_CREDITO;
       END LOOP;
    END ACTUALIZA_PRECALIFICACION;

END PR_PKG_PRECALIFICADOS;