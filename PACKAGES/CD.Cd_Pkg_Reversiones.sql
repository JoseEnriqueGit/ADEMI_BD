CREATE OR REPLACE PACKAGE BODY CD.Cd_Pkg_Reversiones IS
PROCEDURE Cd_P_Rversa (Pc_Empresa		IN	VARCHAR2,
					   Pc_Agencia		IN	VARCHAR2,
					   Pc_Moneda		IN	VARCHAR2,
                       Pn_Asiento		IN	NUMBER,
                       Pn_Comprobante	IN	NUMBER,
                       Pc_Cliente		IN	VARCHAR2,
                       Pd_Fecha			IN	DATE,
                       Pd_FechaEmision	IN	DATE,
                       Pc_Sistema		IN	VARCHAR2,
                       Pc_Idioma		IN	VARCHAR2,
                       Pc_Mensaje		OUT	VARCHAR2) IS
	vProdSinRedAnt number(8) := 0; 
	vContador number(8) := 0;
BEGIN
    BEGIN   
        select count(p.cod_producto) -- Cuento los CDs que pertenezcan a productos con ind_redencion_ant = 'N'
        into vProdSinRedAnt
        from cd_certificado c, cd_producto_x_empresa p
        where c.cod_empresa = Pc_Empresa 
            and c.estado = 'I' 
            and c.cod_moneda = Pc_Moneda 
            and c.numero_asiento_contable = Pn_Asiento 
            and c.numero_solicitud_cajas =  Pn_Comprobante
            and c.cliente = Pc_Cliente
            and p.cod_empresa = c.cod_empresa
            and p.cod_producto = c.cod_producto
            and p.ind_redencion_ant = 'N';
			      
        IF vProdSinRedAnt > 0 THEN  -- Si pertenecen a productos con ind_redencion_ant = 'N', muestro mensaje y no permito anulación
    		Pc_Mensaje:= PA.OBT_MENSAJE('000670',
                                        Pc_Idioma,
                                        'CD');    					
        ELSE  -- de lo contrario, procedo a anular			
            Cd_P_Anular_solicitud(Pc_Empresa,
								  Pc_Agencia,
                                  Pn_Comprobante,
                                  Pc_Idioma,
                                  Pc_Mensaje);
            IF Pc_Mensaje IS NOT NULL THEN
            	RETURN;
            END IF;
            
            IF Pc_Sistema NOT LIKE 'CJ' THEN
                Cd_P_Anular_Asiento(Pc_Empresa,
                                    Pd_FechaEmision,
                                    Pn_Asiento,
                                    Pc_Idioma,
                                    Pc_Mensaje);
                IF Pc_Mensaje IS NOT NULL THEN
                    RETURN;
                END IF;
            END IF;
            
            Cd_P_Anular_Certificados(Pc_Empresa,
                                     Pc_Agencia,
                                     Pc_moneda,
                                     Pn_Asiento,
                                     Pn_Comprobante,
                                     Pc_Cliente,
                                     Pd_Fecha,
                                     Pc_Sistema,
                                     Pc_Idioma,
                                     Pc_Mensaje);
            IF Pc_Mensaje IS NOT NULL THEN
            	RETURN;
            END IF;
        END IF; 					
    EXCEPTION
    	WHEN OTHERS THEN
        	Pc_Mensaje:= PA.OBT_MENSAJE('000143',
                                        Pc_Idioma,
                                        'CD'); 	
    END;
END;
PROCEDURE Cd_P_Anular_solicitud (Pc_Empresa		IN 	VARCHAR2,
								 Pc_Agencia		IN 	VARCHAR2,
                                 Pn_Comprobante	IN 	NUMBER,
                                 Pc_Idioma		IN 	VARCHAR2,
                                 Pc_Mensaje		OUT VARCHAR2) IS
