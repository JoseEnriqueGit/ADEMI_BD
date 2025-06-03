PROCEDURE Agregar_Dias  (p_f_base          in date, 
                         p_dias            in number, 
                         p_tipo_calendario in number,
                         p_f_resultado     in out date, 
                         p_msj_error       in out varchar2 ) 
IS
  -- Agrega dias a una fecha segun calendario financiero o natural
  -- EFECTUA
  --  Agrega dias a una fecha segun calendario financiero o natural.
  --  El P_Tipo_Calendario debe ser 360 o 365 para indicar que se trata de calend. financiero o 
  -- natural respectivamente.
  -- OBSERVACIONES
  --  Se base en un algoritmo de KIKE para el modulo BDF. GVIQ, 23-MAR-1996, >>>> FPR_PLAN
  -- HISTORIA
  -- GVIQ, 23-MAR-1996
  --  Se hacen varias modificaciones para restar dias y corregir un
  --  problema con el funcionamiento con add_months.
  --
  -- ESOLANO 17.12.1998
  -- Se corrigen aspectos de estetica como identación...
  -- Se incluyo la parte de mensajeria...
  -- Se prueba la rutina y el resultado es el siguiente :
  -- En el caso del calendario de 360 dias se contempla el mes de febrero como un mes de 30 dias
  -- al igual que los otros meses, por lo que la rutina puede ser util para efectos de calculo de
  -- dias para determinar los dias de intereses. El caso de 365 dias funciona normalmente ...

   v_f_resultado     date;
   v_meses           number;
   v_dias            number;
   v_dia_resultado   number;
   v_mes_resultado   number;
   v_anio_resultado  number;
   v_ult_dia         number;
   p_idioma          varchar2(5) ;
   p_sistema         varchar2(3);

begin
   if (p_tipo_calendario = 365) then              -- calendario natural  
      v_f_resultado := p_f_base + p_dias;
   elsif (p_tipo_calendario = 360) then           -- calendario financiero
      if (mod(p_dias, 30) = 0) then               
         v_f_resultado := add_months(p_f_base, p_dias / 30);
         if (p_f_base = last_day(p_f_base) and v_f_resultado = last_day(v_f_resultado) and
            (to_number(to_char(v_f_resultado,'DD')) > to_number(to_char(p_f_base,'DD')))) then   
            v_f_resultado := to_date(to_char(p_f_base,'DD') || 
                                     to_char(v_f_resultado,'MMYYYY'),'DDMMYYYY');
         end if;
      else
         if (p_dias >= 0) then
            v_meses := trunc(p_dias / 30);
            v_dias := mod(p_dias, 30);
            v_f_resultado := add_months(p_f_base, v_meses);
            if (p_f_base = last_day(p_f_base) and v_f_resultado = last_day(v_f_resultado) and
               (to_number(to_char(v_f_resultado,'DD')) > to_number(to_char(p_f_base,'DD')))) then
               v_f_resultado := to_date(to_char(p_f_base,'DD') || 
                                        to_char(v_f_resultado,'MMYYYY'), 'DDMMYYYY');
            end if;
            if (v_f_resultado = last_day(v_f_resultado)) then
               v_f_resultado := v_f_resultado + v_dias;
            else
               -- desarma la fecha en sus partes
               v_dia_resultado  := to_number(to_char(v_f_resultado,'DD'));
               v_mes_resultado  := to_number(to_char(v_f_resultado,'MM'));
               v_anio_resultado := to_number(to_char(v_f_resultado,'YYYY'));
               v_ult_dia := 30;

               -- agrega los dias que han quedado y analiza el cambio de mes y de anio
               v_dia_resultado := v_dia_resultado + v_dias;

               if (v_dia_resultado > v_ult_dia) then
                  v_dia_resultado := v_dia_resultado - v_ult_dia;
                  v_mes_resultado := v_mes_resultado + 1;
               elsif (v_mes_resultado = 2) then
                  v_ult_dia := to_number(to_char(last_day(v_f_resultado),'DD'));
                  if (v_dia_resultado > v_ult_dia) then
                     v_dia_resultado := v_ult_dia;
                  end if;
               end if;

               if (v_mes_resultado > 12) then
                  v_mes_resultado := v_mes_resultado - 12;
                  v_anio_resultado := v_anio_resultado + 1;
               end if;

               -- arma la fecha de nuevo
               v_f_resultado := to_date(to_char(v_dia_resultado, '00') || 
                                        to_char(v_mes_resultado, '00') ||
                                        to_char(v_anio_resultado, '0000'), 'DDMMYYYY');
            end if;
         else         -- p_dias < 0
            v_meses := -1 * trunc(abs(p_dias) / 30);
            v_dias := mod(abs(p_dias), 30);
            v_f_resultado := add_months(p_f_base, v_meses);

            if (p_f_base = last_day(p_f_base) and v_f_resultado = last_day(v_f_resultado) and
                (to_number(to_char(v_f_resultado,'DD')) > to_number(to_char(p_f_base,'DD')))) then
               v_f_resultado := to_date(to_char(p_f_base,'DD') || 
                                        to_char(v_f_resultado,'MMYYYY'), 'DDMMYYYY');
            end if;

            v_mes_resultado := to_number(to_char(v_f_resultado,'MM'));
            if (to_char(p_f_base, 'DD') = '31' and v_dias = 1) then
               null;
            else
               v_f_resultado := v_f_resultado - v_dias;
            end if;
            if (abs(p_dias) < 30) then
               if (to_char(p_f_base,'DD') = '31') then
                  v_f_resultado := v_f_resultado - 1;
               elsif (to_char(p_f_base,'MM') = '02' and
                      to_char(p_f_base,'DD') = '28') then
                      v_f_resultado := v_f_resultado + 2;
               elsif (to_char(p_f_base,'MM') = '02' and
                      to_char(p_f_base,'DD') = '29') then
                      v_f_resultado := v_f_resultado + 1;
               end if;
            end if;
            if (to_number(to_char(v_f_resultado,'DD')) = '31') then
                v_f_resultado := v_f_resultado - 1;
            end if;
         end if; -- restar o sumar
      end if; -- periodicidad multiplo de 30
   else
      p_msj_error := 'AgrDias.ERR: Calendario de ' ||
       to_char(p_tipo_calendario) || ' dias no es valido.';
      return;
   end if;

   -- Asigna variables de salida
   p_f_resultado := v_f_resultado;

exception
   when others then
      p_idioma  := Name_In ('variables.codidioma');
      p_sistema := Name_In ('variables.codsistema');
      utilitarios.mensaje('000508',p_idioma,'CD');
      raise form_trigger_failure;
End; -- Agregar_Dias  

Procedure cd_calcula_dias (f_inicio         in date,
                           f_final          in date,
                           base_plazo       in number,
                           p_frecuencia     in out varchar2, 
                           p_dias_resultado in out number) is
   --
   plazo        number;
   f_aux        date;
   vFec1	number(10);
   vFec2	number(10);
   --
begin
   --
   if base_plazo = 365
   then
     p_dias_resultado := f_final - f_inicio;
   else
     --
     vFec1    := to_number(to_char(f_inicio,'YYYY')) * 360 +
                (to_number(to_char(f_inicio,'MM')) - 1) * 30 +
                 to_number(to_char(f_inicio,'DD'));
     --
     if TO_CHAR(f_inicio,'DD') = '31' and to_char(last_day(f_inicio),'dd') = '31'
     then
       vFec1 := vFec1 - 1;
     end if;
     --
     if to_char(f_inicio,'MM') = 2 and to_char(f_inicio,'DD') = '28' and to_char(last_day(f_inicio),'dd') = '28'
     then
       vFec1 := vFec1 + 2;
     end if;
     --
     if to_char(f_inicio,'MM') = 2 and to_char(f_inicio,'DD') = '29' and to_char(last_day(f_inicio),'dd') = '29'
     then
       vFec1 := vFec1 + 1;
     end if;
     --
     vFec2    := to_number(to_char(f_final,'YYYY')) * 360 +
                (to_number(to_char(f_final,'MM')) - 1) * 30 +
                 to_number(to_char(f_final,'DD'));
     --
     if to_char(f_final,'DD') = '31' and to_char(last_day(f_final),'dd') = '31'
     then
       vFec2 := vFec2 - 1;
     end if;
     --
     if to_char(f_final,'MM') = 2 and to_char(f_final,'DD') = '28' and to_char(last_day(f_final),'dd') = '28'
     then
       vFec2 := vFec2 + 2;
     end if;
     --
     if to_char(f_final,'MM') = 2 and to_char(f_final,'DD') = '29' and to_char(last_day(f_final),'dd') = '29'
     then
       vFec2 := vFec2 + 1;
     end if;
     --
     p_dias_resultado := vFec2 - vFec1;
     --
   end if;
   --
exception when others then
   message('cd_calcula_dias '|| sqlerrm);
   message(' ');
   return;
end;

FUNCTION CD_CALCULA_INTERES(
  fecha1_p		in date,  	-- fecha inicio de calculo de intereses
  fecha2_p		in date,    	-- fecha final de calculo
  monto_p		in number,  	-- monto certificado
  tasa_p		in number,   	-- tasa interes
  base_calculo_p	in number,  	-- 360/365 para calculo de interes
  base_plazo_p		in number 	-- 360/365 para calculo de dias
) RETURN number IS

-- Este procedimiento sirve para calcular los intereses de un monto de acuerdo 
-- a la base de cálculo obtenida de productos x agencia o x emresa, la tasa, 
-- entre dos fechas
-- Historia	26-feb-1998	Adrián Zúñiga Morales	Creación
 
   dias_v        number;       -- dias entre las dos fechas
   total_ints_v  number;	      -- total_ints calculados
   frecuencia_v  VARCHAR2(1); 
BEGIN

   -- Calcula el número de días entre las fechas utilizando el calendario base de plazo ...
   cd_calcula_dias(fecha1_p, fecha2_p, base_plazo_p, frecuencia_v, dias_v); 

   -- Calcula el monto de intereses correspondiente utilizando el calendario base de calculo...
   total_ints_v := cd_cal_interes(monto_p, tasa_p, base_calculo_p, dias_v);
   return(total_ints_v);
END;

FUNCTION CD_CAL_INTERES(p_monto        IN NUMBER DEFAULT 0,
                        p_tasa         IN NUMBER DEFAULT 0,
                        p_dias_base    IN NUMBER DEFAULT 360,
                        p_dias_interes IN NUMBER DEFAULT 0)
                        RETURN NUMBER IS

