/*******************************************
Modificado por FMBLWR 
04-05-2011 17:55:42
*******************************************/
-- CREADO POR LPEREZ LE 03/11/2005, PARA GENERAR UN ARCHIVO DE TEXTO CON LOS DATOS DEL 
-- CERTIFICADO E INVOCAR EL PROGRAMA DE LA SUPER QUE GENERA EL CODIGO DE VERIFICACION, PARA
-- POSTERIORMENTE GUARDAR ESTE CODIGO DE VERIFICACION EN LA TABLA DE CERTIFICADOS Y SER IMPRESO EN EL MISMO CERTIFICADO
--JAC 04-AGO-2010 Implementacion de SYS.DBMS_CRYPTO.HASH
procedure archivo_codigo_verificacion (
   pnum_certificado       in       varchar2,
   pcedula                in       varchar2,
   pnombre_cliente        in       varchar2,
   pcodigo_verificacion   out      varchar2)
is
   -- Variables de manejo de archivo
   vlinebuff   varchar2 (500);
begin
   vlinebuff := rtrim (pnombre_cliente) || replace (pcedula, '-', '') || pnum_certificado;
   --JAC 04-AGO-2010 Implementacion de SYS.DBMS_CRYPTO.HASH
   pcodigo_verificacion := pa.sha1 (vlinebuff);
exception
   when others
   then
      utilitarios.mensaje ('100084',
                           :variables.codidioma,
                           'PA',
                           acknowledge,
                           ('(01) Error Generando el Archivo para generar el Código de Verificación, erro: ' || sqlerrm));
      --
      raise form_trigger_failure;
end;

PROCEDURE Calcule_FEC_PROX_CAP (fec_emi in date, 
                                dia_cap in number, 
                                pla_cap in number, 
                                fre_cap in varchar2, 
                                fec_cap in out date) is
  
  v_plazo_dias       number ;
  v_frecuencia       varchar2(1) ;
  dia_capitalizacion number ;
  diferencia_dias    number ;
  ultimo_dia_mes     date ;

BEGIN

  v_frecuencia := fre_cap ;

  if fre_cap = 'D' then   

    -- Se calcula la proxima fecha de capitalizacion de acuerdo a la fecha de emision, al plazo y frecuencia definidos....
    cd_fecha_exacta(fec_emi, :bkproducto.base_plazo, pla_cap, v_frecuencia, fec_cap, v_plazo_dias);

  else  -- es en meses, debe verificarse contra el campo dia_de_cap_fre_mes ...

    if NVL(dia_cap,0) = 0 then    

      -- No hay dia definido.  El calculo se hace en funcion de la fecha de emision, 
      -- el plazo y frecuencia de capitalizacion...
      cd_fecha_exacta(fec_emi, :bkproducto.base_plazo, pla_cap, v_frecuencia, fec_cap, v_plazo_dias);

    elsif nvl(dia_cap,0) between 1 and 30 then 

      -- Hay un dia específico del mes en que se realiza la capitalizacion ...
      -- Debe realizarse en este dia pero se respeta el plazo y frecuencia definidos ...
      cd_fecha_exacta(fec_emi, :bkproducto.base_plazo, pla_cap, v_frecuencia, fec_cap, v_plazo_dias);

      -- Determina el dia resultante para la capitalizacion ...
      dia_capitalizacion := to_number(to_char(fec_cap, 'DD'));

      -- Saca la diferencia transcurrida entre el dia establecido para la capitalizacion y 
      -- el dia resultante de acuerdo a la fecha emision, plazo y frecuencia de capitalizacion 
      diferencia_dias := nvl(dia_cap,0)  - dia_capitalizacion ;

      if diferencia_dias < 0 then  -- hay que llevarlo al siguiente mes ...
         begin
            select last_day(to_char(fec_cap))
            into ultimo_dia_mes
            from dual ;
         end ;
        fec_cap := cd_fecha_financiera (ultimo_dia_mes, :bkproducto.base_plazo, diferencia_dias) ;

      else    -- es cero o mayor lo que significa que quedara dentro del mismo mes ...
        fec_cap := cd_fecha_financiera (fec_cap, :bkproducto.base_plazo, diferencia_dias) ;
      end if ;

    elsif dia_cap = 31 then  

      -- La capitalizacion se realiza el ultimo dia de cada mes pero se respeta 
      -- el plazo y frecuencia definidos ...
      cd_fecha_exacta(fec_emi, :bkproducto.base_plazo, pla_cap, v_frecuencia, fec_cap, v_plazo_dias);
      begin
         select last_day(to_char(fec_cap))
         into fec_cap
         from dual ;
      end ;

    else
      message('error al cargar el dia de capitalizacion en frecuencia meses');
      raise form_trigger_failure ;
    end if ;
  end if ;
END ;

PROCEDURE call_cd_inserta_movimiento(p_num_certificado varchar2,
																		 p_valor_mvto number,
																		 p_tas_bruta number,
																		 p_comentario varchar2) IS
BEGIN
  cd_inserta_movimiento_cap (:emision.cod_empresa, 
	                         	 p_num_certificado, 
	                          :variables.codsistema,
	                          1, 
	                          :variables.codigo_subtrans_cd, 
	                          null, 
	                          null, 
	                          :variables.fecha, 
	                          null,
	                          p_valor_mvto,
	                         	:emision.cod_producto,
														:variables.codagencia,
														:pblock.tip_certificado,
													  :bkproducto.cod_moneda,
													  'A',--p_estado
														p_valor_mvto,
														null,--p_cre_interes
														null,--p_cre_mes
														p_tas_bruta,
														null,--p_tas_neta
														null,--p_mon_int_x_pagar
														null,--p_mon_acum_int_cap
														null,--p_mon_interes_pagado
														null,--p_mon_int_ganado
														null,--p_porcentaje_renta
														null,--p_base_calculo
														null,--p_mon_descuento
														null,--p_cod_tasa
														null,--p_base_plazo
														p_comentario,
														:variables.asiento_contable) ;
END;

PROCEDURE call_cd_inserta_movimiento(p_num_certificado varchar2,
																		 p_valor_mvto number,
																		 p_tas_bruta number,
																		 p_comentario varchar2) IS
BEGIN
  cd_inserta_movimiento_cap (:emision.cod_empresa, 
	                         	 p_num_certificado, 
	                          :variables.codsistema,
	                          1, 
	                          :variables.codigo_subtrans_cd, 
	                          null, 
	                          null, 
	                          :variables.fecha, 
	                          null,
	                          p_valor_mvto,
	                         	:emision.cod_producto,
														:variables.codagencia,
														:pblock.tip_certificado,
													  :bkproducto.cod_moneda,
													  'A',--p_estado
														p_valor_mvto,
														null,--p_cre_interes
														null,--p_cre_mes
														p_tas_bruta,
														null,--p_tas_neta
														null,--p_mon_int_x_pagar
														null,--p_mon_acum_int_cap
														null,--p_mon_interes_pagado
														null,--p_mon_int_ganado
														null,--p_porcentaje_renta
														null,--p_base_calculo
														null,--p_mon_descuento
														null,--p_cod_tasa
														null,--p_base_plazo
														p_comentario,
														:variables.asiento_contable) ;
END;

PROCEDURE cd_carga_forma(P_EMPRESA    in     varchar2,
                         P_COD_TASA   in     varchar2,
                         P_SPREAD     in     number,
                         P_TASA_BRUTA in out number,
                         P_TASA_NETA  in out number,
                         P_EXCENTO    in     varchar2) IS

v_tasa       NUMBER(10, 6) := NULL;
v_tasa_bruta_antes number(8,5) := 0;
v_error varchar2(6);
v_sqlcode number(6);
v_sistema varchar2(3);

BEGIN
  :GLOBAL.tasa_bruta 	    := null;
  :GLOBAL.tasa_neta           := null;
  :GLOBAL.tasa_bruta_antes    := null;

  v_tasa := CD.pkg_cd_inter.CD_TASINTERES_BASE(p_empresa, p_cod_tasa,:emision.fecha_emision, v_error, v_sqlcode);
  if v_error = '000038' then
     utilitarios.mensaje (v_error, :variables.codidioma, :variables.codsistema) ;
     raise form_trigger_failure ;
  elsif v_error = '000523' then
     utilitarios.mensaje_error (v_error, :variables.codidioma, :variables.codsistema, v_sqlcode);
     raise form_trigger_failure ;
  end if ;
  --Monto de la tasa bruta y la tasa neta
  cd_cal_tasa_neta(p_tasa_neta,  p_spread, :emision.porcentaje_renta,p_tasa_BRUTA, v_error, v_sistema, v_sqlcode);  

  :GLOBAL.tasa_bruta := p_tasa_bruta;
  :GLOBAL.tasa_neta  := p_tasa_neta;
END;

PROCEDURE CD_MONTO_MINIMO(monto in number) IS
BEGIN
  -- Revisar si el monto del certificado es menor al monto minimo por producto
  IF monto  < :BKPRODUCTO.monto_minimo THEN
    UTILITARIOS.mensaje('000089',:variables.CodIdioma, 'CD',ACKNOWLEDGE,TO_CHAR(:BKPRODUCTO.monto_minimo,'999,999,999,990.99'));
    raise form_trigger_failure;
  END IF;
END;

PROCEDURE CD_PLAZO_MINIMO(p_plazo in number) IS
BEGIN
  -- Revisar si el monto del certificado es menor al monto minimo por producto
  IF p_plazo  < :BKPRODUCTO.plazo_minimo THEN
    UTILITARIOS.mensaje('000094',:variables.CodIdioma, 'CD', ACKNOWLEDGE,:BKPRODUCTO.plazo_minimo );
    raise form_trigger_failure;
  END IF;
END;

/* CGBS$SET_QUERY_MODE */
PROCEDURE CGBS$SET_QUERY_MODE(
   P_QUERY_MODE IN VARCHAR2) IS  /* Query Mode */
/* Set all query items to the current query mode */
BEGIN
  NULL;
END;

/* CGLY$CANVAS_MANAGEMENT */
PROCEDURE CGLY$CANVAS_MANAGEMENT IS
/* Top level canvas management procedure */
  current_canvas VARCHAR2(61) := get_item_property(:SYSTEM.CURSOR_ITEM,
      ITEM_CANVAS);
  base_canvas VARCHAR2(61);
  canvas_list VARCHAR2(255);
BEGIN
  IF ( (:CG$CTRL.CG$LAST_CANVAS IS NULL) OR (:CG$CTRL.CG$LAST_CANVAS !=
      current_canvas) ) THEN
    :CG$CTRL.CG$LAST_CANVAS := current_canvas;
    set_window_property( get_view_property( current_canvas, WINDOW_NAME
        ), VISIBLE, PROPERTY_ON);
    CGLY$GET_RELATED_CANVASES(current_canvas, base_canvas);
    IF ( base_canvas = 'CG$PAGE_1') THEN
      canvas_list := :CG$CTRL.CG$PAGE_1_LIST;
    ELSIF ( base_canvas = 'CG$PAGE_2') THEN
      canvas_list := :CG$CTRL.CG$PAGE_2_LIST;
    ELSIF ( base_canvas = 'CG$PAGE_3') THEN
      canvas_list := :CG$CTRL.CG$PAGE_3_LIST;
    END IF;
    CGLY$DISPLAY_CANVASES(canvas_list, current_canvas, base_canvas);
    IF ( base_canvas = 'CG$PAGE_1') THEN
      :CG$CTRL.CG$PAGE_1_LIST := canvas_list;
    ELSIF ( base_canvas = 'CG$PAGE_2') THEN
      :CG$CTRL.CG$PAGE_2_LIST := canvas_list;
    ELSIF ( base_canvas = 'CG$PAGE_3') THEN
      :CG$CTRL.CG$PAGE_3_LIST := canvas_list;
    END IF;
  END IF;
END;

/* CGLY$DISPLAY_CANVASES */
PROCEDURE CGLY$DISPLAY_CANVASES(
   P_CANVAS_LIST    IN OUT VARCHAR2      /* List of displayed canvases */
  ,P_CURRENT_CANVAS IN     VARCHAR2      /* Current canvas             */
  ,P_BASE_CANVAS    IN     VARCHAR2) IS  /* Base canvas                */
/* Display the current canvas plus any others in the canvas list */
  canvas_list VARCHAR2(255);  /* List of displayed canvases */
  canvas_to_raise VARCHAR2(255);  /* Canvas to raise to the top */
BEGIN
  IF ( P_CURRENT_CANVAS = P_BASE_CANVAS) THEN
    P_CANVAS_LIST := P_CURRENT_CANVAS || ',';
  ELSE
    P_CANVAS_LIST := replace(P_CANVAS_LIST, P_CURRENT_CANVAS || ',');
    IF ( get_view_property(P_BASE_CANVAS, VISIBLE) = 'FALSE') THEN
      canvas_list := P_CANVAS_LIST;
      WHILE (canvas_list IS NOT NULL) LOOP
        canvas_to_raise := substr(canvas_list, 1, instr(canvas_list,
            ','));
        canvas_list := replace(canvas_list, canvas_to_raise);
        CGLY$RAISE_CANVAS(rtrim(canvas_to_raise, ','));
      END LOOP;
    END IF;
    P_CANVAS_LIST := P_CANVAS_LIST || P_CURRENT_CANVAS || ',';
  END IF;
  CGLY$RAISE_CANVAS(P_CURRENT_CANVAS);
END;

/* CGLY$GET_RELATED_CANVASES */
PROCEDURE CGLY$GET_RELATED_CANVASES(
   P_CURRENT_CANVAS IN OUT VARCHAR2      /* Current canvas */
  ,P_BASE_CANVAS    IN OUT VARCHAR2) IS  /* Base canvas    */
/* Find the canvases associated with the current canvas and record whi */
/* base canvas is displayed in each window                             */
BEGIN
  IF ( P_CURRENT_CANVAS = 'CG$SPREAD_TABLE_1') THEN
    P_CURRENT_CANVAS := 'CG$PAGE_1';
  ELSIF ( P_CURRENT_CANVAS = 'CG$SPREAD_TABLE_2') THEN
    P_CURRENT_CANVAS := 'CG$PAGE_2';
  ELSIF ( P_CURRENT_CANVAS = 'CG$SPREAD_TABLE_3') THEN
    P_CURRENT_CANVAS := 'CG$PAGE_3';
  END IF;
  IF ( P_CURRENT_CANVAS = 'CG$POPUP_1') THEN
    P_BASE_CANVAS := 'CG$PAGE_1';
  ELSE
    P_BASE_CANVAS := P_CURRENT_CANVAS;
  END IF;
  IF (get_view_property(P_CURRENT_CANVAS, WINDOW_NAME) = 'WIN') THEN
    :CG$CTRL.WIN_PAGE := P_BASE_CANVAS;
  ELSIF (get_view_property(P_CURRENT_CANVAS, WINDOW_NAME) =
      'ROOT_WINDOW') THEN
    IF (:CG$CTRL.ROOT_WINDOW_PAGE != P_BASE_CANVAS) THEN
      set_view_property('CG$SPREAD_TABLE_1', VISIBLE, PROPERTY_OFF);
      set_view_property('CG$POPUP_1', VISIBLE, PROPERTY_OFF);
      set_view_property('CG$SPREAD_TABLE_2', VISIBLE, PROPERTY_OFF);
      set_view_property('CG$SPREAD_TABLE_3', VISIBLE, PROPERTY_OFF);
    END IF;
    :CG$CTRL.ROOT_WINDOW_PAGE := P_BASE_CANVAS;
  END IF;
END;

/* CGLY$RAISE_CANVAS */
PROCEDURE CGLY$RAISE_CANVAS(
   P_CANVAS IN VARCHAR2) IS  /* Current canvas */
/* Raise the current canvas, plus any dependant canvases to the top */
BEGIN
  set_view_property(P_CANVAS, VISIBLE, PROPERTY_ON);
  IF ( P_CANVAS = 'CG$PAGE_1') THEN
    set_view_property('CG$SPREAD_TABLE_1', VISIBLE, PROPERTY_ON);
  ELSIF ( P_CANVAS = 'CG$PAGE_2') THEN
    set_view_property('CG$SPREAD_TABLE_2', VISIBLE, PROPERTY_ON);
  ELSIF ( P_CANVAS = 'CG$PAGE_3') THEN
    set_view_property('CG$SPREAD_TABLE_3', VISIBLE, PROPERTY_ON);
  END IF;
END;

procedure cliente_repetido_item
is
   vreg       number;
   vcliente   varchar2 (15);
begin
   if :cuenta_cliente_rel.codigo_cliente is not null
   then
      vreg := :system.cursor_record;
      vcliente := :cuenta_cliente_rel.codigo_cliente;
      --
      first_record;
      if :system.last_record = 'TRUE'
         and :system.cursor_record = 1
      then
         null;
      else
         --if nvl(:variables.total_bloque,0) = 0 then
         loop
            if vreg <> :system.cursor_record
            then
               if vcliente = :cuenta_cliente_rel.codigo_cliente
               then
                  utilitarios.mensaje ('100084',
                                       :variables.codidioma,
                                       'PA',
                                       acknowledge,
                                       ('(09) Este Cliente ya fue digitado en el registro No. ' || :system.cursor_record));
                  go_record (vreg);
                  raise form_trigger_failure;
               end if;
            end if;
            if nvl (:variables.total_bloque, 0) > 0
            then
               exit when :variables.total_bloque = :system.cursor_record;
            else
               exit when vreg = :system.cursor_record;
            end if;
            next_record;
         end loop;
      end if;
   end if;
end;

procedure conexion_con_cajas (cual_bloque number, pc_control varchar2, pn_monto number)
is
   consecutivo              number     		:= 0;
   observa2                 varchar2 (100) := null;
   vcontador                number;
   total_certificados       number         := 0;
   total_monto              number         := 0;
   -- Jsanchez
   -- Se cambia el parametro de number a varchar
   -- numero_cd                number         := 0;
   numero_cd                varchar2(15);
   monto_cd                 number         := 0;
   numero_cliente           varchar2 (8);
   vcodigo_subtransaccion   number (3);
begin
--p_depura('jsq conexion_con_cajas 1');
   vcodigo_subtransaccion := :variables.codigo_subtrans_cd;
   --
   if cual_bloque = 0
   then                                                                          -- es el bloque de certificados con cupones
--p_depura('jsq conexion_con_cajas 1 bloque 0');
      total_certificados := :pblock.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock.total_monto;
      else
         total_monto := pn_monto;
      end if;
      go_block ('PBLOCK');
   elsif cual_bloque = 1
   then                                                             -- es el bloque de certificados a la vista capitalizables
--p_depura('jsq conexion_con_cajas 1 bloque 1');
      go_block ('PBLOCK1');
      total_certificados := :pblock1.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock1.total_monto;
      else
         total_monto := pn_monto;
      end if;
   elsif cual_bloque = 2
   then                                                                            -- es el bloque de certificados a la vista
--p_depura('jsq conexion_con_cajas 1 bloque 2');
      go_block ('PBLOCK2');
      total_certificados := :pblock2.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock2.total_monto;
      else
         total_monto := pn_monto;
      end if;
   end if;
--p_depura('jsq conexion_con_cajas 2');
   -- Se determina el numero de solicitud de ingreso en Cajas ...
   begin
   consecutivo_ingresos (consecutivo);
    exception
   when others
   then
      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error generando consecutivo de caja'||sqlerrm);
      clear_form (no_validate);
      rollback;
      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
      raise form_trigger_failure;
   end;
   :variables.solicitud := consecutivo;
--p_depura('jsq conexion_con_cajas 3');
   -- Busca el campo NUM_CLIENTE asociado al COD_CLIENTE en la tabla CLIENTE que es lo que hay que enviar a cajas...
   begin
      select num_cliente
        into numero_cliente
        from cliente
       where cod_empresa = :emision.cod_empresa
         and cod_cliente = :emision.cliente;
   exception
      when no_data_found
      then
         utilitarios.mensaje ('000129', :variables.codidioma, 'CD');
         raise form_trigger_failure;
   end;
--p_depura('jsq conexion_con_cajas 4');
   -- Inserta en bcj_solicitud el comprobante de ingreso para ser atendido en el area de Cajas...
   begin
   genera_solicitud_cajas (:emision.cod_empresa,
                           :variables.codagencia,                                  -- lperez 06/06/2006 :emision.cod_agencia,
                           consecutivo,
                           :bkproducto.cod_moneda,
                           numero_cliente,                -- :emision.cliente se sustituye para lograr consistencia con cajas
                           total_monto,
                           :emision.fecha_emision,
                           :variables.asiento_contable,
                           null);
   exception
   when others
   then
      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error generando solicitud de caja'||sqlerrm);
      clear_form (no_validate);
      rollback;
      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
      raise form_trigger_failure;
end;
--p_depura('jsq conexion_con_cajas 5');
   -- Se relacionan cada uno de los certificados emitidos con el comprobante de ingreso en cajas
   first_record;
   vcontador := 1;
   while vcontador <= total_certificados
   loop
      if cual_bloque = 0
      then                                                                       -- es el bloque de certificados con cupones
         numero_cd := :pblock.num_certificado;
         monto_cd := :pblock.monto;
      elsif cual_bloque = 1
      then                                                          -- es el bloque de certificados a la vista capitalizables
         numero_cd := :pblock1.num_certificado;
         monto_cd := :pblock1.monto;
      elsif cual_bloque = 2
      then                                                                         -- es el bloque de certificados a la vista
         numero_cd := :pblock2.num_certificado;
         monto_cd := :pblock2.monto;
      end if;
