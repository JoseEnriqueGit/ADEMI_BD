create or replace PACKAGE BODY    pr_credito
AS
   PROCEDURE inserta_credito (
      p_codigo_empresa            NUMBER,
      p_codigo_agencia            NUMBER,
      p_no_credito       IN OUT   NUMBER,
      p_credito          IN OUT   t_rec_pr_creditos,
      pmensajeerror      IN OUT   VARCHAR2
   )
   IS
      --

      -- Declaracion de cursores
      CURSOR cur_tipo_credito (p_codigo_empresa NUMBER, p_tipo_credito NUMBER)
      IS
         SELECT grupo_tipo_credito, tiene_vencimiento, es_pre_aprobado,
                NVL (es_cuota_multiple, 'N') es_cuota_multiple,
                con_garantia_certificado, porcentaje_pignoracion_cd,
                ind_es_reserva, NVL (ptp.plazo_minimo, 1) plazo_minimo,
                
                --Nvl( plazo_minimo, 1 ) plazo_minimo,--LMVR
                NVL (ptp.plazo_maximo, 9999) plazo_maximo,
                
                --Nvl( plazo_maximo, 9999 ) plazo_maximo,--LMVR
                NVL (comision_normal_minima, 0) comision_normal_minima,
                NVL (comision_normal_maxima, 100) comision_normal_maxima,
                monto_minimo, monto_maximo, 0 cantidad_cuotas_extra,
                'AN' periodo_cuota_extraordinario, 0 cuota_extraordinaria,
                'ME' periodo_cuota_ordinaria, 0 dias_periodo_extraordinario
           FROM pr_tipo_credito ptc, pr_tipos_plazos ptp
          WHERE ptc.codigo_empresa = p_codigo_empresa
            AND ptc.tipo_credito = p_tipo_credito
            AND ptc.codigo_plazo = ptp.codigo_plazo;

      -- Declaracion de Variables
      exerror                EXCEPTION;
      v_plazo_minimo         pr_tipo_credito.plazo_minimo%TYPE;
      v_plazo_maximo         pr_tipo_credito.plazo_maximo%TYPE;
      v_monto_minimo         pr_tipo_credito.monto_minimo%TYPE;
      v_monto_maximo         pr_tipo_credito.monto_maximo%TYPE;
      v_grupo_tipo_credito   pr_tipo_credito.grupo_tipo_credito%TYPE;
      v_rec_tipo_credito     cur_tipo_credito%ROWTYPE;
      vcount                 NUMBER (8);
      vtipcredfecrev         VARCHAR2 (80);
      -- API 08/10/2009 Inclusion control fecha proxima revision
      cmensaje               VARCHAR2 (250);                            --LMVR
      --LMVR
      vmonto                 pr_creditos.monto_credito%TYPE;
      vmonto_cargo           pr_rangos_x_cargo_x_tc.monto_cargo%TYPE;
      vmonto_minimo          pr_rangos_x_cargo_x_tc.monto_minimo%TYPE;
      vmonto_maximo          pr_rangos_x_cargo_x_tc.monto_maximo%TYPE;
      vmonto_calculado       pr_cargos_x_credito.monto_cargo%TYPE;
      vmonto_calculo        Number; 
   --LMVR
   BEGIN
      DBMS_OUTPUT.put_line ('Inicia Inserta_Credito');
      --

      --p_depura( 'BD Inserta_Credito' );

      --

      --p_depura( 'BD cur_tip_credito' );

      --
      p_depura ('p_credito.tipo_credito :' || p_credito.tipo_credito);

      OPEN cur_tipo_credito (p_codigo_empresa, p_credito.tipo_credito);

      FETCH cur_tipo_credito
       INTO v_rec_tipo_credito;

      IF cur_tipo_credito%NOTFOUND
      THEN
         pmensajeerror := '000376';
         RETURN;
      END IF;

      CLOSE cur_tipo_credito;

      --

      --p_depura( 'BD calcula_tasa_interes' );

      --
      BEGIN
         calcula_tasa_interes (p_codigo_empresa,
                               p_codigo_agencia,
                               p_credito,
                               pmensajeerror
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            pmensajeerror := 'ERROR Tasa ' || pmensajeerror;
            RETURN;
      END;

      p_depura ('BD MSJ Inserta_Credito: ' || pmensajeerror);

      IF pmensajeerror IS NOT NULL
      THEN
         RETURN;
      END IF;

      --

      --
      p_credito.acumula_intereses := 'S';
      p_credito.revaloriza := 'N';                                    -- Nuevo
      /* API 22/07/2011: Si el tipo de credito es de tiendas y se escoge una cuenta que no

      pertence al cliente, debo esperar aprobacion de la misma antes de pasar a estado 'R'*/

      /*if nvl(p_credito.descuenta_intereses_desembolso,'N') = 'S'

        and p_credito.codigo_cliente <> p_credito.cod_cliente_cta then

            p_credito.estado := 'S';  -- Solicitado = espera por aprobacion de la cuenta.

        else

            p_credito.estado :='R';

      end if;*/
      p_credito.monto_desembolsado := 0;
      p_credito.monto_x_desembolsar := 0;
      p_credito.monto_pagado_principal := 0;
      p_credito.monto_pagado_intereses := 0;
      p_credito.monto_variacion := 0;
      p_credito.intereses_acumulados := 0;
      p_credito.monto_revalorizacion := 0;
      p_credito.intereses_en_suspenso := 0;
      p_credito.intereses_anticipados := 0;
      p_credito.cuota_anterior := p_credito.cuota;
      p_credito.dia_pago := TO_CHAR (p_credito.f_apertura, 'DD');
      p_credito.tasa_original := p_credito.desc_valor_tasa_corrientes;
      p_credito.tipo_abono := NVL (p_credito.tipo_abono, 'I');

      --

      --
      IF     (   p_credito.monto_credito < v_rec_tipo_credito.monto_minimo
              OR p_credito.monto_credito > v_rec_tipo_credito.monto_maximo
             )
         AND p_credito.num_grupo_microcredito IS NULL
      THEN
         pmensajeerror := '000392';
         RETURN;
      END IF;

      --
      p_depura ('p_credito.plazo :' || p_credito.plazo);
      p_depura (   'v_rec_tipo_credito.plazo_minimo :'
                || v_rec_tipo_credito.plazo_minimo
               );
      p_depura (   'v_rec_tipo_credito.plazo_maximo :'
                || v_rec_tipo_credito.plazo_maximo
               );

      --
      IF    p_credito.plazo < v_rec_tipo_credito.plazo_minimo
         OR p_credito.plazo > v_rec_tipo_credito.plazo_maximo
      THEN
         pmensajeerror := '001642';
         RETURN;
      END IF;

      --

      --

      -- API 20/02/2013: Validacion campos de la cotizacion de prestamos de tiendas.
      IF NVL (v_rec_tipo_credito.grupo_tipo_credito, 'X') = 'T'
      THEN
         IF p_credito.no_cotizacion IS NULL
         THEN
            pmensajeerror := '001864';
            RETURN;
         END IF;

         IF p_credito.dir_sucursal IS NULL
         THEN
            pmensajeerror := '001865';
            RETURN;
         END IF;

         IF p_credito.vendedor IS NULL
         THEN
            pmensajeerror := '001866';
            RETURN;
         END IF;

         IF p_credito.mto_inicial_cotizacion IS NULL
         THEN
            pmensajeerror := '001867';
            RETURN;
         END IF;

         IF p_credito.mto_financiado IS NULL
         THEN
            pmensajeerror := '001868';
            RETURN;
         END IF;

         IF p_credito.gastos_cierre IS NULL
         THEN
            pmensajeerror := '001869';
            RETURN;
         END IF;

         IF p_credito.comisionpto15 IS NULL
         THEN
            pmensajeerror := '001870';
            RETURN;
         END IF;

         IF p_credito.neto_pagar IS NULL
         THEN
            pmensajeerror := '001871';
            RETURN;
         END IF;
      END IF;

      --

      --

      -- API 08/10/2009 : Adecuacion para pedir como obligatorio el campo Fecha Proxima Revision para los creditos 26,28,35,36
      IF p_credito.f_proxima_revision IS NULL
      THEN
         vtipcredfecrev :=
            pa_utils.obt_parametros (TO_CHAR (p_codigo_empresa),
                                     'PR',
                                     'TIP_CRED_FEC_REV'
                                    );
         --
         vtipcredfecrev := '|' || vtipcredfecrev || '|';
         --
         vcount :=
                  INSTR (vtipcredfecrev, '|' || p_credito.tipo_credito || '|');

         --
         IF vcount > 0
         THEN
            -- Encontro la ocurrencia del tipo de credito en el array con el listado
            pmensajeerror := '001872';
            RETURN;
         END IF;
      END IF;

      --

      -- API 10/12/2008  (Lperez) Si el Tipo de Credito es Con Garantia de Certificados, validar que hayan sido digitados

      -- los datos obligatorios para este tipo de credito.
      IF NVL (v_rec_tipo_credito.con_garantia_certificado, 'N') = 'S'
      THEN
         /*If p_credito.cuenta_desem Is Null Then

            pmensajeerror              := '001873';

            Return;

         End If;*/ --Portacredit

         --

         /* Este segmento de codigo se  comenta ya que en la forma pr0080 no se

         encuentra de donde se toma el contenido de :variables.total_pignorar

         if nvl(:variables.total_pignorar,0) <> :bkcredit.monto_credito then

             message('El Monto Total a Pignorar debe ser Igual al Monto del Credito.');

             message(' ');

             go_item('pr_garantias.numero_documento');

             raise form_trigger_failure;

         end if; */

         /*If p_credito.cod_notario Is Null Then

            pmensajeerror              := '001874';

            Return;

         End If;*/ --Portacredit
         NULL;
      END IF;

      --
      IF v_rec_tipo_credito.periodo_cuota_extraordinario IS NULL
      THEN
         --
         IF v_rec_tipo_credito.es_cuota_multiple = 'S'
         THEN
            IF NVL (v_rec_tipo_credito.cantidad_cuotas_extra, 0) <= 0
            THEN
               pmensajeerror := '001833';
               RETURN;
            END IF;

            -- El campo no puede ser nulo
            pmensajeerror := '000373';
            RETURN;
         END IF;

         --

         --
         BEGIN
            SELECT dias_periodo
              INTO v_rec_tipo_credito.dias_periodo_extraordinario
              FROM pr_periodicidad
             WHERE codigo_periodo =
                               v_rec_tipo_credito.periodo_cuota_extraordinario;
         EXCEPTION
            WHEN OTHERS
            THEN
               pmensajeerror := '000350';
               RETURN;
         END;
      END IF;

      --
      DBMS_OUTPUT.put_line ('a001 Inserta_Credito');
      --p_depura( p_no_credito );
      consecutivo_credito (p_codigo_empresa,
                           p_codigo_agencia,
                           p_no_credito,
                           pmensajeerror
                          );
      p_depura ('BD MSJConsecutivo_Credito: ' || pmensajeerror);

      IF pmensajeerror IS NOT NULL
      THEN
         pmensajeerror := pmensajeerror;
         RETURN;
      END IF;

      p_credito.no_credito := p_no_credito;

      --

      --p_depura('p_credito.cuota '||p_credito.cuota);

      --
      --BFernandez
      --28/10/2016
      --Que busque el Ejecutivo del Analista
      Begin
         Select Codigo_Persona
           Into p_credito.codigo_ejecutivo
            from pr_analistas p1
            where p1.codigo_empresa  = p_codigo_empresa 
              And p1.codigo_analista = p_credito.codigo_analista;
      Exception
           When NO_DATA_FOUND Then
              NULL;
      End;   
      Begin  
         Update Cliente
            Set Cod_Oficial = p_credito.codigo_ejecutivo
         Where cod_empresa = p_codigo_empresa
           And Cod_Cliente =  TO_CHAR(p_credito.codigo_cliente,'999999999999999');
      Exception
           When OTHERS Then
              NULL;
      End;
      --Fin BFernandez
      -- 
      BEGIN
         --p_depura( 'Inserta_Credito en pr_creditos' );
         DBMS_OUTPUT.put_line ('a002 Inserta_Credito');

         INSERT INTO pr_creditos
                     (codigo_empresa, no_credito, codigo_agencia,
                      codigo_moneda, codigo_cliente,
                      codigo_direccion, tipo_credito,
                      estado, monto_credito,
                      es_linea_credito, tipo_linea,
                      manejo, modalidad_cobro,
                      tipo_intereses, tipo_calendario,
                      tipo_cuota, codigo_periodo_cuota,
                      codigo_periodo_intereses,
                      periodo_comision_normal,
                      comision_normal, cuota,
                      monto_desembolsado,
                      monto_pagado_principal,
                      monto_pagado_intereses,
                      intereses_acumulados,
                      monto_revalorizacion,
                      intereses_en_suspenso,
                      cuota_anterior, plazo,
                      id_sistema_externo, no_solicitud,
                      no_credito_origen, tipo_tasa,
                      codigo_tipo_de_tasa,
                      variacion_base, tasa_interes,
                      tasa_original,
                      codigo_tasa_moratorios,
                      variacion_mora, tasa_moratorios,
                      periodo_revision_tasa,
                      variacion_max_revision,
                      variacion_max_total,
                      gracia_principal, gracia_mora,
                      codigo_origen,
                      no_programa_asociado,
                      codigo_ejecutivo, cobrador,
                      codigo_referente, codigo_analista,
                      codigo_nivel_aprobacion,
                      f_apertura, f_vencimiento,
                      f_cancelacion, f_adjudicacion,
                      f_ultima_revision,
                      f_ultimo_pago_principal,
                      f_ultimo_pago_intereses,
                      f_primer_desembolso,
                      f_ultimo_desembolso,
                      f_proxima_comision, f_aprobacion,
                      f_ultimo_pago_mora,
                      f_reconocim_intereses,
                      f_principal_anterior,
                      f_intereses_anterior,
                      f_mora_anterior,
                      f_ultima_revalorizacion,
                      tipo_abono, cuenta_abono,
                      tipo_desembolso, cuenta_desem,
                      continua_cobro_intereses,
                      dia_pago, marca_rev_tasa,
                      revaloriza, observaciones1,
                      observaciones2, adicionado_por, fecha_adicion,
                      modificado_por, fecha_modificacion,
                      codigo_sub_aplicacion,
                      monto_variacion,
                      codigo_actividad,
                      codigo_subactividad,
                      codigo_calificacion_sistema,
                      codigo_calificacion_manual,
                      observaciones_calificacion,
                      atraso_promedio, tipo_comision,
                      plan_inversion, pais_destino,
                      departamento_destino,
                      municipio_destino,
                      distrito_destino,
                      codigo_sub_clase, tipo_mora,
                      porcentaje_tasa_mora,
                      aprobado_por, codigo_plazo,
                      tasa_original_mora,
                      monto_x_desembolsar,
                      calificado_por,
                      f_ultima_calificacion,
                      plazo_operaciones,
                      permite_sobregiro,
                      porcentaje_sobregiro, f_prorroga,
                      f_ultimo_pago_comision,
                      f_proxima_revision,
                      f_ultima_rev_mora, observaciones3,
                      observaciones4,
                      bloqueo_desembolso, desc_cargos,
                      desc_poliza, desc_cuota,
                      desc_comision, acumula_intereses,
                      variacion_minima,
                      variacion_maxima, tipo_revision,
                      periodos_gracia_principal,
                      f_pago_comision_atrasada,
                      tipo_regreso_cobro,
                      f_pago_cobro_administrativo,
                      base_calculo_moratorios,
                      intereses_anticipados,
                      intereses_antes_cobro_judicial,
                      marca_cobro_administrativo,
                      porc_saldo_no_utilizado,
                      f_ultimo_pago_intereses_venc,
                      f_proxima_mora_flat, renovacion,
                      cod_notario, cliente_prospecto,
                      numero_cf,
                      descuenta_intereses_desembolso,
                      cantidad_cuotas_descontar,
                      no_poliza_bco, ind_pr_vehiculo,
                      cantidad_cobro_cargo,
                      destino_de_fondos, cod_promotor,
                      f_restructuracion,
                      f_restruc_a_vigente,
                      res_apr_inmed, dir_sucursal,
                      mto_inicial_cotizacion,
                      mto_financiado, vendedor,
                      porciento_retencion, neto_pagar,
                      no_cotizacion, gastos_cierre,
                      comisionpto15,
                      int_completivo_acum,
                      num_grupo_microcredito,
                      segregacion_rd, unidad_plazo,
                      plazo_segun_unidad, esvida
                     )
              VALUES (p_codigo_empresa, p_no_credito, p_codigo_agencia,
                      p_credito.codigo_moneda, p_credito.codigo_cliente,
                      p_credito.codigo_direccion, p_credito.tipo_credito,
                      p_credito.estado, p_credito.monto_credito,
                      p_credito.es_linea_credito, p_credito.tipo_linea,
                      p_credito.manejo, p_credito.modalidad_cobro,
                      p_credito.tipo_intereses, p_credito.tipo_calendario,
                      p_credito.tipo_cuota, p_credito.codigo_periodo_cuota,
                      NVL(p_credito.codigo_periodo_intereses,p_credito.codigo_periodo_cuota),
                      NVL(p_credito.periodo_comision_normal,p_credito.codigo_periodo_cuota),
                      p_credito.comision_normal, p_credito.cuota,
                      NVL (p_credito.monto_desembolsado, 0),
                      NVL (p_credito.monto_pagado_principal, 0),
                      NVL (p_credito.monto_pagado_intereses, 0),
                      NVL (p_credito.intereses_acumulados, 0),
                      NVL (p_credito.monto_revalorizacion, 0),
                      NVL (p_credito.intereses_en_suspenso, 0),
                      p_credito.cuota_anterior, p_credito.plazo,
                      p_credito.id_sistema_externo, p_credito.no_solicitud,
                      p_credito.no_credito_origen, p_credito.tipo_tasa,
                      p_credito.codigo_tipo_de_tasa,
                      p_credito.variacion_base, p_credito.tasa_interes,
                      p_credito.tasa_original,
                      p_credito.codigo_tasa_moratorios,
                      p_credito.variacion_mora, p_credito.tasa_moratorios,
                      nvl(p_credito.periodo_revision_tasa,'SE'),
                      p_credito.variacion_max_revision,
                      p_credito.variacion_max_total,
                      p_credito.gracia_principal, p_credito.gracia_mora,
                      p_credito.codigo_origen,
                      p_credito.no_programa_asociado,
                      p_credito.codigo_ejecutivo, p_credito.cobrador,
                      p_credito.codigo_referente, p_credito.codigo_analista,
                      p_credito.codigo_nivel_aprobacion,
                      p_credito.f_apertura, p_credito.f_vencimiento,
                      p_credito.f_cancelacion, p_credito.f_adjudicacion,
                      p_credito.f_ultima_revision,
                      p_credito.f_ultimo_pago_principal,
                      p_credito.f_ultimo_pago_intereses,
                      p_credito.f_primer_desembolso,
                      p_credito.f_ultimo_desembolso,
                      p_credito.f_proxima_comision, p_credito.f_aprobacion,
                      p_credito.f_ultimo_pago_mora,
                      p_credito.f_reconocim_intereses,
                      p_credito.f_principal_anterior,
                      p_credito.f_intereses_anterior,
                      p_credito.f_mora_anterior,
                      p_credito.f_ultima_revalorizacion,
                      p_credito.tipo_abono, p_credito.cuenta_abono,
                      p_credito.tipo_desembolso, p_credito.cuenta_desem,
                      p_credito.continua_cobro_intereses,
                      p_credito.dia_pago, p_credito.marca_rev_tasa,
                      p_credito.revaloriza, p_credito.observaciones1,
                      p_credito.observaciones2, USER, SYSDATE,
                      NULL, NULL,
                      p_credito.codigo_sub_aplicacion,
                      NVL (p_credito.monto_variacion, 0),
                      p_credito.codigo_actividad,
                      p_credito.codigo_subactividad,
                      p_credito.codigo_calificacion_sistema,
                      p_credito.codigo_calificacion_manual,
                      p_credito.observaciones_calificacion,
                      p_credito.atraso_promedio, p_credito.tipo_comision,
                      p_credito.plan_inversion, p_credito.pais_destino,
                      p_credito.departamento_destino,
                      p_credito.municipio_destino,
                      p_credito.distrito_destino,
                      p_credito.codigo_sub_clase, p_credito.tipo_mora,
                      p_credito.porcentaje_tasa_mora,
                      p_credito.aprobado_por, p_credito.codigo_plazo,
                      p_credito.tasa_original_mora,
                      NVL (p_credito.monto_x_desembolsar, 0),
                      p_credito.calificado_por,
                      p_credito.f_ultima_calificacion,
                      p_credito.plazo_operaciones,
                      p_credito.permite_sobregiro,
                      p_credito.porcentaje_sobregiro, p_credito.f_prorroga,
                      p_credito.f_ultimo_pago_comision,
                      p_credito.f_proxima_revision,
                      p_credito.f_ultima_rev_mora, p_credito.observaciones3,
                      p_credito.observaciones4,
                      p_credito.bloqueo_desembolso, NVL(p_credito.desc_cargos,'S'),
                      NVL(p_credito.desc_poliza,'S'), NVL(p_credito.desc_cuota,'S'),
                      NVL(p_credito.desc_comision,'S'), p_credito.acumula_intereses,
                      p_credito.variacion_minima,
                      p_credito.variacion_maxima, p_credito.tipo_revision,
                      p_credito.periodos_gracia_principal,
                      p_credito.f_pago_comision_atrasada,
                      p_credito.tipo_regreso_cobro,
                      p_credito.f_pago_cobro_administrativo,
                      p_credito.base_calculo_moratorios,
                      NVL (p_credito.intereses_anticipados, 0),
                      p_credito.intereses_antes_cobro_judicial,
                      p_credito.marca_cobro_administrativo,
                      p_credito.porc_saldo_no_utilizado,
                      p_credito.f_ultimo_pago_intereses_venc,
                      p_credito.f_proxima_mora_flat, p_credito.renovacion,
                      p_credito.cod_notario, p_credito.cliente_prospecto,
                      p_credito.numero_cf,
                      p_credito.descuenta_intereses_desembolso,
                      p_credito.cantidad_cuotas_descontar,
                      p_credito.no_poliza_bco, p_credito.ind_pr_vehiculo,
                      p_credito.cantidad_cobro_cargo,
                      p_credito.destino_de_fondos, p_credito.cod_promotor,
                      p_credito.f_restructuracion,
                      p_credito.f_restruc_a_vigente,
                      p_credito.res_apr_inmed, p_credito.dir_sucursal,
                      p_credito.mto_inicial_cotizacion,
                      p_credito.mto_financiado, p_credito.vendedor,
                      p_credito.porciento_retencion, p_credito.neto_pagar,
                      p_credito.no_cotizacion, p_credito.gastos_cierre,
                      p_credito.comisionpto15,
                      p_credito.int_completivo_acum,
                      p_credito.num_grupo_microcredito,
                      p_credito.segregacion_rd, 'M',
                      /*(p_credito.plazo / 30)*/   --malmanzar 10-05-2018
                      p_credito.plazo_segun_unidad, 'S'
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_application_error (num      => -20000,
                                     msg      =>    'Error en Inserta_Credito:'
                                                 || SQLERRM
                                    );
            RETURN;
      END;

      DBMS_OUTPUT.put_line ('a003 Inserta_Credito');
      --
      p_depura ('inserta cuenta_cliente_relacion');

      --
      INSERT INTO cuenta_cliente_relacion
                  (num_cuenta, codigo_cliente, tipo_relacion, principal,
                   cod_sistema, estado, numero_linea
                  )
           VALUES (p_no_credito, p_credito.codigo_cliente, NULL, 'S',
                   'PR', NULL, 1
                  );

      --LMVR
      IF p_credito.codigo_clienteco IS NOT NULL
      THEN
         INSERT INTO cuenta_cliente_relacion
                     (num_cuenta, codigo_cliente,
                      tipo_relacion, principal, cod_sistema, estado,
                      numero_linea
                     )
              VALUES (p_no_credito, p_credito.codigo_clienteco,
                      p_credito.codigo_relacionco, 'N', 'PR', NULL,
                      2
                     );
      END IF;

      --LMVR
      BEGIN
         INSERT INTO pr_cond_x_creditos
                     (codigo_empresa, no_credito, codigo_condicion, estado,
                      adicionado_por, fecha_adicion, modificado_por,
                      fecha_modificacion)
            SELECT codigo_empresa, p_no_credito, codigo_condicion, 'R', USER,
                   SYSDATE, NULL, NULL
              FROM pr_cond_x_tipo_credito
             WHERE codigo_empresa = p_codigo_empresa
               AND tipo_credito = p_credito.tipo_credito;

         --
         p_depura ('pr_cond_x_creditos');
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      --
      BEGIN
         INSERT INTO pr_req_x_creditos
                     (codigo_empresa, no_credito, codigo_requisito, estado,
                      obligatorio, adicionado_por, fecha_adicion,
                      modificado_por, fecha_modificacion, f_vencimiento,
                      autorizado_por)
            SELECT codigo_empresa, p_no_credito, codigo_requisito, 'P',
                   obligatorio, USER, SYSDATE, NULL, NULL, NULL, NULL
              FROM pr_req_x_tipo_credito
             WHERE codigo_empresa = p_codigo_empresa
               AND tipo_credito = p_credito.tipo_credito;

         --
         p_depura ('pr_req_x_creditos');
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      --
      BEGIN
         FOR i IN (SELECT   codigo_cargo, tipo_cargo, monto_cargo,
                            monto_minimo, monto_maximo, tipo_cobro,
                            codigo_tipo_transaccion, codigo_periodo
                       FROM pr_cargos_x_tipo_credito ctc
                      WHERE codigo_empresa = p_codigo_empresa
                        AND tipo_credito = p_credito.tipo_credito
                        AND codigo_cargo != NVL(param.parametro_x_empresa (p_codigo_empresa,
                                                                           'COD_CARGO_LEY288',
                                                                           'PR'
                                                                           ),-1)
                        AND NOT EXISTS (
                               SELECT *
                                 FROM pr_cargos_x_credito
                                WHERE codigo_empresa = ctc.codigo_empresa
                                  AND no_credito = p_no_credito
                                  AND codigo_cargo = ctc.codigo_cargo)
                   ORDER BY codigo_cargo, codigo_tipo_transaccion)
         LOOP
            SELECT monto_credito
              INTO vmonto
              FROM pr_creditos
             WHERE no_credito = p_no_credito;

            BEGIN
               SELECT monto_cargo, monto_minimo, monto_maximo
                 INTO vmonto_cargo, vmonto_minimo, vmonto_maximo
                 FROM pr_rangos_x_cargo_x_tc
                WHERE cod_empresa = p_codigo_empresa   --'1'--p_codigo_empresa
                  AND tipo_credito = p_credito.tipo_credito
                  --vtipo_credito--'0'--p_tipo_credito
                  AND codigo_cargo = i.codigo_cargo     --'50'--p_codigo_cargo
                  --and p_codigo_tipo_transaccion = p_codigo_tipo_transaccion
                  AND vmonto BETWEEN monto_credito_inferior
                                 AND monto_credito_superior;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  vmonto_cargo := i.monto_cargo;
                  vmonto_minimo := i.monto_minimo;
                  vmonto_maximo := i.monto_maximo;
            END;

            --BFernandez 20/04/2016
            --Calcular el monto del cargo
            /*IF i.tipo_cargo = 'P'
            THEN
               vmonto_calculado := (NVL (vmonto, 0) * (vmonto_cargo / 100));
            ELSE
               vmonto_calculado := vmonto_cargo;
            END IF;*/

            INSERT INTO pr_cargos_x_credito
                        (codigo_empresa, no_credito, codigo_cargo,
                         codigo_tipo_transaccion, tipo_cargo,
                         monto_cargo, monto_minimo, monto_maximo,
                         tipo_cobro, codigo_periodo, adicionado_por,
                         fecha_adicion, modificado_por, fecha_modificacion,
                         f_ultima_generacion
                        )
                 VALUES (p_codigo_empresa, p_no_credito, i.codigo_cargo,
                         i.codigo_tipo_transaccion, i.tipo_cargo,
                         vmonto_cargo, vmonto_minimo, vmonto_maximo,
                         i.tipo_cobro, i.codigo_periodo, USER,
                         SYSDATE, NULL, NULL,
                         NULL
                        );
         END LOOP;

         --
         p_depura ('pr_cargos_x_credito');
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      --
      BEGIN
         /*Insert Into pr_polizas_x_credito

                  ( codigo_empresa, no_credito, tipo_poliza, numero_poliza,

                    monto_a_pagar, monto_seguro, fecha_ultimo_pago, identificacion,

                    adicionado_por, fecha_adicion, modificado_por, fecha_modificacion,

                    modalidad_poliza, codigo_periodo, f_ultima_generacion, tipo_cobro,

                    cuota_inicial, inclusion_manual, codigo_modalidad )

         Select codigo_empresa,

                p_no_credito,

                tipo_poliza,

                numero_poliza,

                monto_minimo,

                Null,

                Null,

                Null,

                User,

                Sysdate,

                Null,

                Null,

                Null,

                Null,

                Null,

                Null,

                Null,

                Null,

                Null

           From pr_polizas_x_tipo_credito

          Where codigo_empresa = p_codigo_empresa

            And tipo_credito = p_credito.tipo_credito;*/
            
        Declare
        vncodeudor Number := null;
        Begin    
         pkg_polizas.agrega_poliza (pempresa           => p_codigo_empresa,
                                    pcredito           => p_no_credito,
                                    pfecha             => p_credito.f_apertura,
                                    --Sysdate,
                                    pesvida            => 'S',
                                    pesvehiculo        => 'N',
                                    pesincendio        => 'N',
                                    pEsIncendioPy      => 'N',  ---REQ_59191_Seguro_Insendio_Pymes >> Nuevo Parámetro
                                    pmensajeerror      => cmensaje,
                                    pcodeudor          => vncodeudor,
                                    pAccion            => 'I', --C = Solo cálculo, I = Calcula e inserta
                                    pTipoPoliza        => null,
                                    pMontoCalculo      => vmonto_calculo   
                                   );
        End;                           
         p_depura ('pr_polizas_x_credito ' || cmensaje);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      DBMS_OUTPUT.put_line ('Finaliza Inserta_Credito');
   EXCEPTION
      WHEN exerror
      THEN
         DBMS_OUTPUT.put_line ('exerror Inserta_Credito');
         -- Error generando el registro de credito
         RETURN;
      WHEN OTHERS
      THEN
         -- Error generando el registro de credito
         DBMS_OUTPUT.put_line ('error 001817 Inserta_Credito');
         p_depura ('JMM ' || SQLERRM);
         pmensajeerror := '001817 ';                             --||sqlerrm;
         --                pMensajeError :=  sqlerrm;
         RETURN;
   END inserta_credito;

   --

   --
   PROCEDURE inserta_microcredito (
      p_codigo_empresa            NUMBER,
      p_codigo_agencia            NUMBER,
      p_tipo_credito              NUMBER,
      p_num_grupo                 NUMBER,
      p_codidioma                 VARCHAR2,
      p_no_credito       IN OUT   NUMBER,
      pmensajeerror      IN OUT   VARCHAR2
   )
   IS
      --

      -- Variables locales
      rec_pr_creditos         t_rec_pr_creditos;    -- Variable tipo registro
      v_desc_ejecutivo        VARCHAR2 (500);
      v_desc_actividad        VARCHAR2 (500);
      v_agencia_labora        VARCHAR2 (100);
      v_desc_plan_inversion   VARCHAR2 (500);
   BEGIN
      p_depura ('rec_pr_creditos.f_apertura');
      rec_pr_creditos.f_apertura :=
           fecha_actual_calendario ('PR', p_codigo_empresa, p_codigo_agencia);
      p_depura ('pr_tipo_credito ptc,pr_parametros_microcredito ppm');

      BEGIN
         SELECT ptc.codigo_moneda, ptc.tipo_credito,
                ptc.es_linea_credito,
                ptc.tipo_linea, ptc.manejo,
                ptc.modalidad_cobro,
                ptc.tipo_intereses,
                ptc.tipo_calendario,
                ptc.periodo_comision_normal,
                ptc.comision_normal, ptc.tipo_tasa,
                ptc.codigo_tipo_de_tasa,
                ptc.variacion_base,
                ptc.tasa_interes,
                ptc.codigo_tasa_moratorios,
                ptc.variacion_mora,
                ptc.tasa_moratorios,
                ptc.gracia_principal,
                ptc.gracia_mora, ptc.codigo_origen,
                ptc.continua_cobro_intereses,
                ptc.dia_pago, ptc.revaloriza,
                ptc.codigo_sub_aplicacion,
                ptc.tipo_comision, ptc.tipo_mora,
                ptc.porcentaje_tasa_mora,
                ppm.plazo,
                ptc.permite_sobregiro,
                ptc.porcentaje_sobregiro,
                ptc.variacion_minima,
                ptc.variacion_maxima,
                ptc.periodos_gracia_principal,
                ptc.base_calculo_moratorios,
                ptc.descuenta_intereses_desembolso,
                ptc.cantidad_cuotas_descontar,
                ptc.ind_pr_vehiculo,
                (SELECT dias_periodo
                   FROM pr_periodicidad pp
                  WHERE pp.codigo_periodo = ppm.frecuencia_pago)
                                                              frecuencia_pago,
                (SELECT ptp.plazo_maximo
                   FROM pr_tipos_plazos ptp
                  WHERE ptp.codigo_plazo = ppm.plazo), 'C' tipo_desembolso,
                0 codigo_actividad,
                0 codigo_subactividad,
                0 codigo_sub_clase,
                ppm.frecuencia_pago codigo_periodo_cuota,
                ppm.frecuencia_pago codigo_periodo_interes,
                ppm.frecuencia_pago periodo_comision_normal
           INTO rec_pr_creditos.codigo_moneda, rec_pr_creditos.tipo_credito,
                rec_pr_creditos.es_linea_credito,
                rec_pr_creditos.tipo_linea, rec_pr_creditos.manejo,
                rec_pr_creditos.modalidad_cobro,
                rec_pr_creditos.tipo_intereses,
                rec_pr_creditos.tipo_calendario,
                rec_pr_creditos.periodo_comision_normal,
                rec_pr_creditos.comision_normal, rec_pr_creditos.tipo_tasa,
                rec_pr_creditos.codigo_tipo_de_tasa,
                rec_pr_creditos.variacion_base,
                rec_pr_creditos.tasa_interes,
                rec_pr_creditos.codigo_tasa_moratorios,
                rec_pr_creditos.variacion_mora,
                rec_pr_creditos.tasa_moratorios,
                rec_pr_creditos.gracia_principal,
                rec_pr_creditos.gracia_mora, rec_pr_creditos.codigo_origen,
                rec_pr_creditos.continua_cobro_intereses,
                rec_pr_creditos.dia_pago, rec_pr_creditos.revaloriza,
                rec_pr_creditos.codigo_sub_aplicacion,
                rec_pr_creditos.tipo_comision, rec_pr_creditos.tipo_mora,
                rec_pr_creditos.porcentaje_tasa_mora,
                rec_pr_creditos.codigo_plazo,
                rec_pr_creditos.permite_sobregiro,
                rec_pr_creditos.porcentaje_sobregiro,
                rec_pr_creditos.variacion_minima,
                rec_pr_creditos.variacion_maxima,
                rec_pr_creditos.periodos_gracia_principal,
                rec_pr_creditos.base_calculo_moratorios,
                rec_pr_creditos.descuenta_intereses_desembolso,
                rec_pr_creditos.cantidad_cuotas_descontar,
                rec_pr_creditos.ind_pr_vehiculo,
                rec_pr_creditos.dias_periodo_cuota,
                rec_pr_creditos.plazo, rec_pr_creditos.tipo_desembolso,
                rec_pr_creditos.codigo_actividad,
                rec_pr_creditos.codigo_subactividad,
                rec_pr_creditos.codigo_sub_clase,
                rec_pr_creditos.codigo_periodo_cuota,
                rec_pr_creditos.codigo_periodo_intereses,
                rec_pr_creditos.periodo_comision_normal
           FROM pr_tipo_credito ptc, pr_parametros_microcredito ppm
          WHERE ptc.codigo_empresa = p_codigo_empresa
            AND ptc.tipo_credito = p_tipo_credito
            AND ptc.ind_micro_credito = 'S'
            AND ppm.codigo_empresa = ptc.codigo_empresa
            AND ppm.tipo_credito = ptc.tipo_credito;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            pmensajeerror := '000376';
      END;

      rec_pr_creditos.estado := 'R';
      rec_pr_creditos.tipo_cuota := 'N';
      rec_pr_creditos.f_vencimiento :=
                            rec_pr_creditos.f_apertura + rec_pr_creditos.plazo;
      p_depura ('microcredito');

      FOR microcredito IN (SELECT pdgm.codigo_cliente, pdgm.monto,
                                  pgm.num_grupo, pdgm.cuenta_desem
                             FROM pr_grupo_microcredito pgm,
                                  pr_detalle_grupo_microcredito pdgm
                            WHERE pgm.codigo_empresa = p_codigo_empresa
                              AND pgm.num_grupo = p_num_grupo
                              AND pgm.tipo_credito = p_tipo_credito
                              AND pdgm.codigo_empresa = pgm.codigo_empresa
                              AND pdgm.num_grupo = pgm.num_grupo)
      LOOP
         rec_pr_creditos.codigo_cliente := microcredito.codigo_cliente;
         rec_pr_creditos.monto_credito := microcredito.monto;
         rec_pr_creditos.num_grupo_microcredito := microcredito.num_grupo;
         rec_pr_creditos.cuenta_desem := microcredito.cuenta_desem;
         --
         p_depura ('Obtiene_PlanInversion');
         --
         obtiene_planinversion (p_codigo_empresa,
                                p_codidioma,
                                rec_pr_creditos.plan_inversion,
                                v_desc_plan_inversion
                               );
         --
         p_depura ('Busca_Extras_Cliente');
         --
         busca_extras_cliente (p_codigo_empresa,
                               rec_pr_creditos.codigo_actividad,
                               microcredito.codigo_cliente,
                               v_desc_ejecutivo,
                               v_desc_ejecutivo,
                               v_desc_actividad,
                               v_agencia_labora,
                               --FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA
                               rec_pr_creditos,
                               p_codidioma
                              );
         --
         p_depura ('Inserta_Credito');
         --
         inserta_credito (p_codigo_empresa,
                          p_codigo_agencia,
                          rec_pr_creditos.no_credito,
                          rec_pr_creditos,
                          pmensajeerror
                         );
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         pmensajeerror := '000956';
   END;

   --
   PROCEDURE consecutivo_credito (
      p_codigo_empresa   IN       VARCHAR2,
      p_codigo_agencia   IN       VARCHAR2,
      p_consecutivo      IN OUT   NUMBER,
      p_mensaje          IN OUT   VARCHAR2
   )
   IS
      v_consec       NUMBER;
      v_no_secuenc   NUMBER;
      v_dummy        NUMBER;
   BEGIN
      --
      p_mensaje := NULL;

      --
      BEGIN
         BEGIN
            SELECT no_secuencia
              INTO v_no_secuenc
              FROM pr_parametros
             WHERE codigo_empresa = TO_NUMBER (p_codigo_empresa);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_mensaje := '000043';                  -- Error PR_Parametros
               RETURN;
         END;

         --
         IF (v_no_secuenc = 1)
         THEN
            SELECT creditos_bpr_001.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 2)
         THEN
            SELECT creditos_bpr_002.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 3)
         THEN
            SELECT creditos_bpr_003.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 4)
         THEN
            SELECT creditos_bpr_004.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 5)
         THEN
            SELECT creditos_bpr_005.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 6)
         THEN
            SELECT creditos_bpr_006.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 7)
         THEN
            SELECT creditos_bpr_007.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 8)
         THEN
            SELECT creditos_bpr_008.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 9)
         THEN
            SELECT creditos_bpr_009.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         ELSIF (v_no_secuenc = 10)
         THEN
            SELECT creditos_bpr_010.NEXTVAL
              INTO v_consec
              FROM SYS.DUAL;
         END IF;

         --
         SELECT COUNT ('x')
           INTO v_dummy
           FROM pr_creditos
          WHERE codigo_empresa = TO_NUMBER (p_codigo_empresa)
            AND no_credito = v_consec;

         --
         IF (v_dummy > 0)
         THEN
            p_mensaje := '000044';                     --El Credito ya existe
            RETURN;
         ELSE
            SELECT COUNT ('x')
              INTO v_dummy
              FROM pr_creditos_hi
             WHERE codigo_empresa = TO_NUMBER (p_codigo_empresa)
               AND no_credito = v_consec;

            IF (v_dummy > 0)
            THEN
               p_mensaje := '000045';    --El Credito ya existe en Historicos
               RETURN;
            END IF;
         END IF;

         p_consecutivo := v_consec;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_mensaje := '000032';
   END;

   --

   --
   PROCEDURE determina_dias_de_trabajo (
      p_codigo_empresa    IN       VARCHAR2,
      p_codigo_agencia    IN       VARCHAR2,
      p_trabaja_sabado    IN OUT   BOOLEAN,
      p_trabaja_domingo   IN OUT   BOOLEAN
   )
   IS
   BEGIN
      DECLARE
         agencia_central   agencias.codigo_agencia%TYPE;
         indsabado         VARCHAR2 (1);
         inddomingo        VARCHAR2 (1);
      BEGIN
         BEGIN
            SELECT codigo_agencia, trabaja_sab, trabaja_dom
              INTO agencia_central, indsabado, inddomingo
              FROM agencias
             WHERE codigo_empresa = p_codigo_empresa
               AND codigo_agencia = p_codigo_agencia;
         EXCEPTION
            WHEN NO_DATA_FOUND                                   -- No trabaja
            THEN
               p_trabaja_sabado := FALSE;
               p_trabaja_domingo := FALSE;
         END;

         IF (indsabado = 'S')
         THEN
            p_trabaja_sabado := TRUE;
         ELSE
            p_trabaja_sabado := FALSE;
         END IF;

         IF (inddomingo = 'S')
         THEN
            p_trabaja_domingo := TRUE;
         ELSE
            p_trabaja_domingo := FALSE;
         END IF;
      END;
   END;

   --

   --
   PROCEDURE calcula_tasa_interes (
      p_codigo_empresa            NUMBER,
      p_codigo_agencia            NUMBER,
      p_credito          IN OUT   t_rec_pr_creditos,
      pmensajeerror      IN OUT   VARCHAR2
   )
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('p_codigo_empresa=' || p_codigo_empresa);
      DBMS_OUTPUT.put_line ('p_codigo_agencia=' || p_codigo_agencia);
      DBMS_OUTPUT.put_line (   'p_credito.codigo_tipo_de_tasa='
                            || p_credito.codigo_tipo_de_tasa
                           );
      DBMS_OUTPUT.put_line (   ' p_credito.f_apertura='
                            || TO_CHAR (p_credito.f_apertura, 'dd/mm/yyyy')
                           );
      p_depura (   'p_credito.codigo_tipo_de_tasa='
                || p_credito.codigo_tipo_de_tasa
               );
      p_depura ('p_credito.CODIGO_EMPRESA ' || p_credito.codigo_empresa);
      p_depura ('p_credito.CODIGO_AGENCIA ' || p_credito.codigo_agencia);
      p_depura (   ' p_credito.f_apertura='
                || fecha_actual_calendario ('PR',
                                            p_credito.codigo_empresa,
                                            p_credito.codigo_agencia
                                           )
               );
      p_depura (   ' p_credito.f_apertura2='
                || fecha_actual_calendario ('PR', '1', '50')
               );
      p_depura (   ' p_credito.f_apertura3='
                || TO_DATE ('18/12/2015', 'dd/mm/yyyy')
               );

      BEGIN
         SELECT a.mnemonico,
                b.porcentaje,
                a.variacion_min,
                a.variacion_max
           INTO p_credito.desc_tasa_interes_base,
                p_credito.desc_valor_tasa_corrientes,
                p_credito.variacion_min_interes,
                p_credito.variacion_max_interes
           FROM tipos_de_tasas_de_interes a, valores_de_tasas_de_interes b
          WHERE a.codigo_tipo_de_tasa = b.codigo_tipo_de_tasa
            AND b.codigo_empresa = p_codigo_empresa
            AND a.codigo_tipo_de_tasa = p_credito.codigo_tipo_de_tasa
            AND b.fecha_inicio =
                   (SELECT MAX (fecha_inicio)
                      FROM valores_de_tasas_de_interes
                     WHERE codigo_empresa = p_codigo_empresa
                       AND codigo_tipo_de_tasa = a.codigo_tipo_de_tasa
                       AND fecha_inicio <=
                              fecha_actual_calendario
                                                    ('PR',
                                                     p_credito.codigo_empresa,
                                                     p_credito.codigo_agencia
                                                    ));

         --p_credito.f_apertura--to_date('18/12/2015','dd/mm/yyyy')
         p_depura ('consulta tasa de interes ' || SQLERRM);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- ERROR: La Tasa Base de Intereses Corrientes no existe
            pmensajeerror := '001024';
            p_credito.desc_tasa_interes_base := NULL;
            p_credito.desc_valor_tasa_corrientes := NULL;
            RETURN;
         WHEN TOO_MANY_ROWS
         THEN
            -- ERROR: La Tasa Base de Intereses Corrientes esta duplicada
            pmensajeerror := '001025';
            p_credito.desc_tasa_interes_base := NULL;
            p_credito.desc_valor_tasa_corrientes := NULL;
            RETURN;
         WHEN OTHERS
         THEN
            pmensajeerror := SQLERRM;
            p_depura ('error others ' || SQLERRM);
            p_credito.desc_tasa_interes_base := NULL;
            p_credito.desc_valor_tasa_corrientes := NULL;
            RETURN;
      END;

      p_credito.variacion_base := NVL (p_credito.variacion_base, 0);
      p_credito.tasa_interes :=
               p_credito.desc_valor_tasa_corrientes + p_credito.variacion_base;

      IF p_credito.tipo_mora = 1
      THEN
         /*p_credito.porcentaje_tasa_mora := 0;

         If p_credito.codigo_tasa_moratorios Is Null Then

            p_credito.codigo_tasa_moratorios := p_credito.codigo_tipo_de_tasa;

            p_credito.desc_tasa_mora_base := p_credito.desc_tasa_interes_base;

            p_credito.desc_valor_tasa_moratorios := p_credito.desc_valor_tasa_corrientes;

            p_credito.variacion_mora   := p_credito.variacion_base;

         End If;

         p_credito.tasa_moratorios  :=

              Nvl( p_credito.desc_valor_tasa_moratorios, 0 )

            + Nvl( p_credito.variacion_mora, 0 );*/
         SELECT b.porcentaje
           INTO p_credito.tasa_original_mora      --Desc_Valor_Tasa_Moratorios
           FROM tipos_de_tasas_de_interes a, valores_de_tasas_de_interes b
          WHERE a.codigo_tipo_de_tasa = b.codigo_tipo_de_tasa
            AND b.codigo_empresa = p_codigo_empresa
            AND a.codigo_tipo_de_tasa = p_credito.codigo_tasa_moratorios
            AND b.fecha_inicio =
                   (SELECT MAX (fecha_inicio)
                      FROM valores_de_tasas_de_interes
                     WHERE codigo_empresa = p_codigo_empresa
                       AND codigo_tipo_de_tasa = a.codigo_tipo_de_tasa
                       AND fecha_inicio <=
                              fecha_actual_calendario
                                                    ('PR',
                                                     p_credito.codigo_empresa,
                                                     p_credito.codigo_agencia
                                                    ));