/* FUNCTION CD_CAL_INTERES
** Hecho por: Alex Salas M. 
** Fecha: 17-02-1998
** Proposito: Retorna monto de interes
** Argumentos: Monto, tasa, dias_base, dias_interes
*/

   v_monto_interes cd_certificado.monto%TYPE :=0;
BEGIN
   v_monto_interes := (round(((p_monto*(p_tasa/100)) /p_dias_base),7)*p_dias_interes);
   RETURN(v_monto_interes);
END;

PROCEDURE CD_CAL_TASA_NETA( p_tasa_neta    IN  OUT NUMBER ,
                            p_spread       IN  NUMBER DEFAULT 0,
                            p_renta        IN  NUMBER DEFAULT 0, 
                            p_tasa_bruta   IN  OUT NUMBER, 
                            p_Codigo_Error OUT VARCHAR2, 
                            p_Sistema      OUT VARCHAR2, 
                            p_SQLCode      OUT VARCHAR2 ) IS


/* PROCEDURE CD_CAL_TASA_NETA 
** Hecho por: Alex Salas M.
** Fecha: 17-02-1998
** Proposito: Retorna la tasa neta
** Argumentos: tasa neta, spread, renta, tasa bruta
** ESOLANO 17-12-1998 Modificacion para que devuelva la situacion de error mediante parametros
**                    Se elimina el uso de la instr. Raise_Application_Error ...
*/

   v_tasa_bruta NUMBER(8, 5) :=0;
   v_factor NUMBER(8, 5) :=(1-(p_renta/100)); 
   M_Error VARCHAR2(10);
BEGIN
   IF p_tasa_neta <= 0 
  -- 	OR p_spread < 0
   THEN
      p_Codigo_Error := '000090';   -- La tasa y el spread deben ser mayor a cero 
      p_Sistema      := 'CD' ;
      p_SQLCode      := NULL ;
   ELSE
      p_tasa_bruta :=(NVL(p_tasa_bruta, 0) + NVL(p_spread, 0)) ;
      p_tasa_neta  :=NVL(p_tasa_bruta, 0) * v_factor;    
   END IF;
END;

function cd_CONSECUTIVO_INGRESOS (Consecutivo out number,
                                  p_sql_code  out varchar2,
                                  p_cod_error out varchar2)
                                  RETURN boolean IS
  -- EFECTUA: Obtiene el siguiente numero para los comprobantes de
  --          ingreso de cajas.
  -- ESCritO: Por Bernal Blanco
BEGIN
  Select BCJ_Solic_Ingreso.NextVaL
    into   Consecutivo
    From   dual;
  return true;

RETURN NULL; Exception
  When Others Then
    p_sql_code  := sqlcode ; 
    p_cod_error := '000209';  /* Tiene problemas con el procedimiento de consecutivo de ingresos.*/ 
    return null;
END;

function cd_CONSECUTIVO_INGRESOS (Consecutivo out number,
                                  p_sql_code  out varchar2,
                                  p_cod_error out varchar2)
                                  RETURN boolean IS
  -- EFECTUA: Obtiene el siguiente numero para los comprobantes de
  --          ingreso de cajas.
  -- ESCritO: Por Bernal Blanco
BEGIN
  Select BCJ_Solic_Ingreso.NextVaL
    into   Consecutivo
    From   dual;
  return true;

RETURN NULL; Exception
  When Others Then
    p_sql_code  := sqlcode ; 
    p_cod_error := '000209';  /* Tiene problemas con el procedimiento de consecutivo de ingresos.*/ 
    return null;
END;

function cd_CONSECUTIVO_INGRESOS (Consecutivo out number,
                                  p_sql_code  out varchar2,
                                  p_cod_error out varchar2)
                                  RETURN boolean IS
  -- EFECTUA: Obtiene el siguiente numero para los comprobantes de
  --          ingreso de cajas.
  -- ESCritO: Por Bernal Blanco
BEGIN
  Select BCJ_Solic_Ingreso.NextVaL
    into   Consecutivo
    From   dual;
  return true;

RETURN NULL; Exception
  When Others Then
    p_sql_code  := sqlcode ; 
    p_cod_error := '000209';  /* Tiene problemas con el procedimiento de consecutivo de ingresos.*/ 
    return null;
END;

PROCEDURE CD_FECHA_EXACTA(p_fecha_inicial       IN DATE ,
                          p_calendario_base     IN number ,
                          p_valor               IN NUMBER , 
                          p_frecuencia          IN OUT VARCHAR2 ,
                          p_fecha_final         IN OUT DATE ,
                          p_total_dias          IN OUT number )
IS
BEGIN
  /* PROCEDURE CD_FECHA_EXACTA
  ** Hecho por: Adrian Zuñiga Morales
  ** Fecha: 10-06-1998
  ** Proposito : Regresar la cantidad de dias y la fecha exaxtos
  ** Observacion: Este procedimiento aplica solo cuando la frecuencia
  ** del calculo es mensual, lo que se requiere es saber
  ** los dias exactos.
  ** Argumentos: fecha inicio, dias,
  **
  */
  DECLARE
     M_Error VARCHAR2(10);
     v_valor NUMBER := 0;
  BEGIN
    --
    -- Revisa las posibles inconsistencias
    --
    IF p_valor <= 0 THEN
       M_Error := '000034'; 
    END IF;

    IF p_frecuencia NOT IN('D', 'M') THEN
       M_Error := '000033';
    END IF;

    IF p_calendario_base NOT IN(360, 365) THEN
       M_Error := '000032';
    END IF;
    --
    -- Calculo de dias exactos y la fecha exacta
    --
    IF(p_frecuencia = 'M'AND p_calendario_base = 365) THEN
       p_fecha_final := ADD_MONTHS(p_fecha_inicial, p_valor);
       p_total_dias := p_valor;
    ELSIF (p_frecuencia = 'D'AND p_calendario_base = 365) THEN
       p_fecha_final :=(p_fecha_inicial + p_valor);
       CD_CALCULA_DIAS(p_fecha_inicial,
                       p_fecha_final,
                       p_calendario_base,
                       p_frecuencia,
                       p_total_dias);
    ELSIF (p_frecuencia = 'D'AND p_calendario_base = 360) THEN
          p_fecha_final :=
          CD_FECHA_FINANCIERA(p_fecha_inicial,
                              p_calendario_base,
                              p_valor);
          p_total_dias := p_valor;
    ELSIF (p_frecuencia = 'M'AND p_calendario_base = 360) THEN
          --calcula el  numero de dias  a sumar a la fecha base, como es 360
          --y la frecuencia es Meses, estos son de 30 dias por lo que
          --los dias corresponden a multiplicar el p_valor * 30
          p_fecha_final :=CD_FECHA_FINANCIERA(p_fecha_inicial,
                                              p_calendario_base,
                                              p_valor*30);
          p_total_dias := p_valor;
    END IF;
  EXCEPTION
     WHEN OTHERS THEN 
       utilitarios.mensaje(M_Error,name_in('variables.codidioma'),'CD');
       raise form_trigger_failure;
  END;
END CD_FECHA_EXACTA;

PROCEDURE CD_FECHA_EXACTA(p_fecha_inicial       IN DATE ,
                          p_calendario_base     IN number ,
                          p_valor               IN NUMBER , 
                          p_frecuencia          IN OUT VARCHAR2 ,
                          p_fecha_final         IN OUT DATE ,
                          p_total_dias          IN OUT number )
IS
BEGIN
  /* PROCEDURE CD_FECHA_EXACTA
  ** Hecho por: Adrian Zuñiga Morales
  ** Fecha: 10-06-1998
  ** Proposito : Regresar la cantidad de dias y la fecha exaxtos
  ** Observacion: Este procedimiento aplica solo cuando la frecuencia
  ** del calculo es mensual, lo que se requiere es saber
  ** los dias exactos.
  ** Argumentos: fecha inicio, dias,
  **
  */
  DECLARE
     M_Error VARCHAR2(10);
     v_valor NUMBER := 0;
  BEGIN
    --
    -- Revisa las posibles inconsistencias
    --
    IF p_valor <= 0 THEN
       M_Error := '000034'; 
    END IF;

    IF p_frecuencia NOT IN('D', 'M') THEN
       M_Error := '000033';
    END IF;

    IF p_calendario_base NOT IN(360, 365) THEN
       M_Error := '000032';
    END IF;
    --
    -- Calculo de dias exactos y la fecha exacta
    --
    IF(p_frecuencia = 'M'AND p_calendario_base = 365) THEN
       p_fecha_final := ADD_MONTHS(p_fecha_inicial, p_valor);
       p_total_dias := p_valor;
    ELSIF (p_frecuencia = 'D'AND p_calendario_base = 365) THEN
       p_fecha_final :=(p_fecha_inicial + p_valor);
       CD_CALCULA_DIAS(p_fecha_inicial,
                       p_fecha_final,
                       p_calendario_base,
                       p_frecuencia,
                       p_total_dias);
    ELSIF (p_frecuencia = 'D'AND p_calendario_base = 360) THEN
          p_fecha_final :=
          CD_FECHA_FINANCIERA(p_fecha_inicial,
                              p_calendario_base,
                              p_valor);
          p_total_dias := p_valor;
    ELSIF (p_frecuencia = 'M'AND p_calendario_base = 360) THEN
          --calcula el  numero de dias  a sumar a la fecha base, como es 360
          --y la frecuencia es Meses, estos son de 30 dias por lo que
          --los dias corresponden a multiplicar el p_valor * 30
          p_fecha_final :=CD_FECHA_FINANCIERA(p_fecha_inicial,
                                              p_calendario_base,
                                              p_valor*30);
          p_total_dias := p_valor;
    END IF;
  EXCEPTION
     WHEN OTHERS THEN 
       utilitarios.mensaje(M_Error,name_in('variables.codidioma'),'CD');
       raise form_trigger_failure;
  END;
END CD_FECHA_EXACTA;