--p_depura('jsq conexion_con_cajas 6 '||cual_bloque||'** '||numero_cd||'*** '||monto_cd);
      --
      begin
      insert into cd_det_ing_caja
                  (cod_empresa,
                   num_solicitud,
                   num_certificado,
                   ord_linea,
                   tip_linea,
                   tip_operacion,
                   num_cupon,
                   monto,
                   adicionado_por,
                   fec_adicion,
                   modificado_por,
                   fec_modificacion,
                   num_documento)
           values (:emision.cod_empresa,
                   consecutivo,
                   numero_cd,
                   vcontador,
                   'CD',
                   'I',
                   null,
                   monto_cd,
                   :variables.usuario,
                   sysdate,
                   null,
                   null,
                   null);
                   exception
										when others
										then
										   utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error insertando en detalle movimiento Caja '||sqlerrm);
										   clear_form (no_validate);
										   rollback;
										   execute_trigger ('WHEN-NEW-FORM-INSTANCE');
										   raise form_trigger_failure;
				end;
--p_depura('jsq conexion_con_cajas 7 ');
      -- Se registra la emision de cada certificado como un movimiento en la tabla cd_movimiento ...
      --Rvelilla 20/12/2016 Reestructuracion Tabla CD_Movimientos, se agregan nuevos parametros al procedimiento
		     begin
		      cd_inserta_movimiento_cap (:emision.cod_empresa,
				                              numero_cd,
				                              :variables.codsistema,
				                              1,
				                              vcodigo_subtransaccion,
				                              null,
				                              null,
				                              :variables.fecha,
				                              null,
		                                  monto_cd,--p_valor_mvto
		                                  :emision.cod_producto,
																		  :variables.codagencia,
																		  :pblock.tip_certificado,
																		  :bkproducto.cod_moneda,
																		  'A',--p_estado
																				monto_cd,--p_monto
																				null,--p_cre_interes
																				null,--p_cre_mes
																				null,--p_tas_bruta
																				null,--p_tas_neta
																				null,--p_mon_int_x_pagar
																				null,--p_mon_acum_int_cap
																				null,--p_mon_interes_pagado
																				null,--p_mon_int_ganado
																				null,--p_porcentaje_renta
																				null,--p_base_calculo
																				null,--p_mon_descuento
																				null,--p_cod_tasa
																				null,--p_base_plazo
																				'CDFEMICE CONEXION_CON_CAJAS V2',
																				:variables.asiento_contable);
																				exception
																					   when others
																					   then
																					      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error creando movimiento CDs '||sqlerrm);
																					      clear_form (no_validate);
																					      rollback;
																					      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
																					      raise form_trigger_failure;
																	end;
--p_depura('jsq conexion_con_cajas 8 ');
      -- Se actualizan los certificados generados con el numero de asiento y la solicitud de cajas
      -- correspondientes ...
      begin
      update cd_certificado
         set numero_asiento_contable = :variables.asiento_contable,
             numero_solicitud_cajas = :variables.solicitud
       where cod_empresa = :emision.cod_empresa
         and num_certificado = numero_cd;
         if sql%notfound then
		      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error actualizando CDs '||sqlerrm);
		      clear_form (no_validate);
		      rollback;
		      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
		      raise form_trigger_failure;
         	end if;
        end; 
--p_depura('jsq conexion_con_cajas 9 ');
      vcontador := vcontador + 1;
      if vcontador <= total_certificados
      then
         next_record;
      end if;
   end loop;
exception
   when others
   then
      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) Error genérico - Final-'||sqlerrm);
      clear_form (no_validate);
      rollback;
      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
      raise form_trigger_failure;
end;

procedure conexion_con_cajas_old (cual_bloque number, pc_control varchar2, pn_monto number)
is
   consecutivo              number     := 0;
   observa2                 varchar2 (100) := null;
   vcontador                number;
   total_certificados       number         := 0;
   total_monto              number         := 0;
   -- Jsanchez
   -- Se cambia el parametro de number a varchar
   -- numero_cd                number         := 0;
   numero_cd                varchar2(15);
   monto_cd                 number         := 0;
   numero_cliente           varchar2 (8);
   vcodigo_subtransaccion   number (3);
begin
--p_depura('jsq conexion_con_cajas 1');
   vcodigo_subtransaccion := :variables.codigo_subtrans_cd;
   --
   if cual_bloque = 0
   then                                                                          -- es el bloque de certificados con cupones
--p_depura('jsq conexion_con_cajas 1 bloque 0');
      total_certificados := :pblock.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock.total_monto;
      else
         total_monto := pn_monto;
      end if;
      go_block ('PBLOCK');
   elsif cual_bloque = 1
   then                                                             -- es el bloque de certificados a la vista capitalizables
--p_depura('jsq conexion_con_cajas 1 bloque 1');
      go_block ('PBLOCK1');
      total_certificados := :pblock1.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock1.total_monto;
      else
         total_monto := pn_monto;
      end if;
   elsif cual_bloque = 2
   then                                                                            -- es el bloque de certificados a la vista
--p_depura('jsq conexion_con_cajas 1 bloque 2');
      go_block ('PBLOCK2');
      total_certificados := :pblock2.total_cds;
      -- Jsanchez
      if pc_control = 'N'
      then
         total_monto := :pblock2.total_monto;
      else
         total_monto := pn_monto;
      end if;
   end if;
--p_depura('jsq conexion_con_cajas 2');
   -- Se determina el numero de solicitud de ingreso en Cajas ...
   consecutivo_ingresos (consecutivo);
   :variables.solicitud := consecutivo;
--p_depura('jsq conexion_con_cajas 3');
   -- Busca el campo NUM_CLIENTE asociado al COD_CLIENTE en la tabla CLIENTE que es lo que hay que enviar a cajas...
   begin
      select num_cliente
        into numero_cliente
        from cliente
       where cod_empresa = :emision.cod_empresa
         and cod_cliente = :emision.cliente;
   exception
      when no_data_found
      then
         utilitarios.mensaje ('000129', :variables.codidioma, 'CD');
         raise form_trigger_failure;
   end;
--p_depura('jsq conexion_con_cajas 4');
   -- Inserta en bcj_solicitud el comprobante de ingreso para ser atendido en el area de Cajas...
   genera_solicitud_cajas (:emision.cod_empresa,
                           :variables.codagencia,                                  -- lperez 06/06/2006 :emision.cod_agencia,
                           consecutivo,
                           :bkproducto.cod_moneda,
                           numero_cliente,                -- :emision.cliente se sustituye para lograr consistencia con cajas
                           total_monto,
                           :emision.fecha_emision,
                           :variables.asiento_contable,
                           null);
--p_depura('jsq conexion_con_cajas 5');
   -- Se relacionan cada uno de los certificados emitidos con el comprobante de ingreso en cajas
   first_record;
   vcontador := 1;
   while vcontador <= total_certificados
   loop
      if cual_bloque = 0
      then                                                                       -- es el bloque de certificados con cupones
         numero_cd := :pblock.num_certificado;
         monto_cd := :pblock.monto;
      elsif cual_bloque = 1
      then                                                          -- es el bloque de certificados a la vista capitalizables
         numero_cd := :pblock1.num_certificado;
         monto_cd := :pblock1.monto;
      elsif cual_bloque = 2
      then                                                                         -- es el bloque de certificados a la vista
         numero_cd := :pblock2.num_certificado;
         monto_cd := :pblock2.monto;
      end if;
--p_depura('jsq conexion_con_cajas 6 '||cual_bloque||'** '||numero_cd||'*** '||monto_cd);
      --
      insert into cd_det_ing_caja
                  (cod_empresa,
                   num_solicitud,
                   num_certificado,
                   ord_linea,
                   tip_linea,
                   tip_operacion,
                   num_cupon,
                   monto,
                   adicionado_por,
                   fec_adicion,
                   modificado_por,
                   fec_modificacion,
                   num_documento)
           values (:emision.cod_empresa,
                   consecutivo,
                   numero_cd,
                   vcontador,
                   'CD',
                   'I',
                   null,
                   monto_cd,
                   :variables.usuario,
                   sysdate,
                   null,
                   null,
                   null);
--p_depura('jsq conexion_con_cajas 7 ');
      -- Se registra la emision de cada certificado como un movimiento en la tabla cd_movimiento ...
      --Rvelilla 20/12/2016 Reestructuracion Tabla CD_Movimientos, se agregan nuevos parametros al procedimiento
      cd_inserta_movimiento_cap (:emision.cod_empresa,
                             numero_cd,
                             :variables.codsistema,
                             1,
                             vcodigo_subtransaccion,
                             null,
                             null,
                             :variables.fecha,
                             null,
                                    monto_cd,--p_valor_mvto
                                   	:emision.cod_producto,
																		:variables.codagencia,
																		:pblock.tip_certificado,
																	  :bkproducto.cod_moneda,
																	  'A',--p_estado
																		monto_cd,--p_monto
																		null,--p_cre_interes
																		null,--p_cre_mes
																		null,--p_tas_bruta
																		null,--p_tas_neta
																		null,--p_mon_int_x_pagar
																		null,--p_mon_acum_int_cap
																		null,--p_mon_interes_pagado
																		null,--p_mon_int_ganado
																		null,--p_porcentaje_renta
																		null,--p_base_calculo
																		null,--p_mon_descuento
																		null,--p_cod_tasa
																		null,--p_base_plazo
																		'CDFEMICE CONEXION_CON_CAJAS.',
																		:variables.asiento_contable);
--p_depura('jsq conexion_con_cajas 8 ');
      -- Se actualizan los certificados generados con el numero de asiento y la solicitud de cajas
      -- correspondientes ...
      update cd_certificado
         set numero_asiento_contable = :variables.asiento_contable,
             numero_solicitud_cajas = :variables.solicitud
       where cod_empresa = :emision.cod_empresa
         and num_certificado = numero_cd;
--p_depura('jsq conexion_con_cajas 9 ');
      vcontador := vcontador + 1;
      if vcontador <= total_certificados
      then
         next_record;
      end if;
   end loop;
exception
   when others
   then
      utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, '(02) '||sqlerrm);
      clear_form (no_validate);
      rollback;
      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
      raise form_trigger_failure;
end;

procedure conexion_con_contabilidad (cual_bloque number)
is
   vcontador                number         := 0;
   mensaje_error            varchar2 (150);
   tipo_cambio1             number;
   tipo_cambio2             number;
   referencia               varchar2 (30)  := null;
   vreg_actual              number;
   total_certificados       number;
   cuenta_contable          varchar2 (30);
   monto_cd                 number;
   vcodigo_transaccion      number;
   vcodigo_subtransaccion   number;
begin
   begin
      select valor
        into vcodigo_subtransaccion
        from parametros_x_empresa
       where cod_empresa = :variables.codempresa
         and cod_sistema = 'CD'
         and abrev_parametro = 'SUBTIPO_EMICD_NUEVO';
   exception
      when no_data_found
      then
         utilitarios.mensaje ('000526', :variables.codidioma, :variables.codsistema);
         raise form_trigger_failure;
   end;
   if cual_bloque = 0
   then                                                                           -- es el bloque de certificados con cupones
      total_certificados := :pblock.total_cds;
      go_block ('PBLOCK');
   elsif cual_bloque = 1
   then                                                             -- es el bloque de certificados a la vista capitalizables
      total_certificados := :pblock1.total_cds;
      go_block ('PBLOCK1');
   elsif cual_bloque = 2
   then                                                                            -- es el bloque de certificados a la vista
      total_certificados := :pblock2.total_cds;
      go_block ('PBLOCK2');
   end if;
   -- Se procede a construir la informacion de referencia sobre los
   --  certificados creados ...
   first_record;
   vreg_actual := :system.cursor_record;
   :variables.inf_referencia := null;
   if total_certificados = 1
   then
      :variables.inf_referencia := :etiquetas.et_emision_unica;
      if cual_bloque = 0
      then
         :variables.inf_referencia := :variables.inf_referencia || :pblock.num_certificado;
      elsif cual_bloque = 1
      then
         :variables.inf_referencia := :variables.inf_referencia || :pblock1.num_certificado;
      elsif cual_bloque = 2
      then
         :variables.inf_referencia := :variables.inf_referencia || :pblock2.num_certificado;
      end if;
   else
      :variables.inf_referencia := :etiquetas.et_emision_multiple;
      vcontador := 1;
      while vcontador <= total_certificados
      loop
         if cual_bloque = 0
         then
            :variables.inf_referencia := :variables.inf_referencia || :pblock.num_certificado || '-';
         elsif cual_bloque = 1
         then
            :variables.inf_referencia := :variables.inf_referencia || :pblock1.num_certificado || '-';
         elsif cual_bloque = 2
         then
            :variables.inf_referencia := :variables.inf_referencia || :pblock2.num_certificado || '-';
         end if;
         vcontador := vcontador + 1;
         if vcontador <= total_certificados
         then
            next_record;
         end if;
      end loop;
   end if;
   -- Se procede a crear el encabezado del asiento contable (cg_movimiento_resumen)...
   caratula_del_asiento (to_number (:emision.cod_empresa),
                         to_number (:emision.cod_agencia),
                         'BCD',                                                                                 -- aplicacion
                         to_number (:emision.cod_producto),                                                 -- sub aplicacion
                         1,                                                                                    -- transaccion
                         vcodigo_subtransaccion,                                             -- sub transaccion EMISION NUEVA
                         total_certificados,                                  -- numero_transaccion (total de cds contenidos)
                         :variables.inf_referencia,
                         :emision.fecha_emision,
                         :variables.fecha,
                         :variables.asiento_contable,
                         :variables.usuario,
                         mensaje_error);
   if (mensaje_error is not null)
   then
      utilitarios.mensaje ('100084',
                           :variables.codidioma,
                           'PA',
                           acknowledge,
                           '(03) '||mensaje_error);
      --
      utilitarios.mensaje ('000481', :variables.codidioma, 'CD');
      rollback;
      execute_trigger ('WHEN-NEW-FORM-INSTANCE');
      raise form_trigger_failure;
   end if;
   vcontador := 1;
   first_record;
   while vcontador <= total_certificados
   loop
      if cual_bloque = 0
      then                                                                       -- es el bloque de certificados con cupones
         cuenta_contable := :pblock.cuenta_contable;
         monto_cd := :pblock.monto;
      elsif cual_bloque = 1
      then                                                          -- es el bloque de certificados a la vista capitalizables
         cuenta_contable := :pblock1.cuenta_contable;
         monto_cd := :pblock1.monto;
      elsif cual_bloque = 2
      then                                                                         -- es el bloque de certificados a la vista
         cuenta_contable := :pblock2.cuenta_contable;
         monto_cd := :pblock2.monto;
      end if;
--p_depura('jsq a --> '||cual_bloque|| ' - '||cuenta_contable|| ' - ' ||monto_cd);
      lineas_del_asiento (to_number (:emision.cod_empresa),
                          to_number (:emision.cod_agencia),
                          'BCD',                                                                      -- codigo de aplicacion
                          to_number (:emision.cod_producto),                                            -- codigo de producto
                          1,                                                                                   -- transaccion
                          vcodigo_subtransaccion,                                            -- sub transaccion EMISION NUEVA
                          to_char (total_certificados),                              -- numero de transaccion   EMISION NUEVA
                          :variables.inf_referencia,
                          :emision.fecha_emision,
                          :emision.fecha_emision,
                          :variables.fecha,
                          to_number (:variables.asiento_contable),
                          cuenta_contable,
                          0,                                                                                      -- auxiliar
                          monto_cd,
                          'S',                                                                              -- acumula montos
                          'C',                                                                     -- tipo movimiento Credito
                          'N',                                                                         -- modifica movimiento
                          tipo_cambio1,
                          tipo_cambio2,
                          :variables.usuario,
                          mensaje_error,
                          referencia);
--p_depura('jsq a1 --> '||mensaje_error);
      if (mensaje_error is not null)
      then
         message (mensaje_error);
         message (' ', no_acknowledge);
         clear_form (no_validate);
         rollback;
         execute_trigger ('WHEN-NEW-FORM-INSTANCE');
         raise form_trigger_failure;
      end if;
      vcontador := vcontador + 1;
      if vcontador <= total_certificados
      then
         next_record;
      end if;
   end loop;
end;

PROCEDURE CONSECUTIVO_INGRESOS(Consecutivo in out number) IS
 vnivel number;
BEGIN
      -- EFECTUA: Obitiene el siguiente numero para los comprobantes de
      --          ingreso de cajas.
      -- EscritO: Por Bernal Blanco
      -- Modificado : Ericka Solano 05/11/1998 Esolano para que tome el valor
      --              la tabla BCJ_PARAMETROS_AGENCIA

   /*begin
      select nvl(CONSECUTIVO_SOLIC_INGRESOS,1)
      into consecutivo
      from BCJ_PARAMETROS_AGENCIA
      where codigo_empresa = :emision.COD_EMPRESA
        and codigo_agencia = :variables.codagencia-- lperez 06/06/2006 :emision.COD_AGENCIA
      for update of CONSECUTIVO_SOLIC_INGRESOS ;
   exception 
      when no_data_found then
        UTILITARIOS.mensaje('000505',:variables.CodIdioma, 'CD');
        raise form_trigger_failure;
   end ;*/
begin
	select BCJ_RECIB_INGRESO.nextval into consecutivo from dual;      
	end;
   /*update BCJ_PARAMETROS_AGENCIA
   set CONSECUTIVO_SOLIC_INGRESOS = Consecutivo + 1 
      where codigo_empresa = :emision.COD_EMPRESA
        and codigo_agencia = :variables.codagencia;*/-- lperez 06/06/2006 :emision.COD_AGENCIA
   vnivel := :system.message_level;
   :system.message_level := 25;     
   post;
   :system.message_level := vnivel;
END;

PROCEDURE CONSECUTIVO_INGRESOS_old(Consecutivo in out number) IS
 vnivel number;
BEGIN
      -- EFECTUA: Obitiene el siguiente numero para los comprobantes de
      --          ingreso de cajas.
      -- EscritO: Por Bernal Blanco
      -- Modificado : Ericka Solano 05/11/1998 Esolano para que tome el valor
      --              la tabla BCJ_PARAMETROS_AGENCIA

   begin
      select nvl(CONSECUTIVO_SOLIC_INGRESOS,1)
      into consecutivo
      from BCJ_PARAMETROS_AGENCIA
      where codigo_empresa = :emision.COD_EMPRESA
        and codigo_agencia = :variables.codagencia-- lperez 06/06/2006 :emision.COD_AGENCIA
      for update of CONSECUTIVO_SOLIC_INGRESOS ;
   exception 
      when no_data_found then
        UTILITARIOS.mensaje('000505',:variables.CodIdioma, 'CD');
        raise form_trigger_failure;
   end ;
   update BCJ_PARAMETROS_AGENCIA
   set CONSECUTIVO_SOLIC_INGRESOS = Consecutivo + 1 
      where codigo_empresa = :emision.COD_EMPRESA
        and codigo_agencia = :variables.codagencia;-- lperez 06/06/2006 :emision.COD_AGENCIA
   vnivel := :system.message_level;
   :system.message_level := 25;     
   post;
   :system.message_level := vnivel;
END;

PROCEDURE Creando_CDS_con_CUPONES IS
  
  vError            varchar2(100);
  vSqlError         varchar2(100);
  vreg_actual       number;


begin
  vreg_actual := :system.cursor_record ;
  :system.message_level := 25 ;
  post;
  :system.message_level := 0 ;
  go_block('pblock');
  go_record (vreg_actual) ;
  if :pblock.dia_pago_int is null then
     Generacion_Cupones ;  -- Crea los cupones para el certificado actual en proceso
  else
   	 Generacion_Cupones_Dia_Pago ;  -- Crea los cupones para el certificado actual en proceso
  end if;
end ;

procedure CreaVarGlobales is
--EFECTUA : Crea las variables globales en caso de que 
--          no existan y almacena los valores en
--          variables locales.
--HISTORIA: ymur : 06/feb/97 : redefinicion

begin

   default_value('AALMONTE', 'GLOBAL.Usuario');
   default_value('1', 'GLOBAL.CodEmpresa');
   default_value('NO', 'GLOBAL.NomEmpresa');
   default_value('10005', 'GLOBAL.CodAgencia');
   default_value('NO', 'GLOBAL.NomAgencia');
   default_value('ESPA', 'GLOBAL.CodIdioma');
   default_value('CD', 'GLOBAL.CodSisMenu');
--   default_value(null, 'GLOBAL.Fecha');
   default_value(null, 'GLOBAL.solicitud');

   --Almacena los valores en variables locales
   :variables.usuario    := :GLOBAL.Usuario;
   :variables.CodEmpresa := :GLOBAL.CodEmpresa;
   :variables.NomEmpresa := :GLOBAL.NomEmpresa;
   :variables.CodAgencia := :GLOBAL.CodAgencia;
   :variables.NomAgencia := :GLOBAL.NomAgencia;
   :variables.CodIdioma  := :GLOBAL.CodIdioma;
   :variables.CodSisMenu := :GLOBAL.CodSisMenu;
