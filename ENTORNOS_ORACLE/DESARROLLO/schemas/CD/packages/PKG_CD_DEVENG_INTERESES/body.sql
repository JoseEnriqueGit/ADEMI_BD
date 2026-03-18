CREATE OR REPLACE PACKAGE BODY CD.PKG_CD_DEVENG_INTERESES
IS
/******************************************************************************
   NAME:       PKG_CD_DEVENG_INTERESES
   PURPOSE:    Realizar monitoreos entre la informacion calculada por el proceso temporal y el cierre

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        02/02/2017   rvelilla       1. Created this package.
******************************************************************************/
   PROCEDURE Cd_P_Carga_Nuevos (Pc_Empresa       IN     VARCHAR2,
                                Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
                                Pc_Mensaje          OUT VARCHAR2)
   IS
    -- Efecua: Realiza el proceso de carga de certificados nuevos en la tabla temporal
    -- Requiere: Empresa, Nro Certificado (opcional)
    -- Historia: rvelilla:_ Creacion
     v_fec_ini_mig date := to_date('01/08/2016','dd/mm/yyyy');
    
     CURSOR c_carga_cd_certificados
      IS
        select cod_empresa, num_certificado, 
               (fec_emision - 1) fec_calc_interes, 
               0 mon_acum_int_cap, 0 mon_acum_int_cal, 'CARGA_NUEVOS' comentario
        from cd_certificado
        where estado in ('A', 'R')
        and  num_certificado = nvl (Pc_Certificado, num_certificado)
        and fec_emision >= v_fec_ini_mig
        minus
        select cod_empresa, num_certificado,  
               (select fec_emision - 1 from cd_certificado where num_certificado = t.num_certificado) fec_calc_interes, 
               0 mon_acum_int_cap, 0 mon_acum_int_cal, 'CARGA_NUEVOS' comentario   
        from cd_certificado_tmp T
        where num_certificado = nvl (Pc_Certificado, num_certificado)
        order by cod_empresa, fec_calc_interes, Num_Certificado;
        
   BEGIN
        FOR i IN c_carga_cd_certificados
        LOOP
                BEGIN
                    INSERT INTO cd_certificado_tmp (COD_EMPRESA, 
                                                    NUM_CERTIFICADO, 
                                                    FEC_CALC_INTERES, 
                                                    MON_ACUM_INT_CAP,
                                                    MON_ACUM_INT_CAL,
                                                    COMENTARIO)  
                    VALUES (i.cod_empresa,
                            i.num_certificado,
                            i.fec_calc_interes,
                            i.mon_acum_int_cap,
                            i.mon_acum_int_cal, 
                            i.comentario);                           

                    COMMIT;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       Pc_Mensaje :=
                          'Error Cargando cd_certificado ' || i.num_certificado;
                       ROLLBACK;
                 END;
      END LOOP;
   END Cd_P_Carga_Nuevos;
 
   PROCEDURE Cd_P_Procesa_Rezagados (Pc_Empresa       IN     VARCHAR2,
                                Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
                                Pc_Mensaje          OUT VARCHAR2)
    IS
    -- Efecua: Realiza el proceso de calculo de intereses para certificados rezagados
    -- Requiere: Empresa, Nro Certificado (opcional)
    -- Historia: rvelilla:_ Creacion
   
   Pd_FechaInicio   DATE;
   Pd_FechaFin      DATE;
   Vc_Certificado   VARCHAR2(50);
   
      CURSOR c_cd_certificado_rez(p_fec_hasta_interes    DATE)
      IS
         SELECT  cod_empresa,
                 num_certificado,
                 tip_certificado,
                 cod_producto,
                 fec_max_calc fec_calc_interes
        FROM
        (SELECT c.cod_empresa,
                        c.num_certificado,
                        c.tip_certificado,
                        c.cod_producto,
                        max(t.fec_calc_interes) fec_max_calc
                   FROM cd_certificado c, cd_certificado_tmp t
                    where  c.cod_empresa = t.cod_empresa
                    and c.num_certificado = t.num_certificado
                        AND t.num_certificado = NVL (Pc_Certificado, t.num_certificado)
                        AND c.estado IN ('A', 'R')
                        AND (((nvl (c.fec_vencimiento, trunc (sysdate - 1)) > p_fec_hasta_interes  
                               and nvl(c.ind_reno_auto, 'N') = 'N')
                           or ((nvl (c.fec_vencimiento, trunc (sysdate - 1)) >= p_fec_hasta_interes  
                                and nvl(c.ind_reno_auto, 'N') = 'S'))))
                        AND t.cod_empresa = Pc_Empresa
                        group by c.cod_empresa,
                        c.num_certificado,
                        c.tip_certificado,
                        c.cod_producto)
        where fec_max_calc < p_fec_hasta_interes
        order by fec_calc_interes desc;
    BEGIN
        BEGIN
            select max(fec_calc_interes)
            INTO Pd_FechaFin
            from cd_certificado_tmp t
            where  t.cod_empresa = Pc_Empresa;
        EXCEPTION
        WHEN OTHERS THEN
            Pd_FechaFin := trunc(sysdate - 1);
        END;
        
        FOR i IN c_cd_certificado_rez(Pd_FechaFin)
        LOOP
            Pd_FechaInicio := i.fec_calc_interes;
            Vc_Certificado := i.num_certificado;
            if i.tip_certificado <> 'CU' then
                PKG_CD_DEVENG_INTERESES.Cd_P_Capitalizacion (Pc_Empresa,
                                      Vc_Certificado ,
                                      Pd_FechaInicio,
                                      Pd_FechaFin,
                                      Pc_Mensaje);
                                              
            --DBMS_OUTPUT.put_line('Error Cd_P_Capitalizacion: '||Pc_Mensaje); 
            else
             if i.cod_producto not in (370, 371) then
             PKG_CD_DEVENG_INTERESES.Cd_P_Pago_intereses (Pc_Empresa,
                                  Vc_Certificado ,
                                  Pd_FechaInicio,
                                  Pd_FechaFin,
                                  Pc_Mensaje);
                                              
            --DBMS_OUTPUT.put_line('Error Cd_P_Pago_intereses: '||Pc_Mensaje);
             else
             PKG_CD_DEVENG_INTERESES.Cd_P_Pago_Bonos (Pc_Empresa,
                                  Vc_Certificado ,
                                  Pd_FechaInicio,
                                  Pd_FechaFin,
                                  Pc_Mensaje);
            end if;
           end if;
            --DBMS_OUTPUT.put_line('Error Cd_P_Pago_Bonos: '||Pc_Mensaje);     
        END LOOP;    
               
   END Cd_P_Procesa_Rezagados;    
 
   PROCEDURE Cd_P_Capitalizacion (
      Pc_Empresa       IN     VARCHAR2,
      Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
      Pd_FechaInicio   IN     DATE,
      Pd_FechaFin      IN     DATE,
      Pc_Mensaje          OUT VARCHAR2)
   IS
    -- Efecua: Realiza el proceso de calculo de intereses para certificados capitalizables
    -- Requiere: Empresa, Nro Certificado (opcional), fecha incio, fecha final
    -- Historia: rvelilla:_ Creacion

      v_fec_desde_interes   cd_certificado.fec_calc_interes%TYPE;
      v_fec_hasta_interes   cd_certificado.fec_calc_interes%TYPE;
      v_mes_desde_interes   VARCHAR2 (2);
      v_cre_mes             cd_certificado.cre_mes%TYPE := 0;
      v_mon_acum_int_ret    cd_certificado.mon_acum_int_cap%TYPE := 0;
      v_fecha_proc          cd_interes.fecha_calculo%TYPE := Pd_FechaInicio;



      CURSOR ccapitacizacion (
         p_fec_desde_interes    DATE,
         p_fec_hasta_interes    DATE)
      IS
           SELECT cod_empresa, num_certificado, SUM (cre_interes) tot_interes
             FROM cd_certificado_tmp t
            WHERE     t.fec_calc_interes BETWEEN p_fec_desde_interes
                                             AND p_fec_hasta_interes
                  AND t.num_certificado =
                         NVL (Pc_Certificado, t.num_certificado)
                  AND t.estado IN ('A', 'R')
                  AND t.tip_certificado <> 'CU'
                  AND t.cod_empresa = Pc_Empresa
         GROUP BY cod_empresa, num_certificado;

      CURSOR cdatos (
         p_fec_calc_interes DATE)
      IS
         WITH t_tasa_a_fecha
              AS (SELECT t.cod_empresa,
                         t.num_certificado,
                         DECODE (
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1),
                            0, DECODE (
                                  f_cd_obt_tasa_a_fecha (
                                     t.cod_empresa,
                                     t.num_certificado,
                                     (SELECT MAX (fecha_calculo)
                                        FROM cd_interes
                                       WHERE     cod_empresa = t.cod_empresa
                                             AND num_certificado =
                                                    t.num_certificado
                                             AND fecha_calculo <=
                                                    t.fec_calc_interes)),
                                  0, f_cd_obt_tasa_a_fecha (
                                        t.cod_empresa,
                                        t.num_certificado,
                                        (SELECT MIN (fecha_calculo)
                                           FROM cd_interes
                                          WHERE     cod_empresa =
                                                       t.cod_empresa
                                                AND num_certificado =
                                                       t.num_certificado
                                                AND fecha_calculo >=
                                                       t.fec_calc_interes))),
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1))
                            tasa_a_fecha
                    FROM cd_certificado_tmp t
                   WHERE     t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_retiro
              AS (SELECT DISTINCT
                         m.cod_empresa,
                         m.num_certificado,
                         NVL (TO_NUMBER (m.detalle_actual, '9,999,999.99'),
                              0)
                            mon_retiro
                    FROM cd_movimiento m
                   WHERE     m.cod_empresa = Pc_Empresa
                         AND m.tip_transaccion = 95
                         AND m.fecha_movimiento = p_fec_calc_interes + 1),
              t_mon_int_ganado
              AS (SELECT c.cod_empresa,
                         c.num_certificado,
                         (  (  (  NVL (c.monto, 0)
                                + NVL (t.mon_acum_int_cap, 0)
                                - NVL (vr.mon_retiro, 0))
                             * (NVL (vt.tasa_a_fecha, 0) / 100))
                          / NVL (c.base_calculo, 1))
                            mon_int_ganado
                    FROM cd_certificado c,
                         cd_certificado_tmp t,
                         t_tasa_a_fecha vt,
                         t_retiro vr
                   WHERE     c.cod_empresa = t.cod_empresa
                         AND c.num_certificado = t.num_certificado
                         AND c.cod_empresa = vt.cod_empresa
                         AND c.num_certificado = vt.num_certificado
                         AND vr.cod_empresa(+) = c.cod_empresa
                         AND vr.num_certificado(+) = c.num_certificado
                         AND t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_personas
              AS (SELECT cod_persona,
                         nombre,
                         DECODE (es_fisica, 'S', 'F', 'J') tipo_persona,
                         DECODE (cobr_nodgii_132011, 'S', 'N', 'S') exento,
                         CASE
                            WHEN es_fisica = 'S' AND cobr_nodgii_132011 = 'S'
                            THEN
                               10
                            WHEN es_fisica = 'N' AND cobr_nodgii_132011 = 'S'
                            THEN
                               1
                            ELSE
                               0
                         END
                            porcentaje_renta
                    FROM personas)
         SELECT c.cod_empresa,
                c.num_certificado,
                c.cliente,
                vp.nombre,
                vp.tipo_persona,
                c.fec_emision,
                NVL (c.monto, 0) monto,
                NVL (t.mon_acum_int_cap, 0) mon_acum_int_cap,
                NVL (t.mon_acum_int_cal, 0) mon_acum_int_cal,
                t.fec_calc_interes,
                NVL (vt.tasa_a_fecha, 0) tasa_a_fecha,
                c.base_calculo,
                c.estado,
                c.cod_producto,
                c.cod_agencia,
                c.fec_ult_renov,
                c.tip_certificado,
                c.cod_moneda,
                vp.exento,
                vp.porcentaje_renta,
                NVL (vr.mon_retiro, 0) mon_retiro,
                NVL (t.mon_interes_pagado, 0) mon_interes_pagado,
                NVL (vm.mon_int_ganado, 0) mon_int_ganado,
                ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0))
                   mon_descuento,
                NVL (t.cre_mes, 0) cre_mes,
                (  NVL (vm.mon_int_ganado, 0)
                 - ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0)))
                   cre_interes,
                'Cd_P_Capitalizacion' comentario,
                c.forma_pago_intereses,
                c.cod_cartera,
                c.cod_tasa,
                c.fec_vencimiento,
                c.fec_pago,
                c.base_plazo,
                c.mon_retenido,
                c.ind_reno_auto
           FROM cd_certificado c,
                cd_certificado_tmp t,
                t_tasa_a_fecha vt,
                t_mon_int_ganado vm,
                t_retiro vr,
                t_personas vp
          WHERE     c.cod_empresa = t.cod_empresa
                AND c.num_certificado = t.num_certificado
                AND c.cod_empresa = vt.cod_empresa
                AND c.num_certificado = vt.num_certificado
                AND c.cod_empresa = vm.cod_empresa
                AND c.num_certificado = vm.num_certificado
                AND vr.cod_empresa(+) = c.cod_empresa
                AND vr.num_certificado(+) = c.num_certificado
                AND c.cliente = vp.cod_persona
                AND c.estado IN ('A', 'R')
                AND c.tip_certificado <> 'CU'
                AND t.num_certificado =
                       NVL (Pc_Certificado, c.num_certificado)
                AND t.fec_calc_interes = p_fec_calc_interes
                AND t.cod_empresa = Pc_Empresa;

   BEGIN
      WHILE v_fecha_proc <= Pd_FechaFin
      LOOP
         FOR i IN cdatos (v_fecha_proc - 1)
         LOOP
            if (((nvl (i.fec_vencimiento, trunc (sysdate - 1)) > v_fecha_proc  
                       and nvl(i.ind_reno_auto, 'N') = 'N')
                  or ((nvl (i.fec_vencimiento, trunc (sysdate - 1)) >= v_fecha_proc  
                            and nvl(i.ind_reno_auto, 'N') = 'S'))))
            then
              BEGIN
               IF EXTRACT (DAY FROM v_fecha_proc) = 27
               THEN
                  v_cre_mes := NVL (i.mon_int_ganado, 0);
               ELSE
                  v_cre_mes := i.cre_mes + NVL (i.mon_int_ganado, 0);
               END IF;

               INSERT INTO cd_certificado_tmp (cod_empresa,
                                               num_certificado,
                                               cliente,
                                               nombre_persona,
                                               tipo_persona,
                                               fec_emision,
                                               cod_producto,
                                               estado,
                                               cod_agencia,
                                               fec_ult_renov,
                                               tip_certificado,
                                               cod_moneda,
                                               tip_transaccion,
                                               exento,
                                               porcentaje_renta,
                                               fec_calc_interes,
                                               monto,
                                               mon_acum_int_cap,
                                               mon_acum_int_cal,
                                               mon_interes_pagado,
                                               tas_bruta,
                                               base_calculo,
                                               mon_int_ganado,
                                               mon_descuento,
                                               cre_interes,
                                               cre_mes,
                                               mon_int_x_pagar,
                                               comentario,
                                               forma_pago_intereses,
                                               cod_cartera,
                                               cod_tasa,
                                               fec_vencimiento,
                                               fec_pago,
                                               base_plazo,
                                               mon_retenido)
                    VALUES (
                              i.cod_empresa,
                              i.num_certificado,
                              i.cliente,
                              i.nombre,
                              i.tipo_persona,
                              i.fec_emision,
                              i.cod_producto,
                              i.estado,
                              i.cod_agencia,
                              i.fec_ult_renov,
                              i.tip_certificado,
                              i.cod_moneda,
                              NULL,
                              i.exento,
                              i.porcentaje_renta,
                              v_fecha_proc,
                              i.monto,
                              NVL (i.mon_acum_int_cap, 0),
                                NVL (i.mon_acum_int_cal, 0)
                              + NVL (i.mon_int_ganado, 0),
                                NVL (i.mon_interes_pagado, 0)
                              + NVL (i.mon_retiro, 0),
                              NVL (i.tasa_a_fecha, 0),
                              i.base_calculo,
                              NVL (i.mon_int_ganado, 0),
                              NVL (i.mon_descuento, 0),
                              NVL (i.cre_interes, 0),
                              NVL (v_cre_mes, 0),
                                NVL (i.mon_acum_int_cap, 0)
                              + NVL (v_cre_mes, 0),
                              i.comentario,
                              i.forma_pago_intereses,
                              i.cod_cartera,
                              i.cod_tasa,
                              i.fec_vencimiento,
                              i.fec_pago,
                              i.base_plazo,
                              i.mon_retenido);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  Pc_Mensaje :=
                        'Error Insertando en cd_certificado_tmp '
                     || i.num_certificado;
            END;

            BEGIN
               IF (NVL (i.mon_acum_int_cap, 0) - NVL (i.mon_retiro, 0)) > 0
               THEN
                  v_mon_acum_int_ret :=
                     NVL (i.mon_acum_int_cap, 0) - NVL (i.mon_retiro, 0);
               ELSE
                  v_mon_acum_int_ret := 0;
               END IF;

               UPDATE cd.cd_certificado_tmp
                  SET mon_acum_int_cap = v_mon_acum_int_ret
                WHERE     cod_empresa = i.cod_empresa
                      AND num_certificado = i.num_certificado
                      AND fec_calc_interes = v_fecha_proc;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  Pc_Mensaje :=
                        'Error Actualizando retiro en mon_acum_int_cap en cd_certificado_tmp '
                     || i.num_certificado;
            END;
          END IF;
         END LOOP;


         IF EXTRACT (DAY FROM v_fecha_proc) = 26
         THEN
            v_fec_desde_interes := ADD_MONTHS (v_fecha_proc, -1) + 1;

            FOR j IN ccapitacizacion (v_fec_desde_interes, v_fecha_proc)
            LOOP
               IF NVL (j.tot_interes, 0) > 0
               THEN
                  BEGIN
                     UPDATE cd.cd_certificado_tmp
                        SET mon_acum_int_cap =
                                 NVL (mon_acum_int_cap, 0)
                               + NVL (j.tot_interes, 0)
                      WHERE     cod_empresa = j.cod_empresa
                            AND num_certificado = j.num_certificado
                            AND fec_calc_interes = v_fecha_proc;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        Pc_Mensaje :=
                              'Error Actualizando capitalizacion en mon_acum_int_cap en cd_certificado_tmp '
                           || j.num_certificado;
                  END;

                  COMMIT;
               END IF;
            END LOOP;
         END IF;

         v_fecha_proc := v_fecha_proc + 1;
      END LOOP;
   END Cd_P_Capitalizacion;

   PROCEDURE Cd_P_Pago_intereses (
      Pc_Empresa       IN     VARCHAR2,
      Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
      Pd_FechaInicio   IN     DATE,
      Pd_FechaFin      IN     DATE,
      Pc_Mensaje          OUT VARCHAR2)
   IS
    -- Efecua: Realiza el proceso de calculo de intereses para certificados pagaderos
    -- Requiere: Empresa, Nro Certificado (opcional), fecha incio, fecha final
    -- Historia: rvelilla:_ Creacion
      v_fec_desde_interes   cd_certificado.fec_calc_interes%TYPE;
      v_fec_hasta_interes   cd_certificado.fec_calc_interes%TYPE;
      v_mes_desde_interes   VARCHAR2 (2);
      v_cre_mes             cd_certificado.cre_mes%TYPE := 0;
      v_mon_acum_int_ret    cd_certificado.mon_acum_int_cap%TYPE := 0;

      v_fecha_proc          cd_interes.fecha_calculo%TYPE := Pd_FechaInicio;
      v_fecha_proc_fin      cd_interes.fecha_calculo%TYPE
                               := TO_DATE ('30/11/2016', 'dd/mm/yyyy');

      CURSOR cpago (
         p_fec_desde_interes    DATE,
         p_fec_hasta_interes    DATE)
      IS
           SELECT cod_empresa, num_certificado, SUM (cre_interes) tot_interes
             FROM cd_certificado_tmp t
            WHERE     t.fec_calc_interes BETWEEN p_fec_desde_interes
                                             AND p_fec_hasta_interes
                  AND t.num_certificado =
                         NVL (Pc_Certificado, t.num_certificado)
                  AND t.estado IN ('A', 'R')
                  AND t.tip_certificado = 'CU'
                  AND t.cod_producto NOT IN (370, 371)
                  AND t.cod_empresa = Pc_Empresa
         GROUP BY cod_empresa, num_certificado;


      CURSOR cdatos (
         p_fec_calc_interes DATE)
      IS
         WITH t_tasa_a_fecha
              AS (SELECT t.cod_empresa,
                         t.num_certificado,
                         DECODE (
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1),
                            0, DECODE (
                                  f_cd_obt_tasa_a_fecha (
                                     t.cod_empresa,
                                     t.num_certificado,
                                     (SELECT MAX (fecha_calculo)
                                        FROM cd_interes
                                       WHERE     cod_empresa = t.cod_empresa
                                             AND num_certificado =
                                                    t.num_certificado
                                             AND fecha_calculo <=
                                                    t.fec_calc_interes)),
                                  0, f_cd_obt_tasa_a_fecha (
                                        t.cod_empresa,
                                        t.num_certificado,
                                        (SELECT MIN (fecha_calculo)
                                           FROM cd_interes
                                          WHERE     cod_empresa =
                                                       t.cod_empresa
                                                AND num_certificado =
                                                       t.num_certificado
                                                AND fecha_calculo >=
                                                       t.fec_calc_interes))),
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1))
                            tasa_a_fecha
                    FROM cd_certificado_tmp t
                   WHERE     t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_mon_int_ganado
              AS (SELECT c.cod_empresa,
                         c.num_certificado,
                         (  (  (NVL (c.monto, 0))
                             * (NVL (vt.tasa_a_fecha, 0) / 100))
                          / NVL (c.base_calculo, 1))
                            mon_int_ganado
                    FROM cd_certificado c,
                         cd_certificado_tmp t,
                         t_tasa_a_fecha vt
                   WHERE     c.cod_empresa = t.cod_empresa
                         AND c.num_certificado = t.num_certificado
                         AND c.cod_empresa = vt.cod_empresa
                         AND c.num_certificado = vt.num_certificado
                         AND t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_personas
              AS (SELECT cod_persona,
                         nombre,
                         DECODE (es_fisica, 'S', 'F', 'J') tipo_persona,
                         DECODE (cobr_nodgii_132011, 'S', 'N', 'S') exento,
                         CASE
                            WHEN es_fisica = 'S' AND cobr_nodgii_132011 = 'S'
                            THEN
                               10
                            WHEN es_fisica = 'N' AND cobr_nodgii_132011 = 'S'
                            THEN
                               1
                            ELSE
                               0
                         END
                            porcentaje_renta
                    FROM personas)
         SELECT c.cod_empresa,
                c.num_certificado,
                c.cliente,
                vp.nombre,
                vp.tipo_persona,
                c.fec_emision,
                NVL (c.monto, 0) monto,
                0 mon_acum_int_cap,
                NVL (t.mon_acum_int_cal, 0) mon_acum_int_cal,
                t.fec_calc_interes,
                NVL (vt.tasa_a_fecha, 0) tasa_a_fecha,
                c.base_calculo,
                c.estado,
                c.cod_producto,
                c.cod_agencia,
                c.fec_ult_renov,
                c.tip_certificado,
                c.cod_moneda,
                vp.exento,
                vp.porcentaje_renta,
                0 mon_retiro,
                NVL (t.mon_interes_pagado, 0) mon_interes_pagado,
                NVL (vm.mon_int_ganado, 0) mon_int_ganado,
                ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0))
                   mon_descuento,
                NVL (t.cre_mes, 0) cre_mes,
                (  NVL (vm.mon_int_ganado, 0)
                 - ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0)))
                   cre_interes,
                'Cd_P_Pago_intereses' comentario,
                c.forma_pago_intereses,
                c.cod_cartera,
                c.cod_tasa,
                c.fec_vencimiento,
                c.fec_pago,
                c.base_plazo,
                c.mon_retenido,
               c.ind_reno_auto
           FROM cd_certificado c,
                cd_certificado_tmp t,
                t_tasa_a_fecha vt,
                t_mon_int_ganado vm,
                t_personas vp
          WHERE     c.cod_empresa = t.cod_empresa
                AND c.num_certificado = t.num_certificado
                AND c.cod_empresa = vt.cod_empresa
                AND c.num_certificado = vt.num_certificado
                AND c.cod_empresa = vm.cod_empresa
                AND c.num_certificado = vm.num_certificado
                AND c.cliente = vp.cod_persona
                AND c.estado IN ('A', 'R')
                AND c.tip_certificado = 'CU'
                AND C.cod_producto NOT IN (370, 371)
                AND t.num_certificado =
                       NVL (Pc_Certificado, c.num_certificado)
                AND t.fec_calc_interes = p_fec_calc_interes
                AND t.cod_empresa = Pc_Empresa;

   BEGIN
      WHILE v_fecha_proc <= Pd_FechaFin
      LOOP
         FOR i IN cdatos (v_fecha_proc - 1)
         LOOP
          if (((nvl (i.fec_vencimiento, trunc (sysdate - 1)) > v_fecha_proc  
                       and nvl(i.ind_reno_auto, 'N') = 'N')
                  or ((nvl (i.fec_vencimiento, trunc (sysdate - 1)) >= v_fecha_proc  
                            and nvl(i.ind_reno_auto, 'N') = 'S'))))
          then
            BEGIN
               IF EXTRACT (DAY FROM v_fecha_proc) = 27
               THEN
                  v_cre_mes := NVL (i.mon_int_ganado, 0);
               ELSE
                  v_cre_mes := i.cre_mes + NVL (i.mon_int_ganado, 0);
               END IF;

               INSERT INTO cd_certificado_tmp (cod_empresa,
                                               num_certificado,
                                               cliente,
                                               nombre_persona,
                                               tipo_persona,
                                               fec_emision,
                                               cod_producto,
                                               estado,
                                               cod_agencia,
                                               fec_ult_renov,
                                               tip_certificado,
                                               cod_moneda,
                                               tip_transaccion,
                                               exento,
                                               porcentaje_renta,
                                               fec_calc_interes,
                                               monto,
                                               mon_acum_int_cap,
                                               mon_acum_int_cal,
                                               mon_interes_pagado,
                                               tas_bruta,
                                               base_calculo,
                                               mon_int_ganado,
                                               mon_descuento,
                                               cre_interes,
                                               cre_mes,
                                               mon_int_x_pagar,
                                               comentario,
                                               forma_pago_intereses,
                                               cod_cartera,
                                               cod_tasa,
                                               fec_vencimiento,
                                               fec_pago,
                                               base_plazo,
                                               mon_retenido)
                    VALUES (
                              i.cod_empresa,
                              i.num_certificado,
                              i.cliente,
                              i.nombre,
                              i.tipo_persona,
                              i.fec_emision,
                              i.cod_producto,
                              i.estado,
                              i.cod_agencia,
                              i.fec_ult_renov,
                              i.tip_certificado,
                              i.cod_moneda,
                              NULL,
                              i.exento,
                              i.porcentaje_renta,
                              v_fecha_proc,
                              i.monto,
                              0,
                                NVL (i.mon_acum_int_cal, 0)
                              + NVL (i.mon_int_ganado, 0),
                              NVL (i.mon_interes_pagado, 0),
                              NVL (i.tasa_a_fecha, 0),
                              i.base_calculo,
                              NVL (i.mon_int_ganado, 0),
                              NVL (i.mon_descuento, 0),
                              NVL (i.cre_interes, 0),
                              NVL (v_cre_mes, 0),
                              NVL (v_cre_mes, 0),
                              i.comentario,
                              i.forma_pago_intereses,
                              i.cod_cartera,
                              i.cod_tasa,
                              i.fec_vencimiento,
                              i.fec_pago,
                              i.base_plazo,
                              i.mon_retenido);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  Pc_Mensaje :=
                        'Error Insertando en cd_certificado_tmp '
                     || i.num_certificado;
            END;
          END IF;
         END LOOP;

         IF EXTRACT (DAY FROM v_fecha_proc) = 26
         THEN
            v_fec_desde_interes := ADD_MONTHS (v_fecha_proc, -1) + 1;

            FOR j IN cpago (v_fec_desde_interes, v_fecha_proc)
            LOOP
               IF NVL (j.tot_interes, 0) > 0
               THEN
                  BEGIN
                     UPDATE cd.cd_certificado_tmp
                        SET mon_interes_pagado =
                                 NVL (mon_interes_pagado, 0)
                               + NVL (j.tot_interes, 0)
                      WHERE     cod_empresa = j.cod_empresa
                            AND num_certificado = j.num_certificado
                            AND fec_calc_interes = v_fecha_proc;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        Pc_Mensaje :=
                              'Error Actualizando pago interes en mon_interes_pagado en cd_certificado_tmp '
                           || j.num_certificado;
                  END;

                  COMMIT;
               END IF;
            END LOOP;
         END IF;

         v_fecha_proc := v_fecha_proc + 1;
      END LOOP;
   END Cd_P_Pago_intereses;

   PROCEDURE Cd_P_Pago_Bonos (Pc_Empresa       IN     VARCHAR2,
                              Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
                              Pd_FechaInicio   IN     DATE,
                              Pd_FechaFin      IN     DATE,
                              Pc_Mensaje          OUT VARCHAR2)
   IS
    -- Efecua: Realiza el proceso de calculo de intereses para certificados bonos
    -- Requiere: Empresa, Nro Certificado (opcional), fecha incio, fecha final
    -- Historia: rvelilla:_ Creacion
      v_fec_desde_interes   cd_certificado.fec_calc_interes%TYPE;
      v_fec_hasta_interes   cd_certificado.fec_calc_interes%TYPE;

      v_mes_desde_interes   VARCHAR2 (2);
      v_cre_mes             cd_certificado.cre_mes%TYPE := 0;
      v_cod_producto        cd_certificado.cod_producto%TYPE;

      v_mon_acum_int_ret    cd_certificado.mon_acum_int_cap%TYPE := 0;

      v_fecha_proc          cd_interes.fecha_calculo%TYPE := Pd_FechaInicio;

      CURSOR cpago (
         p_fec_desde_interes    DATE,
         p_fec_hasta_interes    DATE)
      IS
           SELECT cod_empresa, num_certificado, SUM (cre_interes) tot_interes
             FROM cd_certificado_tmp t
            WHERE     t.fec_calc_interes BETWEEN p_fec_desde_interes
                                             AND p_fec_hasta_interes
                  AND t.num_certificado =
                         NVL (Pc_Certificado, t.num_certificado)
                  AND t.estado IN ('A', 'R')
                  AND t.tip_certificado = 'CU'
                  AND t.cod_producto IN (370, 371)
                  AND t.cod_empresa = Pc_Empresa
         GROUP BY cod_empresa, num_certificado;


      CURSOR cdatos (
         p_fec_calc_interes DATE)
      IS
         WITH t_tasa_a_fecha
              AS (SELECT t.cod_empresa,
                         t.num_certificado,
                         DECODE (
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1),
                            0, DECODE (
                                  f_cd_obt_tasa_a_fecha (
                                     t.cod_empresa,
                                     t.num_certificado,
                                     (SELECT MAX (fecha_calculo)
                                        FROM cd_interes
                                       WHERE     cod_empresa = t.cod_empresa
                                             AND num_certificado =
                                                    t.num_certificado
                                             AND fecha_calculo <=
                                                    t.fec_calc_interes)),
                                  0, f_cd_obt_tasa_a_fecha (
                                        t.cod_empresa,
                                        t.num_certificado,
                                        (SELECT MIN (fecha_calculo)
                                           FROM cd_interes
                                          WHERE     cod_empresa =
                                                       t.cod_empresa
                                                AND num_certificado =
                                                       t.num_certificado
                                                AND fecha_calculo >=
                                                       t.fec_calc_interes))),
                            f_cd_obt_tasa_a_fecha (t.cod_empresa,
                                                   t.num_certificado,
                                                   t.fec_calc_interes + 1))
                            tasa_a_fecha
                    FROM cd_certificado_tmp t
                   WHERE     t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_mon_int_ganado
              AS (SELECT c.cod_empresa,
                         c.num_certificado,
                         (  (  (NVL (c.monto, 0))
                             * (NVL (vt.tasa_a_fecha, 0) / 100))
                          / NVL (c.base_calculo, 1))
                            mon_int_ganado
                    FROM cd_certificado c,
                         cd_certificado_tmp t,
                         t_tasa_a_fecha vt
                   WHERE     c.cod_empresa = t.cod_empresa
                         AND c.num_certificado = t.num_certificado
                         AND c.cod_empresa = vt.cod_empresa
                         AND c.num_certificado = vt.num_certificado
                         AND t.cod_empresa = Pc_Empresa
                         AND t.fec_calc_interes = p_fec_calc_interes),
              t_personas
              AS (SELECT cod_persona,
                         nombre,
                         DECODE (es_fisica, 'S', 'F', 'J') tipo_persona,
                         DECODE (cobr_nodgii_132011, 'S', 'N', 'S') exento,
                         CASE
                            WHEN es_fisica = 'S' AND cobr_nodgii_132011 = 'S'
                            THEN
                               10
                            WHEN es_fisica = 'N' AND cobr_nodgii_132011 = 'S'
                            THEN
                               1
                            ELSE
                               0
                         END
                            porcentaje_renta
                    FROM personas)
         SELECT c.cod_empresa,
                c.num_certificado,
                c.cliente,
                vp.nombre,
                vp.tipo_persona,
                c.fec_emision,
                NVL (c.monto, 0) monto,
                0 mon_acum_int_cap,
                NVL (t.mon_acum_int_cal, 0) mon_acum_int_cal,
                t.fec_calc_interes,
                NVL (vt.tasa_a_fecha, 0) tasa_a_fecha,
                c.base_calculo,
                c.estado,
                c.cod_producto,
                c.cod_agencia,
                c.fec_ult_renov,
                c.tip_certificado,
                c.cod_moneda,
                vp.exento,
                vp.porcentaje_renta,
                0 mon_retiro,
                NVL (t.mon_interes_pagado, 0) mon_interes_pagado,
                NVL (vm.mon_int_ganado, 0) mon_int_ganado,
                ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0))
                   mon_descuento,
                NVL (t.cre_mes, 0) cre_mes,
                (  NVL (vm.mon_int_ganado, 0)
                 - ( (vp.porcentaje_renta / 100) * NVL (vm.mon_int_ganado, 0)))
                   cre_interes,
                'Cd_P_Pago_Bonos' comentario,
                c.forma_pago_intereses,
                c.cod_cartera,
                c.cod_tasa,
                c.fec_vencimiento,
                c.fec_pago,
                c.base_plazo,
                c.mon_retenido,
               c.ind_reno_auto
           FROM cd_certificado c,
                cd_certificado_tmp t,
                t_tasa_a_fecha vt,
                t_mon_int_ganado vm,
                t_personas vp
          WHERE     c.cod_empresa = t.cod_empresa
                AND c.num_certificado = t.num_certificado
                AND c.cod_empresa = vt.cod_empresa
                AND c.num_certificado = vt.num_certificado
                AND c.cod_empresa = vm.cod_empresa
                AND c.num_certificado = vm.num_certificado
                AND c.cliente = vp.cod_persona
                AND c.estado IN ('A', 'R')
                AND c.tip_certificado = 'CU'
                AND c.cod_producto IN (370, 371)
                AND t.num_certificado =
                       NVL (Pc_Certificado, c.num_certificado)
                AND t.fec_calc_interes = p_fec_calc_interes
                AND t.cod_empresa = Pc_Empresa;

   BEGIN
      WHILE v_fecha_proc <= Pd_FechaFin
      LOOP
         FOR i IN cdatos (v_fecha_proc - 1)
         LOOP
          if (((nvl (i.fec_vencimiento, trunc (sysdate - 1)) > v_fecha_proc  
                       and nvl(i.ind_reno_auto, 'N') = 'N')
                  or ((nvl (i.fec_vencimiento, trunc (sysdate - 1)) >= v_fecha_proc  
                            and nvl(i.ind_reno_auto, 'N') = 'S'))))
            then
            BEGIN
               IF    (    i.cod_producto = 370
                      AND EXTRACT (DAY FROM v_fecha_proc) = 17)
                  OR (    i.cod_producto = 371
                      AND EXTRACT (DAY FROM v_fecha_proc) = 24)
               THEN
                  v_cre_mes := NVL (i.mon_int_ganado, 0);
               ELSE
                  v_cre_mes := i.cre_mes + NVL (i.mon_int_ganado, 0);
               END IF;

               INSERT INTO cd_certificado_tmp (cod_empresa,
                                               num_certificado,
                                               cliente,
                                               nombre_persona,
                                               tipo_persona,
                                               fec_emision,
                                               cod_producto,
                                               estado,
                                               cod_agencia,
                                               fec_ult_renov,
                                               tip_certificado,
                                               cod_moneda,
                                               tip_transaccion,
                                               exento,
                                               porcentaje_renta,
                                               fec_calc_interes,
                                               monto,
                                               mon_acum_int_cap,
                                               mon_acum_int_cal,
                                               mon_interes_pagado,
                                               tas_bruta,
                                               base_calculo,
                                               mon_int_ganado,
                                               mon_descuento,
                                               cre_interes,
                                               cre_mes,
                                               mon_int_x_pagar,
                                               comentario,
                                               forma_pago_intereses,
                                               cod_cartera,
                                               cod_tasa,
                                               fec_vencimiento,
                                               fec_pago,
                                               base_plazo,
                                               mon_retenido)
                    VALUES (
                              i.cod_empresa,
                              i.num_certificado,
                              i.cliente,
                              i.nombre,
                              i.tipo_persona,
                              i.fec_emision,
                              i.cod_producto,
                              i.estado,
                              i.cod_agencia,
                              i.fec_ult_renov,
                              i.tip_certificado,
                              i.cod_moneda,
                              NULL,
                              i.exento,
                              i.porcentaje_renta,
                              v_fecha_proc,
                              i.monto,
                              0,
                                NVL (i.mon_acum_int_cal, 0)
                              + NVL (i.mon_int_ganado, 0),
                              NVL (i.mon_interes_pagado, 0),
                              NVL (i.tasa_a_fecha, 0),
                              i.base_calculo,
                              NVL (i.mon_int_ganado, 0),
                              NVL (i.mon_descuento, 0),
                              NVL (i.cre_interes, 0),
                              NVL (v_cre_mes, 0),
                              NVL (v_cre_mes, 0),
                              i.comentario,
                              i.forma_pago_intereses,
                              i.cod_cartera,
                              i.cod_tasa,
                              i.fec_vencimiento,
                              i.fec_pago,
                              i.base_plazo,
                              i.mon_retenido);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  Pc_Mensaje :=
                        'Error Insertando en cd_certificado_tmp '
                     || i.num_certificado;
            END;
          END IF;
         END LOOP;

         IF    (EXTRACT (DAY FROM v_fecha_proc) = 16)
            OR (EXTRACT (DAY FROM v_fecha_proc) = 23)
         THEN
            IF (EXTRACT (DAY FROM v_fecha_proc) = 16)
            THEN
               v_cod_producto := 370;
            ELSE
               v_cod_producto := 371;
            END IF;

            v_fec_desde_interes := ADD_MONTHS (v_fecha_proc, -1) + 1;

            FOR j IN cpago (v_fec_desde_interes, v_fecha_proc)
            LOOP
               IF NVL (j.tot_interes, 0) > 0
               THEN
                  BEGIN
                     UPDATE cd.cd_certificado_tmp
                        SET mon_interes_pagado =
                                 NVL (mon_interes_pagado, 0)
                               + NVL (j.tot_interes, 0)
                      WHERE     cod_empresa = j.cod_empresa
                            AND num_certificado = j.num_certificado
                            AND fec_calc_interes = v_fecha_proc
                            AND cod_producto = v_cod_producto;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        Pc_Mensaje :=
                              'Error Actualizando pago interes en mon_interes_pagado en cd_certificado_tmp '
                           || j.num_certificado;
                  END;

                  COMMIT;
               END IF;
            END LOOP;
         END IF;

         v_fecha_proc := v_fecha_proc + 1;
      END LOOP;
   END Cd_P_Pago_Bonos;

   
   PROCEDURE Cd_P_Verifica_Deveng (
      Pc_Empresa       IN     VARCHAR2,
      Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
      Pc_Mensaje          OUT VARCHAR2) 
   IS
    -- Efecua: Realiza el proceso de verificacion de calculo de intereses temporal contra el cierre
    -- Requiere: Empresa, Nro Certificado (opcional)
    -- Historia: rvelilla:_ Creacion
      CURSOR c_comp_cd_certificados
      IS
         SELECT  t.cod_empresa,
                t.num_certificado,
                t.fec_calc_interes,
                t.cod_agencia,
                (nvl(c.mon_acum_int_cap,0) - nvl(t.mon_acum_int_cap,0)) dif_mon_acum_int_cap,
                (nvl(c.mon_acum_int_cal,0) - nvl(t.mon_acum_int_cal,0)) dif_mon_acum_int_cal,
                (nvl(c.mon_interes_pagado,0) - nvl(t.mon_interes_pagado,0)) dif_mon_interes_pagado,
                (nvl(c.tas_bruta,0) - nvl(t.tas_bruta,0)) dif_tas_bruta,
                (nvl(c.mon_int_ganado,0) - nvl(t.mon_int_ganado,0)) dif_mon_int_ganado,
                (nvl(c.cre_interes,0) - nvl(t.cre_interes,0)) dif_cre_interes,
                (nvl(c.cre_mes,0) - nvl(t.cre_mes,0)) dif_cre_mes,
                (nvl(c.mon_int_x_pagar,0) - nvl(t.mon_int_x_pagar,0)) dif_mon_int_x_pagar
           FROM cd_certificado_tmp t, cd_certificado c
          WHERE t.cod_empresa = c.cod_empresa
          and   t.num_certificado = c.num_certificado
          and    t.fec_calc_interes IN
                       (SELECT MAX (fec_calc_interes)
                          FROM cd_certificado_tmp
                         WHERE     cod_empresa = t.cod_empresa
                               AND num_certificado = t.num_certificado)
                AND t.num_certificado = NVL (Pc_Certificado, t.num_certificado)
                AND c.estado IN ('A', 'R')
                AND c.cre_mes > 0
                AND t.cod_empresa = Pc_Empresa;

   BEGIN
        FOR i IN c_comp_cd_certificados
        LOOP
         
            IF i.dif_cre_mes <> 0
               AND ABS(i.dif_cre_mes) >= 1
               --OR i.dif_mon_acum_int_cal <> 0
               --OR i.dif_mon_interes_pagado <> 0
               --OR i.dif_tas_bruta <> 0
               --OR i.dif_mon_int_ganado <> 0
               --OR i.dif_cre_interes <> 0
               --OR i.dif_mon_acum_int_cap <> 0
               --OR i.dif_mon_int_x_pagar <> 0
             THEN
                BEGIN
                    UPDATE cd.cd_certificado_tmp
                       SET procesar = 'E',
                           comentario = ' dif_mon_acum_int_cap '||i.dif_mon_acum_int_cap||
                                        ' dif_mon_acum_int_cal '||i.dif_mon_acum_int_cal||
                                        ' dif_mon_interes_pagado '||i.dif_mon_interes_pagado||
                                        ' dif_tas_bruta '||i.dif_tas_bruta||
                                        ' dif_mon_int_ganado '||i.dif_mon_int_ganado||
                                        ' dif_cre_interes '||i.dif_cre_interes||
                                        ' dif_cre_mes '||i.dif_cre_mes||
                                        ' dif_mon_int_x_pagar '||i.dif_mon_int_x_pagar
                     WHERE     cod_empresa = i.cod_empresa
                           AND num_certificado = i.num_certificado
                           AND fec_calc_interes = i.fec_calc_interes;

                    COMMIT;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       Pc_Mensaje :=
                          'Error Actualizando verificacion cd_certificado ' || i.num_certificado;
                       ROLLBACK;
                 END;
        END IF;
      END LOOP;
   END Cd_P_Verifica_Deveng;
   
   PROCEDURE Cd_P_Aplica_Deveng (
      Pc_Empresa       IN     VARCHAR2,
      Pc_Certificado   IN     VARCHAR2 DEFAULT NULL,
      Pc_Tipo          IN     VARCHAR2 DEFAULT NULL,
      Pc_Mensaje          OUT VARCHAR2) 
   IS
    -- Efecua: Realiza el proceso de actualizacion de calculo de intereses temporal hacia el certificado e interes
    -- Requiere: Empresa, Nro Certificado (opcional), tipo de certificado (opcional: Null -> Todos, BNA -> Bonos, PGA -> Pagaderos, CPA -> Capitalizables) 
    -- Historia: rvelilla:_ Creacion

    CURSOR c_cap_cd_certificado_tmp
      IS
         SELECT cod_empresa,
                num_certificado,
                cod_agencia,
                monto,
                mon_acum_int_cap,
                mon_acum_int_cal,
                mon_interes_pagado,
                fec_calc_interes,
                tas_bruta,
                base_calculo,
                mon_int_ganado,
                mon_descuento,
                cre_interes,
                cre_mes,
                mon_int_x_pagar
           FROM cd_certificado_tmp t
          WHERE     t.fec_calc_interes IN
                       (SELECT MAX (fec_calc_interes)
                          FROM cd_certificado_tmp
                         WHERE     cod_empresa = t.cod_empresa
                               AND num_certificado = t.num_certificado)
                AND t.num_certificado = NVL (Pc_Certificado, t.num_certificado)
                AND t.estado IN ('A', 'R')
                --AND tip_certificado <> 'CU'
                AND t.cod_empresa = Pc_Empresa;

   BEGIN
        FOR i IN c_cap_cd_certificado_tmp
        LOOP
         BEGIN
            UPDATE cd.cd_certificado
               SET mon_acum_int_cap = NVL (i.mon_acum_int_cap, 0),
                   mon_acum_int_cal = NVL (i.mon_acum_int_cal, 0),
                   mon_interes_pagado = NVL (i.mon_interes_pagado, 0),
                   tas_bruta = NVL (i.tas_bruta, 0),
                   mon_int_ganado = NVL (i.mon_int_ganado, 0),
                   cre_interes = NVL (i.cre_interes, 0),
                   cre_mes = NVL (i.cre_mes, 0),
                   mon_int_x_pagar = NVL (i.mon_int_x_pagar, 0)
             WHERE     cod_empresa = i.cod_empresa
                   AND num_certificado = i.num_certificado
                   and estado in ('A', 'R');

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               Pc_Mensaje :=
                  'Error Actualizando cd_certificado ' || i.num_certificado;
               ROLLBACK;
         END;
         
         BEGIN
            UPDATE cd.cd_interes
               SET monto_cd = i.monto + NVL (i.mon_acum_int_cap, 0),
                   monto_interes = NVL (i.cre_interes, 0),
                   tasa_bruta = NVL (i.tas_bruta, 0),
                   monto_interes_bruto = NVL (i.mon_int_ganado, 0)
             WHERE     cod_empresa = i.cod_empresa
                   AND num_certificado = i.num_certificado
                   AND fecha_calculo IN
                          (SELECT MAX (fecha_calculo)
                             FROM cd_interes
                            WHERE     cod_empresa = i.cod_empresa
                                  AND num_certificado = i.num_certificado
                                  AND fecha_calculo <= i.fec_calc_interes);

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               Pc_Mensaje :=
                  'Error Actualizando cd_interes ' || i.num_certificado;
               ROLLBACK;
         END;
         
      END LOOP;
   END Cd_P_Aplica_Deveng;
   
   procedure dia_habil (empresa             in     number,
                        agencia             in     number,
                        fecha_b                    date,
                        p_trabaja_sabado    in     boolean,
                        p_trabaja_domingo   in     boolean,
                        es_habil            in out number)
   is
      v_es_habil     number (8);
      v_nombre_dia   varchar2 (20);
   --Returna Cero si el dia es no habil..
   begin
      v_nombre_dia := rtrim (to_char (fecha_b, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH'));
      --
      select count ('x')
        into v_es_habil
        from feriados_x_agencia
       where cod_empresa = to_char (empresa)
             and cod_agencia = to_char (agencia)
             and fecha = fecha_b;
      --
      if (v_es_habil = 1)
      then
         v_es_habil := 0;
      elsif ( (v_nombre_dia <> 'SUNDAY')
             or (p_trabaja_domingo))
            and ( (v_nombre_dia <> 'SATURDAY')
                 or (p_trabaja_sabado))
      then
         v_es_habil := 1;
      end if;
      --
      es_habil := v_es_habil;
   end;
   
   PROCEDURE Cd_P_Ejec_Verif_Deveng  IS
       -- Efecua: Realiza el proceso de ejecucion de calculo de intereses temporal y verificacion
    -- Requiere: Empresa, Nro Certificado (opcional), tipo de certificado (opcional) 
   -- Historia: rvelilla:_ Creacion

   Pc_Empresa         VARCHAR2(2) := 1;
   Pn_Agencia         NUMBER := 50;
   Pd_FechaInicio   DATE;
   Pd_FechaSig      DATE;
   Pd_FechaFestSig  DATE;
   Pd_FechaFin      DATE;
   Pc_Certificado   VARCHAR2(50) := null;
   Pc_Mensaje         VARCHAR2(100); 
   Pn_es_habil      NUMBER;
   Pn_sig_habil     NUMBER;
   Pc_nombre_dia    varchar2 (20); 
   Vb_procesar      boolean := false;   
    BEGIN

        Pd_FechaInicio := trunc(sysdate - 1);
        Pd_FechaFin := Pd_FechaInicio;
        Pd_FechaSig := Pd_FechaInicio + 1;
        Pd_FechaFestSig  := Pd_FechaInicio + 3;
        
        PKG_CD_DEVENG_INTERESES.dia_habil(Pc_Empresa, Pn_Agencia, Pd_FechaInicio, false, false, Pn_es_habil);
        
        --DBMS_OUTPUT.put_line('Error dia_habil: '||Pn_es_habil);
        Pc_nombre_dia := rtrim (to_char (Pd_FechaInicio, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH'));
        
        IF Pn_es_habil = 1        
        THEN
            PKG_CD_DEVENG_INTERESES.dia_habil(Pc_Empresa, Pn_Agencia, Pd_FechaSig, false, false, Pn_sig_habil);
            if Pn_sig_habil = 1 then
                Vb_procesar := true;
                Pd_FechaFin := Pd_FechaInicio;
            else
                if (Pc_nombre_dia = 'FRIDAY' OR Pc_nombre_dia = 'THURSDAY') then
                    Vb_procesar := true;
                    PKG_CD_DEVENG_INTERESES.dia_habil(Pc_Empresa, Pn_Agencia, Pd_FechaFestSig, false, false, Pn_sig_habil);
                    if Pn_sig_habil = 1 then
                        Pd_FechaFin := Pd_FechaInicio + 2;
                    else
                        Pd_FechaFin := Pd_FechaInicio + 3;
                    end if;
                else
                    Vb_procesar := true;
                    Pd_FechaFin := Pd_FechaInicio + 1;
                end if;
            end if;
        ELSE
            Vb_procesar := false;
        END IF;    

        IF Vb_procesar    
        THEN
            PKG_CD_DEVENG_INTERESES.Cd_P_Carga_Nuevos (Pc_Empresa,
                                                       Pc_Certificado,
                                                       Pc_Mensaje);
                                                       
            PKG_CD_DEVENG_INTERESES.Cd_P_Procesa_Rezagados    (Pc_Empresa,
                                                       Pc_Certificado,
                                                       Pc_Mensaje);        
                                                       
            PKG_CD_DEVENG_INTERESES.Cd_P_Capitalizacion (Pc_Empresa,
                                  Pc_Certificado ,
                                  Pd_FechaInicio,
                                  Pd_FechaFin,
                                  Pc_Mensaje);
                                              
            --DBMS_OUTPUT.put_line('Error Cd_P_Capitalizacion: '||Pc_Mensaje); 

             PKG_CD_DEVENG_INTERESES.Cd_P_Pago_intereses (Pc_Empresa,
                                  Pc_Certificado ,
                                  Pd_FechaInicio,
                                  Pd_FechaFin,
                                  Pc_Mensaje);
                                              
            --DBMS_OUTPUT.put_line('Error Cd_P_Pago_intereses: '||Pc_Mensaje);

             PKG_CD_DEVENG_INTERESES.Cd_P_Pago_Bonos (Pc_Empresa,
                                  Pc_Certificado ,
                                  Pd_FechaInicio,
                                  Pd_FechaFin,
                                  Pc_Mensaje);
            
            --DBMS_OUTPUT.put_line('Error Cd_P_Pago_Bonos: '||Pc_Mensaje);     
            

             PKG_CD_DEVENG_INTERESES.Cd_P_Verifica_Deveng (Pc_Empresa,
                          Pc_Certificado ,
                          Pc_Mensaje);    
             --DBMS_OUTPUT.put_line('Error Cd_P_Verifica_Deveng: '||Pc_Mensaje);         
        end if;                      
   END Cd_P_Ejec_Verif_Deveng;
END PKG_CD_DEVENG_INTERESES;
/
