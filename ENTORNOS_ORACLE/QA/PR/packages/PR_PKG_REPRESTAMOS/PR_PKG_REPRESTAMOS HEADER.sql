create or replace PACKAGE       PR_PKG_REPRESTAMOS IS
    vTipo_parametro CONSTANT VARCHAR2(30):= 'REPRESTAMOS';
    vCodigoEmpresa  CONSTANT number(1):=1;
    vEstadoNotificacionPendiente  CONSTANT VARCHAR2(5):='NP';
    vEstadoLinkVencido  CONSTANT VARCHAR2(5):='AN';
    PROCEDURE Precalifica_Represtamo;  
    PROCEDURE Precalifica_Repre_Cancelado;
    PROCEDURE Precalifica_Repre_Cancelado_hi;
    PROCEDURE Precalifica_Represtamo_fiadores;
    PROCEDURE Precalifica_Represtamo_fiadores_hi;
    PROCEDURE Precalifica_Carga_Dirigida;
    PROCEDURE Precalifica_Campana_Especiales;         
    PROCEDURE Actualiza_Precalificacion;   
    PROCEDURE Actualiza_Preca_Dirigida;
    PROCEDURE Actualiza_Preca_Campana_Especiale; 
    PROCEDURE Actualiza_XCORE_CUSTOM;
    PROCEDURE ACTUALIZA_XCORE_DIRIGIDA;
    PROCEDURE ACTUALIZA_XCORE_CAMPANA_ESPECIAL;
    PROCEDURE PVALIDA_XCORE;   
    PROCEDURE PVALIDA_WORLD_COMPLIANCE;
    PROCEDURE OBT_WORLD_COMPLIANCE(P_Identificacion IN VARCHAR2,P_Primer_Nombre IN VARCHAR2,P_Primer_Apellido    IN VARCHAR2,VALOR OUT NUMBER, PMENSAJE OUT VARCHAR2) ;  
    FUNCTION F_Genera_Secuencia RETURN NUMBER;
    FUNCTION F_Genera_Secuencia_Carga_Dirigida RETURN NUMBER;
    FUNCTION F_Genera_Secuencia_Campana_Especiales RETURN NUMBER;
    FUNCTION F_Obt_Parametro_Represtamo(pCodigo IN VARCHAR) RETURN VARCHAR2;
    FUNCTION F_Obt_Valor_Parametros(pParametro IN VARCHAR2) RETURN string_table pipelined;
    FUNCTION F_Obt_Parametro_Represtamo_Raw(pCodigo IN VARCHAR) RETURN RAW;
    FUNCTION F_Obt_Descripcion_Estado(pCodigo   IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION F_Obt_Telefono(pCodigo   IN VARCHAR2,pTipo IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION F_Validar_Telefono(pTelefono  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION F_Obt_Empresa_Represtamo RETURN number;
    FUNCTION F_Validar_Edad(pCodigo_cliente IN NUMBER, pTipo VARCHAR2) RETURN NUMBER ; 
    FUNCTION F_Obt_Des_Precalificacion(pCodigo_cliente IN NUMBER) RETURN VARCHAR2;
   -- FUNCTION f_obt_cel_sms(pCod_cliente IN VARCHAR2) RETURN VARCHAR2;
  -- Se obtiene un celular asociado a un cliente de represtamos
  -- se filtra solo por tipo celular prque los residenciales no se puede enviar SMS
  -- se ordena por fecha de inclusión descendente. si es nula se toma el primer dia en producción del core 01072016
  -- y como segundo criterio de orden la fechs de modificación.
    PROCEDURE P_Montos_Represtamos(
                            pNoCredito              IN     NUMBER,
                            pTipo_Credito           IN     NUMBER,
                            pCodigo_Cliente         IN     NUMBER,
                            pFechaPrestamo          IN     DATE DEFAULT Calendar.Fecha_Actual_Calendario('PR', '1', '50'),
                            pTasa                   IN     NUMBER,
                            pMontoPrestamo          IN     NUMBER,
                            pPlazo_Segun_Unidad     IN     NUMBER,    
                            pEsVida                 IN     VARCHAR2 DEFAULT 'S',
                            pEsDesempleo            IN     VARCHAR2 DEFAULT 'S',
                            nMontoCuota             OUT    NUMBER,
                            nMontoCargos            OUT    NUMBER,
                            nMontoCancelacion       OUT    NUMBER,
                            nMontoDepositar         OUT    NUMBER,
                            nMontoSeguroVida        OUT    NUMBER,
                            nMontoSeguroDesempleo   OUT    NUMBER,
                            nMontoMypime            Out    NUMBER,     
                            nMontoCuotaTotal        OUT    NUMBER,
                            PCalculaSeguroMypime  IN     VARCHAR2,
                            PCalculaSeguroDesempleo IN     VARCHAR2,                 
                            pMensajeError           IN OUT VARCHAR2);
                            
    PROCEDURE P_Montos_Represtamos_Cancelado(
                            pNoCredito              IN     NUMBER,
                            pTipo_Credito           IN     NUMBER,
                            pCodigo_Cliente         IN     NUMBER,
                            pFechaPrestamo          IN     DATE DEFAULT Calendar.Fecha_Actual_Calendario('PR', '1', '50'),
                            pTasa                   IN     NUMBER,
                            pMontoPrestamo          IN     NUMBER,
                            pPlazo_Segun_Unidad     IN     NUMBER,    
                            pEsVida                 IN     VARCHAR2 DEFAULT 'S',
                            pEsDesempleo            IN     VARCHAR2 DEFAULT 'S',
                            nMontoCuota             OUT    NUMBER,
                            nMontoCargos            OUT    NUMBER,
                            nMontoCancelacion       OUT    NUMBER,
                            nMontoDepositar         OUT    NUMBER,
                            nMontoSeguroVida        OUT    NUMBER,
                            nMontoSeguroDesempleo   OUT    NUMBER,
                            nMontoMypime            Out    NUMBER,     
                            nMontoCuotaTotal        OUT    NUMBER,
                            PCalculaSeguroMypime  IN     VARCHAR2,
                            PCalculaSeguroDesempleo IN     VARCHAR2,                 
                            pMensajeError           IN OUT VARCHAR2);                        

    PROCEDURE P_Cargar_Opcion_Represtamo(pIdReprestamo     IN     VARCHAR2,
                                         pMensajeError     IN OUT VARCHAR2);    
                                      
    PROCEDURE P_Actualizar_Opcion_Front (pNoCredito                IN     VARCHAR2,
                                         pTIPO_CREDITO             IN     VARCHAR2,
                                         pMonto                    IN     VARCHAR2,
                                         pPlazo                    IN     VARCHAR2,
                                         /*PCalculaSeguroMypime      IN     VARCHAR2,
                                         PCalculaSeguroDesempleo   IN     VARCHAR2,
                                         Montoaprobado             OUT Varchar2,
                                         Montocancelacion          OUT Varchar2,
                                         Montodepositar            OUT Varchar2,
                                         Montocuota                OUT Varchar2,
                                         Montocargo                OUT Varchar2,
                                         MontoseguroVida           OUT Varchar2,
                                         Montodesempleo            OUT Varchar2,
                                         MontoMypime               OUT Varchar2,
                                         Montocuotatotal           OUT Varchar2,
                                         Tasa                      OUT Varchar2,
                                         Plazo                     OUT Varchar2,
                                         Monto                     OUT Varchar2,
                                         PtipoCredito              OUT VARCHAR2,*/
                                        -- status                    OUT Varchar2,
                                         pMensajeError             IN OUT VARCHAR2);
    
    
    PROCEDURE P_Calcular_Opcion_Front     (pIdReprestamo           IN     VARCHAR2,
                                         pMonto                    IN     VARCHAR2,
                                         pPlazo                    IN     VARCHAR2,
                                         PCalculaSeguroMypime      IN     VARCHAR2,
                                         PCalculaSeguroDesempleo   IN     VARCHAR2,
                                         Montoaprobado             OUT Varchar2,
                                         Montocancelacion          OUT Varchar2,
                                         Montodepositar            OUT Varchar2,
                                         Montocuota                OUT Varchar2,
                                         Montocargo                OUT Varchar2,
                                         MontoseguroVida           OUT Varchar2,
                                         Montodesempleo            OUT Varchar2,
                                         MontoMypime               OUT Varchar2,
                                         Montocuotatotal           OUT Varchar2,
                                         Tasa                      OUT Varchar2,
                                         Plazo                     OUT Varchar2,
                                         Monto                     OUT Varchar2,
                                         PtipoCredito              OUT VARCHAR2,
                                         status                    OUT Varchar2,
                                         pMensajeError             IN OUT VARCHAR2);
     PROCEDURE P_Carga_Opcion_Front     (pIdReprestamo           IN     VARCHAR2,
                                         Plazo                   IN Varchar2,
                                         MontoReprestamo         IN Varchar2,
                                         MontoDescontar          IN Varchar2,
                                         Montodepositar          IN Varchar2,
                                         Montocuota              IN Varchar2,
                                         Montocargo              IN Varchar2,
                                         MontoseguroVida         IN Varchar2,
                                         Montodesempleo          IN Varchar2,
                                         Tasa                    IN Varchar2,
                                         Montocuotatotal         IN Varchar2,
                                         MontoMipyme             IN Varchar2,
                                         pMensajeError           IN OUT VARCHAR2);                           
        
    PROCEDURE P_Validar_Idreprestamos(pIdReprestamo     IN     VARCHAR2,
                                      pCanal            IN     VARCHAR2,
                                      pNombres          IN OUT VARCHAR2,
                                      pApellidos        IN OUT VARCHAR2,
                                      pIdentificacion   IN OUT VARCHAR2,
                                      pSexo             IN OUT VARCHAR2,
                                      pMonto            IN OUT NUMBER,
                                      pIntentosIdent    IN OUT NUMBER,
                                      pIntentosPin      IN OUT NUMBER,
                                      pPinTiempo        IN OUT NUMBER,
                                      pEstado           IN OUT VARCHAR2,
                                      pDescEstado       IN OUT VARCHAR2,
                                      pStep             IN OUT VARCHAR2,
                                      pTipoRelacion     IN OUT VARCHAR2,
                                      pOrigenFiador     IN OUT VARCHAR2,
                                      pOrigenCampana    IN OUT VARCHAR2,
                                      pMensaje          IN OUT VARCHAR2);

    FUNCTION F_Validar_Pin(pIdReprestamo     IN VARCHAR2,
                           pCanal            IN VARCHAR2,
                           pIdentificacion   IN VARCHAR2,
                           pPin              IN VARCHAR2)
      RETURN BOOLEAN;                                                                            

    PROCEDURE P_Datos_Primarios(pCodCliente       IN     VARCHAR2,
                                pNombres          IN OUT VARCHAR2,
                                pApellidos        IN OUT VARCHAR2,
                                pIdentificacion   IN OUT VARCHAR2,
                                pSexo             IN OUT VARCHAR2,
                                pFec_Nacimiento   IN OUT DATE,
                                pNacionalidad     IN OUT VARCHAR2,
                                pEstadoCivil      IN OUT VARCHAR2,
                                pMensaje          IN OUT VARCHAR2);

    PROCEDURE P_Datos_Secundarios(pCodCliente         IN     VARCHAR2,
                                  pTelefonoCelular    IN OUT VARCHAR2,
                                  pTelefonoResidencia IN OUT VARCHAR2,
                                  pTelefonoTrabajo    IN OUT VARCHAR2,
                                  pCorreo             IN OUT VARCHAR2,
                                  pCodDireccion       IN OUT VARCHAR2,
                                  pTipDireccion       IN OUT VARCHAR2,
                                  pDireccion          IN OUT VARCHAR2,
                                  pMensaje            IN OUT VARCHAR2);     
                                  
   PROCEDURE P_Obtener_Nombres_Cliente(pNum_Represtamo   IN     VARCHAR2,
                                  pPrimerNombre       OUT VARCHAR2,
                                  pSegundoNombre      OUT VARCHAR2,
                                  pPrimerApellido     OUT VARCHAR2,
                                  pSegundoApellido    OUT VARCHAR2);

    FUNCTION P_Solicitar_Pin(pIdReprestamo     IN VARCHAR2,
                             pCanal            IN VARCHAR2,
                             pUsuario          IN VARCHAR2,
                             pRespuesta        IN OUT VARCHAR2,
                             pObservacion      IN  VARCHAR2 DEFAULT 'Solicitado nuevo PIN')
      RETURN VARCHAR2;

    PROCEDURE P_Actualizar_Intentos(pIdReprestamo     IN VARCHAR2,
                                    pTipoIntento      IN VARCHAR2,        -- TIPO I = Identificacion, P = PIN
                                    pNumeroIntento    IN NUMBER,
                                    pRespuesta        IN OUT VARCHAR2);
                                                                   
    PROCEDURE P_Validar_Cambio_Estado(pIdReprestamo     IN VARCHAR2,
                                      pEstado           IN VARCHAR2);                                                                 
   PROCEDURE P_Generar_Bitacora(pIdReprestamo     IN VARCHAR2,
                                pCanal            IN VARCHAR2,
                                pEstado           IN VARCHAR2,
                                pStep             IN VARCHAR2,
                                pObservaciones    IN VARCHAR2,
                                pUsuario          IN VARCHAR2);   

   FUNCTION f_Validar_Canal(pCanal  IN VARCHAR2)
     RETURN BOOLEAN;                                  
                                   
   FUNCTION P_Total_Estado(pEstado      IN VARCHAR2)
     RETURN NUMBER;
     
   FUNCTION P_Total_Estado_Bitacora(pEstado      IN VARCHAR2)
     RETURN NUMBER; 
     
   FUNCTION P_Total_Estado_Bitacora_ID(pEstado      IN VARCHAR2, pIdReprestamo     IN VARCHAR2)
     RETURN NUMBER;
     
   FUNCTION f_Step_Actual(pEstado      IN VARCHAR2, pIdReprestamo     IN VARCHAR2) RETURN VARCHAR2;
                                
   PROCEDURE P_Notificar_Ayuda(pUsuario          IN VARCHAR2);
   
   PROCEDURE P_Bloquear_Represtamo(pIdReprestamo     IN     VARCHAR2,
                                   pTipoIntento      IN     VARCHAR2,        
                                   pRespuesta        IN OUT VARCHAR2);
   
   PROCEDURE P_Desbloquear_Represtamo(pIdReprestamo     IN      VARCHAR2,
                                      pCodigoEstado     IN      VARCHAR2, 
                                      pUsuario          IN      VARCHAR2,
                                      pObservacion      IN      VARCHAR2,
                                      pRespuesta        IN OUT  VARCHAR2);
   
   PROCEDURE P_Desbloqueo_FrontEnd(pIdReprestamo     IN     VARCHAR2,
                                    pCanal            IN     VARCHAR2,
                                    pTipoBloqueo      IN     NUMBER,
                                    pInternto         IN     NUMBER DEFAULT 3,
                                    pRespuesta        IN OUT VARCHAR2);

PROCEDURE P_Desactivar_Activar_FrontEnd(pIdReprestamo     IN     VARCHAR2,
                                       pActivacion      IN     NUMBER ,
                                        pRespuesta       IN OUT VARCHAR2);   
   PROCEDURE P_Notificar_Desbloqueo(pIdReprestamo    IN      NUMBER,
                                    pCodigoEstado    IN      VARCHAR2,
                                    pRespuesta       IN OUT  VARCHAR2);

   PROCEDURE P_Notificar_Desembolso(pIdReprestamo    IN      NUMBER,
                                    pCodigoEstado    IN      VARCHAR2,
                                    pRespuesta       IN OUT  VARCHAR2);

   PROCEDURE P_Notificar_Encuesta(pIdReprestamo    IN      NUMBER,
                                  pRespuesta       IN OUT  VARCHAR2);                                                                           

   PROCEDURE P_Notificar_Reenvio_Link(pIdReprestamo    IN      NUMBER,
                                      pRespuesta       IN OUT  VARCHAR2);                                     
   
   FUNCTION P_Obt_Estado_Represtamo(pIdReprestamo     IN VARCHAR2,
                                    pTipo             IN VARCHAR2 DEFAULT 'A')  -- A = Actual, O = Original
     RETURN VARCHAR2;
   
   FUNCTION F_Obt_Subject_Email(pIdReprestamo     IN VARCHAR2) RETURN VARCHAR2;    
     
   FUNCTION F_Obt_Body_Mensaje(pIdReprestamo     IN VARCHAR2,
                            pCanal           IN VARCHAR2)
     RETURN VARCHAR2;                             
   
   PROCEDURE P_Registrar_Solicitud(pIdReprestamo     IN     VARCHAR2,
                                   pUsuario          IN     VARCHAR2,
                                   pMensaje          IN OUT VARCHAR2);
   PROCEDURE P_Registra_Solicitud_Dirigida(pIdReprestamo     IN     VARCHAR2,
                                           pUsuario          IN     VARCHAR2,
                                           pMensaje          IN OUT VARCHAR2);
   PROCEDURE P_Registra_Solicitud_Campana(pIdReprestamo     IN     VARCHAR2,
                                          pTipo_Credito    IN      NUMBER,
                                           pUsuario         IN     VARCHAR2,
                                           pMensaje         IN OUT VARCHAR2);                                        
   PROCEDURE P_Registrar_Rechazo(pIdReprestamo   IN     VARCHAR2,
                                 pCanal          IN     VARCHAR2,
                                 pIdRechazo      IN     VARCHAR2,
                                 pMensaje        IN OUT VARCHAR2);   

   PROCEDURE P_Actualizar_Datos_Solicitud( pIdReprestamo        IN     VARCHAR2,
                                           pCanal               IN     VARCHAR2,
                                           pEstado              IN     VARCHAR2,
                                           pStep                IN     VARCHAR2,
                                           pPlazo               IN     NUMBER,                                                
                                           pTelefonoCelular     IN     VARCHAR2,
                                           pTelefonoResidencia  IN     VARCHAR2,
                                           pTelefonoTrabajo     IN     VARCHAR2,
                                           pEmail               IN     VARCHAR2,
                                           pDireccion           IN     VARCHAR2,                                           
                                           pMensaje             IN OUT VARCHAR2);     
                                           
   PROCEDURE P_Actualizar_Canal_Represtamo(  pCod_persona  IN  VARCHAR2,
                                              pcod_area     IN  VARCHAR2,
                                              Pnum_telefono IN  VARCHAR2,
                                              pMensaje          IN OUT VARCHAR2);
   PROCEDURE P_Actualizar_Email_Represtamo    (  pCod_persona  IN  VARCHAR2,
                                              PEmail         IN  VARCHAR2,
                                              pMensaje          IN OUT VARCHAR2);    
   PROCEDURE P_Actualizar_Anular_Represtamo(pMensaje          IN OUT VARCHAR2/*,pIDAPLICACION IN OUT NUMBER*/); 
   
    
   PROCEDURE P_Carga_Precalifica_Represtamo(pMensaje         IN OUT VARCHAR2);                                                     
   PROCEDURE P_Carga_Precalifica_Cancelado(pMensaje          IN OUT VARCHAR2);
   PROCEDURE P_Carga_Precalifica_Manual(pMensaje             IN OUT VARCHAR2);
   PROCEDURE P_Carga_Precalifica_Campana_Especial(pMensaje             IN OUT VARCHAR2);       
   PROCEDURE Enviar_SMS_API(pIdreprestamo       IN     VARCHAR2,
                            pTelefono           IN     VARCHAR2,
                            pNombres            IN     VARCHAR2,
                            pApellidos          IN     VARCHAR2,
                            pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                            pFormatoMensaje     IN     VARCHAR2,
                            pMensaje            IN     VARCHAR2,
                            pRespuesta          IN OUT VARCHAR2);
    PROCEDURE Enviar_SMS_API_DESBLOQUEO(pIdreprestamo       IN     VARCHAR2,
                            pTelefono           IN     VARCHAR2,
                            pNombres            IN     VARCHAR2,
                            pApellidos          IN     VARCHAR2,
                            pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                            pFormatoMensaje     IN     VARCHAR2,
                            pMensaje            IN     VARCHAR2,
                            pRespuesta          IN OUT VARCHAR2);                        

   PROCEDURE Reenviar_Sms_Api(pIdReprestamo       IN     NUMBER,
                              pTelefono           IN     VARCHAR2,
                              pNombres            IN     VARCHAR2,
                              pApellidos          IN     VARCHAR2,
                              pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                              pFormatoMensaje     IN     VARCHAR2,
                              pMensaje            IN     VARCHAR2,
                              pRespuesta          IN OUT VARCHAR2);                             
   PROCEDURE Enviar_Sms_Api_ENCUESTA(pIdReprestamo       IN     NUMBER,
                                       pTelefono           IN     VARCHAR2,
                                       pNombres            IN     VARCHAR2,
                                       pApellidos          IN     VARCHAR2,
                                       pTipoNotificacion   IN     VARCHAR2, -- SMS, WHATSAPP
                                       pFormatoMensaje     IN     VARCHAR2,
                                       pMensaje            IN     VARCHAR2,
                                       pRespuesta          IN OUT VARCHAR2); 
   PROCEDURE Enviar_Correo_API(pEmail            IN     VARCHAR2,
                               pNombres          IN     VARCHAR2,
                               pApellidos        IN     VARCHAR2,
                               pSubject          IN     VARCHAR2,
                               pFormatoMensaje   IN     VARCHAR2,
                               pMensaje          IN     VARCHAR2,
                               pRespuesta        IN OUT VARCHAR2);       
   PROCEDURE Enviar_Correo_API_ENCUESTA(pIdReprestamo     IN     NUMBER,
                                        pEmail            IN     VARCHAR2,
                                        pNombres          IN     VARCHAR2,
                                        pApellidos        IN     VARCHAR2,
                                        pSubject          IN     VARCHAR2,
                                        pFormatoMensaje   IN     VARCHAR2,
                                        pMensaje          IN     VARCHAR2,
                                        pRespuesta        IN OUT VARCHAR2);   
    PROCEDURE Reenviar_Correo_API(pIdReprestamo     IN     NUMBER,
                                  pEmail            IN     VARCHAR2,
                                  pNombres          IN     VARCHAR2,
                                  pApellidos        IN     VARCHAR2,
                                  pSubject          IN     VARCHAR2,
                                  pFormatoMensaje   IN     VARCHAR2,
                                  pMensaje          IN     VARCHAR2,
                                  pRespuesta        IN OUT VARCHAR2);

   FUNCTION F_Reenviar_Represtamo(pIdReprestamoAnt IN      NUMBER,
                                  pUsuario         IN      VARCHAR2,
                                  pError           IN OUT  VARCHAR2) 
      RETURN NUMBER;         
      
   PROCEDURE P_Notificar_Estado(pIdReprestamo    IN      VARCHAR2,
                                pCanal           IN      VARCHAR2,
                                pCodigoEstado    IN      VARCHAR2,
                                pRespuesta       IN OUT  VARCHAR2);   
                                                                                                                               
    PROCEDURE P_Anular_Represtamos_Inactivos(pIdReprestamo IN NUMBER DEFAULT NULL);
    -- Elaborado por Jose Díaz. 22/08/2022
    -- Historia del BackLog RD-24
    -- Se inactivan todos los represtamos que no concluyeron el proceso
    -- Este proceso debe de ejecutarse previo a la recarga automática diaria   
    
    FUNCTION F_Validar_Existe_IdDeclinar(pIdDeclinar     IN VARCHAR2)
      RETURN BOOLEAN;
    
    FUNCTION F_Validar_Existe_Estado(pCodigoEstado     IN VARCHAR2)
      RETURN BOOLEAN;
    FUNCTION F_Validar_Tipo_Represtamo(pIdReprestamo IN NUMBER) RETURN BOOLEAN;
    FUNCTION F_Validar_Tipo_Represtamo_Carga(pIdReprestamo IN NUMBER) RETURN BOOLEAN;
    FUNCTION F_Validar_Listas_PEP(    p_codempresa IN VARCHAR2,p_codpersona IN VARCHAR2)RETURN NUMBER;
    FUNCTION F_Validar_Lista_NEGRA(    p_codempresa IN VARCHAR2,p_codpersona IN VARCHAR2)RETURN NUMBER;
    FUNCTION F_ES_REPRESTAMO_DIGITAL(PNO_CREDITO IN NUMBER)  
     RETURN VARCHAR2;
    FUNCTION F_Existe_Represtamo(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN;
    FUNCTION F_Existe_Solicitudes(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN;
    FUNCTION F_Existe_Credito(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN;
    FUNCTION F_Existe_Canales(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN;
    FUNCTION F_Existe_Opciones(pIdReprestamo IN NUMBER )
      RETURN BOOLEAN;
    FUNCTION F_Obtener_Nuevo_Credito(pIdReprestamo IN NUMBER)
      RETURN   NUMBER;
   FUNCTION F_Obtener_Credito_Cancelado(pIdReprestamo IN NUMBER,PMONTO IN NUMBER)
      RETURN   NUMBER;  
  FUNCTION F_Obtener_plazo(pIdReprestamo IN NUMBER, pMtoSeleccionado IN NUMBER)
      RETURN   NUMBER ;
    FUNCTION F_Obtener_Total_SMS_Enviados(pIdReprestamo IN NUMBER)
      RETURN   NUMBER;
    FUNCTION F_Existe_Plazo(pTipoCredito    IN VARCHAR2,
                            pPlazo          IN NUMBER )
      RETURN BOOLEAN;
    
    FUNCTION F_Obtiene_Desc_Bitacora(pIdReprestamo      IN NUMBER,
                                     pEstado            IN VARCHAR2)
      RETURN VARCHAR2;
      
    FUNCTION F_TIENE_GARANTIA(pNoCredito IN NUMBER)
   
      RETURN NUMBER;
   FUNCTION F_TIENE_GARANTIA_HISTORICO(pNoCredito IN NUMBER)
   
      RETURN NUMBER;
    FUNCTION F_HORARIO_VALIDO_NOTIFICACION( pfecha IN DATE ) 
      RETURN NUMBER;
    PROCEDURE P_Actualiza_Credito_Solicitud(
                                 pNum_Represtamo   IN       NUMBER,
                                 pNuevo_credito    IN       NUMBER,        ---Out
                                 pIdTempfud        IN       VARCHAR2,         
                                 pNombreArchivo    IN       VARCHAR2,
                                 pError               OUT   VARCHAR2);  
    
    PROCEDURE P_Actualiza_Fud (pIdReprestamo         IN      NUMBER,
                              pTelefono             IN      VARCHAR2,
                              pEmail                IN      VARCHAR2,
                              pCodPais              IN      NUMBER,
                              pCodProvincia         IN      NUMBER,
                              pCodCanton            IN      NUMBER,
                              pCodDistrito          IN      NUMBER,
                              pCodCiudad            IN      NUMBER,
                              pDireccion            IN      VARCHAR2,
                              pLugarTrabajo         IN      VARCHAR2,
                              pFechaIngreso         IN      VARCHAR2,
                              pCargo                IN      VARCHAR2,
                              pNombreEstablecimiento IN      VARCHAR2,
                              pMes                  IN      VARCHAR2,
                              pAno                  IN      VARCHAR2,
                              pDestinoCredito       IN      NUMBER,
                              pDestino              IN      VARCHAR2,
                              pTrabajoDireccion     IN      VARCHAR2,
                              pTipoGeneradorDivisas IN      VARCHAR2,
                              pOcupacion            IN      VARCHAR2,
                              pError                   OUT  VARCHAR2);
    
    PROCEDURE P_Procesa_Credito (pCodigo_Empresa   IN     NUMBER,
                                 pNum_Represtamo   IN     NUMBER,
                                 pPeriodicidad     IN     VARCHAR2 DEFAULT '05', --- (2) := '05'; ---In
                                 pNuevo_credito       OUT NUMBER,        ---Out
                                 pError               OUT VARCHAR2);   
   PROCEDURE P_Procesa_Credito_Cancelado (pCodigo_Empresa   IN     NUMBER,
                                 pNum_Represtamo   IN     NUMBER,
                                 pPeriodicidad     IN     VARCHAR2 DEFAULT '05', --- (2) := '05'; ---In
                                 pMtoPrestamo      IN     NUMBER,
                                 pNuevo_credito       OUT NUMBER,        ---Out
                                 pNumCliente       IN VARCHAR2,
                                 pError               OUT VARCHAR2);                                   
   PROCEDURE P_GENERA_DOCUMENTOS (pError OUT VARCHAR2);
    PROCEDURE p_Procesa_Fec(pNum_Represtamo         IN      NUMBER,
                            pCOD_AGENCIA            IN      VARCHAR2,
                            pCOD_OFICIAL            IN      VARCHAR2,
                            pCODIGO_ACTIVIDAD       IN      VARCHAR2,
                            pMARGEN_BRUTO_STD       IN      NUMBER,
                            pGASTOS_OPERATIVOS_STD  IN      NUMBER,  
                            pVENTAS_MENSUAL         IN      NUMBER,
                            pCOSTO_VENTAS           IN      NUMBER,
                            pGASTOS_OPERATIVO       IN      NUMBER,
                            pOTROS_INGRESOS         IN      NUMBER,
                            pGASTOS_FAMILIARES      IN      NUMBER,
                            pEXCEDENTE_FAMILIAR     IN      NUMBER,
                            pREL_CUOTA_EXCED_FAM    IN      NUMBER,    
                            pError                     OUT  VARCHAR2);
    
    PROCEDURE setError(pProgramUnit        IN     VARCHAR2,
                       pPieceCodeName      IN     VARCHAR2,
                       pErrorDescription   IN     VARCHAR2,
                       pErrorTrace         IN     CLOB,
                       pEmailNotification  IN     VARCHAR2,
                       pParamList          IN     ia.logger.TPARAMLIST,
                       pOutputLogger       IN     BOOLEAN,
                       pExecutionTime      IN     NUMBER,
                       pIdError              OUT  NUMBER);        
   PROCEDURE P_JOB_CREA_CREDITO_S; 
   PROCEDURE P_JOB_CREA_CREDITO;  
   PROCEDURE P_JOB_CREA_ACTUALIZA_CORE;   
   
   PROCEDURE P_CARGA_DE08(pFechaRegulatoria in date);     
   PROCEDURE P_CARGA_DE05(pFechaCastigo in date);     
   PROCEDURE P_Generar_reporte_deponente(p_No_Credito       IN     NUMBER,
                                                         p_Codigo_Cliente   IN     VARCHAR2,
                                                         p_Ciudad           IN     VARCHAR2,
                                                         p_SubirFileFlow    IN     BOOLEAN DEFAULT TRUE,
                                                         pError             IN OUT VARCHAR2);  
   PROCEDURE P_REGISTRO_SOLICITUD;
   PROCEDURE P_Insertar_Campana(
                                p_codigoEmpresa IN NUMBER,
                                p_nombre IN VARCHAR2,
                                p_descripcion IN VARCHAR2,
                                p_estado IN VARCHAR2,
                                pError   OUT VARCHAR2);      
                                
    PROCEDURE P_Actualizar_Campana(
                                   p_codigoEmpresa IN NUMBER,
                                   p_codigoCampana IN NUMBER,
                                   p_nombre IN VARCHAR2,
                                   p_descripcion IN VARCHAR2,
                                   p_estado IN VARCHAR2,
                                   pError OUT VARCHAR2);    
                                   
    PROCEDURE P_Inactivar_Campana;
    PROCEDURE P_CARGAR_DATOS_FUD_ANTERIOR(
                    p_id_represtamo IN VARCHAR2,
                    p_tipo_documento_identidad OUT VARCHAR2,
                    p_num_documento_identidad OUT VARCHAR2,
                    p_apodo OUT VARCHAR2,
                    p_id_agencia OUT VARCHAR2,
                    p_sexo OUT VARCHAR2,
                    p_fecha_nacimiento OUT VARCHAR2,
                    p_id_empleado OUT VARCHAR2,
                    p_id_pais OUT VARCHAR2,
                    p_id_provincia OUT VARCHAR2,
                    p_id_municipio OUT VARCHAR2,
                    p_id_distrito OUT VARCHAR2,
                    p_id_estado_civil OUT VARCHAR2,
                    p_nombre_vinculado OUT VARCHAR2,
                    p_direccion OUT VARCHAR2,
                    p_direccion_idsector OUT VARCHAR2,
                    p_direccion_idprovincia OUT VARCHAR2,
                    p_direccion_distrito OUT VARCHAR2,
                    p_ref_domicilio OUT VARCHAR2,
                    p_tipo_persona OUT VARCHAR2,
                    p_reside_mes OUT VARCHAR2,
                    p_reside_ano OUT VARCHAR2,
                    p_telefono_casa OUT VARCHAR2,
                    p_telefono_celular OUT VARCHAR2,
                    p_nombre_negocio OUT VARCHAR2,
                    p_rnc OUT VARCHAR2,
                    p_fax OUT VARCHAR2,
                    p_email OUT VARCHAR2,
                    p_inicio_mes OUT VARCHAR2,
                    p_inicio_ano OUT VARCHAR2,
                    p_lugar_trabajo OUT VARCHAR2,
                    p_fecha_ingreso OUT VARCHAR2,
                    p_cargo OUT VARCHAR2,
                    p_trabajo_direccion OUT VARCHAR2,
                    p_trabajo_idprovincia OUT VARCHAR2,
                    p_trabajo_idmunicipio OUT VARCHAR2,
                    p_trabajo_iddistrito OUT VARCHAR2,
                    p_punto_referencia OUT VARCHAR2,
                    p_telefono OUT VARCHAR2,
                    p_codigo_proyecto OUT VARCHAR2,
                    p_especifique_destino OUT VARCHAR2,
                    p_tasa_cal OUT VARCHAR2,
                    p_id_tipo_vinculado OUT VARCHAR2,
                    p_refpersonales_apellidos OUT VARCHAR2,
                    p_refpersonales_nombres OUT VARCHAR2,
                    p_refpers_relfamiliar OUT VARCHAR2,
                    p_refpersonales_nombres2 OUT VARCHAR2,
                    p_refpersonales_apellidos2 OUT VARCHAR2,
                    p_refpers_relfamiliar2 OUT VARCHAR2,
                    p_numdocumentoidentidadco OUT VARCHAR2,
                    p_primernombreco OUT VARCHAR2,
                    p_segundonombreco OUT VARCHAR2,
                    p_primerapellidoco OUT VARCHAR2,
                    p_segundoapellidoco OUT VARCHAR2,
                    p_fechanacimientoco OUT VARCHAR2,
                    p_apodoco OUT VARCHAR2,
                    p_idpaisco OUT VARCHAR2,
                    p_idprovinciaco OUT VARCHAR2,
                    p_idmunicipioco OUT VARCHAR2,
                    p_iddistritoco OUT VARCHAR2,
                    p_nombrevinculadoco OUT VARCHAR2,
                    p_idtipovinculadoco OUT VARCHAR2,
                    p_nombre_negocioco OUT VARCHAR2,
                    p_rncco OUT VARCHAR2,
                    p_faxco OUT VARCHAR2,
                    p_emailco OUT VARCHAR2,
                    p_actividad_ciiuco OUT VARCHAR2,
                    p_inicio_mes_co OUT VARCHAR2,
                    p_inicio_ano_co OUT VARCHAR2,
                    p_lugar_trabajoco OUT VARCHAR2,
                    p_fecha_ingresoco OUT VARCHAR2,
                    p_trabajo_direccionco OUT VARCHAR2,
                    p_trabajo_idsectorco OUT VARCHAR2,
                    p_trabajo_idprovinciaco OUT VARCHAR2,
                    p_trabajo_idmunicipioco OUT VARCHAR2,
                    p_trabajo_iddistritoco OUT VARCHAR2,
                    p_punto_referenciaco OUT VARCHAR2,
                    p_cargoco OUT VARCHAR2,
                    p_plazocal OUT VARCHAR2,
                    p_frecuencia_cal OUT VARCHAR2,
                    p_gradoint OUT VARCHAR2,
                    p_idocupacion OUT VARCHAR2,
                    p_idvinculado OUT VARCHAR2,
                    p_actividad_ciiu OUT VARCHAR2,
                    p_trabajo_idsector OUT VARCHAR2,
                    p_nombres OUT VARCHAR2,
                    p_apellidos OUT VARCHAR2,
                    p_primernombre OUT VARCHAR2,
                    p_segundonombre OUT VARCHAR2,
                    p_primerapellido OUT VARCHAR2,
                    p_segundoapellido OUT VARCHAR2,
                    p_desc_provincia OUT VARCHAR2,
                    p_desc_distrito OUT VARCHAR2,
                    p_desc_ciudad OUT VARCHAR2,
                    p_desc_provincia_dom OUT VARCHAR2,
                    p_desc_distrito_dom OUT VARCHAR2,
                    p_desc_ciudad_dom OUT VARCHAR2,
                    p_trabajo_desc_provincia OUT VARCHAR2,
                    p_trabajo_desc_distrito OUT VARCHAR2,
                    p_trabajo_desc_ciudad OUT VARCHAR2,
                    p_id_tempfud OUT VARCHAR2,
                    p_nomarchivo OUT VARCHAR2,
                    p_monto_solicitado OUT VARCHAR2);
    PROCEDURE P_CARGAR_DATOS_FUD_NUEVO(
                    p_id_represtamo IN VARCHAR2,
                    p_tipo_documento_identidad OUT VARCHAR2,
                    p_num_documento_identidad OUT VARCHAR2,
                    p_apodo OUT VARCHAR2,
                    p_id_agencia OUT VARCHAR2,
                    p_sexo OUT VARCHAR2,
                    p_fecha_nacimiento OUT VARCHAR2,
                    p_id_empleado OUT VARCHAR2,
                    p_id_pais OUT VARCHAR2,
                    p_id_provincia OUT VARCHAR2,
                    p_id_municipio OUT VARCHAR2,
                    p_id_distrito OUT VARCHAR2,
                    p_id_estado_civil OUT VARCHAR2,
                    p_nombre_vinculado OUT VARCHAR2,
                    p_direccion OUT VARCHAR2,
                    p_direccion_idsector OUT VARCHAR2,
                    p_direccion_idprovincia OUT VARCHAR2,
                    p_direccion_distrito OUT VARCHAR2,
                    p_ref_domicilio OUT VARCHAR2,
                    p_tipo_persona OUT VARCHAR2,
                    p_reside_mes OUT VARCHAR2,
                    p_reside_ano OUT VARCHAR2,
                    p_telefono_casa OUT VARCHAR2,
                    p_telefono_celular OUT VARCHAR2,
                    p_nombre_negocio OUT VARCHAR2,
                    p_rnc OUT VARCHAR2,
                    p_fax OUT VARCHAR2,
                    p_email OUT VARCHAR2,
                    p_inicio_mes OUT VARCHAR2,
                    p_inicio_ano OUT VARCHAR2,
                    p_lugar_trabajo OUT VARCHAR2,
                    p_fecha_ingreso OUT VARCHAR2,
                    p_cargo OUT VARCHAR2,
                    p_trabajo_direccion OUT VARCHAR2,
                    p_trabajo_idprovincia OUT VARCHAR2,
                    p_trabajo_idmunicipio OUT VARCHAR2,
                    p_trabajo_iddistrito OUT VARCHAR2,
                    p_punto_referencia OUT VARCHAR2,
                    p_telefono OUT VARCHAR2,
                    p_codigo_proyecto OUT VARCHAR2,
                    p_especifique_destino OUT VARCHAR2,
                    p_tasa_cal OUT VARCHAR2,
                    p_id_tipo_vinculado OUT VARCHAR2,
                    p_refpersonales_apellidos OUT VARCHAR2,
                    p_refpersonales_nombres OUT VARCHAR2,
                    p_refpers_relfamiliar OUT VARCHAR2,
                    p_refpersonales_nombres2 OUT VARCHAR2,
                    p_refpersonales_apellidos2 OUT VARCHAR2,
                    p_refpers_relfamiliar2 OUT VARCHAR2,
                    p_numdocumentoidentidadco OUT VARCHAR2,
                    p_primernombreco OUT VARCHAR2,
                    p_segundonombreco OUT VARCHAR2,
                    p_primerapellidoco OUT VARCHAR2,
                    p_segundoapellidoco OUT VARCHAR2,
                    p_fechanacimientoco OUT VARCHAR2,
                    p_apodoco OUT VARCHAR2,
                    p_idpaisco OUT VARCHAR2,
                    p_idprovinciaco OUT VARCHAR2,
                    p_idmunicipioco OUT VARCHAR2,
                    p_iddistritoco OUT VARCHAR2,
                    p_nombrevinculadoco OUT VARCHAR2,
                    p_idtipovinculadoco OUT VARCHAR2,
                    p_nombre_negocioco OUT VARCHAR2,
                    p_rncco OUT VARCHAR2,
                    p_faxco OUT VARCHAR2,
                    p_emailco OUT VARCHAR2,
                    p_actividad_ciiuco OUT VARCHAR2,
                    p_inicio_mes_co OUT VARCHAR2,
                    p_inicio_ano_co OUT VARCHAR2,
                    p_lugar_trabajoco OUT VARCHAR2,
                    p_fecha_ingresoco OUT VARCHAR2,
                    p_trabajo_direccionco OUT VARCHAR2,
                    p_trabajo_idsectorco OUT VARCHAR2,
                    p_trabajo_idprovinciaco OUT VARCHAR2,
                    p_trabajo_idmunicipioco OUT VARCHAR2,
                    p_trabajo_iddistritoco OUT VARCHAR2,
                    p_punto_referenciaco OUT VARCHAR2,
                    p_cargoco OUT VARCHAR2,
                    p_plazocal OUT VARCHAR2,
                    p_frecuencia_cal OUT VARCHAR2,
                    p_gradoint OUT VARCHAR2,
                    p_idocupacion OUT VARCHAR2,
                    p_idvinculado OUT VARCHAR2,
                    p_actividad_ciiu OUT VARCHAR2,
                    p_trabajo_idsector OUT VARCHAR2,
                    p_nombres OUT VARCHAR2,
                    p_apellidos OUT VARCHAR2,
                    p_primernombre OUT VARCHAR2,
                    p_segundonombre OUT VARCHAR2,
                    p_primerapellido OUT VARCHAR2,
                    p_segundoapellido OUT VARCHAR2,
                    p_desc_provincia OUT VARCHAR2,
                    p_desc_distrito OUT VARCHAR2,
                    p_desc_ciudad OUT VARCHAR2,
                    p_desc_provincia_dom OUT VARCHAR2,
                    p_desc_distrito_dom OUT VARCHAR2,
                    p_desc_ciudad_dom OUT VARCHAR2,
                    p_trabajo_desc_provincia OUT VARCHAR2,
                    p_trabajo_desc_distrito OUT VARCHAR2,
                    p_trabajo_desc_ciudad OUT VARCHAR2,
                    p_id_tempfud OUT VARCHAR2,
                    p_nomarchivo OUT VARCHAR2,
                    p_monto_solicitado OUT VARCHAR2);
    PROCEDURE P_CARGAR_DATOS_FEC_NUEVO( 
                    p_id_represtamo          IN  VARCHAR2,
                    p_no_credito             OUT VARCHAR2,
                    p_id_represtamo_out      OUT VARCHAR2,
                    p_nombres                OUT VARCHAR2,
                    p_codigo_cliente         OUT VARCHAR2,
                    p_fecha                  OUT VARCHAR2,
                    p_oficina                OUT VARCHAR2,
                    p_oficial_negocio        OUT VARCHAR2,
                    p_no_credito_nuevo       OUT VARCHAR2,
                    p_actividad_economica    OUT VARCHAR2,
                    p_mto_prestamo           OUT VARCHAR2,
                    p_plazo                  OUT VARCHAR2,
                    p_mto_cuota_total        OUT VARCHAR2,
                    p_tasa                   OUT VARCHAR2,
                    p_excedente_familiares   OUT VARCHAR2,
                    p_costo_ventas           OUT VARCHAR2,
                    p_gasto_operativo        OUT VARCHAR2,
                    p_gasto_operativo_std    OUT VARCHAR2,
                    p_margen_bruto_std       OUT VARCHAR2,
                    p_gastos_familiares      OUT VARCHAR2,
                    p_otros_ingresos         OUT VARCHAR2,
                    p_rel_cuota_exced_fam    OUT VARCHAR2,
                    p_ventas_mensual         OUT VARCHAR2 );
                    
PROCEDURE P_ACTUALIZA_COMENTARIO_CAMPANA(pComentario in VARCHAR2);
PROCEDURE P_Registrar_Ejecucion_Param(pCodigoParametro IN VARCHAR2,
                                     pTotalRegistros  IN NUMBER);
END PR_PKG_REPRESTAMOS;