--   :variables.Fecha      := :GLOBAL.Fecha;
   :variables.solicitud  := :GLOBAL.solicitud;

   --En esta seccion deben ser borradas los variables
   --globales adicionales que fueron utilizadas solamente
   -- para invocar la esta pantalla
   --
   -- Por ejemplo:
   -- erase('GLOBAL.CodClienteEspecial');
end;

-- Standard delete timer procedure. Is part of iconic button tool tips.
PROCEDURE DEL_TIMER (tm_name Varchar2 )IS
  tm_id timer;
BEGIN
  tm_id := find_timer(tm_name);
  if not id_null(tm_id) then 
    delete_timer(tm_id);
  end if;
END;

procedure determine_tasa (cual_bloque in varchar2)
is
   v_monto            number (17, 2);
   vf_inicio          date;
   vf_final           date;
   v_dias             number (5);
   v_empresa          varchar2 (3);
   v_producto         varchar2 (5);
   v_cliente          varchar2 (15);
   vbase_plazo        number (3);
   v_frecuencia       varchar2 (1);
   v_cod_tasa         varchar2 (5);
   v_spread           number (8, 4);
   v_operacion        varchar2 (1);
   v_tasa_neta        number (8, 4);
   v_tasa_bruta       number (8, 4);
   v_error            varchar2 (4000);
   v_sqlcode          number (6);
   v_fecha_vigencia   date;
   nValortasa 					number;
   ncontrol		number;
   --
   vn_acumulado       number (21, 9);
   vrenovacion			varchar2(1):='N';
begin
--
--p_depura('jsq determina_tasa 0 '||cual_bloque);
   -- Inicializa las variables dependiendo del tipo de certificado o del bloque donde se haga el llamado...
   if cual_bloque = 'CU' then
      v_empresa := :pblock.cod_empresa;
      v_producto := :pblock.cod_producto;
      v_monto := :pblock.monto;
      v_cliente := :pblock.cliente;
      vf_inicio := :variables.fecha;
      vf_final := :pblock.fec_vencimiento;
      vbase_plazo := :bkproducto.base_plazo;
      v_frecuencia := :pblock.tip_plazo;
      cd_calcula_dias (vf_inicio, vf_final, vbase_plazo, v_frecuencia, v_dias);
   elsif cual_bloque = 'CA' then
      v_empresa := :pblock2.cod_empresa;
      v_producto := :pblock2.cod_producto;
      v_monto := :pblock2.monto;
      v_cliente := :pblock2.cliente;
      vf_inicio := :variables.fecha;
      vf_final := :pblock2.fec_vencimiento;
      vbase_plazo := :bkproducto.base_plazo;
      v_frecuencia := :pblock2.tip_plazo;
      cd_calcula_dias (vf_inicio, vf_final, vbase_plazo, v_frecuencia, v_dias);
--
--p_depura('jsq determina_tasa ');
   elsif cual_bloque = 'VI' then
      v_empresa := :pblock1.cod_empresa;
      v_producto := :pblock1.cod_producto;
      v_monto := :pblock1.monto;
      v_cliente := :pblock1.cliente;
      vf_inicio := :variables.fecha;
      vf_final := :pblock1.fec_emision;
      vbase_plazo := :bkproducto.base_plazo;
      v_dias := 0;
   end if;
   --
   -- Jsanchez
   -- Acumulado por Cliente
   /*begin
      select nvl (sum (a.monto), 0)
        into vn_acumulado
        from cd_certificado a
       where cod_empresa = v_empresa
         and cliente = v_cliente
         and cod_moneda = :bkproducto.cod_moneda
         and estado = 'A';
   exception
      when others
      then
         vn_acumulado := 0;
   end;*/
   begin
						Select ind_renovacion_auto
						into vrenovacion
						 from cd.cd_producto_x_empresa 
                   where cod_empresa=:pblock1.cod_empresa 
                                 And cod_producto=:pblock1.cod_producto 
                                And ind_renovacion_auto='S';
   exception
   	when no_data_found then
   	vrenovacion:='';
   end;
   if nvl(vrenovacion,'N')='S' then
   begin
      select nvl (sum (a.monto), 0)
        into vn_acumulado
        from cd_certificado a
       where cod_empresa = v_empresa
         and cliente = v_cliente
         and cod_moneda = :bkproducto.cod_moneda
         and estado = 'A';/*
         and cod_producto In (Select cod_producto from cd.cd_producto_x_empresa 
                               where cod_empresa=:pblock1.cod_empresa 
                                 And cod_producto=:pblock1.cod_producto 
                                 And ind_renovacion_auto='S');*/
   exception
      when others
      then
         vn_acumulado := 0;
   end;
   else
   	vn_acumulado := 0;
end if;
   --
   v_monto := v_monto + vn_acumulado;
--
--p_depura('jsq v_monto '||v_monto ||' - '||v_empresa ||' - '||v_producto ||' - '||v_monto ||' - '||v_cliente ||' - '||vf_inicio ||' - '||vf_final ||' - '||vbase_plazo ||' - '||v_frecuencia);
   --
   if :bkproducto.a_la_vista = 'S' then
      begin
--p_depura('jsq select 1');
         select cod_tasa,
                spread,
                operacion,
                fecha_vigencia
           into v_cod_tasa,
                v_spread,
                v_operacion,
                v_fecha_vigencia
           from cd_vis_cli_tasa_monto
          where cod_empresa = v_empresa
            and cod_producto = v_producto
            and estado = 'A'
            and cod_cliente = v_cliente
            and v_monto between monto_minimo and monto_maximo
            and fecha_vigencia in (
                  select max (fecha_vigencia)
                    from cd_vis_cli_tasa_monto
                   where cod_empresa = v_empresa
                     and cod_producto = v_producto
                     and estado = 'A'
                     and cod_cliente = v_cliente
                     and v_monto between monto_minimo and monto_maximo
                     and fecha_vigencia <= vf_inicio);
      exception
         when no_data_found then
            begin