--p_credito.F_APERTURA--to_date(to_char(p_credito.f_apertura,'dd/mm/yyyy'),'dd/mon/yyyy')
         p_credito.desc_valor_tasa_moratorios := p_credito.tasa_original_mora;
         p_credito.tasa_moratorios :=
              NVL (p_credito.desc_valor_tasa_moratorios, 0)
            + NVL (p_credito.variacion_mora, 0);
      ELSE
         IF NVL (p_credito.porcentaje_tasa_mora, 0) = 0
         THEN
            p_credito.porcentaje_tasa_mora := 0;
         END IF;

         p_credito.codigo_tasa_moratorios := NULL;
         p_credito.desc_tasa_mora_base := NULL;
         p_credito.desc_valor_tasa_moratorios := NULL;
         p_credito.variacion_mora :=
              NVL (p_credito.tasa_interes, 0)
            * (NVL (p_credito.porcentaje_tasa_mora, 0) / 100);
         p_credito.tasa_moratorios :=
            NVL (p_credito.tasa_interes, 0)
            + NVL (p_credito.variacion_mora, 0);
      END IF;

      --

      --      Begin

      --         p_depura( 'JMM**' || p_codigo_empresa || '*' || p_credito.no_credito || '*' || p_credito.f_apertura || '*' ||

      --                        p_credito.f_vencimiento  || '*' ||  p_credito.gracia_principal  || '*' ||

      --                        p_credito.monto_credito  || '*' ||  p_credito.tipo_cuota  || '*' ||

      --                        p_credito.dias_periodo_cuota  || '*' ||  p_credito.tasa_interes || '*' ||

      --                        p_credito.tipo_intereses || '*' ||  p_credito.tipo_calendario || '*' ||

      --                        p_credito.plazo || '*' ||  p_credito.f_apertura || '*' ||

      --                        p_credito.cuota || '*' ||  pmensajeerror );

      -- JMM**1**10-DEC-15**0**N**36.2*V*4**10-DEC-15**

      --p_credito.cuota := CUOTAPRESTAMOCAL;

      --         calcula_cuota( p_codigo_empresa, p_credito.no_credito, p_credito.f_apertura,

      --                        p_credito.f_vencimiento, p_credito.gracia_principal,

      --                        p_credito.monto_credito, p_credito.tipo_cuota,

      --                        p_credito.dias_periodo_cuota, p_credito.tasa_interes,

      --                        p_credito.tipo_intereses, p_credito.tipo_calendario,

      --                        p_credito.plazo, p_credito.f_apertura, True, True,

      --                        p_credito.cuota, pmensajeerror );

      --      Exception

      --         When Others Then

      --         p_depura( 'JMM2**' || p_codigo_empresa || '*' || p_credito.no_credito || '*' || p_credito.f_apertura || '*' ||

      --                        p_credito.f_vencimiento  || '*' ||  p_credito.gracia_principal  || '*' ||

      --                        p_credito.monto_credito  || '*' ||  p_credito.tipo_cuota  || '*' ||

      --                        p_credito.dias_periodo_cuota  || '*' ||  p_credito.tasa_interes || '*' ||

      --                        p_credito.tipo_intereses || '*' ||  p_credito.tipo_calendario || '*' ||

      --                        p_credito.plazo || '*' ||  p_credito.f_apertura || '*' ||

      --                        p_credito.cuota || '*' ||  pmensajeerror );

      --            pmensajeerror              := 'Error calcula cuota';

      --      End;
      IF pmensajeerror IS NOT NULL
      THEN
         RETURN;
      END IF;
   END calcula_tasa_interes;

   --
   PROCEDURE calcula_cuota (
      -- del credito
      p_codigo_empresa         IN       NUMBER,
      p_no_credito             IN       NUMBER,
      p_f_primer_desem         IN       DATE,
      p_f_vencimiento          IN       DATE,
      p_gracia_principal       IN       NUMBER,                     -- en dias
      p_saldo_real             IN       NUMBER,
      p_tipo_cuota             IN       VARCHAR2,
      p_periodicidad           IN       NUMBER,
      -- cantidad dias periodic. de interes
      p_tasa                   IN       NUMBER,  -- porcentaje (23, 27.5, etc)
      p_tipo_interes           IN       VARCHAR2,  -- (V)encido o (A)nticipado
      p_tipo_calendario        IN       NUMBER,   -- tipos de cal: 1, 2, 3 o 4
      p_plazo_total            IN       NUMBER,                     -- en dias
      -- especificos
      p_f_calculo              IN       DATE,
      p_con_saldo_teorico      IN       BOOLEAN,
      p_con_gracia_principal   IN       BOOLEAN,
      -- salida
      p_cuota                  IN OUT   NUMBER,
      p_msj_error              IN OUT   VARCHAR2
   )
   IS
      -- OJO: las variables que siguien se dejan como number; para

      -- hacer el calculo con toda la mantiza decimal, y asi evitar

      -- errores de redondeo
      v_tasa_periodo         NUMBER;
      v_subtot1              NUMBER;
      v_subtot2              NUMBER;
      --
      v_f_gracia_hasta       DATE;
      v_cuota                pr_creditos.cuota%TYPE;
      v_periodos             NUMBER (10);
      v_interes              NUMBER (16, 2);
      v_cal_base_calculo     NUMBER (5);
      v_cal_intereses        NUMBER (5);
      v_plazo_restante       NUMBER (10);
      v_saldo_teorico        NUMBER (22, 2);
      v_principal_atrasado   NUMBER (22, 2);
      v_periodicidad         NUMBER;
      v_dias_naturales       NUMBER;
   BEGIN
      p_msj_error := 'base calculo';
      --

      -- Se determinan los calendarios para los dias interes y para

      -- la base del calculo
      v_cal_base_calculo := 360;
      v_cal_intereses := 360;

      IF (p_tipo_calendario IN (1, 2))
      THEN
         -- base calculo natural
         v_cal_base_calculo := 365;
      END IF;

      IF (p_tipo_calendario IN (1, 4))
      THEN
         -- dias interes natural
         v_cal_intereses := 365;
      END IF;

      --

      -- Calcula el plazo restante
      p_msj_error := 'agregar dias';                               -- mg_debug
      p_depura (   'agregar dias '
                || p_f_primer_desem
                || '*'
                || TRUNC (SYSDATE)
                || '*'
                || p_gracia_principal
                || '*360*'
                || '*'
                || v_f_gracia_hasta
                || '*'
                || p_msj_error
               );
      agregar_dias (NVL (p_f_primer_desem, TRUNC (SYSDATE)),
                    p_gracia_principal,
                    360,
                    v_f_gracia_hasta,
                    p_msj_error
                   );

      IF (p_msj_error IS NOT NULL)
      THEN
         RETURN;
      END IF;

      --
      IF (p_con_gracia_principal AND v_f_gracia_hasta > p_f_calculo)
      THEN
         -- si la fecha del calculo esta en el periodo gracia, se toma

         -- la fecha de gracia hasta
         restar_fechas (p_f_vencimiento,
                        v_f_gracia_hasta,
                        v_cal_intereses,
                        v_plazo_restante,
                        p_msj_error
                       );

         IF (p_msj_error IS NOT NULL)
         THEN
            RETURN;
         END IF;
      ELSE
         -- si no toma la fecha de calculo
         restar_fechas (p_f_vencimiento,
                        p_f_calculo,
                        v_cal_intereses,
                        v_plazo_restante,
                        p_msj_error
                       );

         IF (p_msj_error IS NOT NULL)
         THEN
            RETURN;
         END IF;
      END IF;

      IF v_cal_intereses = 365
      THEN
         SELECT dias_periodo_cal_nat
           INTO v_dias_naturales
           FROM pr_periodicidad
          WHERE dias_periodo = p_periodicidad;

         v_periodicidad := v_dias_naturales;
      ELSE
         v_periodicidad := p_periodicidad;
      END IF;

      v_periodos := ROUND (v_plazo_restante / v_periodicidad);

      IF (v_periodos = 0)
      THEN
         v_periodos := 1;
      END IF;

      p_msj_error := 'tasa periodo';
      v_tasa_periodo := ((p_tasa / 100) / v_cal_base_calculo) * v_periodicidad;
      --
      p_msj_error := 'saldo teorico';

      -- Si se desea hacer el calculo considerando el saldo teorico, se

      -- calcula el principal atrasado y se resta al saldo real.
      IF (p_con_saldo_teorico)
      THEN
         BEGIN
            SELECT NVL (SUM (NVL (saldo_principal, 0)), 0)
              INTO v_principal_atrasado
              FROM pr_plan_pagos
             WHERE codigo_empresa = p_codigo_empresa
               AND no_credito = p_no_credito
               AND no_cuota > 0
               AND f_teorica <= p_f_calculo;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_msj_error := '000032';
               RETURN;
         END;
      ELSE
         v_principal_atrasado := 0;
      END IF;

      v_saldo_teorico := p_saldo_real - v_principal_atrasado;
      --

      -- Se calcula la cuota dependiendo del tipo de cuota y del tipo

      -- de interes

      --
      p_msj_error := 'calcula cuota';

      IF (p_tipo_cuota IN ('N', 'L'))
      THEN
         --

         -- Cuotas nivelada y libre

         --
         IF (p_tasa = 0)
         THEN
            v_cuota := v_saldo_teorico / v_periodos;
         ELSIF (p_tipo_interes = 'A')
         THEN
            -- interes anticipado
            v_cuota :=
                 v_saldo_teorico
               / (  (  (1 - POWER (1 + v_tasa_periodo, -1 * (v_periodos - 1))
                       )
                     / v_tasa_periodo
                    )
                  + 1
                 );
         ELSIF (p_tipo_interes = 'V')
         THEN
            -- interes vencido
            v_subtot1 := 1 - POWER ((1 + v_tasa_periodo), (v_periodos * -1));
            v_cuota := v_saldo_teorico * (v_tasa_periodo / v_subtot1);
         END IF;
      ELSIF (p_tipo_cuota IN ('P', 'M'))
      THEN
         --

         -- Cuota principal nivelado y multiperiodica

         --
         v_cuota := v_saldo_teorico / v_periodos;

         IF (p_tipo_interes = 'A')
         THEN
            v_cuota := v_saldo_teorico / (v_periodos + 1);
         END IF;
      ELSIF (p_tipo_cuota IN ('U', 'V'))
      THEN
         --

         -- Cuota Un Solo Pago y principal al Vencimiento

         --
         v_tasa_periodo := p_tasa / 100;

         IF (p_tasa = 0)
         THEN
            -- Credito sin intereses
            v_cuota := v_saldo_teorico;
         ELSE
            v_interes :=                                          -- mg_debug
                 (v_saldo_teorico * v_plazo_restante * v_tasa_periodo
                 )
               / v_cal_base_calculo;
            v_cuota := v_saldo_teorico + v_interes;
         END IF;
      ELSE
         --

         -- Otras cuotas

         --
         v_cuota := 0;
      END IF;

      p_msj_error := NULL;
      --

      -- Variables de salida

      --
      p_cuota := v_cuota;
   EXCEPTION
      WHEN OTHERS
      THEN
         --    p_msj_error  := sqlerrm;   -- mg_debug
         NULL;
   END;

   --

   --
   PROCEDURE agregar_dias (
      p_f_base            IN       DATE,
      p_dias              IN       NUMBER,
      p_tipo_calendario   IN       NUMBER,
      p_f_resultado       IN OUT   DATE,
      p_msj_error         IN OUT   VARCHAR2
   )
   IS
      v_f_resultado      DATE;
      v_meses            NUMBER;
      v_dias             NUMBER;
      v_dia_resultado    NUMBER;
      v_mes_resultado    NUMBER;
      v_anio_resultado   NUMBER;
      v_ult_dia          NUMBER;
   BEGIN
      IF (p_tipo_calendario = 365)
      THEN
         --

         -- calendario natural

         --
         v_f_resultado := p_f_base + p_dias;
      ELSIF (p_tipo_calendario = 360)
      THEN
         --

         -- calendario financiero

         --
         IF (MOD (p_dias, 30) = 0)
         THEN
            v_f_resultado := ADD_MONTHS (p_f_base, p_dias / 30);

            IF (    p_f_base = LAST_DAY (p_f_base)
                AND v_f_resultado = LAST_DAY (v_f_resultado)
                AND (TO_NUMBER (TO_CHAR (v_f_resultado, 'DD')) >
                                          TO_NUMBER (TO_CHAR (p_f_base, 'DD'))
                    )
               )
            THEN
               v_f_resultado :=
                  TO_DATE (   TO_CHAR (p_f_base, 'DD')
                           || TO_CHAR (v_f_resultado, 'MMYYYY'),
                           'DDMMYYYY'
                          );
            END IF;
         ELSE
            IF (p_dias >= 0)
            THEN
               v_meses := TRUNC (p_dias / 30);
               v_dias := MOD (p_dias, 30);
               v_f_resultado := ADD_MONTHS (p_f_base, v_meses);

               IF (    p_f_base = LAST_DAY (p_f_base)
                   AND v_f_resultado = LAST_DAY (v_f_resultado)
                   AND (TO_NUMBER (TO_CHAR (v_f_resultado, 'DD')) >
                                          TO_NUMBER (TO_CHAR (p_f_base, 'DD'))
                       )
                  )
               THEN
                  v_f_resultado :=
                     TO_DATE (   TO_CHAR (p_f_base, 'DD')
                              || TO_CHAR (v_f_resultado, 'MMYYYY'),
                              'DDMMYYYY'
                             );
               END IF;

               IF (v_f_resultado = LAST_DAY (v_f_resultado))
               THEN
                  v_f_resultado := v_f_resultado + v_dias;
               ELSE
                  -- desarma la fecha en sus partes
                  v_dia_resultado :=
                                    TO_NUMBER (TO_CHAR (v_f_resultado, 'DD'));
                  v_mes_resultado :=
                                    TO_NUMBER (TO_CHAR (v_f_resultado, 'MM'));
                  v_anio_resultado :=
                                  TO_NUMBER (TO_CHAR (v_f_resultado, 'YYYY'));
                  v_ult_dia := 30;
                  -- agrega los dias que han quedado y analiza el cambio

                  -- de mes y de anio
                  v_dia_resultado := v_dia_resultado + v_dias;

                  IF (v_dia_resultado > v_ult_dia)
                  THEN
                     v_dia_resultado := v_dia_resultado - v_ult_dia;
                     v_mes_resultado := v_mes_resultado + 1;
                  ELSIF (v_mes_resultado = 2)
                  THEN
                     v_ult_dia :=
                         TO_NUMBER (TO_CHAR (LAST_DAY (v_f_resultado), 'DD'));

                     IF (v_dia_resultado > v_ult_dia)
                     THEN
                        v_dia_resultado := v_ult_dia;
                     END IF;
                  END IF;

                  IF (v_mes_resultado > 12)
                  THEN
                     v_mes_resultado := v_mes_resultado - 12;
                     v_anio_resultado := v_anio_resultado + 1;
                  END IF;

                  -- arma la fecha de nuevo
                  v_f_resultado :=
                     TO_DATE (   TO_CHAR (v_dia_resultado, '00')
                              || TO_CHAR (v_mes_resultado, '00')
                              || TO_CHAR (v_anio_resultado, '0000'),
                              'DDMMYYYY'
                             );
               END IF;
            ELSE
               -- p_dias < 0
               v_meses := -1 * TRUNC (ABS (p_dias) / 30);
               v_dias := MOD (ABS (p_dias), 30);
               v_f_resultado := ADD_MONTHS (p_f_base, v_meses);

               IF (    p_f_base = LAST_DAY (p_f_base)
                   AND v_f_resultado = LAST_DAY (v_f_resultado)
                   AND (TO_NUMBER (TO_CHAR (v_f_resultado, 'DD')) >
                                          TO_NUMBER (TO_CHAR (p_f_base, 'DD'))
                       )
                  )
               THEN
                  v_f_resultado :=
                     TO_DATE (   TO_CHAR (p_f_base, 'DD')
                              || TO_CHAR (v_f_resultado, 'MMYYYY'),
                              'DDMMYYYY'
                             );
               END IF;

               v_mes_resultado := TO_NUMBER (TO_CHAR (v_f_resultado, 'MM'));

               IF (TO_CHAR (p_f_base, 'DD') = '31' AND v_dias = 1)
               THEN
                  NULL;
               ELSE
                  v_f_resultado := v_f_resultado - v_dias;
               END IF;

               IF (ABS (p_dias) < 30)
               THEN
                  IF (TO_CHAR (p_f_base, 'DD') = '31')
                  THEN
                     v_f_resultado := v_f_resultado - 1;
                  ELSIF (    TO_CHAR (p_f_base, 'MM') = '02'
                         AND TO_CHAR (p_f_base, 'DD') = '28'
                        )
                  THEN
                     v_f_resultado := v_f_resultado + 2;
                  ELSIF (    TO_CHAR (p_f_base, 'MM') = '02'
                         AND TO_CHAR (p_f_base, 'DD') = '29'
                        )
                  THEN
                     v_f_resultado := v_f_resultado + 1;
                  END IF;
               END IF;

               IF (TO_NUMBER (TO_CHAR (v_f_resultado, 'DD')) = '31')
               THEN
                  v_f_resultado := v_f_resultado - 1;
               END IF;
            END IF;                                          -- restar o sumar
         END IF;                                -- periodicidad multiplo de 30
      ELSE
         p_msj_error := '000046';                  -- Calendario no es valido
         RETURN;
      END IF;

      --

      -- Asigna variables de salida

      --
      p_f_resultado := v_f_resultado;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_msj_error := '000032';
         RETURN;
   END agregar_dias;                                           -- Agregar_Dias

   --

   --
   PROCEDURE busca_extras_cliente (
      p_codigo_empresa     IN       VARCHAR2,
      p_codigo_actividad   IN OUT   NUMBER,
      p_codigo_cliente     IN       NUMBER,
      p_codigo_ejecutivo   IN OUT   VARCHAR2,
      p_desc_ejecutivo     IN OUT   VARCHAR2,
      p_desc_actividad     IN OUT   VARCHAR2,
      p_agencia_labora     IN OUT   VARCHAR2,
      --FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA
      p_credito            IN OUT   t_rec_pr_creditos,
      p_codidioma          IN       VARCHAR2
   )
   IS
      v_cod_cliente   VARCHAR2 (15);

      --FAMH --- 12-05-2005
      CURSOR datos_demograficos
      IS
         SELECT d.cod_pais, d.cod_provincia, d.cod_canton, d.cod_distrito,
                a.codigo_actividad_economica, a.cod_direccion, pf.cod_sector,
                aebc.division, aebc.grupo, aebc.rama, aebc.segregacion_rd
           FROM clientes a,
                dir_personas d,
                personas_fisicas pf,
                actividades_economicas_bc_ciiu aebc
          WHERE a.codigo_empresa = p_codigo_empresa
            AND a.codigo_cliente = p_codigo_cliente
            AND d.cod_persona = a.cod_cliente
            AND d.cod_direccion = a.cod_direccion
            AND pf.cod_per_fisica = a.cod_cliente
            AND aebc.segregacion_rd = pf.cod_actividad
            -- Flarsen 26/05/2014 Se agrega el tipo de direccion para determinar cual mostrar en pantalla
            AND d.tip_direccion NOT IN (5);

      --FAMH --- 12-05-2005
      v_des_pais      VARCHAR2 (500);
      v_sector        VARCHAR2 (10);
   BEGIN
      --FAMH --- 12-05-2005
      OPEN datos_demograficos;

      FETCH datos_demograficos
       INTO p_credito.pais_destino, p_credito.departamento_destino,
            p_credito.municipio_destino, p_credito.distrito_destino,
            v_sector, p_credito.codigo_direccion, v_sector,
            p_credito.codigo_actividad, p_credito.codigo_subactividad,
            p_credito.codigo_sub_clase, p_credito.segregacion_rd;

      CLOSE datos_demograficos;

      --

      --
      p_codigo_actividad := p_credito.codigo_actividad;

      --

      --FAMH --- 12-05-2005

      --
      --BFernandez
      --28/10/2016
      --Que el ejecutivo sea el mismo analista
   /*   SELECT cod_cliente
        INTO v_cod_cliente
        FROM clientes
       WHERE codigo_empresa = p_codigo_empresa
         AND codigo_cliente = p_codigo_cliente;

      INSERT INTO pr.prueba
                  (campo1
                  )
           VALUES (v_cod_cliente
                  );

      SELECT cod_oficial
        INTO p_credito.codigo_ejecutivo
        FROM cliente
       WHERE cod_empresa = p_codigo_empresa AND cod_cliente = v_cod_cliente;*/

      --

      /*select codigo_analista

      into p_credito.codigo_ejecutivo

      from pr_analistas

      where codigo_persona = p_codigo_ejecutivo;*/

      --
      p_codigo_ejecutivo := p_credito.codigo_ejecutivo;

     /* INSERT INTO pr.prueba
                  (campo1
                  )
           VALUES (p_credito.codigo_ejecutivo
                  );*/

      BEGIN
         SELECT SUBSTR (per.nombre, 1, 60), cod_agencia_labora
           --Select substr(per.nombre,1,60)    FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA

         --into P_Desc_Ejecutivo
         INTO   p_desc_ejecutivo, p_agencia_labora
           FROM personas per, empleados emp
          WHERE emp.cod_empresa = p_codigo_empresa
            AND emp.id_empleado = p_codigo_ejecutivo
            AND emp.es_oficial = 'S'
            AND per.cod_per_fisica = emp.cod_per_fisica;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT descripcion
           INTO p_desc_actividad
           FROM actividades_economicas
          WHERE codigo_actividad = p_codigo_actividad;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            NULL;
      END;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         NULL;
   END busca_extras_cliente;

   --

   --
   PROCEDURE obtiene_planinversion (
      p_codigo_empresa        IN       VARCHAR2,
      p_cod_idioma            IN       VARCHAR2,
      p_plan_inversion        IN OUT   NUMBER,
      p_desc_plan_inversion   IN OUT   VARCHAR2
   )
   IS
   BEGIN
      SELECT plan_inversion, nombre_plan
        INTO p_plan_inversion, p_desc_plan_inversion
        FROM pr_plan_inversion
       WHERE codigo_empresa = p_codigo_empresa
         AND plan_inversion = (SELECT MIN (plan_inversion)
                                 FROM pr_plan_inversion
                                WHERE codigo_empresa = p_codigo_empresa);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_depura ('no encontro plan_de_inversion');
         -- ERROR: No existen Planes de Inversion
         utilitarios.mensaje ('000384', p_cod_idioma, 'PR');
         RETURN;
      WHEN OTHERS
      THEN
         p_depura ('others plan_inversion ' || SQLERRM);
         utilitarios.mensaje ('000032', p_cod_idioma, 'PR');
         RETURN;
   END obtiene_planinversion;

   --

   -- IGH, Req RCC002. Inserta un credito x un sobregiro no autorizado.
   PROCEDURE inserta_sobregiro (
      p_codigo_empresa            NUMBER,
      p_codigo_agencia            NUMBER,
      p_tipo_credito              NUMBER,
      p_num_grupo                 NUMBER,
      p_codidioma                 VARCHAR2,
      pcodcliente                 VARCHAR2,                             -- IGH
      pmonto                      NUMBER,                               -- IGH
      pcuentaabono                VARCHAR2,                             -- IGH
      pmensajeerror      IN OUT   VARCHAR2
   )
   IS
      --

      -- Variables locales
      rec_pr_creditos         t_rec_pr_creditos;    -- Variable tipo registro
      v_desc_ejecutivo        VARCHAR2 (500);
      v_desc_actividad        VARCHAR2 (500);
      v_agencia_labora        VARCHAR2 (100);
      v_desc_plan_inversion   VARCHAR2 (500);
      vperiodicidad_pago      VARCHAR2 (5);
      salir                   EXCEPTION;
   --
   BEGIN
      --
      rec_pr_creditos.f_apertura :=
           fecha_actual_calendario ('PR', p_codigo_empresa, p_codigo_agencia);
      vperiodicidad_pago :=
         pa_interfaz_consulta.obtieneparametroempresa ('PR',
                                                       p_codigo_empresa,
                                                       'PERIODICI_PAGO_MENS'
                                                      );

      BEGIN
         SELECT ptc.codigo_moneda, ptc.tipo_credito,
                ptc.es_linea_credito,
                ptc.tipo_linea, ptc.manejo,
                ptc.modalidad_cobro,
                ptc.tipo_intereses,
                ptc.tipo_calendario,
                ptc.periodo_comision_normal,
                ptc.comision_normal, ptc.tipo_tasa,
                ptc.codigo_tipo_de_tasa,
                ptc.variacion_base,
                ptc.tasa_interes,
                ptc.codigo_tasa_moratorios,
                ptc.variacion_mora,
                ptc.tasa_moratorios,
                ptc.gracia_principal,
                ptc.gracia_mora, ptc.codigo_origen,
                ptc.continua_cobro_intereses,
                ptc.dia_pago, ptc.revaloriza,
                ptc.codigo_sub_aplicacion,
                ptc.tipo_comision, ptc.tipo_mora,
                ptc.porcentaje_tasa_mora,
                ptc.codigo_plazo,
                ptc.permite_sobregiro,
                ptc.porcentaje_sobregiro,
                ptc.variacion_minima,
                ptc.variacion_maxima,
                ptc.periodos_gracia_principal,
                ptc.base_calculo_moratorios,
                ptc.descuenta_intereses_desembolso,
                ptc.cantidad_cuotas_descontar,
                ptc.ind_pr_vehiculo,
                
                --
                (SELECT dias_periodo
                   FROM pr_periodicidad pp
                  WHERE pp.codigo_periodo = vperiodicidad_pago)
                                                             frecuencia_plazo,
                
                --rec_pr_creditos.dias_periodo_cuota

                --
                (SELECT ptp.plazo_maximo
                   FROM pr_tipos_plazos ptp
                  WHERE ptp.codigo_plazo = ptc.codigo_plazo),
                'C' tipo_desembolso,                     -- cuenta relacionada
                0 codigo_actividad,
                0 codigo_subactividad,
                0 codigo_sub_clase,
                vperiodicidad_pago,
                --codigo_periodo_cuota, -- cod del periodo del cobro de la cuota
                vperiodicidad_pago,
                --codigo_periodo_intereses, si el tipo de cuota es Multiperiodica
                ptc.periodo_comision_normal
           INTO rec_pr_creditos.codigo_moneda, rec_pr_creditos.tipo_credito,
                rec_pr_creditos.es_linea_credito,
                rec_pr_creditos.tipo_linea, rec_pr_creditos.manejo,
                rec_pr_creditos.modalidad_cobro,
                rec_pr_creditos.tipo_intereses,
                rec_pr_creditos.tipo_calendario,
                rec_pr_creditos.periodo_comision_normal,
                rec_pr_creditos.comision_normal, rec_pr_creditos.tipo_tasa,
                rec_pr_creditos.codigo_tipo_de_tasa,
                rec_pr_creditos.variacion_base,
                rec_pr_creditos.tasa_interes,
                rec_pr_creditos.codigo_tasa_moratorios,
                rec_pr_creditos.variacion_mora,
                rec_pr_creditos.tasa_moratorios,
                rec_pr_creditos.gracia_principal,
                rec_pr_creditos.gracia_mora, rec_pr_creditos.codigo_origen,
                rec_pr_creditos.continua_cobro_intereses,
                rec_pr_creditos.dia_pago, rec_pr_creditos.revaloriza,
                rec_pr_creditos.codigo_sub_aplicacion,
                rec_pr_creditos.tipo_comision, rec_pr_creditos.tipo_mora,
                rec_pr_creditos.porcentaje_tasa_mora,
                rec_pr_creditos.codigo_plazo,
                rec_pr_creditos.permite_sobregiro,
                rec_pr_creditos.porcentaje_sobregiro,
                rec_pr_creditos.variacion_minima,
                rec_pr_creditos.variacion_maxima,
                rec_pr_creditos.periodos_gracia_principal,
                rec_pr_creditos.base_calculo_moratorios,
                rec_pr_creditos.descuenta_intereses_desembolso,
                rec_pr_creditos.cantidad_cuotas_descontar,
                rec_pr_creditos.ind_pr_vehiculo,
                rec_pr_creditos.dias_periodo_cuota,
                rec_pr_creditos.plazo,
                rec_pr_creditos.tipo_desembolso,
                rec_pr_creditos.codigo_actividad,
                rec_pr_creditos.codigo_subactividad,
                rec_pr_creditos.codigo_sub_clase,
                rec_pr_creditos.codigo_periodo_cuota,
                rec_pr_creditos.codigo_periodo_intereses,
                rec_pr_creditos.periodo_comision_normal
           FROM pr_tipo_credito ptc
          WHERE ptc.codigo_empresa = p_codigo_empresa
            AND ptc.tipo_credito = p_tipo_credito
            AND ptc.ind_micro_credito = 'N';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            pmensajeerror := '000376';
            RAISE salir;
      END;

      --
      rec_pr_creditos.cuenta_abono := pcuentaabono;
      rec_pr_creditos.cuenta_desem := pcuentaabono;
      rec_pr_creditos.estado := 'R';
      rec_pr_creditos.tipo_cuota := 'N';
      rec_pr_creditos.f_vencimiento :=
                            rec_pr_creditos.f_apertura + rec_pr_creditos.plazo;
      --
      rec_pr_creditos.codigo_cliente := pcodcliente;
      rec_pr_creditos.monto_credito := pmonto;
      rec_pr_creditos.num_grupo_microcredito := p_num_grupo;
      --
      obtiene_planinversion (p_codigo_empresa,
                             p_codidioma,
                             rec_pr_creditos.plan_inversion,
                             v_desc_plan_inversion
                            );
      --
      busca_extras_cliente (p_codigo_empresa,
                            rec_pr_creditos.codigo_actividad,
                            pcodcliente,
                            v_desc_ejecutivo,
                            v_desc_ejecutivo,
                            v_desc_actividad,
                            v_agencia_labora,
                            rec_pr_creditos,
                            p_codidioma
                           );
      --
      inserta_credito (p_codigo_empresa,
                       p_codigo_agencia,
                       rec_pr_creditos.no_credito,
                       rec_pr_creditos,
                       pmensajeerror
                      );

      IF pmensajeerror IS NOT NULL
      THEN
         RAISE salir;
      END IF;
   --
   EXCEPTION
      WHEN salir
      THEN
         RETURN;
      WHEN OTHERS
      THEN
         pmensajeerror := '000956';
         RETURN;
   END;

   --

   --
   PROCEDURE crea_credito_pda (
      p_codempresa              NUMBER,
      p_codagencia              NUMBER,
      p_plazo                   NUMBER,
      p_tasa                    NUMBER DEFAULT 0,
      p_frecuencia              VARCHAR2,
      p_cuota                   NUMBER DEFAULT 0,
      p_tipocredito             VARCHAR2,
      reg1             IN OUT   pr_credito.t_rec_pr_creditos,
      p_nrocredito     IN OUT   VARCHAR2,
      p_mensajeerror   IN OUT   VARCHAR2
   )
   IS
      v_desc_ejecutivo        VARCHAR2 (500);
      v_desc_actividad        VARCHAR2 (500);
      v_agencia_labora        VARCHAR2 (100);
      v_desc_plan_inversion   VARCHAR2 (500);
      vperiodicidad_pago      VARCHAR2 (5);
   BEGIN
      -- p_codempresa := 1;

      --    p_codagencia := :New.idagencia;

      --   reg1.tipo_credito := TO_NUMBER (:New.tipoproductos);  --:New.tipoproductos;
      reg1.f_apertura :=
         fecha_actual_calendario ('PR',
                                  p_codempresa,
                                  TO_NUMBER (p_codagencia)
                                 );      --to_date('09/12/2015','dd/mm/yyyy');
      --     reg1.f_apertura := FECHA_ACTUAL_CALENDARIO ('PR',

      --                              p_codempresa, p_codagencia);
      vperiodicidad_pago :=
         pa_interfaz_consulta.obtieneparametroempresa ('PR',
                                                       p_codempresa,
                                                       'PERIODICI_PAGO_MENS'
                                                      );

      BEGIN
         SELECT ptc.codigo_moneda, ptc.tipo_credito,
                ptc.es_linea_credito, ptc.tipo_linea, ptc.manejo,
                ptc.modalidad_cobro, ptc.tipo_intereses,
                ptc.tipo_calendario, ptc.periodo_comision_normal,
                ptc.comision_normal, ptc.tipo_tasa,
                ptc.codigo_tipo_de_tasa, ptc.variacion_base,
                ptc.tasa_interes, ptc.codigo_tasa_moratorios,
                ptc.variacion_mora, ptc.tasa_moratorios,
                ptc.gracia_principal, ptc.gracia_mora, ptc.codigo_origen,
                ptc.continua_cobro_intereses, ptc.dia_pago,
                ptc.revaloriza, ptc.codigo_sub_aplicacion,
                ptc.tipo_comision, ptc.tipo_mora,
                ptc.porcentaje_tasa_mora, ptc.codigo_plazo,      -- ppm.plazo,
                ptc.permite_sobregiro, ptc.porcentaje_sobregiro,
                ptc.variacion_minima, ptc.variacion_maxima,
                ptc.periodos_gracia_principal,
                ptc.base_calculo_moratorios,
                ptc.descuenta_intereses_desembolso,
                ptc.cantidad_cuotas_descontar, ptc.ind_pr_vehiculo,
                p_frecuencia,