Function CD_Genera_Solicitud_Cajas(p_codigo_empresa   in number,
                             p_codigo_agencia         in number,
                             numero_comprobante       in number,
                             indicador_comprobante    in varchar2, --I: Ingresos, E: Egresos
                             codigo_moneda            in number,
                             p_codigo_cliente         in number,
                             monto                    in number,
                             fecha_comprobante        date     ,  
                             numero_asiento           in number,
                             desc_trans               in varchar2,
                             Po_err_cd                Out Varchar2, --Error de certificados
                             Po_sql_code              Out Varchar2  --Error de oracle
) return boolean
  /*
  Proposito : Genera la solicitud de ingreso o egreso a cajas
  Historia  : JRM, Creacion : 11/9/98
  */
is

  Observa2      Varchar2(100);
  Desc1         Varchar2(100);
  v_cod_cliente number(7); --Codigo de cliente
--
Begin
  --Se obtiene el codigo_cliente equivalente al cod_cliente, pues
  --la tabla de cajas referencia a este campo.
  /*
   begin
      select unique codigo_cliente
        into v_cod_cliente
        from clientes
       where codigo_empresa = p_codigo_empresa and
             codigo_agencia = p_codigo_agencia and
             cod_cliente = p_codigo_cliente;
      EXCEPTION
       WHEN OTHERS THEN
         Po_sql_code  := sqlcode;
         Po_err_cd    := '000129';
         return false;
    end;
*/
  
  --Inserta la solicitud en cajas
  begin
     Desc1    := desc_trans;
     Observa2 := null;

     Insert into bcj_solicitud(CODIGO_EMPRESA,
                               CODIGO_AGENCIA,
                               CODIGO_APLICACION,
                               NUMERO_COMPROBANTE,
                               INDICADOR_COMPROBANTE,
                               CODIGO_MONEDA,
                               CODIGO_CLIENTE,
                               ESTADO_COMPROBANTE,
                               MONTO_COMPROBANTE,
                               MONTO_TIPOCAMBIO1,
                               MONTO_TIPOCAMBIO2,
                               FECHA_COMPROBANTE,
                               OBSERVACIONES1,
                               OBSERVACIONES2,
                               ADICIONADO_POR,
                               APROBADO_POR,
                               FECHA_ADICION,
                               FECHA_APROBACION,
                               NUMERO_ASIENTO_CONTABLE,
                               Cod_Comprobante,
                               Observaciones4)
                      values ( p_codigo_empresa, 
                               P_codigo_agencia,
                               'BCD',
                               numero_comprobante, 
                               indicador_comprobante,
                               codigo_moneda, 
                               p_codigo_cliente,
                               'B',
                               monto,
                               1,
                               1,
                               fecha_comprobante,
                               Desc1,
                               Observa2,
                               user,
                               user, 
                               SYSDATE,
                               fecha_comprobante,
                               numero_asiento,
                               '18',
                               p_codigo_agencia);
     EXCEPTION
       WHEN OTHERS THEN
          Po_sql_code  := sqlcode;
          Po_err_cd    := '000210';
          return false;
  end;

  return true; --No hubo error
End;

FUNCTION CD_ING_DET_NOTA_DEBITO(pCodEmpresa     in Varchar2, -- Empresa
                                pNotaDebito     in Number,   -- Nota debito
                                pCertificado    in Varchar2, -- Certificado
                                pPrincipal      in Number,   -- Principal del certificado
                                pIntGanados     in Number,   -- Intereses por pagar
                                pIntReconocidos in Number,   -- Intereses reconocidos
                                pError          out Varchar2, -- Codigo de error
                                pSqlError       out Varchar2) -- Codigo de error de sql
RETURN BOOLEAN IS
   /*
     EFECTUA : Ingresa una linea en el detalle de nota de debito
     HISTORIA: JRM (Creacion) :  11/08/1998
   */
BEGIN
  insert into cd_det_nota_debito
    (cod_empresa,
     consecutivo,
     num_certificado,
     mon_principal,
     mon_int_x_pagar,
     mon_int_reconocidos
     )
  values 
    (pCodEmpresa, 
     pNotaDebito, 
     pCertificado, 
     pPrincipal, 
     pIntGanados,
     pIntReconocidos);

  return true;

 RETURN NULL; EXCEPTION
    when others then
      pError := '000463';
      pSqlError := SQLCODE;
      return false;
END;

PROCEDURE CD_INS_DET_ING_CAJA(pNumSolic       in number,   -- Numero de Solicitud
                              pCodEmpresa     in varchar2, -- Empresa
                              pNumCert        in varchar2, -- Numero de Cd
                              pOrd_Linea      IN NUMBER,   -- Numero de linea del detalle
                              pTip_Linea      IN VARCHAR2, -- Tipo de linea
                              pTip_Operacion  IN VARCHAR2, -- Tipo de operacion
                              pNum_Cupon      IN NUMBER,   -- Numero de cupon
                              pNum_Doc        IN VARCHAR2, -- Numero de documento. Ej. Nota debito.
                              pMonto          IN NUMBER,   -- Monto de la linea
                              pError          out Varchar2, -- Codigo de error
                              pSqlError       out Varchar2) -- Codigo de error de sql
   IS
   /*
    EFECTUA : Realiza el registro del detalle del ingreso de cajas por concepto
              de un monto adicional en la renovacion de cds.
    REQUIERE: n/a
    HISTORIA: dsaborio : 24/07/1998 : creacion
              JRM :      11/08/1998 : modificacion para ajustarse a las necesidades de la
                                    forma de pago en cajas.
  */
BEGIN
  insert into cd_det_ing_caja
    (cod_empresa,
     num_solicitud,
     num_certificado,
     ord_linea,
     tip_linea,
     tip_operacion,
     num_cupon,
     num_documento,
     monto,
     adicionado_por,
     fec_adicion)
   values 
    (pCodEmpresa, 
     pNumSolic, 
     pNumCert, 
     pOrd_Linea, 
     pTip_Linea, 
     pTip_Operacion,
     pNum_Cupon,  
     pNum_Doc, 
     pMonto, 
     USER, 
     Sysdate);

  exception
    when dup_val_on_index then
      pError := '000429';
      pSqlError := SQLCODE;
    when others then
      pError := '000430';
      pSqlError := SQLCODE;
END;

