create or replace PACKAGE      "PARAM" IS
  FUNCTION Parametro_General(p_abrev      varchar2,
			   p_codSistema varchar2)
		 RETURN varchar2;
  FUNCTION Parametro_x_Agencia(p_codEmpresa varchar2,
			     p_codAgencia varchar2,
			     p_abrev      varchar2,
			     p_codSistema varchar2)
		 RETURN varchar2;
  FUNCTION Parametro_x_Empresa(p_codEmpresa varchar2,
			       p_abrev      varchar2,
			       p_codSistema varchar2)
		 RETURN varchar2;
END;

 
 
 