--p_depura('jsq select 2');
               select cod_tasa,
                      spread,
                      operacion,
                      fecha_vigencia
                 into v_cod_tasa,
                      v_spread,
                      v_operacion,
                      v_fecha_vigencia
                 from cd_vis_prd_tasa_monto
                where cod_empresa = v_empresa
                  and cod_producto = v_producto
                  and estado = 'A'
                  and v_monto between monto_minimo and monto_maximo
                  and fecha_vigencia in (
                        select max (fecha_vigencia)
                          from cd_vis_prd_tasa_monto
                         where cod_empresa = v_empresa
                           and cod_producto = v_producto
                           and estado = 'A'
                           and v_monto between monto_minimo and monto_maximo
                           and fecha_vigencia <= vf_inicio);
            exception
               when no_data_found
               then
                  utilitarios.mensaje ('000172', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
                  raise form_trigger_failure;
               when others
               then
                  utilitarios.mensaje ('000174', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
                  raise form_trigger_failure;
            end;
         when others then
            utilitarios.mensaje ('000173', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
            raise form_trigger_failure;
      end;
   else
      begin
--p_depura('jsq select 3');
         select cod_tasa,
                spread,
                operacion,
                fecha_vigencia
           into v_cod_tasa,
                v_spread,
                v_operacion,
                v_fecha_vigencia
           from cd_cli_tasa_plazo_monto
          where cod_empresa = v_empresa
            and cod_producto = v_producto
            and estado = 'A'
            and cod_cliente = v_cliente
            and v_monto between monto_minimo and monto_maximo
            and v_dias between plazo_minimo and plazo_maximo
            and fecha_vigencia in (
                  select max (fecha_vigencia)
                    from cd_cli_tasa_plazo_monto
                   where cod_empresa = v_empresa
                     and cod_producto = v_producto
                     and estado = 'A'
                     and cod_cliente = v_cliente
                     and v_monto between monto_minimo and monto_maximo
                     and v_dias between plazo_minimo and plazo_maximo
                     and fecha_vigencia <= vf_inicio);
      exception
         when no_data_found
         then
            begin
--p_depura('jsq 1 cdfemice '||v_empresa||'-'||v_producto||'-'||v_monto||'-'||v_dias||'-'||vf_inicio);
              /* select a.cod_tasa,
                      a.spread,
                      a.operacion,
                      a.fecha_vigencia
                 into v_cod_tasa,
                      v_spread,
                      v_operacion,
                      v_fecha_vigencia
                 from cd_prd_tasa_plazo_monto a
                where a.cod_empresa = v_empresa
                  and a.cod_producto = v_producto
                  and a.estado = 'A'
                  and v_monto between a.monto_minimo and a.monto_maximo
                  -- jsanchez (06/02/2016)
                  -- se adiciona nvl
                  and nvl (v_dias, 0) between a.plazo_minimo and a.plazo_maximo
                  -- and fecha_vigencia <= vf_inicio;
                  and a.fecha_vigencia in (select max (b.fecha_vigencia)
                                             from cd_prd_tasa_plazo_monto b
                                            where a.cod_empresa = b.cod_empresa
                                              and a.cod_producto = b.cod_producto
                                              and a.estado = b.estado
                                              and v_monto between b.monto_minimo and b.monto_maximo
                                              and nvl (v_dias, 0) between b.plazo_minimo and b.plazo_maximo
                                              and b.fecha_vigencia <= vf_inicio);*/
           begin
           		ncontrol:= CD.pkg_cd_inter.Obtiene_CDTasActual( v_empresa,  v_producto, v_dias, v_monto, v_cod_tasa , v_spread, v_operacion, nValortasa);
															                             
							if ncontrol=0 then
										utilitarios.mensaje ('000162', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
              			raise form_trigger_failure;
								end if;
           end;
           
            exception
               /*when no_data_found
               then
                  utilitarios.mensaje ('000162', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
                  raise form_trigger_failure;
               when too_many_rows
               then
                  utilitarios.mensaje ('000571', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
                  raise form_trigger_failure;*/
               when others
               then
                  utilitarios.mensaje ('000171', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
                  raise form_trigger_failure;
            end;
         when others
         then
            utilitarios.mensaje ('000163', name_in ('variables.codidioma'), name_in ('variables.codsistema'));
            raise form_trigger_failure;
      end;
   end if;
   -- Va a averiguar el valor de la tasa de interes registrada por medio del codigo v_cod_tasa...
   v_tasa_bruta := CD.pkg_cd_inter.CD_TASINTERES_BASE(v_empresa, v_cod_tasa, :variables.fecha, v_error, v_sqlcode);
   if v_error = '000038' then
      utilitarios.mensaje (v_error, :variables.codidioma, :variables.codsistema);
      raise form_trigger_failure;
   elsif v_error = '000523'
   then
      utilitarios.mensaje_error (v_error, :variables.codidioma, :variables.codsistema, v_sqlcode);
      raise form_trigger_failure;
   end if;
   -- se determina la tasa neta real tomando en cuenta el spread, retornando ademas la tasa bruta...
   CD.pkg_cd_inter.cd_calcula_tasa_neta (v_tasa_bruta, v_spread, nvl (:emision.porcentaje_renta, 0), v_tasa_neta, v_operacion, v_error);
   
   if cual_bloque = 'CU' then
      :pblock.tas_neta := v_tasa_neta;
      :pblock.tas_bruta := v_tasa_bruta;
      :pblock.cod_tasa := v_cod_tasa;
   elsif cual_bloque = 'VI' then
      :pblock1.tas_neta := v_tasa_neta;
      :pblock1.tas_bruta := v_tasa_bruta;
      :pblock1.cod_tasa := v_cod_tasa;
   elsif cual_bloque = 'CA' then
      :pblock2.tas_neta := v_tasa_neta;
      :pblock2.tas_bruta := v_tasa_bruta;
      :pblock2.cod_tasa := v_cod_tasa;
--
--p_depura('jsq determina_tasa 2 '||:pblock2.tas_neta||'-'||:pblock2.tas_bruta||'-'||:pblock2.cod_tasa);
   end if;
   :variables.tasa_original := :pblock2.tas_neta;
   :variables.tasa_bruta := v_tasa_bruta;
   :variables.tasa_neta := v_tasa_neta;
end;

 procedure direccionar_bloque (pforma varchar2)
is
begin
   :system.message_level := 25;
   if (pforma in ('VCF', 'VCV', 'VF', 'VV'))
   then
      go_block ('PBLOCK2');
      clear_block (no_validate);
      go_block ('PBLOCK');
      clear_block (no_validate);
      if :pblock1.cod_producto <> :emision.cod_producto
      then
         go_block ('PBLOCK1');                                                     -- Aunque el bloque 2 ya este desplegado,
         clear_block (no_validate);                                                    -- deben digitarse los datos de nuevo
      else
         go_block ('PBLOCK1');
      end if;
   elsif pforma = 'CU'
   then
      go_block ('PBLOCK1');
      clear_block (no_validate);
      go_block ('PBLOCK2');
      clear_block (no_validate);
      if :pblock.cod_producto <> :emision.cod_producto
      then
         go_block ('PBLOCK');                                                      -- Aunque el bloque 2 ya este desplegado,
         clear_block (no_validate);                                                    -- deben digitarse los datos de nuevo
      else
         go_block ('PBLOCK');
      end if;
   elsif pforma in ('CF', 'CV')
   then
      go_block ('PBLOCK1');
      clear_block (no_validate);
      go_block ('PBLOCK');
      clear_block (no_validate);
      if :pblock2.cod_producto <> :emision.cod_producto
      then
         go_block ('PBLOCK2');                                                     -- Aunque el bloque 2 ya este desplegado,
         clear_block (no_validate);                                                    -- deben digitarse los datos de nuevo
      else
         go_block ('PBLOCK2');
      end if;
   end if;
   first_record;
   :system.message_level := 0;
exception
   when others
   then
      utilitarios.mensaje ('000064', :variables.codidioma, 'CD');
end;

procedure generacion_cupones
is
   vcantcupones         number (5)     := 0;
   vcuponessobran       number (5)     := 0;
   vdiassobran          number (5)     := 0;
   vcuponesnormales     number (5)     := 0;
   vdias_normales       number (5);
   hay_ajuste           boolean;
   vtotaldias           number (5)     := 0;
   vcontador            number (5)     := 0;
   vcontador_normal     number (5)     := 0;
   vcontador_especial   number         := 0;
   vmonto_cupon_neto    number (17, 2);
   vmonto_cupon_bruto   number (17, 2);
   vfrecuencia          varchar2 (1);
   vfven_cupon          date;
   vfecha_arranque      date;
   vplazo_ints          number (5);
   vdias                number (5);
   habra_ajuste         varchar2 (5);
   vestadocupon         varchar2 (1);
begin
   -- Este proceso determina las caracteristicas de los cupones que se deben generar dejando los
   -- valores en las siguientes variables
   -- VCANTCUPONES : Cantidad Total de cupones a generar
   -- VCUPONESNORMALES : Cantidad de cupones enteros de VDIAS_NORMALES dias
   -- VCUPONESSOBRAN : Cantidad de cupones especiales a generar de VDIASSOBRAN dias
   -- Finalmente la variable HAY_AJUSTE indicara si se debe hacer algun ajuste en algun cupon ...
   
   --if :variables.control = 'S'
   if tiene_forma_pago = 'S'
   then
      vestadocupon := 'A';
   else
      vestadocupon := 'I';
   end if;
   hay_ajuste := false;
   if :pblock.tip_plazo = :pblock.fre_capitaliza
   then
      -- En este caso la unica posibilidad es que los dos sean meses
      vcantcupones := trunc (:pblock.plazo / :pblock.pla_capitaliza);
      vcuponesnormales := vcantcupones;
      vcuponessobran := mod (:pblock.plazo, :pblock.pla_capitaliza);
      if vcuponessobran <> 0
      then
         vdiassobran := vcuponessobran * 30;
         vcuponessobran := 1;
      end if;
   elsif :pblock.fre_capitaliza = 'V'
   then
      vcantcupones := 1;
      vcuponesnormales := 1;
      vcuponessobran := 0;
      vdiassobran := 0;
   elsif :pblock.tip_plazo = 'D'
   then
      vtotaldias := :pblock.pla_capitaliza * 30;
      vcantcupones := trunc (:pblock.pla_dias / vtotaldias);
      vcuponesnormales := vcantcupones;
      vdiassobran := mod (:pblock.pla_dias, vtotaldias);
   end if;
   if (vdiassobran > 0)
   then
      if vdiassobran < :bkproducto.num_dias
      then
         vcuponesnormales := vcuponesnormales - 1;
         vcuponessobran := 1;
         vdiassobran := 30 + vdiassobran;
         hay_ajuste := true;
      else
         vcuponessobran := 1;
         vcantcupones := vcantcupones + 1;
      end if;
   end if;
   -- Se define el plazo en dias de los cupones normales o al vencimiento que se generaran en vdias_normales.
   -- Los casos especiales se manejaran utilizando los valores de vCuponesSobran y vDiasSobran
   -- Esolano 19/10/98
   if :pblock.fre_capitaliza = 'V'
   then                                                                     -- los dias de capitalizacion son el plazo del cd
      if :pblock.tip_plazo = 'D'
      then
         vdias_normales := :pblock.pla_dias;
      else
         vdias_normales := :pblock.plazo * 30;
      end if;
   else                                         -- el pago de intereses es en meses y pueden existir o no cupones adicionales
      vdias_normales := :pblock.pla_capitaliza * 30;
   end if;
   -- Aqui comenzaria la generacion de los cupones con fechas y demas ...
   vfecha_arranque := :emision.fecha_emision;
   vfrecuencia := 'D';
   vcontador := 1;
   vcontador_normal := 0;
   vcontador_especial := 0;
   --  Se procede a generar los cupones "normales"
   while vcontador <= vcantcupones
   loop
      if (hay_ajuste)
         and (:pblock.ajusta = 'I')
         and (vcontador = 1)
         and (vcontador_especial <> vcuponessobran)
      then
         vdias := vdiassobran;
         vcontador_especial := vcontador_especial + 1;
      elsif (hay_ajuste)
            and (:pblock.ajusta = 'F')
            and (vcontador = vcantcupones)
            and (vcontador_especial <> vcuponessobran)
      then
         vdias := vdiassobran;
         vcontador_especial := vcontador_especial + 1;
      elsif (not hay_ajuste)
            and (vcontador = vcantcupones)
            and (vcontador_especial <> vcuponessobran)
      then
         vdias := vdiassobran;
         vcontador_especial := vcontador_especial + 1;
      else
         vdias := vdias_normales;
         vcontador_normal := vcontador_normal + 1;
      end if;
      vmonto_cupon_bruto := cd_cal_interes (:pblock.monto, :pblock.tas_bruta, :bkproducto.base_calculo, vdias);
      vmonto_cupon_neto := cd_cal_interes (:pblock.monto, :pblock.tas_neta, :bkproducto.base_calculo, vdias);
      cd_fecha_exacta (vfecha_arranque, :bkproducto.base_plazo, vdias, vfrecuencia, vfven_cupon, vplazo_ints);
      -- Llena los campos del bloque CUPO donde se guardara el registro de cupones ...
      insert into cd_cupon
                  (cod_empresa,
                   num_certificado,
                   numero_cupon,
                   monto_bruto,
                   estado,
                   monto_neto,
                   fecha_vencimiento,
                   fecha_pago,
                   contador_impresion,
                   utilizado,
                   excento,
                   adicionado_por,
                   fecha_adicion,
                   modificado_por,
                   fecha_modificacion,
                   observacion,
                   mon_retenido,
                   pla_dias,
                   dias_efectivo,
                   dias_cheques)
           values (:emision.cod_empresa,
                   :pblock.num_certificado,
                   vcontador,
                   vmonto_cupon_bruto,
                   vestadocupon,
                   vmonto_cupon_neto,
                   vfven_cupon,
                   null,
                   0,
                   'N',
                   :pblock.exc_impuesto,
                   :variables.usuario,
                   :variables.fecha,
                   null,
                   null,
                   null,
                   0,
                   vdias,
                   vdias,
                   vdias);
      -- Reinicializa las variables de control ...
      vfecha_arranque := vfven_cupon;
      vcontador := vcontador + 1;
   end loop;
   --
   synchronize;
--
end;

procedure generacion_cupones_dia_pago
is
   vfaltancupones       boolean;
   vdias_normales       number (5);
   vfecha_arranque      date;
   vfrecuencia          varchar2 (1);
   vcontador            number (5);
   vdias                number (5);
   vfven_cupon          date;
   vmonto_cupon_bruto   number (18, 2);
   vmonto_cupon_neto    number (18, 2);
   vestadocupon         varchar2 (1);
   vprimeravez          varchar2 (1)   := 'S';
begin
   --if :variables.control = 'S'
   if tiene_forma_pago = 'S'
   then
      vestadocupon := 'A';
   else
      vestadocupon := 'I';
   end if;
   -- Se define el plazo en dias de los cupones normales o al vencimiento que se generaran en vdias_normales.
   -- Esolano 19/10/98
   if :pblock.fre_capitaliza = 'V'
   then                                                                     -- los dias de capitalizacion son el plazo del cd
      if :pblock.tip_plazo = 'D'
      then
         vdias_normales := :pblock.pla_dias;
      else
         vdias_normales := :pblock.plazo * 30;
      end if;
   else                                         -- el pago de intereses es en meses y pueden existir o no cupones adicionales
      vdias_normales := :pblock.pla_capitaliza * 30;
   end if;
   --
   -- Aqui comenzaria la generacion de los cupones con fechas y demas ...
   vfecha_arranque := :emision.fecha_emision;
   vfrecuencia := 'D';
   vcontador := 1;
   vfaltancupones := true;
   --  Se procede a generar los cupones "normales"
   while vfaltancupones
   loop
      if :pblock.fre_capitaliza = 'V'
      then                                                                 -- los dias de capitalizacion son el plazo del cd
         vdias := vdias_normales;
         vfven_cupon := :pblock.fec_vencimiento;
         vfaltancupones := false;
      else
         verifica_dia_pago (:emision.fecha_emision,
                            vfecha_arranque,
                            vfven_cupon,
                            :pblock.dia_pago_int,
                            :pblock.fec_vencimiento,
                            vprimeravez,
                            :bkproducto.base_plazo,
                            :pblock.tip_plazo,
                            vdias);
         if :pblock.fec_vencimiento = vfven_cupon
         then
            vfaltancupones := false;
         end if;
      end if;
      vmonto_cupon_bruto := cd_cal_interes (:pblock.monto, :pblock.tas_bruta, :bkproducto.base_calculo, vdias);
      vmonto_cupon_neto := cd_cal_interes (:pblock.monto, :pblock.tas_neta, :bkproducto.base_calculo, vdias);
      -- Llena los campos del bloque CUPO donde se guardara el registro de cupones ...
      insert into cd_cupon
                  (cod_empresa,
                   num_certificado,
                   numero_cupon,
                   monto_bruto,
                   estado,
                   monto_neto,
                   fecha_vencimiento,
                   fecha_pago,
                   contador_impresion,
                   utilizado,
                   excento,
                   adicionado_por,
                   fecha_adicion,
                   modificado_por,
                   fecha_modificacion,
                   observacion,
                   mon_retenido,
                   pla_dias,
                   dias_efectivo,
                   dias_cheques)
           values (:emision.cod_empresa,
                   :pblock.num_certificado,
                   vcontador,
                   vmonto_cupon_bruto,
                   vestadocupon,
                   vmonto_cupon_neto,
                   vfven_cupon,
                   null,
                   0,
                   'N',
                   :pblock.exc_impuesto,
                   :variables.usuario,
                   :variables.fecha,
                   null,
                   null,
                   null,
                   0,
                   vdias,
                   vdias,
                   vdias);
      -- Reinicializa las variables de control ...
      vfecha_arranque := vfven_cupon;
      vcontador := vcontador + 1;
   end loop;
   --
   synchronize;
end;

PROCEDURE Genera_Solicitud_Cajas( codigo_empresa     in number,
                                  codigo_agencia     in number,
                                  numero_comprobante in number,
                                  codigo_moneda      in number,
                                  codigo_cliente     in number,
                                  monto              in number,
                                  fecha_comprobante  date     ,  
                                  numero_asiento     in number,
                                  numero_certificado in VARCHAR2  ) is

  vcontador         number ;
  vreg_actual       number ;

BEGIN
  Insert into bcj_solicitud( Codigo_Empresa,
                             Codigo_Agencia,
                             Codigo_Aplicacion,
                             Numero_Comprobante,
                             Indicador_Comprobante,
                             Codigo_Moneda,
                             Codigo_Cliente,
                             Estado_Comprobante,
                             Monto_Comprobante,
                             Monto_TipoCambio1,
                             Monto_TipoCambio2,
                             Fecha_Comprobante,
                             Observaciones1,
                             Observaciones2,
                             Observaciones3, 
                             Observaciones4, 
                             Adicionado_por,
                             Modificado_por,
                             Anulado_por,
                             Aprobado_por,
                             Fecha_Adicion,
                             Fecha_Modificacion,
                             Fecha_Aprobacion,
                             Fecha_Anulacion,
                             Numero_Asiento_Contable,
                             NCliente,
                             Nivel_Uso,
                             Cod_Comprobante) 
                    values ( codigo_empresa,
                             codigo_agencia,
                             'BCD',
                             numero_comprobante,
                             'I',
                             codigo_moneda,
                             codigo_cliente,
                             'B',
                             monto,
                             1,
                             1,
                             fecha_comprobante,
                             :variables.inf_referencia,
                             NULL,
                             NULL, 
                             NULL, 
                             :variables.usuario,
                             NULL,
                             NULL,
                             :variables.usuario,
                             sysdate,
                             NULL,
                             fecha_comprobante,
                             NULL,
                             numero_asiento,
                             NULL,
                             NULL, 
                             '18');                             
EXCEPTION
     WHEN OTHERS THEN
           message(sqlcode||' '||sqlerrm);
           message(' ',no_acknowledge);
           UTILITARIOS.mensaje('000210',:variables.CodIdioma, 'CD' );
           raise form_trigger_failure;
END;

PROCEDURE Gestiona_Solicitud (pTipo in varchar2, pConsecutivo in number) IS
/*****************************************************************************************
 Realiza   : Solicita o cancela la solicitud de aprobación de débito a cuentas
 Requiere  :
 Historia  : 13/11/2012  API : Creación
*****************************************************************************************/
   Cursor Detalle is
      select FORMA_PAGO,     
             CONSECUTIVO,
             MONTO,          
             CUENTA,
             DESCRIPCION,    
             BENEFICIARIO,
             CONSECUTIVO_FPG
      from   cd_detalle_forma_pago
      where  forma_pago  is not null
      and    consecutivo is not null
      and    consecutivo_fpg = pConsecutivo
      order  by forma_pago;

   vResp 						 number; 
	 vSolicitud 			 number:=0;
	 vAprobacion			 number:=0;
	
begin

	if pTipo = 'S' then -- Solicitar
   for i in detalle
   loop	
			-- Debo recorrer el detalle completo para agregar la solicitar 
			-- de autorización para el débito a cada cuenta
			if (i.forma_pago = 'CE') then -- Cuentas de Efectivo
	  	  vSolicitud := vSolicitud + 1;
				Solicitud_Debito_Cta (:emision.cliente,
															:emision.titular,
															1,
															:variables.codigo_subtrans_cd,
															:variables.codsistema,
															i.cuenta,
															:variables.fecha,
															i.monto,
															vResp);												
				if vResp = 1 then
					vAprobacion := vAprobacion + 1;
				end if;
			end if;
	 end loop;
	 if vSolicitud <> vAprobacion then
			raise form_trigger_failure;
	 end if;       	
	else
	   for i in detalle
	   loop	
				-- Debo recorrer el detalle completo para cancelar las solicitudes utilizadas 
				if (i.forma_pago = 'CE') then -- Cuentas de Efectivo
		  			vResp := 0;			
						:variables.ValoresClaveDBCTA := 'TX:1|SUBTX:'||:variables.codigo_subtrans_cd||'|CLIENTE:'||:emision.cliente||'|MODULO:'||:variables.codsistema||'|FECHA:'||:variables.fecha;
						vResp := pa.cancela_solicitud_procesos(:variables.PROC_DEBITO_CTA,i.cuenta,:variables.usuario,:variables.valoresclavedbcta,ltrim(rtrim(to_char(i.monto,'9,999,999,990.00'))));
						if vResp = 0 then
								UTILITARIOS.Mensaje('000435',:variables.codidioma,'PA',NULL,'SOLICITUD_X_PROCESO');
						end if;
				end if;
	   end loop;
	end if;
end;

PROCEDURE Gestiona_Solicitud (pTipo in varchar2, pConsecutivo in number) IS
/*****************************************************************************************
 Realiza   : Solicita o cancela la solicitud de aprobación de débito a cuentas
 Requiere  :
 Historia  : 13/11/2012  API : Creación
*****************************************************************************************/
   Cursor Detalle is
      select FORMA_PAGO,     
             CONSECUTIVO,
             MONTO,          
             CUENTA,
             DESCRIPCION,    
             BENEFICIARIO,
             CONSECUTIVO_FPG
      from   cd_detalle_forma_pago
      where  forma_pago  is not null
      and    consecutivo is not null
      and    consecutivo_fpg = pConsecutivo
      order  by forma_pago;

   vResp 						 number; 
	 vSolicitud 			 number:=0;
	 vAprobacion			 number:=0;
	
begin

	if pTipo = 'S' then -- Solicitar
   for i in detalle
   loop	
			-- Debo recorrer el detalle completo para agregar la solicitar 
			-- de autorización para el débito a cada cuenta
			if (i.forma_pago = 'CE') then -- Cuentas de Efectivo
	  	  vSolicitud := vSolicitud + 1;
				Solicitud_Debito_Cta (:emision.cliente,
															:emision.titular,
															1,
															:variables.codigo_subtrans_cd,
															:variables.codsistema,
															i.cuenta,
															:variables.fecha,
															i.monto,
															vResp);												
				if vResp = 1 then
					vAprobacion := vAprobacion + 1;
				end if;
			end if;
	 end loop;
	 if vSolicitud <> vAprobacion then
			raise form_trigger_failure;
	 end if;       	
	else
	   for i in detalle
	   loop	
				-- Debo recorrer el detalle completo para cancelar las solicitudes utilizadas 
				if (i.forma_pago = 'CE') then -- Cuentas de Efectivo
		  			vResp := 0;			
						:variables.ValoresClaveDBCTA := 'TX:1|SUBTX:'||:variables.codigo_subtrans_cd||'|CLIENTE:'||:emision.cliente||'|MODULO:'||:variables.codsistema||'|FECHA:'||:variables.fecha;
						vResp := pa.cancela_solicitud_procesos(:variables.PROC_DEBITO_CTA,i.cuenta,:variables.usuario,:variables.valoresclavedbcta,ltrim(rtrim(to_char(i.monto,'9,999,999,990.00'))));
						if vResp = 0 then
								UTILITARIOS.Mensaje('000435',:variables.codidioma,'PA',NULL,'SOLICITUD_X_PROCESO');
						end if;
				end if;
	   end loop;
	end if;
end;

procedure inivarglobaleslocales
is
--EFECTUA : Inicializacion de Variables Locales Adicionales
--HISTORIA: ymur : 06/feb/97 : redefinicion
begin
   --Variables para el manejo de Folders
   :variables.tabactual := '0';
   :variables.canactual := '';
   --Informacion General
   :variables.codforma := :system.current_form;
   :variables.codsistema := upper (substr (:variables.codforma, 1, 2));
   :variables.fecha := utl_calendario.fecha_calendario_sistema (:variables.codsistema, :variables.codempresa, :variables.codagencia);
   --
   -- Jsanchez
   :variables.tipcamdol := pa_utl.obtiene_tipo_cambio (:variables.codempresa, '1', :variables.fecha);
   --
   :variables.derechos := utilitarios.derechos_x_forma (:variables.usuario, :variables.codsistema, :variables.codforma);
   --
   -- Jsanchez
   :variables.cd_monto_tope_int := to_number (parametros.parametro_x_empresa (:variables.codempresa, 'CD_MONTO_TOPE_INT', :variables.codsistema));
   -- Jsanchez
   :variables.cd_monto_tope_int_do := to_number (parametros.parametro_x_empresa (:variables.codempresa, 'CD_MONTO_TOPE_INT_DO', :variables.codsistema));
end;

/************************************************************************************** **
** PROCEDIMIENTO QUE SE ENCARGA DE INSERTAR A BITACORA_MONITOR LAS TRANSACCIONES DE LOS ** 
** CLIENTES QUE SE ENCUENTRE EN ESTADO R - RESTRINGIDO                                  **
** RCEBALLOS 13/04/2010                                                                 **
*************************************************************************************** **/
PROCEDURE INSERTA_MONITOR(Estado_Cliente varchar2) IS   
BEGIN
  PA.AUDITA_TRANSACCION (pTipoRegistro          => '1',
    	                   pCodSistema            => 'CD',
    	                   pOrigenTx              => 'CD',
    	                   pTipoTx                => 1, --Emision Nueva
    	                   pSubTipoTx             => :variables.codigo_subtrans_cd,
    	                   pFechaTx               => to_char(:Variables.Fecha, 'YYYYMMDD'), --FechaTx
    	                   pHoraTx                => to_char(sysdate, 'HH24MISS'), --HoraTx
    	                   pUsuarioTx             => :variables.usuario,
    	                   pUsuarioMod            => '', --Usuario Modif.
    	                   pUsuarioRev            => '', --Usuario Reversa
    	                   pUsuarioAut            => '', --Usuario Autoriza
    	                   pFechaMod              => '', --Fecha Modificacion
    	                   pFechaRev              => '', --Fecha Reversion
    	                   pFechaAut              => '', --Fecha Autorizacion
    	                   pAgencia               => :variables.codAgencia,
    	                   pReferencia            => '', -- Nulo por que no se obtiene al momento de enviar
    	                   pNumCuenta             => null,
    	                   pMontoTx               => 0, --Mto del ingreso de la moneda destino(extranjera)
                   	     pMontoEfectivo         => 0,
                         pMontoDocumento        => 0, --Mto del ingreso de la moneda destino(extranjera)
    	                   pMontoCkPropio         => 0,
    	                   pMontoCkOtros          => 0,
    	                   pReverso               => '',
    	                   pMonedaTx              => '', --Moneda de la Transaccion
    	                   pCodCliente            => :CUENTA_CLIENTE_REL.CODIGO_CLIENTE, --Codigo del Cliente
    	                   pNumeroDocumento       => '',
    	                   pCodCajero             => '',          --Codigo del Cajero
    	                   pTasaCambio            => null, --Tasa de Cambio
    	                   pEstadoMovimiento      => 'I',
    	                   pDescripcionTx         => '',
    	                   pNumAutorizacion       => '',
    	                   pNumTarjeta            => Null,
                         pTabla                 => '',
    	                   pDatosAntes            => null,
    	                   pDatosDespues          => null, 
                         pEstadoCliente         => Estado_Cliente);
EXCEPTION
	when others then
	  utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, ('(08) Error insertando en la bitacora monitor: '||sqlerrm));
	  raise form_trigger_failure;
END;

procedure interfaz_cc (
   pcodempresa     in       varchar2,
   pnumcuenta      in       number,
   pmonto          in       number,
   pctapuente      in       varchar2,
   pcoderror       out      varchar2,
   pcodsistema     out      varchar2,
   psqlcode        out      number,
   pno_documento   out      number)
is
   --
   vcodproducto     productos.cod_producto%type;
   vnummovimiento   number (12);
   vsecuencia       number (12);
   verraplic        number (12);
   vcoderror        varchar2 (6);
   vctactablecc     cg_catalogo_x_empresa.cuenta_contable%type;                                     -- Cuenta Contable de CC
   vmsjerror        varchar2 (250)                               := null;                                -- Mensaje de error
   vnumasiento      cg_movimiento_resumen.numero_asiento%type;
   v_tc1            number (15, 8);
   v_tc2            number (15, 8);
   vcodagencia      agencia.cod_agencia%type;
   vmondiferencia   number (18, 2)                               := 0.00;                    -- Diferencia en Cuadre Asiento
   vexiste          varchar2 (1);
   vaprobado        varchar2 (1);
   vaplicacargos    varchar2 (1);
   vcliente         varchar2 (15);
   vnumreferido     number (14);                                    --Nmartinez 13/01/2011 --Adecuacion Referidos duplicados
--
begin
   --
   -- Se obtiene alguna informacion de la cuenta
   --
   begin
      select cod_producto,
             cod_agencia,
             cod_cliente                                                                                 -- lperez 09/05/2006
        into vcodproducto,
             vcodagencia,
             vcliente
        from cuenta_efectivo
       where (cod_empresa = pcodempresa)
         and (num_cuenta = pnumcuenta)
         and (ind_estado not in (0, 2, 4, 5));
   exception
      when no_data_found
      then
         pcoderror := '000024';                                                      -- La cuenta esta cancelada o no existe
         pcodsistema := 'CC';
         psqlcode := sqlcode;
         return;
      when others
      then
         pcoderror := '000006';                                                              -- Error al verificar la cuenta
         pcodsistema := 'CC';
         psqlcode := sqlcode;
         return;
   end;
   --
   -- Se obtiene la cuenta contable del PRINCIPAL del producto de CC
   --
   --cuenta_contable_sector (:variables.codempresa, 'BCC', vcodproducto, 'PRINCIPAL', vcliente, vctactablecc, vmsjerror);
   
   cg.cg_utl.cuenta_contable_sector(:variables.codempresa, 'BCC', vcodproducto, 'PRINCIPAL', vcliente, vctactablecc, vmsjerror); -- fermin rodriguez 29/10/2019 Banco Ademi.
   
--p_depura('jsq c1 '||:variables.codempresa||' - '||'BCC'||' - '||vcodproducto||' - '||'PRINCIPAL'||' - '||vcliente||' - '||vctactablecc||' - '||vmsjerror);
   --
   if vmsjerror is not null
   then
      --
      pcoderror := substr (vmsjerror, 4, 6);
      pcodsistema := substr (vmsjerror, 1, 2);
      return;
   --
   end if;
   --
   -- Genera la linea del asiento contable para la cuenta de efectivo
   --
--p_depura('jsq c '||vctactablecc|| ' - ' ||pmonto);
   lineas_del_asiento (:variables.codempresa,
                       /* La linea del asiento debe tener la misma agencia que
                       el encabezado, la cual es la agencia de conexion

                       Proyecto Contabilizacion de Sucursales
                       Ana Patricia Inoa - SEP/2003

                       --vCodAgencia,
                       */
                       :variables.codagencia,
                       'BCC',
                       vcodproducto,
                       57,
                       :variables.subtipo_db_emicert,
                       '0',
                       :etiquetas.et_interfaz_cg,
                       :variables.fecha,
                       :variables.fecha,
                       :variables.fecha,
                       to_number (:variables.asiento_contable),                                                --vNumAsiento,
                       vctactablecc,
                       /* La linea del asiento debe tener la unidad a la que
                       pertenece la cuenta

                       Proyecto Contabilizacion de Sucursales
                       Ana Patricia Inoa - SEP/2003

                       :variables.codagencia,
                       */
                       vcodagencia,
                       pmonto,
                       'N',
                       'D',                                                             -- Debito para matar la cuenta puente
                       'N',
                       v_tc1,
                       v_tc2,
                       :variables.usuario,
                       vmsjerror);
   if (vmsjerror is not null)
   then
      --
      pcoderror := substr (vmsjerror, 4, 6);
      pcodsistema := substr (vmsjerror, 1, 2);
      return;
   --
   end if;
   --
   -- Se agrega el movimiento a cc.movimto_diario
   --
   obt_parametros (:variables.codempresa, 'CD', 'APLICA_CARGOS_EN_CC', :variables.codidioma, vaplicacargos, null);
   begin
--p_depura('jsq 112.00');
      agrega_movimiento (pcodempresa,
                         :variables.codagencia,
                         'CD',
                         pnumcuenta,
                         vcodproducto,
                         57,
                         :variables.subtipo_db_emicert,
                         :variables.usuario,
                         :variables.fecha,
                         --                        to_number(:variables.asiento_contable),
                         :variables.consec_forma_pago,
                         pmonto,
                         :variables.nom_subtip_cc,
                         'CD',
                         nvl (substr (:pblock.num_certificado, 7, 8), 0),
                         vaplicacargos,
                         vnummovimiento);
      -- 2. Aplica el movimiento.
--p_depura('jsq 112.05 '||vcoderror);
      aplica_movimiento (vnummovimiento, null, null, null, null, null, vsecuencia, verraplic, vcoderror, 'S');
--p_depura('jsq 112.10 '||vcoderror);
      -- lperez 23/11/2005, para retornar el no. movimiento cuando la fp es cc
      pno_documento := vnummovimiento;
      -- fin lperez
--p_depura('jsq 112.20 '||vcoderror);
      if vcoderror = '000074'
         or vcoderror = '003054'
      then
--p_depura('jsq 112.30');
         --Nmartinez 13/01/2011
         --Buscando si existe un referidos aprobado para la emision del certificado
         begin
            select num_cheque
              into vnumreferido
              from cks_referidos a
             where cod_empresa = :variables.codempresa
               and num_cuenta = pnumcuenta
               and mon_cheque = pmonto
               and trunc (fec_movimiento) = trunc (sysdate)
               and estado = 'A'
               and cod_sistema = 'CD'
               and fec_pago is null
               and rownum < 2;
         exception
            when no_data_found
            then
               vnumreferido := null;
         end;
--p_depura('jsq 112.40');
         verifica_referido (:variables.codempresa, vnumreferido,
                            --rtrim(ltrim(:emision.cliente||:emision.cod_producto)),  --Nmartinez 13/01/2011 Sustitución del numero de documento, por un numero secuencial
                            pmonto, pnumcuenta, vexiste, vaprobado);
--p_depura('jsq 112.50');
         if vexiste = 'S'
            and vaprobado = 'S'
         then
            --Nmartinez 13/01/2011 Sustitución del numero de documento, por un numero secuencial para los referidos
            --referidos(pCodEmpresa, :variables.CodAgencia,:variables.CONSEC_FORMA_PAGO, pMonto, pNumCuenta, :variables.subtipo_db_emicert, vNumMovimiento, :variables.fecha, vCodError);
--p_depura('jsq 112.60');
            -- Jsanchez
            -- Se comenta proceso de REFERIDOS, porque se valida en la opción FORMA DE PAGO si cada cuenta si es que tiene saldo
            -- antes de elegirla.
            -- referidos (pcodempresa, :variables.codagencia, vnumreferido, pmonto, pnumcuenta, :variables.subtipo_db_emicert, vnummovimiento, :variables.fecha, vcoderror);
            null;
--p_depura('jsq 112.70');
         end if;
      end if;
      if (vcoderror != '000005')
      then
--p_depura('jsq 112.80 '||vcoderror);
         pcoderror := vcoderror;
         psqlcode := verraplic;
         pcodsistema := 'CC';
         -- Si dio algun error se debe eliminar el movimiento generado
         delete      movimto_diario
               where (cod_empresa = :variables.codempresa)
                 and (num_movto_d = vnummovimiento);
         --
         return;
      else
--p_depura('jsq 112.90');
         /* API 02/FEB/2004
         Actualizar la fecha de pago de los referidos */
         if vexiste = 'S'
            and vaprobado = 'S'
         then
            update cks_referidos
               set fec_pago = sysdate
             where cod_empresa = :variables.codempresa
               and num_cuenta = pnumcuenta
               and num_cheque = vnumreferido
               --rtrim(ltrim(:emision.cliente||:emision.cod_producto)) --Nmartinez 13/01/2011 Sustitución del numero de documento, por un numero secuencial
               and mon_cheque = pmonto
               and trunc (fec_movimiento) = trunc (sysdate)
               and estado = 'A';
         end if;
         /* API 02/FEB/2004 */

         -- Se actualiza el movimiento a contabilizado
         update movimto_diario
            set estado_movimto = 'C'
          where (num_movto_d = vnummovimiento);
         --
         pcoderror := '000005';                                                               -- Proceso realizado con exito;
         pcodsistema := 'CC';
         return;
      end if;
   end;
--p_depura('jsq 112.100');
exception
   when others
   then
      psqlcode := sqlcode;
      pcoderror := '000648';                                            -- Error al hacer el debito a la cuenta de efectivo.
      pcodsistema := 'CD';
      return;
end;

procedure interfaz_cg (
   pcodempresa    in       varchar2,
   pnumcuenta     in       number,
   pmonto         in       number,
   pctapuente     in       varchar2,
   pcodproducto   in       varchar2,
   pcoderror      out      varchar2,
   pcodsistema    out      varchar2,
   psqlcode       out      number)
is
   --
   vcoderror        varchar2 (6);
   vmsjerror        varchar2 (250)                              := null;                                 -- Mensaje de error
   vnumasiento      cg_movimiento_resumen.numero_asiento%type;
   v_tc1            number (15, 8);
   v_tc2            number (15, 8);
   vmondiferencia   number (18, 2)                              := 0.00;                     -- Diferencia en Cuadre Asiento
--
begin
   --
   -- Genera la linea del asiento contable para la cuenta contable
   --
--p_depura('jsq b '||pnumcuenta|| ' - ' ||pmonto);
   lineas_del_asiento (:variables.codempresa,
                       :variables.codagencia,
                       'BCD',
                       pcodproducto,
                       1,
                       :variables.subtipo_emicd_x_conta,
                       '0',
                       :etiquetas.et_interfaz_cg,
                       :variables.fecha,
                       :variables.fecha,
                       :variables.fecha,
                       :variables.asiento_contable,                                                            --vNumAsiento,
                       pnumcuenta,
                       :variables.codagencia,
                       pmonto,
                       'N',
                       'D',                                                             -- Debito para matar la cuenta puente
                       'N',
                       v_tc1,
                       v_tc2,
                       :variables.usuario,
                       vmsjerror);
   if (vmsjerror is not null)
   then
      --
      pcoderror := substr (vmsjerror, 4, 6);
      pcodsistema := substr (vmsjerror, 1, 2);
      return;
   --
   end if;
   -- Si todo salio bien entonces...of course my little horse.
   pcoderror := '000512';                                                               -- Transaccion efectuada exitosamente
   pcodsistema := 'CD';
--
exception
   when others
   then
      pcoderror := '000133';                         -- Error al hacer el credito de la cuenta contable en la forma de pago.
      pcodsistema := 'CD';
      psqlcode := sqlcode;
      return;
end;

PROCEDURE Muestra_Cupon_Dia_Pago IS
  vFaltanCupones   boolean;
  vdias_normales   number(5);
  vFecha_Arranque  date;
  vFrecuencia      varchar2(1);
  vContador        number(5);
  vDias           number(5);
  vFven_Cupon      date;
  vmonto_cupon_bruto number(18,2);
  vmonto_cupon_neto  number(18,2);
  vEstadoCupon       varchar2(1);
  vPrimeraVez varchar2(1) := 'S';
BEGIN
  go_block('CUPO'); 
  clear_block (no_validate) ;
  --
  --if :variables.control = 'S' then
  if tiene_forma_pago = 'S' then
     vEstadoCupon := 'A';
  else
     vEstadoCupon := 'I';
  end if;

  -- Se define el plazo en dias de los cupones normales o al vencimiento que se generaran en vdias_normales. 
  -- Esolano 19/10/98

  IF  :pblock.fre_capitaliza = 'V' THEN   -- los dias de capitalizacion son el plazo del cd
    IF :pblock.tip_plazo = 'D' then 
      vdias_normales := :pblock.pla_dias ;
    ELSE
      vdias_normales := :pblock.plazo * 30;
    END IF ;
  ELSE  -- el pago de intereses es en meses y pueden existir o no cupones adicionales
    vdias_normales := :pblock.pla_capitaliza  * 30 ;
  END IF ;
  --
  -- Aqui comenzaria la generacion de los cupones con fechas y demas ...
  vfecha_arranque := :emision.fecha_emision ;   
  vfrecuencia := 'D' ;
  vcontador := 1 ;
  vFaltanCupones := TRUE;
  --  Se procede a generar los cupones "normales"
  while vFaltanCupones loop
     if  :pblock.fre_capitaliza = 'V' then   -- los dias de capitalizacion son el plazo del cd
         vDias := vdias_normales;
         vFven_Cupon := :pblock.fec_vencimiento;
         vFaltanCupones := FALSE;
     else
     	   Verifica_Dia_Pago(:emision.fecha_emision,
     	                     vFecha_Arranque,
     	   									 vFven_cupon,
     	   									 :pblock.dia_pago_int,
     	   									 :pblock.fec_vencimiento,
     	   									 vPrimeraVez,
     	   									 :bkproducto.base_plazo,
     	   									 :pblock.tip_plazo,
   	    									 vDias);
     	    if :pblock.fec_vencimiento = vFven_Cupon then
     	    	  vFaltanCupones := FALSE;
     	    end if;
     end if;       
     vmonto_cupon_bruto := cd_cal_interes ( :pblock.monto, :pblock.tas_bruta, :bkproducto.base_calculo, vDias);
     vmonto_cupon_neto := cd_cal_interes ( :pblock.monto, :pblock.tas_neta, :bkproducto.base_calculo, vDias);
     --
    :cupo.numero_cupon    := vcontador ;
    :cupo.monto_bruto     := vmonto_cupon_bruto ;
    :cupo.monto_neto      := vmonto_cupon_neto ;
    :cupo.estado          := 'I' ;
    :cupo.fecha_vencimiento := vfven_cupon ;
    :cupo.pla_dias        := vdias ;
    :cupo.dias_efectivo   := vdias ;
    :cupo.dias_cheques    := vdias ;    
    
    -- Reinicializa las variables de control ...
    vfecha_arranque := vfven_cupon ;
    vcontador := vcontador + 1 ;
    if vFaltanCupones = TRUE then
      next_record ;
    else
      exit;
    end if ;
  end loop ;
  --
  go_record(1);
END;

PROCEDURE Muestra_Cupones IS

  vCantCupones     NUMBER(5) := 0;
  vCuponesSobran   NUMBER(5) := 0;
  vDiasSobran      NUMBER(5) := 0 ;
  vCuponesNormales NUMBER(5) := 0 ;
  vdias_normales     NUMBER(5) ;
  hay_ajuste         BOOLEAN ;
  vTotalDias         NUMBER(5) := 0 ;
  vcontador          NUMBER(5) := 0 ;
  vcontador_normal   NUMBER(5) := 0 ;
  vcontador_especial NUMBER := 0 ;
  vmonto_cupon_neto  NUMBER (17,2) ;
  vmonto_cupon_bruto NUMBER (17,2) ;
  vfrecuencia        VARCHAR2(1) ;
  vfven_cupon        DATE ;
  vfecha_arranque    DATE ;
  vplazo_ints        NUMBER(5) ;
  vdias              NUMBER(5) ;

  habra_ajuste varchar2(5) ;


BEGIN
  go_block('CUPO'); 
  clear_block (no_validate) ;
  -- Este proceso determina las caracteristicas de los cupones que se deben generar dejando los
  -- valores en las siguientes variables 
  -- VCANTCUPONES : Cantidad Total de cupones a generar
  -- VCUPONESNORMALES : Cantidad de cupones enteros de VDIAS_NORMALES dias
  -- VCUPONESSOBRAN : Cantidad de cupones especiales a generar de VDIASSOBRAN dias
  -- Finalmente la variable HAY_AJUSTE indicara si se debe hacer algun ajuste en algun cupon ...

  hay_ajuste := FALSE ;
  IF :PBLOCK.TIP_PLAZO = :PBLOCK.FRE_CAPITALIZA THEN    
     -- En este caso la unica posibilidad es que los dos sean meses
     vCantCupones    := TRUNC(:PBLOCK.PLAZO / :PBLOCK.PLA_CAPITALIZA) ;
     vCuponesNormales := vCantCupones ;
     vCuponesSobran  := MOD(:PBLOCK.PLAZO, :PBLOCK.PLA_CAPITALIZA) ;
     if vCuponesSobran <> 0 then 
        vDiasSobran := vCuponesSobran * 30 ;
        vCuponesSobran := 1 ;
     end if ;
  ELSIF :PBLOCK.FRE_CAPITALIZA = 'V' THEN
     vCantCupones    := 1 ;
     vCuponesNormales := 1 ;
     vCuponesSobran  := 0 ;
     vDiasSobran     := 0 ;
  ELSIF :PBLOCK.TIP_PLAZO = 'D'  THEN
     vTotalDias := :pblock.pla_capitaliza * 30;
     vCantCupones := TRUNC(:PBLOCK.PLA_DIAS/vTotalDias) ;
     vCuponesNormales := vCantCupones ;
     vDiasSobran  := MOD(:PBLOCK.PLA_DIAS,vTotalDias) ;
  END IF ;
  IF (vDiasSobran > 0)  THEN    
    IF vDiasSobran < :bkproducto.num_dias THEN
      vCuponesNormales := vCuponesNormales - 1 ;
      VCuponesSobran  := 1 ;
      VDiasSobran := 30 + vDiasSobran ;
      hay_ajuste := TRUE ;
    ELSE
      vCuponesSobran := 1 ;
      vCantCupones := vCantCupones + 1 ;
    END IF ;
  END IF ;

  -- Se define el plazo en dias de los cupones normales o al vencimiento que se generaran en vdias_normales. 
  -- Los casos especiales se manejaran utilizando los valores de vCuponesSobran y vDiasSobran
  -- Esolano 19/10/98

  IF  :pblock.fre_capitaliza = 'V' THEN   -- los dias de capitalizacion son el plazo del cd
    IF :pblock.tip_plazo = 'D' then 
      vdias_normales := :pblock.pla_dias ;
    ELSE
      vdias_normales := :pblock.plazo * 30;
    END IF ;
  ELSE  -- el pago de intereses es en meses y pueden existir o no cupones adicionales
    vdias_normales := :pblock.pla_capitaliza  * 30 ;
  END IF ;

  -- Aqui comenzaria la generacion de los cupones con fechas y demas ...
  vfecha_arranque := :emision.fecha_emision ;   
  vfrecuencia := 'D' ;
  vcontador := 1 ;
  vcontador_normal := 0 ;
  vcontador_especial := 0 ;

  --  Se procede a generar los cupones "normales"
  while vcontador <= vCantCupones loop
    if (hay_ajuste) and (:pblock.ajusta = 'I') and (vcontador = 1) and (vcontador_especial <> vCuponesSobran) then 
       vdias := vDiasSobran ;
       vcontador_especial := vcontador_especial  + 1;
    elsif (hay_ajuste) and (:pblock.ajusta = 'F') and (vcontador = vCantCupones) and (vcontador_especial <> vCuponesSobran ) then 
       vdias := vDiasSobran ;
       vcontador_especial := vcontador_especial  + 1;
    elsif (not hay_ajuste) and (vcontador = vCantCupones) and (vcontador_especial <> vCuponesSobran ) then 
       vdias := vDiasSobran ;
       vcontador_especial := vcontador_especial  + 1;
    else 
       vdias := vDias_Normales ;
       vcontador_normal := vcontador_normal + 1 ;
    end if ;

    vmonto_cupon_bruto := cd_cal_interes ( :pblock.monto, :pblock.tas_bruta, :bkproducto.base_calculo, vDias);
    vmonto_cupon_neto := cd_cal_interes ( :pblock.monto, :pblock.tas_neta, :bkproducto.base_calculo, vDias);
    cd_fecha_exacta (vfecha_arranque, 
                     :bkproducto.base_plazo, 
                     vDias, 
                     vfrecuencia , 
                     vfven_cupon, 
                     vplazo_ints) ;

    :cupo.numero_cupon    := vcontador ;
    :cupo.monto_bruto     := vmonto_cupon_bruto ;
    :cupo.monto_neto      := vmonto_cupon_neto ;
    :cupo.estado          := 'I' ;
    :cupo.fecha_vencimiento := vfven_cupon ;
    :cupo.pla_dias        := vdias ;
    :cupo.dias_efectivo   := vdias ;
    :cupo.dias_cheques    := vdias ;    

/*
    -- Llena los campos del bloque CUPO donde se guardara el registro de cupones ...
    :cupo.cod_empresa := :emision.cod_empresa ;
    :cupo.num_certificado := :pblock.num_certificado ;
    :cupo.fecha_pago      := NULL ;
    :cupo.contador_impresion := 0 ;
    :cupo.utilizado       := NULL ;
    :cupo.excento         := :emision.excento ;
    :cupo.adicionado_por  := :variables.usuario ;
    :cupo.fecha_adicion   := :variables.fecha ;
    :cupo.modificado_por  := :variables.usuario ;
    :cupo.observacion     := NULL ;
    :cupo.marca           := 'N' ;
    :cupo.fecha_modificacion := :variables.fecha ;
*/    
    -- Reinicializa las variables de control ...
    vfecha_arranque := vfven_cupon ;
    vcontador := vcontador + 1 ;
    if vcontador <= vCantCupones then
      next_record ;
    end if ;
  end loop ;
  go_record(1) ; 
END;

PROCEDURE Obtiene_Datos_Cuenta IS

--EFECTUA : Obtiene el nombre del cliente dueno de la cuenta, asi como
--          la descripcion de la agencia y el producto y otros datos
--REQUIERE:
--HISTORIA: mpre : 29/marzo/1995  **Creacion
--          mpre : 05/abril/1995  **Se agrego la busqueda de algunos
--                                  saldos e intereses

   vCodProducto		varchar2(4);

BEGIN
   if (:pblock.num_cuenta is not null)
   then
      begin
        -- Se buscan datos de la cuenta
         select nombre, cod_producto
          into :emision.nom_due_cta, vCodProducto
          from cuenta_efectivo a, personas b
          where ( a.cod_empresa = :variables.CodEmpresa )
          and   ( a.num_cuenta  = :pblock.num_cuenta     )
          and   ( b.cod_persona = a.cod_cliente         );
      exception
         when no_data_found then
            :emision.des_producto    := null;
            :emision.nom_due_cta     := null;
            UTILITARIOS.mensaje('000007',:variables.CodIdioma,'CC');
            raise form_trigger_failure;

         when others then
            :emision.des_producto    := null;
            :emision.nom_due_cta     := null;
            UTILITARIOS.mensaje_error('000006',:variables.CodIdioma,'CC',sqlcode);
            raise form_trigger_failure;
      end;
   
      begin
         -- Se busca la descripcion del producto
          select descripcion
          into :emision.des_producto
          from productos
          where ( cod_empresa  = :variables.CodEmpresa )
          and   ( cod_producto = vCodProducto          );
      exception
         when no_data_found then
            UTILITARIOS.mensaje('000021',:variables.CodIdioma,'PA');
            raise form_trigger_failure;
         when others then
            UTILITARIOS.mensaje_error('000027',:variables.CodIdioma,'PA',sqlcode);
            raise form_trigger_failure;
      end;
   end if ;
END;

PROCEDURE p_alerta(pMensaje IN VARCHAR2) IS
  vBoton  NUMBER;
BEGIN
  set_alert_property('ALERTA',ALERT_MESSAGE_TEXT,pMensaje);
  vBoton := show_alert('ALERTA');
  set_alert_property('ALERTA',ALERT_MESSAGE_TEXT,null);
END;

PROCEDURE PasaBloqueDetalle IS
BEGIN
  :SYSTEM.MESSAGE_LEVEL := 25;
  IF (:EMISION.FORMA_CALCULO IN ('VCF','VCV', 'VF', 'VV')) 
  THEN  
    GO_ITEM('PBLOCK1.MONTO');
  ELSIF :EMISION.FORMA_CALCULO = 'CU' 
  THEN  
    GO_ITEM('PBLOCK.MONTO');  
  ELSIF :EMISION.FORMA_CALCULO IN ('CF','CV') 
  THEN  
    GO_ITEM('PBLOCK2.MONTO');
  END IF;
  :SYSTEM.MESSAGE_LEVEL := 0;
EXCEPTION
   when others then
     UTILITARIOS.mensaje('000064',:variables.CodIdioma, 'CD' );
END;

PROCEDURE p_mensaje(pMensaje IN VARCHAR2) IS
  vBoton  NUMBER;
BEGIN
  set_alert_property('INFORMACION',ALERT_MESSAGE_TEXT,pMensaje);
  vBoton := show_alert('INFORMACION');
  set_alert_property('INFORMACION',ALERT_MESSAGE_TEXT,null);
END;

--EFECTUA: deshabilita propiedades de los campos.
--REQUIERE: 
PROCEDURE P_OCULTAR_CAMPO(ptextItem varchar2, pTipo varchar2, pRecord number, pVisual varchar2, pNavg varchar2, pUpdate varchar2, pInsert varchar2, pDelete varchar2) IS
vitemtype varchar2(20);
vitem item;

BEGIN
  if pTipo = 'IN' then  	
  	if pVisual = '0' then  		
  		set_item_instance_property(ptextItem,pRecord, visual_attribute,'va_ocultar_campo');
  	elsif pVisual = '1' then  		
  		set_item_instance_property(ptextItem,pRecord, visual_attribute,'texto_negro');
  	end if;
  	
  	if pNavg = '0' then
  		set_item_instance_property(ptextItem,pRecord, navigable,property_false);  		
  	elsif pNavg = '1' then
  		set_item_instance_property(ptextItem,pRecord, navigable,property_true); 
  	end if;
  	
  	if pUpdate = '0' then
  		set_item_instance_property(ptextItem,pRecord, update_allowed,property_false);
  	elsif pUpdate = '1' then
  		set_item_instance_property(ptextItem,pRecord, update_allowed,property_true);
  	end if;
  	
  	if pInsert = '0' then
  		set_item_instance_property(ptextItem,pRecord, insert_allowed,property_false);
  	elsif pInsert = '1' then                                                            
  		set_item_instance_property(ptextItem,pRecord, insert_allowed,property_true);
  	end if;
  	
  	if pDelete = '0' then
  		set_item_instance_property(ptextItem,pRecord, delete_allowed,property_false);
  	elsif pDelete = '1' then
  		set_item_instance_property(ptextItem,pRecord, delete_allowed,property_true);
  	end if;
  elsif pTipo = 'IT' then
  	if pVisual = '0' then  		
  		set_item_property(ptextItem,visual_attribute,'va_ocultar_campo');
  	elsif pVisual = '1' then  		
  		set_item_property(ptextItem,visual_attribute,'texto_negro');
  	end if;
  	
  	if pNavg = '0' then
  		set_item_property(ptextItem,navigable,property_false);  		
  	elsif pNavg = '1' then
  		set_item_property(ptextItem,navigable,property_true); 
  	end if;
  	
  	if pUpdate = '0' then
  		set_item_property(ptextItem,update_allowed,property_false);
  	elsif pUpdate = '1' then
  		set_item_property(ptextItem,update_allowed,property_true);
  	end if;
  	
  	if pInsert = '0' then
  		set_item_property(ptextItem,insert_allowed,property_false);
  	elsif pInsert = '1' then                                                            
  		set_item_property(ptextItem,insert_allowed,property_true);
  	end if;
  	
  	if pDelete = '0' then
  		set_item_property(ptextItem,delete_allowed,property_false);
  	elsif pDelete = '1' then
  		set_item_property(ptextItem,delete_allowed,property_true);
  	end if;
  end if;    
  
END;

/*****************************************************************************************
Realiza   : La cancelacion de certificados y cupones vencidos a través la forma de pago que
se detalla en la tabla CD_DETALLE_FORMA_PAGO, la cual se puede realizar por medio
de 4 alternativas :
 
1. Cuenta de Efectivo ----> 'CE'
2. Cuenta Contable    ----> 'CO'
3. Cuenta Bancaria    ----> 'CK'
4. Comprobante Egreso ----> 'EE'

p.d. Por aquello... estas codificaciones fueron creadas por Alex Salas.

Creación : 17-DIC-1998 10:33:24 a.m. rmorales sysde(c)1998
*****************************************************************************************/
procedure procesa_forma_pago (pn_bloque in number, pconsecutivo in number, pno_documento out number)
is
   --
   cursor detalle
   is
      select   forma_pago,
               consecutivo,
               monto,
               cuenta,
               descripcion,
               beneficiario,
               consecutivo_fpg
          from cd_detalle_forma_pago
         where forma_pago is not null
           and consecutivo is not null
           and consecutivo_fpg = pconsecutivo
      order by forma_pago;
   --
   -- Variables de uso comun
   --
   vprodgeneral     varchar2 (5);                                                         -- Producto general de certificados
   vmsjerror        varchar2 (250)                               := null;                                 -- Mensaje de error
   vcodprodpuente   productos.cod_producto%type;                             -- Producto utilizado para obtener la cta puente
   vcertificados    boolean                                      := false;
   -- Para verificar si existen certificados a cancelar
   vcupones         boolean                                      := false;    -- Para verificar si existen cupones a cancelar
   vnumasiento      cg_movimiento_resumen.numero_asiento%type;
   v_tc1            number (15, 8);
   v_tc2            number (15, 8);
   vmonrenta        number (18, 2);                                                                -- Monto Impuesto de Renta
   vmondiferencia   number (18, 2)                               := 0.00;                     -- Diferencia en Cuadre Asiento
   vcoderror        mensajes_sistema.num_mensaje%type;
   vcodsistema      sistemas.cod_sistema%type;
   verroraplic      number (12);                                                           -- Represesnta el sqlcode devuelto
   -- Conceptos Contables
   vconcepintxpag   cg_cuentas_x_concepto.concepto%type;                                        -- Concepto Interes por Pagar
   vconcepintrec    cg_cuentas_x_concepto.concepto%type;                                    -- Concepto Intereses Reconocidos
   -- Cuentas Contables
   vctapuente       cg_catalogo_x_empresa.cuenta_contable%type;                             -- Cuenta Puente para cancelacion
   vctaintxpag      cg_catalogo_x_empresa.cuenta_contable%type;                                 -- Cuenta intereses por pagar
   vctaintrec       cg_catalogo_x_empresa.cuenta_contable%type;                               -- Cuenta intereses Reconocidos
   vctarenta        cg_catalogo_x_empresa.cuenta_contable%type;                                   -- Cuenta impuesto de renta
   v_alert          number;
   vnumreferido     number (14);                                     --Nmartinez 13/01/2011 --Adecuacion Referidos duplicados
   -- Variables de exception
   bcg_interface    exception;
   bcc_interface    exception;
   bcj_interface    exception;
   bba_interface    exception;
   error            exception;
begin
   -- Se realiza las interfaces indicadas en la forma de pago
   --
   for i in detalle
   loop
      --
      vcoderror := null;
      vcodsistema := null;
      verroraplic := null;
      --
      if (i.forma_pago = 'CE')
      then                                                                                            -- Cuentas de Efectivo
         --
         if (:variables.subtipo_db_emicert is null)
         then
            --
            obt_parametros (:variables.codempresa,
                            'CC',
                            'SUBTIP_DB_EMICERT',
                            :variables.codidioma,
                            :variables.subtipo_db_emicert);
            --
            begin
               select descripcion
                 into :variables.nom_subtip_cc
                 from subtip_transac
                where cod_empresa = :variables.codempresa
                  and cod_sistema = 'CC'
                  and tip_transaccion = 57
                  and subtip_transac = ltrim (rtrim (:variables.subtipo_db_emicert));
            exception
               when others
               then
                  :variables.nom_subtip_cc := ' ';
            end;
         end if;
         --
         interfaz_cc (:variables.codempresa,
                      i.cuenta,
                      i.monto,
                      vctapuente,
                      vcoderror,
                      vcodsistema,
                      verroraplic,
                      pno_documento);                   --lperez 23/11/2005, para guardar el no_doc cuando es cuenta efectivo
         --
         if (vcodsistema <> 'CC'
             and vcoderror is not null)
         then
            --
            utilitarios.mensaje_error (vcoderror, :variables.codidioma, vcodsistema, verroraplic);
            raise bcc_interface;
         --
         else
            if (vcoderror <> '000005')
            then
               utilitarios.mensaje_error (vcoderror, :variables.codidioma, vcodsistema, verroraplic);
               -- JVP 04/2001
               -- Funcionalidad de referidos.
               set_alert_property ('CONFIRMACION', alert_message_text, 'Desea enviar a Referidos?');
               v_alert := show_alert ('CONFIRMACION');
               if v_alert = alert_button1
               then
                  :system.message_level := 25;
                  ---                 rollback;
                  :system.message_level := 0;
                  forms_ddl ('rollback');
                  --Nmartinez 13/01/2011 Adecuacion Referidos
                  --Buscando la Secuencia del Referido
                  begin
                     select cc.cks_referidos_sq.nextval
                       into vnumreferido
                       from dual;
                  exception
                     when others
                     then
                        mensaje ('Error Buscando secuencia CC.CKS_REFERIDOS_SQ ' || sqlerrm);
                        raise form_trigger_failure;
                  end;
                  insert into cks_referidos
                              (cod_empresa,
                               num_cuenta,
                               num_cheque,
                               fec_movimiento,
                               mon_cheque,
                               cod_agencia,
                               origen_cheque,
                               usuario_solicita,
                               estado,
                               cod_sistema)
                       values (:variables.codempresa,
                               i.cuenta,
                               vnumreferido,
                               --rtrim(ltrim(:emision.cliente||:emision.cod_producto)), --Nmartinez 13/01/2011 Sustitución por un numero secuencial
                               sysdate,
                               i.monto,
                               :variables.codagencia,
                               'J',
                               user,
                               'P',
                               'CD');
                  forms_ddl ('commit');
                  :system.message_level := 25;
                  exit_form (no_validate, full_rollback);
                  :system.message_level := 0;
               end if;
               raise bcc_interface;
            end if;
         end if;
      --
      elsif (i.forma_pago = 'CO')
      then                                                                                                 -- Cuenta Contable
         --
         obt_parametros (:variables.codempresa,
                         'CD',
                         'SUBTIPO_EMICD_CONTA',
                         :variables.codidioma,
                         :variables.subtipo_emicd_x_conta);
         --
         interfaz_cg (:variables.codempresa, i.cuenta, i.monto, vctapuente, vprodgeneral, vcoderror, vcodsistema,
                      verroraplic);
         --
         if (vcodsistema <> 'CD'
             and vcoderror is not null)
         then
            --
            utilitarios.mensaje_error (vcoderror, :variables.codidioma, vcodsistema, verroraplic);
            raise bcg_interface;
         --
         else
            if (vcoderror <> '000512')
            then
               utilitarios.mensaje_error (vcoderror, :variables.codidioma, vcodsistema, verroraplic);
               raise bcg_interface;
            end if;
         end if;
      --
      elsif (i.forma_pago = 'EE') -- Cajas
      then
         --
         conexion_con_cajas (pn_bloque, tiene_forma_pago, i.monto);
      end if;
   end loop;
end;

function productos_x_agencia (p_empresa in varchar2, p_producto in varchar2, p_agencia in varchar2)
   return boolean
is
   --
   -- Datos de la Tabla de productos x empresa
   --
   vc_query  varchar2(2000); --Lista de Valores
begin
   default_value (null, 'GLOBAL.monto_minimo');
   default_value (null, 'GLOBAL.producto_agencia');
   --
   -- revisa si la tabla cd_producto_x_agencia tiene informacion
   --
   begin
      select monto_minimo,
             a_la_vista,
             forma_calculo_interes,
             frec_revision,
             plazo_revision,
             fre_capitaliza,
             plazo_capitaliza,
             paga_renta,
             porcentaje_renta,
             base_calculo,
             base_plazo,
             plazo_minimo,
             num_dias,
             tiene_doc_fisico,
             modifica_pla_cap,
             dia_de_cap_fre_mes,
             dia_pago_int,
             cod_cartera,
             dias_efectivo,
             dias_cheque,
             -- Jsanchez
             ind_renovacion_auto,
             'N'
        into :bkproducto.monto_minimo,
             :bkproducto.a_la_vista,
             :bkproducto.forma_calculo_interes,
             :bkproducto.frec_revision,
             :bkproducto.plazo_revision,
             :bkproducto.fre_capitaliza,
             :bkproducto.plazo_capitaliza,
             :bkproducto.paga_renta,
             :bkproducto.porcentaje_renta,
             :bkproducto.base_calculo,
             :bkproducto.base_plazo,
             :bkproducto.plazo_minimo,
             :bkproducto.num_dias,
             :bkproducto.tiene_doc_fisico,
             :bkproducto.modifica_pla_cap,
             :bkproducto.dia_de_cap_fre_mes,
             :bkproducto.dia_pago_int,
             :bkproducto.cod_cartera,
             :bkproducto.dias_efectivo,
             :bkproducto.dias_cheque,
             -- Jsanchez
             :bkproducto.ind_reno_auto,
             :bkproducto.ind_prd_emp
        from cd_producto_x_agencia
       where cod_empresa = p_empresa
         and cod_producto = p_producto
         and cod_agencia = p_agencia;
   exception
      when no_data_found
      then
         begin
            select monto_minimo,
                   a_la_vista,
                   forma_calculo_interes,
                   fre_revision,
                   plazo_revision,
                   fre_capitaliza,
                   plazo_capitaliza,
                   paga_renta,
                   porcentaje_renta,
                   base_calculo,
                   base_plazo,
                   plazo_minimo,
                   num_dias,
                   tiene_doc_fisico,
                   modifica_pla_cap,
                   dia_de_cap_fre_mes,
                   dia_pago_int,
                   cod_cartera,
                   dias_efectivo,
                   dias_cheque,
                   -- Jsanchez
                   ind_renovacion_auto,
                   nvl (ind_prd_emp, 'N')
              into :bkproducto.monto_minimo,
                   :bkproducto.a_la_vista,
                   :bkproducto.forma_calculo_interes,
                   :bkproducto.frec_revision,
                   :bkproducto.plazo_revision,
                   :bkproducto.fre_capitaliza,
                   :bkproducto.plazo_capitaliza,
                   :bkproducto.paga_renta,
                   :bkproducto.porcentaje_renta,
                   :bkproducto.base_calculo,
                   :bkproducto.base_plazo,
                   :bkproducto.plazo_minimo,
                   :bkproducto.num_dias,
                   :bkproducto.tiene_doc_fisico,
                   :bkproducto.modifica_pla_cap,
                   :bkproducto.dia_de_cap_fre_mes,
                   :bkproducto.dia_pago_int,
                   :bkproducto.cod_cartera,
                   :bkproducto.dias_efectivo,
                   :bkproducto.dias_cheque,
                   -- Jsanchez
                   :bkproducto.ind_reno_auto,
                   :bkproducto.ind_prd_emp
              from cd_producto_x_empresa
             where cod_empresa = p_empresa
               and cod_producto = p_producto;
         exception
            when no_data_found
            then
               -- No encontro la informacion del producto x empresa
               utilitarios.mensaje ('000190', :variables.codidioma, 'CD', sqlcode);
               raise form_trigger_failure;
            when others
            then
               -- Error al buscar informacion del producto x empresa
               utilitarios.mensaje ('000171', :variables.codidioma, 'CD', sqlcode);
               raise form_trigger_failure;
         end;
      when others
      then
         -- Error al buscar informacion del producto x agencia
         utilitarios.mensaje ('000189', :variables.codidioma, 'CD', sqlcode);
         raise form_trigger_failure;
   end;
   :bkproducto.cod_producto := :emision.cod_producto;
   :bkproducto.cod_empresa := :variables.codempresa;
   --
   -- Obtiene el codigo de moneda del producto encontrado
   begin
      select cod_moneda
        into :bkproducto.cod_moneda
        from productos
       where cod_empresa = :bkproducto.cod_empresa
         and cod_producto = :bkproducto.cod_producto;
   exception
      when no_data_found
      then
         -- Error al buscar la moneda para el producto
         utilitarios.mensaje ('000192', :variables.codidioma, 'CD');
         raise form_trigger_failure;
      when too_many_rows
      then
         -- Error, existe mas de un producto con este codigo en Productos de PA, verifique
         utilitarios.mensaje ('000191', :variables.codidioma, 'CD');
         raise form_trigger_failure;
   end;
   --
   -- Cargar variables del bloque de productos por agencia
   --
   :emision.forma_calculo := :bkproducto.forma_calculo_interes;
   :emision.porcentaje_renta := :bkproducto.porcentaje_renta;
   :emision.fecha_emision := :variables.fecha;
   if :emision.forma_calculo = 'CU'
   then
      set_item_property ('PBLOCK.AL_PORTADOR_CUPON', displayed, property_true);
      -- Jsanchez (06/02/2016)
      -- Se deja campo inactivvo pues no puede ser editado por el usuario
      -- SET_ITEM_PROPERTY('PBLOCK.AL_PORTADOR_CUPON',ENABLED,PROPERTY_TRUE);
      -- SET_ITEM_PROPERTY('PBLOCK.AL_PORTADOR_CUPON',NAVIGABLE,PROPERTY_TRUE);
      -- SET_ITEM_PROPERTY('PBLOCK.AL_PORTADOR_CUPON',UPDATEABLE,PROPERTY_TRUE);
      -- Fin Jsanchez (06/02/2016)
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', displayed, property_true);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', enabled, property_true);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', navigable, property_true);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', updateable, property_true);
      set_item_property ('PBLOCK.NUM_CUENTA', displayed, property_true);
      set_item_property ('PBLOCK.NUM_CUENTA', enabled, property_true);
      set_item_property ('PBLOCK.NUM_CUENTA', navigable, property_true);
      set_item_property ('PBLOCK.NUM_CUENTA', updateable, property_true);
   else
      set_item_property ('PBLOCK.AL_PORTADOR_CUPON', displayed, property_true);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', displayed, property_true);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', enabled, property_false);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', navigable, property_false);
      set_item_property ('PBLOCK.FORMA_PAGO_INTERESES', updateable, property_false);
      set_item_property ('PBLOCK.NUM_CUENTA', displayed, property_true);
      set_item_property ('PBLOCK.NUM_CUENTA', enabled, property_false);
      set_item_property ('PBLOCK.NUM_CUENTA', navigable, property_false);
      set_item_property ('PBLOCK.NUM_CUENTA', updateable, property_false);
   end if;
   --
   -- Jsanchez
   -- Se actualiza lista de valores dependiendo del tipo de plazo de producto
   --
   if :bkproducto.plazo_minimo <= 31
   then
      vc_query := 'select descripcion, cod_sec from pa_catalogo_codigos where cod_gen = ''CN'' order by 2';
      --
      if not LLenarLIstaElementos('pblock.plazo', vc_query)
      then
         Mensaje('Error Cargando Lista de Valores de Calendario Normal (PKBLOCK)');
      end if;  
      --
      if not LLenarLIstaElementos('pblock2.plazo', vc_query)
      then
         Mensaje('Error Cargando Lista de Valores de Calendario Normal (PKBLOCK2)');
      end if;  
   else
      vc_query := 'select descripcion, cod_sec from pa_catalogo_codigos where cod_gen = ''CJ'' order by 2';
      --
      if not LLenarLIstaElementos('pblock.plazo', vc_query)
      then
         Mensaje('Error Cargando Lista de Valores de Calendario Financiero (PKBLOCK)');
      end if;  
      --
      if not LLenarLIstaElementos('pblock2.plazo', vc_query)
      then
         Mensaje('Error Cargando Lista de Valores de Calendario Financiero (PKBLOCK2)');
      end if;  
   end if;
   --
   return true;
end;

/*
EFECTUA: LAS VALIDACIONES/PREGUNTAS DE FACTA PARA UNA PERSONA
REQUIERE: N/A
CREACION: enfrancisco: Enver D. Francisco Báez
FECHA: 2014-05-07
MODIFICACIONES:
USUARIO FECHA      DESCRIPCION
------- ---------- --------------------------------------------------------------------
*/
procedure p_validapersonafacta
is
   vcantdiasvalidacion   number (5);
   vfechoy               date;
   vcantdiaactfatca      number (5);
   vcodpaisfatca         varchar2 (50) := pa.param.parametro_x_empresa (:variables.codempresa, 'PAIS_FATCA', 'PA');
   vesfisico             varchar2 (1);
   vcount                number (1)    := 1;                                  -- EFrancisco 22/09/2014 Implementacion Fatca.
begin
   vcantdiasvalidacion := to_number (pa.param.parametro_x_empresa (:variables.codempresa, 'DIAS_VAL_FATCA', 'PA'));
   begin
      select fec_hoy
        into vfechoy
        from pa.calendarios
       where cod_empresa = :variables.codempresa
         and cod_agencia = :variables.codagencia
         and cod_sistema = 'CD';
   exception
      when no_data_found
      then
         utilitarios.mensaje ('000672', :variables.codidioma, :variables.codsistema);
         raise form_trigger_failure;
   end;
   begin
      select   min (vfechoy - trunc (fec_actualizacion)),
               es_fisica
          into vcantdiaactfatca,
               vesfisico
          from personas
         where cod_persona = :bk_fatca.cod_persona
      group by es_fisica;
      vcantdiaactfatca := nvl (vcantdiaactfatca, 99999);
   exception
      when others
      then
         vcantdiaactfatca := 0;
   end;
   if vcantdiaactfatca >= vcantdiasvalidacion
      or nvl (:bk_fatca.ciclo_val, 'N') = 'S'
   then
      :bk_fatca.ciclo_val := 'S';
      -- EFrancisco 22/09/2014 Implementacion Fatca.
      if nvl (:bk_fatca.val_nac_us, 'N') = 'N'
      then
         set_lov_property ('LOV_PAIS_NAC_FACTA', group_name, 'RG_PAISES_US');
         set_alert_property ('ALERTA_FACTA', alert_message_text, '¿Tiene usted ciudadanía Norteamericana?');
         if show_alert ('ALERTA_FACTA') = alert_button1
         then                                                                                                           --Si
            :bk_fatca.cod_tipo_id_nac := null;
            :bk_fatca.des_pais_nac := null;
            :bk_fatca.cod_pais_nac := null;
            :bk_fatca.des_tipo_id_nac := null;
            :bk_fatca.num_identif_nac := null;
            go_item ('BK_FATCA.COD_PAIS_NAC');
            :bk_fatca.val_nac_us := 'N';
            :bk_fatca.val_nac := null;
         else                                                                                                            --No
            :bk_fatca.val_nac_us := 'S';
         end if;
      end if;
      if nvl (:bk_fatca.val_nac, 'N') = 'N'
         and nvl (:bk_fatca.val_nac_us, 'N') = 'S'
      then
         set_lov_property ('LOV_PAIS_NAC_FACTA', group_name, 'RG_PAISES');
         set_alert_property ('ALERTA_FACTA', alert_message_text, '¿Tiene Usted  otra Ciudadanía?');
         if show_alert ('ALERTA_FACTA') = alert_button1
         then                                                                                                           --Si
            :bk_fatca.cod_tipo_id_nac := null;
            :bk_fatca.des_pais_nac := null;
            :bk_fatca.cod_pais_nac := null;
            :bk_fatca.des_tipo_id_nac := null;
            :bk_fatca.num_identif_nac := null;
            go_item ('BK_FATCA.COD_PAIS_NAC');
            :bk_fatca.val_nac_us := 'S';
            :bk_fatca.val_nac := 'N';
         else                                                                                                            --No
            :bk_fatca.val_nac := 'S';
         end if;
      end if;
      -- EFrancisco 22/09/2014 Implementacion Fatca.
      if nvl (:bk_fatca.val_res_us, 'N') = 'N'
         and nvl (:bk_fatca.val_nac, 'N') = 'S'
         and nvl (:bk_fatca.val_nac_us, 'N') = 'S'
         and vesfisico = 'S'
      then
         if :bk_fatca.val_usperson = 'N'
         then
            set_lov_property ('LOV_PAIS_RES_FACTA', group_name, 'RG_PAISES_US');
            set_alert_property ('ALERTA_FACTA', alert_message_text, '¿Tiene usted Residencia Norteamericana?');
            if show_alert ('ALERTA_FACTA') = alert_button1
            then                                                                                                        --Si
               if get_item_property ('BK_FATCA.COD_TIPO_ID_RES', visible) = 'FALSE'
               then
                  set_item_property ('BK_FATCA.COD_TIPO_ID_RES', visible, property_true);
                  set_item_property ('BK_FATCA.DES_TIPO_ID_RES', visible, property_true);
                  set_item_property ('BK_FATCA.NUM_IDENTIF_RES', visible, property_true);
                  set_item_property ('BK_FATCA.COD_TIPO_ID_RES', enabled, property_true);
                  set_item_property ('BK_FATCA.NUM_IDENTIF_RES', enabled, property_true);
                  set_item_property ('BK_FATCA.COD_PAIS_RES', position, :emision.xitempos1, :emision.yitempos1);
                  set_item_property ('BK_FATCA.DES_PAIS_RES', position, :emision.xitempos2, :emision.yitempos2);
               end if;
               :bk_fatca.cod_pais_res := null;
               :bk_fatca.des_pais_res := null;
               :bk_fatca.cod_tipo_id_res := null;
               :bk_fatca.des_tipo_id_res := null;
               :bk_fatca.num_identif_res := null;
               go_item ('BK_FATCA.COD_PAIS_RES');
               :bk_fatca.val_res_us := 'N';
               :bk_fatca.val_res := null;
            else                                                                                                         --No
               :bk_fatca.val_res_us := 'S';
            end if;
         else
            :bk_fatca.val_res_us := 'S';
         end if;
      elsif vesfisico = 'N'
      then                                                                                      --si es juridico no pregunto.
         :bk_fatca.val_res_us := 'S';
      end if;
      if nvl (:bk_fatca.val_res, 'N') = 'N'
         and nvl (:bk_fatca.val_nac, 'N') = 'S'
         and nvl (:bk_fatca.val_nac_us, 'N') = 'S'
         and nvl (:bk_fatca.val_res_us, 'N') = 'S'
         and vesfisico = 'S'
      then
         set_lov_property ('LOV_PAIS_RES_FACTA', group_name, 'RG_PAISES');
         set_alert_property ('ALERTA_FACTA', alert_message_text, '¿Tiene usted Residencia de otro país?');
         if show_alert ('ALERTA_FACTA') = alert_button1
         then                                                                                                           --Si
            :bk_fatca.cod_pais_res := null;
            :bk_fatca.des_pais_res := null;
            :bk_fatca.cod_tipo_id_res := null;
            :bk_fatca.des_tipo_id_res := null;
            :bk_fatca.num_identif_res := null;
            if get_item_property ('BK_FATCA.COD_TIPO_ID_RES', visible) = 'TRUE'
            then
               :emision.xitempos1 := get_item_property ('BK_FATCA.COD_PAIS_RES', x_pos);
               :emision.yitempos1 := get_item_property ('BK_FATCA.COD_PAIS_RES', y_pos);
               :emision.xitempos2 := get_item_property ('BK_FATCA.DES_PAIS_RES', x_pos);
               :emision.yitempos2 := get_item_property ('BK_FATCA.DES_PAIS_RES', y_pos);
            end if;
            set_item_property ('BK_FATCA.COD_TIPO_ID_RES', visible, property_false);
            set_item_property ('BK_FATCA.DES_TIPO_ID_RES', visible, property_false);
            set_item_property ('BK_FATCA.NUM_IDENTIF_RES', visible, property_false);
            set_item_property ('BK_FATCA.COD_PAIS_RES', position, 181, 51);
            set_item_property ('BK_FATCA.DES_PAIS_RES', position, 231, 51);
            go_item ('BK_FATCA.COD_PAIS_RES');
            :bk_fatca.val_res_us := 'S';
            :bk_fatca.val_res := 'N';
         else                                                                                                            --No
            :bk_fatca.val_res := 'S';
         end if;
      elsif vesfisico = 'N'
      then                                                                                      --si es juridico no pregunto.
         :bk_fatca.val_res := 'S';
      end if;
      -- EFrancisco 22/09/2014 Implementacion Fatca.
      /*if :BK_FATCA.COD_PAIS_RES is not null or :BK_FATCA.COD_PAIS_NAC is not null and :BK_FATCA.VAL_NAC_US is not null and :BK_FATCA.VAL_RES_US is not null then--si tiene datos en algun pais de nacionalidad o residente.
      if (:BK_FATCA.VAL_RES = 'S' and vCodPaisFatca like '%|'||:BK_FATCA.COD_PAIS_RES||'|%') or
      (:BK_FATCA.VAL_NAC = 'S' and vCodPaisFatca like '%|'||:BK_FATCA.COD_PAIS_NAC||'|%') or
      (:BK_FATCA.VAL_RES_US = 'S' and vCodPaisFatca like '%|'||:BK_FATCA.COD_PAIS_RES||'|%') or
      (:BK_FATCA.VAL_NAC_US = 'S' and vCodPaisFatca like '%|'||:BK_FATCA.COD_PAIS_NAC||'|%') then--si el pais es alguno de los que aplica FATCA.
      :BK_FATCA.VAL_PRES := 'S';--ya que es U.S. Person no valido 183 dias.
      end if;
      end if;*/
      if nvl (:bk_fatca.val_usperson, 'N') = 'S'
      then
         :bk_fatca.val_pres := 'S';                                              --ya que es U.S. Person no valido 183 dias.
      end if;
      if nvl (:bk_fatca.val_pres, 'N') = 'N'
         and nvl (:bk_fatca.val_res, 'N') = 'S'
         and nvl (:bk_fatca.val_nac, 'N') = 'S'
         and nvl (:bk_fatca.val_nac_us, 'N') = 'S'
         and nvl (:bk_fatca.val_res_us, 'N') = 'S'
         and vesfisico = 'S'
      then                                                           -- si es fisico y ya validamos las anteriores preguntas.
         set_alert_property ('ALERTA_FACTA',
                             alert_message_text,
                                '¿Ha permanecido la persona '
                             || pa.param.parametro_x_empresa (:variables.codempresa, 'PRES_SUS_FATCA', 'PA')
                             || ' días ó más en territorio Estadounidense en los últimos 12 meses?');
         if show_alert ('ALERTA_FACTA') = alert_button1
         then                                                                                                            --Si
            go_item ('BK_FATCA.PRESENCIA_SUST');
         else                                                                                                            --No
            :bk_fatca.val_pres := 'S';
         end if;
      elsif vesfisico = 'N'
      then                                                                                      --si es juridico no pregunto.
         :bk_fatca.val_pres := 'S';
      end if;
   elsif vcantdiaactfatca <= vcantdiasvalidacion
         or nvl (:bk_fatca.ciclo_val, 'N') = 'N'
   then
      :bk_fatca.ciclo_val := 'S';
      :bk_fatca.val_nac := 'S';
      :bk_fatca.val_res := 'S';
      :bk_fatca.val_pres := 'S';
      -- EFrancisco 22/09/2014 Implementacion Fatca.
      if :system.cursor_record = 1
      then
         next_record;
      else
         go_item ('CUENTA_CLIENTE_REL.TIPO_RELACION');
      end if;
   end if;
           --end if vCantDiaActFatca >= vCantDiasValidacion
   -- EFrancisco 22/09/2014 Implementacion Fatca.
   if nvl (:bk_fatca.val_nac, 'N') = 'S'
      and nvl (:bk_fatca.val_res, 'N') = 'S'
      and nvl (:bk_fatca.val_pres, 'N') = 'S'
      and nvl (:bk_fatca.val_nac_us, 'N') = 'S'
      and nvl (:bk_fatca.val_res_us, 'N') = 'S'
   then
      update personas
         set fec_actualizacion = sysdate,
             es_fatca = 'N',
             lleno_fatca = 'S'
       where cod_persona = :bk_fatca.cod_persona;
      --
      if :system.cursor_record = 1
      then
         next_record;
      else
         go_item ('CUENTA_CLIENTE_REL.TIPO_RELACION');
      end if;
   end if;
exception
   when others
   then
      message ('Error en program unit P_ValidaPersonaFacta > ' || sqlerrm);
      message (' ', no_acknowledge);
end p_validapersonafacta;

FUNCTION RETORNA_COMPANIA(P_CAMPO IN OUT VARCHAR2,
                          P_BASE  IN VARCHAR2 )
RETURN BOOLEAN IS
BEGIN
     P_CAMPO := :VARIABLES.CODEMPRESA;
     RETURN TRUE;
END;

procedure solicitud_aprobacion (
   pcodcliente    in       varchar2,
   pcliente       in       varchar2,
   pcodproducto   in       varchar2,
   pproducto      in       varchar2,
   pplazo         in       number,
   ptasa          in       number,
   pmonto         in       number,
   -- Jsanchez
   pspread        in       number,
   pbruta         in       number,
   presp          out      number)
is
   -- Efectúa: Pide aprobación para la tasa de los CDs. Verifica primero si ya existe una solicitud
   --     de aprobación, pendiente o aprobada, para saber como proceder.
   -- Requiere:
   -- Historia: API 28/08/2012 - Creación.
   vsolicitud    number;
   vmensaje      varchar2 (150);
   vnumboton     number;
   vproceso      number;
   vdetalle      varchar2 (1000);
   vmonto        number (20, 2);
   vpediraprob   varchar2 (1);
begin
   -- Revisar si se sale del rango de tasa establecido y debe pedir aprobación
   vpediraprob := 'S';
   --
   begin
      select 'N'
        into vpediraprob
        from cd_prd_tasa_plazo_monto
       where cod_empresa = :variables.codempresa
         and cod_producto = pcodproducto
         and estado = 'A'
         and pmonto between monto_minimo and monto_maximo
         and pplazo between plazo_minimo and plazo_maximo
         -- Jsanchez
         -- and ptasa between tasa_minima and tasa_maxima
         -- and fecha_vigencia <= :variables.fecha;
         and pbruta between tasa_minima and tasa_maxima
         and pspread <= spread
         and fecha_vigencia < :variables.fecha;
   exception
      when others
      then
         vpediraprob := 'S';
   end;
   --
   if vpediraprob = 'S'
   then
      -- Buscar el código que corresponde al proceso de reimpresión de CDs
      begin
         :variables.aprob_apertura_cds := parametros.parametro_x_empresa (:variables.codempresa, 'APROB_APERTURA_CDS', 'PA');
      exception
         when others
         then
            utilitarios.mensaje_error ('000083', :variables.codidioma, 'PA', 'APROB_APERTURA_CDS');
            presp := 0;
      end;
      --
      :variables.valoresclave := 'COD_CLIENTE:'
      || pcodcliente
      || '|COD_PRODUCTO:'
      || pcodproducto
      || '|PLAZO:'
      || pplazo
      || '|MONTO:'
      || pmonto
      || '|SPREAD:'
      || pspread;
      --LMVR
      /*'COD_CLIENTE:'   || pcodcliente
                              || '|COD_PRODUCTO:' || pcodproducto
                              || '|PLAZO:'        || pplazo
                              || '|MONTO:'        || pmonto
                              -- Jsanchez
                              -- || '|TASA:'         || ptasa;
                              || '|TASA:'         || pbruta;*/
      --LMVR                              
      -- Verificar si existe una solicitud pendiente
      vsolicitud := pa.verifica_solicitud_procesos (:variables.aprob_apertura_cds, null, :variables.usuario, :variables.valoresclave);
      --
      if vsolicitud = 0
      then                                                                                                           -- Error
         utilitarios.mensaje_error ('000434', :variables.codidioma, 'PA', 'SOLICITUD_X_PROCESO');
         presp := 0;
      elsif vsolicitud = 1
      then                                                                     -- Ya había sido insertada, esperar aprobación
         pa.pa_utl.obtienemensajeerror ('000733', 'PA', null, :variables.codidioma, vmensaje);
         set_alert_property ('INFORMACION', alert_message_text, vmensaje);
         vnumboton := show_alert ('INFORMACION');
         presp := 0;
      elsif vsolicitud = 2
      then                                                                        -- No existe, preguntar si desea solicitar?
         if show_alert ('SOLICITUD') = alert_button1
         then
            vdetalle := 'Cliente: '  || pcliente || chr (13) || chr (10)
                     || 'CEDULA:'    || obt_num_id_persona_peso (pcodcliente) || chr (13) || chr (10)
                     || 'PRODUCTO: ' || pproducto || chr (13) || chr (10)
                     || 'Plazo: '    || pplazo || ' Días ' || chr (13) || chr (10)
                     || 'Monto: $'   || ltrim (to_char (pmonto, '999,999,999,999.00')) || chr (13) || chr (10)
                     || 'Spread: '   || ltrim (to_char (pspread, '99.00')) || chr (13) || chr (10)
                     || 'Tas.Bruta: '|| ltrim (to_char (pbruta - pspread, '99.00'));
            vsolicitud :=
               pa.inserta_solicitud_procesos (:variables.aprob_apertura_cds,
                                              null,
                                              :variables.usuario,
                                              sysdate,
                                              :variables.valoresclave,
                                              -- Jsanchez
                                              ltrim (to_char (pbruta, '990.0000')),--LMVR
                                              vdetalle);
            if vsolicitud = 0
            then
               utilitarios.mensaje_error ('000436', :variables.codidioma, 'PA', 'SOLICITUD_X_PROCESO');
            else
               pa.pa_utl.obtienemensajeerror ('000733', 'PA', null, :variables.codidioma, vmensaje);
               set_alert_property ('INFORMACION', alert_message_text, vmensaje);
               vnumboton := show_alert ('INFORMACION');
            end if;
         end if;
         presp := 0;
      elsif vsolicitud = 3
      then                                                                         -- Existe una solicitud aprobada, proceder
         presp := 1;
      elsif vsolicitud = 4
      then
         utilitarios.mensaje ('000734', :variables.codidioma, 'PA'); -- El código de proceso no existe y debe crearse primero
         presp := 0;
      elsif vSolicitud = 5 then 
			 	utilitarios.mensaje('100076', :variables.codidioma, 'PA');
			 	--pResp := 0;
			 	--LMVR
			 	if show_alert ('SOLICITUD') = alert_button1
         then
            vdetalle := 'Cliente: '  || pcliente || chr (13) || chr (10)
                     || 'CEDULA:'    || obt_num_id_persona_peso (pcodcliente) || chr (13) || chr (10)
                     || 'PRODUCTO: ' || pproducto || chr (13) || chr (10)
                     || 'Plazo: '    || pplazo || ' Días ' || chr (13) || chr (10)
                     || 'Monto: $'   || ltrim (to_char (pmonto, '999,999,999,999.00')) || chr (13) || chr (10)
                     || 'Spread: '   || ltrim (to_char (pspread, '99.00')) || chr (13) || chr (10)
                     || 'Tas.Bruta: '|| ltrim (to_char (pbruta - pspread, '99.00'));
            vsolicitud :=
               pa.inserta_solicitud_procesos (:variables.aprob_apertura_cds,
                                              null,
                                              :variables.usuario,
                                              sysdate,
                                              :variables.valoresclave,
                                              -- Jsanchez
                                              ltrim (to_char (pbruta, '990.0000')),--LMVR
                                              vdetalle);
            if vsolicitud = 0
            then
               utilitarios.mensaje_error ('000436', :variables.codidioma, 'PA', 'SOLICITUD_X_PROCESO');
            else
               pa.pa_utl.obtienemensajeerror ('000733', 'PA', null, :variables.codidioma, vmensaje);
               set_alert_property ('INFORMACION', alert_message_text, vmensaje);
               vnumboton := show_alert ('INFORMACION');
            end if;
         end if;
         presp := 0;
         --LMVR
      end if;
   else
      presp := 1;
   end if;
end;

procedure solicitud_debito_cta (
   pcodcliente       in       varchar2,
   pcliente          in       varchar2,
   ptransaccion      in       number,
   psubtransaccion   in       number,
   pmodulo           in       varchar2,
   pcuenta           in       varchar2,
   pfecha            in       date,
   pmonto            in       number,
   presp             out      number)
is
   -- Efectúa: Maneja la solicitud de aprobación del débito a cuenta, verificando primero si existe una solicitud pendiente o aprobada.
   -- Requiere: Definir en la forma los siguientes ítems: variables.PROC_DEBITO_CTA, variables.ValoresClaveDbCta
   --      Definir alerta: DEBITO_CUENTA (tipo note, boton Ok)
   --      Este procedimiento recibe todos los parámetros que sean necesarios para identificar como única
   --      la transacción que pide aprobación. Estos valores se enviarán en variables.valoresclave
   -- Historia: API 09/11/2012 - Creación.
   vsolicitud         number;
   vmensaje           varchar2 (150);
   vnumboton          number;
   vproceso           number;
   vdetalle           varchar2 (1000);
   vpediraprob        varchar2 (1);
   vdesctransaccion   varchar2 (100);
   vdescsubtransacc   varchar2 (100);
begin
   -- Buscar el código que corresponde al proceso de aprobación Lista OFAC
   begin
      :variables.proc_debito_cta := parametros.parametro_x_empresa (:variables.codempresa, 'PROC_DEBITO_CTA', 'PA');
   exception
      when others
      then
         utilitarios.mensaje_error ('000083', :variables.codidioma, 'PA', 'PROC_DEBITO_CTA');
         presp := 0;
         raise form_trigger_failure;
   end;
   -- Este string se envía como clave para identificar el registro de la solicitud de aprobación
   :variables.valoresclavedbcta :=
         'TX:'
      || ptransaccion
      || '|SUBTX:'
      || psubtransaccion
      || '|CLIENTE:'
      || pcodcliente
      || '|MODULO:'
      || pmodulo
      || '|FECHA:'
      || pfecha;
   -- Verificar si existe una solicitud pendiente
   vsolicitud :=
      pa.verifica_solicitud_procesos (:variables.proc_debito_cta,
                                      pcuenta,
                                      :variables.usuario,
                                      :variables.valoresclavedbcta,
                                      ltrim (to_char (pmonto, '9,999,999,990.00')));
   if vsolicitud = 0
   then                                                                                                              -- Error
      utilitarios.mensaje_error ('000434', :variables.codidioma, 'PA', 'SOLICITUD_X_PROCESO');
      presp := 0;
   elsif vsolicitud = 1
   then                                                                        -- Ya había sido insertada, esperar aprobación
      set_alert_property ('DEBITO_CUENTA',
                          alert_message_text,
                          'La solicitud de débito a cuenta ya había sido insertada, espere su aprobación.');
      vnumboton := show_alert ('DEBITO_CUENTA');
      presp := 0;
   elsif vsolicitud = 2
   then                                                                                               -- No existe, insertar.
      -- Descripción de la transacción
      begin
         select descripcion
           into vdesctransaccion
           from cat_tip_transac
          where cod_sistema = pmodulo
            and tip_transaccion = ptransaccion;
      exception
         when others
         then
            utilitarios.mensaje ('000049', :variables.codidioma, 'PA');
            presp := 0;
            raise form_trigger_failure;
      end;
      -- Descripción de la Sub-transacción
      begin
         select descripcion
           into vdescsubtransacc
           from subtip_transac
          where cod_empresa = :variables.codempresa
            and cod_sistema = pmodulo
            and tip_transaccion = ptransaccion
            and subtip_transac = psubtransaccion;
      exception
         when others
         then
            utilitarios.mensaje ('000219', :variables.codidioma, 'PA');
            presp := 0;
            raise form_trigger_failure;
      end;
      --
      vdetalle := 'Cliente: ' || pcliente || chr (13) || chr (10)
               || 'Producto: ' || pa_obt_descripcion_producto (:variables.codempresa, :emision.cod_producto) || chr (13) || chr (10)
               || 'Transacción: ' || vdesctransaccion || chr (13) || chr (10)
               || 'Sub-Transacción: ' || vdescsubtransacc || chr (13) || chr (10)
               || 'Módulo: Certificados de Depósito';
      --
      vsolicitud :=
         pa.inserta_solicitud_procesos (:variables.proc_debito_cta,
                                        pcuenta,
                                        :variables.usuario,
                                        sysdate,
                                        :variables.valoresclavedbcta,
                                        ltrim (to_char (pmonto, '9,999,999,990.00')),
                                        vdetalle);
      if vsolicitud = 0
      then
         utilitarios.mensaje ('000436', :variables.codidioma, 'PA', null, 'SOLICITUD_X_PROCESO');
      else
         set_alert_property ('DEBITO_CUENTA',
                             alert_message_text,
                             'Se ha insertado una solicitud de débito a la cuenta ' || pcuenta || ', espere su aprobación.');
         vnumboton := show_alert ('DEBITO_CUENTA');
      end if;
      presp := 0;
   elsif vsolicitud = 3
   then                                                                            -- Existe una solicitud aprobada, proceder
      presp := 1;
   elsif vsolicitud = 4
   then
      utilitarios.mensaje ('000734', :variables.codidioma, 'PA');   -- El código de proceso no existe y debe crearse primero
      presp := 0;
   end if;
end;

PROCEDURE TASA_PLAZO_MONTO2( P_EMPRESA    IN VARCHAR2,
                            P_PRODUCTO   IN VARCHAR2,
                            P_CLIENTE    IN VARCHAR2,
                	          P_COD_TASA   IN OUT VARCHAR2,
                            P_SPREAD     IN OUT NUMBER,
                            P_TASA_BRUTA IN OUT NUMBER,
                            P_TASA_NETA  IN OUT NUMBER,
                            P_EXCENTO    IN     VARCHAR2,
			          						P_TIP_CD     IN VARCHAR2) IS

/* FHER, 07/01/1999.
   Se modifica la asignación de la tasa base, ya que se debe de tomar como la base +/- el 
   spread vigente de acuerdo al tipo de cd. Ya que este spread no se debe de tomar como el
   spread del certificado.
*/

 v_codigo_busqueda       varchar2(1) := null;
 v_cod_tasa              cd_cli_tasa_plazo_monto.cod_tasa%TYPE;
 v_valor_tasa            tasas_interes.valor_actual%TYPE;
 v_frecuencia		 cd_certificado.fre_capitaliza%TYPE;
 v_dias			 number(10);
 v_base_plazo		 cd_producto_x_empresa.base_plazo%TYPE;
 v_tasa			 cd_certificado.cod_tasa%TYPE;
 v_spread		       cd_certificado.spread_cd%TYPE;
 v_operacion		 varchar2(1);
 v_tasa_neta		 cd_certificado.tas_neta%TYPE;
 v_tasa_bruta		 cd_certificado.tas_bruta%TYPE;
 v_fec_vencimiento	 cd_certificado.fec_vencimiento%TYPE;
 v_fec_emision		 cd_certificado.fec_emision%TYPE;
 v_monto		       cd_certificado.monto%TYPE;
 v_error                 varchar2(6);
 v_sqlcode               number(6) ;
 nvalor									number:=0;
vcodmensaje 					varchar2(20):='';
vError							  varchar2(4000);
BEGIN


-- carga las variables locales con  los valores del bloque correspondiente
-- de acuerdo al tipo de cd.

  if p_tip_cd = 'CU' then
    v_fec_vencimiento	:= :pblock.fec_vencimiento; 
    v_fec_emision	:= :pblock.fec_emision; 
    v_monto		:= :pblock.monto; 
  elsif p_tip_cd = 'CA' then
    v_fec_vencimiento	:= :pblock2.fec_vencimiento; 
    v_fec_emision	:= :pblock2.fec_emision; 
    v_monto		:= :pblock2.monto; 
  elsif  p_tip_cd = 'VI' then
    v_fec_emision	:= :pblock1.fec_emision;   
    v_monto		:= :pblock1.monto; 
  end if;

  if p_tip_cd <> 'VI' then
    -- obtiene la base de plazo para el cd
    v_base_plazo := :bkproducto.base_plazo;

    -- calcula el numero de dias del plazo del certificado
    cd_calcula_dias( v_fec_emision, v_fec_vencimiento, v_base_plazo, v_frecuencia, v_dias);
  else
    v_dias := 0;
  end if;

-- obtiene la tasa preferencial registrada  de acuerdo a la prioridad
-- primero por cliente, sino, por producto.
--p_depura('jsq 2 cdfemice '||'-'||p_empresa||'-'||p_producto||'-'||p_cliente||'-'||v_dias||'-'||v_monto||'-'||v_fec_emision||'-'||v_tasa||'-'||v_spread||'-'||v_operacion);
/*cd_tasa_plazo_monto(  
  	p_empresa ,
	p_producto ,
	p_cliente ,
	v_dias ,
	v_monto ,
	v_fec_emision ,
	v_tasa ,
	v_spread ,
	v_operacion );*/
	nvalor:=cd.pkg_cd_inter.Obtiene_CDTasActual( p_empresa ,
															 						 	 p_producto ,
																						 v_dias ,
																						 v_monto ,
																						 v_tasa ,
																						 v_spread ,
																						 v_operacion,
																						 vcodmensaje );
  
-- obtiene el valor actual de la tasa encontrada..
  v_tasa_bruta := CD.pkg_cd_inter.CD_TASINTERES_BASE(p_empresa , v_tasa ,  :variables.fecha, v_error, v_sqlcode);
  mensaje('1 v_tasa_bruta '||nvl(v_operacion,'t'));

-- se debe obtener la tasa neta con el codigo especificado...
  CD.pkg_cd_inter.CD_CALCULA_TASA_NETA(
    v_tasa_bruta ,
    v_spread ,
    nvl(:emision.porcentaje_renta,0) ,
    v_tasa_neta,
    v_operacion,
    vError );

	if vError is not null then
      utilitarios.mensaje_error ('000090', :variables.codidioma, :variables.codsistema, vError);
      raise form_trigger_failure;   
   end if;      

  :variables.tasa_neta_antes     := v_tasa_neta;
  p_cod_tasa := v_tasa;
  p_spread := 0;
  p_tasa_bruta := v_tasa_bruta;
  p_tasa_neta := v_tasa_neta;
END;

/*
	HAGUTIERREZ | REQ_19940
  Funcion para validar si tiene formas de pago registradas
  y evitar el uso de la variable variables.control
*/

FUNCTION tiene_forma_pago RETURN VARCHAR2 IS
	numlineas number:= 0;
BEGIN
     --
   begin
      select count (*)
        into numlineas
        from cd_detalle_forma_pago
       where consecutivo_fpg = :variables.consec_forma_pago;
      --
   exception
      when others
      then
         utilitarios.mensaje ('000646', :variables.codidioma, 'CD', sqlerrm);
         raise form_trigger_failure;
   end;

   if numlineas = 0
   then
      RETURN 'N';
   else
      RETURN 'S';
   end if;
END;

PROCEDURE Valida_BA IS
   --
   vCodMoneda  number(2);
   vFechaHoyBA date;
   --
begin
   begin
      select c.codigo_moneda
      into   vCodMoneda
      from   ba_ctas_corrientes c,
             entes_externos     e,
             personas p
      where  c.codigo_empresa         = :variables.codempresa
      and    c.id_cuenta          = :pblock.num_cuenta
      and    to_char(c.codigo_emisor) = e.cod_ente
      and    e.cod_persona = p.cod_persona;
   exception
      when no_data_found then
         bell;
         Utilitarios.Mensaje('000530',:variables.CodIdioma,'CD');
         raise form_trigger_failure;
      when others then
         bell;
         Utilitarios.Mensaje_Error('000531',:variables.CodIdioma,'CD',SQLCODE);
         raise form_trigger_failure;
   end;
   --
   -- Se valida la moneda de la cuenta con respecto a la de la transaccion
   --
   if (to_char(vCodMoneda) <> :pblock.cod_moneda) then
      --
      bell;
      Utilitarios.Mensaje('000528',:variables.CodIdioma,'CD');
      raise form_trigger_failure;
      --
   end if;
   --
   -- Se valida la fecha de calendario
   --
   vFechaHoyBA := UTL_Calendario.Fecha_Calendario_Sistema('BA',
               	                                          :variables.CodEmpresa,
	                                                  :variables.CodAgencia);
   --
/*   
   if (trunc(vFechaHoyBA) <> trunc(:variables.fecha)) then
      --
      bell;
      Utilitarios.Mensaje('000529',:variables.CodIdioma,'CD');
      raise form_trigger_failure;
      --
   end if;
*/   
end;

PROCEDURE Valida_CC IS

-- Efectúa: Valida la cuenta de efectivo escogida.
-- Requiere:
-- Historia: API 31/08/2012: Adecuación por la Norma #13-2011 de la DGII sobre las cuentas 
-- a que se acreditan los intereses - Para personas física, debe pertenecer a una persona
-- física y para personas jurídicas solo puede ser del titular de la cuenta.
   --
   vCodMoneda    moneda.cod_moneda%type;
   vFechaHoyCC   date;
   vIndEstado    cuenta_efectivo.ind_estado%type;
   vTipoPersona  varchar2(1); -- API 31/08/2012
   vTitular			 varchar2(15); -- API 31/08/2012
   --
begin
   if ( :pblock.num_cuenta is null ) then
      bell;
      UTILITARIOS.mensaje('000113',:variables.CodIdioma,'CD');
      raise form_trigger_failure;
   else
      :pblock.num_cuenta := substr(:pblock.num_cuenta,1,1)||lpad(substr(:pblock.num_cuenta,2),13,'0');
      --
      begin
         select a.ind_estado,
                c.cod_moneda,
                -- API 31/08/2012
                decode(es_fisica,'S','N','J'), 
                a.cod_cliente
         into   vIndEstado,
                vCodMoneda,
                -- API
                vTipoPersona,  
                vTitular
         from   cuenta_efectivo a, personas b, productos C
         where  ( a.cod_empresa  = :variables.CodEmpresa      )
         and    ( a.num_cuenta   = to_number(:pblock.num_cuenta))
         and    ( b.cod_persona  = a.cod_cliente              )
         and    ( c.cod_empresa  = a.cod_empresa              )
         and    ( c.cod_producto = a.cod_producto             );
      exception
         when no_data_found then
            bell;
            :pblock.num_cuenta := NULL;
            Utilitarios.Mensaje('000527',:variables.CodIdioma,'CD');
            raise form_trigger_failure;
         when others then
            :pblock.num_cuenta := NULL;
            bell;
            Utilitarios.Mensaje_Error('000184',:variables.CodIdioma,'CD',SQLCODE);
            raise form_trigger_failure;
      end;
      -- API 31/08/2012: Validación Norma #13-2012 DGII
      if :emision.tipo_persona = 'N' and :emision.tipo_persona <> vTipoPersona then
      	bell;
        :pblock.num_cuenta := NULL;
        Utilitarios.Mensaje('000688',:variables.CodIdioma,'PA',null,'en la cuenta seleccionada, debe pertencer a una persona física.');
        raise form_trigger_failure;
      end if;
      if :emision.tipo_persona = 'J' and vTitular <> :emision.cliente then
      	bell;
        :pblock.num_cuenta := NULL;
        Utilitarios.Mensaje('000688',:variables.CodIdioma,'PA',null,'en la cuenta seleccionada, debe pertencer al titular del certificado.');
        raise form_trigger_failure;
      end if;
      --
      -- Se valida el estado de la cuenta de efectivo
      --
      if vIndEstado not in ('1','3','6') then
         --
         Utilitarios.Mensaje('000532',:variables.CodIdioma,'CD');
         raise form_trigger_failure;
         --
      end if;
      --
      -- Se valida la moneda de la cuenta con respecto a la de la transaccion
      --
      if (vCodMoneda <> :pblock.cod_moneda) then
         --
         bell;
         :pblock.num_cuenta := NULL;
         Utilitarios.Mensaje('000528',:variables.CodIdioma,'CD');
         raise form_trigger_failure;
         --
      end if;
      --
      -- Se valida la fecha de calendario
      --
      vFechaHoyCC := UTL_Calendario.Fecha_Calendario_Sistema('CC',
		  	                                     :variables.CodEmpresa,
 			                                     :variables.CodAgencia);
      -- 
 /*         
      if (trunc(vFechaHoyCC) <> trunc(:variables.fecha)) then
         --
         bell;
         Utilitarios.Mensaje('000529',:variables.CodIdioma,'CD');
         raise form_trigger_failure;
         --
      end if;
      */
   end if;

END;

PROCEDURE Valida_CG IS
   --
   CategoriaCta          varchar2(1);
   vPermAsiento          varchar2(1);
   IndAcceso             varchar2(1);
   vTipMovimi            varchar2(1);
   vMonedaCta            number(2);
   vFechaHoyCG           date;
   --
begin
   --
   begin
      select categoria_cta,
             moneda_cuenta
      into   CategoriaCta,
             vMonedaCta
      from   cg_catalogo_x_empresa
      where  codigo_empresa  = :variables.codempresa
      and    cuenta_contable = :pblock.num_cuenta;
   exception
     when no_data_found then
        :pblock.num_cuenta := null;
        utilitarios.mensaje('000001', :variables.codidioma, 'CG');
        raise form_trigger_failure;
     when others then
        :pblock.num_cuenta := null;
        utilitarios.mensaje_error('000099', :variables.codidioma,'CG',sqlcode);
        raise form_trigger_failure;
   end;
   --
   -- cuenta contable debe permitir movimientos y debe ser posible
   -- utilizarla en asientos de diario, ademas se obtiene el tipo de cambio
   -- que utiliza (actual, historico, etc.).
   --
   begin
      select tipo_movimiento    ,
             permite_asiento    ,
             ind_acceso
      into   vTipMovimi         ,
             vPermAsiento,
             IndAcceso
      from   cg_catalogo_x_empresa
      where  codigo_empresa  = :variables.codempresa
      and    cuenta_contable = :pblock.num_cuenta
      and    estado          = 'A';
   exception
      when others then
         utilitarios.mensaje_error('000221', :variables.codidioma,'CG',sqlcode);
         raise form_trigger_failure;
   end;
   --
   if (IndAcceso = 'S')
   then
      utilitarios.mensaje('000245', :variables.codidioma, 'CG');
      raise form_trigger_failure;
   end if;
   if (vTipMovimi = 'M')
   then
      utilitarios.mensaje('000003', :variables.codidioma, 'CG');
      raise form_trigger_failure;
   elsif vPermAsiento = 'N'
   then
      utilitarios.mensaje('000058', :variables.codidioma, 'CG');
      raise form_trigger_failure;
   end if;
   --
   -- Se valida la moneda de la cuenta
   --
   if (to_char(vMonedaCta) <> :pblock.cod_moneda) then
      --
      Utilitarios.Mensaje('000528',:variables.CodIdioma,'CD');
      raise form_trigger_failure;
      --
   end if;
end;

-- por Lperez 25/05/2006, para validar no se grabe un cliente repetido en el bloque
procedure valida_cliente_repetido
is
   vreg       number;
   --vtipo   varchar2(2);
   vcliente   varchar2 (15);
begin
   go_block ('cuenta_cliente_rel');
   first_record;
   --vreg    := :system.cursor_record;
   --vcliente := :cuenta_cliente_rel.codigo_cliente;
   loop
      if :system.last_record = 'TRUE'
         and :system.cursor_record = 1
      then
         exit;
      else
         vreg := :system.cursor_record;
         vcliente := :cuenta_cliente_rel.codigo_cliente;
         --first_record;
         loop
            next_record;
            if vreg <> :system.cursor_record
            then
               if vcliente = :cuenta_cliente_rel.codigo_cliente
               then
                  utilitarios.mensaje ('100084',
                                       :variables.codidioma,
                                       'PA',
                                       acknowledge,
                                       ('(04) Este Cliente ya fue digitado en el registro No. ' || vreg || '. Verifique por Favor.'));
                  --go_record(vreg);
                  raise form_trigger_failure;
               end if;
            end if;
            exit when :system.last_record = 'TRUE';
         --next_record;
         end loop;
         go_record (vreg);
         next_record;
         --
         if :emision.tipo_persona <> :cuenta_cliente_rel.tipo_persona
         then
            utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, ('(05) No puede Relacionar Clientes Personales y Comerciales. Por Favor Verifique.'));
            raise form_trigger_failure;
         end if;
         --
         exit when :system.last_record = 'TRUE';
      end if;
   end loop;