PROCEDURE CD_INSERTA_MOVIMIENTO (P_cod_empresa 		in Varchar2,
	         				               P_num_certificado	in Varchar2,
	                			         P_cod_sistema		in Varchar2,
 	                      			   P_Tip_Transaccion	in Number,
	                         			 P_Subtip_transaccion	in Varchar2,
 	                         			 P_Numero_cupon		in Number  ,  -- Número del cupon para el movimiento 
				                         P_Detalle_actual	in Varchar2,
	    			                     P_Fecha_movimiento	in Date,
            		              	 P_Detalle_anterior	in Varchar2) IS

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
    and      cod_sistema = P_cod_sistema;
  exception
     when no_data_found then
       utilitarios.mensaje('000104', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
     when others then
       utilitarios.mensaje('000104', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
  end;

  -- Obtiene el próximo número de movimiento de acuerdo a la secuencia
  begin
     SELECT seq_movimientos.nextval
       into siguiente_movimiento_v	
       from dual;
   exception
      when no_data_found then
       utilitarios.mensaje('000102', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
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
    Values(P_cod_empresa ,
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
       utilitarios.mensaje('000103', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
  end ;
END;

PROCEDURE CD_INSERTA_MOVIMIENTO_CAP  (P_cod_empresa 				in Varchar2,
	         				               			P_num_certificado			in Varchar2,
	                			         			P_cod_sistema					in Varchar2,
 	                      			   			P_Tip_Transaccion			in Number,
	                         			 			P_Subtip_transaccion	in Varchar2,
 	                         			 			P_Numero_cupon				in Number  ,  -- Número del cupon para el movimiento 
				                         			P_Detalle_actual			in Varchar2,
	    			                     			P_Fecha_movimiento		in Date,
            		              	 			P_Detalle_anterior		in Varchar2,
            		              	 			p_valor_mvto 					in number default 0,
            		              	 			p_cod_producto 				in varchar2 default null,
																			p_cod_agencia 				in varchar2 default null,
																			p_tip_certificado 		in varchar2 default null,
																			p_cod_moneda 					in varchar2 default null,
																			p_estado 							in varchar2 default null,
																			p_monto 							in number default 0,
																			p_cre_interes 				in number default 0,
																			p_cre_mes 						in number default 0,
																			p_tas_bruta 					in number default 0,
																			p_tas_neta 						in number default 0,
																			p_mon_int_x_pagar 		in number default 0,
																			p_mon_acum_int_cap 		in number default 0,
																			p_mon_interes_pagado 	in number default 0,
																			p_mon_int_ganado 			in number default 0,
																			p_porcentaje_renta 		in number default 0,
																			p_base_calculo 				in number default 0,
																			p_mon_descuento 			in number default 0,
																			p_cod_tasa 			 			in varchar2 default null,
																			p_base_plazo    			in number default 0,
																			p_comentario     			in varchar2 default null,
																			p_numero_asiento 			in number) IS

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
    and      cod_sistema = P_cod_sistema;
  exception
     when no_data_found then
       utilitarios.mensaje('000104', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
     when others then
       utilitarios.mensaje('000104', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
  end;

  -- Obtiene el próximo número de movimiento de acuerdo a la secuencia
  begin
     SELECT seq_movimientos.nextval
       into siguiente_movimiento_v	
       from dual;
   exception
      when no_data_found then
       utilitarios.mensaje('000102', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
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
	  			Fecha_Adicion,
	  			valor_mvto,
	  			cod_producto,
					cod_agencia,
					tip_certificado,
					cod_moneda,
					estado,
					monto,
					cre_interes,
					cre_mes,
					tas_bruta,
					tas_neta,
					mon_int_x_pagar,
					mon_acum_int_cap,
					mon_interes_pagado,
					mon_int_ganado,
					porcentaje_renta,
					base_calculo,
					mon_descuento,
					cod_tasa,
					base_plazo,
					comentario,
					numero_asiento_pago )
    Values(P_cod_empresa ,
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
	   			 sysdate,
	   			  p_valor_mvto,
	   			 	p_cod_producto,
						p_cod_agencia,
						p_tip_certificado,
						p_cod_moneda,
						p_estado,
						p_monto,
						p_cre_interes,
						p_cre_mes,
						p_tas_bruta,
						p_tas_neta,
						p_mon_int_x_pagar,
						p_mon_acum_int_cap,
						p_mon_interes_pagado,
						p_mon_int_ganado,
						p_porcentaje_renta,
						p_base_calculo,
						p_mon_descuento,
						p_cod_tasa,
						p_base_plazo,
						p_comentario,
						p_numero_asiento);
  exception
      when others then
       utilitarios.mensaje('000103', Name_in('variables.codidioma'), Name_in('variables.codsistema'));
       raise form_trigger_failure ;
  end ;
END;

PROCEDURE CD_INS_HIST_RENOV(pTipoMov      in varchar2, -- Tipo de Renovacion (F/U)
                            pCodEmpresa   in varchar2, -- Empresa
                            pNumCdOrigen  in varchar2, -- Cd Original
                            pNumCdDestino in varchar2, -- Cd Nuevo
                            pError        in out varchar) -- mensaje de Error
   IS

--  Code modified by the Forms Migration Assistant
--  01-ago-2015 09:39 PM

   /*
    EFECTUA : Realiza la insercion de los datos referentes a la renovacion de cds
              en el historico correspondiente.
    REQUIERE: Tipo de Renovacion: [F]raccionamiento, [U]nificacion
    HISTORIA: dsaborio : 24/07/1998 : creacion
  */
BEGIN
  insert into cd_hist_frac_unif
                 (cod_tipo_mov, 
                  cod_empresa, 
                  num_cd_origen, 
                  num_cd_destino,
                  adicionado_por, 
                  fec_adicion)
          values (pTipoMov, 
                  pCodEmpresa, 
                  pNumCdOrigen, 
                  pNumCdDestino,
                  USER, 
                  TRUNC(Sysdate));
  exception
    when dup_val_on_index then
      pError := '000427';
    when others then
      pError := '000428';
END;

PROCEDURE CD_INS_HIST_RENOV(pTipoMov      in varchar2, -- Tipo de Renovacion (F/U)
                            pCodEmpresa   in varchar2, -- Empresa
                            pNumCdOrigen  in varchar2, -- Cd Original
                            pNumCdDestino in varchar2, -- Cd Nuevo
                            pError        in out varchar) -- mensaje de Error
   IS

--  Code modified by the Forms Migration Assistant
--  01-ago-2015 09:39 PM

   /*
    EFECTUA : Realiza la insercion de los datos referentes a la renovacion de cds
              en el historico correspondiente.
    REQUIERE: Tipo de Renovacion: [F]raccionamiento, [U]nificacion
    HISTORIA: dsaborio : 24/07/1998 : creacion
  */
BEGIN
  insert into cd_hist_frac_unif
                 (cod_tipo_mov, 
                  cod_empresa, 
                  num_cd_origen, 
                  num_cd_destino,
                  adicionado_por, 
                  fec_adicion)
          values (pTipoMov, 
                  pCodEmpresa, 
                  pNumCdOrigen, 
                  pNumCdDestino,
                  USER, 
                  TRUNC(Sysdate));
  exception
    when dup_val_on_index then
      pError := '000427';
    when others then
      pError := '000428';
END;

PROCEDURE CD_INS_HIST_RENOV(pTipoMov      in varchar2, -- Tipo de Renovacion (F/U)
                            pCodEmpresa   in varchar2, -- Empresa
                            pNumCdOrigen  in varchar2, -- Cd Original
                            pNumCdDestino in varchar2, -- Cd Nuevo
                            pError        in out varchar) -- mensaje de Error
   IS

--  Code modified by the Forms Migration Assistant
--  01-ago-2015 09:39 PM

   /*
    EFECTUA : Realiza la insercion de los datos referentes a la renovacion de cds
              en el historico correspondiente.
    REQUIERE: Tipo de Renovacion: [F]raccionamiento, [U]nificacion
    HISTORIA: dsaborio : 24/07/1998 : creacion
  */
BEGIN
  insert into cd_hist_frac_unif
                 (cod_tipo_mov, 
                  cod_empresa, 
                  num_cd_origen, 
                  num_cd_destino,
                  adicionado_por, 
                  fec_adicion)
          values (pTipoMov, 
                  pCodEmpresa, 
                  pNumCdOrigen, 
                  pNumCdDestino,
                  USER, 
                  TRUNC(Sysdate));
  exception
    when dup_val_on_index then
      pError := '000427';
    when others then
      pError := '000428';
END;

PROCEDURE CD_INS_HIST_RENOV(pTipoMov      in varchar2, -- Tipo de Renovacion (F/U)
                            pCodEmpresa   in varchar2, -- Empresa
                            pNumCdOrigen  in varchar2, -- Cd Original
                            pNumCdDestino in varchar2, -- Cd Nuevo
                            pError        in out varchar) -- mensaje de Error
   IS

--  Code modified by the Forms Migration Assistant
--  01-ago-2015 09:39 PM

   /*
    EFECTUA : Realiza la insercion de los datos referentes a la renovacion de cds
              en el historico correspondiente.
    REQUIERE: Tipo de Renovacion: [F]raccionamiento, [U]nificacion
    HISTORIA: dsaborio : 24/07/1998 : creacion
  */
BEGIN
  insert into cd_hist_frac_unif
                 (cod_tipo_mov, 
                  cod_empresa, 
                  num_cd_origen, 
                  num_cd_destino,
                  adicionado_por, 
                  fec_adicion)
          values (pTipoMov, 
                  pCodEmpresa, 
                  pNumCdOrigen, 
                  pNumCdDestino,
                  USER, 
                  TRUNC(Sysdate));
  exception
    when dup_val_on_index then
      pError := '000427';
    when others then
      pError := '000428';
END;

FUNCTION CD_NOM_AGENCIA(P_CODIGO IN NUMBER ) RETURN VARCHAR2 IS

/* FUNCTION CD_NOM_AGENCIA
** Hecho por: Alex Salas M.
** Fecha: 22-09-1997
** Proposito: Regresar el Nombre de la Agencia
** Argumentos: Codigo de Agencia*/

v_nombre_agencia VARCHAR2(80) := NULL;
v_codigo_agencia VARCHAR2(5) := NULL;

BEGIN
   SELECT distinct b.cod_agencia, descripcion
     INTO v_codigo_agencia, v_nombre_agencia
     FROM sistemas_x_agencia a, agencia b
    WHERE p_codigo = b.cod_agencia
      AND ROWNUM <= 1;
   RETURN(v_nombre_agencia);
   RETURN NULL; EXCEPTION
     When no_data_found then
       utilitarios.mensaje('000132',name_in('variables.codidioma'),'CD');
       raise form_trigger_failure;
     When others then
       utilitarios.mensaje('000132',name_in('variables.codidioma'),'CD');
       raise form_trigger_failure;
END;

FUNCTION CD_NOM_CLIENTE(P_CODIGO  IN VARCHAR2, 
                        P_Error   IN OUT VARCHAR2, 
                        P_SQLCODE IN OUT NUMBER ) RETURN VARCHAR2 IS

  /* FUNCTION CD_NOM_CLIENTE
  ** Hecho por: Alex Salas M.
  ** Fecha: 23-09-1997
  ** Proposito: Regresar el Nombre del Cliente
  ** Argumentos: Codigo de la Persona */

  v_nombre_cliente VARCHAR2(65) := NULL;

BEGIN
   SELECT nombre
     INTO v_nombre_cliente
     FROM personas
    WHERE p_codigo = cod_persona;
   RETURN(v_nombre_cliente);
RETURN NULL; EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      P_error := '000042';
      p_SQLCODE := SQLCODE;
      return NULL;
   WHEN TOO_MANY_ROWS THEN 
      P_error := '000128';
      p_SQLCODE := SQLCODE;
      return NULL;
   WHEN OTHERS THEN 
      P_error := '000129';
      p_SQLCODE := SQLCODE;
      return NULL;
END;

FUNCTION CD_NOM_PRODUCTO(p_empresa   IN VARCHAR2 ,
                         p_producto  IN VARCHAR2, 
                         p_error     IN OUT VARCHAR2, 
                         p_sqlcode   IN OUT NUMBER ) 
                         RETURN VARCHAR2 IS
 
  /* FUNCTION CD_NOM_PRODUCTO
  ** Hecho por: Alex Salas M.
  ** Fecha: 26-12-1997
  ** Proposito: Regresar el Nombre del producto
  ** Argumentos: Codigo de empresa y codigo producto
  */

  v_nombre_producto VARCHAR2(80) := NULL;

BEGIN
   SELECT descripcion
     INTO v_nombre_producto
     FROM productos
    WHERE p_empresa = cod_empresa
      AND p_producto = cod_producto;
   RETURN(v_nombre_producto);
RETURN NULL; EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      P_error := '000050';
      p_SQLCODE := SQLCODE;
      return NULL;
   WHEN OTHERS THEN 
      P_error := '000165';
      p_SQLCODE := SQLCODE;
      return NULL;
END;

FUNCTION CD_NOM_SISTEMA(P_CODIGO IN VARCHAR2 ) RETURN VARCHAR2 IS

  /* FUNCTION CD_NOM_SISTEMA
  ** Hecho por: Alex Salas M.
  ** Fecha: 22-09-1997
  ** Proposito: Regresar el Nombre del Sistema
  ** Argumentos: Codigo de Sistema*/

  v_nombre_sistema VARCHAR2(80) := NULL;
  v_codigo_sistema VARCHAR2(2) := NULL;
BEGIN
   SELECT cod_sistema, descripcion
     INTO v_codigo_sistema, v_nombre_sistema
     FROM sistemas b
    WHERE p_codigo = b.cod_sistema;
   RETURN(v_nombre_sistema);
   RETURN NULL; EXCEPTION
    WHEN NO_DATA_FOUND THEN
      utilitarios.mensaje_error('000589',name_in('variables.codidioma'),'CD',SQLCODE);
      raise form_trigger_failure;
    WHEN OTHERS THEN      
      utilitarios.mensaje_error('000590',name_in('variables.codidioma'),'CD',SQLCODE);
      raise form_trigger_failure;
END;

PROCEDURE CD_OBT_CARTERA(
                         p_empresa   IN VARCHAR2 ,
                         p_cuenta 	 IN OUT VARCHAR2 ,
                         p_cartera   IN OUT VARCHAR2 ,
                         p_plazo 	   IN NUMBER,
                         p_clasificacion IN varchar2,   -- indicador de Normal (V), Garantia, Interbancario
                         p_vencido	 IN varchar2,       -- indicador de Vencido (S), Vigente (N), Vista (V)
                         p_moneda	   IN varchar2,       -- moneda para la cuenta contable
                         p_cliente   IN VARCHAR2,
                         p_forma_pago_int IN VARCHAR2,       -- RMARTINEZ 21/12/2006
                         p_error     IN OUT varchar2, 
                         p_sqlcode   IN OUT number,
                         -- este parametro indica P si la cuenta a buscar es la de principal
                         -- I si es la de Intereses Activos.
                         pTipoCuenta IN varchar2 default 'P' -- Lperez 05/01/2007
                        )  IS
 
  /*****************************************************************
  PROCEDURE: CD_OBT_CARTERA
  REQUIERE : empresa, moneda, plazo incio y plazo final
  HECHO POR: ALEX SALAS M., 12-02-1998
  Modificado por :  Adrián Zúñiga Morales. 7-Jul-1998
                    para manejo de parámetros de clasificación y vencido
  *****************************************************************/
  v_sector_contable varchar2(6);
BEGIN
    p_cuenta  := NULL ;
   
  -- RMARTINEZ 10/05/2006
  -- Para buscar la cuenta contable por sector
   Begin
	   SELECT COD_SEC_CONTABLE
	   INTO v_sector_contable
	   FROM PERSONAS
	   WHERE COD_PERSONA = p_cliente;
	 
   Exception when others then
   	v_sector_contable := null;
  	  -- Error al buscar el cliente
      p_error := '000129' ;    
      p_sqlcode := SQLCODE ;
    return;   	 
   End;

  IF v_sector_contable is not null then
  	BEGIN	
    	SELECT decode(pTipoCuenta,'P',cd.cuenta_contable,cd.cuenta_contable_interes),--Lperez 05/01/2007
    				 cd.cod_cartera
      	INTO p_cuenta, p_cartera
      	FROM cd_cartera cd, cg_catalogo_x_empresa cg
     	 WHERE cd.codigo_empresa  = p_empresa
       	 AND cd.cod_cartera     = p_cartera
       	 AND p_plazo between cd.plazo_inicio AND cd.plazo_fin
       	 AND cd.clasificacion   = p_clasificacion
       	 AND cd.vencido         = p_vencido
       	 AND cd.cod_sec_contable = v_sector_contable  -- RMARTINEZ 10/05/2006
       	 AND cd.forma_pago_int   = p_forma_pago_int   -- RMARTINEZ 21/12/2006
       	 AND cd.codigo_empresa  = cg.codigo_empresa
       	 AND cd.cuenta_contable = cg.cuenta_contable
       	 AND cg.moneda_cuenta   = p_moneda;
		EXCEPTION
   		WHEN NO_DATA_FOUND THEN
      	-- No encontro niguna cartera que cumpla con el plazo y la clasificacion indicada
      	p_error := '000181' ;    
      	p_sqlcode := SQLCODE ;
   		WHEN TOO_MANY_ROWS THEN
      	-- Encontro mas de una cartera para el plazo indicado y la clasificacion
      	p_error := '000182' ;    
      	p_sqlcode := SQLCODE ;
   		WHEN OTHERS THEN
      	-- Error al buscar la cartera indicada
      	p_error := '000183' ;    
      	p_sqlcode := SQLCODE ;
		END;   
		-- Lperez 05/01/2006
		if p_cuenta is null then
			if pTipoCuenta = 'I' then
				-- Error al obtener cuenta para intereses
      	p_error := '000138' ;    
      	p_sqlcode := SQLCODE ;
			end if;			
		end if;		
		-- Fin Lperez 05/01/2006
  ELSE
  	-- Cliente no tiene sector contable asignado
      p_error := '000665' ;    
      p_sqlcode := SQLCODE ;
  	
  END IF;           
END;

PROCEDURE CD_OBT_CARTERA_VISTA(
                               p_empresa       IN VARCHAR2 ,
                               p_cuenta        IN OUT VARCHAR2 ,
                               p_cartera       IN OUT VARCHAR2 ,
                               p_clasificacion IN VARCHAR2, -- clasificacion de cartera: Normal (V), Garantia (G), Interbancario (I)
                               p_moneda        IN VARCHAR2,
                               p_cliente       IN VARCHAR2,   -- RMARTINEZ 10/05/2006
                               p_forma_pago_int IN VARCHAR2,  -- RMARTINEZ 21/12/2006
                               p_error         IN OUT VARCHAR2, 
                               p_sqlcode       IN OUT NUMBER,
                               -- este parametro indica P si la cuenta a buscar es la de principal
                         			 -- I si es la de Intereses Activos.
                         			 pTipoCuenta IN varchar2 default 'P' -- Lperez 05/01/2007
                              ) IS

  /*****************************************************************************************************
  PROCEDURE: CD_OBT_CARTERA_VISTA
  REQUIERE : empresa, moneda, plazo incio y plazo final
  HECHO POR: ALEX SALAS M., 24-03-1998
  Modificado Por: Adrian Zuñiga M. 8-Jul-1998
 	     Quitar parametro de plazo, agregar parametro de moneda, clasificacion y manejo de errores.
  28.12.98   Esolano 
           Se modifica para que retorne el codigo de error (p_error) y el sqlcode (p_sqlcode)
  *****************************************************************************************************/
  v_sector_contable varchar2(6);
BEGIN
  -- RMARTINEZ 10/05/2006
  -- Para buscar la cuenta contable por sector
   Begin
	   SELECT COD_SEC_CONTABLE
	   INTO v_sector_contable
	   FROM PERSONAS
	   WHERE COD_PERSONA = p_cliente;
	 
   Exception when others then
   	v_sector_contable := null;
  	-- Cliente no tiene sector contable asignado
      p_error := '000665' ;    
      p_sqlcode := SQLCODE ;
    return;   	 
   End;

  IF v_sector_contable is not null then
  	BEGIN
    	SELECT decode(pTipoCuenta,'P',cd.cuenta_contable,cd.cuenta_contable_interes),--Lperez 05/01/2007
    				 cd.cod_cartera
      	INTO p_cuenta, p_cartera
      	FROM cd_cartera cd, cg_catalogo_x_empresa cg
     	 WHERE cd.codigo_empresa = p_empresa
       	 AND cd.cod_cartera    = p_cartera
       	 AND cd.vencido = 'V' -- cartera a la vista
       	 AND cd.clasificacion = p_clasificacion
       	 AND cd.cod_sec_contable = v_sector_contable  -- RMARTINEZ 10/05/2006
       	 AND cd.forma_pago_int   = p_forma_pago_int   -- RMARTINEZ 21/12/2006
       	 AND cd.codigo_empresa = cg.codigo_empresa
       	 AND cd.cuenta_contable = cg.cuenta_contable
       	 AND cg.moneda_cuenta = p_moneda ;       
		EXCEPTION
   		WHEN NO_DATA_FOUND THEN
      	-- No encontro niguna cartera a la vista que cumpla con la clasificacion indicada
      	p_error := '000186' ;
      	p_sqlcode := SQLCODE ;
   		WHEN TOO_MANY_ROWS THEN
      	-- Encontro mas de una cartera a la vista para la clasificacion
      	p_error := '000187' ;
      	p_sqlcode := SQLCODE ;
   		WHEN OTHERS THEN
      	-- Error al buscar la cartera indicada
      	p_error := '000183' ;
      	p_sqlcode := SQLCODE ;
		END;    
		--
		-- Lperez 05/01/2006
		if p_cuenta is null then
			if pTipoCuenta = 'I' then
				-- Error al obtener cuenta para intereses
      	p_error := '000138' ;    
      	p_sqlcode := SQLCODE ;
			end if;			
		end if;		
		-- Fin Lperez 05/01/2006
 END IF;
END;

FUNCTION CD_OBT_CASTIGO_X_RET( cod_empresa_p  IN VARCHAR2 , 
                               cod_producto_p IN VARCHAR2 , 
                               p_plazo IN NUMBER DEFAULT 0) 
                               RETURN NUMBER IS
           /*
             Nombre: cd_obt_castigo_x_ret
             Tipo: Funcion
             Retorna: VARCHAR2 (10)
             Parametros: p_plazo NUMBER
             Descripcion: Devuelve el codigo de castigo por retiro
             para el numero de dias que viene como parametro.
             Historia:
             27-04-1998 Adrian Zuñiga Morales Creacion
           */
BEGIN
  DECLARE
     CURSOR plazos IS
        SELECT consecutivo, plazo_inicio, plazo_fin, monto
          FROM cd_castigo_retiro
         WHERE cod_empresa = cod_empresa_p
           AND cod_producto = cod_producto_p;
  BEGIN
     FOR r IN plazos LOOP
        -- verifica si el plazo dado esta entre plazo_inicio y plazo_fin
        IF p_plazo between r.plazo_inicio and r.plazo_fin THEN
           RETURN(r.monto);
        END IF;
     END LOOP;
     -- si termina el CURSOR, significa que no esta, entonces retorna null.
     RETURN(0);
  END;
RETURN NULL; END CD_OBT_CASTIGO_X_RET;

FUNCTION CD_OBT_CASTIGO_X_RET( cod_empresa_p  IN VARCHAR2 , 
                               cod_producto_p IN VARCHAR2 , 
                               p_plazo IN NUMBER DEFAULT 0) 
                               RETURN NUMBER IS
           /*
             Nombre: cd_obt_castigo_x_ret
             Tipo: Funcion
             Retorna: VARCHAR2 (10)
             Parametros: p_plazo NUMBER
             Descripcion: Devuelve el codigo de castigo por retiro
             para el numero de dias que viene como parametro.
             Historia:
             27-04-1998 Adrian Zuñiga Morales Creacion
           */
BEGIN
  DECLARE
     CURSOR plazos IS
        SELECT consecutivo, plazo_inicio, plazo_fin, monto
          FROM cd_castigo_retiro
         WHERE cod_empresa = cod_empresa_p
           AND cod_producto = cod_producto_p;
  BEGIN
     FOR r IN plazos LOOP
        -- verifica si el plazo dado esta entre plazo_inicio y plazo_fin
        IF p_plazo between r.plazo_inicio and r.plazo_fin THEN
           RETURN(r.monto);
        END IF;
     END LOOP;
     -- si termina el CURSOR, significa que no esta, entonces retorna null.
     RETURN(0);
  END;
RETURN NULL; END CD_OBT_CASTIGO_X_RET;

FUNCTION CD_OBT_CASTIGO_X_RET( cod_empresa_p  IN VARCHAR2 , 
                               cod_producto_p IN VARCHAR2 , 
                               p_plazo IN NUMBER DEFAULT 0) 
                               RETURN NUMBER IS
           /*
             Nombre: cd_obt_castigo_x_ret
             Tipo: Funcion
             Retorna: VARCHAR2 (10)
             Parametros: p_plazo NUMBER
             Descripcion: Devuelve el codigo de castigo por retiro
             para el numero de dias que viene como parametro.
             Historia:
             27-04-1998 Adrian Zuñiga Morales Creacion
           */
BEGIN
  DECLARE
     CURSOR plazos IS
        SELECT consecutivo, plazo_inicio, plazo_fin, monto
          FROM cd_castigo_retiro
         WHERE cod_empresa = cod_empresa_p
           AND cod_producto = cod_producto_p;
  BEGIN
     FOR r IN plazos LOOP
        -- verifica si el plazo dado esta entre plazo_inicio y plazo_fin
        IF p_plazo between r.plazo_inicio and r.plazo_fin THEN
           RETURN(r.monto);
        END IF;
     END LOOP;
     -- si termina el CURSOR, significa que no esta, entonces retorna null.
     RETURN(0);
  END;
RETURN NULL; END CD_OBT_CASTIGO_X_RET;

FUNCTION CD_OBT_CASTIGO_X_RET( cod_empresa_p  IN VARCHAR2 , 
                               cod_producto_p IN VARCHAR2 , 
                               p_plazo IN NUMBER DEFAULT 0) 
                               RETURN NUMBER IS
           /*
             Nombre: cd_obt_castigo_x_ret
             Tipo: Funcion
             Retorna: VARCHAR2 (10)
             Parametros: p_plazo NUMBER
             Descripcion: Devuelve el codigo de castigo por retiro
             para el numero de dias que viene como parametro.
             Historia:
             27-04-1998 Adrian Zuñiga Morales Creacion
           */
BEGIN
  DECLARE
     CURSOR plazos IS
        SELECT consecutivo, plazo_inicio, plazo_fin, monto
          FROM cd_castigo_retiro
         WHERE cod_empresa = cod_empresa_p
           AND cod_producto = cod_producto_p;
  BEGIN
     FOR r IN plazos LOOP
        -- verifica si el plazo dado esta entre plazo_inicio y plazo_fin
        IF p_plazo between r.plazo_inicio and r.plazo_fin THEN
           RETURN(r.monto);
        END IF;
     END LOOP;
     -- si termina el CURSOR, significa que no esta, entonces retorna null.
     RETURN(0);
  END;
RETURN NULL; END CD_OBT_CASTIGO_X_RET;

FUNCTION CD_OBT_CASTIGO_X_RET( cod_empresa_p  IN VARCHAR2 , 
                               cod_producto_p IN VARCHAR2 , 
                               p_plazo IN NUMBER DEFAULT 0) 
                               RETURN NUMBER IS
           /*
             Nombre: cd_obt_castigo_x_ret
             Tipo: Funcion
             Retorna: VARCHAR2 (10)
             Parametros: p_plazo NUMBER
             Descripcion: Devuelve el codigo de castigo por retiro
             para el numero de dias que viene como parametro.
             Historia:
             27-04-1998 Adrian Zuñiga Morales Creacion
           */
BEGIN
  DECLARE
     CURSOR plazos IS
        SELECT consecutivo, plazo_inicio, plazo_fin, monto
          FROM cd_castigo_retiro
         WHERE cod_empresa = cod_empresa_p
           AND cod_producto = cod_producto_p;
  BEGIN
     FOR r IN plazos LOOP
        -- verifica si el plazo dado esta entre plazo_inicio y plazo_fin
        IF p_plazo between r.plazo_inicio and r.plazo_fin THEN
           RETURN(r.monto);
        END IF;
     END LOOP;
     -- si termina el CURSOR, significa que no esta, entonces retorna null.
     RETURN(0);
  END;
RETURN NULL; END CD_OBT_CASTIGO_X_RET;

FUNCTION CD_OBTIENE_RENTA(
                          P_EMPRESA  IN VARCHAR2,
                          P_AGENCIA  IN VARCHAR2,
                          P_PRODUCTO IN VARCHAR2
)
RETURN NUMBER  IS
   -- Realiza : Esta funcion obtiene el porcentaje de renta de la tabla de 
   --           cd_producto_x_agencia, si es del caso, o de producto_x_empresa, si es del caso,
   --           si no lo encuentra en ninguna de las dos entonces regresa 0
   --
   porcentaje_renta_v        cd_producto_x_agencia.porcentaje_renta%TYPE;
--
BEGIN
   --
   -- Si es por agencia, obtiene la base de calculo de prod_x_agencia
   --
   begin
      SELECT  porcentaje_renta		
        INTO  porcentaje_renta_v
        FROM  cd_producto_x_agencia
       WHERE  cod_empresa  = p_empresa
         AND  cod_producto = p_producto
         AND  cod_agencia  = p_agencia;
   exception 
      when no_data_found then
         -- si no lo encuentra lo busca en productos por empresa
         -- obtiene la base de calculo de prod_x_empresa
         begin
  	    SELECT  porcentaje_renta
	      INTO  porcentaje_renta_v
	      FROM  cd_producto_x_empresa
	     WHERE  cod_empresa  = p_empresa
	       AND  cod_producto = p_producto;
	 exception
	    when no_data_found then
               utilitarios.mensaje('000509',NAME_IN('variables.codidioma'),'CD');
               raise form_trigger_failure;
	    when others then
               utilitarios.mensaje_error('000111',NAME_IN('variables.codidioma'),'CD',sqlcode);
               raise form_trigger_failure;
         end;
      when others then
         utilitarios.mensaje_error('000111',NAME_IN('variables.codidioma'),'CD',sqlcode);
         raise form_trigger_failure;
   end;
   RETURN(porcentaje_renta_v);
END;

FUNCTION CD_OBT_MONEDA(
                       p_empresa  IN VARCHAR2 ,
                       p_producto IN VARCHAR2 )
                       RETURN     VARCHAR2 IS
  /*Autor : Alex Salas M., 12/02/98
            Retorna el codigo de moneda para Certificados
  */
  M_Error VARCHAR2(10);
  Cod_moneda VARCHAR2(4) := NULL;
BEGIN
   SELECT cod_moneda
     INTO Cod_moneda
     FROM productos
    WHERE cod_producto = p_producto
      AND cod_empresa = p_empresa
      AND cod_cat_producto = 'CD';
   RETURN Cod_moneda;
RETURN NULL; EXCEPTION
   WHEN OTHERS THEN
      utilitarios.mensaje('000088',name_in('variables.codidioma'),'CD',SQLCODE);
      raise form_trigger_failure;
END;

FUNCTION CD_OBT_NUM_CERTIFICADO (P_Empresa IN VARCHAR2, 
                                 P_Agencia IN VARCHAR2,
                                 P_Moneda  IN NUMBER,
                                 P_Error   IN OUT VARCHAR2, 
                                 P_SqlCode IN OUT VARCHAR2) RETURN VARCHAR2 IS 

   /* Creacion : LARROYO 26.11.99  */
   /* Objetivo : Obtener el proximo numero de certificado a partir de una tabla de consecutivos
                 por empresa, agencia y moneda.  Si se presenta algun error se devuelven 
                 en los parametros de salida P_Error y P_SqlCode                                  */
   v_numero  number(9);
   v_maximo  number(9);
BEGIN
   v_numero := NULL ;

   -- Consigue el ultimo numero de certificado asignado por medio de la tabla
   -- parametro_x_empresa y le hace un  "lock" mientras asigna el nuevo número
   begin
     select nvl(val_siguiente,0), val_maximo
       into v_numero, v_maximo
       from cd_consec_x_agencia
      where cod_empresa = P_Empresa
        and cod_agencia = P_Agencia
        and cod_moneda  = P_Moneda
        and activa      = 'S' 
        for update of val_siguiente ;
      if v_numero >= v_maximo then
      	p_error := '000652' ;
      	return NULL;
      end if;
   exception
     WHEN NO_DATA_FOUND THEN
        p_error := '000354' ;
        p_sqlcode := SQLCODE ;
     WHEN TOO_MANY_ROWS THEN
        p_error := '000355' ;
        p_sqlcode := SQLCODE ;
     WHEN OTHERS THEN
        p_error := '000101' ;
        p_sqlcode := SQLCODE ;
   end ;
   if v_numero is not null then
     -- Actualiza el ultimo numero de certificado asignado 
     begin
       update cd_consec_x_agencia
          set val_siguiente = nvl(val_siguiente,0) + 1
        where cod_empresa = P_Empresa
          and cod_agencia = P_Agencia
          and cod_moneda  = P_Moneda
          and activa      = 'S';
     exception
       WHEN NO_DATA_FOUND THEN
          p_error := '000354' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN TOO_MANY_ROWS THEN
          p_error := '000355' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN OTHERS THEN
          p_error := '000101' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
    end ;
  end if ;
  return (v_numero) ;
END;

FUNCTION CD_OBT_NUM_CERTIFICADO (P_Empresa IN VARCHAR2, 
                                 P_Agencia IN VARCHAR2,
                                 P_Moneda  IN NUMBER,
                                 P_Error   IN OUT VARCHAR2, 
                                 P_SqlCode IN OUT VARCHAR2) RETURN VARCHAR2 IS 

   /* Creacion : LARROYO 26.11.99  */
   /* Objetivo : Obtener el proximo numero de certificado a partir de una tabla de consecutivos
                 por empresa, agencia y moneda.  Si se presenta algun error se devuelven 
                 en los parametros de salida P_Error y P_SqlCode                                  */
   v_numero  number(9);
   v_maximo  number(9);
BEGIN
   v_numero := NULL ;

   -- Consigue el ultimo numero de certificado asignado por medio de la tabla
   -- parametro_x_empresa y le hace un  "lock" mientras asigna el nuevo número
   begin
     select nvl(val_siguiente,0), val_maximo
       into v_numero, v_maximo
       from cd_consec_x_agencia
      where cod_empresa = P_Empresa
        and cod_agencia = P_Agencia
        and cod_moneda  = P_Moneda
        and activa      = 'S' 
        for update of val_siguiente ;
      if v_numero >= v_maximo then
      	p_error := '000652' ;
      	return NULL;
      end if;
   exception
     WHEN NO_DATA_FOUND THEN
        p_error := '000354' ;
        p_sqlcode := SQLCODE ;
     WHEN TOO_MANY_ROWS THEN
        p_error := '000355' ;
        p_sqlcode := SQLCODE ;
     WHEN OTHERS THEN
        p_error := '000101' ;
        p_sqlcode := SQLCODE ;
   end ;
   if v_numero is not null then
     -- Actualiza el ultimo numero de certificado asignado 
     begin
       update cd_consec_x_agencia
          set val_siguiente = nvl(val_siguiente,0) + 1
        where cod_empresa = P_Empresa
          and cod_agencia = P_Agencia
          and cod_moneda  = P_Moneda
          and activa      = 'S';
     exception
       WHEN NO_DATA_FOUND THEN
          p_error := '000354' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN TOO_MANY_ROWS THEN
          p_error := '000355' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN OTHERS THEN
          p_error := '000101' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
    end ;
  end if ;
  return (v_numero) ;
END;

FUNCTION CD_REG_VARCHAR(
  p_valor IN VARCHAR2 )
RETURN VARCHAR2 IS
  /*****************************************************************
  FUNCTION que retorna un valor tipo varchar
  HISTORIA Alex Salas M.,11-11-1997
  *****************************************************************/
BEGIN
   RETURN(p_valor);
END;

FUNCTION CD_TASA_INTERES(p_empresa IN VARCHAR2, 
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
   SELECT val_tasa
     INTO v_tasa
     FROM valores_tasas_interes
    WHERE cod_empresa = p_empresa
      AND cod_tasa = p_tasa
      AND fec_inicio IN (SELECT MAX(fec_inicio)
                           FROM	valores_tasas_interes
                          WHERE	cod_empresa = p_empresa
                            AND	cod_tasa = p_tasa
                            AND	fec_inicio <= p_fecha);
   RETURN(v_tasa);
RETURN NULL; EXCEPTION
   WHEN NO_DATA_FOUND THEN  
      P_Error := '000038' ;
      P_SQLCODE := sqlcode ;
      return null;
   WHEN OTHERS THEN 
      P_Error := '000523';
      P_SQLCODE := sqlcode ;
      return null;
END;

PROCEDURE CD_TASA_PLAZO_MONTO(p_empresa   IN VARCHAR2 ,
                              p_producto  IN VARCHAR2 ,
                              p_cliente   IN VARCHAR2 ,
                              p_plazo     IN NUMBER DEFAULT 0,
                              p_monto     IN NUMBER DEFAULT 0,
                              p_fecha     IN DATE ,
                              p_tasa      OUT VARCHAR2 ,
                              p_spread    OUT NUMBER ,
                              p_operacion OUT VARCHAR2 )
IS
   /* Nombre: CD_TASA_PLAZO_MONTO
        Tipo: Procedimiento
    Historia: 12-01-1998 Creacion Alex Salas M.
              23-04-1998 modificacion Adrian Zuñiga M.
              Rehacerla para adaptarla al siguiente modelo
              19-05-1998 modificacion Adrian Zuñiga M.
              Replanteamiento a los nuevos requerimientos
   Proposito: Regresa el codigo de la tasa de la tabla tasa, plazo y monto,
              de la siguiente forma, si tiene por cliente regresa la de cliente
              sino busca si tiene busca la de producto y la regresa.
  Argumentos: p_empresa   Codigo de empresa
              p_producto  codigo producto
              p_cliente   codigo de cliente
              p_plazo     codigo rango plazo
              p_monto     codigo rango monto
              p_fecha     fecha de vigencia.
              p_tasa      codigo_tasa
              p_spread    %spread
              p_operacion +/- */

  v_tasa       cd_cli_tasa_plazo_monto.cod_tasa%TYPE     := NULL;
  v_spread     cd_cli_tasa_plazo_monto.spread%TYPE       := NULL;
  v_cliente    cd_cli_tasa_plazo_monto.cod_cliente%TYPE  := NULL;
  v_producto   cd_prd_tasa_plazo_monto.cod_producto%TYPE := NULL;
  v_error      VARCHAR2(10);
  v_a_la_vista cd_producto_x_empresa.a_la_vista%TYPE;

BEGIN
   /* Primero verifica si el producto es a la vista
     Si no es a la vista =>
     busca en tasa plazo monto por cliente
     si no encuentra registro =>
     busca en tasa plazo monto por producto
     devuelve datos si encuentra, sino da error
     Si es a la vista =>
     busca en tasa monto por cliente a la vista
     si no encuentra registro =>
     busca en tasa monto por producto a la vista
     devuelve datos si encuentra, sino da error
     Esta forma de busqueda tiene varias deficiencias debido a que las
     validaciones consideradas en el ingreso de los datos para los rangos,
     unicamente se valida que el los rangos que se estan incluyendo esten dentro
     de otro existente.
     De este modo se permite que puedan existir rangos que contengan otros y
     traslapes de rangos, de forma que a la hora de buscar, pueden haber varios
     registros que cumplan con la condicion antes mencionada, solo que va a
     devolver la que haya sido ingresada de ultima de acuerdo al criterio de
     busqueda. */

     /* Modificada por ESOLANO 18.01.1999 para que localice el valor del codigo de la tasa, el 
     spread y la operacion del cuadro de tasas dados el codigo de empresa, codigo de producto,
     plazo, monto. El criterio de busqueda esta establecido para que halle el registro con 
     estado = 'A' y MAXIMA FECHA DE VIGENCIA siempre y cuando esta sea menor o igual a la fecha
     que se envia por parametro.  La modificacion radica en obtener la MAXIMA FECHA DE VIGENCIA
     NO EL MAXIMO CODIGO */


   BEGIN
      SELECT a_la_vista
        INTO v_a_la_vista
        FROM cd_producto_x_empresa
       WHERE cod_empresa = p_empresa
         AND cod_producto = p_producto;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        utilitarios.mensaje ('000050', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
        raise form_trigger_failure ;
      WHEN OTHERS THEN
        utilitarios.mensaje ('000171', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
        raise form_trigger_failure ;
   END;


   IF v_a_la_vista = 'N' THEN
      BEGIN
         SELECT cod_tasa, spread, operacion
           INTO p_tasa, p_spread, p_operacion
           FROM cd_cli_tasa_plazo_monto
          WHERE cod_empresa = p_empresa
            AND cod_producto = p_producto
            AND cod_cliente = p_cliente
            AND estado = 'A'
            AND p_plazo between plazo_minimo AND plazo_maximo
            AND p_monto between monto_minimo AND monto_maximo
            AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                     FROM cd_cli_tasa_plazo_monto
                                    WHERE cod_empresa = p_empresa
                                      AND cod_producto = p_producto
                                      AND cod_cliente = p_cliente
                                      AND estado = 'A'
                                      AND p_plazo between plazo_minimo AND plazo_maximo
                                      AND p_monto between monto_minimo AND monto_maximo
                                      AND fecha_vigencia <= p_fecha);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         BEGIN
            SELECT cod_tasa, spread, operacion
              INTO p_tasa, p_spread, p_operacion
              FROM cd_prd_tasa_plazo_monto
             WHERE cod_empresa = p_empresa
               AND cod_producto = p_producto
               AND estado = 'A'
               AND p_plazo between plazo_minimo AND plazo_maximo
               AND p_monto between monto_minimo AND monto_maximo
               AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                        FROM cd_prd_tasa_plazo_monto
                                       WHERE cod_empresa = p_empresa
                                         AND cod_producto = p_producto
                                         AND estado = 'A'
                                         AND p_plazo between plazo_minimo AND plazo_maximo
                                         AND p_monto between monto_minimo AND monto_maximo
                                         AND fecha_vigencia <= p_fecha);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              utilitarios.mensaje ('000162', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
              raise form_trigger_failure ;
            WHEN OTHERS THEN
              utilitarios.mensaje ('000171', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
              raise form_trigger_failure ;
         END;
         WHEN OTHERS THEN
           utilitarios.mensaje ('000163', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
           raise form_trigger_failure ;
      END;
   ELSIF
      v_a_la_vista = 'S' THEN
      BEGIN
         SELECT cod_tasa, spread, operacion
           INTO p_tasa, p_spread, p_operacion
           FROM cd_vis_cli_tasa_monto
          WHERE cod_empresa = p_empresa
            AND cod_producto = p_producto
            AND cod_cliente = p_cliente
            AND estado = 'A'
            AND p_monto between monto_minimo AND monto_maximo
            AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                     FROM cd_vis_cli_tasa_monto
                                    WHERE cod_empresa = p_empresa
                                      AND cod_producto = p_producto
                                      AND cod_cliente = p_cliente
                                      AND estado = 'A'
                                      AND p_monto between monto_minimo AND monto_maximo
                                      AND fecha_vigencia <= p_fecha);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         BEGIN
            SELECT cod_tasa, spread, operacion
              INTO p_tasa, p_spread, p_operacion
              FROM cd_vis_prd_tasa_monto
             WHERE cod_empresa = p_empresa
               AND cod_producto = p_producto
               AND estado = 'A'
               AND p_monto between monto_minimo AND monto_maximo
               AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                        FROM cd_vis_prd_tasa_monto
                                       WHERE cod_empresa = p_empresa
                                         AND cod_producto = p_producto
                                         AND estado = 'A'
                                         AND p_monto between monto_minimo AND monto_maximo
                                         AND fecha_vigencia <= p_fecha);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               utilitarios.mensaje ('000172', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
               raise form_trigger_failure ;
            WHEN OTHERS THEN
               utilitarios.mensaje ('000174', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
               raise form_trigger_failure ;
         END;
         WHEN OTHERS THEN
            utilitarios.mensaje ('000173', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
            raise form_trigger_failure ;
      END;
   END IF;
END;

PROCEDURE CD_TASA_PLAZO_MONTO(p_empresa   IN VARCHAR2 ,
                              p_producto  IN VARCHAR2 ,
                              p_cliente   IN VARCHAR2 ,
                              p_plazo     IN NUMBER DEFAULT 0,
                              p_monto     IN NUMBER DEFAULT 0,
                              p_fecha     IN DATE ,
                              p_tasa      OUT VARCHAR2 ,
                              p_spread    OUT NUMBER ,
                              p_operacion OUT VARCHAR2 )
IS
   /* Nombre: CD_TASA_PLAZO_MONTO
        Tipo: Procedimiento
    Historia: 12-01-1998 Creacion Alex Salas M.
              23-04-1998 modificacion Adrian Zuñiga M.
              Rehacerla para adaptarla al siguiente modelo
              19-05-1998 modificacion Adrian Zuñiga M.
              Replanteamiento a los nuevos requerimientos
   Proposito: Regresa el codigo de la tasa de la tabla tasa, plazo y monto,
              de la siguiente forma, si tiene por cliente regresa la de cliente
              sino busca si tiene busca la de producto y la regresa.
  Argumentos: p_empresa   Codigo de empresa
              p_producto  codigo producto
              p_cliente   codigo de cliente
              p_plazo     codigo rango plazo
              p_monto     codigo rango monto
              p_fecha     fecha de vigencia.
              p_tasa      codigo_tasa
              p_spread    %spread
              p_operacion +/- */

  v_tasa       cd_cli_tasa_plazo_monto.cod_tasa%TYPE     := NULL;
  v_spread     cd_cli_tasa_plazo_monto.spread%TYPE       := NULL;
  v_cliente    cd_cli_tasa_plazo_monto.cod_cliente%TYPE  := NULL;
  v_producto   cd_prd_tasa_plazo_monto.cod_producto%TYPE := NULL;
  v_error      VARCHAR2(10);
  v_a_la_vista cd_producto_x_empresa.a_la_vista%TYPE;

BEGIN
   /* Primero verifica si el producto es a la vista
     Si no es a la vista =>
     busca en tasa plazo monto por cliente
     si no encuentra registro =>
     busca en tasa plazo monto por producto
     devuelve datos si encuentra, sino da error
     Si es a la vista =>
     busca en tasa monto por cliente a la vista
     si no encuentra registro =>
     busca en tasa monto por producto a la vista
     devuelve datos si encuentra, sino da error
     Esta forma de busqueda tiene varias deficiencias debido a que las
     validaciones consideradas en el ingreso de los datos para los rangos,
     unicamente se valida que el los rangos que se estan incluyendo esten dentro
     de otro existente.
     De este modo se permite que puedan existir rangos que contengan otros y
     traslapes de rangos, de forma que a la hora de buscar, pueden haber varios
     registros que cumplan con la condicion antes mencionada, solo que va a
     devolver la que haya sido ingresada de ultima de acuerdo al criterio de
     busqueda. */

     /* Modificada por ESOLANO 18.01.1999 para que localice el valor del codigo de la tasa, el 
     spread y la operacion del cuadro de tasas dados el codigo de empresa, codigo de producto,
     plazo, monto. El criterio de busqueda esta establecido para que halle el registro con 
     estado = 'A' y MAXIMA FECHA DE VIGENCIA siempre y cuando esta sea menor o igual a la fecha
     que se envia por parametro.  La modificacion radica en obtener la MAXIMA FECHA DE VIGENCIA
     NO EL MAXIMO CODIGO */


   BEGIN
      SELECT a_la_vista
        INTO v_a_la_vista
        FROM cd_producto_x_empresa
       WHERE cod_empresa = p_empresa
         AND cod_producto = p_producto;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        utilitarios.mensaje ('000050', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
        raise form_trigger_failure ;
      WHEN OTHERS THEN
        utilitarios.mensaje ('000171', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
        raise form_trigger_failure ;
   END;


   IF v_a_la_vista = 'N' THEN
      BEGIN
         SELECT cod_tasa, spread, operacion
           INTO p_tasa, p_spread, p_operacion
           FROM cd_cli_tasa_plazo_monto
          WHERE cod_empresa = p_empresa
            AND cod_producto = p_producto
            AND cod_cliente = p_cliente
            AND estado = 'A'
            AND p_plazo between plazo_minimo AND plazo_maximo
            AND p_monto between monto_minimo AND monto_maximo
            AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                     FROM cd_cli_tasa_plazo_monto
                                    WHERE cod_empresa = p_empresa
                                      AND cod_producto = p_producto
                                      AND cod_cliente = p_cliente
                                      AND estado = 'A'
                                      AND p_plazo between plazo_minimo AND plazo_maximo
                                      AND p_monto between monto_minimo AND monto_maximo
                                      AND fecha_vigencia <= p_fecha);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         BEGIN
            SELECT cod_tasa, spread, operacion
              INTO p_tasa, p_spread, p_operacion
              FROM cd_prd_tasa_plazo_monto
             WHERE cod_empresa = p_empresa
               AND cod_producto = p_producto
               AND estado = 'A'
               AND p_plazo between plazo_minimo AND plazo_maximo
               AND p_monto between monto_minimo AND monto_maximo
               AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                        FROM cd_prd_tasa_plazo_monto
                                       WHERE cod_empresa = p_empresa
                                         AND cod_producto = p_producto
                                         AND estado = 'A'
                                         AND p_plazo between plazo_minimo AND plazo_maximo
                                         AND p_monto between monto_minimo AND monto_maximo
                                         AND fecha_vigencia <= p_fecha);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              utilitarios.mensaje ('000162', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
              raise form_trigger_failure ;
            WHEN OTHERS THEN
              utilitarios.mensaje ('000171', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
              raise form_trigger_failure ;
         END;
         WHEN OTHERS THEN
           utilitarios.mensaje ('000163', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
           raise form_trigger_failure ;
      END;
   ELSIF
      v_a_la_vista = 'S' THEN
      BEGIN
         SELECT cod_tasa, spread, operacion
           INTO p_tasa, p_spread, p_operacion
           FROM cd_vis_cli_tasa_monto
          WHERE cod_empresa = p_empresa
            AND cod_producto = p_producto
            AND cod_cliente = p_cliente
            AND estado = 'A'
            AND p_monto between monto_minimo AND monto_maximo
            AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                     FROM cd_vis_cli_tasa_monto
                                    WHERE cod_empresa = p_empresa
                                      AND cod_producto = p_producto
                                      AND cod_cliente = p_cliente
                                      AND estado = 'A'
                                      AND p_monto between monto_minimo AND monto_maximo
                                      AND fecha_vigencia <= p_fecha);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         BEGIN
            SELECT cod_tasa, spread, operacion
              INTO p_tasa, p_spread, p_operacion
              FROM cd_vis_prd_tasa_monto
             WHERE cod_empresa = p_empresa
               AND cod_producto = p_producto
               AND estado = 'A'
               AND p_monto between monto_minimo AND monto_maximo
               AND fecha_vigencia IN (SELECT MAX(fecha_vigencia)
                                        FROM cd_vis_prd_tasa_monto
                                       WHERE cod_empresa = p_empresa
                                         AND cod_producto = p_producto
                                         AND estado = 'A'
                                         AND p_monto between monto_minimo AND monto_maximo
                                         AND fecha_vigencia <= p_fecha);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               utilitarios.mensaje ('000172', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
               raise form_trigger_failure ;
            WHEN OTHERS THEN
               utilitarios.mensaje ('000174', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
               raise form_trigger_failure ;
         END;
         WHEN OTHERS THEN
            utilitarios.mensaje ('000173', Name_In('variables.codidioma'), Name_In('variables.codsistema')) ;
            raise form_trigger_failure ;
      END;
   END IF;
END;

PROCEDURE HABILITACAMPO(--JRM 26/06/98
  P_CAMPO IN VARCHAR2,
  P_BAND  IN BOOLEAN)
  /*
    EFECTUA : Habilita o inhabilita un campo dependiendo del valor
              de la bandera en el parametro respectivo.
    HISTORIA: Jrm: Creacion
  */
  is
begin
  if p_band
  then
    set_item_property(p_campo, ENABLED, PROPERTY_ON);
    set_item_property(p_campo, UPDATE_ALLOWED, PROPERTY_ON);
    set_item_property(p_campo, NAVIGABLE, PROPERTY_ON);
  else
    set_item_property(p_campo, ENABLED, PROPERTY_OFF);
  end if;
end;

PROCEDURE obt_parametros(
          pCodEmpresa      in varchar2,
          pCodSistema      in varchar2,
          pParametro       in varchar2,
          pCodIdioma       in varchar2,
          pValor           in out varchar2,
          pDefecto         in varchar2 default '%%%'
) IS
BEGIN
     if pDefecto='%%%'
     then
        select substr(VALOR,1,15)
          into pValor
          from PARAMETROS_X_EMPRESA
         where (COD_EMPRESA = pCodEmpresa)
           and (COD_SISTEMA = pCodSistema)
           and (ABREV_PARAMETRO = pParametro);
     else
       begin
         select substr(VALOR,1,15)
           into pValor
           from PARAMETROS_X_EMPRESA
          where (COD_EMPRESA = pCodEmpresa)
            and (COD_SISTEMA = pCodSistema)
            and (ABREV_PARAMETRO = pParametro);
       exception
         when OTHERS
         then
           pValor := pDefecto;
       end;
     end if;
exception
     when no_data_found
     then
          Utilitarios.Mensaje('000639',pCodIdioma,'CD',acknowledge,pParametro);
          raise form_trigger_failure;
     when others
     then
          Utilitarios.Mensaje_Error('000111',pCodIdioma,'PA',SQLCODE);
          raise form_trigger_failure;
END;

PROCEDURE obt_parametros(
          pCodEmpresa      in varchar2,
          pCodSistema      in varchar2,
          pParametro       in varchar2,
          pCodIdioma       in varchar2,
          pValor           in out varchar2,
          pDefecto         in varchar2 default '%%%'
) IS
BEGIN
     if pDefecto='%%%'
     then
        select substr(VALOR,1,15)
          into pValor
          from PARAMETROS_X_EMPRESA
         where (COD_EMPRESA = pCodEmpresa)
           and (COD_SISTEMA = pCodSistema)
           and (ABREV_PARAMETRO = pParametro);
     else
       begin
         select substr(VALOR,1,15)
           into pValor
           from PARAMETROS_X_EMPRESA
          where (COD_EMPRESA = pCodEmpresa)
            and (COD_SISTEMA = pCodSistema)
            and (ABREV_PARAMETRO = pParametro);
       exception
         when OTHERS
         then
           pValor := pDefecto;
       end;
     end if;
exception
     when no_data_found
     then
          Utilitarios.Mensaje('000639',pCodIdioma,'CD',acknowledge,pParametro);
          raise form_trigger_failure;
     when others
     then
          Utilitarios.Mensaje_Error('000111',pCodIdioma,'PA',SQLCODE);
          raise form_trigger_failure;
END;

