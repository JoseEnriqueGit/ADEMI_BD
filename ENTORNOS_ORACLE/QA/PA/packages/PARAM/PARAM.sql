create or replace PACKAGE BODY    "PARAM" IS
/* -------------------------------------------------------------------- */
FUNCTION Parametro_x_Agencia(p_codEmpresa varchar2,
			     p_codAgencia varchar2,
			     p_abrev      varchar2,
			     p_codSistema varchar2)
		 RETURN varchar2 IS
/* OBJETIVO
	Devolver el valor de un parametro definido para un
	sistema especifico.
    REQUIERE
	Pasar lo siguiente
		p_codEmpresa -- Codigo de la empresa
		p_codAgencia -- Codigo de la Agencia
		p_abrev      -- Abreviatura del parametro
		p_codSistema -- Codigo del sistema
    HISTORIA
	evil 30-01-1996
*/
    v_valor varchar2(80);
BEGIN
     select valor
	into v_valor
	from parametros_x_agencia
	where cod_empresa = p_codEmpresa and
	      cod_agencia = p_codAgencia and
	      cod_sistema = p_codSistema and
	      abrev_parametro = p_abrev;
    return v_valor;
exception
    when OTHERS then
       return null;
END;
/* -------------------------------------------------------------------- */
FUNCTION Parametro_x_Empresa(p_codEmpresa varchar2,
			     p_abrev      varchar2,
			     p_codSistema varchar2)
		 RETURN varchar2 IS
/* OBJETIVO
	Devolver el valor de un parametro definido para un
	sistema especifico.
    REQUIERE
	Pasar lo siguiente
		p_codEmpresa -- Codigo de la empresa
		p_abrev      -- Abreviatura del parametro
		p_codSistema -- Codigo del sistema
    HISTORIA
	evil 30-01-1996
*/
    v_valor parametros_x_empresa.valor%type;---varchar2(80); --malmanzar 04-03-2024
BEGIN
   select valor
	into v_valor
	from parametros_x_empresa
	where cod_empresa = p_codEmpresa and
	      cod_sistema = p_codSistema and
	      abrev_parametro = p_abrev;
    return v_valor;
exception
    when OTHERS then
       return null;
END;
/* -------------------------------------------------------------------- */
FUNCTION Parametro_General(p_abrev      varchar2,
			   p_codSistema varchar2)
		 RETURN varchar2 IS
/* OBJETIVO
	Devolver el valor de un parametro definido para un
	sistema especifico.
    REQUIERE
	Pasar lo siguiente
		p_abrev      -- Abreviatura del parametro
		p_codSistema -- Codigo del sistema
    HISTORIA
	evil 30-01-1996
*/
    v_valor param_generales.valor%type;---varchar2(80); --malmanzar 04-03-2024
BEGIN
     select valor
	into v_valor
	from param_generales
	where cod_sistema = p_codSistema and
	      abrev_parametro = p_abrev;
    return v_valor;
exception
    when OTHERS then
       return null;
END;
END;