BEGIN
   update bcj_solicitud
      set estado_comprobante = 'N',
          modificado_por = USER,
          fecha_modificacion = sysdate
    where codigo_empresa = Pc_Empresa
      and codigo_agencia =  Pc_Agencia
      and numero_comprobante = Pn_Comprobante
      and indicador_comprobante = 'I';
EXCEPTION
	WHEN OTHERS THEN
      Pc_Mensaje:= PA.OBT_MENSAJE('000537',
                                  Pc_Idioma,
                                  'CD');
END;
PROCEDURE Cd_P_Anular_Asiento (Pc_Empresa		IN	VARCHAR2,
							   Pd_FechaEmision	IN	DATE,
                               Pn_Asiento		IN	NUMBER,
                               Pc_Idioma		IN	VARCHAR2,
                               Pc_Mensaje		OUT	VARCHAR2) IS
BEGIN
  update cg_movimiento_resumen
     set estado = 'R',
         modificado_por = USER,
         fecha_modificacion = SYSDATE
   where codigo_empresa   = Pc_Empresa
     and fecha_movimiento = Pd_FechaEmision
     and numero_asiento   = Pn_Asiento;
  Update Cg_movimiento_detalle
     Set Estado = 'R',
         Modificado_Por     = USER,
         Fecha_Modificacion = SYSDATE
   where codigo_empresa   = Pc_Empresa
     and fecha_movimiento = Pd_FechaEmision
     and numero_asiento   = Pn_Asiento;    
   exception
    when others then
      Pc_Mensaje:= PA.OBT_MENSAJE('000538',
                                  Pc_Idioma,
                                  'CD');
END;
PROCEDURE Cd_P_Anular_Certificados(Pc_Empresa		IN 	VARCHAR2,
								   Pc_Agencia		IN 	VARCHAR2,
                                   Pc_moneda		IN 	VARCHAR2,
                                   Pn_Asiento		IN 	NUMBER,
                                   Pn_Comprobante	IN	NUMBER,
                                   Pc_Cliente		IN 	VARCHAR2,
                                   Pd_Fecha			IN	DATE,
                                   Pc_Sistema		IN	VARCHAR2,
                                   Pc_Idioma		IN 	VARCHAR2,
                                   Pc_Mensaje		OUT	VARCHAR2) IS
Num_Cd number(10);
cursor certificados is
select num_certificado
from cd_certificado
where cod_empresa = Pc_Empresa 
        and (estado = 'I' 
        	 or 'CJ' =Pc_Sistema) 
        and cod_moneda = Pc_moneda 
        and numero_asiento_contable = Pn_Asiento
        and numero_solicitud_cajas = Pn_Comprobante
        and cliente = Pc_Cliente;
BEGIN
	for c in certificados loop
        begin
          update cd_certificado
             set estado = 'N',
                 modificado_por = user,
                 fec_modificacion = sysdate
           where cod_empresa = Pc_Empresa 
            and num_certificado = c.num_certificado;
          exception
           when others then
             Pc_Mensaje:= PA.OBT_MENSAJE('000539',
                                         Pc_Idioma,
                                         'CD');
        end;
        
        begin
          update cd_cupon
             set estado = 'N',
                 modificado_por = user,
                 fecha_modificacion = sysdate
           where cod_empresa = Pc_Empresa 
            and num_certificado = c.num_certificado;
        exception
           when others then 
             Pc_Mensaje:= PA.OBT_MENSAJE('000539',
                                  Pc_Idioma,
                                  'CD');
        end;

    	num_cd := to_number(substr(c.num_certificado,7,9)); 
		-- Anulando el numero consecutivo del Certificado
	    begin
            insert into cd_consec_x_agencia_anuladas
                  (COD_EMPRESA,    
	               COD_AGENCIA,    
	               COD_MONEDA,     
	               NUM_SECUENCIA,
	               DESCRIPCION,    
	               ANULADO_POR,    
	               FEC_ANULACION)
            values(Pc_Empresa ,
                   Pc_Agencia,
                   Pc_Moneda,
                   Num_Cd,
                   'Anulación de certifcado',
                   user,
                   sysdate);
	    exception
	    when others then  
			Pc_Mensaje:= PA.OBT_MENSAJE('000359',
                                        Pc_Idioma,
                                        'CD');
	  	end;

		if c.num_certificado is not null then	
		  cd_p_inserta_movimiento (Pc_Empresa, 
		                         c.num_certificado, 
		                         'CD',
		                         9, 
		                         1, 
		                         null, 
		                         'Anulación de Certificado', 
		                         Pd_Fecha,
		                         null, 
                                 Pc_Idioma,
                                 Pc_Mensaje) ;
		end if;
	end loop; -- API
