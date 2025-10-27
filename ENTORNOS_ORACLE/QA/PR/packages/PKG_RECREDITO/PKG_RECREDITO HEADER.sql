create or replace PACKAGE    PKG_RECREDITO AS

procedure p_genera_recredito(pcodigo_empresa number,
                             pNo_credito number, 
                             pCredito_Cancela Number,
                             pfecha date,
                             pUser Varchar2,
                             pAccion Varchar2);
                             
Function f_existe_recredito( pcodigo_empresa number,
                             pNo_credito number)
  Return boolean;    

Function f_nivel_aprobacion(pCodigo_Empresa Number,pUsuario Varchar2) 
  Return Boolean;              
  
  Function f_credito_pad (pcodigo_empresa Number,pNo_credito Number) return number;        
  
  Function f_recredito_cancela( pcodigo_empresa number,
                              pNo_credito number) return boolean;
                              
Function f_cancela_tipo_credito(pCodigo_Empresa Number, pTipo_Credito Number) Return Varchar2;                                                            

END PKG_RECREDITO;