CREATE OR REPLACE PACKAGE BODY CD.pkg_cd_inter is
    procedure retiro_interes(pcompania       in varchar2,
                             pagencia        in varchar2,
                             pCertificado    in varchar2,
                             ptransaccion    in varchar2,
                             psubtiptransac  in varchar2,
                             pFechacal       in date,
                             pasiento        in varchar2,
                             pmontoInteres   in number,
                             pnumtransaccion in out varchar2,
                             vmensajeerror   in out varchar2) Is 
        vNumeroTrans     VARCHAR2(25):='';
        nmontocd         cd.cd_certificado.monto_original%type;
        nmontoIntCap     cd.cd_certificado.mon_acum_int_cap%type;
        nTasaBruta       cd.cd_certificado.tas_bruta%type;
        nTasaNeta        cd.cd_certificado.tas_neta%type;
        nMontoIntBruto   cd.cd_certificado.mon_acum_int_cal%type;
        dfechavence      cd.cd_certificado.fec_vencimiento%type;
    Begin
      
        if pnumtransaccion is null then
              Begin
                   pnumtransaccion:=ps.pk_creditouni.codigo_secuencia(pempresa     =>pcompania,
                                                                      psistema     =>'CD',
                                                                      ptabla       =>'CD_RETIRO_INTERESES',
                                                                      pcampo       =>'NUMERO_TRANSACCION',
                                                                      pproceso     =>'RG');
              end;
              
              if pnumtransaccion is not null then
                  begin
                      update ps.modelodatos
                      set secuencia=nvl(secuencia,0)+1
                      where cod_empresa   =   pcompania               and
                            cod_sistema   =   'CD'                    and
                            nombre_tabla  =   'CD_RETIRO_INTERESES'   and
                            nombre_campo  =   'NUMERO_TRANSACCION'    and
                            proceso       =   'RG'                    and
                            estado        =   'ACT';
                  end;
                  commit;
              end if;
          
        end if;
        
        begin
            select monto_original,mon_acum_int_cap,tas_bruta,tas_neta,mon_acum_int_cal,fec_vencimiento
              into nmontocd,nmontoIntCap,nTasaBruta,nTasaNeta,nMontoIntBruto,dfechavence
              from cd.cd_certificado
             where cod_empresa       = pcompania     and
                   num_certificado   = pcertificado  and
                   Estado in ('A','R');
        exception
            when no_data_found then
                vmensajeerror:='CD00001 - Datos del Certificado no Encontrado.';
            when others then
                vmensajeerror:='CD00001 - Datos del Certificado no Encontrado.';
        end;
        
        If vmensajeerror Is Null Then
          Begin
              Insert Into cd.cd_retiro_intereses
                 ( CODIGO_EMPRESA, CODIGO_AGENCIA, NUMERO_TRANSACCION, TIP_TRANSACCION,
                   SUBTIP_TRANSACC, NUM_CERTIFICADO, FECHA_RETIRO, MONTO_CD, INTERES_ACUMULADO,
                   INTERES_RETIRADO, TASA_BRUTA, TASA_NETA, ADICIONADO_POR, FECHA_ADICION,
                   MONTO_INTERES_BRUTO, ESTADO,  NUMERO_ASIENTO, FECHA_VENCIMIENTO)
               Values
                 (pcompania,pagencia,pnumtransaccion,ptransaccion,psubtiptransac,pCertificado,
                  pfechacal,nmontocd,nmontoIntCap,pmontoInteres,nTasaBruta,nTasaNeta,
                  User,sysdate,nMontoIntBruto,'A',pasiento,dfechavence);
          End;
          commit;
        End IF;
    End;
                    
    Function Obtiene_CDTasActual(pcodempresa    in Varchar2, 
                                 pcodproducto   in Varchar2,
                                 pplazo         in Number,
                                 pmonto         in Number,
                                 pcodtasa       In Out Varchar,
                                 pspread        in out number,
                                 poperacion     in out varchar2,
                                 pvalortasa        out number) 
        Return number is
      bExiste   boolean:=true;
    Begin
       Begin
           select a.cod_tasa,
                    a.tasa_maxima,
                    a.spread,
                    a.operacion
               into pcodtasa,
                    pvalortasa,
                    pspread,
                    poperacion
               from cd_prd_tasa_plazo_monto a
              where a.cod_empresa = pcodempresa
                and a.cod_producto = pcodproducto
                and a.estado = 'A'
                and pmonto between a.monto_minimo and a.monto_maximo
                and nvl (pplazo, 0) between a.plazo_minimo and a.plazo_maximo
                and a.codigo in (select max (b.codigo)
                                    from cd_prd_tasa_plazo_monto b
                                   where b.cod_empresa = pcodempresa
                                     and b.cod_producto = pcodproducto
                                     and b.estado = 'A'
                                     and pmonto between b.monto_minimo and b.monto_maximo
                                     and nvl (pplazo, 0) between b.plazo_minimo and b.plazo_maximo);
       exception
           when no_data_found then
               bExiste:=false;                                              
       End;
       
       if bExiste then
         Return (1);
       else
         Return(0);
       end if;
    End;
    FUNCTION CD_TASINTERES_BASE(p_empresa IN VARCHAR2, 
                                p_tasa    IN VARCHAR2, 
                                p_fecha   IN DATE, 
                                p_error   IN OUT varchar2, 
                                p_sqlcode IN OUT varchar2 )  RETURN NUMBER IS

      /* FUNCTION CD_TASA_INTERES
      ** Hecho por: Alex Salas M.
      ** Fecha: 12-01-1998
      ** Modificada por : Alex Salas
      ** Fecha modificada: 27-02-1998
      ** Proposito: Regresa Tasa de interes vigente a la fecha especificada, de la empresa 
      ** y codigo de tasa dado
      ** Argumentos: Codigo de empresa, codigo de tasa, fecha */

      v_tasa NUMBER(10, 6) :=0;
    BEGIN
        BEGIN
           SELECT val_tasa
             INTO v_tasa
             FROM pa.valores_tasas_interes
            WHERE cod_empresa = p_empresa
              AND cod_tasa = p_tasa
              AND TRUNC(fec_inicio) IN (SELECT MAX(TRUNC(fec_inicio))
                                          FROM valores_tasas_interes
                                         WHERE cod_empresa = p_empresa
                                           AND cod_tasa = p_tasa
                                           AND fec_inicio <= p_fecha);
        EXCEPTION
           WHEN NO_DATA_FOUND THEN  
              P_Error := '000038' ;
              P_SQLCODE := sqlcode ;
              V_TASA:=NULL;
           WHEN OTHERS THEN 
              P_Error := '000523';
              P_SQLCODE := sqlcode ;
              V_TASA:=NULL;
        END;
        RETURN(v_tasa);
    END;
    
    procedure cd_calcula_tasa_neta (
       p_tasa_bruta   in out   number,
       p_spread       in       number default 0,
       p_renta        in       number default 0,
       p_tasa_neta    in out   number,
       p_operacion    in       varchar2, -- +/- suma o resta
       p_error           out   varchar2) is
       /*
       ** Proposito: Retorna la tasa neta
       ** Argumentos: tasa neta, spread, renta, tasa bruta, operacion
       */
       v_tasa_bruta   number (8, 5) := 0;
       v_factor       number (8, 5) := 1 - (nvl (p_renta, 0) / 100);
       m_error        varchar2 (10);
       v_calculado    number;
    begin
       if p_tasa_bruta <= 0 then          
          utilitarios.obt_mensaje_error ('000090', 'CD', p_error);
          raise_application_error(-20100, p_error);
       elsif p_operacion = '+' then
          p_tasa_bruta := nvl (p_tasa_bruta, 0) + nvl (p_spread, 0);
          p_tasa_neta := p_tasa_bruta;
       elsif p_operacion = '-' then
          p_tasa_bruta := nvl (p_tasa_bruta, 0) - nvl (p_spread, 0);
          p_tasa_neta := p_tasa_bruta;
       end if;
       --
       if p_tasa_bruta > 0  then
          v_calculado := p_tasa_neta / 10;
          v_calculado := nvl (p_tasa_bruta, 0) - v_calculado;
          p_tasa_neta := v_calculado;
       end if;
    end;
    
end;
/