end;

PROCEDURE Valida_Firma(pbloque number) IS
-- Para validar que la firma especificada sea valida, lperez 29/05/2006.
 	Cursor busca_oficial (pfirma varchar2) is	
 	 select 'x'
	  from empleados a, personas b
	 where a.id_empleado    					= pfirma 
  	 and a.esta_activo    					= 'S'
  	 and nvl(a.firma_autorizada,'N')= 'S'
  	 -- Comentado por Jsanchez
  	 -- and ( substr(cod_agencia_labora,1,3)  = substr(:emision.cod_agencia,1,3) or -- RMARTINEZ 07/02/2008
  	 --			 substr(a.cod_agencia_labora,1,3)= substr(:variables.codagencia,1,3))
	   and a.cod_per_fisica 					= b.cod_per_fisica;
	vexiste varchar2(1);   
BEGIN	
	if :emision.oficial1 is null or :emision.oficial2 is null then
		go_item('emision.oficial1');
		raise form_trigger_failure;
	else
		open busca_oficial(:emision.oficial1);
		fetch busca_oficial into vexiste;
		if busca_oficial%notfound then			
			UTILITARIOS.mensaje_error('000676',:variables.CodIdioma,'PA',SqlCode);
			go_item('emision.oficial1');
			raise form_trigger_failure;
		end if;
		close busca_oficial;
		--
		open busca_oficial(:emision.oficial2);
		fetch busca_oficial into vexiste;
		if busca_oficial%notfound then			
			UTILITARIOS.mensaje_error('000676',:variables.CodIdioma,'PA',SqlCode);
			go_item('emision.oficial2');
			raise form_trigger_failure;
		end if;
		close busca_oficial;
		--
		if pbloque = 0 then
			:pblock.firma_aut1 := :emision.oficial1;
			:pblock.firma_aut2 := :emision.oficial2;
		elsif pbloque = 1 then
			:pblock1.firma_aut1 := :emision.oficial1;
			:pblock1.firma_aut2 := :emision.oficial2;
		elsif pbloque = 2 then
			:pblock2.firma_aut1 := :emision.oficial1;
			:pblock2.firma_aut2 := :emision.oficial2;
		end if;
	end if;	
