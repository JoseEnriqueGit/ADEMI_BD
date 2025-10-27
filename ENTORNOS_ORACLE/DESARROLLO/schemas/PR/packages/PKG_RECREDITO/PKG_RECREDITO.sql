create or replace PACKAGE BODY    PKG_RECREDITO AS

procedure p_genera_recredito(pcodigo_empresa number,
                                       pNo_credito number, 
                                       pCredito_Cancela Number,
                                       pfecha date,
                                       pUser Varchar2,
                                       pAccion Varchar2) -- I = Insert, 'D' = Delete  
                                       is  


 pragma autonomous_transaction;
Begin

if pAccion = 'I' then

Begin
INSERT INTO PR_CANCELACION_CREDITOS(Codigo_Empresa,
                                    no_credito,
                                    No_Credito_Cancelado,
                                    Adicionado_Por,
                                    Fecha_Adicion)
				                    VALUES(
				                    pcodigo_empresa,
				                    pno_credito,
				                    pCredito_Cancela,
				                    pUser,
				                    pfecha);
				                    Exception
				                    When dup_val_on_index then
				                    Null;
End;				                    
   Elsif				                    
       pAccion = 'D' then
       delete PR_CANCELACION_CREDITOS
              where Codigo_Empresa = pcodigo_empresa
                and no_credito = pno_credito
                and No_Credito_Cancelado = pCredito_Cancela;
  Else
  Null;
  End if;               

Commit;
End p_genera_recredito;

Function f_existe_recredito( pcodigo_empresa number,
                             pNo_credito number) return boolean is
                             
  vcount Number;                             
Begin
  Select count(1)
    Into vcount
  From PR_CANCELACION_CREDITOS
  Where codigo_empresa = pcodigo_empresa
    And No_Credito_Cancelado = pNo_credito;
    If vcount > 0 then
    Return True;
    Else
    Return False;
    End If;
End;                                

Function f_nivel_aprobacion(pCodigo_Empresa Number,pUsuario Varchar2)
 Return Boolean is
 
  Cursor c_Data(pc_empresa Number,pc_usuario Varchar2) Is
    SELECT DISTINCT aut
    FROM(
    SELECT   codigo_nivel_aprobacion,
             (Select RELACIONA_AUTO_CANCELACION
              From pr_niveles_aprobacion
              WHERE CODIGO_NIVEL_APROBACION = a.CODIGO_NIVEL_APROBACION) Aut
              From pr_niveles_x_analista a
             Where codigo_empresa = pc_empresa
               And codigo_persona In(
                      Select a.id_empleado
                        From empleados a, usuarios b
                       Where a.cod_per_fisica = b.cod_per_fisica
                         And b.cod_usuario = pc_usuario))
       where aut='S';
 
 vValor varchar2(1);
-- vNivel Number;
-- Vresult boolean;
 Begin
 
 Open c_Data(pCodigo_Empresa ,pUsuario);
 Fetch c_Data Into vValor;
 if C_data%notfound then
   vValor:='N';
 End IF; 
 IF nvl(vValor,'N') = 'S' THEN
    RETURN TRUE;
 ELSE
    RETURN FALSE;
 END IF;
 
 End; 
 
 Function f_credito_pad (pcodigo_empresa Number,pNo_credito Number) return number is
 
 vcredito_can number;
 Begin
   Select no_credito
     into vcredito_can
     From PR_CANCELACION_CREDITOS canc
     Where canc.codigo_empresa = pcodigo_empresa
       And canc.no_credito_Cancelado = pNo_credito;
     Return vcredito_can ; 
     Exception
     When others then
     Return Null;
  End;

Function f_recredito_cancela( pcodigo_empresa number,
                              pNo_credito number) return boolean is
                             
  vcount Number;
  vresult boolean;                             
Begin
  
  Select count(1)
    Into vcount
    From pr_creditos 
 Where codigo_empresa = pcodigo_empresa
    And Estado = 'C'
    And No_Credito in ( Select no_credito_cancelado 
                          From PR_CANCELACION_CREDITOS
                         Where codigo_empresa = pcodigo_empresa
                           And No_Credito = pNo_credito);
    If vcount > 0 then
    vresult := True;
    Else
    vresult := False;
    End If;
    Return vresult;
End;

Function f_cancela_tipo_credito(pCodigo_Empresa Number, pTipo_Credito Number) Return Varchar2 is

vCANCELA_RECREDITO pr_tipo_credito.CANCELA_RECREDITO%type;
Begin
  select CANCELA_RECREDITO
     into vCANCELA_RECREDITO
   from pr_tipo_credito
  where codigo_empresa = pCodigo_Empresa
    and tipo_credito = pTipo_Credito;
    
   Return vCANCELA_RECREDITO;
     Exception 
      when others then 
      vCANCELA_RECREDITO := 'N';
       Return vCANCELA_RECREDITO;
End; 


END PKG_RECREDITO;