END;
PROCEDURE Cd_P_Inserta_Movimiento (P_cod_empresa 		in 	Varchar2,
	         				       P_num_certificado	in 	Varchar2,
	                			   P_cod_sistema		in 	Varchar2,
 	                      		   P_Tip_Transaccion	in 	Number,
	                         	   P_Subtip_transaccion	in 	Varchar2,
 	                         	   P_Numero_cupon		in 	Number  ,  -- Número del cupon para el movimiento 
				                   P_Detalle_actual		in 	Varchar2,
	    			               P_Fecha_movimiento	in 	Date,
            		               P_Detalle_anterior	in 	Varchar2,
                                   P_Idioma				in Varchar2,
                                   P_Mensaje			out Varchar2) IS
   v_descripcion	  	 subtip_transac.descripcion%type;
   siguiente_movimiento_v	 cd_movimiento.consecutivo%type;
BEGIN
  --  Descripcion: Este procedimiento se encarga de insertar un movimiento 
  --  en la tabla de CD_MOVIMIENTO de acuerdo a los parametros indicados.
  --  Historia:  Adrián Zúñiga Morales  13-feb-1998  Creación

  -- Obtiene la descripcion del tipo de movimiento 
  begin
    select   descripcion
    into     v_descripcion
    from     subtip_transac
    where    cod_empresa = p_cod_empresa
    and      tip_transaccion = p_tip_transaccion
    and      subtip_transac  = p_subtip_transaccion
    and      cod_sistema = 'CD';
  exception
     when others then
        P_Mensaje := PA.OBT_MENSAJE('000104',
                                    P_Idioma,
                                    'CD');
  end;

  -- Obtiene el próximo número de movimiento de acuerdo a la secuencia
  begin
     SELECT seq_movimientos.nextval
       into siguiente_movimiento_v	
       from dual;
   exception
      when no_data_found then
        P_Mensaje := PA.OBT_MENSAJE('000102',
                                    P_Idioma,
                                    'CD');
  end;
  begin
    Insert into Cd_movimiento (
	  			cod_empresa, 
          		num_certificado,
  	  			consecutivo,  
          		cod_sistema,
   	  			Tip_Transaccion, 
          		Subtip_transac,
	  			Numero_cupon, 
         	 	Descripcion,
	  			Detalle_actual, 
          		Fecha_movimiento,
	  			Detalle_anterior,	
          		Adicionado_por,
	  			Fecha_Adicion )
    Values		(P_cod_empresa ,
 	   			 P_num_certificado,
	   			 siguiente_movimiento_v  ,
	   			 P_cod_sistema,
	   			 P_Tip_Transaccion ,
	   			 P_Subtip_transaccion,
	   			 P_Numero_cupon,
	   			 v_Descripcion,
           		 P_Detalle_actual,
	   			 P_fecha_movimiento,
	   			 P_Detalle_anterior,
	   			 USER,
	   			 sysdate);
  exception
      when others then
        P_Mensaje:= PA.OBT_MENSAJE('000103',
                                    P_Idioma,
                                    'CD')||sqlerrm;
  end ;
END;

END Cd_Pkg_Reversiones;
/