END;
/*
if :emision.oficial1 is null or :emision.oficial2 is null then
		message('Debe especificar los oficiales autorizados para la firma..');
		message('');
		show_view('win_oficiales');
		go_item('emision.oficial1');
		RETURN FALSE;
	else
		return true;
	end if;	
	*/

  function valida_rango_tasa (ptip_tasa in varchar2, pmon_tasa in number)
   return boolean
is
   vvariacion_max   number (10, 6) := 0;
   vvariacion_min   number (10, 6) := 0;
   ex_error         exception;
   ex_rango         exception;
   vret             boolean        := true;
   vmensaje_err     varchar2 (300);
   vcod_error       varchar2 (10)  := null;
begin
   begin
      select variacion_min,
             variacion_max
        into vvariacion_min,
             vvariacion_max
        from tasas_interes
       where cod_empresa = :variables.codempresa
         and cod_tasa = ptip_tasa;
   exception
      when no_data_found
      then
         utilitarios.mensaje ('000661', 'ESPA', 'CD', null);
         --vMensaje_Err := 'No se encontraron los parámetros de la tasa de interés';
         raise ex_error;
      when others
      then
         utilitarios.mensaje ('000662', 'ESPA', 'CD', null, sqlerrm);
         --vMensaje_Err := 'Error buscando los parámetros de la tasa de interés';
         raise ex_error;
   end;
   if (nvl (pmon_tasa, 0) < vvariacion_min)
      or (nvl (pmon_tasa, 0) > vvariacion_max)
   then
      vmensaje_err := ' de ' || vvariacion_min || ' a ' || vvariacion_max;
      raise ex_rango;
   end if;
   return vret;