/*(select dias_periodo

                                from pr_periodicidad pp

                               where  pp.codigo_periodo = vPeriodicidad_pago) frecuencia_pago,*/
                             p_plazo, 
                                      /*  (select ptp.plazo_maximo

                                                                      from pr_tipos_plazos ptp

                                                                     where ptp.CODIGO_PLAZO = ppm.plazo) ,*/
                'C' tipo_desembolso,
                0 codigo_actividad, 0 codigo_subactividad,
                0 codigo_sub_clase, vperiodicidad_pago,
                --ppm.frecuencia_pago codigo_periodo_cuota,
                vperiodicidad_pago,
                                   --ppm.frecuencia_pago codigo_periodo_interes,
                                   ptc.periodo_comision_normal
           INTO reg1.codigo_moneda, reg1.tipo_credito,
                reg1.es_linea_credito, reg1.tipo_linea, reg1.manejo,
                reg1.modalidad_cobro, reg1.tipo_intereses,
                reg1.tipo_calendario, reg1.periodo_comision_normal,
                reg1.comision_normal, reg1.tipo_tasa,
                reg1.codigo_tipo_de_tasa, reg1.variacion_base,
                reg1.tasa_interes, reg1.codigo_tasa_moratorios,
                reg1.variacion_mora, reg1.tasa_moratorios,
                reg1.gracia_principal, reg1.gracia_mora, reg1.codigo_origen,
                reg1.continua_cobro_intereses, reg1.dia_pago,
                reg1.revaloriza, reg1.codigo_sub_aplicacion,
                reg1.tipo_comision, reg1.tipo_mora,
                reg1.porcentaje_tasa_mora, reg1.codigo_plazo,
                reg1.permite_sobregiro, reg1.porcentaje_sobregiro,
                reg1.variacion_minima, reg1.variacion_maxima,
                reg1.periodos_gracia_principal,
                reg1.base_calculo_moratorios,
                reg1.descuenta_intereses_desembolso,
                reg1.cantidad_cuotas_descontar, reg1.ind_pr_vehiculo,
                reg1.dias_periodo_cuota, reg1.plazo, reg1.tipo_desembolso,
                reg1.codigo_actividad, reg1.codigo_subactividad,
                reg1.codigo_sub_clase, reg1.codigo_periodo_cuota,
                reg1.codigo_periodo_intereses, reg1.periodo_comision_normal
           FROM pr_tipo_credito ptc
          WHERE ptc.codigo_empresa = p_codempresa
            AND ptc.tipo_credito = p_tipocredito;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_mensajeerror := '000376';
            RETURN;
      END;

      --

      --
      reg1.estado := 'R';
      reg1.tipo_cuota := 'N';
      reg1.f_vencimiento := reg1.f_apertura + reg1.plazo;
      --

      --
      pr_credito.obtiene_planinversion (TO_NUMBER (p_codempresa),
                                        'ESPA',
                                        reg1.plan_inversion,
                                        v_desc_plan_inversion
                                       );
      --
      p_depura ('Busca_Extras_Cliente');
      --
      pr_credito.busca_extras_cliente (p_codempresa,
                                       reg1.codigo_actividad,
                                       reg1.codigo_cliente,
                                       v_desc_ejecutivo,
                                       v_desc_ejecutivo,
                                       v_desc_actividad,
                                       v_agencia_labora,
                                       --FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA
                                       reg1,
                                       'ESPA'
                                      );
      --
      pr_credito.inserta_credito (p_codempresa,
                                  TO_NUMBER (p_codagencia),
                                  p_nrocredito,
                                  reg1,
                                  p_mensajeerror
                                 );
      DBMS_OUTPUT.put_line ('p_mensajeerror=' || p_mensajeerror);
   END crea_credito_pda;
END pr_credito;