exception
   when ex_rango
   then
      utilitarios.mensaje ('000660', 'ESPA', 'CD', null, vmensaje_err);
      -- vret := false;
      return vret;
   when ex_error
   then
      vret := false;
      return vret;
   when others
   then
      vmensaje_err := sqlerrm;
      utilitarios.mensaje ('000663', 'ESPA', 'CD', null, sqlerrm);
      vret := false;
      return vret;
end;

-- Modificada por Lperez el 13/02/2007, el titular no debe llevar relacion, solo los relacionados
-- al cd, ya que la relacion es del relacionado hacia el titular.
-- Lperez 25/05/2006, Para validar no se grabe incorrectametne la relacion entre los cliente CD's
-- el tipo indica si es llamado desde un item = I o desde el bloque key-commit = B
procedure valida_relacion_cliente (tipo varchar2, total_reg number)
is
   vtotal_reg   number;
begin
   valida_relacion_y_o;
   if tipo = 'B'
   then
      go_block ('cuenta_cliente_rel');
      -- para saber total registros del bloque
      last_record;
      --
      vtotal_reg := :system.cursor_record;
   else
      vtotal_reg := total_reg;
   end if;
   --
   first_record;
   loop
      if :system.cursor_record = 1
      then
         if :tipo_relacion is not null
         then
            :cuenta_cliente_rel.tipo_relacion := null;
            utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, ('(06) El Cliente Principal no debe tener Relacion, ya que es el Titular del Cd.'));
         end if;
      else
         if :tipo_relacion is null
            and :cuenta_cliente_rel.codigo_cliente is not null
         then
            :variables.tipo_requerido := 'S';
            :cuenta_cliente_rel.tipo_relacion := ' ';
            go_item ('cuenta_cliente_rel.tipo_relacion');
            utilitarios.mensaje ('100084', :variables.codidioma, 'PA', acknowledge, ('(07) Debe especificar el tipo de relación para el Cliente No. ' || :system.cursor_record || ' del Certificado.'));
            raise form_trigger_failure;
         end if;
      end if;
      :variables.tipo_requerido := 'N';
      exit when :system.cursor_record = vtotal_reg;
      next_record;
   end loop;
   --
   if tipo = 'I'
   then
      go_item ('emision.cod_producto');
   end if;
end;

procedure valida_relacion_y_o
is
   lc_relacion   varchar2 (50);
begin
   go_block ('CUENTA_CLIENTE_REL');
   first_record;
   while :cuenta_cliente_rel.codigo_cliente is not null
   loop
      if lc_relacion is not null
      then
         :cuenta_cliente_rel.tipo_relacion := lc_relacion;
      end if;
      -- Jsanchez (06/02/2016)
      -- Se corrije proceso para que el valor de tipo de relacion no sean diferente al escogido en el primer registro
      -- if :system.cursor_record = 2
      if :system.cursor_record = 3
      then
         lc_relacion := :cuenta_cliente_rel.tipo_relacion;
      end if;
      if :system.last_record = 'TRUE'
      then
         exit;
      else
         next_record;
      end if;
   end loop;
   first_record;
end;

